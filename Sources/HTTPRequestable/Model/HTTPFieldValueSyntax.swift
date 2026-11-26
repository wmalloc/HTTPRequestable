//
//  HTTPFieldValueSyntax.swift
//
//  Created by Waqar Malik on 11/25/26.
//

/// Grammar checks and encoding for parts of HTTP field values (RFC 9110 section 5.6).
///
/// `KeyedItem` and `Quality` use these so a value cannot end a parameter or list element early and add
/// parameters or elements of its own.
enum HTTPFieldValueSyntax {
  /// Whether `scalar` is a `tchar`: a letter, a digit or one of ``!#$%&'*+-.^_`|~``.
  static func isTokenCharacter(_ scalar: Unicode.Scalar) -> Bool {
    switch scalar {
    case "a" ... "z", "A" ... "Z", "0" ... "9",
         "!", "#", "$", "%", "&", "'", "*", "+", "-", ".", "^", "_", "`", "|", "~":
      true
    default:
      false
    }
  }

  /// Whether `string` is a non-empty `token`.
  static func isToken(_ string: some StringProtocol) -> Bool {
    !string.isEmpty && string.unicodeScalars.allSatisfy(isTokenCharacter)
  }

  /// Whether `string` is a media range such as `text/html`, `text/*` or `*/*`: two tokens joined by `/`.
  static func isMediaRange(_ string: String) -> Bool {
    let parts = string.split(separator: "/", omittingEmptySubsequences: false)
    return parts.count == 2 && parts.allSatisfy(isToken)
  }

  /// Whether `scalar` is a control character, which a field value cannot contain even quoted.
  /// Horizontal tab is allowed.
  static func isControlCharacter(_ scalar: Unicode.Scalar) -> Bool {
    (scalar.value < 0x20 && scalar != "\t") || scalar.value == 0x7F
  }

  /// Whether `string` is a complete `quoted-string`: it starts and ends with `"`, and every `"` or `\`
  /// in between is escaped with `\`. Characters outside ASCII are allowed, as `obs-text`.
  static func isQuotedString(_ string: String) -> Bool {
    let scalars = Array(string.unicodeScalars)
    guard scalars.count >= 2, scalars.first == "\"", scalars.last == "\"" else {
      return false
    }
    var index = 1
    while index < scalars.count - 1 {
      let scalar = scalars[index]
      if isControlCharacter(scalar) {
        return false
      }
      if scalar == "\\" {
        // A quoted-pair: the escaped character must exist and cannot be the closing quote.
        index += 1
        guard index < scalars.count - 1, !isControlCharacter(scalars[index]) else {
          return false
        }
      } else if scalar == "\"" {
        return false
      }
      index += 1
    }
    return true
  }

  /// Whether `string` is a token or a media range, the forms a list item or a parameterized item takes.
  static func isItem(_ string: String) -> Bool {
    isToken(string) || isMediaRange(string)
  }

  /// Whether `value` can be written as a parameter value: it holds no control character, such as CR or
  /// LF, which no field value can hold even quoted.
  static func isParameterValue(_ value: String) -> Bool {
    !value.unicodeScalars.contains(where: isControlCharacter)
  }

  /// `value` as a parameter value: as it is when it is a token or already a quoted-string, otherwise
  /// quoted with `"` and `\` escaped.
  ///
  /// - Precondition: ``isParameterValue(_:)`` is `true` for `value`.
  static func parameterValue(_ value: String) -> String {
    if isToken(value) || isQuotedString(value) {
      return value
    }
    var quoted = "\""
    for character in value {
      if character == "\"" || character == "\\" {
        quoted.append("\\")
      }
      quoted.append(character)
    }
    quoted.append("\"")
    return quoted
  }

  /// `quality` as a `qvalue`: clamped to 0...1 and written with one to three decimals and no exponent,
  /// such as `1.0`, `0.9` or `0.125`. `nil` when it is NaN.
  static func qvalue(_ quality: Float) -> String? {
    guard !quality.isNaN else {
      return nil
    }
    let thousandths = Int((min(max(Double(quality), 0), 1) * 1000).rounded())
    guard thousandths < 1000 else {
      return "1.0"
    }
    var decimals = String(thousandths)
    decimals = String(repeating: "0", count: 3 - decimals.count) + decimals
    while decimals.count > 1, decimals.hasSuffix("0") {
      decimals.removeLast()
    }
    return "0.\(decimals)"
  }
}

// MARK: - Parsing

extension HTTPFieldValueSyntax {
  /// The parts of a parsed media type, such as `text/html; charset=utf-8`.
  struct MediaType {
    /// The type, lowercased.
    var type: String
    /// The subtype, lowercased.
    var subtype: String
    /// The parameters in order, with names lowercased and quoted values unquoted.
    var parameters: [(name: String, value: String)]
  }

  /// Parses `string` as a `media-type` (RFC 9110 section 8.3.1): `type "/" subtype`, then any number of
  /// `; name=value` parameters, where each value is a token or a quoted-string. Whitespace is allowed
  /// only around the `;` separators. Returns `nil` when `string` does not match.
  static func parseMediaType(_ string: String) -> MediaType? {
    var scanner = FieldScanner(string)
    guard let type = scanner.token(), scanner.consume("/"), let subtype = scanner.token() else {
      return nil
    }
    var parameters: [(name: String, value: String)] = []
    while true {
      scanner.skipWhitespace()
      if scanner.isAtEnd {
        break
      }
      guard scanner.consume(";") else {
        return nil
      }
      scanner.skipWhitespace()
      // RFC 9110 allows empty parameters, as in `text/plain;`.
      if scanner.isAtEnd || scanner.peek == ";" {
        continue
      }
      guard let name = scanner.token(), scanner.consume("=") else {
        return nil
      }
      guard let value = scanner.peek == "\"" ? scanner.quotedString() : scanner.token() else {
        return nil
      }
      parameters.append((name: name.lowercased(), value: value))
    }
    return MediaType(type: type.lowercased(), subtype: subtype.lowercased(), parameters: parameters)
  }

  /// The elements of a comma-separated list, trimmed of whitespace and without empty elements. Commas
  /// inside quoted-strings do not separate elements.
  static func listElements(_ string: String) -> [String] {
    var elements: [String] = []
    var current = String.UnicodeScalarView()
    var isQuoted = false
    var isEscaped = false
    for scalar in string.unicodeScalars {
      if isEscaped {
        isEscaped = false
      } else if isQuoted, scalar == "\\" {
        isEscaped = true
      } else if scalar == "\"" {
        isQuoted.toggle()
      } else if scalar == ",", !isQuoted {
        elements.append(String(current))
        current = String.UnicodeScalarView()
        continue
      }
      current.append(scalar)
    }
    elements.append(String(current))
    return elements
      .map { $0.trimmingWhitespace() }
      .filter { !$0.isEmpty }
  }

  /// Parses a `qvalue` (RFC 9110 section 12.4.2): `0` to `1` with at most three decimals. Returns `nil`
  /// for anything else, such as `2`, `0.1234` or `abc`.
  static func parseQValue(_ string: String) -> Double? {
    let parts = string.split(separator: ".", omittingEmptySubsequences: false)
    guard (1 ... 2).contains(parts.count), parts[0] == "0" || parts[0] == "1" else {
      return nil
    }
    if parts.count == 2 {
      let decimals = parts[1]
      guard decimals.count <= 3, decimals.allSatisfy(\.isASCII), decimals.allSatisfy(\.isNumber) else {
        return nil
      }
      guard parts[0] == "0" || decimals.allSatisfy({ $0 == "0" }) else {
        return nil
      }
    }
    return Double(string)
  }

  /// Reads the parts of a field value one at a time.
  private struct FieldScanner {
    private let scalars: [Unicode.Scalar]
    private var index = 0

    init(_ string: String) {
      scalars = Array(string.unicodeScalars)
    }

    var isAtEnd: Bool {
      index == scalars.count
    }

    var peek: Unicode.Scalar? {
      isAtEnd ? nil : scalars[index]
    }

    /// Consumes `scalar` if it is next.
    mutating func consume(_ scalar: Unicode.Scalar) -> Bool {
      guard peek == scalar else {
        return false
      }
      index += 1
      return true
    }

    /// Skips spaces and horizontal tabs (`OWS`).
    mutating func skipWhitespace() {
      while let scalar = peek, scalar == " " || scalar == "\t" {
        index += 1
      }
    }

    /// Consumes a token, or returns `nil` when none is next.
    mutating func token() -> String? {
      let start = index
      while let scalar = peek, HTTPFieldValueSyntax.isTokenCharacter(scalar) {
        index += 1
      }
      guard index > start else {
        return nil
      }
      var token = String.UnicodeScalarView()
      token.append(contentsOf: scalars[start ..< index])
      return String(token)
    }

    /// Consumes a quoted-string and returns its content with quoted-pairs resolved, or returns `nil`
    /// when the string is not closed or contains a control character.
    mutating func quotedString() -> String? {
      guard consume("\"") else {
        return nil
      }
      var content = String.UnicodeScalarView()
      while let scalar = peek {
        index += 1
        if HTTPFieldValueSyntax.isControlCharacter(scalar) {
          return nil
        }
        if scalar == "\"" {
          return String(content)
        }
        if scalar == "\\" {
          guard let escaped = peek, !HTTPFieldValueSyntax.isControlCharacter(escaped) else {
            return nil
          }
          index += 1
          content.append(escaped)
        } else {
          content.append(scalar)
        }
      }
      return nil
    }
  }
}

private extension String {
  /// The string without leading or trailing spaces and horizontal tabs.
  func trimmingWhitespace() -> String {
    var scalars = Substring(self).unicodeScalars
    while let first = scalars.first, first == " " || first == "\t" {
      scalars.removeFirst()
    }
    while let last = scalars.last, last == " " || last == "\t" {
      scalars.removeLast()
    }
    return String(scalars)
  }
}
