---
layout: post
comments: true
title: "Understanding _VariadicView"
categories: article
tags: [swift, SwiftUI, iOS, _VariadicView]
excerpt_separator: <!--more-->
comments_id: 116

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---


SwiftUI introduces several powerful types for building dynamic and composable user interfaces. Among these is `_VariadicView`, an often overlooked yet highly useful internal type. 
<!--more-->

This article explores `_VariadicView` and related types, their relationships, and practical applications. While `_VariadicView` is not part of the public API, understanding it can provide insights into advanced SwiftUI techniques.

## Introduction

Recently I faced with some library that build dynamically buttons in vertical or horizontal manner with specific separators in between. The interesting point was that all buttons user by the library should be provided as `@ViewBuilder` block packed in special `View` type, like `Group`. The trick moment here - is that this library somehow disasseble this `@ViewBuilder` block and work with each element separately.

So I dive deeper in the library and found, that under the hood there is some (looks like private) type named `_VariadicView` and the whole family with it working hard to make this idea come true. 

Ok, ok, u may say, that how about this `Group` initializer [`init(subviews:transform:)`](https://developer.apple.com/documentation/swiftui/group/init(subviews:transform:)):

```swift
 Group(subviews: content) { subviews in
 ... // iterate over each subview
```

Yes, but this is for iOS 18 and Swift 6.0+... how about earlier versions? The answer is `_VariadicView`.

As result, we can use this:

```swift
 _VariadicView.Tree(ContentLayout()) {
    content
}
```

where all magic is inside `ContentLayout`:

```swift
func body(children: _VariadicView.Children) -> some View {
  HStack(spacing: 0) {
    children.first
    ForEach(children.dropFirst()) { child in
        if !hideDivider {
            Divider()
        }
        child
    }
}
```

So, at the first look - same code as we used before, but with `_VariadicView`. What's the benefit? The idea behind this is a bit more deeper - we can easelly access to elements of layout, and we can control and manage them.

## `_VariadicView` family

`_VariadicView` facilitates dynamic rendering of views based on a variable number of child views. Depending of user layout that is processed with `_VariadicView.Tree` the way how internal subviews are handled - different.

The family of this type contains next:

- `public typealias Root = _VariadicView_Root`
- `public typealias ViewRoot = _VariadicView_ViewRoot`
- `public typealias Children = _VariadicView_Children`
- `public typealias UnaryViewRoot = _VariadicView_UnaryViewRoot`
- `public typealias MultiViewRoot = _VariadicView_MultiViewRoot`
- `public struct Tree<Root, Content> where Root: _VariadicView_Root`

The idea of how this works can be obtained from [OpenSwiftUI project](https://github.com/Cosmo/OpenSwiftUI/blob/master/Sources/OpenSwiftUI/_VariadicView/VariadicView.swift)

> I also found [one of the few posts](https://www.emergetools.com/blog/posts/how-to-use-variadic-view) about this type, that describe, I believe, same piece of code

Let's review each type in a bit more details.

### `_VariadicView_Root`

`_VariadicView_Root` is a typealias or internal construct within `SwiftUI` that acts as the abstract representation of a variadic view's root.

It is used internally by `SwiftUI` to manage the root processing of variadic views, delegating to either `_VariadicView_MultiViewRoot` or `_VariadicView_UnaryViewRoot` depending on the context.


### `_VariadicView_ViewRoot`

`_VariadicView.ViewRoot` is the core protocol that defines the behavior of a custom variadic view. Both `_VariadicView_MultiViewRoot` and `_VariadicView_UnaryViewRoot` conform to this protocol and specialize it for handling multiple or single child views, respectively.

> While `_VariadicView.ViewRoot` can be used directly, `SwiftUI` provides `_VariadicView_MultiViewRoot` and `_VariadicView_UnaryViewRoot` for common cases. However, there are scenarios where you may prefer `_VariadicView.ViewRoot`:
> 
> * **Completely Custom Layouts**: For layouts not easily expressed with stacks, grids, or predefined patterns.
* **Special Child Processing**: When you need to implement unique behavior or processing logic for children.
* **Debugging or Wrapping Existing Views**: Custom wrappers that process child views dynamically

| Feature                        | `_VariadicView_ViewRoot`                | `_VariadicView_Root`                   |
|--------------------------------|-----------------------------------------|----------------------------------------|
| **Type**                       | Protocol                               | Internal construct or typealias       |
| **Purpose**                    | Defines how variadic views process children | Abstract root representation for variadic views |
| **Developer Interaction**      | Developers conform to it to create custom variadic views | Not directly accessible or used by developers |
| **Usage**                      | Custom layouts and child processing    | Framework-level abstraction            |
| **Examples**                   | CustomStack, CustomGrid, etc.          | Internally links to `_VariadicView_MultiViewRoot` and `_VariadicView_UnaryViewRoot` |
| **Flexibility**                | Fully customizable                    | Internally managed by SwiftUI          |



### `_VariadicView_UnaryViewRoot`

- Represents the root of a tree that processes a single variadic view.
- Acts as a point where layout and modifiers are applied to the child views.

```swift
struct MyUnaryViewRoot: _VariadicView.UnaryViewRoot {
    func body(children: _VariadicView.Children) -> some View {
        VStack {
            ...
        }
    }
}
```

### `_VariadicView_MultiViewRoot`

- Represents the root of a tree that processes a few dynamic views.
- Acts as a point where layout and modifiers are applied to the child's views.

```swift
struct MyMultiViewRoot: _VariadicView_MultiViewRoot {
    func body(children: _VariadicView.Children) -> some View {
        ForEach(children) { child in
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                child
            }
            .padding()
        }
    }
}

struct IndependentChildrenExample: View {
    var body: some View {
        MyMultiViewRoot {
            Text("Child 1")
            Text("Child 2")
            Text("Child 3")
        }
    }
}
```

| Feature                      | `_VariadicView.ViewRoot`             | `_VariadicView_MultiViewRoot`          | `_VariadicView_UnaryViewRoot`          |
|------------------------------|---------------------------------------|---------------------------------------|---------------------------------------|
| **Purpose**                  | Generic protocol for variadic views  | Specializes for multiple children     | Specializes for single child          |
| **Flexibility**              | Highly flexible, requires manual work| Optimized for common multi-view cases | Simplified for single-child cases     |
| **Use Case**                 | Custom layouts or processing         | Dynamic layouts like grids or stacks  | Single-child wrappers                 |
| **Ease of Use**              | Requires detailed implementation     | Straightforward for multi-view layouts| Straightforward for single-child use  |


### `_VariadicView_Children`

- Represents a collection of child views in the variadic tree.
- Provides APIs for accessing and iterating over child views.

```swift
 _VariadicView.Tree(MyUnaryViewRoot()) {
    Text("Child 1") // <- part of _VariadicView.Children
    Text("Child 2") // <- part of _VariadicView.Children
    Text("Child 3") // <- part of _VariadicView.Children
}
```

### `_VariadicView.Tree<Root, Content>`

- `_VariadicView.Tree` handles views with a dynamic number of children, such as views constructed with `@ViewBuilder` or container views like `HStack` and `VStack`.
- It organizes child views and integrates them into SwiftUI's rendering and layout systems.

When constructing UI with containers or builders, SwiftUI needs to manage the child views dynamically. `_VariadicView.Tree` handles this task by:
1. Organizing the child views into a manageable structure.
2. Calculating layouts and ensuring state consistency across dynamic updates.

A few more types (listed above) helps `_VariadicView.Tree` to achieve it's goal.

### Type's diagram

To make things even more clear, here is the relationsheep in graphical way:

```console
+---------------------------+
|       _VariadicView       |
+---------------------------+
           |
           v
+---------------------------+
|  _VariadicView.ViewRoot   |
+---------------------------+
           |
           v
+---------------------------+
| _VariadicView.Children    |
+---------------------------+
           |
           v
+---------------------------+
|     _VariadicView.Tree    |
+---------------------------+
           |
           |
           +------------------+
           |                  |
           v                  v
+-------------------+   +-------------------+
| _VariadicView_    |   | _VariadicView_    |
| UnaryViewRoot     |   | MultiViewRoot     |
+-------------------+   +-------------------+
```

Legend:

1. **`_VariadicView`**: Acts as the foundation, enabling dynamic child processing.
2. **`_VariadicView.ViewRoot`**: Represents the root of a variadic view hierarchy.
3. **`_VariadicView.Children`**: Provides access to the child views.
4. **`_VariadicView.Tree`**: A specialized structure representing the tree of child views in the hierarchy. It ensures efficient organization and traversal of views. Without `_VariadicView.Tree`, the system would need to repeatedly iterate through all child views to perform common tasks like rendering, layout computation, or updates, resulting in significant performance overhead and more complex logic.
5. **`SwiftUI._VariadicView_UnaryViewRoot`**: Handles cases where the variadic root processes a single child view.
6. **`SwiftUI._VariadicView_MultiViewRoot`**: Handles cases where the variadic root processes multiple child views.


A good example can explain even better. As a simple, yet powerfull example we can use implementation from [so question](https://stackoverflow.com/questions/79178893/how-we-can-convert-a-variadicview-unaryviewroot-to-variadicview-multiviewroot) with small modification:

```swift
CustomVStack_MultiViewRoot {
  Text("CustomVStack_MultiViewRoot").bold()
  parts
}
.border(.red)
```

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-01-02-_VariadicView/demo.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-01-02-_VariadicView/demo.png" alt="demo" width="300"/>
</a>
</div>
<br>
<br>

<details><summary> The full code is here </summary>
<p>

{% highlight swift %}
import SwiftUI

struct ContentView: View {

  @ViewBuilder var parts: some View {
      Text("First")
      Text("Second")
      Text("Third")
  }

  var body: some View {
    VStack {

      VStack(spacing: 10.0) {

        VStack {
          Text("VStack").bold()
          parts
        }
        .border(.yellow)

        CustomVStack_UnaryViewRoot {
          Text("CustomVStack_UnaryViewRoot").bold()
          parts
        }
        .border(.blue)

        CustomVStack_MultiViewRoot {
          Text("CustomVStack_MultiViewRoot").bold()
          parts
        }
        .border(.red)

        Group {
          Text("Group").bold()
          parts
        }
        .border(.orange)

        List {
          Text("List").bold()
          parts
        }
        .border(.purple)

        CustomList {
          Text("CustomList").bold()
          parts
        }
        .bordered()

      }
    }
  }
}

struct VStackLayout_UnaryViewRoot: _VariadicView_UnaryViewRoot {
  func body(children: _VariadicView.Children) -> some View {
    return children
  }
}

struct VstackLayout_MultiViewRoot: _VariadicView_MultiViewRoot {
  func body(children: _VariadicView.Children) -> some View {
    return children
  }
}

struct CustomVStack_UnaryViewRoot<Content: View>: View {
  var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    _VariadicView.Tree(VStackLayout_UnaryViewRoot()) {
      content
    }
  }
}

struct CustomVStack_MultiViewRoot<Content: View>: View {
  var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    _VariadicView.Tree(VstackLayout_MultiViewRoot()) {
      content
    }
  }
}


struct CustomListRoot: _VariadicView_ViewRoot {
  func body(children: _VariadicView.Children) -> some View {
    ScrollView {
      ForEach(children) { child in
        child
          .padding(.vertical, 4)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(4)
      }
    }
    .padding()
  }
}

struct CustomList<Content: View>: View {
  @ViewBuilder let content: Content

  var body: some View {
    _VariadicView.Tree(CustomListRoot()) {
      content
    }
  }
}

extension CustomList {
  func bordered() -> some View {
    self
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(Color.blue, lineWidth: 1)
      )
  }
}
{% endhighlight %}

</p>
</details>
<br>

The real-world usage can be achieved via various extenstions, such as the [one proposed by crhis.eidhof](https://chris.eidhof.nl/post/variadic-views/)

## Alternatives

While `_VariadicView.Tree` and its related types are private, developers can achieve similar functionality using public APIs:

### `@ViewBuilder`

```swift
struct ExampleView: View {
    var body: some View {
        VStack {
            Text("Child 1")
            if Bool.random() {
                Text("Conditional Child")
            }
            Text("Child 3")
        }
    }
}
```

### `ForEach`

```swift
struct ForEachExample: View {
    let items = ["Child 1", "Child 2", "Child 3"]
    
    var body: some View {
        VStack {
            ForEach(items, id: \.self) { item in
                Text(item)
            }
        }
    }
}
```

### `ForEach(subviews:content:)` and other similar

```swift
HStack(spacing: 0) {
    Group(subviews: content) { subviews in
    	...
    }
}
```

> [(from iOS 18)](https://developer.apple.com/documentation/swiftui/foreach/init(subviews:content:))

### Custom View Containers

```swift
struct CustomContainer<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack {
            content()
        }
    }
}

struct Example: View {
    var body: some View {
        CustomContainer {
            Text("Child 1")
            Text("Child 2")
        }
    }
}
```

## Best Practices

To produce efficient code that works well on different swift versions and iOS versions, we can use macroses and preconditions:

```swift
@available(iOS, introduced: 14.0, deprecated: 18.0, message: "Use `ForEach(subviewOf:content:)` instead")
@MainActor 
struct MyLayout: _VariadicView_ViewRoot {
    
    #if swift(>=6.0)
    func body(children: _VariadicView.Children) -> some View {
        HStack(spacing: 0) {
            ForEach(children) { child in
                child
            }
        }
    }
    #else
    nonisolated 
    func body(children: _VariadicView.Children) -> some View {
        HStack(spacing: 0) {
            ForEach(children) { child in
                child
            }
        }
    }    
    #endif
}

// and later in some View

public var body: some View {
#if swift(>=6.0)
if #available(iOS 18.0, *) {
    HStack(spacing: 0) {
        Group(subviews: content) { subviews in
            ForEach(subviews) { child in
                child
            }
        }
    }
} else {
    _VariadicView.Tree(MyLayout()) {
        content
    }
}
#else
_VariadicView.Tree(MyLayout()) {
    content
}
#endif
```

## Conclusion

Although `_VariadicView` is an internal API, its concepts and functionality reveal the power and flexibility of SwiftUI. By mastering these types, developers can build more dynamic and reusable UI components, pushing the boundaries of SwiftUI.

Share your thoughts and experiments in the comments below!

## Resources

* [variadic-views-in-swiftui](https://movingparts.io/variadic-views-in-swiftui)
* [OpenSwiftUI project](https://github.com/Cosmo/OpenSwiftUI/blob/master/Sources/OpenSwiftUI/_VariadicView/VariadicView.swift)
* [variadic-views](https://chris.eidhof.nl/post/variadic-views/)
* [Swift Forums - Discussions on Variadic Views](https://forums.swift.org/)
* [Apple's SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
* [Understanding SwiftUI Internals by Majid Jabrayilov](https://swiftwithmajid.com/)
* [Advanced SwiftUI Techniques on Hacking with Swift](https://www.hackingwithswift.com/)
* [Source Code Exploration on Swift Open Source](https://github.com/apple/swift)**