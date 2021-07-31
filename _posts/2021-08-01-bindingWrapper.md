---
layout: post
comments: true
title: "BindingWrapper"
categories: article
tags: [iOS, SwiftUI, DynamicProperty]
excerpt_separator: <!--more-->
comments_id: 53

author:
- kyryl horbushko
- Lviv
---

Displaying changes instantly is great, but not always. `SwiftUI` gave us a great mechanism for this, and we love it.

Often, when we have a deal with a mobile application such behavior is exactly what we want. But imagine a situation, when on such a change u should perform a kind of heavy operation - in this case, the output of such behavior is a bit not what we want.
<!--more-->

The real case - imagine that u have a filter, and the user should be able to select 10 or more filter categories and apply them all at once or change his mind and cancel this operation. At the same moment, we want to use `SwiftUI` and show everything on screen using this great binding system.

## BindingWrapper

I am faced with this problem on a current project. As result, I think, that it would be great if we can make kind of `@Binding` but on additional action.

The regular `@Binding` we can describe as following:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-08-01-bindingWrapper/regular_binding.png" alt="idea" width="450"/>
</div>
<br>
<br>

And the one that we need to solve proble described above:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-08-01-bindingWrapper/controllableBinding.png" alt="idea" width="450"/>
</div>
<br>
<br>

To do so, we can create data copy, modify it and commit from the user gave it back. To save the same functionality as `@Binding` we can do next:


1. store 2 versions of data - initial (input) and the one that is currently active

{% highlight swift %}
@Binding private var active: Type
@Binding private var original: Type
{% endhighlight %}

2. create `@Published` property for displaying any changes and handling proxy state 

{% highlight swift %}
@Published var proxy: Type
{% endhighlight %}

3. on init `View` perform a `dance`

{% highlight swift %}
self._original = inputBinding
viewModel.sortBy = inputBinding.wrappedValue
self._active = $viewModel.proxy
{% endhighlight %}

4. on `commit` send data

{% highlight swift %}
_original.wrappedValue = viewModel.proxy
{% endhighlight %}

Such an approach work, but... it's not the best from the code perspective of view - too many things we need to write every time, too many parts separated all over the app. 

So I decided to make it compact and wrap it into stuct. The result is next:

{% highlight swift %}
struct BindingWrapper<T> {
  private final class Proxy<T>: ObservableObject {
    @Published var proxy: T
    init(value: T) {
      proxy = value
    }
  }
  
  @Binding private var originalValue: T
  @Binding var value: T
  @ObservedObject private var proxy: Proxy<T>
  
  init(value: Binding<T>) {
    _originalValue = value
    _value = value
    
    proxy = .init(value: value.wrappedValue)
    _value = $proxy.proxy
  }
  
  func commit() {
    _originalValue.wrappedValue = proxy.proxy
  }
}
{% endhighlight %}

Looks like that everything is ok, but if u try to use this in the code - nothing happens, updates are not received. The reason - because `View` doesn't know that u'r struct backed store changed... 

A naive approach to fix this would be to use the `@State` modifier for this property, but in this case, u need to set the default value - this is not the good approach for the `@Binding` value.

The correct way would be simple conformance to the [`DynamicProperty`](https://developer.apple.com/documentation/swiftui/dynamicproperty).

{% highlight swift %}
struct BindingWrapper<T>: DynamicProperty
{% endhighlight %}

> read more about [`DynamicProperty` on my prev post here]({% post_url 2021-01-08-dynamicProperty %}).

Now, everything works as expected - View can show binding value instantly, but sending value out of the view - this is a task for a final user.

Here is a quick demo:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-08-01-bindingWrapper/demo.gif" alt="idea" width="250"/>
</div>
<br>
<br>

## Resources

* [`DynamicProperty`](https://developer.apple.com/documentation/swiftui/dynamicproperty)