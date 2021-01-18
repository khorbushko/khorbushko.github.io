---
layout: post
comments: true
title: "Network reachability"
categories: article
tags: [iOS, SystemConfiguration, Network, Combine]
excerpt_separator: <!--more-->
comments_id: 24

author:
- kyryl horbushko
- Lviv
---

Now, networking is one of the core components of almost any mobile app. Most applications store, retrieve, analyze, and provide data to u using a network connection. Without networking, most apps can't exist at all. 

Different situations may occur and apps may be used in a different location with or without an internet connection. Sometimes we would like to notify the user that some connection interruptions have been detected and so the work of the app may be unstable. This indeed improves UX. 
<!--more-->

I don't want to cover good practices related to network connectivity usage - what we should do and what shouldn't, instead, I just want to cover the part that allows performing check the connection itself.
 
> In case if u have some doubts about the network connectivity checking process, I can only recommend review networking documentation available [here](https://developer.apple.com/library/archive/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/WhyNetworkingIsHard/WhyNetworkingIsHard.html#//apple_ref/doc/uid/TP40010220-CH13-SW2) and review Apple WWDC video ([#712](https://developer.apple.com/videos/play/wwdc2019/712/), [#713](https://developer.apple.com/videos/play/wwdc2019/713/))
> 

I should also mention that according to doc: 

> *" Checking the reachability flag does not guarantee that your traffic will never be sent over a cellular connection."*

So my advice before we start - make sure that the purpose of the network connection checking process does not reduce the functionality of your app, and u use it just as an informative mechanism, in other cases u can *lie* to your user and provide poor UX.

The most popular ways to check internet connection are created thanks to next frameworks:

- `SystemConfiguration`
- `Network`

## NetworkReachabilityProvider

Before we dive into details of each framework usage, we may want to configure some requirements for our NetworkStatus monitor. I have created `NetworkReachabilityProvider` protocol, that describes a possible way of determining information about network connection change:

{% highlight swift %}
import Foundation
import Combine

protocol NetworkReachabilityProvider: class {
    var networkStatusHandler: AnyPublisher<NetworkReachabilityStatus, Never> { get }
    
    func stopListening()
    func startListening() -> AnyPublisher<Bool, Never>
}

public enum NetworkReachabilityStatus: Equatable {
    public enum ConnectionType {
        case ethernetOrWiFi
        case wwan
    }
    
    case unknown
    case notReachable
    case reachable(ConnectionType)
}
{% endhighlight %}

As u can see, this protocol requires that we start and stop monitoring and does not provide u current state. Instead `networkStatusHandler` will return u current state as soon as u start listening. 

U may found such a way not useful for some cases - for example when u need to know instantly the status of a network connection. But I do this intentionally because u shouldn't have such a situation at all - remember that I mention above *"make sure that purpose of network connection checking process does not reduce the functionality of your app"*. So u don't need to know the instant status at all. And for informative purposes, u can use listeners and appropriate publishers.

> A good point to mention - there are a lot of discussions about reachability ([here](https://www.vadimbulavin.com/network-connectivity-on-ios-with-swift/) and [here](https://www.mikeash.com/pyblog/friday-qa-2013-06-14-reachability.html) for example) and it's non 100% precise result. And this is one more reason to not use this option for controlling how u logic works. Instead, better use the post-factum result of network requests and adjust logic using actual and REAL results.

## SystemConfiguration

This framework provides for us various mechanisms that *allow applications to access a device’s network configuration settings*.

> The System Configuration framework provides powerful, flexible support for establishing and maintaining access to a configurable network and system resources. It offers your application the ability to determine, set, and maintain configuration settings and to detect and respond dynamically to changes in that information. [more](https://developer.apple.com/library/archive/documentation/Networking/Conceptual/SystemConfigFrameworks/SC_Intro/SC_Intro.html#//apple_ref/doc/uid/TP40001065)
>
> [reference to api](https://developer.apple.com/documentation/systemconfiguration)

The most interesting part for us - is the chapter dedicated to reachability - [Determining Reachability and Getting Connected](https://developer.apple.com/library/archive/documentation/Networking/Conceptual/SystemConfigFrameworks/SC_ReachConnect/SC_ReachConnect.html#//apple_ref/doc/uid/TP40001065-CH204-BHAFBAHI). According to it we should perform a few main steps to get things done:

* Create a reference for your target remote host you can use in other reachability functions.
* Add the target to your run loop.
* Provide a callback function that’s called when the reachability status of your target changes.
* Determine if the target is reachable.

### Implementation

The API allows us to use network host or node name [`SCNetworkReachabilityCreateWithName`](https://developer.apple.com/documentation/systemconfiguration/1514904-scnetworkreachabilitycreatewithn?language=objc) we want to check or using the specified network address struct `sockaddr_in` - [`SCNetworkReachabilityCreateWithAddress`](https://developer.apple.com/documentation/systemconfiguration/1514895-scnetworkreachabilitycreatewitha?language=objc). Third option - [`SCNetworkReachabilityCreateWithAddressPair`](https://developer.apple.com/documentation/systemconfiguration/1514908-scnetworkreachabilitycreatewitha?language=objc) - allow to create a reachability reference to the specified network address.

> Checking host sometimes is useful, but this means that logic will depend on the availability of some host.

I prefer to use `SCNetworkReachabilityCreateWithAddress` - this does not require any host specification or specific network address.

{% highlight swift %}
// Socket address, internet style
var initialAddress = sockaddr_in()
// The length member, sin_len, was added with 4.3BSD-Reno,
// when support for the OSI protocols was added
initialAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
// internetwork: UDP, TCP, etc
initialAddress.sin_family = sa_family_t(AF_INET)
    
if let initialReachability: SCNetworkReachability =
    withUnsafePointer(
        to: &initialAddress, {
            $0.withMemoryRebound(
                to: sockaddr.self,
                capacity: MemoryLayout<sockaddr>.size
            ) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) {
   // do next steps...
} else {
   // handle failure...
}
{% endhighlight %}

Using `SCNetworkReachability` we can extract `SCNetworkReachabilityFlags` and retrive current state of network connectivity status:

{% highlight swift %}
var flags = SCNetworkReachabilityFlags()
if SCNetworkReachabilityGetFlags(reachability, &flags) {
    return flags
}
{% endhighlight %}

Function to retrive status may be done as next:

{% highlight swift %}
private func reachabilityOfNetworkFor(
    _ flags: SCNetworkReachabilityFlags
) -> NetworkReachabilityStatus {
    var networkStatus: NetworkReachabilityStatus = .unknown
    
    let isReachable = flags.contains(.reachable)
    let needsConnection = flags.contains(.connectionRequired)
    
    let canConnectAutomatically = flags.contains(.connectionOnDemand) ||
        flags.contains(.connectionOnTraffic)
    let canConnectWithoutUserInteraction = canConnectAutomatically &&
        !flags.contains(.interventionRequired)
    let isNetworkAvailableFlag = isReachable &&
        (!needsConnection || canConnectWithoutUserInteraction)
    
    if isNetworkAvailableFlag {
        networkStatus = .reachable(.ethernetOrWiFi)
        
        #if os(iOS)
        if flags.contains(.isWWAN) {
            networkStatus = .reachable(.wwan)
        }
        #endif
        
    } else {
        networkStatus = .notReachable
    }
    
    return networkStatus
}
{% endhighlight %}

This is all good, but we also would like to be informed when something changed. To configure such behavior we may use [`SCNetworkReachabilitySetCallback`](https://developer.apple.com/documentation/systemconfiguration/1514903-scnetworkreachabilitysetcallback?language=objc).

{% highlight swift %}
var context = SCNetworkReachabilityContext(
    version: 0,
    info: nil,
    retain: nil,
    release: nil,
    copyDescription: nil
)
context.info = Unmanaged.passUnretained(self).toOpaque()
    
let callbackEnabled = SCNetworkReachabilitySetCallback(
    reachability,
    { (_, flags, info) in
        if let info = info {
            let reachability = Unmanaged<NetworkReachability>
                .fromOpaque(info)
                .takeUnretainedValue()
            reachability.notifyListener(flags)
        }
    },
    &context
)
    
let queueEnabled = SCNetworkReachabilitySetDispatchQueue(
    reachability,
    handlerQueue
)
    
handlerQueue.async { [weak self] in
    self?.notifyListener(self?.flagsForCurrentReachability ?? .init())
}
{% endhighlight %}

> Alternative way is to use [`SCNetworkReachabilityScheduleWithRunLoop`](https://developer.apple.com/documentation/systemconfiguration/1514894-scnetworkreachabilityschedulewit?language=objc) instead of [`SCNetworkReachabilitySetDispatchQueue`](https://developer.apple.com/documentation/systemconfiguration/1514911-scnetworkreachabilitysetdispatch?language=objc). I prefere use `DispatchQueue`, bacause configuration is much easier.

`notifyListener` is a function that simply analyzes new flags and posts updates.

And we also need to have an option to stop the process:

{% highlight swift %}
SCNetworkReachabilitySetCallback(reachability, nil, nil)
SCNetworkReachabilitySetDispatchQueue(reachability, nil)
{% endhighlight %}

Putting all together we can get next:

{% highlight swift %}
import Foundation
import SystemConfiguration
import Combine

final class NetworkReachability: NetworkReachabilityProvider {
    
    public var networkStatusHandler: AnyPublisher<NetworkReachabilityStatus, Never> {
        reachabilityNotifier.eraseToAnyPublisher()
    }
    
    private let handlerQueue: DispatchQueue = .main
    private let reachability: SCNetworkReachability
    private var previousFlags: SCNetworkReachabilityFlags
    private let reachabilityNotifier: PassthroughSubject<NetworkReachabilityStatus, Never>
    
    private var flagsForCurrentReachability: SCNetworkReachabilityFlags? {
        var flags = SCNetworkReachabilityFlags()
        if SCNetworkReachabilityGetFlags(reachability, &flags) {
            return flags
        }
        
        return nil
    }
    
    // MARK: - Lifecycle
    
    convenience init?() {
        // Socket address, internet style
        var initialAddress = sockaddr_in()
        // The length member, sin_len, was added with 4.3BSD-Reno,
        // when support for the OSI protocols was added
        initialAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        // internetwork: UDP, TCP, etc
        initialAddress.sin_family = sa_family_t(AF_INET)
        
        if let initialReachability: SCNetworkReachability =
            withUnsafePointer(
                to: &initialAddress, {
                    $0.withMemoryRebound(
                        to: sockaddr.self,
                        capacity: MemoryLayout<sockaddr>.size
                    ) {
                        SCNetworkReachabilityCreateWithAddress(nil, $0)
                    }
                }) {
            self.init(reachability: initialReachability)
        } else {
            return nil
        }
    }
    
    private init(reachability: SCNetworkReachability) {
        self.reachability = reachability
        self.previousFlags = .init()
        self.reachabilityNotifier = PassthroughSubject<NetworkReachabilityStatus, Never>()
    }
    
    deinit {
        defer {
            reachabilityNotifier.send(completion: .finished)
        }
        stopListening()
    }
    
    // MARK: - Public
    
    func stopListening() {
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }
    
    @discardableResult
    func startListening() -> AnyPublisher<Bool, Never> {
        var context = SCNetworkReachabilityContext(
            version: 0,
            info: nil,
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        context.info = Unmanaged.passUnretained(self).toOpaque()
        
        let callbackEnabled = SCNetworkReachabilitySetCallback(
            reachability,
            { (_, flags, info) in
                if let info = info {
                    let reachability = Unmanaged<NetworkReachability>
                        .fromOpaque(info)
                        .takeUnretainedValue()
                    reachability.notifyListener(flags)
                }
            },
            &context
        )
        
        let queueEnabled = SCNetworkReachabilitySetDispatchQueue(
            reachability,
            handlerQueue
        )
        
        handlerQueue.async { [weak self] in
            self?.notifyListener(self?.flagsForCurrentReachability ?? .init())
        }
        
        return Just(callbackEnabled && queueEnabled).eraseToAnyPublisher()
    }
    
    // MARK: - Private
    
    private func reachabilityOfNetworkFor(
        _ flags: SCNetworkReachabilityFlags
    ) -> NetworkReachabilityStatus {
        var networkStatus: NetworkReachabilityStatus = .unknown
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        let canConnectAutomatically = flags.contains(.connectionOnDemand) ||
            flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically &&
            !flags.contains(.interventionRequired)
        let isNetworkAvailableFlag = isReachable &&
            (!needsConnection || canConnectWithoutUserInteraction)
        
        if isNetworkAvailableFlag {
            networkStatus = .reachable(.ethernetOrWiFi)
            
            #if os(iOS)
            if flags.contains(.isWWAN) {
                networkStatus = .reachable(.wwan)
            }
            #endif
            
        } else {
            networkStatus = .notReachable
        }
        
        return networkStatus
    }
    
    private func notifyListener(_ flags: SCNetworkReachabilityFlags) {
        guard previousFlags != flags else {
            return
        }
        previousFlags = flags
        let currentNetworkStatus = reachabilityOfNetworkFor(flags)
        
        reachabilityNotifier.send(currentNetworkStatus)
    }
}
{% endhighlight %}

### 3rd party solutions

If u don't want to spend some time and check how to implement this u may use already existing great solutions from [Apple](https://developer.apple.com/library/archive/samplecode/Reachability/Introduction/Intro.html#//apple_ref/doc/uid/DTS40007324-Intro-DontLinkElementID_2) or some other developers such as [Ashley Mills](https://github.com/ashleymills/Reachability.swift/blob/master/Sources/Reachability.swift)


> To adopt Reachability from Ashley Mills we may wrap her code in to next:

{% highlight swift %}
import Combine

final class ReachabilityAshley: NetworkReachabilityProvider {
    public var networkStatusHandler: AnyPublisher<NetworkReachabilityStatus, Never> {
        reachabilityNotifier.eraseToAnyPublisher()
    }
    
    private var reachability: Reachability
    private let reachabilityNotifier: PassthroughSubject<NetworkReachabilityStatus, Never>
    private var token: AnyCancellable?
    
    init?() {
        do {
            self.reachability = try Reachability()
            self.reachabilityNotifier = PassthroughSubject<NetworkReachabilityStatus, Never>()
        } catch {
            return nil
        }
    }
    
    func stopListening() {
        token?.cancel()
        token = nil
        reachability.stopNotifier()
    }
    
    @discardableResult
    func startListening() -> AnyPublisher<Bool, Never> {
        do {
            token = NotificationCenter.default
                .publisher(for: Notification.Name.reachabilityChanged)
                .sink(receiveValue: checkForReachability)
            try reachability.startNotifier()
            return Just(true).eraseToAnyPublisher()
        } catch {
            token?.cancel()
            return Just(false).eraseToAnyPublisher()
        }
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - Private
    
    private func checkForReachability(_ notification: Notification) {
        let networkReachability = notification.object as? Reachability
        var networkStatus: NetworkReachabilityStatus = .unknown

        if let remoteHostStatus = networkReachability?.connection {
            switch remoteHostStatus {
            case .wifi,
                 .cellular:
                networkStatus = .reachable(.ethernetOrWiFi)
            case .unavailable:
                networkStatus = .notReachable
            }
        }
        
        reachabilityNotifier.send(networkStatus)
    }
}
{% endhighlight %}

## Network

[`Network`](https://developer.apple.com/documentation/network) is a new framework available for iOS 12+ and dedicated for creating network connections to send and receive data using transport and security protocols. 

Within its rich functionality `Network` has `NWPathMonitor` class that can be used for* monitor and react to network changes*. Usage is much simpler in comparison to `SystemConfiguration`. To make it works, we simply create an object and subscribe to any changes, analyzing response:

{% highlight swift %}
import Foundation
import Combine
import Network

final class NetworkMonitor: NetworkReachabilityProvider {
    public var networkStatusHandler: AnyPublisher<NetworkReachabilityStatus, Never> {
        reachabilityNotifier.eraseToAnyPublisher()
    }
    
    private let monitor: NWPathMonitor = .init()
    private let handlerQueue: DispatchQueue = .main
    private let reachabilityNotifier: PassthroughSubject<NetworkReachabilityStatus, Never>
    
    // MARK: - Lifecycle
    
    public init() {
        reachabilityNotifier = PassthroughSubject<NetworkReachabilityStatus, Never>()
        configureListener()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Public
    
    public func stopListening() {
        monitor.cancel()
    }
    
    @discardableResult
    public func startListening() -> AnyPublisher<Bool, Never> {
        monitor.start(queue: handlerQueue)
        return Just(true).eraseToAnyPublisher()
    }
    
    // MARK: - Private
    
    private func configureListener() {
        var networkStatus: NetworkReachabilityStatus = .unknown

        monitor.pathUpdateHandler = { [weak self] path in
            switch path.status {
            case .satisfied:
                if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
                    networkStatus = .reachable(.ethernetOrWiFi)
                } else {
                    networkStatus = .reachable(.wwan)
                }
            case .unsatisfied,
                 .requiresConnection:
                networkStatus = .notReachable
            @unknown default:
                networkStatus = .notReachable
            }
            
            self?.reachabilityNotifier.send(networkStatus)
        }
    }
}
{% endhighlight %}

As u can see - such solutions are much simpler and compact. But under the hood, it's using the same mechanisms.

To demonstrate usage of all variants, I created demo app:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-01-18-network-reachability/demo.gif" alt="demo" width="300"/>
</div>

## Resources

- [SysytemConfiguration programming Guide](https://developer.apple.com/library/archive/documentation/Networking/Conceptual/SystemConfigFrameworks/SC_ReachConnect/SC_ReachConnect.html#//apple_ref/doc/uid/TP40001065-CH204-BHAFBAHI)
- [Simple ping](https://developer.apple.com/library/archive/samplecode/SimplePing/Introduction/Intro.html)
- [Apple Reachability](https://developer.apple.com/library/archive/samplecode/Reachability/Introduction/Intro.html#//apple_ref/doc/uid/DTS40007324-Intro-DontLinkElementID_2)
- [Network](https://developer.apple.com/documentation/network)
- [Network connectivity on ios with swift](https://www.vadimbulavin.com/network-connectivity-on-ios-with-swift/)
- [MikeAsh Friday Q&A 2013-06-14: Reachability](https://www.mikeash.com/pyblog/friday-qa-2013-06-14-reachability.html)

[download source code]({% link assets/posts/images/2021-01-18-network-reachability/source/networkStatus.zip %})
