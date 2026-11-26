//
//  HTTPSecurityDelegateTests.swift
//

#if canImport(ObjectiveC) && canImport(Security) && canImport(CryptoKit)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import HTTPRequestable
import HTTPTypes
import MockURLProtocol
import Security
import Testing

/// Self-signed test certificates; pins computed with
/// `openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64`.
private enum TestCertificates {
  static let ecDER = "MIIBHDCBwgIJAN6USjMPRbLCMAoGCCqGSM49BAMCMBYxFDASBgNVBAMMC3Bpbi10ZXN0LWVjMB4XDTI2MTEyMTIyNDY1NFoXDTM2MTExODIyNDY1NFowFjEUMBIGA1UEAwwLcGluLXRlc3QtZWMwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASMXc3nxSEPYH7dtH2FQLMdNgLjEPSUptOFV88x8CEVcIXZ0WN3DEL+VYHNjtggSpSdi/tQaFJ4X7tE40BmKG8pMAoGCCqGSM49BAMCA0kAMEYCIQDi66Pwxtvbdxf4JPAWBTwZ/htaFKQaas5cIcPkCR1vbwIhALJ6uvSfnToOuQ3N5CoLS7hfq2RWS75MxmcLuzU5BTJU"
  static let ecPin = "LxpGyHQz+lJx1MwgSvOeNq/n1gW/kPEqMibyLAvUOiM="

  static let rsaDER = "MIICqjCCAZICCQC+K3v2pU9cJTANBgkqhkiG9w0BAQsFADAXMRUwEwYDVQQDDAxwaW4tdGVzdC1yc2EwHhcNMjYxMTIxMjI0NjQ5WhcNMzYxMTE4MjI0NjQ5WjAXMRUwEwYDVQQDDAxwaW4tdGVzdC1yc2EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCmRErQq2QNgRFxtCFY6CoOcu2EQFT6tmsJZzebsRCUygUocOqVSTi/yvxiZm7b+1vFNRjsoK49D8F15cBgJgd5ZwmhU5Mzj/wa2dYqAdnFPwWV/+3GkPKjnezxQgLFDqf/RTljA/OSCS4lul4GMsBvymPJXrbv2rZrYQznByNN+WzBDGmm4qEg34W5rzRI6ljjWabfEZyQWsdMJvOak1GRvAYxWu8IaTfdzt/RmGQIGXPpuECvqLikcLdOBh9/K0RtV8+e3K0rt6xXwNm+C/lwyfIM76s64UwBBp3YT7GvjlMQaxT9q+FvzhbWwGF2Bu6CBPiDgi12YN+I6zkhuEZJAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAGM+7OHvZB75EdWCq2/jN2W9Fx+F204Q7XCEay7/UkjgZPZemkp9BqFlzHlBisyicGoIUFBHoMoG83VKQAHkQP13RuieOGbbaugBZyJ9GijZA/BBg9iDcMZ4A17TrmqEh60XaAC3mt2QMQZYfMANxcZhUMlyUSWUeNzlEZlpMsurhP/MsrK1yHn70gsgFmEemRFJnnirJqsBh2I4eGsnOMQH29Lg8l+eB/xy1xr3WL/O4iv+bkg+E5tkZMPMr/qUHFHafjnYzjz0NdRdJdz3O2w934vDFVBmNf8ge47So+QrCgcSFqY7Uld45MxVu9YGUDPmCUeGbXoXsuvuOmeiTmk="
  static let rsaPin = "uZGT1Bd4NO7pMnuqcMFUcoJsfm3K9XqKNzR+O1qHDtw="

  static func certificate(_ base64: String) throws -> SecCertificate {
    let data = try #require(Data(base64Encoded: base64))
    return try #require(SecCertificateCreateWithData(nil, data as CFData))
  }
}

/// Records which callbacks reach it through the wrapper.
private final class RecordingDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
  var redirectedRequest: URLRequest?
  var challengeCount = 0

  func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                  newRequest request: URLRequest, completionHandler: @escaping @Sendable (URLRequest?) -> Void)
  {
    redirectedRequest = request
    completionHandler(request)
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge,
                  completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
  {
    challengeCount += 1
    completionHandler(.rejectProtectionSpace, nil)
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64,
                  totalBytesExpectedToSend: Int64) {}
}

private final class ChallengeSender: NSObject, URLAuthenticationChallengeSender {
  func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
  func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
  func cancel(_ challenge: URLAuthenticationChallenge) {}
}

private final class Box<Value>: @unchecked Sendable {
  var value: Value
  init(_ value: Value) {
    self.value = value
  }
}

struct HTTPSecurityDelegateTests {
  // MARK: Wrapping

  @Test("Delegates are wrapped so redirect protection always applies")
  func wrapping() {
    #expect(URLSession.secureTaskDelegate(nil) === HTTPSecurityDelegate.default)

    let policy = HTTPRedirectPolicy(allowedHosts: ["a.example.com"])
    #expect(URLSession.secureTaskDelegate(policy) === policy)

    let security = HTTPSecurityDelegate(maxResponseSize: 10)
    #expect(URLSession.secureTaskDelegate(security) === security)

    let custom = RecordingDelegate()
    let wrapped = URLSession.secureTaskDelegate(custom) as? HTTPSecurityDelegate
    #expect(wrapped?.delegate === custom)
    #expect(wrapped?.redirectPolicy === HTTPRedirectPolicy.default)
  }

  @Test("Callbacks the wrapper does not handle are forwarded")
  func forwarding() {
    let custom = RecordingDelegate()
    let wrapped = HTTPSecurityDelegate(delegate: custom)
    let didSend = #selector(URLSessionTaskDelegate.urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:))
    let metrics = #selector(URLSessionTaskDelegate.urlSession(_:task:didFinishCollecting:))
    #expect(wrapped.responds(to: didSend))
    #expect(wrapped.forwardingTarget(for: didSend) as AnyObject? === custom)
    #expect(!wrapped.responds(to: metrics))
    #expect(!HTTPSecurityDelegate().responds(to: didSend))
  }

  // MARK: Redirects

  private func redirect(through delegate: HTTPSecurityDelegate, from: String, to: String) throws -> URLRequest? {
    let fromURL = try #require(URL(string: from))
    let task = URLSession.shared.dataTask(with: fromURL)
    defer { task.cancel() }
    var newRequest = try URLRequest(url: #require(URL(string: to)))
    newRequest.setValue("Bearer secret", forHTTPHeaderField: "Authorization")
    let response = try #require(HTTPURLResponse(url: fromURL, statusCode: 302, httpVersion: nil, headerFields: nil))
    let result = Box<URLRequest?>(nil)
    delegate.urlSession(URLSession.shared, task: task, willPerformHTTPRedirection: response, newRequest: newRequest) { result.value = $0 }
    return result.value
  }

  @Test("The wrapped delegate sees the redirect after credentials are stripped")
  func redirectFilteredBeforeForwarding() throws {
    let custom = RecordingDelegate()
    let result = try redirect(through: HTTPSecurityDelegate(delegate: custom), from: "https://api.example.com/a", to: "https://evil.example.org/b")
    #expect(result != nil)
    #expect(result?.value(forHTTPHeaderField: "Authorization") == nil)
    #expect(custom.redirectedRequest?.value(forHTTPHeaderField: "Authorization") == nil)
  }

  @Test("A blocked redirect never reaches the wrapped delegate")
  func blockedRedirectNotForwarded() throws {
    let custom = RecordingDelegate()
    let result = try redirect(through: HTTPSecurityDelegate(delegate: custom), from: "https://api.example.com/a", to: "http://api.example.com/b")
    #expect(result == nil)
    #expect(custom.redirectedRequest == nil)
  }

  @Test("Without a redirect policy the proposed request is followed unchanged")
  func noRedirectPolicy() throws {
    let result = try redirect(through: HTTPSecurityDelegate(redirectPolicy: nil), from: "https://api.example.com/a", to: "https://evil.example.org/b")
    #expect(result?.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
  }

  // MARK: Challenges

  private func challenge(method: String, host: String = "api.example.com") -> URLAuthenticationChallenge {
    let space = URLProtectionSpace(host: host, port: 443, protocol: "https", realm: nil, authenticationMethod: method)
    return URLAuthenticationChallenge(protectionSpace: space, proposedCredential: nil, previousFailureCount: 0,
                                      failureResponse: nil, error: nil, sender: ChallengeSender())
  }

  private func disposition(of delegate: HTTPSecurityDelegate, for challenge: URLAuthenticationChallenge) throws -> URLSession.AuthChallengeDisposition? {
    let task = try URLSession.shared.dataTask(with: #require(URL(string: "https://api.example.com")))
    defer { task.cancel() }
    let result = Box<URLSession.AuthChallengeDisposition?>(nil)
    delegate.urlSession(URLSession.shared, task: task, didReceive: challenge) { disposition, _ in result.value = disposition }
    return result.value
  }

  @Test("Challenges that are not pinned fall back to the wrapped delegate, then the system")
  func challengeFallback() throws {
    let basic = challenge(method: NSURLAuthenticationMethodHTTPBasic)
    #expect(try disposition(of: HTTPSecurityDelegate(), for: basic) == .performDefaultHandling)

    let custom = RecordingDelegate()
    #expect(try disposition(of: HTTPSecurityDelegate(delegate: custom), for: basic) == .rejectProtectionSpace)
    #expect(custom.challengeCount == 1)
  }

  @Test("A pinned host's server trust challenge is decided by the pins, not the wrapped delegate")
  func pinnedChallengeNotForwarded() throws {
    let custom = RecordingDelegate()
    let pins = HTTPPublicKeyPinning(publicKeyHashes: [TestCertificates.ecPin], hosts: ["api.example.com"])
    let delegate = HTTPSecurityDelegate(pinning: pins, delegate: custom)

    // No serverTrust can be attached to a synthetic challenge, so a pinned host is cancelled.
    #expect(try disposition(of: delegate, for: challenge(method: NSURLAuthenticationMethodServerTrust)) == .cancelAuthenticationChallenge)
    #expect(custom.challengeCount == 0)

    // Hosts outside the pins go to the wrapped delegate.
    #expect(try disposition(of: delegate, for: challenge(method: NSURLAuthenticationMethodServerTrust, host: "other.example.org")) == .rejectProtectionSpace)
  }

  // MARK: Pinning

  @Test("Pins match openssl's SubjectPublicKeyInfo hashes")
  func publicKeyHashes() throws {
    #expect(try HTTPPublicKeyPinning.publicKeyHash(for: TestCertificates.certificate(TestCertificates.ecDER)) == TestCertificates.ecPin)
    #expect(try HTTPPublicKeyPinning.publicKeyHash(for: TestCertificates.certificate(TestCertificates.rsaDER)) == TestCertificates.rsaPin)

    let pins = try HTTPPublicKeyPinning(certificates: [TestCertificates.certificate(TestCertificates.rsaDER)], additionalPublicKeyHashes: ["backup"])
    #expect(pins.publicKeyHashes == [TestCertificates.rsaPin, "backup"])
  }

  @Test("Pins apply to their hosts, and to subdomains only when asked")
  func pinnedHosts() {
    #expect(HTTPPublicKeyPinning(publicKeyHashes: []).applies(toHost: "anything.example"))

    let exact = HTTPPublicKeyPinning(publicKeyHashes: [], hosts: ["Example.com"])
    #expect(exact.applies(toHost: "example.COM"))
    #expect(!exact.applies(toHost: "api.example.com"))

    let subdomains = HTTPPublicKeyPinning(publicKeyHashes: [], hosts: ["example.com"], includesSubdomains: true)
    #expect(subdomains.applies(toHost: "api.example.com"))
    #expect(!subdomains.applies(toHost: "badexample.com"))
  }

  @Test("A pinned key does not rescue a chain the system rejects")
  func systemValidationFirst() throws {
    let certificate = try TestCertificates.certificate(TestCertificates.ecDER)
    var trust: SecTrust?
    #expect(SecTrustCreateWithCertificates(certificate, SecPolicyCreateSSL(true, "pin-test-ec" as CFString), &trust) == errSecSuccess)
    let serverTrust = try #require(trust)
    let pins = HTTPPublicKeyPinning(publicKeyHashes: [TestCertificates.ecPin])
    #expect(throws: TrustError.evaluationFailed) {
      try pins.evaluate(serverTrust)
    }
  }

  // MARK: Response size

  private func mockSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
  }

  private func request(serving bytes: Int) async throws -> HTTPRequest {
    let url = try #require(URL(string: "https://api.example.com/size/\(UUID().uuidString)"))
    try await MockURLProtocol.setRequestHandler({ _ in
      (Data(repeating: 7, count: bytes), HTTPURLResponse.ok(url: url))
    }, forIdentifier: url)
    return HTTPRequest(method: .get, url: url)
  }

  @Test("Responses over maxResponseSize are rejected")
  func responseTooLarge() async throws {
    let session = mockSession()
    let request = try await request(serving: 1000)
    await #expect(throws: URLError(.dataLengthExceedsMaximum)) {
      try await session.performRequest(request, httpBody: nil, retryPolicy: nil, delegate: HTTPSecurityDelegate(maxResponseSize: 100))
    }
  }

  @Test("Responses within maxResponseSize are returned in full")
  func responseWithinLimit() async throws {
    let session = mockSession()
    let request = try await request(serving: 1000)
    let response = try await session.performRequest(request, httpBody: nil, retryPolicy: nil, delegate: HTTPSecurityDelegate(maxResponseSize: 1000))
    #expect(response.responseData.count == 1000)
    #expect(response.status == .ok)
  }

  @Test("Request bodies are still sent when a size limit is set")
  func limitedUploadSendsBody() async throws {
    let session = mockSession()
    let url = try #require(URL(string: "https://api.example.com/upload/\(UUID().uuidString)"))
    try await MockURLProtocol.setRequestHandler({ request in
      // URLProtocol sees uploaded bodies as a stream.
      let body = request.httpBody ?? request.httpBodyStream.map { stream in
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 64)
        while case let count = stream.read(&buffer, maxLength: buffer.count), count > 0 {
          data.append(buffer, count: count)
        }
        return data
      }
      return (body ?? Data(), HTTPURLResponse.ok(url: url))
    }, forIdentifier: url)
    let response = try await session.performRequest(HTTPRequest(method: .post, url: url), httpBody: Data("hello".utf8), retryPolicy: nil,
                                                    delegate: HTTPSecurityDelegate(maxResponseSize: 100))
    #expect(response.responseData == Data("hello".utf8))
  }
}
#endif
