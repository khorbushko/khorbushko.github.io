---
layout: post
comments: true
title: "any and some"
categories: article
tags: [swift, any, some, keywords]
excerpt_separator: <!--more-->
comments_id: 114

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---


Swift introduces the `any` and `some` keywords to handle protocol types with clarity and intent. These keywords serve complementary purposes and are used to distinguish between existential and opaque types.
<!--more-->

Related posts:

- [any and Any]({% post_url 2024-12-03-any and any %})
- any and some

## The `any`

### Purpose

The `any` keyword is used to define **existential types**, meaning "a type that conforms to a protocol, but whose specific type is hidden." It is useful when you want to work with *any instance* that conforms to a protocol without caring about its exact type.

### Example

```swift
protocol Drawable {
    func draw()
}

func render(shape: any Drawable) {
    shape.draw()
}

let circle = Circle()  // Circle conforms to Drawable
render(shape: circle)  // Works with any type conforming to Drawable
```

### Key Characteristics

- **Type Erasure**: The exact type is not preserved. You only know it conforms to the protocol.
- **Dynamic Dispatch**: Calls to protocol methods are dynamically dispatched.
- **Use Case**: When you want flexibility and don’t need the compiler to track the exact type.


## The `some`

### Purpose

The `some` keyword is used to define **opaque types**, meaning "a specific type that conforms to a protocol, but whose identity is hidden from the caller." It is useful when you want to return a single, specific type that conforms to a protocol but don’t want to expose its exact type in the function signature.

### Example

```swift
protocol Drawable {
    func draw()
}

struct Circle: Drawable {
    func draw() {
        print("Drawing a circle")
    }
}

func createCircle() -> some Drawable {
    return Circle()
}

let shape = createCircle()
shape.draw()  // Works, but the actual type (Circle) is hidden
```

### Key Characteristics

- **Type Preservation**: The underlying type is preserved internally but hidden from the caller.
- **Static Dispatch**: Method calls can be statically dispatched, improving performance.
- **Use Case**: When you want type safety while abstracting implementation details.


## Differences

| Feature                | `any`                              | `some`                              |
|------------------------|-------------------------------------|-------------------------------------|
| **Meaning**            | "Any type that conforms to a protocol" | "A specific type that conforms to a protocol" |
| **Type Information**   | Erased (not preserved)             | Preserved internally (opaque)       |
| **Dispatch**           | Dynamic                           | Static                              |
| **Use Case**           | Flexibility, abstraction           | Performance, type safety            |
| **Heterogeneous Types**| Supported (e.g., collections)      | Not supported                       |
| **Return Type**        | Can return multiple types          | Must return one consistent type     |


## When to Use `any` and when `some`

- **Use `any`**:

  - When working with heterogeneous types (e.g., arrays of different `Drawable` types).
  - When you need the flexibility to accept or return any type conforming to a protocol.
  - When dynamic behavior or runtime polymorphism is required.

- **Use `some`**:

  - When you need performance and type safety while abstracting implementation details.
  - When returning a single, consistent type that conforms to a protocol.
  - For private implementation details, where the caller doesn’t need to know the exact type.


## Example: Comparing `any` and `some`

```swift
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

// Using `any`
func render(shape: any Drawable) {
    shape.draw()
}

// Using `some`
func createCircle() -> some Drawable {
    return Circle()
}

let circle = createCircle() // always Circle
circle.draw()  // Output: Drawing a circle

let square = Square()
render(shape: square)  // Output: Drawing a square
```

### More details

We may compare functions that doing same job but using different keywords:

1. `func render(shape: some Drawable)`

* **Opaque Type**: The `some` keyword defines an `opaque` type. This means the function guarantees that the `shape` parameter is a single, specific type that conforms to the `Drawable` protocol, but the **exact type** is *hidden* from the caller.
* **Type Preservation**: The actual type of `shape` is preserved within the function, but it's not exposed to the outside world. This enables more optimized performance since Swift can statically dispatch method calls on `shape`.
* **Static Dispatch**: The compiler knows the exact type of `shape` at compile-time, so calls to `draw()` are dispatched statically. This avoids the overhead of dynamic dispatch.
* **Return Type**: The function signature guarantees that `shape` is a `Drawable`, but we don't know whether it's a `Circle`, `Square`, or any other concrete type. It could be any type that conforms to `Drawable`, but only one type will be returned or passed to the function for a given call.

```
func render(shape: some Drawable) {
    shape.draw()  // Call is statically dispatched to the specific type.
}
```

In this example, you are promising that the `shape` is some **specific type** conforming to `Drawable`, but the exact type is not revealed to the function caller.

2 `func render(shape: any Drawable)`

* **Existential Type**: The `any` keyword defines an existential type, meaning that the `shape` can be any type that conforms to the `Drawable` protocol, but the exact type is not known. The value is stored as an "*opaque wrapper*," and **type information is erased.**
* **Type Erasure**: The actual type of `shape` is erased. This means the compiler can't guarantee what the specific type is, and you lose type information inside the function. To access specific properties or methods beyond the protocol, you'd need to use type casting.
* **Dynamic Dispatch**: Because `shape` can be any type that conforms to `Drawable`, Swift uses dynamic dispatch to invoke methods on it (like `draw()`). This introduces a performance overhead compared to static dispatch, since the exact method to call is determined at runtime.

```
func render(shape: any Drawable) {
    shape.draw()  // Call is dynamically dispatched at runtime.
}
```

In this example, `shape` can be any type that conforms to `Drawable`, and it could be different types in different invocations. The method calls will be dispatched dynamically at runtime.

3 `func render(shape: Drawable)`

* **Protocol Type**: This signature is using protocol composition. It accepts any type that conforms to the `Drawable` protocol, but it **doesn’t hide or erase the type** information—it expects the type to be available to the function.
* **Dynamic Dispatch**: Similar to using any `Drawable`, the method call to `shape.draw()` would be resolved at runtime via dynamic dispatch, because the compiler doesn't know the specific type of `shape` at compile-time. Every call to `draw()` on `shape` is resolved at runtime, which introduces some performance overhead.
* **Type Safety**: The function doesn't know the exact type of `shape` but can still call any methods that are defined in the `Drawable` protocol. There's no guarantee about the specific concrete type of `shape`.

```
func render(shape: Drawable) {
    shape.draw()  // Calls draw on any Drawable conforming type at runtime.
}
```

Combining all together

| **Aspect**                  | **`func render(shape: Drawable)`**                       | **`func render(shape: some Drawable)`**            | **`func render(shape: any Drawable)`**              |
|-----------------------------|----------------------------------------------------------|----------------------------------------------------|----------------------------------------------------|
| **Type Information**         | Exact type of `shape` is not known at compile time, but it’s the **same** type for every call to `render`. | Exact type is **hidden** but preserved internally.  | Type is **erased**, cannot access specific properties. |
| **Dispatch Type**            | **Dynamic dispatch** at runtime (like `any`), leading to some performance overhead.     | **Static dispatch** at compile-time (more optimized). | **Dynamic dispatch** at runtime, similar to `Drawable`. |
| **Performance**              | Slight performance overhead due to dynamic dispatch.     | More efficient due to static dispatch.             | Similar to `Drawable`, performance overhead due to dynamic dispatch. |
| **Type Safety**              | Limited type safety. Can't access properties specific to `shape` unless you cast. | Preserved type safety with exact type hidden.      | Limited type safety. Can only access protocol methods, need casting for specific type access. |
| **Flexibility**              | Accepts any type conforming to `Drawable`, but does not expose concrete type. | Less flexible in that it hides the type but guarantees a single type. | Highly flexible, accepts **any** type conforming to `Drawable`. |


- `func render(shape: Drawable)` and `func render(shape: any Drawable)` both accept any type that conforms to `Drawable` but **use dynamic dispatch**, meaning the specific type is not known at compile-time and method calls are resolved at runtime.
- `func render(shape: some Drawable)` also accepts any type conforming to `Drawable`, but it uses **static dispatch** (since the type is preserved internally), leading to **better performance** and **type safety** because the exact type is known at compile time.
  
In terms of **developer priorities**:

- Use `render(shape: Drawable)` or `render(shape: any Drawable)` if you need flexibility and don't mind the slight performance hit from dynamic dispatch.
- Use `render(shape: some Drawable)` if you want better performance (static dispatch) and maintain type safety, but with the tradeoff of not exposing the exact type to the caller.

The usage and syntax of the code are the same in both `some Drawable` and `any Drawable` — the **main difference** lies in **type handling and performance**.

## Conclusion

`some` is used when you want to guarantee a single concrete type, while `any` is used when you need flexibility and can work with any type conforming to a protocol, with the tradeoff of less performance and type safety.

By understanding the differences between `any` and `some`, developers can write clearer and more efficient Swift code that balances flexibility and type safety.

## Resource List

- [Swift Documentation: Protocols](https://developer.apple.com/documentation/swift/protocols)
- [Swift Evolution Proposal SE-0301: `any` Keyword](https://github.com/apple/swift-evolution/blob/main/proposals/0301-any.md)
- [Swift Evolution Proposal SE-0244: Opaque Result Types (`some`)](https://github.com/apple/swift-evolution/blob/main/proposals/0244-opaque-result-types.md)
- [Understanding Protocols and Generics in Swift](https://swift.org/documentation/)
- Books like *Swift Programming: The Big Nerd Ranch Guide*.
