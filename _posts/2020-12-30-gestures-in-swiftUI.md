---
layout: post
comments: true
title: "Gestures in SwiftUI at scale"
categories: article
tags: [iOS, SwiftUI, Gestures]
excerpt_separator: <!--more-->
comments_id: 20

author:
- kyryl horbushko
- Lviv
---

Touch interface provides users essential way to communicate with a device with phenomenal simplicity. U even can't notice how many gestures u did in the last few hours while u use your phone. But if u think about it - the number of gestures interactions may surprise you.
<!--more-->

Thinking about better usability for our apps, we should also remember about `Gesture` functionality. With `SwiftUI` gestures API becomes even more powerful and simple in comparison to `UIKit`. 

## About gesture

We can apply gestures using few approaches in `SwiftUI`. One requires from us only use specially designed function for handling main aspect of any gesture (for example action from `TapGesture` can be handled with [`onTapGesture(count:perform:)`](https://developer.apple.com/documentation/swiftui/view/ontapgesture(count:perform:)) , or `LongPressGesture` can be handled with [`onLongPressGesture(minimumDuration:pressing:perform:)`](https://developer.apple.com/documentation/swiftui/view/onlongpressgesture(minimumduration:pressing:perform:))). 

Another one - use gesture modifier that can apply any gesture type to view with all needed events in it.

> Actually there are few modifies - [`gesture(_:including:)`](https://developer.apple.com/documentation/swiftui/view/gesture(_:including:)), [`highPriorityGesture(_:including:)`](https://developer.apple.com/documentation/swiftui/view/highprioritygesture(_:including:)) and [`simultaneousGesture(_:including:)`](https://developer.apple.com/documentation/swiftui/view/simultaneousgesture(_:including:)). 
> 
> These names already provide a partial answer about the purpose of each function.

From the documentation we can find, that `Gesture` in `SwiftUI` - * its stream of values for state-provided from the sequence of the event.* This type is defined as a protocol and requires to provide a type of `Value` that will be returned with gesture and `body` - *content and behavior of the gesture*.

Before we review any type of `Gesture`, it's good to know what can be done within it and which event's can be handled/received. 

Gesture protocol has few extension function that provide functionality for performing gestures related operations:

- [`updating(_:body:)`](https://developer.apple.com/documentation/swiftui/gesture/updating(_:body:))
- [`onChanged(_:)`](https://developer.apple.com/documentation/swiftui/gesture/onchanged(_:))
- [`onEnded(_:)`](https://developer.apple.com/documentation/swiftui/gesture/onended(_:))

So, these are the main 3 activities that are interesting for us. But if we think a bit, then we may realize that for example `TapGesture` don't need the `onChanged(_:)` function, thus tap its just a tap, and such an event as change simply can't exist for it (or will never provide useful information). 

Keeping this in mind, Apple has defined `Value` for the gesture, which can interpret the possibility of changes. Modifier as `onChanged(_:)` can't be executed for values that can't change and if we back to `TapGesture` there is no such value - when we check documentation we can find:

{% highlight swift %}
/// The type representing the gesture's value.
public typealias Value = ()

/// The type of gesture representing the body of `Self`.
public typealias Body = Never
{% endhighlight %}

this mean that `onChanged(_:)` is not applicable bacause `Value` is not `Equatable` (`onChanged(_:)` has requirement that `Self.Value : Equatable`) - *nothing* can't cnange.

> It's good to know that for a gesture that can have an end event there is a type `_EndedGesture<T>` (`A gesture that triggers `action` when the gesture ends`), for one that can have change in some state - `_ChangedGesture<T>` (*A gesture that triggers `action` when this gesture's value changed*), for those of them who can update some value based on state - `GestureStateGesture<T, V>`. 
> 
> Prefix `_` on some types means that this is a private type, so realization details are hidden from us, but we can make an assumption about functionality behind.

## Gesture types

Sometimes a picture is better than a thousand words. So here are available gestures in SwiftUI

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-30-gestures-in-swiftUI/gestures.svg" alt="gestures_types" width="350"/>
</div>

### TapGesture

I already mention `TapGesture` - this is one of the simplest gesture.
We already discovered that `Value` for this gesture is `Void` and `body` can't be changed. 

We may use this gesture in a few ways:

{% highlight swift %}
Text("Hello \(tapCount)")
    .onTapGesture {
        tapCount += 1
    }
{% endhighlight %}

> Tap gesture also has `count` parameter, by *default* equal to 1, so if needed u may specify any numbers of tap, before `TapGesture` fire end event

or 

{% highlight swift %}
Text("Hello \(tapCount)")
    .gesture(
        TapGesture()
            .onEnded({ (_) in
					tapCount += 1
            })
    )
{% endhighlight %}

> note - we may also use an updating function on tap gesture, but its gonna never be called because `Value` is `Void`


### LongPressGesture

This gesture according to its name used for detecting longPress events - no surprise here ;]. 

In comparison to tap, updating is now can be used, because it has defined value type as `public typealias Value = Bool`. This mean, that additional function `onChanged(_:)` also available (`Bool` is `Equatable`). Lets see it in action:

{% highlight swift %}
struct LongPressGestureDemoView: View {
    @GestureState private var isLongPressActivated: Bool = false
    @State private var tapCount: Int = 0
    
    var body: some View {
        Text("Hello \(tapCount)")
            .padding()
            .background(isLongPressActivated ? Color.red : Color.green)
            .cornerRadius(4)
            // .animation(.easeInOut) // animate all changes
            .gesture(
                LongPressGesture(
                    minimumDuration: 1,
                    maximumDistance: 10
                )
                // SwiftUI invokes the updating callback as soon as it recognizes the gesture and whenever the value of the gesture changes
                .updating(
                    $isLongPressActivated,
                    // currentState - type of Value -> Bool
                    // gestureState - type of @GestureState
                    // transaction - object to pass an animation between views in a view hierarchy. The context of the current state-processing update
                    body: { (currentState, gestureState, transaction) in
                        print("On updating: \(currentState), \(gestureState), \(transaction)")
                        // any transformation from
                        // type of @GestureState to
                        // type of Value -> Bool
                        gestureState = currentState
                        
                        // transaction for gesture
                        transaction.animation = Animation.easeInOut(duration: 1.0)
                    }
                )
                // called when Value changed
                // value - Value -> Bool
                .onChanged({ (value) in
                    print("On changed: \(value)")
                })
                .onEnded({ (value) in
                    tapCount += 1
                    print("On Ended - \(value)")
                })
            )
    }
}
{% endhighlight %}

> I wrote separate article about [`propertyWrappers in SwiftUI`]({% post_url 2020-12-10-swiftUIpropertyWrappers %})

Result:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-30-gestures-in-swiftUI/demo_longPress.gif" alt="demo_longPress" width="550"/>
</div>

And don't forget about *simplified* version for long press action:

{% highlight swift %}
  SomeView()
    .onLongPressGesture(minimumDuration: 1, maximumDistance: 10) { (value) in
        // do stuff
    } perform: {
        // do stuff
    }
{% endhighlight %}

### DragGesture

A gesture that allows very common operation such as drag, on in other words - swipe.

`Value` for this gesture is quite interesting, contains a lot of data and defined as next:

{% highlight swift %}
    public struct Value : Equatable {
        public var time: Date
        public var location: CGPoint
        public var startLocation: CGPoint
        public var translation: CGSize { get }
        public var predictedEndLocation: CGPoint { get }
        public var predictedEndTranslation: CGSize { get }
...
{% endhighlight %}

As u can see - we can use a lot of data from the `Value` type and so perform the same complex operation as with old gestures in `UIKit`. Commonly used `translation` value, thus in most cases, we only need an amount of moved distance over screen:

{% highlight swift %}
struct DragGestureDemoView: View {
    @GestureState private var dragTranslation: CGSize = .zero
    
    var body: some View {
        Text("Hello")
            .padding()
            .cornerRadius(4)
            .offset(x: dragTranslation.width, y: dragTranslation.height)
            .gesture(
                DragGesture()
                    .updating(
                        $dragTranslation,
                        body: { (value, state, transition) in
                            state = value.translation
                        }
                    )
            )
            .animation(.easeInOut)
    }
}
{% endhighlight %}

Result:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-30-gestures-in-swiftUI/demo_dragGesture.gif" alt="demo_dragGesture" width="550"/>
</div>

> Check *simplified* API on your own - it's very similar to previously shown here. 
> 
> For the next gestures I won't write any information about this option and let u experiment with it on your own.

### RotationGesture

Another one gesture on the list - `RotationGesture`. The purpose is pretty clear from the name - we can perform scale using 2 fingers on the screen and move them in a circular motion in the same direction.

`Value` for this gesture defined as next:

{% highlight swift %}
public typealias Value = Angle
{% endhighlight %}

`Angle` can be used to any transformation, for example:

{% highlight swift %}
struct RotationGestureDemoView: View {
    @GestureState private var rotationAngle: Angle = .zero
    
    var body: some View {
        Text("Hello")
            .padding(50)
            .background(Color.red)
            .cornerRadius(4)
            .hueRotation(rotationAngle)
            .gesture(
                RotationGesture()
                    .updating(
                        $rotationAngle,
                        body: { (value, state, transition) in
                            state = Angle(degrees: value.degrees)
                        }
                    )
            )
            .animation(.easeInOut)
    }
}
{% endhighlight %}
Result:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-30-gestures-in-swiftUI/demo_rotationGesture.gif" alt="demo_rotationGesture" width="550"/>
</div>

### MagnificationGesture

This is a new name for pinch and zoom gesture. To invoke it - use 2 fingers towards each other or away to zoom out or in.

`Value` for this gesture defined as next:

{% highlight swift %}
public typealias Value = CGFloat
{% endhighlight %}

We can experiment with this gesture using next snipet:

{% highlight swift %}
struct MagnificationGestureDemoView: View {
    @GestureState private var scaleAmount: CGFloat = 1
    
    var body: some View {
        Text("Hello")
            .padding(50)
            .background(Color.red)
            .cornerRadius(4)
            .scaleEffect(scaleAmount)
            .gesture(
                MagnificationGesture()
                    .updating(
                        $scaleAmount,
                        body: { (value, state, transition) in
                            state = value
                        }
                    )
            )
            .animation(.easeInOut)
    }
}
{% endhighlight %}

As result u can receive something like:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-30-gestures-in-swiftUI/demo_magnificationGesture.gif" alt="demo_magnificationGesture" width="550"/>
</div>

### HoverGesture

This gesture available for macOS/iPadOS, but we also may define it in iOS - the effect will be not visible. 

> on macOS in `UIKit` for the same effect may be used `UIHoverGestureRecognizer`

Trigger for this gesture - pointer over the object. Various howerEffect may highlight view element on pointer enter event.

{% highlight swift %}
struct HoverGestureDemoView: View {
    
    var body: some View {
        Text("Hello")
            .padding(50)
            .background(Color.red)
            .cornerRadius(4)
            .hoverEffect(.lift)
            .onHover(perform: { hovering in
                print("hower event triggered")
            })
    }
}
{% endhighlight %}

> To simulate on simulator we can use iPad, and use SimulatorMenu -> I/O -> Input -> Send pointer to device

## Combination of gestures

This is a very powerful feature of gestures that simplify usage of different gestures and so allow us to provide to user special interaction gestures, making unique feelings about any app.

The combination may be used in a few ways: by modifying the sequence of gestures or by specifying priorities of them in the view tree, or by configuring them to use simultaneously. To do so Apple included in SwiftUI a full set of tools:

- [`simultaneously(with:)`](https://developer.apple.com/documentation/swiftui/longpressgesture/simultaneously(with:))
- [`sequenced(before:)`](https://developer.apple.com/documentation/swiftui/longpressgesture/sequenced(before:))
- [`exclusively(before:)`](https://developer.apple.com/documentation/swiftui/longpressgesture/exclusively(before:))
- [`highPriorityGesture(_:including:)`](https://developer.apple.com/documentation/swiftui/view/highprioritygesture(_:including:))

We may grab some of this and create next sample:

{% highlight swift %}
struct CombinatedGestureDemoView: View {
    @GestureState private var dragTranslation: CGSize = .zero
    @GestureState private var isLongPressActivated = false
    @State private var isScaled = false
    
    var body: some View {
        Text("Hello")
            .padding()
            .background(isLongPressActivated ? Color.green: Color.red)
            .cornerRadius(4)
            .scaleEffect(isScaled ? 1.2 : 1)
            .offset(x: dragTranslation.width, y: dragTranslation.height)
            .gesture(
                LongPressGesture(minimumDuration: 1.0)
                    .updating(
                        $isLongPressActivated,
                        body: { (currentState, state, transaction) in
                            state = currentState
                        })
                    // on End LongPressGesture
                    .onEnded({ (_) in
                        isScaled = true
                    })
                    .sequenced(before: DragGesture())
                    .updating(
                        $dragTranslation,
                        body: { (value, state, transition) in
                            // value can contain as many sequence element as u added
                            switch value {
                            // select only one that we need
                            case .second(let isLongPressActivated, let dragValue) where isLongPressActivated == true:
                                state = dragValue?.translation ?? .zero
                            default:
                                break
                            }
                        }
                    )
                    // on End sequence
                    .onEnded({ (_) in
                        isScaled = false
                    })
            )
            .animation(.easeInOut)
    }
}
{% endhighlight %}

Result:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-30-gestures-in-swiftUI/demo_combinedGesture.gif" alt="demo_combinedGesture" width="550"/>
</div>
<br>


> Good sample of the composition of gesture available [here](https://developer.apple.com/documentation/swiftui/composing-swiftui-gestures)

## Conclusion

`SwiftUI` not only save for us all options available from `UIKit` in terms of gestures but also introduce a few new options within great simplification.

[download source code]({% link assets/posts/images/2020-12-30-gestures-in-swiftUI/source/gestures.zip %})
