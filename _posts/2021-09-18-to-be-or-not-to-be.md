---
layout: post
comments: true
title: "To be, or not to be, that is the question"
categories: article
tags: [swift, SIL, dispatch]
excerpt_separator: <!--more-->
comments_id: 58

author:
- kyryl horbushko
- Lviv
---

Calling a method or a function is pretty simple - u just use dot notation. But how compiler know which function to call? What to select if a type has an inheritance. And how about protocols? 

Knowing internal processes that are used for this and other similar activities can help u a lot, especially when u try to understand how the code is working and why u receive such a result.
<!--more-->

> My motivation for this article was a too often unexpected explanation about dispatch process in swift that I heard during various discussions of this topic with other developers. 
> 
> So, here I tried to cover the most interesting and fundamental parts that are needed for any iOS developer.

## Dispatch vs Binding

Invoking a method or a function is a special process that has various names, often known as dispatch. There are a few types of dispatch. But, before moving in any direction from this point, I'd suggest looking at the definition related to dispatch.

We can found a few different types of dispatch that are used in different languages:

- **static** (**direct**) dispatch - *" a form of polymorphism fully resolved during compile time"* (there is also a case where  *"the compiler can locate where the instructions are, at compile time"*, and this named sometimes as **inline** dispatch)
- **dynamic** (**table**, **message**) dispatch - *"the process of selecting which implementation of a polymorphic operation (method or function) to call at run time"*

Dispatch works closely with other processes - type determining. 

This can be a tricky process. We all (maybe :]) love the power of compiler that allows us to suggest and predict methods/functions/props related to a certain type and (more important) protect us from stupid mistakes. 

In general, a type can be known or unknown before checking at runtime. As result, 2 main categories are used for type-check:

- late binding (dynamic binding/linking) - *"a particular operation or object at runtime, rather than during compilation"*
- early binding (static binding/linking) - *"an operation during compilation phase when all types of variables and expressions are fixed"*

Now we can see 2 different processes here - binding and dispatching. These 2 are often misunderstood: 

**Binding** is a process that refers to associating a name with some operation.

**Dispatching** is a process that refers to choosing a concrete implementation for the operation after binding (associating a name with some operation).

## swift, objC, and dispatch

Let's think for a moment about cases when we dispatch can be used:

- from value type (`struct`, `enum` etc)	- func
	- property
- from ref type (`class`, `actor`)
	- inherited obj
	- func
	- property
- from `protocol`
	- function defined in protocol requirements
	- function added in extension without protocol requirements
	- property
	- `PAT`s
	- inherited protocol
- from extensions
- from generics
- from `NSObject`

Additionally, some modifiers/attributes also can change the dispatch:

- `@objc` and `@nonobjc`
- `final`
- `dynamic`
- `@inline`

A lot of things).

Let's dive into some details.

First of all, as u can see there are a few "values" that can be dispatched:

- function/method
- property

Also, it's good to mention that static dispatch is available for both ref and value types, but dynamic - only to ref types. Before moving to the next points, let's look into how different dispatch types work.

### Dynamic dispatch

This technique allows to use us polymorphism. The downside of such dispatch - it's a time cost - whenever compiler calls something and uses dynamic dispatch the witness table is used (same as [virtual table](https://en.wikipedia.org/wiki/Virtual_method_table) in other languages). The witness table is used to determine the implementation, thus this process looking for some memory, this can't be done before runtime.

There are a few types of dynamic dispatch:

- table (witness or [virtual](https://en.wikipedia.org/wiki/Virtual_method_table)) dispatch - use a collection of addresses and names assigned to each address. Every class, the subclass has its witness table. Every piece of the entities is described inside.

> You can check header file for [`SILWitnessTable`](https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/include/swift/SIL/SILWitnessTable.h) and look for [doc](https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/OptimizationTips.rst#reducing-dynamic-dispatch), that describe dynamic dispatching and ways that can be used for optimization/changing dispatch

- message dispatch - Objective-C messages are dispatched using the runtime's `objc_msgSend()` function (min 2 params are used - received obj, selector and optionally variables if present). This dispatch is slower than table dispatch. Supportive info stored in `isa` pointer. The system also can cache selectors and addresses. 

> Thanks to message dispatch we were able to use method swizzling, forward invocation, and few other techniques. More - look [here](https://www.mikeash.com/pyblog/friday-qa-2009-03-20-objective-c-messaging.html)

### Static dispatch

This kind of dispatch is used when all information is available before the runtime - the compiler directly jumps to the memory address without check. With some optimization (inlining) this process can be very fast.

There is also [a few techniques](https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/OptimizationTips.rst#reducing-dynamic-dispatch), that can convert default dynamic dispatch into static dispatch in swift:

- `final` keyword for a class, method, or a property
- `private` and `fileprivate`
- Whole Module Optimization can change dispatch

> One more [article about performance](https://developer.apple.com/swift/blog/?id=27)

> It's also useful to read the [swift changelog ](https://github.com/apple/swift/blob/b371b44c4cea60170210f55b55f03b2554581799/CHANGELOG.md). Here are a few words (hint) about the `final` keyword - *"This attribute prevents overriding the declaration in any subclass and provides better performance (since dynamic dispatch is avoided in many cases)."*

### What dispatch used and when?

Using all described above, we can create next table where different dispatch usage described:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-09-18-to-be-or-not-to-be/dispatch.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-09-18-to-be-or-not-to-be/dispatch.png" alt="dispatch_call" width="550"/>
</a>
</div>
<br>
<br>

## SIL

I already wrote a few articles about [SIL language](https://github.com/apple/swift/blob/main/docs/SIL.rst) and how it can be used in practice. To check dispatch we also can use SIL.

In SIL, every dispatch type has specific name - if we look at content of the [SIL language](https://github.com/apple/swift/blob/main/docs/SIL.rst) doc, we can easelly find:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-09-18-to-be-or-not-to-be/SIL_dynamicDispatch.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-09-18-to-be-or-not-to-be/SIL_dynamicDispatch.png" alt="dispatch_SIL" width="350"/>
</a>
</div>
<br>
<br>

> Another hint regarding dispatch can be obtained from [mangled](https://github.com/apple/swift/blob/0cd0cbc02adf2f794570cf102fde08089d7fdae2/docs/ABI/Mangling.rst) name:
{% highlight swift %}
global ::= global 'TD'                 // dynamic dispatch thunk
{% endhighlight %}

For Obj-C dynamic dispatch, there is should be `volatile`, `objc_method`, or `foreign`.

> This hint I found on [this](https://trinhngocthuyen.github.io/posts/tech/method-dispatch-in-swift/) blog

All calls without these marks use static dispatch.

To check our notes, we can write some demo code, generate SIL and check the actual dispatch.

{% highlight swift %}
import Foundation

class Foo { 
	func myFunc_0() {}
	@objc func myFunc_1() {}
}

final class Bar {
	final func myFunc_1() {}
}

struct FooBar {
	func myFunc_2() {}
}
{% endhighlight %}

with command `swiftc -O -emit-silgen /Users/khb/Desktop/test_dispatch.swift > OUTPUT.rawsil` we can generate SIL and check it for keywords described above.

I won't put everything from SIL, instead here is a few examples:

Dynamic dispatch:

table:

{% highlight sil %}
sil_vtable Bar {
  #Bar.init!allocator: (Bar.Type) -> () -> Bar : @$s13test_dispatch3BarCACycfC	// Bar.__allocating_init()
  #Bar.deinit!deallocator: @$s13test_dispatch3BarCfD	// Bar.__deallocating_deinit
}
{% endhighlight %}

message (`objc_method`):

{% highlight sil %}
// @objc Foo.myFunc_1()
sil hidden [thunk] [ossa] @$s13test_dispatch3FooC8myFunc_1yyFTo : $@convention(objc_method) (Foo) -> () {
{% endhighlight %}

Static dispatch:

{% highlight sil %}
// FooBar.myFunc_2()
sil hidden [ossa] @$s13test_dispatch6FooBarV8myFunc_2yyF : $@convention(method) (FooBar) -> () {
{% endhighlight %}

## Pitfalls

### Protocol extension method without protocol requirements

Something, dispatch can provide unclear results. A good example posted in official doc [here](https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/GenericsManifesto.md#dynamic-dispatch-for-members-of-protocol-extensions) - usage of different dispatch types for different code-base can lead to unexpected results in the protocol:

{% highlight swift %}
protocol P {
  func foo()
}

extension P {
  func foo() { print("P.foo()") }
  func bar() { print("P.bar()") }
}

struct X : P {
  func foo() { print("X.foo()") }
  func bar() { print("X.bar()") }
}

let x = X()
x.foo() // X.foo()
x.bar() // X.bar()

let p: P = X()
p.foo() // X.foo()
p.bar() // P.bar()
{% endhighlight %}

> Example from the [link above](https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/GenericsManifesto.md#dynamic-dispatch-for-members-of-protocol-extensions)

### Memory representation of the protocol

Another moment - memory representation for types, that are created within protocols. The type that implements protocol may require a different amount of words - depends on parameters and methods inside the type. Now, how we can represent the same thing in memory if it may have various sizes?

> A *"Word"* - is a set of bits native for a given arch - 32 or 64 for example.

The answer here - existential container (exist - something is inside). The structure of this container is a bit another topic. The interesting thing is that this container has a witness table (VWT) for value and a protocol (PWT). So the more protocol we use at a type (or for protocol composition `&`) the bigger size for the existential container will be (thus additional address (word) added to PWT). 

{% highlight swift %}
protocol Foo { }
protocol Bar { }
typealias FooBar = Foo & Bar

let sizeOfFoo = MemoryLayout<Foo>.size
print(sizeOfFoo)
let sizeOfFooBar = MemoryLayout<FooBar>.size
print(sizeOfFooBar)
{% endhighlight %}

Output:

{% highlight swift %}
40
48
{% endhighlight %}

> 1 Protocol + 1 word. I have a 64-bit machine, so the word is 64 bit or 8 bytes. And here u can see the diff

That is the hidden cost of the POP in Swift (protocol-oriented programming).

### Keywords combination

Be careful when combining various keywords - some of them do create not very obvious results:

Which dispatch will be here?

{% highlight swift %}
class Bar {
	@inline(__always) // should be static dispatch
	dynamic  // should be dynamic dispatch
	func interesting() { }
}
{% endhighlight %}

To check the result, we can inspect SIL:

{% highlight sil %}
sil_vtable Bar {
  #Bar.interesting: (Bar) -> () -> () : @$s22test_combined_keywords3BarC11interestingyyF	// Bar.interesting()
...
{% endhighlight %}

Thus this method in the witness table-use dynamic dispatch.

So `@inline` it's just a kind of hint for the compilator, not the requirements.

## Bugs

Everyone can make an error. [Here](https://bugs.swift.org/browse/SR-12753?jql=text%20~%20%22dynamic%20dispatch%22) and [here](https://bugs.swift.org/browse/SR-7039?jql=text%20~%20%22static%20dispatch%22) a bugs related to dispatch on Swift board. Some of them are already closed.

> The most interesting one (a bit outdated, but still interesting) u can find at the end of [this great article](https://www.rightpoint.com/rplabs/switch-method-dispatch-table)

## My principles

My rule - always try to do the task at least for 101%. Using info from above, we now can try to always improve our code by reducing dynamic dispatch as much as possible - this will provide a performance boost for our code. 

I already put a link to [this](https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/OptimizationTips.rst#reducing-dynamic-dispatch) official post with a hint, but to make things better in everyday life I follow few next rules:

- think before creating a class, maybe u need a struct
- always when creating a class marks it as a final
- all functions should have access modifiers
- avoid very big inheritance model, thus this will produce a longer time for resolving in dynamic dispatch
- follow POP, but not make the thing too abstract and too complicated, because this will reduce not only understandability but and performance and memory needed
- location of the function/methods matter - think about the usage of u'r functionality - if u need better performance, u can also improve this using static dispatch (in cost to some flexibility)
- use `final`, `dynamic`, `static`, `@objc`, `@inlinable` (`@inline(__always)`) - as a shortcut to change dispatch
 
## Resources

* [Dynamic dispatch](https://en.wikipedia.org/wiki/Dynamic_dispatch)
* [Static dispatch](https://en.wikipedia.org/wiki/Static_dispatch)
* [Late binding](https://en.wikipedia.org/wiki/Late_binding)
* [Early vs late binding](https://softwareengineering.stackexchange.com/questions/200115/what-is-early-and-late-binding/200123#200123)
* [SO - What is the difference between dynamic dispatch and late binding in C++?](https://stackoverflow.com/questions/20187587/what-is-the-difference-between-dynamic-dispatch-and-late-binding-in-c)
* [Virtual table](https://en.wikipedia.org/wiki/Virtual_method_table)
* [SIL](https://github.com/apple/swift/blob/main/docs/SIL.rst)
* [SO - Whose witness table should be used?](https://stackoverflow.com/questions/55508918/whose-witness-table-should-be-used)
* [Friday Q&A 2009-03-20: Objective-C Messaging](https://www.mikeash.com/pyblog/friday-qa-2009-03-20-objective-c-messaging.html)
* [Writing High-Performance Swift Code](https://github.com/apple/swift/blob/7123d2614b5f222d03b3762cb110d27a9dd98e24/docs/OptimizationTips.rst#reducing-dynamic-dispatch)
* [Method dispatch in swift](https://trinhngocthuyen.github.io/posts/tech/method-dispatch-in-swift/)
* [Method Dispatch in Swift](https://www.rightpoint.com/rplabs/switch-method-dispatch-table)
* [Increase performance by reducing dispatch](https://developer.apple.com/swift/blog/?id=27)