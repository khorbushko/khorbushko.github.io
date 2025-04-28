---
layout: post
comments: true
title: "Deep or not too deep"
categories: article
tags: [Android, iOS, Deep-link, AppsFlyer, longRead]
excerpt_separator: <!--more-->
comments_id: 117

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

In the realm of modern applications, shortcuts serve as a valuable tool to enhance the user experience by providing essential functionalities with minimal effort. One notable advantage of shortcuts is the ability to tap on a link and directly access the specific screen required within the application, eliminating the need for additional steps.
<!--more-->

Beneath the surface, a sophisticated link known as a deep link plays a crucial role in enabling seamless user interactions. While deep links may evoke a sense of magic, the reality is that they operate in a straightforward manner. Understanding the intricacies of deep linking is essential for harnessing its full potential.

Deep linking enables mobile apps to be opened with specific content or functionality directly from external sources like websites, messengers, emails, or even other apps. It creates a seamless user experience by:

* Creating a reference (referral) system
* Providing seamless informative experience
* Directing users to specific in-app content
* Maintaining context across different platforms
* Improving conversion rates for marketing campaigns
* Enabling app-to-app communication
* Providing measurable attribution for user acquisition
* etc (only imagination is a limit)

## A History

The evolution of deep linking on mobile platforms include few major steps until now:

* **2011-2012**: Early implementations on iOS using custom *[URI schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)* (like `myapp://`)

> Custom URI schemes use a unique protocol identifier (instead of http:// or https://) to trigger app openings. The format is typically:
> 
> ```
> [scheme]://[host]/[path]?[parameters]
> ```
> Example: helloApp://info/screen?=greet
> Limitations of Custom URI Schemes
> 
> * No fallback mechanism: If app isn't installed, the link fails (unlike Universal Links/App Links)
> * Browser blocking: Some browsers may block custom schemes for security
> * App chooser: Android may show a disambiguation dialog if multiple apps handle same scheme
> * Lack of validation: No ownership verification like with Universal Links/App Links
> 
> Despite these limitations, custom URI schemes remain useful for:
> 
> * App-to-app communication
> * Simple deep linking needs
> * Legacy support
> * Cases where you don't control a web domain
> 


* **2013**: Android introduces App Links (initially called "*[Android App Links](https://developer.android.com/training/app-links)*")

> Android first introduced its version of deep linking in 2013 under the name "Android App Links" (later rebranded as just "App Links"). This was Google's answer to iOS's URL schemes, but with several key improvements:
>
> * HTTP/HTTPS Support: Unlike custom URI schemes, App Links used standard web URLs
> * No Disambiguation Dialog: When properly configured, links would open directly in the app without asking users to choose
> * Domain Verification: Introduced a way to prove domain ownership
>
> Key limitations in this early version:
> 
> * No automatic verification
> * Still showed disambiguation dialogs
> * Required manual handling of both http and https
>


* **2015**: iOS introduces *[Universal Links](https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html#//apple_ref/doc/uid/TP40016308-CH12)* with iOS 9
> 
> With iOS 9 in 2015, Apple introduced **Universal Links** as a more secure and powerful alternative to custom URL schemes. This technology fundamentally changed how iOS apps handle deep linking by:

> * Using standard HTTPS URLs (no more "`myapp://`" schemes)
> * Providing a fallback to websites when apps aren't installed
> * Eliminating the *"Open in..."* dialog through domain ownership verification
> * Improving security by preventing URL scheme hijacking
> 
> Additionally, Apple App Site Association (AASA) File is now helps to filter links for determining ownership of the domain and improve security:
>
>
```
	{
	  "applinks": {
	    "apps": [],
	    "details": [
	      {
	        "appID": "TeamID.BundleID",
	        "paths": ["/products/*", "/blog/2804?/*", "NOT /search"]
	      }
	    ]
	  }
	}
```
>
> Another improvement - entitlements - now Associated Domains must be listed in format `applinks:yourdomain.com`
> 

* **2016**: Google launches *[Digital Asset Links](https://developers.google.com/digital-asset-links/v1/getting-started)* for Android App Links

> In 2015 with Android 6.0 (Marshmallow), Google introduced the Digital Asset Links system and the `autoVerify` attribute:
> 
> ```
	<intent-filter android:autoVerify="true">
	    <action android:name="android.intent.action.VIEW" />
	    <category android:name="android.intent.category.DEFAULT" />
	    <category android:name="android.intent.category.BROWSABLE" />
	    <data android:scheme="https" android:host="example.com" />
	</intent-filter>
> ```
> 
> The Android system would:
> 
> * Find all intent filters with `autoVerify=true`
> * Query each domain for the **assetlinks.json** file (aka filter for verification domain ownership and so protect users)
> 
> ```
	[{
	  "relation": ["delegate_permission/common.handle_all_urls"],
	  "target": {
	    "namespace": "android_app",
	    "package_name": "com.yourcompany.yourapp",
	    "sha256_cert_fingerprints": [
	      "SHA256:YOUR_APP_SIGNING_CERT_FINGERPRINT"
	    ]
	  }
	}]
> ```
> * Verify the digital signature matches
> * If verified, bypass the disambiguation dialog
> 

* **2018-2020**: Growing adoption of deferred deep linking solutions (Android)

> **Evolution Since 2015**
> 
> * Android 7.0 (2016): Improved verification reliability
> * Android 8.0 (2017): Added verification caching
> * Android 10 (2019): Enhanced security and verification
> * Android 11 (2020): Package visibility changes affected some implementations
> * Android 12 (2021): New privacy-focused restrictions
> 

* **2021**: iOS 15 introduces *[Private Relay](https://support.apple.com/en-us/102602)* impacting attribution tracking
> Introduced in iOS 15 (2021), iCloud Private Relay is Apple's privacy-focused service that:
> 
> * Obscures user IP addresses
> * Encrypts DNS queries
> * Routes traffic through two separate relays
> * Changes apparent location data
> * Available to iCloud+ subscribers (free with some plans, $0.99/month standalone).
> 
> For developers this is an additional pain in implementation, but for user this is trully a good protection, anti tracking feature (I will describe more later in this article)
> 

* **2022-2023**: Continued refinements with improved security and reliability
>
> Currently Android uses all evolutions steps including **assetlinks.json** file and xml declaration in maifest, with ability to use callback uri.

And this is still evolutioning. Exciting.

## Deep Linking Flows

Now, knowing the history, we can rule the future. But, especially for me, understanding is coming with some visualization. So below are few diagrams that describe basic deepl links flows.

The simplest option - is just click a link and open a screen (with some parameters or without):

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/1.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/1.png" width="500"/>
</a>
</div>
<br>


Universal Links Flow (iOS)

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/2.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/2.png" width="500"/>
</a>
</div>
<br>

Android App Links Flow

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/3.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/3.png" width="500"/>
</a>
</div>
<br>

Deferred Deep Linking Flow

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/4.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/4.png" width="500"/>
</a>
</div>
<br>

The more interesting story, is that u may modify this flows as u wish, and for example create a referral system using deffered link, as example:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/5.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/5.png" width="500"/>
</a>
</div>
<br>

For Web-to-Store Flow this will looks like this:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/6.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/6.png" width="300"/>
</a>
</div>
<br>

As u can see, this flow may be as simple as just a click handle or may become quite complex. Again - there is no limits for the process.

## Native Solutions

OK. Enough teory, let's looks how this can be implemented on both platforms (iOS and Android) using native capabilities.

### iOS Deep Linking Solutions

Despite the evolution process described above, Apple still support both options, and this can be a good point for some cases - as always - implementation of the solutions depends on your app's needs.

#### Custom URL Schemes

The steps are next:

* Define `URL Scheme` in `Info.plist`

```swift
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>com.example.myapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string> <!-- Your custom scheme -->
        </array>
    </dict>
</array>
```

* Handle callback

```
// For UIKit apps (`AppDelegate`)
func application(
	_ app: UIApplication, 
	open url: URL, 
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
 ) -> Bool {
    // Process URL
    return true
}

// For SwiftUI apps (`SceneDelegate`)
func scene(
	_ scene: UIScene, 
	openURLContexts URLContexts: Set<UIOpenURLContext>
	) {
    if let url = URLContexts.first?.url {
        handleCustomURL(url)
    }
}
```

* Parse URL (primitive solution)

```
func handleCustomURL(_ url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
    
    let scheme = url.scheme // "myapp"
    let host = url.host     // e.g., "product"
    let path = url.path     // e.g., "/123"
    let queryItems = components.queryItems // e.g., "?screen=info"
    
    // Example: myapp://product/123?color=red
    if scheme == "myapp" && host == "product", 
    	!url.pathComponents.isEmpty {
        let productID = url.pathComponents[1] // "123"
        let color = queryItems?
        					.first(where: { $0.name == "color" })?.value
        showProduct(id: productID, color: color)
    }
}
```

* Triggering the URL

You have a few options:

* Typing in **Safari**: `myapp://product/123`
* Using Xcode terminal:
```bash
xcrun simctl openurl booted "myapp://product/123?color=blue"
```
> more about [simctl](https://nshipster.com/simctl/)

* Advanced Handling

For better compatibility:

```
// Add to Info.plist to make links clickable in Safari
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>myapp</string>
</array>
```

For `SwiftUI`:

```
// In your App file
@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleCustomURL(url)
                }
        }
    }
}
```

This is a general idea how it works.


#### Universal Links

Amore andvanced way to handle links - is use of universal links. This process require a bit more work, but result is even better. So let's start from the very first step -

* Apple App Site Association (**AASA**) File

> Associated domains establish a secure association between domains and your app so you can share credentials or provide features in your app from your website.
> 

U must:

* Set up `HTTPS` (required)
* Upload the `AASA` file to the correct location
* Ensure proper `Content-Type` header (`application/json`)

Example of the file:

```
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "TeamID.BundleID",
        "paths": ["/products/*", "/blog/202?/*", "NOT /search"]
      }
    ]
  }
}
```

This file is a JSON file hosted at:
`https://yourdomain.com/.well-known/apple-app-site-association` or as alternative way, you can [create](https://gist.github.com/mat/e35393e9dfd9d7fb0972?permalink_comment_id=4367879#gistcomment-4367879) a `CloudFront` Function and associate it to your distribution's cache behavior as a viewer-request function to bypass hosting the file completely.

> [As example u can check this git for more](https://github.com/HenSquared/AASA-Examples)

* **Entitlements** Configuration

Required in your Xcode project:

* Associated Domains entitlement enabled
* Domains listed in format: `applinks:<domain>`

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/xcode.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/xcode.png" width="300"/>
</a>
</div>
<br>

* Callback Handling

The most easy part i guess. Depending from u'r app configuration u can hanlde this in `AppDelegate`/`SceneDelegate`. As an example:

```
func application(_ application: UIApplication,
                 continue userActivity: NSUserActivity,
                 restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    
    guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
          let url = userActivity.webpageURL else {
        return false
    }
    
    // Handle the Universal Link
    handleDeepLink(url)
    
    return true
}
```
`handleDeepLink` - here u can parse data and create some navigation patterns for u'r app.

Don't forget to handle both cold starts and background activations.

### Android Deep Linking Solutions

#### Deep Links (Intent Filters)

* Add intent filters to your activity to handle deep links:

```xml
<activity android:name=".MainActivity">
    <!-- Intent filter for deep links -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        
        <!-- Handle links like: https://example.com/product/123 -->
        <data
            android:scheme="https"
            android:host="example.com"
            android:pathPrefix="/product/" />
        
        <!-- OR for custom schemes: myapp://product/123 -->
        <data
            android:scheme="myapp"
            android:host="product" />
    </intent-filter>
</activity>
```

* Handle Incoming Deep Links in `Activity`

Extract the deep link data in your `Activity` (or `Fragment`):


```kotlin
override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    
    // Handle deep link when app is opened via URL
    intent?.data?.let { uri ->
		...
    }
}
```

* Test Deep Links

Tests can be done via few methods:

**Using `adb`:**

```bash
adb shell am start -W -a android.intent.action.VIEW -d "https://example.com/product/123" com.your.package

// or

adb shell am start -W -a android.intent.action.VIEW -d "myapp://product/123" com.your.package
```

**Clicking Links in Browser**

* Enter `https://example.com/product/123` in Chrome.
* If the app is installed, Android will prompt to open it.


#### Android App Links

* Modify manifest file by including `intent-filter`. For verified HTTPS links (no disambiguation dialog), add `autoVerify="true"`:


```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="example.com"
          android:pathPrefix="/app" />
</intent-filter>
```

* And host an `assetlinks.json` file at:

```
https://example.com/.well-known/assetlinks.json
```

* Verify

```bash
adb shell pm verify-app-links --package com.your.package
```

## Debugging tips

For both version always check all possible cases:

* If app not installed
* If app installed and terminated
* If app installed and in background
* If app installed, in background and opened different screens (etc)
* If few instances of app is launched (`Scenes` for iOS)
* Cross check links from iOS to Android and vice versa
* etc

It's good to test on at least few devices and on different operation system version.

### iOS

* To check AASA file, you can download it:

```curl
curl -I https://yourdomain.com/.well-known/apple-app-site-association
```

or use some validators, for example [branch.io](https://branch.io/resources/aasa-validator/) or [median](https://median.co/docs/deep-linking-validator) or some other service.

* Sometimes AASA file can be cashed, and so not update. To check this, we can use Apple CDN api:

```curl
curl --request GET \
  --url https://app-site-association.cdn-apple.com/a/v1/<assosiated-domain> \
```

* Same stuff with cashe can be on iOS. To check cached file on iOS:

1. Connect device to Mac
2. Open `Console` app
3. Filter for `swcd` messages

* Force AASA Refresh

```bash
xcrun simctl spawn booted log config --mode "private_data:on"
xcrun simctl spawn booted log stream --level debug | grep swcd
```

Other option - on/off Airplain mode, reboot device or reinstall app (this not always works).

* Test Universal Links directly

```bash
xcrun simctl openurl booted "https://yourdomain.com/yourPath"
```

* For testing, use the Notes of messagers. Links don't works in Safari. If you force press on a link and see ”Open in app” in the context menu, that’s a good sign. 

> Here’s a more detailed article about this: [https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links).

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/df_i.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/df_i.png" width="500"/>
</a>
</div>
<br>

### Android

* Multiple Activities Handling Same Links?

1. Use `Intent.resolveActivity()` to check conflicts.
2. Set `android:order="1"` in `<intent-filter>` to prioritize.

* Improve Security

Validate incoming URIs - use `Intent.FLAG_GRANT_READ_URI_PERMISSION` if sharing file URIs.

* Test URL accessibility

```curl
curl -I https://yourdomain.com/.well-known/assetlinks.json
```

* Check Verification Status on Device

```bash
adb shell pm get-app-links com.your.package
```

* Reset verification cache on Device

```bash
adb shell pm set-app-links --package com.your.package 0 all
adb shell pm verify-app-links --package com.your.package
```

* Simulate a link click

```bash
adb shell am start -a android.intent.action.VIEW \
    -d "https://yourdomain.com/path" \
    com.your.package
```


* Digital Asset Links API validation

```bash
https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://yourdomain.com&relation=delegate_permission/common.handle_all_urls
```

Possible debugging flow:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/df_a.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/df_a.png" width="500"/>
</a>
</div>
<br>

## Common Pitfalls

Every process has its own set of limitations and pitfalls. Here are some common ones that I’ve encountered:

### iOS-Specific Issues

* AASA File Caching

1. iOS aggressively caches the AASA file
2. Changes may take 24+ hours to propagate
3. Workaround: Reinstall app or reboot device

* HTTPS Requirements

1. Universal Links require HTTPS
2. Self-signed certificates won't work in production

* First-Time Launch Behavior

1. On first launch after install, iOS may open Safari first
2. Subsequent taps will open the app directly

* Private Relay (iOS 15+)

Apple's Private Relay can obscure IP addresses and location data. Another option - is to use AppClips for direct navigation and attribution tracking or [Pastboard](https://www.branch.io/resources/blog/how-to-set-up-deferred-deep-linking-on-ios/) solution.

Apple recommend to use `SKAdNetwork` for attribution, but this want help u in case of deferred deep linking.

* Universal Links Broken in Some Versions

Check release notes for currently testing iOS version.

> For example iOS 12.2 had known issues with Universal Links
> Another moment - some versions may fall back to web even when app is installed

* Browser Compatibility

Universal Links work in Safari but may not in third-party browsers. Custom schemes may be blocked by some browsers

### Android-Specific Issues

* Link opens browser instead of app

Ensure `intent-filter` is correct in `AndroidManifest.xml`.

* Disambiguation dialog appears

Use App Links (`autoVerify="true"`) for HTTPS links.

* Deep link not working after install

Check if the link was clicked before app installation (use **Deferred Deep Linking** - `DDL`).

or/and clear Play Store cache

```bash
adb shell pm clear com.android.vending
```

* Multiple apps claim the same domain

```bash
adb shell pm get-app-links --user 0
```


## Implementation example with `AppsFlyer`

That was a bit challenging, but there’s a lot of information available, including more details in official documents.

Luckily, there are several online services that can simplify this process for developers and end-users. One such service is [AppsFlyer](https://www.appsflyer.com).

> Before, everyone used Firebase deep linking, but that service is being deprecated and closing soon. AppsFlyer is a good alternative for many apps. Other alternatives include branch.io. I believe there are more, but I didn’t look too deeply into deep link services - the AppsFlyer service I chose can meet all our needs in a few steps.

There are a few things about this service that could be improved, but I’ll mention them later.

### Web

On web console u need to create 2 apps - iOS and Android. Then u receive dev key - this key will be used as a secret for u'r configuration.

I don't want to dive to deep in details - thus in general the process is very straitforward - just press next and enter data they ask for ;].

> Here’s the best part: AppsFlyer will automatically set up **AASA** and **assetlinks** based on u't inputs, which will make the process much smoother. And guess what? You get a host for free! No need to ask the frontend team to do anything.

### iOS

Let's start from iOS, thus here we need a bit more work, due to some privacy limitations and other system restrictions.

The first step is configure entitlments:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>aps-environment</key>
	<string>development</string>
	<key>com.apple.developer.associated-domains</key>
	<array>
		<string>applinks:myapp.onelink.me</string>
	</array>
</dict>
</plist>
```

where `myapp.onelink.me` - configured in AppsFlyer template as subdomain. 

Also configure URL type (if needed) with old good `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleTypeRole</key>
			<string>Editor</string>
			<key>CFBundleURLName</key>
			<string>com.app</string>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>app</string>
			</array>
		</dict>
	</array>
```

Now, let's create a handle for all events related to AppsFlyer as a separate module, that can be easelly replaced in case of provider change. I named this handle as `AppsFlyerHandle`.

For sake of the simplisity I named all func in this class in same way as it will be called from. For example:

```swift
@discardableResult
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configure()
    setSecrets()
    attachDelegate()
    handle.waitForATTUserAuthorization(timeoutInterval: 60)

    fetchPasteBoard()
    addObservers()
    return true
  }
```

We will call this function from  `didFinishLaunchingWithOptions` of `AppDelegate`.

The flow for this is next:

- setup keys, secrets, team ID, debug props
- add callbacks
- configure tracking (optionally)
- configure Private-Relay workaround (optionally)
- start service

> The goos thing - is that this service has [online validator](https://hq1.appsflyer.com/sdk-integration-test/app/id6744247109) of the configuration.

The process is well described in [articles from AppsFlyer](https://dev.appsflyer.com/hc/docs/dl_ios_init_setup). But I want to stop on some tricky moments.

#### Private Relay

This is a point where I spent a lot of time for debugging. On debug build everything may works as expected, but on prod - no, on adhoc - sometimes.

The good thing, is that we may easelly workaround this using pasteboard, but for user this will be appeared as system popup that ask to paste values from pasteboard into the app. How to do this well described [here](https://www.branch.io/resources/blog/how-to-set-up-deferred-deep-linking-on-ios/). On AppsFlyer they have just a small comment about this option [here](https://dev.appsflyer.com/hc/docs/dl_ios_private_relay).

In case u want to have deferred deeplink - this is one of the step that is needed for sure.

The implementation for reading pasteboard and parcing values - is very simple:

```swift
private func fetchPasteBoard() {
    if Storage.isInitialLaunch {
      let pasteboardUrl = UIPasteboard.general.string ?? ""
      let checkParameter = "cp_url=true"

      if pasteboardUrl.contains(checkParameter) {
        handle.performOnAppAttribution(with: URL(string: pasteboardUrl))
      }

      Storage.isInitialLaunch = false
    }
  }
```

where `cp_url=true` a custom flag appended to expanded short link received on web, for example when user click Download app from store.

`handle.performOnAppAttribution` will trigger `didResolveDeepLink` method from `DeepLinkDelegate` - so u don't need to do here something 

#### Deferred Deep link

This is another tricky moment. The first thing is that u cannot use u'r own keys for query params in short link, but only system-defined. I find-out this by small disclaimer in the documentation about legasy api (strange) [here](https://dev.appsflyer.com/hc/docs/dl_ios_gcd_legacy):

> We recommend using unified deep linking (UDL). UDL conforms to the iOS 14.5+ privacy standards and only returns parameters relevant to deep linking and deferred deep linking: `deep_link_value` and `deep_link_sub1-10`. Attribution parameters (such as `media_source`, `campaign`, `af_sub1-5`, etc.), return null and can’t be used for deep linking purposes.

Also this moment is confirmed in dialog with AppsFlyer:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/dialog.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-04-28-deep-linking/dialog.png" width="300"/>
</a>
</div>
<br>

Just a heads up, the deferred deep link isn’t being called from the `didResolveDeepLink` method in the `DeepLinkDelegate`. Instead, it’s being returned in the deprecated `onConversionDataSuccess` method from the `AppsFlyerLibDelegate`. 

This callback might return data every time the app launches, even if the deferred URL is the same. To fix this, AppsFlyer has provided some special keys in the `conversionInfo`, so you can implement it as follow:


```swift
func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
    Log.debug("[AFSDK] Deep link onConversionDataSuccess - \(conversionInfo)")

    let status = conversionInfo["af_status"] as? String
    let isFirstLaunch = conversionInfo["is_first_launch"] as? Bool

    if status == "Non-organic" && isFirstLaunch == true,
       let link = UniLink.build(conversionInfo, source: .conversion) {
      onReceiveUniLink?(link)
    }
  }
```

> `UniLink` - just a wrapper above the link I used in the app. U can place there u'r own code for parsing u'r config of the links.

All other points is quite simple and without some tricks.

#### Link generator

The link generator will automatically create shorter links for you. 

If you receive a long link, it means that some of the parameters are invalid and cannot be handled properly. 

For instance, links support the [OG](https://www.opengraph.xyz/) system. If you have a description or title that’s longer than 250 characters, this is a problem and the link will not be shortened. Instead, you’ll get a long link, but the error won’t be returned from AppsFlyer’s link generator.

AppsFlyer does not support whole OG tags - u can check everything that is supported [here](https://support.appsflyer.com/hc/en-us/articles/207447163-About-link-structure-and-parameters).

#### Debug device 

The last moment I almoust forget about - is test device. U need to add manually (automatic way is not working for me) u'r device `idfa` identifier to the system, so deeplinks works on u'r debug builds.

Here is the [link to place](https://hq1.appsflyer.com/test-devices/devices) where it should be done.


<details><summary> The full code for AppsFlyerHandle </summary>
<p>

{% highlight swift %}
import Foundation
import UIKit

import AppsFlyerLib
import AppTrackingTransparency

final class AppsFlyerHandle: NSObject {

  private enum Storage {
    @UserDefaultValueStorageWrapper(
      key: "initial_launch",
      defaultValue: true
    )
    static var isInitialLaunch: Bool
  }

  private let handle = AppsFlyerLib.shared()
  var onReceiveUniLink: ((UniLink) -> Void)?

  // MARK: Public

  @discardableResult
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configure()
    setSecrets()
    attachDelegate()
    handle.waitForATTUserAuthorization(timeoutInterval: 60)

    fetchPasteBoard()
    addObservers()
    return true
  }

  @discardableResult
  func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity
  ) -> Bool {
    handle.continue(userActivity, restorationHandler: nil)
    return true
  }

  @discardableResult
  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    handle.handleOpen(url, options: options)
    return true
  }

  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any]
  ) {
    handle.handlePushNotification(userInfo)
  }

  // MARK: Private

  @objc private func onApplicationBecomeActive() {
    handle.start()

    ATTrackingManager.requestTrackingAuthorization { (status) in
      Log.debug("[AFSDK] ATTrackingManager auth status - \(status)")
    }
  }

  private func configure() {
#if DEBUG
    handle.isDebug = true
#endif
    handle.appInviteOneLinkID = "TEMPLATE_ID"
    handle.customerUserID = UIDevice.current.identifierForVendor?.uuidString
  }

  private func setSecrets() {
    handle.appsFlyerDevKey = "YOUR_SECRET_FROM_WEB"
    handle.appleAppID = "YOUR_APP_ID"
  }

  private func attachDelegate() {
    handle.deepLinkDelegate = self
    handle.delegate = self
  }

  private func addObservers() {
    NotificationCenter.default
      .addObserver(
        self,
        selector: #selector(onApplicationBecomeActive),
        name: UIApplication.didBecomeActiveNotification,
        object: nil
      )
  }

  private func fetchPasteBoard() {
    if Storage.isInitialLaunch {
      let pasteboardUrl = UIPasteboard.general.string ?? ""
      let checkParameter = "cp_url=true"

      if pasteboardUrl.contains(checkParameter) {
        handle.performOnAppAttribution(with: URL(string: pasteboardUrl))
      }

      Storage.isInitialLaunch = false
    }
  }
}

extension AppsFlyerHandle: DeepLinkDelegate {
  func didResolveDeepLink(_ result: DeepLinkResult) {
    let dataString: String = "\(result.deepLink?.toString() ?? "")"
    let error = result.error?.localizedDescription ?? "noErr"
    let status = result.status == .found
    let defferedFromWeb = result.deepLink?.clickEvent["cp_url"] != nil
    let source: UniLink.Source = defferedFromWeb
                                    ? .defferedWithPrivateRelay
                                    : .resolver
    Log.debug("[AFSDK] Deep link - \(status): \(source) \(dataString), \(error)")

    if let link = UniLink.build(result, source: source) {
      onReceiveUniLink?(link)
    }
  }
}

extension AppsFlyerHandle: AppsFlyerLibDelegate {

  func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
    Log.debug("[AFSDK] Deep link onConversionDataSuccess - \(conversionInfo)")

    let status = conversionInfo["af_status"] as? String
    let isFirstLaunch = conversionInfo["is_first_launch"] as? Bool

    if status == "Non-organic" && isFirstLaunch == true,
       let link = UniLink.build(conversionInfo, source: .conversion) {
      onReceiveUniLink?(link)
    }
  }

  func onConversionDataFail(_ error: any Error) {
    Log.debug("[AFSDK] Deep link onConversionDataFail \(error)")
  }
}
{% endhighlight %}

</p>
</details>
<br>

### Android

As I mention above, Android is much easier to handle and configure. The project I was playing with has used Java, so code below also on Java instead of Kotlin, but the idea is pretty same. 

At first - configure `AndroidManifest.xml` by adding `intent-filter`:


```xml
<intent-filter  android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="https"
                    android:host="app.onelink.me" />
            </intent-filter>
            <intent-filter>
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data
                    android:host=""
                    android:scheme="app" />
            </intent-filter>
```

Next step - just add same keys, configs and appID:

```java
public void configureHandleWith(Context context) {
        AppsFlyerLib.getInstance()
                .init(
                        "YOUR_SECRET_FROM_WEB",
                        null,
                        context
                );
        AppsFlyerLib.getInstance().setAppId(BuildConfig.APPLICATION_ID);
        AppsFlyerLib.getInstance().setAppInviteOneLink("TEMPLATE_ID");
        AppsFlyerLib.getInstance().setDebugLog(BuildConfig.DEBUG);
        AppsFlyerLib.getInstance().start(context);
}
```

And subscribe for deepLink:

```java
    public void subscribeForDeepLinkEvent(OnResultListener onResultListener) {
        AppsFlyerLib.getInstance()
                .subscribeForDeepLink(new DeepLinkListener() {
                    @Override
                    public void onDeepLinking(@NonNull DeepLinkResult deepLinkResult) {
                        DeepLinkResult.Status dlStatus = deepLinkResult.getStatus();
                        Log.i(LOG_TAG, dlStatus.toString());

                        if (dlStatus == DeepLinkResult.Status.FOUND) {
                            DeepLink deepLinkObj = deepLinkResult.getDeepLink();
                            try {
                                onResultListener.onReceiveLink(
                                        deepLinkObj.getDeepLinkValue(),
                                        deepLinkObj.getClickEvent()
                                );
                            } catch (Exception e) {
                                Log.d(AppsFlyerUniLinkHandle.LOG_TAG, "DeepLink data came back null");
                            }
                        }
                    }
                });
    }
```

That's it - no pitfalls, the process is quite easy here.

> `onResultListener.onReceiveLink` should implement same logic for checking deferred link params 

<details><summary> The full code for AppsFlyerHandle </summary>
<p>

{% highlight swift %}

public class AppsFlyerUniLinkHandle {

    public static final String LOG_TAG = "[AFSDK]";

    public interface OnResultListener {
        void onReceiveLink(String link, JSONObject eventDetails);
    }

    private static final AppsFlyerUniLinkHandle ourInstance = new AppsFlyerUniLinkHandle();

    public static AppsFlyerUniLinkHandle handle() {
        return ourInstance;
    }

    public void configureHandleWith(Context context) {
        AppsFlyerLib.getInstance()
                .init(
                        "YOUR_SECRET_FROM_WEB",
                        null,
                        context
                );
        AppsFlyerLib.getInstance().setAppId(BuildConfig.APPLICATION_ID);
        AppsFlyerLib.getInstance().setAppInviteOneLink(TEMPLATE_ID);
        AppsFlyerLib.getInstance().setDebugLog(BuildConfig.DEBUG);
        AppsFlyerLib.getInstance().start(context);
    }

    public void subscribeForDeepLinkEvent(OnResultListener onResultListener) {
        AppsFlyerLib.getInstance()
                .subscribeForDeepLink(new DeepLinkListener() {
                    @Override
                    public void onDeepLinking(@NonNull DeepLinkResult deepLinkResult) {
                        DeepLinkResult.Status dlStatus = deepLinkResult.getStatus();
                        Log.i(LOG_TAG, dlStatus.toString());

                        if (dlStatus == DeepLinkResult.Status.FOUND) {
                            DeepLink deepLinkObj = deepLinkResult.getDeepLink();
                            try {
                                onResultListener.onReceiveLink(
                                        deepLinkObj.getDeepLinkValue(),
                                        deepLinkObj.getClickEvent()
                                );
                            } catch (Exception e) {
                                Log.d(AppsFlyerUniLinkHandle.LOG_TAG, "DeepLink data came back null");
                            }
                        }
                    }
                });
    }
}

{% endhighlight %}

</p>
</details>
<br>

## Conclusion

Wow.. quite a long read ;).

Deep linking is a must-have for modern mobile apps to give users a smooth experience across different platforms. While iOS and Android have built-in solutions, platforms like AppsFlyer offer powerful implementations that handle tricky situations, track attribution, and delay deep linking. 

To make sure everything works correctly, developers need to set up AASA and Digital Asset Links files properly and be aware of any platform-specific limitations or privacy concerns.

At first glance, it may seem a bit tricky, but the more you play with it, the easier it becomes!


## Resources

* [URI schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
* [Android App Links](https://developer.android.com/training/app-links)
* [Universal Links](https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html#//apple_ref/doc/uid/TP40016308-CH12)
* [Digital Asset Links](https://developers.google.com/digital-asset-links/v1/getting-started)
* [Private Relay](https://support.apple.com/en-us/102602)
* [simctl](https://nshipster.com/simctl/)
* [AASA-Examples](https://github.com/HenSquared/AASA-Examples)
* [AppsFlyer](https://www.appsflyer.com)
* [Debugging unoversal link](https://developer.apple.com/documentation/technotes/tn3155-debugging-universal-links)
* [iOS config AppsFlyer](https://dev.appsflyer.com/hc/docs/dl_ios_init_setup)
* [OG](https://www.opengraph.xyz/)
* [AppsFlyer supported Attributes](https://support.appsflyer.com/hc/en-us/articles/207447163-About-link-structure-and-parameters)
