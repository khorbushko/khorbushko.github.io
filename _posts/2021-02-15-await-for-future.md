---
layout: post
comments: true
title: "await for a new  async in Swift"
categories: article
tags: [iOS, Swift, await/async]
excerpt_separator: <!--more-->
comments_id: 29

author:
- kyryl horbushko
- Lviv
---

Async tasks allow us to improve UX and use (or at least try to use) all possible power that the device could provide for us. Almost every app nowadays uses async code - from executing small, not important to heavy, possibly remote, tasks. Such behavior can greatly improve any flow and move u'r app to the next level.
<!--more-->

## The problem

Async code with callbacks provides great power to us (such as run some part of code on another thread or auto handle completion of async code, or even the possibility to provide non-blocking behavior). However, with this power comes great irresponsibility - our code can have a lot of bad things like:

- [pyramid of doom](https://en.wikipedia.org/wiki/Pyramid_of_doom_(programming)) (A sequence of simple asynchronous operations often requires deeply-nested closures)
- unclear Error handling (Callbacks make error handling difficult and very verbose)
- errors in logic (sometimes callback calls can be missed in nested conditional flows - when use guard for example)
- poor maintenance, scalability, understanding, and readability
- hard conditional execution

We have a lot of techniques to fix these issues:

- shallow code
- pack u'r code into modules
- use the monad-like style for error/data handling
- limit nesting functions calls
- reuse code
- Result type

For now, we have a few techniques that are used almost on an every-day basis - [GCD](https://developer.apple.com/documentation/DISPATCH) and [OperationQueue](https://developer.apple.com/documentation/foundation/operationqueue). And they are great - easy to use, has a lot of possibilities, very flexible, has reach documentation, but... we still should remember about the problems that were mention before, and so, use additional techniques for resolving them.

> This problem isn't new. And in other languages there is a possible solution - async/await. For example - [in c#](https://docs.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/async/):
>
> *provides an abstraction over asynchronous code. You write code as a sequence of statements, just like always. You can read that code as though each statement completes before the next begins. The compiler performs several transformations because some of those statements may start work and return a Task that represents the ongoing work.* (from the official doc).

## Async/await

Recently, [new proposal for Swift appears](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md#motivation-completion-handlers-are-suboptimal).

Interesting. As for me - this looks like one of the biggest improvements during the last time for Swift language.

Let's start from `_Concurrency` - this is an experimental framework, and so we can't use it for any production code (API may be changed), but for a test, this works just fine.

### Task

Here, we can find `Task` - a type that represents some kind of work. From doc - *" is the analog of a thread for asynchronous functions. All asynchronous functions run as part of some task."*

With this `Task` type we can run code using various options:

- `runDetached` - run as is (not recommended)
- `withDeadline` - execute a task with deadline restriction
- `withGroup` - by grouping a few tasks

> In the declaration of these functions u can find a new attribute - `@concurrent`. I found [the interesting thread on Swift forum](https://forums.swift.org/t/pitch-4-concurrentvalue-and-concurrent-closures-evolution-pitches/44446/3) related to this, also there is a note about this attribute - *"The purpose of `@concurrent` is to support function values that conform to `ConcurrentValue` and can therefore be used in contexts that require `ConcurrentValue`."*
> 
> [`ConcurrentValue`](https://docs.google.com/document/d/1m2fLLq9_ArY1ySt108soxOZNX7XT0ixMlNLFK08789M/edit) - this is protocol, that mark object as safe and ready for concurent operations (*"are safe to share across concurrently-executing code"* according to [proposal](https://github.com/DougGregor/swift-evolution/blob/actors/proposals/nnnn-actors.md#cross-actor-references-and-concurrentvalue-types)).

`Task` also has supportive functions and properties such as `currentPriority` or `cancel`/`sleep` etc. I believe this API will be extended to allow do same things as with `GCD` and `OperationQueue`.

### Actor

Another interesting type there - `Actor` - *"An actor is a form of class that protects access to its mutable state"* ([source](https://github.com/DougGregor/swift-evolution/blob/actors/proposals/nnnn-actors.md#cross-actor-references-and-concurrentvalue-types)). 

There is not much about this type in the current API, I believe it will be extended in the few next updates.

### Convert functions into new async code

The last part, that needs to be mentions - is support for existing code. If u already has some asynchronous code with closure-based callback, we can use few functions for converting it to a new async way:

{% highlight swift %}
public func withCheckedContinuation<T>(function: String = #function, _ body: (CheckedContinuation<T>) -> Void) async -> T

public func withCheckedThrowingContinuation<T>(function: String = #function, _ body: (CheckedThrowingContinuation<T>) -> Void) async throws -> T

public func withUnsafeContinuation<T>(_ fn: (UnsafeContinuation<T>) -> Void) async -> T

public func withUnsafeThrowingContinuation<T>(_ fn: (UnsafeThrowingContinuation<T>) -> Void) async throws -> T
{% endhighlight %}

### Entry point

As mention in proposal *"Because only async code can call other async code, this proposal provides no way to initiate asynchronous code. This is intentional: all asynchronous code runs within the context of a “task”"* ([source](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md#launching-async-tasks)).

This entry point may be an available function

{% highlight swift %}
public func runAsyncAndBlock(_ asyncFun: @escaping () async -> ())
{% endhighlight %}

## Practice

Better - is always to test the code - run it and feel the power :].

### Environment

To test await/async we should install beta toolchain from [here](https://swift.org/download/#snapshots). Just scroll to Trunk development (main) and download the latest version. Then install the package and switch to it in xCode settings.

If u do everything fine, then u can see blue chain link in status bar of xCode project:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-15-await-for-future/toolchain.png" alt="toolchain" width="550"/>
</div>
<br>

To use async/await in a project u have few options - use it in swift package or in the project. In both cases, u should add `-Xfrontend -enable-experimental-concurrency`. 

Put it in `Other Swift flags` in build settings for a project.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-15-await-for-future/proj-flag.png" alt="proj-flag" width="550"/>
</div>
<br>

For SP, for selected target add:

{% highlight swift %}
    .unsafeFlags([
        "-Xfrontend",
        "-enable-experimental-concurrency"
    ])
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-15-await-for-future/sp_flag.png" alt="sp_flag" width="550"/>
</div>
<br>

### Code sample

The easiest variant - to use Task, that can be run in place:

We can define next function:

{% highlight swift %}
func runMeAsync() async {
    for idx in 1...3 {
        sleep(1)
        print("\(idx) at \(Date())")
    }
}
{% endhighlight %}
 
If we try just to run it we will get an error:

{% highlight swift %}
runMeAsync() // ERR: 'async' in a function that does not support concurrency
{% endhighlight %}

Even with `async` from `Dispatch`:

{% highlight swift %}
DispatchQueue.main.async {
    await runMeAsync() // ERR: Invalid conversion from 'async' function of type '() async -> Void' to synchronous function type '@convention(block) () -> Void'
}
{% endhighlight %}

As I mention above, we need to get an entry point for the async code.

We can either:

{% highlight swift %}
let handle = Task.runDetached(operation: {
    await runMeAsync()
})
{% endhighlight %}

or

{% highlight swift %}
runAsyncAndBlock {
    try? await runMeAsync()
}
{% endhighlight %}

Both will run just fine and provide the next output:

{% highlight swift %}
Hello, world!
1 at 2021-02-15 03:56:22 +0000
2 at 2021-02-15 03:56:23 +0000
3 at 2021-02-15 03:56:24 +0000
Program ended with exit code: 0
{% endhighlight %}

Now, case when we want to reuse existing code:

{% highlight swift %}
func doSomething(_ callback: (() -> ())?) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
        print("from \(#function) \(Date())")
        callback?()
    }
}

func doSomethingAsync() async -> () {
    await withUnsafeContinuation { continuation in
        doSomething {
            continuation.resume(returning: ())
        }
    }
}

runAsyncAndBlock {
    await doSomethingAsync()
}
{% endhighlight %}

and result is:

{% highlight swift %}
from doSomething(_:) 2021-02-15 04:22:38 +0000
Program ended with exit code: 0
{% endhighlight %}

What, if we want to use result of some `async` function after `await`? Use `@asyncHandler`:

{% highlight swift %}
func doSomething(_ callback: (() -> ())?) {
    DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
        print("from \(#function) \(Date())")
        callback?()
    }
}

func doSomethingAsync2() async -> String {
    await withUnsafeContinuation { continuation in
        doSomething {
            continuation.resume(returning: #function)
        }
    }
}

@asyncHandler func doSomethingWithAsyncDataInsideFunction() {
    let result: String? = try? await doSomethingAsync2()
    print("The result is \(result), obtained in \(#function)")
}

doSomethingWithAsyncDataInsideFunction()
{% endhighlight %}

output:

{% highlight swift %}
Hello, world!
from doSomething(_:) 2021-02-15 04:49:00 +0000
The result is Optional("doSomethingAsync2()"), obtained in doSomethingWithAsyncDataInsideFunction()
Program ended with exit code: 0
{% endhighlight %}

> `@asyncHandler` functions cannot be marked as `async`

## Conclusion

As for me, this is a great improvement, that provides a better and more convenience way of async code handling. Can't await when it to become available :].

[download source code]({% link assets/posts/images/2021-02-15-await-for-future/source/async-test.zip %})


## Resources

* [Async/await for Swift](https://github.com/apple/swift-evolution/blob/main/proposals/0296-async-await.md#motivation-completion-handlers-are-suboptimal)
* [Async-await experiment](https://github.com/peterfriese/Swift-Async-Await-Experiments)
* [Toolchain download page](https://swift.org/download/#releases)
* [Using async/await in SwiftUI](https://peterfriese.dev/async-await-in-swiftui/)
* [Task API and Structured Concurrency](https://github.com/DougGregor/swift-evolution/blob/structured-concurrency/proposals/nnnn-structured-concurrency.md)
* [Concurrency Interoperability with Objective-C](https://github.com/DougGregor/swift-evolution/blob/concurrency-objc/proposals/NNNN-concurrency-objc.md)
* [`ConcurrentValue`](https://docs.google.com/document/d/1m2fLLq9_ArY1ySt108soxOZNX7XT0ixMlNLFK08789M/edit)
* [SE-0296: async/await SF](https://forums.swift.org/t/se-0296-async-await/42605/206)
* [Getting started with async/await in Swift](https://www.enekoalonso.com/articles/getting-started-with-async-await-in-swift)
* [Simple example involving structured concurrency](https://forums.swift.org/t/simple-example-involving-structured-concurrency/43424/2)
* [Pitch #4: ConcurrentValue and @concurrent closures Evolution Pitches](https://forums.swift.org/t/pitch-4-concurrentvalue-and-concurrent-closures-evolution-pitches/44446)