---
layout: post
comments: true
title: "First look at WindowGroup"
categories: article
tags: [iOS, macOS, SwiftUI, WindowGroup, SceneBuilder]
excerpt_separator: <!--more-->
comments_id: 39

author:
- kyryl horbushko
- Lviv
---

Within SwiftUI 2.0 we got an option to create a pure SwiftUI app (at least a minimal one). To make this possible, Apple introduces [`WindowGroup`](https://developer.apple.com/documentation/swiftui/windowgroup) - *"a scene that presents a group of identically structured windows."* 

This view has power only for platforms, that support multi-windows - macOS and iPadOS. In addition to this, this view allows to group opened windows into the tabbed interface. 
<!--more-->

## @SceneBuilder

`WindowGroup` can be used within `@main` attribute (an attribute that creates a new-style entry point for the app, introduces in [SE-0281](https://github.com/apple/swift-evolution/blob/master/proposals/0281-main-attribute.md)).

{% highlight swift %}
@main
struct TestApplication: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
{% endhighlight %}

> read more about [`@main`]({% post_url 2021-01-21-entry-point %})

If we check the declaration, we can see, that `WindowGroup` conforms to `Scene` protocol, as `DocumentGroup` and `Settings`. These types of views can be used as `@SceneBuilder`'s for the app. For other platforms such as WatchKit there are few other types (for example [`WKNotificationScene`](https://developer.apple.com/documentation/swiftui/wknotificationscene)).

> `SceneBuilder` - allows combining few scenes into one
> 
{% highlight swift %}
@_functionBuilder public struct SceneBuilder {
    public static func buildBlock<Content>(_ content: Content) -> Content where Content : Scene
}
{% endhighlight %}

We also can create our custom View that conforms to `Scene` protocol and use it:

{% highlight swift %}
struct MyScene: Scene {
  var body: some Scene {
    WindowGroup {
      MyView()
        .frame(width: 200, height: 200)
        .background(Color.red)
    }
  }
}

struct MyView: View {
  var body: some View {
    Text("Aloha")
  }
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-25-window-group/singleView.png" alt="singleView" width="250"/>
</div>
<br>
<br>

In `@SceneBuilder` we also can create and use a few scenes - as I mentioned above, out of the box available [`WindowGroup`](https://developer.apple.com/documentation/swiftui/windowgroup), [`DocumentGroup`](https://developer.apple.com/documentation/swiftui/documentgroup) and [`Settings`](https://developer.apple.com/documentation/swiftui/settings).

If we do so, behavior directly depends on the order and used types of scenes that we have used.

## Commands

Within any type we also receive an ability to create and modify menu-commands:

{% highlight swift %}
WindowGroup {
      ContentView()
        .frame(width: 200, height: 200)
    }
    .commands {
      CommandMenu("MyMenu") {
        Button("MyMenu Action") {
          // do stuff here
        }
        .keyboardShortcut("w")
      }
    }
{% endhighlight %}

> `@CommandsBuilder` is used here - this is yet another builder, but it works only within `Command`

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-25-window-group/command-menu.png" alt="command-menu" width="350"/>
</div>
<br>
<br>

> Note: u can use `.commands` viewModifier on any scene in your `@SceneBuilder`, all of them will take an effect, no matter on which type u define it.

If u would like to remove/replace any command in the menu, use specially designed view modifiers:

{% highlight swift %}
  .commands {
    CommandGroup(replacing: .newItem, addition: { })
  }
{% endhighlight %}

In addition to custom commands, u also receive a few free actions:

- new window
- all tabs
- preferences (later about it)

### New window

Using File/New window app will create the same window one more time.

### All tabs

Using View/Show all tabs - we can receive a preview of all related to this window tabs opened right now

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-25-window-group/show-all-window.gif" alt="show-all-window" width="300"/>
</div>
<br>
<br>

### Preferences

Preferences menu automatically bind `Settings` from u'r scene builder to this action.

{% highlight swift %}
Settings {
  VStack {
    Text("Bonjur")
  }
  .frame(width: 300, height: 400)
}
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-25-window-group/settings-one.png" alt="settings" width="200"/>
</div>
<br>
<br>

If u didn't define `Settings`, then, nothing will be shown.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-25-window-group/settings-no.png" alt="settings" width="200"/>
</div>
<br>
<br>

If u define few `Settings` in your `@SceneBuilder`, u get as many Preferences in menu as u define:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-25-window-group/settings-2.png" alt="settings" width="200"/>
</div>
<br>
<br>

> At the moment of writing (xCode Version 12.4 (12D4e) and Swift 5.4), as u can see on the screenshot, the hot-key combination is the same for each menu, and any of this submenu will display only the very first defined `Settings` from u'r scene builder. I believe this is a bug in SwiftUI, and this will be fixed in the next releases.

## Multiple Scenes in builder

We can define also a few scenes in our scene builder, but, as I mentioned above, the first one only will be displayed. 

{% highlight swift %}
WindowGroup {
  ContentView()
    .frame(width: 200, height: 200)
}
.commands {
  CommandMenu("MyMenu") {
    Button("MyMenu Action") {
      // do stuff here
    }
    .keyboardShortcut("w")
  }
}
    
WindowGroup {
  MyView()
    .frame(width: 200, height: 200)
    .background(Color.red)
}
{% endhighlight %}

So, how to switch between them? The answer is - [`handlesexternalevents(matching:)`](https://developer.apple.com/documentation/swiftui/group/handlesexternalevents(matching:)). 

This view modifier *" specifies a modifier to indicate if this Scene can be used when creating a new Scene for the received External Event".*

> `External Event` - is a bit intriguing definition of something. I didn't find any explanation from Apple for this that include a complete list of this stuff, but I assume that this includes at least :
> 
- [universal links](https://developer.apple.com/ios/universal-links/)
- [SiriKit](https://developer.apple.com/documentation/sirikit)
- [Spotlight](https://developer.apple.com/documentation/foundation/spotlight)
- [Handoff](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/Handoff/HandoffFundamentals/HandoffFundamentals.html#//apple_ref/doc/uid/TP40014338)
- other ? (not sure about them)

Usage of this viewModifier a bit tricky. First of all - we have 2 versions of this modifier:

 - `handlesExternalEvents(matching:)`
 - `handlesExternalEvents(preferring:, allowing:)`
 
The first one (as it mentioned in doc) - *"is only supported for WindowGroup Scene types"*. And to use it, we should use deep link:
 
{% highlight swift %}
.handlesExternalEvents(matching: ["myScene"])
{% endhighlight %}

we can define a matching condition, that will be checked and if it succeeds, an appropriate window will be called. 

To do so, we should :

1. Define URL Scheme, for example: *"myApp"*:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-25-window-group/urlScheme.png" alt="urlScheme" width="300"/>
</div>
<br>
<br>

2. use `openURL` using [`OpenURLAction`](https://developer.apple.com/documentation/swiftui/openurlaction) to call this deep link:

{% highlight swift %}
@main
struct testWindowGroupApp: App {
  
  @Environment(\.openURL) var openURL
  
  var body: some Scene {
    
    WindowGroup {
      ContentView()
        .frame(width: 200, height: 200)
    }
    .commands {
      CommandMenu("MyMenu") {
        Button("Show my Scene") {
          openURL(URL(string: "myApp://myScene")!)
        }
        .keyboardShortcut("w")
      }
    }
    .handlesExternalEvents(matching: ["main"])
    
    MyScene()
      .handlesExternalEvents(matching: ["myScene"])
...
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-25-window-group/demo_openURL.gif" alt="demo_openURL" width="350"/>
</div>
<br>
<br>

> additional post on Apple developer forum [here](https://developer.apple.com/forums/thread/651592?answerId=651132022#651132022) or this [SO question](https://stackoverflow.com/questions/62915324/swiftui-2-the-way-to-open-view-in-new-window)

Second, `handlesExternalEvents(preferring:, allowing:)`, can be used on any view within any scene, but only for platforms, that supports it. 

In our case, we can use it, to make sure, that `main` window will be only one:

{% highlight swift %}
WindowGroup {
  ContentView()
    .frame(width: 200, height: 200)
    .handlesExternalEvents(preferring: ["main"], allowing: ["*"])
}
{% endhighlight %}

## Pitfalls and limitation

### Full control of window

To get full control on an `NSWindow` object on macOS, u should still refer to AppKit (for example, by using `NSViewRepresentable`).

In some situations u still need to use good, old `NSApplicationDelegate`:

{% highlight swift %}
@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
{% endhighlight %}

or by using some instance/static properties from `NSWindow`.

### Data sharing between scenes

To share data between scenes in scene builder u can use one of the next approaches:

- share viewModel object and hold reference in view marked with `@main` attribute. Note, that each `Scene` has its state management machine (if I can name it like this). This means, that each @State and other similar propertyWrappers and attributes work independently.
- use serialization and shared storage 

### macOS menu bar extras app

If u want to create a pure SwiftUI macOS app that acts as [`LSUIElement`](https://developer.apple.com/documentation/bundleresources/information_property_list/lsuielement) and when u click on some of the menu items a new window should appear, u will get a lot of issues.

> *["Menu Bar Extras"](https://developer.apple.com/design/human-interface-guidelines/macos/extensions/menu-bar-extras/)* is an official name for icons in the menu bar. Often it's called status-bar items, but this is not an official name.

As on my trials, I got next:

- sometimes selected scene is not shown (needs to click a few times on the button to make it workable)
- sometimes copy of menu-bar extras created (even if u create an `NSMenu` only for a dedicated window)

Also, it's good to note, that u should still use `NSMenu` and `NSMenuItem` to make menu bar extras (there is no mechanism in SwiftUI for this; yet?).

> As a workaround to issues described above, I used `NSWindow`.

[download source code]({% link assets/posts/images/2021-04-25-window-group/source/testWindowGroup.zip %})


## Resources

* [`WindowGroup`](https://developer.apple.com/documentation/swiftui/windowgroup)
* [`Settings`](https://developer.apple.com/documentation/swiftui/settings)
* [`DocumentGroup`](https://developer.apple.com/documentation/swiftui/documentgroup)
* [Managing scenes in SwiftUI](https://swiftwithmajid.com/2020/08/26/managing-scenes-in-swiftui/)
* [Human Interface Guidelines on Menu Bar Extras](https://developer.apple.com/design/human-interface-guidelines/macos/extensions/menu-bar-extras/)
* [NSUserActivity with SwiftUI](https://swiftui-lab.com/nsuseractivity-with-swiftui/)
* [WWDC 10037](https://developer.apple.com/videos/play/wwdc2020/10037/)
* [SO Understanding Scene/WindowGroup in SwiftUI 2?](https://stackoverflow.com/questions/62851510/understanding-scene-windowgroup-in-swiftui-2)
* [How to manage WindowGroup in SwiftUI for macOS](https://onmyway133.com/posts/how-to-manage-windowgroup-in-swiftui-for-macos/)