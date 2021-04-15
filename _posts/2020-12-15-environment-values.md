---
layout: post
comments: true
title: "Passing data down the view tree in SwiftUI"
categories: article
tags: [iOS, SwiftUI, EnvironmentValues, dataflow]
excerpt_separator: <!--more-->
comments_id: 14

author:
- kyryl horbushko
- Lviv
---


[`EnvironmentValues`](https://developer.apple.com/documentation/swiftui/environmentvalues) is a set of values that may be used during interface and app functionality building. 

This is a simple and yet powerful addition from `SwiftUI`, that can improve any state and dataFlow in the app.
<!--more-->

> A collection of environment values propagated through a view hierarchy. ([Apple](https://developer.apple.com/documentation/swiftui/environmentvalues))

## EnvironmentValues

By itself, `EnvironmentValues` is a struct with a collection of values. We may create an instance of this struct and check it out:

{% highlight swift %}
let values = EnvironmentValues()
{% endhighlight %}

simple `po` command gives us not to much info:

> po values
> 
> ▿ []
> 
>   ▿ plist : []
> 
>     - elements : nil
> 
>   - tracker : nil

But, according to [official doc](https://developer.apple.com/documentation/swiftui/environmentvalues) - we may access thought `@Environment` and keypath to a lot of them. To figure out what if under the hood we may use `Mirror`:

{% highlight swift %}
Mirror(reflecting: values).children
{% endhighlight %}

> ▿ AnyCollection<(label: Optional<String>, value: Any)>
> 
>   ▿ _box : <_RandomAccessCollectionBox<LazyMapSequence<Range<Int>, (label: Optional<String>, value: Any)>>: 0x600002314820>

Aha, this is a struct that uses lazy collection within these values. 

The usage of these values is very important in `SwiftUI`. Values can be used implicitly by setting them for any of the view tree:

{% highlight swift %}
struct ContentView: View {
    
    var body: some View {
        VStack {
            Text("Hello")
        }
        .environment(\.font, .headline)
        .debug()
    }
}
{% endhighlight %}

where `debug` is extension to View that prints `Mirror(reflecting: self).subjectType`.

> thanks to [objc.io](https://www.objc.io/books/thinking-in-swiftui/) for this 

{% highlight swift %}
extension View {
    func debug() -> Self {
        print(Mirror(reflecting: self).subjectType)
        return self
    }
}
{% endhighlight %}

The type will be next:

{% highlight swift %}
ModifiedContent<VStack<Text>, _EnvironmentKeyWritingModifier<Optional<Font>>>
{% endhighlight %}

We also know that we can apply modifiers to some stack, and then all nested children that can apply these settings should apply these values.

{% highlight swift %}
struct ContentView: View {
    
    var body: some View {
        VStack {
            Text("Hello")
        }
        .font(.headline)
        .debug()
    }
}
{% endhighlight %}

And if we check the type

{% highlight swift %}
ModifiedContent<VStack<Text>, _EnvironmentKeyWritingModifier<Optional<Font>>>
{% endhighlight %}

You can see, that Type is the same, so this is just a wrapper for environment values that can be used on our own.

This means that we can use the environment to create custom modifiers and functions that can change the appearance of our view's even on high-level view tree view's.

> there is an [open-source WIP project](https://github.com/Cosmo/OpenSwiftUI/blob/master/Sources/OpenSwiftUI/Modifiers/EnvironmentKeyWritingModifier.swift) that tries to implement SwiftUI within `_EnvironmentKeyWritingModifier`, check it out for more.


## Custom environment value

As mention on [official doc](https://developer.apple.com/documentation/swiftui/environmentkey), we can create a custom Environment value.

The steps are very simple:

1. declare a new environment key type and specify a value for the required defaultValue property

{% highlight swift %}
private struct CheckmarkStrokeColorKey: EnvironmentKey {
    static let defaultValue: Color = .green
}
{% endhighlight %}

> here we will use this value for our own `View` with a checkmark shape inside

2. use the key to define a new environment value property

{% highlight swift %}
extension EnvironmentValues {
    var checkmarkStrokeColor: Color {
        get { self[CheckmarkStrokeColorKey.self] }
        set { self[CheckmarkStrokeColorKey.self] = newValue }
    }
}
{% endhighlight %}

This then can be used inside `View` using the `@Environment` variable:

{% highlight swift %}
struct Checkmark: Shape {
    
    func path(in rect: CGRect) -> Path {
        Path { checkMarkBezierPath in
            let origin = rect.origin
            let diameter = rect.height
            let point1 = CGPoint(
                x: origin.x + diameter * 0.1,
                y: origin.y + diameter * 0.4
            )
            let point2 = CGPoint(
                x: origin.x + diameter * 0.40,
                y: origin.y + diameter * 0.7
            )
            let point3 = CGPoint(
                x: origin.x + diameter * 0.95,
                y: origin.y + diameter * 0.2
            )
            
            checkMarkBezierPath.move(to: point1)
            checkMarkBezierPath.addLine(to: point2)
            checkMarkBezierPath.addLine(to: point3)
        }
    }
}

struct AnimatedCheckMarkView: View {
    @Environment(\.checkmarkStrokeColor) var strokeColor: Color
    
    var body: some View {
        Checkmark()
            .stroke(
                strokeColor,
                style: StrokeStyle(
                    lineWidth: 5,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
    }
}
{% endhighlight %}

And usage:

{% highlight swift %}
struct ContentView: View {
    var body: some View {
        AnimatedCheckMarkView()
            .frame(width: 150, height: 150)
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-15-environment-values/default.png" alt="default" width="350"/>
</div>

with changed environment:

{% highlight swift %}
struct ContentView: View {
    var body: some View {
        AnimatedCheckMarkView()
            .environment(\.checkmarkStrokeColor, .red)
            .frame(width: 150, height: 150)
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-15-environment-values/changed.png" alt="changed" width="350"/>
</div>

We may go futher and add View extension as done within font in saple above:

{% highlight swift %}
extension View {
    
    func checkmarkStrokeColor(_ color: Color) -> some View {
        environment(\.checkmarkStrokeColor, color)
    }
}
{% endhighlight %}

Than apply to view tree:

{% highlight swift %}
struct ContentView: View {
    var body: some View {
        VStack {
            AnimatedCheckMarkView()
            AnimatedCheckMarkView()
            AnimatedCheckMarkView()
        }
        .checkmarkStrokeColor(.orange)
        .frame(width: 150, height: 450)
    }
}
{% endhighlight %}

Result:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-15-environment-values/extension.png" alt="extension" width="350"/>
</div>


## Pros and Cons

Cons:

- easy to forget to pass the `@Environment` variable and no error until we not use the actual screen where it uses. The good point here - `default` value will be used
- easy to mismatch view-tree and set a variable in the wrong place
- ease to forget to pass `@EnvironmentObject` - in comparison to `@Environment`, the default value is missed here, and do crash will be received.

Pros:

+ easy customization
+ easy injection


[download source playground]({% link assets/posts/images/2020-12-15-environment-values/source/testEnvironment.zip %})