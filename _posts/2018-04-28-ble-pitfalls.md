---
layout: post
comments: true
title: "BLE pitfalls"
categories: article
tags: [BLE,iOS, utils]
excerpt_separator: <!--more-->
comments_id: 5

author:
- kyryl horbushko
- Lviv
---

> originally this post was written on Apr 28, 2018 and available [here](https://medium.com/@kirill.ge/cocoatouch-ble-pitfalls-9b9b92ebc739) 

Abbreviations (in order of appearance):

* **BLE**- Bluetooth Low
* **PCB** — Printed circuit board
* **API** — Application Programming Interface


Every developer who worked with iOS BLE knows that not everything is so good as it’s described in the documentation. And today, I would like to describe a few main points that can be tricky when working with BLE. I would like to provide some information for you, reader and I guess BLE-developer, to make your journey in Cocoa BLE world less painful and more productive.

<!--more-->

So, the very first thing you need to know is the answer to the question ”Where exactly something goes wrong — on my side or on the connected device? Does something happen when I send a command to the device?”

To get an answer to this question I recommend to use a few approaches:

* sniffer tool
* 3rd party apps for testing API
* logging
* firmware version of the device, with which you work without encryption or any other protection

So, let’s discuss every point more details.


## Sniffer tool

**Sniffer tool** — this a tool that allows you to intersect data packets and analyze them without a CoreBluetooth framework. It can be very helpful to distinguish different aspects of BLE communication — requests, responses, unhandled error, unexpected messages, etc. To set up such tool, you basically need several things: special Ppcband firmware Mac. I used Wireshark and Nordic Semiconductors test board. Together they provide a powerful toolset for sniffing activities.

Sniffer tools can be used in two modes — advertisement and connection.

Useful links are:

* [info about sniffing tools and how they work](http://www.argenox.com/bluetooth-low-energy-ble-v4-0-development/library/ultimate-guide-to-debugging-bluetooth-smart-ble-products/)
* [sniffer-tool — nRF-Sniffer-UG](https://www.nordicsemi.com/eng/nordic/Products/nRF52-DK/nRF-Sniffer-UG-v2/65245)
* [Wireshark](https://www.wireshark.org/)
* [XQuartz (needed for some versions of Wireshark)](https://www.xquartz.org/releases/XQuartz-2.7.8.html)

## 3rd party apps for testing API

3rd party apps for testing API — one of the fastest ways to test your device is to use 3rd party solutions. With such products, you can easily scan, discover, send/receive, or even simulate some functionality of your device. 

Great examples are:

* [LightBlue](https://itunes.apple.com/us/app/lightblue-explorer/id557428110?mt=8)
* [BlueGecko](https://itunes.apple.com/us/app/silicon-labs-blue-gecko-wstk/id1030932759?mt=8)

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2018-04-28-ble-pitfalls/src_1.png" alt="preview_1" width="550"/>
</div>

## Logging

Logging — most BLE devices talk to a smartphone on the other end. Because of this, understanding what’s happening on the phone itself can be critical. One of the most useful techniques for checking what’s happening on the phone is to use the operating system’s own logging capabilities.

In iOS, enabling Bluetooth logging requires installing a special profile in the device. You can find more information on enabling it at [link](https://developer.apple.com/bluetooth/)

Once enabled, iTunes can sync the logs to a computer and they can be analyzed.


## Firmware

Firmware — to protect own product it’s common to use an encrypted protocol of communication between app and device. Such approach ensures a higher security level for a user, but at the same time is much harder in terms of development. To simplify this process, always use an unencrypted version of firmware during development and include an additional level of security only for production purposes. This, of course, affects firmware development time a little bit, but this also reduces efforts required from your side to develop a great app using such firmware.

At this point, I assume that development environment is up and running, and all you need is just to make your hands dirty and write some code to bring life to the app :).

Now, to make sure your user gets best UX you should fully control all processes inside your app and, correspondingly, all aspects of it. Basically, you should think about the following points:

* Bluetooth device availability (status observation)
* timeout for from the connected device
* multiline response handling (if needed)
* backgrounding (if needed)
* multi-device connection (if needed)

I won’t describe all aspects of each point in the list above, instead, I will give you some advice for them.

## Status observation

Status observation — luckily for us, iOS may work with a few devices at the same time and so with a few objects that can handle work with Bluetooth devices. And of course, we will use this possibility. One approach is to prepare a simple device scanner — this will allow you to be notified when a Bluetooth device is up and running and vise This approach is simple and effective and may be as follows:

{% highlight swift %}
import Foundation
import CoreBluetooth
 
final class BLEStatusObserver: NSObject {
 
    public struct Notifications {
        public static let BLEStatusObserverDidDetectBLEStatusChange = "BLEStatusObserverDidDetectBLEStatusChangeNotification"
 
        struct Keys {
            static let availability = "availability"static let message = "message"
        }
    }
    static let observer = BLEStatusObserver()
 
    var isBleDeviceActive:Bool {
        return currentState == .poweredOn
    }
    private var centralManager:CBCentralManager?
    private var currentState:CBManagerState = .unknown
 
    // MARK: - LifeCycle
 
    override init() {
        super.init()
 
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}
 
extension BLEStatusObserver:CBCentralManagerDelegate {
    // MARK: - CBCentralManagerDelegate
 
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var notificationMessage:String? = nilswitch central.state {
            case .unauthorized:
                notificationMessage = NdynamicLocalizableString"bleService.message.StatusUnathorized")
            case .unsupported:
                notificationMessage = NdynamicocalizableString("bleService.message.Unsupported")
            case .poweredOff:
                notificationMessage = NdynamicocalizableString("bleService.message.PowerOff")
            case .poweredOn:
                notificationMessage = NdynamicocalizableString("bleService.message.PowerOn")
            default:
                break
        }
 
        currentState = central.state
 
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: BLEStatusObserver.Notifications.BLEStatusObserverDidDetectBLEStatusChange), 
                                       object: nil, userInfo: [
                                                                    Notifications.Keys.availability : central.state == .poweredOn,
                                                                    Notifications.Keys.message : notificationMessage ?? ""
                                                                ])
    }
}
{% endhighlight %}

## Timeout

Timeout — timeout for BLE requests is not handled by CoreBluetooth by default, so you should implement such mechanism by yourself. And here is the place where you can use all your creativity within project requirements. The only thing that I guess you need to know — yes, timeout is required.


Another useful point may be the knowledge of the data packet transferring speed and dependencies. Someone has already prepared tests on real devices ([like this one](https://punchthrough.com/blog/posts/maximizing-ble-throughput-on-ios-and-android)), you may also want to check out an official Bluetooth doc ([like this one](http://people.csail.mit.edu/rudolph/Teaching/Articles/BTBook.pdf)).

 I suppose that this time may depend on several things:

* transmitter models of your BLE devices
* realization of firmware (different functions may require different time to execute, on one project we have a request that may execute up to 4 sec on the device side)
* range from the device
* transmitting power

Taking this into account, I suggest to start within 50–100 ms as a start point and adjust it based on your needs.

## Multiline response

Multiline response — some firmware may return a few lines of response for specific requests (because of the packet size limitation or realization or another reason). In this case, I would like to suggest to agree on the exact protocol of communication and structure of each request/response. For example, it may be something like this:

* every request should be n-bytes, with 0 on unused space
* every response should start/end within some symbol(s)

Such approach is very simple and, believe me, very effective. If you implement this behavior, you may even have better sleep at night :)

One more point — make sure you execute 1 request at a time. To use such approach, NSOperationQueue may be very helpful. I will not dive into details of realization, but I want to emphasize that you should create some kind of AsyncOperation to properly handle all cases. 

<script src="https://gist.github.com/calebd/93fa347397cec5f88233.js"></script>

> note - this is just a sample

## Backgrounding

Backgrounding — this is interesting. Seriously, very interesting. You should read all available documentation, and do it again. A lot of things are tricky. I can’t describe all tricky parts here, I guess this is a question for a separate [article](https://www.cloudcity.io/blog/2015/06/11/zero-to-ble-on-ios-part-one/).

All you need to know about backgrounding within CocoaTouch — it works, but sometimes it may work not as you expected. In this case, there is only one solution — read the documentation again.

Huh, I guess now you can start coding :).

## REFERENCES

### Apple Developer — Core Bluetooth Programming Guides:

* [About bluetooth](https://developer.apple.com/bluetooth/)
* [CoreBluetooth concepts](https://developer.apple.com/library/ios/documentation/NetworkingInternetWeb/Conceptual/CoreBluetooth_concepts/AboutCoreBluetooth/Introduction.html)
* [WWDC 2012 Videos — Core Bluetooth 101](https://developer.apple.com/videos/wwdc/2012/#703)
* [WWDC 2012 Videos — Advanced Core Bluetooth](https://developer.apple.com/videos/wwdc/2012/#705)
* [WWDC 2013 Videos — Core Bluetooth](https://developer.apple.com/videos/wwdc/2013/#703)

### Other:

* [This nice tutorial](https://www.cloudcity.io/blog/2015/06/11/zero-to-ble-on-ios-part-one/)
* [Sniffer tool](http://www.argenox.com/bluetooth-low-energy-ble-v4-0-development/library/ultimate-guide-to-debugging-bluetooth-smart-ble-products/)