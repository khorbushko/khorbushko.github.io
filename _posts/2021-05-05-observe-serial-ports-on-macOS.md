---
layout: post
comments: true
title: "Observe serial ports on macOS"
categories: article
tags: [macOS, serial, swift]
excerpt_separator: <!--more-->
comments_id: 41

author:
- kyryl horbushko
- Lviv
---

Recently I played a bit within Arduino using Visual Code. After switching to M1 mac, I faced with [issue](https://github.com/microsoft/vscode-arduino/issues/1232), that visual-code extension for Arduino does not allow to select of a serial port and to open communication channel with the board.

As result, every time I must check all available serial ports, and put a name into the `arduino.json` config file. And when I need to communicate with port - I should also use either Arduino IDE either some other tools. 
<!--more-->

I believe that fix will be created soon, but, doing the same thing, again and again, is a bit annoying, so I decided to automate a bit this process, and one of the step, required for this - is to simplify getting of serial port list and communication via serial port.

To do so, I decided to create a menu bar extra's app, that in few clicks can provide some common actions related to serial ports on the system.

## Serial port observation

In this app, I added a view, that displays the list of serial ports, reflects any changes in it (on connection via USB Arduino board for example), and allows copy name or/and open a communication view with it.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-05-05-observe-serial-ports-on-macOS/preview.png" alt="preview" width="250"/>
</div>
<br>
<br>

> I already covered few points related to this app [here]({% post_url 2021-04-25-window-group %}) and [here]({% post_url 2021-04-30-minimal-macOS-menu-bar-extra's-app-with-SwiftUI %})

To solve this task, I looked into available options and decided to use [`IOKit`](https://developer.apple.com/documentation/iokit) from Apple.

### getting serial ports data

To find all serial ports with `IOKit` we should create a set of parameter that we can use for search and then look up registered `IOService` objects that match a matching dictionary:

{% highlight swift %}
var result: kern_return_t = KERN_FAILURE
let classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue)
result = IOServiceGetMatchingServices(
  kIOMasterPortDefault,
  classesToMatch,
  &serialPortIterator
)
{% endhighlight %}

`kern_return_t` will contain the result of the operation - `KERN_SUCCESS` if everything is fine, or other code. 

Function `IOServiceMatching` creates for us matching dictionary with base parameters, required for search.

U can add additional parameters in it, using small dance between types:

{% highlight swift %}

var matchingDict = IOServiceMatching(kIOSerialBSDServiceValue) as NSDictionary as! [String: AnyObject]
matchingDict[kIOSerialBSDTypeKey] = kIOSerialBSDAllTypes as AnyObject
let cfMatchingDictionary = matchingDict as CFDictionary
{% endhighlight %}

> Check API declaration [`IOSerialKeys.h`](https://opensource.apple.com/source/IOSerialFamily/IOSerialFamily-6/IOSerialFamily.kmodproj/IOSerialKeys.h.auto.html) for other keys:
> 
{% highlight swift %}
Sample Matching dictionary
{
    IOProviderClass = kIOSerialBSDServiceValue;
    kIOSerialBSDTypeKey = kIOSerialBSDAllTypes
			| kIOSerialBSDModemType
			| kIOSerialBSDRS232Type;
    kIOTTYDeviceKey = <Raw Unique Device Name>;
    kIOTTYBaseNameKey = <Raw Unique Device Name>;
    kIOTTYSuffixKey = <Raw Unique Device Name>;
    kIOCalloutDeviceKey = <Callout Device Name>;
    kIODialinDeviceKey = <Dialin Device Name>;
}

> Note only the IOProviderClass is mandatory.  The other keys
> allow the searcher to reduce the size of the set of matching 
> devices.
{% endhighlight %}
>
> U can also specify other search parameters for devices. For example, to search USB, u [should add additional key/value](https://stackoverflow.com/questions/39003986/usb-connection-delegate-on-swift) to matching dictionary (`kUSBVendorID`, `kUSBProductID`):
> 
{% highlight swift %}
// vendor
vendorID = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &usbVendor);
CFDictionarySetValue(matchingDict, CFSTR(kUSBVendorID), vendorID);
{% endhighlight %}

Now, we have a [iterator](https://www.cplusplus.com/reference/iterator/) [`io_iterator_t`](https://developer.apple.com/documentation/iokit/io_iterator_t), by using which we can get all the elements:

{% highlight swift %}
struct SerialPort: Identifiable, Codable {
  
  var id: String {
    "\(bsdPath.hash)"
  }
  
  /// IOCalloutDevice
  var bsdPath: String
  
  /// IOTTYBaseName
  var ttyName: String?
  
  /// IOTTYDevice
  var ttyDevice: String?
  
  /// IODialinDevice
  var dialinPath: String?
}

func extractSerialPaths(portIterator: io_iterator_t) -> [SerialPort] {
	var paths: [SerialPort] = []
	var serialService: io_object_t
	repeat {
	  serialService = IOIteratorNext(portIterator)
	  if (serialService != 0) {
	    
	    var serialPortInfo: SerialPort!
	    
	    [
	      kIOCalloutDeviceKey,
	      kIOTTYDeviceKey,
	      kIOTTYBaseNameKey,
	      kIODialinDeviceKey
	    ].forEach { (inspectKey) in
	      let currentKey: CFString = inspectKey as CFString
	      let valueCFString =
	        IORegistryEntryCreateCFProperty(
	          serialService,
	          currentKey, 
	          kCFAllocatorDefault,
	          0
	        )
	        .takeUnretainedValue()
	      if let value = valueCFString as? String {
	        
	        switch inspectKey {
	          case kIOCalloutDeviceKey:
	            serialPortInfo = .init(bsdPath: value)
	          case kIOTTYBaseNameKey:
	            serialPortInfo.ttyName = value
	          case kIOTTYDeviceKey:
	            serialPortInfo.ttyDevice = value
	          case kIODialinDeviceKey:
	            serialPortInfo.dialinPath = value
	          default:
	            break
	        }
	      }
	    }
	    if serialPortInfo != nil {
	      paths.append(serialPortInfo)
	    }
	    
	  }
	} while serialService != 0
	    
	return paths
}
{% endhighlight %}

Now, we can fetch all the serial ports available. Even more, by modifying the `matchingDic`, we can look up any device type.

### observing changes

The previous code works fine but does not display any changes in real-time. But what if we open a screen and connect a USB device (in my case - Arduino board) - nothing is happening - I either need to reopen the screen either add some button which on click will reload serial port data... Not the best approach.

To solve this we can use `IOKit` notifications - `IOServiceAddMatchingNotification`.

1. create a notification

{% highlight swift %}
let adddedNotificationPort: IONotificationPortRef = IONotificationPortCreate(kIOMasterPortDefault)
// here optional step - we can specify queue on which we will process event
IONotificationPortSetDispatchQueue(adddedNotificationPort, processingIOKitQueue)
{% endhighlight %}

2. add this notification as a source to `RunLoop`

{% highlight swift %}
CFRunLoopAddSource(CFRunLoopGetCurrent(),
                   IONotificationPortGetRunLoopSource(
                   adddedNotificationPort).takeUnretainedValue(),
				   CFRunLoopMode.defaultMode)
{% endhighlight %}

> If u would like to know a bit more about [`RunLoop`]({ post_url 2020-11-29-runloop-in-depth }) - read my post

3. use previously defined `matchingDic` for subscription to this event:

{% highlight swift %}
var matchingDict = IOServiceMatching(kIOSerialBSDServiceValue) as NSDictionary as! [String: AnyObject]
matchingDict[kIOSerialBSDTypeKey] = kIOSerialBSDAllTypes as AnyObject
let cfMatchingDictionary = matchingDict as CFDictionary

let selfPtr = Unmanaged.passUnretained(self).toOpaque()
 
var portIterator: io_iterator_t = 0 
let resultForPublish: kern_return_t = IOServiceAddMatchingNotification(
  adddedNotificationPort,
  kIOPublishNotification,
  cfMatchingDictionary,
  callbackForAddedPort,
  selfPtr,
  &portIterator
)
{% endhighlight %}

Again - `resultForPublish` is `kern_return_t `, as I described earlier. Also, u can see, that I used `selfPtr` - we will use it a bit later, when we proceed notification. That's why we should convert it to `UnsafeMutableRawPointer`, and later convert it back:

{% highlight swift %}
let selfPtr = Unmanaged.passUnretained(self).toOpaque()
// and back
let portDiscoverer = Unmanaged<SerialPortDiscoverer>.fromOpaque(refCon).takeUnretainedValue()
{% endhighlight %}

4. define callback for notification `callbackForAddedPort`:

`callbackForAddedPort` has a type defined as  `IOServiceMatchingCallback`:

{% highlight swift %}
public typealias IOServiceMatchingCallback = @convention(c) (UnsafeMutablePointer<Void>, io_iterator_t) -> Void
{% endhighlight %}

U can see `@convention(c)` - this means, that by using this annotation we can refer to `CFunctionPointer` - *"The c argument is used to indicate a C function reference. The function value carries no context and uses the C calling convention."* ([source](https://itun.es/us/k5SW7.l))

So, we can use same syntax and define our callback as next:

{% highlight swift %}
let callbackForAddedPort: @convention(c) (UnsafeMutableRawPointer?, io_iterator_t) -> Void = { refCon, iterator in
  if let refCon = refCon {
    // reference to observer
    let portDiscoverer = Unmanaged<SerialPortDiscoverer>.fromOpaque(refCon).takeUnretainedValue()
    
    // here we will receive array with only 1 element
    let newPorts = portDiscoverer.extractSerialPaths(portIterator: iterator)
    newPorts.forEach(portDiscoverer.appendPort)
    
  } else {
    print("ref to observer obj not valid")
  }
}
{% endhighlight %}

5. clean up, when we done

To cleanUp, after we have done our job (on-screen close, for example), we should release ref to the pointer. In obj-c, we also should retain iterator and `matchingDic` in our case, but swift manage part of the values for us. All we should do - is to release the pointer to iterator on failure or when we are done:

{% highlight swift %}
IOObjectRelease(portIterator)
{% endhighlight %}

We are ready to receive a notification.

But this is only the first part of the job, the second one - is to subscribe for `kIOTerminatedNotification`- when some port was removed from the system (unplug from the USB). To do so, we should repeat all steps above, but replace the type of notification we would like to receive with `kIOTerminatedNotification` instead of `kIOPublishNotification`.

> From the docs:
> A notification type from `IOKitKeys.h`
>
- `kIOPublishNotification` Delivered when an IOService is registered.
- `kIOFirstPublishNotification` Delivered when an IOService is registered, but only once per IOService instance. Some IOService's may be reregistered when their state is changed.
- `kIOMatchedNotification` Delivered when an IOService has had all matching drivers in the kernel probed and started.
- `kIOFirstMatchNotification` Delivered when an IOService has had all matching drivers in the kernel probed and started, but only once per IOService instance. Some IOService's may be reregistered when their state is changed.
- `kIOTerminatedNotification` Delivered after an IOService has been terminated.

And don't forget to iterate over the iterator, to receive all initial ports:

{% highlight swift %}
var serialService: io_object_t
repeat {
  serialService = IOIteratorNext(iterator)
  // do stuff here with service
} while serialService != 0
{% endhighlight %}

### demo

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-05-05-observe-serial-ports-on-macOS/demo_serialPorts.gif" alt="demo_serialPorts" width="300"/>
</div>
<br>
<br>


## Resources

* [`IOKit`](https://developer.apple.com/documentation/iokit)
* [`io_iterator_t`](https://developer.apple.com/documentation/iokit/io_iterator_t)
* [`IOSerialKeys.h`](https://opensource.apple.com/source/IOSerialFamily/IOSerialFamily-6/IOSerialFamily.kmodproj/IOSerialKeys.h.auto.html)
* [Technical Q&A QA1076 - Tips on USB driver matching for Mac OS X](https://developer.apple.com/library/archive/qa/qa1076/_index.html)
* [Serial Port Programming in Swift for MacOS](https://www.mac-usb-serial.com/docs/tutorials/serial-port-programming-swift-mac-os-x.html)
* [USB Connection Delegate on Swift](https://stackoverflow.com/questions/39003986/usb-connection-delegate-on-swift)
* [iterator](https://www.cplusplus.com/reference/iterator/)
* [SO New @convention(c) in Swift 2: How can I use it?](https://stackoverflow.com/questions/30740560/new-conventionc-in-swift-2-how-can-i-use-it)
* [Performing Serial I/O](https://developer.apple.com/library/archive/samplecode/SerialPortSample/Introduction/Intro.html#//apple_ref/doc/uid/DTS10000454)
* [Detect Serial Devices in Swift](https://www.mac-usb-serial.com/docs/tutorials/detect-serial-devices-mac-os-x-using-swift.html)
* [macOS USB Enumeration in C](https://nachtimwald.com/2020/12/06/macos-usb-enumeration-in-c/)
* [Communicating with a Modem on a Serial Port](https://developer.apple.com/documentation/iokit/communicating_with_a_modem_on_a_serial_port)
* [Hello IOKit: Creating a Device Driver With Project Builder](http://mirror.informatimago.com/next/developer.apple.com/documentation/Darwin/Conceptual/howto/kext_tutorials/hello_iokit/hello_iokit.html)
* [ORSSerialPort](https://github.com/armadsen/ORSSerialPort)