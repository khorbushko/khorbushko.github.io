---
layout: post
comments: true
title: "Understanding @preconcurrency in Swift"
categories: article
tags: [swift, preconcurrency]
excerpt_separator: <!--more-->
comments_id: 109

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

Swift's `@preconcurrency` attribute is a powerful tool introduced to help developers integrate legacy APIs into Swift's modern concurrency model. It ensures compatibility and suppresses compiler warnings when working with older APIs that are not explicitly marked as concurrency-safe.
<!--more-->

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-11-29-preconcurrency_swift/img.webp">
<img src="{{site.baseurl}}/assets/posts/images/2024-11-29-preconcurrency_swift/img.webp" alt="range_slider_no_pattern.png" width="400"/>
</a>
</div>
<br>
<br>


### What is `@preconcurrency`?

The `@preconcurrency` attribute is used to mark types, functions, or protocol conformances that were designed before Swift's concurrency features (`async/await`, `actors`, etc.). It informs the compiler that these APIs are safe to use in concurrent contexts, even though they may not conform to `Sendable` or other concurrency requirements.



### Why is `@preconcurrency` Needed?

Swift’s concurrency model enforces strict thread safety rules, such as requiring types used in concurrent contexts to conform to `Sendable`. When working with legacy APIs that predate these rules, you may encounter warnings or errors. The `@preconcurrency` attribute bridges this gap by:

1. Suppressing concurrency-related warnings for legacy code.
2. Enabling developers to integrate legacy APIs without sacrificing safety or functionality.



### How to Use `@preconcurrency`

The `@preconcurrency` attribute can be applied to:
- Classes, structs, and enums.
- Protocol conformances.
- Functions or methods.



#### **Example 1: Marking Types**

Here’s how to mark a legacy class with `@preconcurrency` to suppress concurrency warnings:

```swift
@preconcurrency
class LegacyAPIWrapper {
    func fetchData() {
        print("Fetching data from legacy API...")
    }
}

let wrapper = LegacyAPIWrapper()

Task {
    await withCheckedContinuation { continuation in
        wrapper.fetchData()
        continuation.resume()
    }
}
```

This ensures the `LegacyAPIWrapper` can be used safely in concurrent contexts.



#### **Example 2: Marking Protocol Conformances**

Suppose a protocol predates Swift's concurrency model. You can use `@preconcurrency` to mark a conforming class as compatible.

```swift
protocol LegacyProtocol {
    func performTask()
}

@preconcurrency
class ConformingClass: LegacyProtocol {
    func performTask() {
        print("Performing task in a legacy way...")
    }
}

let conformingInstance = ConformingClass()

Task {
    await withCheckedContinuation { continuation in
        conformingInstance.performTask()
        continuation.resume()
    }
}
```



#### **Example 3: Combining `@MainActor` with `@preconcurrency`**

Using `@MainActor` ensures a method or class operates on the main thread. When combined with `@preconcurrency`, you can suppress warnings for legacy APIs like `UIDevice`.

##### **Scenario: Updating UI Based on Device Orientation**

```swift
import UIKit

@MainActor
@preconcurrency
class OrientationHandler {
    func handleOrientationChange() {
        let device = UIDevice.current
        
        switch device.orientation {
        case .portrait:
            print("Device is in portrait mode")
        case .landscapeLeft, .landscapeRight:
            print("Device is in landscape mode")
        default:
            print("Device orientation is unknown")
        }
    }
}

let handler = OrientationHandler()

Task { @MainActor in
    handler.handleOrientationChange()
}
```

**Why `@preconcurrency`?**  
`UIDevice` predates Swift's concurrency model and is not `Sendable`. Adding `@preconcurrency` ensures safe usage of `UIDevice` within an `@MainActor` context.



## Conclusion

- `@preconcurrency` helps integrate legacy APIs into Swift's concurrency model.
- It suppresses warnings for types or protocols not marked as `Sendable`.
- Combining `@MainActor` with `@preconcurrency` is especially useful for UI-related legacy APIs.



## Resources

- [Swift Concurrency Documentation](https://swift.org/documentation/concurrency)
- [SE-0302: Sendable and @unchecked Sendable](https://github.com/apple/swift-evolution/blob/main/proposals/0302-sendable-and-unchecked.md)
- [Swift Forums: Discussion on `@preconcurrency`](https://forums.swift.org/)
