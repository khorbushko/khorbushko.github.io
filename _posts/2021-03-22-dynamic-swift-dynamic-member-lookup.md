---
layout: post
comments: true
title: "Dynamic swift - Part 2: @dynamicMemberLookup/@dynamicCallable"
categories: article
tags: [Swift, dynamicMemberLookup, dynamicCallable]
excerpt_separator: <!--more-->
comments_id: 34

author:
- kyryl horbushko
- Lviv
---

In this article, I would like to explore one more dynamic feature available in the Swift language - `@dynamicMemmberLookup`.

This new attribute introduce new behavior in Swift - something more related to scripting languages, but with swift type-safety. This attribute makes it possible to execute a subscript of an object when someone accessing properties.
<!--more-->

This feature was added in Swift 4.2.

**Related articles:**

- [Dynamic swift - Part 1: KeyPath]({% post_url 2021-03-13-dynamic-features-part-1 %})
- Dynamic swift - Part 2: @dynamicMemberLookup
- [Dynamic swift - Part 3: Opposite to @dynamicCallable - static Callable]({% post_url 2021-03-30-dynamic-swift-callable %})
- [Dynamic swift - Part 4: @dynamicReplacement]({% post_url 2021-01-11-do-that-instead-of-this %})

## introduction

According to [Swift doc](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html) - *"Apply this attribute to a class, structure, enumeration, or protocol to enable members to be looked up by name at runtime. The type must implement a `subscript(dynamicMemberLookup:)` subscript."*

The purpose of this attribute - is a simplification of the code by adding some syntax sugar into it. We can create a wrapper around some data. This data may be one, that can't be checked at compile-time (so, in theory not type-safe). If we apply this to type - requested property value also will be checked at runtime, this means, that we can request property that even not exist.
Access to this data will be achieved by using `subscript(dynamicMemberLookup:)`. The parameter name must conform to `ExpressibleByStringLiteral` or `KeyPath`, and return type - any Type u like.

## practical usage

### @dynamicMemberLookup

To use this feature u should mark u'r type with attribute @dynamicMemberLookup and declare subscript with a parameter that conforms to `ExpressibleByStringLiteral` or `KeyPath` and return any type. An external name for the parameter should be *dynamicMember*.

U can also have a few overloaded subscripts in type.


{% highlight swift %}
@dynamicMemberLookup
class Foo {

  subscript(dynamicMember lookUp: String) -> String {
    switch lookUp {
      case "a"..<"d":
        return "hello"
      default:
        return " world"
    }
  }
}

let foo = Foo()
// generate dynamic members that does not exist
print(foo.a, foo.z)

// Output:
// hello  world
{% endhighlight %}

Using `KeyPath`, thing become even better - we can access to properties of instance variables by omitting the name of the selected variable:

{% highlight swift %}
struct FooBar {
  var variable1: String
  var variable2: String
}

@dynamicMemberLookup
final class Bar {

  subscript<T>(
    dynamicMember keyPath: WritableKeyPath<FooBar, T>
  ) -> T {
    get { fooBar[keyPath: keyPath] }
    set { fooBar[keyPath: keyPath] = newValue }
  }

  private(set) var fooBar: FooBar

  // MARK: - Lifecycle

  init(fooBar: FooBar) {
    self.fooBar = fooBar
  }
}

var bar = Bar(
  fooBar: FooBar(
    variable1: "hello",
    variable2: " world"
  )
)
let firstVariable: String = bar.variable1
let secondVariable: String = bar.variable2
print(firstVariable, secondVariable)

// Output:
// hello  world
{% endhighlight %}

> read more about [KeyPath]({% post_url 2021-03-13-dynamic-features-part-1 %})

I use this possibility not very often because as for me, it reduces understandability and readability of code - when u omit in the message chain a name of a variable that u use, u need additional time to inspect the code. 

Also, such an approach hides from us a well-known problem with type coupling - [Message Chains](https://refactoring.guru/smells/message-chains).

> *A message chain occurs when a client requests another object, that object requests yet another one, and so on. These chains mean that the client is dependent on navigation along with the class structure. Any changes in these relationships require modifying the client.* [source](https://refactoring.guru/smells/message-chains).

### @dynamicCallable

This attribute, as mention in [proposal](https://github.com/apple/swift-evolution/blob/master/proposals/0216-dynamic-callable.md) - natural extension to `@dynamicMemberLookup`.

As result, we can mark a type (a class, structure, enumeration, or protocol) as being directly callable.

> `@dynamicCallable` is the natural extension of  `@dynamicMemberLookup` [SE-0195](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md), and serves the same purpose: to make it easier for Swift code to work alongside dynamic languages such as Python and JavaScript [fom Paul Hudson's article"](https://www.hackingwithswift.com/articles/134/how-to-use-dynamiccallable-in-swift)

To make u'r type conforming to this attribute, u should declare `dynamicallyCall(withArguments:)` method or/and `dynamicallyCall(withKeywordArguments:)` method.

> If you implement both `dynamicallyCall` methods, `dynamicallyCall(withKeywordArguments:)` is called when the method call includes keyword arguments. In all other cases, `dynamicallyCall(withArguments:)` is called.

`dynamicallyCall(withArguments:)` require a variadicparameter, that will become an array. For example: `1,2,3` will be transformed into `[1,2,3]`.

`dynamicallyCall(withArguments:)` this method use instance of type as a function name and call it with named arguments with the specified type. For example, if we call `object(key: value)` where value is of type `Int`, inside the function we get `args` equal to `["key": value]`.

I prefer a simple example, that allows quickly understand how things work. So here one:

{% highlight swift %}
@dynamicCallable
class FooFoo {

  func dynamicallyCall(
    withKeywordArguments args: KeyValuePairs<String, Int>
  ) -> String {
    "do something with keyword args \(args)"
  }

  func dynamicallyCall(
    withArguments args: [Int]
  ) -> String {
    "do something with args \(args)"
  }

}

let foofoo = FooFoo()
print(foofoo(value: 111))
print(foofoo(111))

// Output:
// do something with keyword args ["value": 111]
// do something with args [111]
{% endhighlight %}

`@dynamicCallable` and `@dynamicMemberLookup` may be used on one type:

{% highlight swift %}
@dynamicCallable
@dynamicMemberLookup
struct Foo {
	// implementation
}
{% endhighlight %}

For now, I can't see where we can get "win" from this attribute while using just Swift, but definitely, for other developers, there is must be a big "win" here (for one who works with Python, JavaScript, Ruby, or some other domain-specific-language - definitely, thus they describe the purpose in the original proposal).

Again, Swift was created as a very type-safe language, but such dynamism can throw away this idea. The good point here is that all understood this, and as result, we may use `@dynamicMemberLookup` within `KeyPath`, which makes its usage a bit safer.

> If u like an idea about using an object as a function, u may check [Callable feature](https://github.com/apple/swift-evolution/blob/master/proposals/0253-callable.md), which is a "static" feature.
<br>

[download source code]({% link assets/posts/images/2021-03-22-dynamic-swift-dynamic-member-lookup/source/play.playground.zip %})
<br>
<br>

**Related articles:**

- [Dynamic swift - Part 1: KeyPath]({% post_url 2021-03-13-dynamic-features-part-1 %})
- Dynamic swift - Part 2: @dynamicMemberLookup
- [Dynamic swift - Part 3: Opposite to @dynamicCallable - static Callable]({% post_url 2021-03-30-dynamic-swift-callable %})
- [Dynamic swift - Part 4: @dynamicReplacement]({% post_url 2021-01-11-do-that-instead-of-this %})

## Resources

- [Introduce User-defined "Dynamic Member Lookup" Types](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md)
- [Swift doc](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html)
- [Introduce user-defined dynamically "callable" types](https://github.com/apple/swift-evolution/blob/master/proposals/0216-dynamic-callable.md)
- [How @dynamicMemberLookup Works Internally in Swift (+ Creating Custom Swift Attributes)](https://swiftrocks.com/how-dynamicmemberlookup-works-internally-in-swift)
