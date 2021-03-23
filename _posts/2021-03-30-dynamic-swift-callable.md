---
layout: post
comments: true
title: "Dynamic swift - Part 3: Opposite to @dynamicCallable - static Callable"
categories: article
tags: [Swift, callable]
excerpt_separator: <!--more-->
comments_id: 35

author:
- kyryl horbushko
- Lviv
---

Use an object as a function is one more addition, that we have in Swift. This proposal was described on [SE-253](https://github.com/apple/swift-evolution/blob/master/proposals/0253-callable.md). And was added in Swift 5.2. 
<!--more-->

Last time we reviewed [`@dynamicCallable`]({% post_url 2021-03-22-dynamic-swift-dynamic-member-lookup %}) feature - a dynamic possibility to use object as a function. Callable addition allows u also do the same things, but statically.

> This article's series about dynamic features of the swift language, but, I just want to show, that we always have a choice - and here is a sample of it.

**Related articles:**

- [Dynamic swift - Part 1: KeyPath]({% post_url 2021-03-13-dynamic-features-part-1 %})
- [Dynamic swift - Part 2: @dynamicMemberLookup/@dynamicCallable]({% post_url 2021-03-22-dynamic-swift-dynamic-member-lookup %})
- Dynamic swift - Part 3: Opposite to @dynamicCallable - static Callable
- [Dynamic swift - Part 4: @dynamicReplacement]({% post_url 2021-01-11-do-that-instead-of-this %})

## Callable

From [proposal](https://github.com/apple/swift-evolution/blob/master/proposals/0253-callable.md) - *"Callable values are values that define function-like behavior and can be called using function call syntax"*.

Another name for this feature - *"Instance as a Function"*. We may have a situation when some object is created just to execute one function - in such cases, it's better to treat such an object as a function. That's the main idea behind callable.

To do so, we simply should add a function named `callAsFunction` with any parameters - one or few, generic, tuple, closure, etc.

{% highlight swift %}
class Random {

  func callAsFunction(_ range: Range<Int>) -> Int {
    Int.random(in: range)
  }
}

let random = Random()
let num = random(0..<100) // 9
{% endhighlight %}

Here, `random(0..<100)` is a sugar. under the hood, we use ourobject as a function, we may create next alternative for this code:

{% highlight swift %}
func generateRandom() -> (_ range: Range<Int>) -> Int {
	{ inputRange in Int.random(in: inputRange) }
}

let num2 = random.generateRandom()(0..<100) // 50
{% endhighlight %}

So, `callAsFunction` rather than produce a function (like `generateRandom` do), can execute this function directly - so instance became a function.

We can use generics as well:

{% highlight swift %}
func callAsFunction<T>(_ range: Range<T>) -> T where T: FixedWidthInteger {
	T.random(in: range)
}

let lowerBounds: UInt8 = 0
let upperBounds: UInt8 = .max
let num3 = random(lowerBounds..<upperBounds)
{% endhighlight %}

> You can have a few overloads of `callAsFunction` in the same type - instance will behave as it an overloaded function.
<br>

[download source code]({% link assets/posts/images/2021-03-30-dynamic-swift-callable/source/play.playground.zip %})
<br>

**Related articles:**

- [Dynamic swift - Part 1: KeyPath]({% post_url 2021-03-13-dynamic-features-part-1 %})
- [Dynamic swift - Part 2: @dynamicMemberLookup/@dynamicCallable]({% post_url 2021-03-22-dynamic-swift-dynamic-member-lookup %})
- Dynamic swift - Part 3: Opposite to @dynamicCallable - static Callable
- [Dynamic swift - Part 4: @dynamicReplacement]({% post_url 2021-01-11-do-that-instead-of-this %})

## Resources

- [Callable values of user-defined nominal types](https://github.com/apple/swift-evolution/blob/master/proposals/0253-callable.md)
- [Static and Dynamic Callable Types in Swift](https://nshipster.com/callable/)