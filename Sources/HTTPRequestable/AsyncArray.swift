//
//  AsyncArray.swift
//  HTTPRequestable
//
//  Created by Waqar Malik on 4/17/25.
//

import Foundation

/// A storage actor for managing a collection of HTTP interceptors.
///
/// This struct is designed to be used as an `actor`, ensuring thread-safe operations when accessing or modifying the list of interceptors.
/// It conforms to the `Sendable` protocol, allowing it to be safely shared between tasks.
public actor AsyncArray<Element: Sendable>: AsyncSequence {
  /// The internal storage for HTTP interceptors.
  private var elements: [Element]

  /// Creates a new, empty array.
  ///
  public init() {
    self.elements = []
    (self.stream, self.continuation) = AsyncThrowingStream.makeStream(bufferingPolicy: .unbounded)
  }
  
  /// Creates an array containing the elements of a sequence.
  ///
  /// You can use this initializer to create an array from any other type that
  /// conforms to the `Sequence` protocol. For example, you might want to
  /// create an array with the integers from 1 through 7. Use this initializer
  /// around a range instead of typing all those numbers in an array literal.
  ///
  /// You can also use this initializer to convert a complex sequence or
  /// collection type back to an array. For example, the `keys` property of
  /// a dictionary isn't an array with its own storage, it's a collection
  /// that maps its elements from the dictionary only when they're
  /// accessed, saving the time and space needed to allocate an array. If
  /// you need to pass those keys to a method that takes an array, however,
  /// use this initializer to convert that list from its type of
  /// - Parameter s: The sequence of elements to turn into an array.
  public init<S>(_ s: S) where Element == S.Element, S : Sequence {
    self.elements = Array(s)
    (self.stream, self.continuation) = AsyncThrowingStream.makeStream(bufferingPolicy: .unbounded)
  }
  
  /// Creates an array from the given array literal.
  ///
  /// Do not call this initializer directly. It is used by the compiler
  /// when you use an array literal. Instead, create a new array by using an
  /// array literal as its value. To do this, enclose a comma-separated list of
  /// values in square brackets.
  ///
  /// Here, an array of strings is created from an array literal holding
  /// only strings.
  ///
  /// - Parameter elements: A variadic list of elements of the new array.
  public init(arrayLiteral elements: Element...) {
    self.elements = Array(elements)
    (self.stream, self.continuation) = AsyncThrowingStream.makeStream(bufferingPolicy: .unbounded)
  }

  /// The total number of interceptors currently stored in this `HTTPInterceptorStorage`.
  public var count: Int {
    elements.count
  }

  /// Indicates whether the storage is empty (contains no interceptors).
  ///
  /// - Returns:
  ///   - `true` if the storage is empty; otherwise, `false`.
  public var isEmpty: Bool {
    elements.isEmpty
  }

  /// Accesses the element at the specified position.
  ///
  /// The following example uses indexed subscripting to update an array's
  /// second element. After assigning the new value (`"Butler"`) at a specific
  /// position, that value is immediately available at that same position.
  ///
  /// - Parameter index: The position of the element to access. `index` must be
  ///   greater than or equal to `startIndex` and less than `endIndex`.
  ///
  /// - Complexity: Reading an element from an array is O(1). Writing is O(1)
  ///   unless the array's storage is shared with another array or uses a
  ///   bridged `NSArray` instance as its storage, in which case writing is
  ///   O(*n*), where *n* is the length of the array.
  public subscript(index: Int) -> Element {
    elements[index]
  }

  /// Inserts a new element at the specified position.
  ///
  /// The new element is inserted before the element currently at the specified
  /// index. If you pass the array's `endIndex` property as the `index`
  /// parameter, the new element is appended to the array.
  ///
  /// - Parameter newElement: The new element to insert into the array.
  /// - Parameter i: The position at which to insert the new element.
  ///   `index` must be a valid index of the array or equal to its `endIndex`
  ///   property.
  ///
  /// - Complexity: O(*n*), where *n* is the length of the array. If
  ///   `i == endIndex`, this method is equivalent to `append(_:)`.
  public func insert(_ newElement: Element, at i: Int) {
    elements.insert(newElement, at: i)
  }

  /// Adds a new element at the end of the array.
  ///
  /// Use this method to append a single element to the end of a mutable array.
  ///
  /// Because arrays increase their allocated capacity using an exponential
  /// strategy, appending a single element to an array is an O(1) operation
  /// when averaged over many calls to the `append(_:)` method. When an array
  /// has additional capacity and is not sharing its storage with another
  /// instance, appending an element is O(1). When an array needs to
  /// reallocate storage before appending or its storage is shared with
  /// another copy, appending is O(*n*), where *n* is the length of the array.
  ///
  /// - Parameter newElement: The element to append to the array.
  ///
  /// - Complexity: O(1) on average, over many calls to `append(_:)` on the
  ///   same array.
  public func append(_ newElement: Element) {
    elements.append(newElement)
  }

  /// Removes an HTTP interceptor from the storage at a specified index and returns it, if found.
  ///
  /// - Parameter index: The position of the element to remove. `index` must
  ///   be a valid index of the array.
  /// - Returns: The element at the specified index.
  ///
  /// - Complexity: O(*n*), where *n* is the length of the array.
  @discardableResult
  public func remove(at index: Int) -> Element? {
    elements.remove(at: index)
  }

  /// Removes all elements from the array.
  ///
  /// - Parameter keepCapacity: Pass `true` to keep the existing capacity of
  ///   the array after removing its elements. The default value is
  ///   `false`.
  ///
  /// - Complexity: O(*n*), where *n* is the length of the array.
  public func removeAll(keepingCapacity keepCapacity: Bool = false) {
    elements.removeAll(keepingCapacity: keepCapacity)
  }

  /// Removes all the elements that satisfy the given predicate.
  ///
  /// Use this method to remove every element in a collection that meets
  /// particular criteria. The order of the remaining elements is preserved.
  /// This example removes all the odd values from an
  /// array of numbers:
  ///
  /// - Parameter shouldBeRemoved: A closure that takes an element of the
  ///   sequence as its argument and returns a Boolean value indicating
  ///   whether the element should be removed from the collection.
  ///
  /// - Complexity: O(*n*), where *n* is the length of the collection.

  public func removeAll(where shouldBeRemoved: (Element) throws -> Bool) rethrows {
    try elements.removeAll(where: shouldBeRemoved)
  }

  /// Returns a view presenting the elements of the collection in reverse
  /// order.
  ///
  /// You can reverse a collection without allocating new space for its
  /// elements by calling this `reversed()` method. A `ReversedCollection`
  /// instance wraps an underlying collection and provides access to its
  /// elements in reverse order. This example prints the characters of a
  /// string in reverse order:
  ///
  /// If you need a reversed collection of the same type, you may be able to
  /// use the collection's sequence-based or collection-based initializer. For
  /// example, to get the reversed version of a string, reverse its
  /// characters and initialize a new `String` instance from the result.
  ///
  /// - Complexity: O(1)
  public func reversed() -> AsyncArray<Element> {
    let reversedElements = elements.reversed()
    return AsyncArray(reversedElements)
  }
  
  public typealias AsyncIterator = AsyncThrowingStream<Element, Error>.AsyncIterator
  
  private var page = 1
  private var hasReachedEnd = false
  private let stream: AsyncThrowingStream<Element, Error>
  private let continuation: AsyncThrowingStream<Element, Error>.Continuation
   
  func produce() async throws {
    do {
      while !hasReachedEnd {
        let books = try await fetchBooks(page: page)
        hasReachedEnd = books.isEmpty
        for book in books {
          continuation.yield(book)
        }
        page += 1
      }
      continuation.finish()
    } catch {
      continuation.finish(throwing: error)
    }
  }
  
  func fetchBooks(page: Int) async throws -> [Element] {
    elements
  }
  
  // AsyncSequence required a nonisolated func here
  public nonisolated func makeAsyncIterator() -> AsyncIterator {
    stream.makeAsyncIterator()
  }
}
