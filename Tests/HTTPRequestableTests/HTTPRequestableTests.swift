@testable import HTTPRequestable
import HTTPTypes
import Testing

@Suite("HTTPRequestable")
struct HTTPRequestableTests {
  @Test
  func defaultHeaders() async throws {
    let userAgent = HTTPField.defaultUserAgent
    #expect(userAgent.name == HTTPField.Name.userAgent)
    #expect(userAgent.value.contains("com.apple.dt.xctest.tool"))
    #expect(userAgent.value.hasPrefix("xctest"))
    #expect(userAgent.value.hasSuffix("HTTPRequestable"))
    #expect(userAgent.value == String.url_userAgent)
  }
}
