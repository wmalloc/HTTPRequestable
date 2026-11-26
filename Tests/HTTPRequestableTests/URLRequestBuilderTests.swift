//
//  URLRequestBuilderTests.swift
//
//  Created by Waqar Malik on 11/26/26.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import HTTPRequestable
import HTTPTypes
import Testing

struct URLRequestBuilderTests {
  private let request = URLRequest(url: #URL("https://api.example.com/items"))

  @Test("The renamed setters set their properties")
  func renamedSetters() {
    let mainDocument = #URL("https://example.com")
    let configured = request
      .setMainDocumentURL(mainDocument)
      .setAllowsConstrainedNetworkAccess(false)
    #expect(configured.mainDocumentURL == mainDocument)
    #expect(!configured.allowsConstrainedNetworkAccess)
  }

  @Test("setHttpBody sets the body, Content-Length and, when given, Content-Type")
  func setBody() {
    let body = Data("{\"id\":1}".utf8)
    let withType = request.setHttpBody(body, contentType: .json)
    #expect(withType.httpBody == body)
    #expect(withType.value(forHTTPField: .contentLength) == "\(body.count)")
    #expect(withType.value(forHTTPField: .contentType) == "application/json")

    let keepsType = withType.setHttpBody(Data("x".utf8))
    #expect(keepsType.value(forHTTPField: .contentType) == "application/json")
    #expect(keepsType.value(forHTTPField: .contentLength) == "1")
  }

  @Test("Removing the body also removes its Content-Length")
  func removeBody() {
    let removed = request.setHttpBody(Data("abc".utf8)).setHttpBody(nil)
    #expect(removed.httpBody == nil)
    #expect(removed.value(forHTTPField: .contentLength) == nil)
  }

  @Test("setHttpHeader with nil removes the field")
  func removeHeader() {
    let set = request.setHttpHeader("token", forField: .authorization)
    #expect(set.value(forHTTPField: .authorization) == "token")
    #expect(set.setHttpHeader(nil, forField: .authorization).value(forHTTPField: .authorization) == nil)
  }

  @Test("Typed setters cover what the removed String versions did")
  func typedSetters() {
    let configured = request
      .setMethod(.post)
      .setContentType("application/vnd.api+json")
      .setHeaders([HTTPField(name: .accept, value: "application/json")])
      .addHeader(HTTPField(name: .accept, value: "text/plain"))
    #expect(configured.httpMethod == "POST")
    // setHeaders replaced every field, including the Content-Type set before it.
    #expect(configured.value(forHTTPField: .contentType) == nil)
    #expect(configured.value(forHTTPField: .accept) == "application/json,text/plain")
    #expect(request.setMethod(.put).setMethod(nil).httpMethod == "GET")
  }

  @Test("Replacing or clearing the headers removes the existing ones")
  func replaceHeaders() {
    let start = request
      .setHttpHeader("Bearer secret", forField: .authorization)
      .setContentType(.json)
    let replaced = start.setHttpHeaderFields([.accept: "text/plain"])
    #expect(replaced.allHTTPHeaderFields == ["Accept": "text/plain"])
    #expect(start.setHttpHeaderFields(nil).allHTTPHeaderFields?.isEmpty ?? true)
    #expect(start.setHeaders(nil).value(forHTTPField: .authorization) == nil)

    var direct = start
    direct.headerFields = [.userAgent: "test"]
    #expect(direct.allHTTPHeaderFields == ["User-Agent": "test"])
  }

  @Test("setMultipartFormData sets the body with its Content-Type and Content-Length")
  func multipart() throws {
    // A form reads each part's stream once, so an identical second form gives the expected body.
    func makeForm() -> MultipartForm {
      let form = MultipartForm(boundary: "BOUNDARY")
      form.append(data: Data("value".utf8), withName: "field")
      return form
    }
    let form = makeForm()
    let configured = try request.setMultipartFormData(form)
    let body = try #require(configured.httpBody)
    let expected = makeForm()
    #expect(try body == expected.data(streamBufferSize: expected.streamBufferSize))
    #expect(configured.value(forHTTPField: .contentType) == "multipart/form-data; boundary=BOUNDARY")
    #expect(configured.value(forHTTPField: .contentLength) == "\(body.count)")
  }
}
