---
layout: post
comments: true
title: "DynamicProperty"
categories: article
tags: [iOS, SwiftUI, propertyWrapper]
excerpt_separator: <!--more-->
comments_id: 22

author:
- kyryl horbushko
- Lviv
---

With `SwiftUI` we are already faced with a bunch of specially designed `@propertyWrappers`. But, the number of developers who use `SwiftUI` constantly increasing, the problems that they are trying to solve also increasing quite fast. As result, we would like to combine different functions and provide our specific wrapper that should also trigger an update of `View` in `SwiftUI` world.
<!--more-->

> Example may be analog to `@FetchRequest` but for *photos* or fetch request but for a custom database such as `Firebase`. Or simply for some internal logic that wraps some aspect into compact representation.

To do this - we may inspect existing triggers (`@propertyWrappers`) for `View` updates. All of them conform to one protocol - `DynamicProperty`.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-01-08-dynamicProperty/conformingTypes.png" alt="conformingTypes" width="400"/>
</div>
<br>

## DynamicProperty

If we check [documentation](https://developer.apple.com/documentation/swiftui/dynamicproperty) there is not too much - *An interface for a stored variable that updates an external property of a view.* At least we can get an idea - if adopt this protocol, a view should **react** to any changes when property receives updates (changes). 

If we go inside the header and check requirements, we can find, that:

{% highlight swift %}
public protocol DynamicProperty {

    /// Updates the underlying value of the stored value.
    ///
    /// SwiftUI calls this function before rending a view's
    /// ``View/body-swift.property`` to ensure the view has the most recent
    /// value.
    mutating func update()
}

extension DynamicProperty {

    /// Updates the underlying value of the stored value.
    ///
    /// SwiftUI calls this function before rending a view's
    /// ``View/body-swift.property`` to ensure the view has the most recent
    /// value.
    public mutating func update()
}
{% endhighlight %}

The only requirements - `func update()`. As we can see from both header and official doc - `update` is already implemented for us. 

> from [doc](https://developer.apple.com/documentation/swiftui/dynamicproperty) *Required. Default implementation provided.*

Looks like everything simple - we create our own `@propertyWrapper`, conform to `DynamicProperty` protocol, and `View` will respect any changes in it and display appropriate changes on the screen for us. Pretty simple, let's try it.

> Note here - I'm talking about `@propertyWrapper` and `DynamicProperty`, but actually `DynamicProperty` hasn't any limitation, and in theory, anything can adopt it. 
> 
> Both will compile successfully:
>
{% highlight swift %}
class ExampleClass: DynamicProperty { }
struct ExampleStruct: DynamicProperty { }
{% endhighlight %}

## Example

We can test `DynamicProperty` by creating our custom `@propertyWrapper` that simply stores some *Value* and as result, any change should be reflected in `View` (something similar to `@State`).

{% highlight swift %}
@propertyWrapper
struct StoredValue<T>: DynamicProperty where T: DefaultValueProvidable {
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.value(forKey: "testKey.storedValue") as? T ?? T.defaultValue()
        }
        nonmutating set {
            UserDefaults.standard.setValue(newValue, forKey: "testKey.storedValue")
        }
    }
    
    init(wrappedValue value: T) {
        self.wrappedValue = value
    }
}

protocol DefaultValueProvidable {
    static func defaultValue() -> Self
}

extension Int: DefaultValueProvidable {
    static func defaultValue() -> Self {
        0
    }
}
{% endhighlight %}

View for test purpose will show some text and action that will update our value. In the same moment text appearance depends on value:

{% highlight swift %}
struct DynamicTestView: View {
    
    @StoredValue private var testValue: Int = 0
    
    var body: some View {
        VStack {
            Text("Testing DynamicProperty")
                .padding()
                .background(testValue % 2 == 0 ? Color.red : Color.green)
            
            Button(action: {
                testValue += 1
            }, label: {
                Text("Tap")
            })
        }
    }
}
{% endhighlight %}

`update` should be called automatically by the `SwiftUI` engine. But, when we launch the app and press the button - nothing happens. 

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-01-08-dynamicProperty/demo_firstTry.gif" alt="demo_firstTry" width="350"/>
</div>
<br>

Why? Here we have a few moments:

1. how `SwiftUI` determine that something is changed?
2. how the `SwiftUI` call the `update` function (as for struct it doesn't allow you to call a mutating function)?

The first question is very interesting. As u can see from the example above, we got no success in making workable `DynamicProperty`. But, as soon as we can change a bit implementation, by injecting usage of existing `SwiftUI` any `DynamicProperty` as a kind of storage for our value, it works as expected:

{% highlight swift %}
@propertyWrapper
struct StoredValue<T>: DynamicProperty  {

    final private class Storage: ObservableObject {
        var value: T {
            willSet {
                objectWillChange.send()
            }
        }

        init(_ value: T) {
            self.value = value
        }
    }

    @ObservedObject private var storage: Storage

    var wrappedValue: T {
        get {
            storage.value
        }
        nonmutating set {
            storage.value = newValue
        }
    }

    init(wrappedValue value: T) {
        self.storage = Storage(value)
    }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-01-08-dynamicProperty/demo_secondTry.gif" alt="demo_secondTry" width="350"/>
</div>
<br>

The answer to question number 1 (*how `SwiftUI` determine that something is changed?*) maybe next: `SwiftUI` introspect children in type and check values for change events using some internal mechanism.

> A bit more deep dive in how difference is determined by inspecting `@State` is [available here](https://kateinoigakukun.hatenablog.com/entry/2019/06/08/232142)

And as a sample we may refer to [discussion on Swift forum](https://forums.swift.org/t/dynamicviewproperty/25627/5) related to this topic and [custom implementation of `update` function](https://github.com/SwiftWebUI/SwiftWebUI/blob/18cbd100d360432cbc38142f8571176776953450/Sources/SwiftWebUI/Properties/DynamicViewProperty.swift#L55):

{% highlight swift %}
  static func update<V: View>(_ view: inout V, in context: TreeStateContext) {
    guard case .dynamic(let props) = view.lookupTypeInfo() else { return }
    
    currentContext = context
    props.forEach { $0.updateInView(&view) }
    currentContext = nil
  }
{% endhighlight %}

The same idea used for this approach - check the type and update the view.

But still, we have unanswered question number 2 (*how the `SwiftUI` calls the `update` function?*). On the same thread on the Swift forum we may found a few suggestions on how it can be done, and as mentioned by **Helge_Hess1**:

> *To make the View's value "mutable" one just casts the pointer to a mutable one. Which explains why this works even if the properties are defined as let. Not sure whether that is sound (optimizer might layout the properties differently?), but I guess the layout should be stable as part of the "ABI".*
> 
{% highlight swift %}
    let typedPtr = location.assumingMemoryBound(to: Self.self)
    typedPtr.pointee.update()
{% endhighlight %}

Now, it's become more clear - why only `SwiftUI` `DynamicProperties` (an initial name `DynamicViewProperty`) works in such way: all data stored in some external memory and all changes tracked by some internal mechanism, change is done in swift runtime. A bit complex idea, but the result is great (in my opinion).

## Update

> 19.04.2022


Thanks to comment from *@Chris Eidhof* - 
> `StoredValue` implementation you should be using a `StateObject` instead of `ObservedObject`. 

With usage of `@ObservedObject` property storage will be shared (in our case counter), with `@StateObject` - independen.

Here is a small test code:

{% highlight swift %}
struct Nested: View {
  @StoredValue var value = 0

  var body: some View {
    Button("Counter \(value)") {
      value += 1
    }
  }
}

struct DynamicTestView: View {
  @StoredValue private var testValue: Int = 0

  var body: some View {
    let n = Nested()
    VStack {
      n
      n
    }
  }
}
{% endhighlight %}

> this also require update init of `@StoredValue` with `_storage = StateObject(wrappedValue: Storage(value))`

Result:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-01-08-dynamicProperty/comparison_demo.gif">
<img src="{{site.baseurl}}/assets/posts/images/2021-01-08-dynamicProperty/comparison_demo.gif" alt="comparison_demo.gif" width="400"/>
</a>
</div>
<br>
<br>

## Resources

1. [Thread at Swift forum](https://forums.swift.org/t/dynamicviewproperty/25627)
2. [SwiftUIWeb](https://github.com/SwiftWebUI/SwiftWebUI)
3. [Inside `@State`](https://kateinoigakukun.hatenablog.com/entry/2019/06/08/232142)
4. [Data Flow Through SwiftUI](https://vmanot.com/data-flow-through-swiftui)
5. [Stackoverflow question](https://stackoverflow.com/questions/59580065/is-it-correct-to-expect-internal-updates-of-a-swiftui-dynamicproperty-property-w)

[download source code]({% link assets/posts/images/2021-01-08-dynamicProperty/source/dynamicTestView.swift.zip %})