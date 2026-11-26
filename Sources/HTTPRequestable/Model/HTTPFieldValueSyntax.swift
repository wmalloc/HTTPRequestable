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
