---
layout: post
comments: true
title: "Navigation Bar background color in SwiftUI"
categories: article
tags: [iOS, SwiftUI, tutorial]
excerpt_separator: <!--more-->
comments_id: 2

author:
- kyryl horbushko
- Lviv
---


How many times do we need to change something in standard components supplied by Apple? Well, quite often, so I guess everything should be done keeping this simple thing in mind. But let's check `NavigationBar` in SwiftUI.

"Oh crap!" - u can say after the first 10 min of testing and trying to change something - it won't be easy to customize that :(. So today I want to tell u about my experience related to `NavigationBar` customization in SwiftUI.
<!--more-->

## history

Before we dive into SwiftUI detail, let's refresh our memory and see how it works on UIKit. To do so, we may review [official sample](https://developer.apple.com/documentation/uikit/uinavigationcontroller/customizing_your_app_s_navigation_bar). When we dive into details we can see that there is no direct method of changing `NavigationBar` background color, instead Apple <s>propose</s> force us to use `UIAppearence`. Just to recap - appearance is kind of a proxy that is used to modify something without direct change. And here is also limitation - we can't do that change `on the fly` because:

> iOS applies appearance changes **when a view enters a window, it doesn’t change the appearance of a view that’s already in a window**. To change the appearance of a view that’s currently in a window, remove the view from the view hierarchy and then put it back.


{% highlight swift %}
let appearance = UINavigationBarAppearance()
appearance.configureWithOpaqueBackground()
appearance.backgroundColor = UIColor.systemRed
appearance.titleTextAttributes = [.foregroundColor: UIColor.lightText] // With a red background, make the title more readable.
navigationItem.standardAppearance = appearance
navigationItem.scrollEdgeAppearance = appearance
navigationItem.compactAppearance = appearance // For iPhone small navigation bar in landscape.
{% endhighlight %}

This means that we change it through `navigationItem` of viewController in `viewDidLoad` method (for example). 

Another option is to use `UINavigationController` instance, like the following:

{% highlight swift %}
self.navigationController!.navigationBar.barStyle = .default
// Bars are translucent by default.
self.navigationController!.navigationBar.isTranslucent = true
// Reset the bar's tint color to the system default.
self.navigationController!.navigationBar.tintColor = nil
self.navigationController!.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.label]
{% endhighlight %}

and offcause use global settings:

{% highlight swift %}
let appearence = UINavigationBarAppearance()
appearence.configureWithOpaqueBackground()
appearence.backgroundColor = backgroundColor
appearence.titleTextAttributes = [.foregroundColor: tintColor]
appearence.largeTitleTextAttributes = [.foregroundColor: tintColor]
    
UINavigationBar.appearance().standardAppearance = appearence
UINavigationBar.appearance().scrollEdgeAppearance = appearence
UINavigationBar.appearance().compactAppearance = appearence
UINavigationBar.appearance().tintColor = tintColor
{% endhighlight %}

Did u see it? None of the above methods didn't provide an easy way of changing `backgroundColor`.  Why? There is must be some really good reason for that. Maybe this is due to `UIEffectsView` inside or due to `UIImageView` that serves as a background or due to some other points... 

This Appearance API can result in something like:

<br>
<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/24-11-2020-navigation-bar/demo_apearence_uikit.gif" alt="preview_1" width="250"/>
</div>
<br>

> here u can see color change using appearance on `viewDidLoad` and `viewDidAppear`

So the problem actually is quite old and developers always tried to make some workarounds on this - from accessing subviews and reverse engineering to developing their own custom `navigationBars`.

## swiftUI

Ok, how about `SwiftUI`. This technology should bring to us a new experience and easy-to-use API. Apple heard a lot of responses and hopefully make some appropriate changes.

> SwiftUI is an innovative, exceptionally simple way to build user interfaces across all Apple platforms with the power of Swift. ... With a declarative Swift syntax that's easy to read and natural to write, SwiftUI works seamlessly with new Xcode design tools to keep your code and design perfectly in sync. [from offcial](https://developer.apple.com/xcode/swiftui/#:~:text=SwiftUI%20is%20an%20innovative%2C%20exceptionally,with%20the%20power%20of%20Swift.&text=With%20a%20declarative%20Swift%20syntax,and%20design%20perfectly%20in%20sync.)

First look at the API created for `SwiftUI` and we see... nothing. Yes, nothing exists for changing `navigationBar` `backgroundColor`, at all - not even for appearance :(


<br>
<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/24-11-2020-navigation-bar/navigation_view_1.png" alt="preview_1" width="250"/>
</div>
<br>


Wow, that's a bit unexpected. You even don't have access to `NavigationController` anymore.

Starting from SwiftUI 2.0 (iOS 14) Apple add possibility to modify `navigationBar` via `toolbar`. 


{% highlight swift %}
NavigationView {
	// content
   .toolbar {
      ToolbarItem(placement: .principal) {
      		// do whatever u like
      }
   }
}
{% endhighlight %}

Better, but it's still tricky and non so easy as everyone wants. The question about the dynamic change of `backgroundColor` is still open. Even more - what about iOS 13? 

That the problem I faced with, like many other developers.

## solution

As u can imagine I have tested all appearance solutions and some other stuff also. Indeed I ended up with some, but first, let's see what I got.

Off cause, as u maybe already think about my first attempt was to use global appearance, but even without trying I assumed that this won't for dynamic change thus it mention in the doc

> iOS applies appearance changes **when a view enters a window, it doesn’t change the appearance of a view that’s already in a window**. To change the appearance of a view that’s currently in a window, remove the view from the view hierarchy and then put it back.

Anyway, this is quite a good solution for those who have a constant color of navigationBar.


{% highlight swift %}
let appearence = UINavigationBarAppearance()
appearence.configureWithOpaqueBackground()
appearence.backgroundColor = backgroundColor
appearence.titleTextAttributes = [.foregroundColor: tintColor]
appearence.largeTitleTextAttributes = [.foregroundColor: tintColor]
    
UINavigationBar.appearance().standardAppearance = appearence
UINavigationBar.appearance().scrollEdgeAppearance = appearence
UINavigationBar.appearance().compactAppearance = appearence
UINavigationBar.appearance().tintColor = tintColor
{% endhighlight %}

to make it shiny we can even create `View` `modifier`:

<script src="https://gist.github.com/khorbushko/20bbcf44eb4542eef20007bb231bf3ff.js"></script>

but - remember **pitfall** - it won't work for cases when u need to change color dynamically, like I want, so moving forward.

Next attempt - to change `backgroundColor` directly on `navigationBar`. How to achieve this? Well, let's think about `navigationBar` - every `viewController` has its own configuration related to used `NavigationController`. How to access this property? Aha - childViewController - when it attached to `viewcontroller` with `navigationController` - access granted :). How to attach? `UIViewControllerRepresentable` is here to rescue. So basically we need to create a viewModifier that attaches viewController and get access to `navigationBar` for future manipulation. Sounds like a good approach to go. Let's do this:

<script src="https://gist.github.com/khorbushko/c38db74d8c801336bb9d605f77bac62b.js"></script>

> for modification `navigationBar` I used extenstion
> 
> there are few other `AppearenceType` props, but for a test - this is ok to go

Usage:


{% highlight swift %}
.configureNavigationBar {
    $0.switchToAppearence(.defaultLight)
}
{% endhighlight %}

Ok, it's time to play. 

"Just add modified for our view and everything should work like a charm" - I was thinking :). Indeed - it works, when u attach it and change on-the-flay, but not for the case when u open the screen momentary and want to change color instantly. Why? The reason is quite simple - view modifier don't attach our `viewController` as child momentary and so we haven't access to `navigationBar` at the very first moment of modifier usage :( This is because `coordinator` firstly creates an object, that calls modify callback and then attaches to our view - but what we need - it's slightly another sequence.

I can think about playing within `navigationItem` property in an similar way or some other alternatives (like iterate subview that is not preferable at all)... but the result will be the same because of the process of combining `SwiftUI` and `UIKit` is the same...

So, what is my solution then? Ugly one :( - I switched `navigationBar` into `transparent` mode and every view that is needed to be modified has a `ZStack` with color that extends `safeArea` and the actual content. Not the perfect one.

So this is one more improvement that needs to be done for `SwiftUI`.