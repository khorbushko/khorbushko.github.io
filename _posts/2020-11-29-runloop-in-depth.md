---
layout: post
comments: true
title: "RunLoop in details"
categories: article
tags: [iOS, CoreFoundation, longRead]
excerpt_separator: <!--more-->
comments_id: 8

author:
- kyryl horbushko
- Lviv
---

Often we can hear such terms as `RunLoop`, `MainLoop`, or `EventLoop`. But do we know how it works? And what responsibilities it has? 
<!--more-->

## RunLoop

`RunLoop` is the implementation of well-known [EventLoop](https://en.wikipedia.org/wiki/Event_loop) pattern - * programming construct or design pattern that waits for and dispatches events or messages in a program*.


> `while (!end) { } `


This pattern has been implemented on many platforms. Thus, the main problems that it should resolve are:

- receive events/messages
- work when works exist and sleep when no work available (correct resource management).

Hight level description of `Thread`:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-11-29-runloop-in-depth/thread.pdf" alt="thread life" width="350"/>
</div>

Hight level description of `EventLoop`:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-11-29-runloop-in-depth/eventLoop.pdf" alt="thread life" width="450"/>
</div>

## iOS/macOS RunLoop

Talking about iOS/macOS we always refer to `RunLoop`. To be more correct - 2 classes implement this behavior:

- `CFRunLoopRef` ([open source](https://link.jianshu.com/?t=http://opensource.apple.com/source/CF/CF-855.17/CFRunLoop.c))
- `NSRunLoop` (based on `CFRunLoopRef`)

As you already see, `RunLoop` is connected to the thread. You can't create `RunLoop` directly, instead, it's can be created at the very start of `Thread` creating and destroyed at the very end of the`Thread` lifecycle. There are 2 function that provide access to RunLoop - `CFRunLoopGetMain()` and `CFRunLoopGetCurrent()`

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-11-29-runloop-in-depth/runloop_iOS.pdf" alt="debug backtrace" width="650"/>
</div>

> *Run loops are part of the fundamental infrastructure associated with threads. A run loop is an event processing loop that you use **to schedule work** and coordinate the receipt of incoming events. The purpose of a run loop is to **keep your thread busy when there is work** to do and **put your thread to sleep when there is none**.* - [Apple](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html). 

### interface

CoreFoundation has 5 classes that represent full interface for work with RunLoop:

* `CFRunLoopRef`
* `CFRunLoopModeRef`
* `CFRunLoopSourceRef`
* `CFRunLoopTimerRef`
* `CFRunLoopObserverRef`

Let's review each of these types.

[**`CFRunLoopRef`**](https://developer.apple.com/documentation/corefoundation/cfrunloopref) - reference to a run loop object. This object monitors sources of input tasks and dispatches control when they ready to proceed. Three types of objects can be monitored by a run loop: sources (`CFRunLoopSource`), timers (`CFRunLoopTimer`), and observers (`CFRunLoopObserver`). To get any event u need to put any of the supported objects in RunLoop first with an appropriate function call (it's also possible to remove that object later).

Supported modes for CoreFoundation are:

1. `kCFRunLoopDefaultMode` - observe any object changes when the thread is sitting idle. **`Default`**. This mode good when a thread is created for receiving events.
2. `kCFRunLoopCommonMode` - pseudo mode, hold an object and share it with other sets of "common" modes. Thus this is pseudo mode - RunLoop never runs in this mode. Should be used only for a specific set of sources, timers, and observers shared by other modes.

>  check this from `CFRunLoop`
> 
{% highlight swift %}
CFMutableSetRef _commonModes;
CFMutableSetRef _commonModeItems;
{% endhighlight %}

Each `Thread` has **ONLY** one run loop. `RunLoop` can't be created or destroyed on your own - it's done automatically in CoreFoundation when needed (according to doc). Instead u can get `current` `RunLoop` mode.

`RunLoop` has few Modes with Source/Timer/Observer in it. Only **ONE** Mode can be active at once, and it's called `current`. To switch between modes u need to exit Loop and set a new mode. Why? just to separate Source/Timer/Observer and make them not affect each other.


[CFRunLoopRef]({% link assets/posts/images/2020-11-29-runloop-in-depth/pdf/CFRunLoopRef.pdf %})


[**`CFRunLoopSourceRef`** ](https://developer.apple.com/documentation/corefoundation/cfrunloopsourceref?language=objc)- This is an abstraction of an input source that can be put into the RunLoop. They can create some async events (network message or user action). So this is an abstraction for some events/operations.

There are 2 categories Version 0 and Version 1

`Version 0` has only one callback (function pointer), which does not actively trigger an event. In use, you need to call `CFRunLoopSourceSignal(source)` first, mark the Source as pending, and then manually call `CFRunLoopWakeUp(RunLoop)` to wake up RunLoop and let it handle the event.

`Version 1` managed by run loop and kernel. This source use `mach_ports` to signal when it's ready to be executed (automatically). This Source can actively wake up the `RunLoop` thread.

A run loop source can be registered in multiple run loops and run loop modes at the same time.

[CFRunLoopSourceRef]({% link assets/posts/images/2020-11-29-runloop-in-depth/pdf/CFRunLoopSourceRef.pdf %})


[**`CFRunLoopTimerRef`**](https://developer.apple.com/documentation/corefoundation/cfrunlooptimerref) - timer-based trigger. This is a specialized RunLoop source that can be fired at present and at a future time. Each RunLoop timer can be registered in one RunLoop at a time but can be added to a few modes within one run loop.

`CFRunLoopTimer` is “toll-free bridged” with its Cocoa Foundation counterpart, `NSTimer`. This means that the Core Foundation type is interchangeable in function or method calls with the bridged Foundation object. 

> A timer is not a real-time mechanism; it fires only when one of the run loop modes to which the timer has been added is running and able to check if the timer’s firing time has passed. If a timer’s firing time occurs while the run loop is in a mode that is not monitoring the timer or during a long callout, the timer does not fire until the next time the run loop checks the timer. Therefore, the actual time at which the timer fires potentially can be a significant period of time after the scheduled firing time.

[CFRunLoopTimerRef]({% link assets/posts/images/2020-11-29-runloop-in-depth/pdf/CFRunLoopTimerRef.pdf %})


[**`CFRunLoopObserverRef`** ](https://developer.apple.com/documentation/corefoundation/cfrunloopobserver-ri3) - provides a general means to receive callbacks at different points within a running run loop. They fire at a specific location and execution of RunLoop. Can be one-time or repeatable.
Observers do not automatically added to the RunLoop, instead, a special call should be executed to add them.

Each run loop observer can be registered in only one run loop at a time, although it can be added to multiple run loop modes within that run loop.

[CFRunLoopObserverRef]({% link assets/posts/images/2020-11-29-runloop-in-depth/pdf/CFRunLoopObserverRef.pdf %})

{% highlight swift %}
/* Run Loop Observer Activities */
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
    // about to enter Loop
    kCFRunLoopEntry = (1UL << 0),
    // About to process Timer
    kCFRunLoopBeforeTimers = (1UL << 1),
    // About to process Source
    kCFRunLoopBeforeSources = (1UL << 2),
    // about to enter sleep
    kCFRunLoopBeforeWaiting = (1UL << 5),
    // Just wake up from sleep
    kCFRunLoopAfterWaiting = (1UL << 6),
    // About to exit Loop
    kCFRunLoopExit = (1UL << 7),
    // All states
    kCFRunLoopAllActivities = 0x0FFFFFFFU
};
{% endhighlight %}

### mode

We can check source of CFRunLoop.c and found actual declaration for RunLoop mode:


{% highlight swift %}
struct __CFRunLoopMode {
    CFRuntimeBase _base;
    pthread_mutex_t _lock;	/* must have the run loop locked before locking this */
    CFStringRef _name;
    Boolean _stopped;
    char _padding[3];
    ...
}

struct __CFRunLoop {
    CFRuntimeBase _base;
    pthread_mutex_t _lock;			/* locked for accessing mode list */
    __CFPort _wakeUpPort;			// used for CFRunLoopWakeUp 
    Boolean _unused;
    volatile _per_run_data *_perRunData;              // reset for runs of the run loop
    pthread_t _pthread;
    uint32_t _winthread;
    
    // modes:
    
    CFMutableSetRef _commonModes;
    CFMutableSetRef _commonModeItems;
    CFRunLoopModeRef _currentMode;
    CFMutableSetRef _modes;
    
    ...
};   
{% endhighlight %}

As was mention previously, `commonMode` is pseudo mode - you can see from source code that this implemented via few props in the structure that defines `__CFRunLoop`. What does this mean from a practical point of view? 

Main thread has 2 mode: `kCFRunLoopDefaultMode` `UITrackingRunLoopMode` and both of them marked as `common`. 

> check other [modes](https://developer.apple.com/documentation/foundation/runloop/mode) and [here](https://developer.apple.com/documentation/foundation/nsrunloop/run_loop_modes)

`Default` - this one in which application is running, but for example when u touch screen and scroll and mode switched to `tracking` mode, this mean that if u have a timer attached to default mode and u actively touch (for example scroll table view such as news feed), the timer will not be called. This guarantees that scroll operation will be not affected by other sources, in our case timer.

What to do so both timer and scrolling work without any delay or freeze?. You need to register a timer within multiply modes. Yes, the timer can be added to **ONLY** one `RunLoop` but for few modes (as was mention above). To do so - simple use `common` mode - thus is *pseudo* mode and as we already know, share a resource.

You can find a lot of posts regarding this "problem" (that is correct by design selected by Apple). 

> for example [here](https://www.pixeldock.com/blog/how-to-avoid-blocked-downloads-during-scrolling/) or [here](https://stackoverflow.com/questions/7222449/nsdefaultrunloopmode-vs-nsrunloopcommonmodes) or [here](https://programmer.ink/think/ios-development-runloop-understanding.html)

> Check this post for more info about [runLoop and timers](https://www.programmersought.com/article/23684546929/)

So what modes do we have from Apple?

| Mode                         | Name                                                                | Description                                                                                                                                                                                                                                                                                                                                                                                         |
|------------------------------|---------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Default                      | NSDefaultRunLoopMode(Cocoa) kCFRunLoopDefaultMode (Core Foundation) | The default mode is the one used for most operations. Most of the time, you should use this mode to start your run loop and configure your input sources.                                                                                                                                                                                                                                           |
| Connection                   | NSConnectionReplyMode(Cocoa)                                        | Cocoa uses this mode in conjunction with NSConnection objects to monitor replies. You should rarely need to use this mode yourself.                                                                                                                                                                                                                                                                 |
| Modal                        | NSModalPanelRunLoopMode(Cocoa)                                      | Cocoa uses this mode to identify events intended for modal panels.                                                                                                                                                                                                                                                                                                                                  |
| Event tracking               | NSEventTrackingRunLoopMode(Cocoa)                                   | Cocoa uses this mode to restrict incoming events during mouse-dragging loops and other sorts of user interface tracking loops.                                                                                                                                                                                                                                                                      |
| Common modes                 | NSRunLoopCommonModes(Cocoa) kCFRunLoopCommonModes (Core Foundation) | This is a configurable group of commonly used modes. Associating an input source with this mode also associates it with each of the modes in the group. For Cocoa applications, this set includes the default, modal, and event tracking modes by default. Core Foundation includes just the default mode initially. You can add custom modes to the set using the CFRunLoopAddCommonMode function. |
| com.apple.securityd.runloop  | Communication with security. Used by SpringBoard only.             | No                                                                                                                                                                                                                                                                                                                                                                                                  |
| FigPlayerBlockingRunLoopMode | QuickTime related.                                                  | No                                                                                                                                                                                                                                                                                                                                                                                                  |

> just grab this from [official doc](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html)

To get even more info - we can check private mode's:

|                                                                                                                                                                                                                                               Mode                                                                                                                                                                                                                                               |                                                                                                              Purpose                                                                                                             | Part of common modes? |
|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------|
| kCFRunLoopDefaultMode                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | The default run loop mode, almost encompasses every sources. You should always add sources and timers to this mode if there's no special reasons. Can be accessed with the symbol kCFRunLoopDefaultModeand NSDefaultRunLoopMode. | Yes                   |
| NSTaskDeathCheckMode                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Used by NSTask to check if the task is still running.                                                                                                                                                                            | Yes                   |
| _kCFHostBlockingMode _kCFNetServiceMonitorBlockingMode _kCFNetServiceBrowserBlockingMode _kCFNetServiceBlockingMode _kCFStreamSocketReadPrivateMode _kCFStreamSocketCanReadPrivateMode _kCFStreamSocketWritePrivateMode _kCFStreamSocketCanWritePrivateMode _kCFStreamSocketSecurityClosePrivateMode _kCFStreamSocketBogusPrivateMode _kCFURLConnectionPrivateRunLoopMode _kProxySupportLoadingPacPrivateMode _kProxySupportSyncPACExecutionRunLoopMode _kCFStreamSocketSecurityClosePrivateMode | Various private run loop modes used by CFNetwork for blocking operations                                                                                                                                                         | No                    |
| UITrackingRunLoopMode                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | UI tracking.                                                                                                                                                                                                                     | Yes                   |
| GSEventReceiveRunLoopMode                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Receiving system events.                                                                                                                                                                                                         | No                    |
| com.apple.securityd.runloop                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | Communication with securityd. Used by SpringBoard only.                                                                                                                                                                          | No                    |
| FigPlayerBlockingRunLoopMode                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | QuickTime related.                                                                                                                                                                                                               | No                    |


### implementation

If we check implementation of Apple's EventLoop, we will find code that in general - `do while` cycle (as also described [here](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html#//apple_ref/doc/uid/10000057i-CH16-SW23)):

{% highlight swift %}
void CFRunLoopRun(void) {	/* DOES CALLOUT */
    int32_t result;
    do {
        result = CFRunLoopRunSpecific(CFRunLoopGetCurrent(), kCFRunLoopDefaultMode, 1.0e10, false);
        CHECK_FOR_FORK();
    } while (kCFRunLoopRunStopped != result && kCFRunLoopRunFinished != result);
}
{% endhighlight %}

> I grab only a small amount of code from CFRunLoop.c, but if u check it - u will be able to find all steps in the process that Apple mention in their doc:
> 
> 1. Notify observers that the run loop has been entered.
> * Notify observers that any ready timers are about to fire.
> * Notify observers that any input sources that are not port based are about to fire.
> * Fire any non-port-based input sources that are ready to fire.
> * If a port-based input source is ready and waiting to fire, process the event immediately. Go to step 9.
> * Notify observers that the thread is about to sleep.
> * Put the thread to sleep until one of the following events occurs:
>   - An event arrives for a port-based input source.
>   - A timer fires.
>   - The timeout value set for the run loop expires.
>   - The run loop is explicitly woken up.
> * Notify observers that the thread just woke up.
> * Process the pending event.
>   - If a user-defined timer is fired, process the timer event and restart the loop. Go to step 2.
>   - If an input source is fired, deliver the event.
>   - If the run loop was explicitly woken up but has not yet timed out, restart the loop. Go to step 2.
> * Notify observers that the run loop has exited.

If go deeper, we can find that Apple divided the whole system into 4 component:

1. Application layer
2. Application framework layer (Cocoa, CocoaTouch, etc)
3. Core framework layer
4. Darwin

If we go to Darwin and check how it works, we will find that everything is done using Mach's API, via messaging.

> Message definition from <mach/message.h> 
> 
> 
{% highlight swift %}
typedef struct {
  mach_msg_header_t header;
  mach_msg_body_t body;
} mach_msg_base_t;
>
typedef struct {
  mach_msg_bits_t msgh_bits;
  mach_msg_size_t msgh_size;
  mach_port_t msgh_remote_port;
  mach_port_t msgh_local_port;
  mach_port_name_t msgh_voucher_port;
  mach_msg_id_t msgh_id;
} mach_msg_header_t;
{% endhighlight %}

If talking about RunLoop - the core concept is using these messages mach_msg()

> from an above-mentioned sequence of work
> 
>   - An event arrives for a port-based input source.

So RunLoop keeps calls function to receive a message and if no-one responds, kernel push Thread into sleep, while new message becomes available or Thread ends up due to some reason.

### functionality

**autorelease pool** - after the start of the app, few observers registered within the main thread RunLoop. 

One is monitors RunLoop enter (`_objc_autoreleasePoolPush()`), used for creating atoreleasePool withi highest priority *-2147483647*, before anything else. 

Another observer monitors 2 more event - moment when thread ready to sleep (`_objc_autoreleasePoolPop()`) and moment when pool should be recreated (`_objc_autoreleasePoolPush()`). These observers come with the lowest priority - *2147483647* - to make sure that it's will be done after any operations.

> The code executed in the main thread is usually written in such things as event callbacks and Timer callbacks. These callbacks are wrapped around the AutoreleasePool created by RunLoop, so there is no memory leak and the developer does not have to display the Create Pool.

**system events** - one more functionality registered using *Version 1* source (`__IOHIDEventSystemClientQueueCallback()`). 

Events such as shake, touch, volume, screen lock generate [IOHIDEvent](https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-421.6/IOHIDFamily/IOHIDEventTypes.h.auto.html) and sent to **SpringBoard**. The registered observer then calls `_UIApplicationHandleEventQueue()` to proceed next steps within it.

**gestures** - as was mention above RunLoop responsible for processing gestures using `_UIApplicationHandleEventQueue()` call.

In general, Apple firstly registers pending gestures. Later all these pending gestures will proceed within one more observer on RunLoop `_UIGestureRecognizerUpdateObserver()`.

**interface update** - all UI related changes (layout, constraints, layer change, drawing, etc) firstly also marked as pending and send to a special observer-container. Later observer call `_ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv()` that iterate over all pending data.

{% highlight swift %}
_ZN2CA11Transaction17observer_callbackEP19__CFRunLoopObservermPv()
    QuartzCore:CA::Transaction::observer_callback:
        CA::Transaction::commit();
            CA::Context::commit_transaction();
                CA::Layer::layout_and_display_if_needed();
                    CA::Layer::layout_if_needed();
                        [CALayer layoutSublayers];
                            [UIView layoutSubviews];
                    CA::Layer::display_if_needed();
                        [CALayer display];
                            [UIView drawRect];
{% endhighlight %}
 
 > source [here](https://gist.github.com/zhangkn/3ac0767931c69b7831cdb20e61f93ed8) 

**timer** - as was mention above about `CFRunLoopTimerRef` - `NSTimer/Timer` it's toll-free bridged, so RunLoop control how it works also. `CADisplayLink` also use sources from RunLoop interface

> check [AsyncDisplayLink](https://github.com/facebookarchive/AsyncDisplayKit) from Facebook for alternative implementation - it\s allow to execute UI related task on non-main threads

**perform selector** - this is a family of functions from NSObject, under the hood it creates Timer and so also uses RunLoop. 

That's the reason why sometimes it may fail - this means that calling Thread does not have RunLoop.

**GCD** - RunLoop use `GCD` and `GCD` use RunLoop.

When `dispatch_async(dispatch_get_main_queue(), block)` is called, `libDispatch` will send a message to the main thread's RunLoop, RunLoop will wake up, get the block from the message, and callback `CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUEE` execute this block in (). But this logic is limited to dispatch to the main thread, and dispatch to other threads is still handled by libDispatch.

**networking** - on iOS there are few layers for work with network:

- [CFSocket](https://developer.apple.com/documentation/corefoundation/cfsocket-rg7)
- [CFNetwork](https://developer.apple.com/documentation/cfnetwork)
- [NSURLConnection](https://developer.apple.com/documentation/foundation/nsurlconnection)
- [NSURLSession](https://developer.apple.com/documentation/foundation/nsurlsession)

I believe we all saw that response from the network request come to us from a different thread. This means that underlying Thread uses RunLoop for messaging between different sources/observers/timers.

**swiftUI/Combine** - if you are already faced with this new technology u probably already create `Timer` or use `receive(on: options)` for various publishers.

{% highlight swift %}
let timer = Timer
	.publish(every: 1, on: .main, in: .common) // last param is RunLoop mode
	.autoconnect()
{% endhighlight %}

This means that RunLoop is deeply integrated even within new coding approaches provided by Apple.

> check [interesting thread](https://forums.swift.org/t/runloop-main-or-dispatchqueue-main-when-using-combine-scheduler/26635) on Swift forum about Runloop and DispatchQueue


### implementation

When we start the application now we know that the main Thread should auto initialize RunLoop. To check this we can simply check the backtrace of the stack during a simple app launch for iOS.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-11-29-runloop-in-depth/runLoop_action_1.png" alt="debug backtrace" width="750"/>
</div>

As u can see, the backtrace contains 

{% highlight swift %}
frame #22: 0x00007fff25acc950 FrontBoardServices`-[FBSSerialQueue _performNextFromRunLoopSource] + 22
frame #23: 0x00007fff2038c37a CoreFoundation`__CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__ + 17
frame #24: 0x00007fff2038c272 CoreFoundation`__CFRunLoopDoSource0 + 180
frame #25: 0x00007fff2038b7b6 CoreFoundation`__CFRunLoopDoSources0 + 346
frame #26: 0x00007fff20385f1f CoreFoundation`__CFRunLoopRun + 878
frame #27: 0x00007fff203856c6 CoreFoundation`CFRunLoopRunSpecific + 567
{% endhighlight %}

> note - latest call at the top

call to `CFRunLoopRunSpecific`. And next action - creating Source 0 / Version 0 and awaiting for next action. 

> to check this on your side - just put breakpoint on `viewDidLoad` during app launch for the very first `ViewController`.

If we check `CFRunLoop.c`, we can easily find this function

{% highlight swift %}
SInt32 CFRunLoopRunSpecific(CFRunLoopRef rl, CFStringRef modeName, CFTimeInterval seconds, Boolean returnAfterSourceHandled) {     /* DOES CALLOUT */
    CHECK_FOR_FORK();
    if (__CFRunLoopIsDeallocating(rl)) return kCFRunLoopRunFinished;
    __CFRunLoopLock(rl);
    CFRunLoopModeRef currentMode = __CFRunLoopFindMode(rl, modeName, false);
    if (NULL == currentMode || __CFRunLoopModeIsEmpty(rl, currentMode, rl->_currentMode)) {
	Boolean did = false;
	if (currentMode) __CFRunLoopModeUnlock(currentMode);
	__CFRunLoopUnlock(rl);
	return did ? kCFRunLoopRunHandledSource : kCFRunLoopRunFinished;
    }
    volatile _per_run_data *previousPerRun = __CFRunLoopPushPerRunData(rl);
    CFRunLoopModeRef previousMode = rl->_currentMode;
    rl->_currentMode = currentMode;
    int32_t result = kCFRunLoopRunFinished;

	if (currentMode->_observerMask & kCFRunLoopEntry ) __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopEntry);
	result = __CFRunLoopRun(rl, currentMode, seconds, returnAfterSourceHandled, previousMode);
	if (currentMode->_observerMask & kCFRunLoopExit ) __CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);

        __CFRunLoopModeUnlock(currentMode);
        __CFRunLoopPopPerRunData(rl, previousPerRun);
	rl->_currentMode = previousMode;
    __CFRunLoopUnlock(rl);
    return result;
}
{% endhighlight %}

We can easely inspect what's going on using source and backtrace, like:

{% highlight swift %}
result = __CFRunLoopRun(rl, currentMode, seconds, returnAfterSourceHandled, previousMode);
{% endhighlight %}

> frame #25: 0x00007fff2038b7b6 CoreFoundation`__CFRunLoopDoSources0 + 346

and so on.

Another option to check how RunLoop works - is to check backtrace for event starts.

To do so - just override for example `touchesBegan` and add a breakpoint. After entering the bt command in the print area, you can see the complete execution flow

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-11-29-runloop-in-depth/runLoop_action_2.png" alt="debug backtrace" width="750"/>
</div>

Viewed from bottom to top, the approximate flow of the relevant functions executed is:

* `UIApplicationMain`
* `CFRunLoopRunSpecific`
* `__CFRunLoopRun`
* `__CFRunLoopDoSources0`
* Finally,` touchesBegan:withEvent:`


How RunLoop works we can check in actual implementation of this function `static int32_t __CFRunLoopRun(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFTimeInterval seconds, Boolean stopAfterHandle, CFRunLoopModeRef previousMode)`. The implementation is complicated and require some time to understand, but we can use simlified version from [this source](https://www.programmersought.com/article/59784547646/):

{% highlight swift %}
static int32_t __CFRunLoopRun(CFRunLoopRef rl, CFRunLoopModeRef rlm, CFTimeInterval seconds, Boolean stopAfterHandle, CFRunLoopModeRef previousMode) 
{
    int32_t retVal = 0;
    do {
        // Notify Observers that Timers will be processed soon
        __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeTimers);
        // Notify Observers: Sources will be processed soon
        __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeSources);
        // Process Blocks
    	__CFRunLoopDoBlocks(rl, rlm);
        // Process Sources0
        if (__CFRunLoopDoSources0(rl, rlm, stopAfterHandle)) {
            // Process Blocks
            __CFRunLoopDoBlocks(rl, rlm);
	    }
        // Determine if there is Source1
        if (__CFRunLoopServiceMachPort(dispatchPort, &msg, sizeof(msg_buffer), &livePort, 0, &voucherState, NULL)) {
            // If there is Source1, jump to handle_msg
            goto handle_msg;
        }
        // Notify Observers: going to sleep soon
	    __CFRunLoopDoObservers(rl, rlm, kCFRunLoopBeforeWaiting);
    	__CFRunLoopSetSleeping(rl);
        // ⚠️sleep, wait for a message to wake up the thread
        __CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort, poll ? 0 : TIMEOUT_INFINITY, &voucherState, &voucherCopy);
    	__CFRunLoopUnsetSleeping(rl);
        // Notify Observers: Just wake up from sleep
	    __CFRunLoopDoObservers(rl, rlm, kCFRunLoopAfterWaiting);

handle_msg:
        if (Waking up by Timer) {
            // Processing Timer
            __CFRunLoopDoTimers(rl, rlm, mach_absolute_time())
        } else if (Waking up by GCD) {
            // Process GCD 
            __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
        } else {  // Waking up by Source1   
            // Process Source1
            __CFRunLoopDoSource1(rl, rlm, rls, msg, msg->msgh_size, &reply) || sourceHandledThisLoop;  
        }

       // Process Blocks
       __CFRunLoopDoBlocks(rl, rlm);
        
       // Set the return value
	   if (sourceHandledThisLoop && stopAfterHandle) {  // When entering the loop, the parameter returns after processing the event
	       retVal = kCFRunLoopRunHandledSource;
       } else if (timeout_context->termTSR < mach_absolute_time()) {  // Exceed the timeout period of the passed parameter mark
               retVal = kCFRunLoopRunTimedOut;
	   } else if (__CFRunLoopIsStopped(rl)) {  // Forced to stop by an external caller
               __CFRunLoopUnsetStopped(rl);
	       retVal = kCFRunLoopRunStopped;
	   } else if (rlm->_stopped) {  // Automatic stop
	       rlm->_stopped = false;
	       retVal = kCFRunLoopRunStopped;
	   } else if (__CFRunLoopModeIsEmpty(rl, rlm, previousMode)) {  // There is no Source0/Source1/Timer/Observer in mode
	       retVal = kCFRunLoopRunFinished;
	   }
    
    } while (0 == retVal);

    return retVal;
}
{% endhighlight %}

According to this, we can see that main functions are:

1. **`__CFRunLoopDoObservers`**: NotificationObserversWhat to do next
2. **`__CFRunLoopDoBlocks`**: ProcessingBlocks
3. **`__CFRunLoopDoSources0`**: processingSources0
4. **`__CFRunLoopDoSources1`**: ProcessingSources1
5. **`__CFRunLoopDoTimers`**: processingTimers
6. Handling GCD related:`dispatch_async(dispatch_get_main_queue(), ^{ });`
7. **`__CFRunLoopSetSleeping/__CFRunLoopUnsetSleeping`**: sleep waiting/end sleep
8. **`__CFRunLoopServiceMachPort -> mach-msg()`**: transfer control of the current thread

> check out the source link above if you would like to dive into more details, thus I just grab a few moments from that

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-11-29-runloop-in-depth/runLoop_scheme.pdf" alt="debug backtrace" width="850"/>
</div>

> here u can see all 6 functions that is called by CFRunLoop and defined in `CFRunLoop.c`:
> 
{% highlight swift %}
static void __CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__();
static void __CFRUNLOOP_IS_CALLING_OUT_TO_A_BLOCK__();
static void __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__();
static void __CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__();
static void __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE0_PERFORM_FUNCTION__();
static void __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__();
{% endhighlight %}

### practice (usage)

Well, for now, it was almost only theory (except few samples within `Timer`), how about practice? Where this all information can be used?. 

First of all, understanding how something works is very useful if u can be faced with some unexpected behavior or when u faced with the limitation of the existing implementation. But, to make this all information even more useful, let's review a few practical approaches.

**`RunLoop API.`**. 

The most used stuff:

{% highlight swift %}
let currentThreadRunloop = RunLoop.current
let mainRunLoop = RunLoop.main
let mode = currentThreadRunloop.currentMode
{% endhighlight %}

API to manipulate `RunLoop` is not very rich:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-11-29-runloop-in-depth/availableRunLoop_actions.png" alt="debug backtrace" width="250"/>
</div>

It's possible to run `RunLoop` in our custom mode, like:

{% highlight swift %}
let newRunLoop = RunLoop()
let customRunLoopMode = RunLoop.Mode("someMode")
newRunLoop.run(mode: customRunLoopMode, before: Date.distantFuture)
newRunLoop.run()
{% endhighlight %}

But note, that without a timer or port `RunLoop` will not run

{% highlight swift %}
newRunLoop.add(NSMachPort(), forMode: customRunLoopMode)
{% endhighlight %}

> A run loop must have at least one input source or timer to monitor. If one is not attached, the run loop exits immediately. (Apple)
> 
> `CFRunLoopAddSource(runLoop, runLoopSource, kCFRunLoopDefaultMode)`
> or
> `CFRunLoopAddTimer(runLoop, timer, kCFRunLoopCommonModes)`

Even with this code, nothing will work. Why? Check result of `RunLoop.init()` - it's return nil. `RunLoop` should be associated with `Thread`, and normally shouldn't be created manually. 

So, how to attach `RunLoop` to `Thread`?. Well, each we can create `Thread` object and access to `RunLoop.current` - if no `RunLoop` exist, the one will be autocreated for us:

{% highlight swift %}
let thread = Thread {
    let customRunLoop = RunLoop.current
}

thread.start()
{% endhighlight %}

As was mention previously, RunLoop should have at least one source or timer to monitor or it's will exit. How to add them?
We can use one of provided functions for this purpose:

* `CFFileDescriptorCreateRunLoopSource`
* `CFSocketCreateRunLoopSource`
* `CFMachPortCreateRunLoopSource`
* `CFMessagePortCreateRunLoopSource`

> Check [this post](https://rderik.com/blog/understanding-the-runloop-model-by-creating-a-basic-shell/) if you are interested in more details or [official doc](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html). And [this one](https://www.programmersought.com/article/8650683889/) about source/observer/timer


Add **`custom observer`** to RunLoop for heavy work on the main thread. 
this option allows us to execute some heavy computation out of the main thread but change UI when needed on the main thread.

So the idea is quite simple - we just create an observer on the thread which RunLoop we want to use, execute work, and remove the observer when works are done.

{% highlight swift %}
// RunLoop observer allows creating additional process on RunLoop that will be executed after all other processes ended
// so the process will be like this: runLoop (1) -> events (2) -> observer (3) -> runLoop (1) ....
// if this is main RunLoop, runLoop from the main thread, this observer can safely update UI then, without any freeze (if the process if expensive)

// create queue for executing expensive operation
let queue = DispatchQueue(label: "runLoop.sample", qos: .background)
var hasResult: Bool = false

// this function should be called whenever u need to do an expensive operation, then this will be executed asynchronously. This observer will be added to the current runLoop
func onTrigger() {
    
    print("Trigger")
    
    // A runloop observer is added to the current runloop to check for the availability of results. That observer will keep observing until a result is found and then dismiss itself.
    
    queue.asyncAfter(deadline: .now() + 10) {
        print("Work done")
        hasResult = true
    }
    
    let runLoopObserver = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 0, { (observer: CFRunLoopObserver?, activity: CFRunLoopActivity) in
        // execute work on separate thread and here check whenever this work is don, then remove observer
        if !hasResult {
            print("Checked Status - \(hasResult), Thread \(Thread.current)")
            return
        }
        CFRunLoopRemoveObserver(CFRunLoopGetCurrent(), observer, CFRunLoopMode.commonModes)
        print("Status - \(hasResult), Thread \(Thread.current)")
    })
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), runLoopObserver, CFRunLoopMode.commonModes)
}
{% endhighlight %}

> [RunLopp activities](https://developer.apple.com/documentation/corefoundation/cfrunloopactivity)

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-11-29-runloop-in-depth/demo_customObserver.gif" alt="debug backtrace" width="650"/>
</div>




## Resources

- [Apple open source](https://opensource.apple.com/)
- [RunLoop official doc](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Multithreading/RunLoopManagement/RunLoopManagement.html)
- [Principles of RunLoop](https://www.programmersought.com/article/2452697082/)
- [Understanding RunLoop](https://www.programmersought.com/article/59784547646/)
- [RunLoop and timers](https://www.programmersought.com/article/23684546929/)
- [NSTimer in RunLoop](https://www.programmersought.com/article/3798833564/)
- [Great article about RunLoop](http://yangchao0033.github.io/blog/2016/01/06/runloopshen-du-tan-jiu/)
- [CFRunLoopTimerRef](http://mirror.informatimago.com/next/developer.apple.com/documentation/CoreFoundation/Reference/CFRunLoopTimerRef/CFRunLoopTimerRef.pdf)
- [CFRunLoopSourceRef](http://mirror.informatimago.com/next/developer.apple.com/documentation/CoreFoundation/Reference/CFRunLoopSourceRef/CFRunLoopSourceRef.pdf)
- [CFRunLoopRef](http://mirror.informatimago.com/next/developer.apple.com/documentation/CoreFoundation/Reference/CFRunLoopRef/CFRunLoopRef.pdf)
- [CFRunLoopObserverRef](http://mirror.informatimago.com/next/developer.apple.com/documentation/CoreFoundation/Reference/CFRunLoopObserverRef/CFRunLoopObserverRef.pdf)
- [RunLoop modes](http://iphonedevwiki.net/index.php/CFRunLoop)
- [Understanding RunLoop model](https://rderik.com/blog/understanding-the-runloop-model-by-creating-a-basic-shell/)
- [Mach communication](https://nshipster.com/inter-process-communication/)
- [System call](https://en.wikipedia.org/wiki/System_call)
- [IOHIDFamily](http://iphonedevwiki.net/index.php/IOHIDFamily)
- [RunLopp activities](https://developer.apple.com/documentation/corefoundation/cfrunloopactivity)
- [Realm background Thread with custom RunLoop](https://academy.realm.io/posts/realm-notifications-on-background-threads-with-swift/)
- [RunLoop](https://bou.io/RunRunLoopRun.html)
- [Custom implementation of RunLoop](https://github.com/wuyunfeng/LightWeightRunLoop-A-Reactor-Style-NSRunLoop)
- [RunLoop with Threads](https://shinesolutions.com/2009/06/02/run-loops-vs-threads-in-cocoa/)