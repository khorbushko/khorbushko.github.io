---
layout: post
comments: true
title: "Understanding SwiftUI View lifecycle"
categories: article
tags: [iOS, SwiftUI, View]
excerpt_separator: <!--more-->
comments_id: 15

author:
- kyryl horbushko
- Lviv
---

`SwiftUI` brings for us, developers, the whole new ecosystem for creating complex and responsible `UI`. 

Thus the entry point for this approach is quite low and u can start producing acceptable `UI` after the first 5 min, it's always better to dive a bit and understand how everything works under the hood. Such knowledge will improve your future work and our developer's skills. Even more - without understanding how it works, u can't develop something really interesting and stunning.
<!--more-->

Talking about `SwiftUI`, the good start point may be ***understanding View's lifecycle*** - how everything is combined and how every part and components of this ecosystem are related one to each other.

## Lifecycle

We may draw a small scheme that visualize the full Lifecycle of a `View` as follow:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-16-understanding-swiftUI-View-lifecycle/view_lifecycle.pdf" alt="view_lifecycle" width="550"/>
</div>

As u can see - it's not very complex. But under this simplicity, there is much more. Every action has its mechanism(s) that improve and optimize it.
Let's review a bit what's going on when we create and use a `SwiftUI`'s `View`.

## Initialization

`View` is a protocol that requires from us only body definition, we also have one more requirement - `Type` that conform to `View` protocol should be a value type, thus `struct`.

This requirement is not something that u can observe during a compiling time, instead of in runtime u will receive fatalError:

{% highlight swift %}
Fatal error: views must be value types: <ViewFromClass>: file SwiftUI, line 0
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-16-understanding-swiftUI-View-lifecycle/preview_crash.png" alt="preview_crash" width="350"/>
</div>

So View may be only a value type - struct. This means that initialization is quite simple and yet powerful. In most cases compiler create an initializer for us.

During initialization, we also often can create inner `@State` variables (should be `private`) or pass `@State` through `@Binding`. Other properties may be observed using various ways such as `@StateObject`, `@ObservedValue` or `@SceneStorage` etc.

So during initialization, we simply create and configure `View`'s states and *"store"* variables in `SwiftUI` `ViewGraph`.

> `ViewGraph` constructed by private framework `AttributeGraph.framework` (/System/Library/PrivateFrameworks/AttributeGraph.framework)

Result of this initialization - very complex type with Generics, or simply `some View`. `some` specially designed for hiding actual type. Why? That's because of a few main reasons:

* [type-level abstraction ](https://forums.swift.org/t/improving-the-ui-of-generics/22814#heading--missing-type-level-abstraction)
* protection by hiding implementation details (that's almost the same as the point above)
* simplification 

> `some` - is [opaque type](https://docs.swift.org/swift-book/LanguageGuide/OpaqueTypes.html) that was introduces [here](https://github.com/apple/swift-evolution/blob/master/proposals/0244-opaque-result-types.md). This type simply hide return value’s type information and only refere to conformed protocol.
> 
> `some` is opaque type, so all limitation and possibilities are also in place:
> 
* `PAT`'s (protocol associated types) can't be used for opaque type
* these types are identifiable
* can be composed with generic placeholders

To check the actual type of View, we may create a very simple example:

{% highlight swift %}
struct ContentView: View {
    
    @State private var counter = 0
    
    var body: some View {
        VStack {
            Button(action: {
                self.counter += 1
            }, label: {
                Text("Some Text")
            })
            
            if counter > 0 {
                Text("Counter \(counter)")
            }
        }
        .frame(height: 50)
    }
}
{% endhighlight %}

And if we use `Mirror` (aka `print(Mirror(reflecting: self).subjectType)`) we can get:

{% highlight swift %}
ModifiedContent<VStack<TupleView<(Button<Text>, Optional<Text>)>>, _FrameLayout>
{% endhighlight %}

Quite complex generic type, that can be hidden above `some View`. 

> check out any complex `View` that u use in a real project - u will observe a huge name of `Type`.

## Change

As we already know, `View`'s can be redrawn whenever something is changed. This performed very efficiently because of the used mechanism - SwiftUI checks what exactly was changed and redraw only this part (this is also known as `diff`). 

> `AnyView` removes this efficiency because this is type-eraser, so `SwiftUI` can't compare an unknown type with an unknown type, instead, the whole view will be redrawn. So use `AnyView` wisely.

Another essential component of any View - various `@propertyWrappers`. 

We ~~can't~~ (*actually can but with a lot of efforts*) interact within `View` and show to user any update without special variables that can change and hold their state independently from `View` (thus view is a `struct` and any change will recreate/mutate it). Thanks to `@propertyWrappers`, we have a template with boiler part code for various purposes needed during the life of `View`.

> I wrote an overview about available `@propertyWrappers` in `SwiftUI`. You can check it [here]({% post_url 2020-12-10-swiftUIpropertyWrappers %}).

Anyway, these values are initialized within the view and changed outside of view. The only thing that should be done by `View` - is properly reacting to them. And it does. This is done by design. So we should think only about logic now, not about sync the data and view.

The update/redraw `View` flow may be as follow:

* Find State of View using `Field Descriptor`
* Inject `ViewGraph` into `State`
* Render `View.body`
* `State` is changed
* `State` notify the `ViewGraph` to update view
* Re-render `View.body`

> if u interested into how `@State` might work in details - [check this post](https://kateinoigakukun.hatenablog.com/entry/2019/06/09/081831)

## Events

Configuration of `View`'s states is also simplified - we have few callbacks. In additional, if we need some event handling configuration we may use another *dataFlow* mechanisms such as [`onChange(of:perform:)`](https://developer.apple.com/documentation/swiftui/hstack/onchange(of:perform:)) or some other [**View Modifiers**](https://developer.apple.com/documentation/swiftui/hstack-view-modifiers).

> check [this official doc](https://developer.apple.com/documentation/swiftui/state-and-data-flow) for more about data flow

If be clear, there are 2 callback that can be used

* [`onAppear(perform:)`](https://developer.apple.com/documentation/swiftui/hstack/onappear(perform:))
* [`onDisappear(perform:)`](https://developer.apple.com/documentation/swiftui/view/ondisappear(perform:))

That's it. The name tells us their purpose by itself.

{% highlight swift %}
var body: some View {
    VStack {
        EmptyView()
    }
    .onAppear {
        // action
    }
    .onDisappear {
        // action
    }
}
{% endhighlight %}

> other [input events](https://developer.apple.com/documentation/swiftui/view-input-and-events)

In total, we may sum-up all events and update a bit the scheme from the very beginning of the post:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-16-understanding-swiftUI-View-lifecycle/view_lifecycle_comments.pdf" alt="view_lifecycle_comments" width="550"/>
</div>

## Summary

Such an elegant design of `View`'s lifecycle reduces required effort, amount of code and so bugs.

> With a declarative `Swift` syntax that’s easy to read and natural to write, `SwiftUI` works seamlessly with new `Xcode` design tools to keep your code and design perfectly in sync (Apple). [source](https://developer.apple.com/xcode/swiftui/)