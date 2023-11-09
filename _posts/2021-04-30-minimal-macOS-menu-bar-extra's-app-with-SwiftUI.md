---
layout: post
comments: true
title: "Minimal macOS menu bar extra's app with SwiftUI"
categories: article
tags: [macOS, SwiftUI, menu bar extra]
excerpt_separator: <!--more-->
comments_id: 40

author:
- kyryl horbushko
- Lviv
---

Creating a minimal utility app for macOS is quite often needs. Such an app is always available in the menu bar and can perform some operation with just a few clicks or some shortcut can show information instantly.
<!--more-->

> Good catch from [@liemeldert](https://github.com/liemeldert) - 
> 
> *I just wanted to bring your attention to the addition of MenuBarExtras into native SwiftUI. [Here's their docs](https://developer.apple.com/documentation/swiftui/menubarextra)*
> 
> so please also refer to this doc.

When I facing some problem, that requires the same and same activities, I always try to automate it or at least minimize it. Menu bar extra's app - may be a perfect solution for this.

> *["Menu Bar Extras"](https://developer.apple.com/design/human-interface-guidelines/macos/extensions/menu-bar-extras/)* is an official name for icons in the menu bar. Often it's called status-bar items, but this is not an official name.

SwiftUI allows us to build apps much faster, so we can use it for this purpose as well.

> Check [this web resource](https://macmenubar.com/) for a curated list of menu bar extra's

## The way

One of the reasons why I love programming is that because u can solve one task in at least 2 ways. Making menu bar extra's is not an exception. The most popular variant is:

- Using [`NSPopover`](https://developer.apple.com/documentation/appkit/nspopover)
- Using [`NSMenu`](https://developer.apple.com/documentation/appkit/nsmenu)

I personally preferer a way that uses `NSMenu` - as for me it looks and feels much better. Apple also recommends this *"Display a menu—not a popover—when the user clicks your menu bar extra"*.

> If u are wondering how u can achieve the same with `NSPopover`, check for example [this article](https://medium.com/@acwrightdesign/creating-a-macos-menu-bar-application-using-swiftui-54572a5d5f87) and if u need a pure AppKit implementation check [this one](https://www.appcoda.com/macos-status-bar-apps/)

## SwiftUI implementation

Unfortunately, we can't create the macOS bar extra's app without AppKit, by using only SwiftUI. So, we should use `NSMenu` and `NSMenuItem`.

> I won't cover best practices and recommendations from Apple to not rely on menu bar items and to provide an option to allow users to decide show or not menu bar icons, etc. Instead, I just cover how to create a minimal app.

### Configure menu

Let's define our menu structure:

{% highlight swift %}
private func createMenu() {
	if let statusBarButton = statusItem.button {
	  statusBarButton.image = NSImage(
	    systemSymbolName: "hammer",
	    accessibilityDescription: nil
	  )
	  
	  let groupMenuItem = NSMenuItem()
	  groupMenuItem.title = "Group"
	  
	  let groupDetailsMenuItem = NSMenuItem()
	  groupDetailsMenuItem.view = mainView
	  
	  let groupSubmenu = NSMenu()
	  groupSubmenu.addItem(groupDetailsMenuItem)
	  
	  let mainMenu = NSMenu()
	  mainMenu.addItem(groupMenuItem)
	  mainMenu.setSubmenu(groupSubmenu, for: groupMenuItem)
	  
	  let secondMenuItem = NSMenuItem()
	  secondMenuItem.title = "Another item"
	  
	  let secondSubMenuItem = NSMenuItem()
	  secondSubMenuItem.title = "SubItem"
	  secondSubMenuItem.target = actionHandler
	  secondSubMenuItem.action = #selector(ActionHandler.onItemClick(_:))
	  
	  let secondSubMenu = NSMenu()
	  secondSubMenu.addItem(secondSubMenuItem)
	  
	  mainMenu.addItem(secondMenuItem)
	  mainMenu.setSubmenu(secondSubMenu, for: secondMenuItem)
	  
	  
	  let rootItem = NSMenuItem()
	  rootItem.title = "One more action"
	  rootItem.target = actionHandler
	  rootItem.action = #selector(ActionHandler.rootAction(_:))
	  
	  mainMenu.addItem(rootItem)
	  
	  statusItem.menu = mainMenu
	}
}
{% endhighlight %}

This will create for use structure within few submenus, custom SwiftUI view, and actions.

> As soon as u retain `NSStatusItem`, a menu will become available, if u release the variable - then a menu will disappear.

### Retain menu

The next step - is to define a proper point to set the menu and to configure `NSStatusBar` and `NSStatusItem`.

> If u put it before the app is ready for this (before all parts of the app initialized and ready), u can get an assertion like 
> 
> *"Assertion failed: (CGAtomicGet(&is_initialized)), function CGSConnectionByID, file /AppleInternal/BuildRoot/Library/Caches/com.apple.xbs/Sources/SkyLight/SkyLight-570.7/SkyLight/Services/Connection/CGSConnection.mm, line 133."*

The correct place - is when the application did finish launch, but within SwiftUI pure app and @main attribute, this is not available anymore. The solution for this - is to use [`NSApplicationDelegateAdaptor`](https://developer.apple.com/documentation/swiftui/nsapplicationdelegateadaptor) - *"a property wrapper that is used in App to provide a delegate from AppKit"*:

{% highlight swift %}
@main
struct testMenuBarExtraApp: App {
  
  @NSApplicationDelegateAdaptor(AppDelegate.self)
  private var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
{% endhighlight %}

then, we can create `AppDelegate`, and configure everything thereby using `applicationDidFinishLaunching(_:)`:

{% highlight swift %}
import Foundation
import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
  
  private var menuExtrasConfigurator: MacExtrasConfigurator?

  final private class MacExtrasConfigurator: NSObject {
    
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var mainView: NSView
    
    private struct MenuView: View {
      var body: some View {
        HStack {
          Text("Hello from SwiftUI View")
          Spacer()
        }
        .background(Color.blue)
        .padding()
      }
    }
    
    // MARK: - Lifecycle
    
    override init() {
      statusBar = NSStatusBar.system
      statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
      mainView = NSHostingView(rootView: MenuView())
      mainView.frame = NSRect(x: 0, y: 0, width: 300, height: 250)
      
      super.init()
      
      createMenu()
      
      //
    }
    
    // MARK: - Private
    
    // MARK: - MenuConfig
    
    private func createMenu() {
      if let statusBarButton = statusItem.button {
        statusBarButton.image = NSImage(
          systemSymbolName: "hammer",
          accessibilityDescription: nil
        )
        
        let groupMenuItem = NSMenuItem()
        groupMenuItem.title = "Group"
        
        let groupDetailsMenuItem = NSMenuItem()
        groupDetailsMenuItem.view = mainView
        
        let groupSubmenu = NSMenu()
        groupSubmenu.addItem(groupDetailsMenuItem)
        
        let mainMenu = NSMenu()
        mainMenu.addItem(groupMenuItem)
        mainMenu.setSubmenu(groupSubmenu, for: groupMenuItem)
        
        let secondMenuItem = NSMenuItem()
        secondMenuItem.title = "Another item"
        
        let secondSubMenuItem = NSMenuItem()
        secondSubMenuItem.title = "SubItem"
        secondSubMenuItem.target = self
        secondSubMenuItem.action = #selector(Self.onItemClick(_:))
        
        let secondSubMenu = NSMenu()
        secondSubMenu.addItem(secondSubMenuItem)
        
        mainMenu.addItem(secondMenuItem)
        mainMenu.setSubmenu(secondSubMenu, for: secondMenuItem)
        
        
        let rootItem = NSMenuItem()
        rootItem.title = "One more action"
        rootItem.target = self
        rootItem.action = #selector(Self.rootAction(_:))
        
        mainMenu.addItem(rootItem)
        
        statusItem.menu = mainMenu
      }
    }

    // MARK: - Actions
    
    @objc private func onItemClick(_ sender: Any?) {
      print("Hi from action")
    }
    
    @objc private func rootAction(_ sender: Any?) {
      print("Hi from root action")
    }
  }
  
  // MARK: - NSApplicationDelegate
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    menuExtrasConfigurator = .init()
  }
}
{% endhighlight %}

Result:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-30-minimal-macOS-menu-bar-extra's-app-with-SwiftUI/result_step1.png" alt="result_step1" width="350"/>
</div>
<br>
<br>

If u check menu actions - all also works, as we expect:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-30-minimal-macOS-menu-bar-extra's-app-with-SwiftUI/test_actions.png" alt="test_actions" width="250"/>
</div>
<br>
<br>

### Hide unnecessary view

I guess u already noted, that `ContentView` is also displayed, but this is not what we want.

The next task - is to get rid of UI, that is displayed on the app star, thus we want to get the menu bar app. To do so, we should tell to macOS, that we would like to have a background application. We can achieve this by modifying `Info.plist` and adding a special flag - [`LSUIElement`](https://developer.apple.com/documentation/bundleresources/information_property_list/lsuielement).

{% highlight xml %}
<key>LSUIElement</key>
<true/>
{% endhighlight %}

> You can find even more spesific keys for `Info.plist` [here](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html).
> 
> In really - we can use this flag, but this isn't something that was created especially for the described purpose. As was [mention by Apple](https://developer.apple.com/library/archive/technotes/tn2083/_index.html) - an agent is an application without UI that works in bg. So, sometimes it's better to perform process transformation instead of simply putting a key into `Info.plist`:
> 
{% highlight c++ %}
// into agent
ProcessSerialNumber processID = { 0, kCurrentProcess };
OSStatus status = TransformProcessType(&psn, kProcessTransformToUIElementApplication);
// and back
ProcessSerialNumber processID = { 0, kCurrentProcess };
OSStatus status = TransformProcessType(&psn, kProcessTransformToForegroundApplication);
{% endhighlight %}

Now, run u'r app - u can see, that icon in the dock is not appears anymore, but the menu icon is still available and fully functional.

To make things even better, we can replace the content of `@SceneBuilder` in type annotated with `@main` attribute with :

{% highlight swift %}
WindowGroup {
  EmptyView()
    .frame(width: .zero)
}
{% endhighlight %}

> If u not change the frame of the EmptyView, u will see a window within the default frame. I guess this is some point for improvement in SwiftUI and this may be changed in the future.

or 

{% highlight swift %}
Settings {
  EmptyView()
}
{% endhighlight %}

> if u select app and press `CMD+,`, Preferences window will be shown. This is downside of the second approach.
<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-30-minimal-macOS-menu-bar-extra's-app-with-SwiftUI/preferences.png" alt="preferences" width="750"/>
</div>
<br>
<br>

Both variants are not ideal and have their own +/-. I Hope, this will be improved a bit in the next SwiftUI releases.

----

A great addition was added by **@marc-medley** (see comments) regarding `LSUIElement`:

If `Info.plist` is manually added and edited, then the project build settings needs to be updated to not use the `GENERATE_INFOPLIST_FILE` **"Generated Info.plist File"** AND to *know where to find* the manually added `INFOPLIST_FILE` `"Info.plist File"`.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-30-minimal-macOS-menu-bar-extra's-app-with-SwiftUI/finding.png" alt="finding.png" width="450"/>
</div>
<br>
<br>

### Open separate window

Often, we would like to display a window with extended actions on some of the menu buttons click. To do so in SwiftUI, we should define a few more `Scene` in `@SceneBuilder` in type with `@main`annotations and use [`handlesExternalEvents(matching:)`](https://developer.apple.com/documentation/swiftui/group/handlesexternalevents(matching:)). This modifier can create a new scene in your app:

{% highlight swift %}
WindowGroup {
  EmptyView()
    .frame(width: .zero)
}

WindowGroup("myScene") {
    MyView()
      .frame(width: 400, height: 600)
}
.handlesExternalEvents(matching: ["myScene"])
{% endhighlight %}

Next step - define URLtype and call it using Environment [`OpenURLAction`](https://developer.apple.com/documentation/swiftui/openurlaction):

{% highlight swift %}
@Environment(\.openURL) var openURL
// later somewhere in the action

openURL(URL(string: "myApp://myScene")!)
{% endhighlight %}

Result - u can launch few same windows at same time:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-04-30-minimal-macOS-menu-bar-extra's-app-with-SwiftUI/few_windows.png" alt="few_windows" width="200"/>
</div>
<br>
<br>

> If u need only single window - use [`handlesExternalEvents(preferring:, allowing:)`](https://developer.apple.com/documentation/swiftui/path/handlesexternalevents(preferring:allowing:)). Check this [SO post](https://stackoverflow.com/questions/62915324/swiftui-2-the-way-to-open-view-in-new-window) for more.

## Pitfalls and limitation

### Unexpected behavior 

In my previous post about [`WindowGroup`]({% post_url 2021-04-25-window-group %}) I already covered some issues related to menu bar extra's app and WindowGroup, so I just copy-paste them below:

- sometimes selected scene is not shown (needs to click a few times on the button to make it workable)
- sometimes copy of menu-bar extras created (even if u create an `NSMenu` only for a dedicated window)
- when u open a new scene - a dock item is shown (sometimes is not what we want

As a workaround to issues described above, I used `NSWindow` from AppKit:

{% highlight swift %}
let view = SerialPortConsoleView(viewModel: .init(store: store))
let controller = NSHostingController(rootView: view)
let window = NSWindow(contentViewController: controller)
window.styleMask = [.titled, .closable, .miniaturizable]
window.title = "Console \(port.bsdPath)"
let size = NSSize(width: 400, height: 600)
window.minSize = size
window.maxSize = size
window.setContentSize(size)
window.contentMinSize = size
window.contentMaxSize = size
window.makeKeyAndOrderFront(nil)
{% endhighlight %}

### data sharing

To share data between scenes in scene builder u can use one of the next approaches:

- share viewModel object and hold reference in view marked with `@main` attribute. Note, that each `Scene` has its state management machine (if I can name it like this). This means, that each @State and other similar propertyWrappers and attributes work independently.
- use serialization and shared storage 

[download source code]({% link assets/posts/images/2021-04-30-minimal-macOS-menu-bar-extra's-app-with-SwiftUI/source/testMenuBarExtra.zip %})

## Resources

* [HIG - Menu Bar Extras](https://developer.apple.com/design/human-interface-guidelines/macos/extensions/menu-bar-extras/)
* [`NSPopover`](https://developer.apple.com/documentation/appkit/nspopover)
* [`NSMenu`](https://developer.apple.com/documentation/appkit/nsmenu)
* [`NSStatusItem`](https://developer.apple.com/documentation/appkit/nsstatusitem)
* [`NSApplicationDelegateAdaptor`](https://developer.apple.com/documentation/swiftui/nsapplicationdelegateadaptor)
* [`LSUIElement`](https://developer.apple.com/documentation/bundleresources/information_property_list/lsuielement)
* [`handlesExternalEvents(matching:)`](https://developer.apple.com/documentation/swiftui/group/handlesexternalevents(matching:))
* [`handlesExternalEvents(preferring:, allowing:)`](https://developer.apple.com/documentation/swiftui/path/handlesexternalevents(preferring:allowing:))
* [`OpenURLAction`](https://developer.apple.com/documentation/swiftui/openurlaction)
* [Tutorial: Add a Menu Bar Extra to a macOS App](https://8thlight.com/blog/casey-brant/2019/05/21/macos-menu-bar-extras.html)
* [Building a macOS menu bar app is now easier than ever with SwiftUI.](https://www.anaghsharma.com/blog/macos-menu-bar-app-with-swiftui/)
* [Transform `LSUIElement` to foreground application](https://stackoverflow.com/questions/12897214/transform-lsuielement-to-foreground-application)
* [How to create status bar icon & menu with SwiftUI like in macOS Big Sur](https://stackoverflow.com/questions/64949572/how-to-create-status-bar-icon-menu-with-swiftui-like-in-macos-big-sur)
* [Creating a Standalone StatusItem Menu](http://www.sonsothunder.com/devres/revolution/tutorials/StatusMenu.html)
* [Technical Note TN2083 Daemons and Agents](https://developer.apple.com/library/archive/technotes/tn2083/_index.html)
* [How do you show an `NSStatusBar` item AND hide the dock icon?](https://stackoverflow.com/questions/45291536/how-do-you-show-a-nsstatusbar-item-and-hide-the-dock-icon)
* [Apple forum discussion](https://developer.apple.com/forums/thread/651592?answerId=651132022#651132022)
* [SO SwiftUI 2: the way to open view in new window](https://stackoverflow.com/questions/62915324/swiftui-2-the-way-to-open-view-in-new-window)
