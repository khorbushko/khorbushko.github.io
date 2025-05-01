---
layout: post
comments: true
title: "Exploring @unchecked Sendable in Swift Concurrency"
categories: article
tags: [iOS, swift, Concurrency, Sendable]
excerpt_separator: <!--more-->
comments_id: 118

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

Swift's [`Sendable`](https://developer.apple.com/documentation/swift/sendable) protocol is a cornerstone of the language's concurrency model, marking types that can be safely shared across concurrent contexts. When the Swift team introduced structured concurrency in Swift 5.5, they needed a way to ensure thread safety at compile time.
<!--more-->

`@unchecked Sendable` serves as an escape hatch for types that can't automatically satisfy `Sendable` requirements but are known to be thread-safe through other means. It tells the compiler "I know what I'm doing" when you can't prove thread safety through Swift's normal mechanisms.

## Historical Context and Proposal

The concept of [`Sendable`](https://developer.apple.com/documentation/swift/sendable) and its unchecked variant emerged from [SE-0302: `Sendable` and `@Sendable` closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md), which was part of Swift's larger concurrency story.

### Key points from the proposal:

* Originally called `ConcurrentValue`, renamed to `Sendable` before final implementation
* Designed to prevent data races by marking thread-safe types
* `@unchecked Sendable` was included for legacy code and special cases (previously [`UnsafeSendable`](https://developer.apple.com/documentation/swift/unsafesendable))

The `Swift` team recognized that some thread-safe types couldn't mechanically satisfy `Sendable` requirements because:

* They used internal synchronization
* They were inherently immutable despite containing `non-Sendable` components
* They wrapped `non-Sendable` system types that were known to be safe

### Example

A simple example is next:

```swift
final class Counter: @unchecked Sendable {
    private var value: Int = 0
    private let queue = DispatchQueue(label: "com.counter.syncQ")

    func change(_ newValue: Int) {
        queue.sync {
            self.value = newValue
        }
    }
    
    func retrive() -> Int {
        queue.sync { value }
    }
}
```

> Another alternative for isolation may be region-based concurrency isolation [SE-414](https://github.com/apple/swift-evolution/blob/main/proposals/0414-region-based-isolation.md):
> 
```swift
Task { @MainActor in
    // some code
}
```

## Practical Use Cases

The scope for using this attribute is rather extensive, which means we have a significant amount of legacy code or code that we are certain is thread-safe, yet it cannot be adapted to conform to `Sendable`:

* Wrapping `Non-Sendable` Types (because of manual synchronization that provides better performance or due to other reasons)

A good example here is [how `Vapor` handle their `Model` with new concurrency system](https://blog.vapor.codes/posts/fluent-models-and-sendable/)

```swift
import Vapor

struct UserModule: ModuleInterface, @unchecked Sendable {

  func boot(_ app: Application) throws {
	 // do stuff
  }
}
```

* Legacy Code Integration (for example when legacy/system integration requires flexibility)

```swift
final class EmailContact: @unchecked Sendable {
    private var _emails: Array<Email> = []
    private let lock = NSLock()
    
    var emails: Array<Email> {
        lock.withLock { _emails }
    }
    
    @discardableResult
    func remove(at index: Int) -> Email {
        lock.withLock { _emails(at: index) }
    }
    
    func add(_ emails: PhoneNumber) {
        lock.withLock { _emails.append(emails) }
    }
}
```

* Low-Level System Wrappers

```swift
extension ArraySlice: @unchecked Sendable
  where Element: Sendable { }
```

* Actor State Snapshots
* Testing Concurrency
* and many other

Despite existing of this *danger* (as for me) attribute, u must always remember a few things that can improve it's usage:

* Document thoroughly why a type is `@unchecked Sendable`
* Prefer proper `Sendable` conformance when possible
* Write concurrent tests to verify thread safety
* Consider using `actors` as alternatives

Remember (as mentioned in official doc):

> /// To declare conformance to `Sendable` without any compiler enforcement<br>
> /// write `@unchecked Sendable`<br>
> /// You are responsible for the correctness of unchecked sendable types, <br>
> /// for example, by protecting all access to its state with a lock or a queue.
>
> [source](https://github.com/swiftlang/swift/blob/23a181730f5b6a2ce7cb6628b055944d8f602a08/stdlib/public/core/Sendable.swift#L42) 

We may compare 2 main option as follow:

| Operation                          | Runtime Cost               | Thread Safety Mechanism       | Use Case                      |
|------------------------------------|----------------------------|-------------------------------|---------------|-------------------------------|
| **`Actor`**<br> **`Sendable`**       | Low (actor hop)            | Full actor isolation          | Safe reference to actor state |
| **`@unchecked` <br> `Sendable`** | Medium (queue sync)  | Manual synchronization        | Legacy/Custom synchronization |


## Conclusion

Swift if still in active development, so we may discover something new at every corner.

Swift's `@unchecked Sendable` and `@returnsIsolated` form a powerful duo for bridging Swift's strict concurrency model with real-world programming needs.

Remember: concurrency tools are like surgical instruments—powerful when used precisely, dangerous when wielded carelessly. Choose the right tool for each task, and always know why you're reaching for the "unchecked" option.

## Resources

* [`Sendable`](https://developer.apple.com/documentation/swift/sendable) 
* [SE-0302: `Sendable` and `@Sendable` closures](https://github.com/apple/swift-evolution/blob/main/proposals/0302-concurrent-value-and-concurrent-closures.md)
* [`Sendable` vs `@Sendable`](https://www.avanderlee.com/swift/sendable-protocol-closures/)
* [Swift concurrency manifest](https://gist.github.com/lattner/31ed37682ef1576b16bca1432ea9f782)
* [Mutable state protection](https://developer.apple.com/videos/play/wwdc2021/10133/)
* [Sendable usecases](https://forums.swift.org/c/related-projects/sendable/46)