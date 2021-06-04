---
layout: post
comments: true
title: "User-Agent for iOS"
categories: article
tags: [Network, User-Agent]
excerpt_separator: <!--more-->
comments_id: 46

author:
- kyryl horbushko
- Lviv
---

When we meet some person, we always want to introduce ourselves from the best side. We can describe ourselves by telling the name and a few interesting facts.

In the computer world, if we behave as a user - we also should introduce ourselves. One of the options is to use `User-Agent`.
<!--more-->

## User-Agent

The User-Agent request header is a character string that lets servers and network peers identify the application, operating system, vendor, and/or version of the requesting user agent. [source](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent).

Mobile application in every request must send his `User-Agent` in the header with build version and device information.

format:

{% highlight swift %}
User-Agent: <AppName>/version (<system-information>) <platform> (<platform-details>) <extensions>

//for iOS:

User-Agent: <AppName/<version> (<iDevice platform>; <Apple model identifier>; iOS/<OS version>) CFNetwork/<version> Darwin/<version>
{% endhighlight %}

> I'm mostly working with iOS, so this tutorial is dedicated to this OS.

So, the components are:

- Headers Key
- AppName and version
- Info about Device
- CFNetwork version
- Darwin Version

### Headers Key
	
HTTP headers let the client and the server pass additional information with an HTTP request or response. An HTTP header consists of its case-insensitive name followed by a colon (:), then by its value. Whitespace before the value is ignored.

> `User-Agent` `:` `<Value>`

The list of the header key can be found for example [here](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers)

### AppName and Version

This information available in the u'r `Info.plist` file.
U can use the approach described [here](https://medium.com/ios-os-x-development/strongly-typed-access-to-info-plist-file-using-swift-50e78d5abf96) with `InfoPlist` struct like below:

{% highlight swift %}
import Foundation

// MARK: - URLScheme

public typealias URLScheme = String

// MARK: - URLType

public struct URLType: Codable {

  public private (set) var role: String?
  public private (set) var iconFile: String?
  public private (set) var urlSchemes: [String]

  // MARK: - Codable

  private enum Key: String, CodingKey {

    case role = "CFBundleTypeRole"
    case iconFile = "CFBundleURLIconFile"
    case urlSchemes = "CFBundleURLSchemes"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: URLType.Key.self)

    role = try container.decodeIfPresent(String.self, forKey: .role)
    iconFile = try container.decodeIfPresent(String.self, forKey: .iconFile)
    urlSchemes = try container.decode([String].self, forKey: .urlSchemes)
  }
}

// MARK: - InfoPlist

public struct InfoPlist: Codable {

  public private (set) var displayName: String?
  public private (set) var bundleId: String
  public private (set) var bundleName: String?
  public private (set) var versionNumber: String?
  public private (set) var buildNumber: String?

  public private (set) var urlTypes: [URLType]?

  // MARK: - Codable

  private enum Key: String, CodingKey {

    case displayName = "CFBundleDisplayName"
    case bundleName = "CFBundleName"

    case bundleId = "CFBundleIdentifier"
    case versionNumber = "CFBundleShortVersionString"
    case buildNumber = "CFBundleVersion"

    case urlTypes = "CFBundleURLTypes"
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: InfoPlist.Key.self)

    bundleId = try container.decode(String.self, forKey: .bundleId)
    versionNumber = try container.decode(String.self, forKey: .versionNumber)
    buildNumber = try container.decode(String.self, forKey: .buildNumber)

    displayName = try? container.decodeIfPresent(String.self, forKey: .displayName)
    bundleName = try? container.decodeIfPresent(String.self, forKey: .bundleName)

    urlTypes = try? container.decodeIfPresent([URLType].self, forKey: .urlTypes)
  }
}
{% endhighlight %}

Result - u can access all information within a few lines of code:

{% highlight swift %}
let infoPlist = try? PListFile<InfoPlist>()
let appName = infoPlist.data.bundleName
let version = infoPlist.data.versionNumber
let build = infoPlist.data.buildNumber
{% endhighlight %}

### Info about Device

In general, u should collect few components. A lot of solutions are available for this purpose.

To get *modelName* - use for example [this source](https://stackoverflow.com/questions/11197509/how-to-get-device-make-and-model-on-ios/11197770#11197770).

{% highlight swift %}
let modelName = UIDevice.current.modelName
{% endhighlight %}

To get *platform* and *operation system*:

{% highlight swift %}
let platform = UIDevice.current.systemName
let operationSystemVersion = ProcessInfo.processInfo.operatingSystemVersionString
{% endhighlight %}

### CFNetwork version

This is a framework, that uses for accessing network services and handling changes in network configurations. Build on abstractions of network protocols to simplify tasks such as working with BSD sockets, administering HTTP and FTP servers, and managing Bonjour services. Read [more](https://developer.apple.com/documentation/cfnetwork).

To get info about the version of `CFNetwork`:

{% highlight swift %}
static var cfNetworkVersion: String? {
  guard
    let bundle = Bundle(identifier: "com.apple.CFNetwork"),
     let versionAny = bundle.infoDictionary?[kCFBundleVersionKey as String],
     let version = versionAny as? String
      else { return nil }
  return version
}
{% endhighlight %}

> here is [the source of this code](https://developer.apple.com/forums/thread/124183)

### Darwin Version

How to get the Darwin Version described [here](https://stackoverflow.com/a/60503116/2012219), and the code:

{% highlight swift %}
 var systemInfo = utsname()
 uname(&systemInfo)
 let machineMirror = Mirror(reflecting: systemInfo.release)
 let darvinVersionString = machineMirror.children.reduce("") { identifier, element in
   guard let value = element.value as? Int8,
     value != 0 else {
       return identifier
   }

   return identifier + String(UnicodeScalar(UInt8(value)))
 }
{% endhighlight %}

### Combining all together

Now, the simplest part - combine all components:

{% highlight swift %}
static var userAgentHeader: [AnyHashable: Any] {
    var customHeaders: [AnyHashable: Any] = [: ]

    if let infoPlist = try? PListFile<InfoPlist>(),
      let appName = infoPlist.data.bundleName,
        let version = infoPlist.data.versionNumber,
          let build = infoPlist.data.buildNumber,
            let cfNetworkVersionString = ProcessInfo.cfNetworkVersion {

      let modelName = UIDevice.current.modelName
      let platform = UIDevice.current.systemName
      let operationSystemVersion = ProcessInfo.processInfo.operatingSystemVersionString
      let darwinVersionString = ProcessInfo.darwinVersion

      let userAgentString = "\(appName)\(String.slash)\(version).\(build) " +
        "(\(platform); \(modelName); \(operationSystemVersion)) " +
        "CFNetwork/\(cfNetworkVersionString) " +
        "Darwin/\(darwinVersionString)"

      customHeaders[HTTPHeader.Key.userAgent] = userAgentString
    }

    return customHeaders
  }
{% endhighlight %}

Result:

{% highlight swift %}
MyApp/1.1.1233 (iOS; iPhone XS; Version 13.3 (Build 17C45)) CFNetwork/1121.2.1 Darvin/19.3.0
{% endhighlight %}

## Resources

* [User-Agent](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent).
* [RFC-2616](https://datatracker.ietf.org/doc/html/rfc2616#page-145)
* [Header key](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers)
* [Strongly typed access to plist](https://medium.com/ios-os-x-development/strongly-typed-access-to-info-plist-file-using-swift-50e78d5abf96)
* [Device model](https://stackoverflow.com/questions/11197509/how-to-get-device-make-and-model-on-ios/11197770#11197770)
* [`CFNetwork`](https://developer.apple.com/documentation/cfnetwork)
* [Get CFNetwork Version number](https://developer.apple.com/forums/thread/124183)
* [SO: My similar answer](https://stackoverflow.com/a/60504236/2012219)