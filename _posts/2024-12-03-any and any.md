---
layout: post
comments: true
title: "any and Any"
categories: article
tags: [swift, any, Any]
excerpt_separator: <!--more-->
comments_id: 111

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

Swift is a powerful, expressive programming language developed by Apple for building software across its ecosystem. One of the most important features of Swift is its strong type system, which helps developers write robust, predictable, and easy-to-maintain code. 
<!--more-->

However, Swift also provides mechanisms to work with types in a more flexible and dynamic way, which is where the keywords `any` and `Any` come into play. These keywords are important for handling situations where the exact type of an object is unknown or when you're dealing with multiple types under a common abstraction.

## Historical Context and Evolution in Swift

**Early Swift**: In the early versions of Swift, protocol types were used directly (e.g., `Drawable`), but the distinction between a protocol and a concrete type was less clear.

**Swift 5.9**: The introduction of the `any` keyword provided better clarity and type safety when working with protocols. This change was made to align Swift with modern best practices around type safety and code clarity.

**Actors in Swift’s Evolution**:
Chris Lattner: As the original creator of Swift, Lattner’s vision was to build a safe and performant language. Features like Any and any are part of this mission to create a flexible yet safe environment for developers.

**Swift Evolution Community**: The Swift Evolution community, which is a collaborative group of developers, Apple engineers, and other contributors, discussed and refined the introduction of `any` over multiple Swift versions. The Swift forums are the primary place for proposals, discussions, and feedback regarding these features.

## The `Any` Keyword in Swift

The `Any` keyword is one of Swift’s most fundamental type placeholders. 

It allows a variable to hold any type of value, whether it’s a class, struct, enum, or even a closure. Essentially, `Any` is the most general type, and it can be used to represent any type of object.

**Purpose of `Any`**

* **Type Flexibility**: Any allows you to write more general and flexible code that works with any data type.

* **Type Erasure**: When the specific type isn’t known or needed, Any can be used as a placeholder for any type.

* **Working with Heterogeneous Collections**: If you want to store different types of objects in an array or other collection, you can use `Any` to hold them.

{% highlight swift %}
var anything: Any

anything = 12  // An integer
print(anything)  // Output: 12

anything = "Hello, world!"  // A string
print(anything)  // Output: Hello, world!

anything = [1, 2, 3]  // An array
print(anything)  // Output: [1, 2, 3]
{% endhighlight %}

In this example, the variable `anything` can store different types of values like integers, strings, and arrays because it is declared as type Any.

## The `any` Keyword in Swift (Introduced in Swift 5.9)

In Swift 5.9, a new keyword any was introduced as a modifier to denote an "**existential type**," particularly in the context of protocols. While `Any` is a general-purpose type placeholder, `any` is used for a more specific scenario—when you're working with protocol types and you need to specify that an object conforms to a protocol but don't care about the exact type.

> **Existential Types in Swift**
> 
Existential types in Swift represent values that conform to a specified protocol without specifying their concrete type. This abstraction allows for flexibility when designing APIs, as the exact type is hidden behind the protocol.
>
> {% highlight swift %} 
protocol Drawable {
    func draw()
}

func render(shape: any Drawable) {
    shape.draw()
}
{% endhighlight %}
>
> In the above, any `Drawable` is an existential type, meaning the function render can accept any value that conforms to the `Drawable` protocol.
> 
>
> +--------------------------+<br>
>  Existential Type    <br>
> +--------------------------+<br>
> Protocol Metadata  ----------> Indicates the protocol the type conforms to.<br>
> Value Storage      ----------> Holds the actual value (e.g., Circle or Rectangle).<br>
> +--------------------------+<br>
>
> Here’s how this works:
> 
> **Protocol Metadata**: Contains information about the protocol (e.g., `Drawable`) that the value conforms to.
> 
> **Value Storage**: Stores the actual type conforming to the protocol, such as `Circle` or `Rectangle`.
> 
> **Key Characteristics**
> 
> **Dynamic Dispatch**: Method calls on existential types are dispatched dynamically based on the underlying type.
> 
> **Encapsulation**: Existential types encapsulate their concrete implementation details, exposing only protocol-defined functionality.
> Existential types offer a balance between flexibility and abstraction, making them a powerful tool for generic programming in Swift.
>
>

**Purpose of `any`**

* **Protocol Existentials**: The any keyword is used to define a type that conforms to a protocol, without specifying which exact type is being used. This is particularly useful for abstracting code to work with *any* type that conforms to a given protocol.

* **Improving Type Safety**: Using any in protocols makes the distinction clearer between concrete types and protocol-constrained types.

* **Eliminating Ambiguity**: Before Swift 5.9, protocol types used to be referred to simply by their name (e.g., SomeProtocol), but this could lead to confusion about whether it was a protocol or a concrete type. The introduction of any helps avoid such ambiguity.

{% highlight swift %}
protocol Drawable {
    func draw()
}

struct Circle: Drawable {
    func draw() {
        print("Drawing a circle")
    }
}

struct Square: Drawable {
    func draw() {
        print("Drawing a square")
    }
}

func renderShape(shape: any Drawable) {
    shape.draw()
}

let circle = Circle()
let square = Square()

renderShape(shape: circle)  // Output: Drawing a circle
renderShape(shape: square)  // Output: Drawing a square
{% endhighlight %}

Here, any `Drawable` indicates that `renderShape` accepts any object that conforms to the `Drawable` protocol. This helps make the code more flexible and avoids having to explicitly specify the exact type of the object passed to the function.


## Key Differences Between Any and any

**Usage Context:**

* `Any` can hold any type, including non-protocol types like Int, String, etc.
* `any` is used specifically to refer to objects that conform to a protocol.

**Type Safety:**

* When using `Any`, you may need to cast the value to its original type to access specific properties or methods.
* With `any`, the protocol constraints ensure the object behaves according to the protocol.

**Type Erasure:**

* `Any` is a form of type erasure for values of any type.
* `any` enables type erasure for protocol types, but the value still conforms to the specified protocol.


##Conclusion

Both `Any` and `any` serve essential purposes in Swift’s type system, offering flexibility and abstraction when handling unknown or diverse types. While `Any` is a more general-purpose placeholder for any type, `any` provides a clearer and more type-safe way to handle protocol-constrained types. 

The introduction of the any keyword in Swift 5.9 reflects a growing emphasis on clarity and safety in Swift’s evolving language design. Understanding these keywords helps developers write more flexible, maintainable, and type-safe code, which is crucial for building robust Swift applications.

## Resources

* [Apple Developer Documentation](https://developer.apple.com/documentation/swift/any)
* [Swift Evolution Proposal for `any` Keyword](https://github.com/apple/swift-evolution/blob/main/proposals/0301-any.md)
* [Search for specific questions on `Any` and `any`](https://stackoverflow.com/)
