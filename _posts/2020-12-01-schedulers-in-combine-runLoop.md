---
layout: post
comments: true
title: "Schedulers in Combine: Part 2: RunLoop Scheduler"
categories: article
tags: [iOS, Combine]
excerpt_separator: <!--more-->
comments_id: 9

author:
- kyryl horbushko
- Lviv
---

Let's continue to review available `Schedulers` in `Combine`. This is the second article in the series and here we will review `RunLoop` as a `Scheduler`.
<!--more-->

Just to quick recap from prev. article - `Scheduler` it's a protocol the can be used to define how a certain amount of work can be done. 

Also, it's a good idea to remind ourselves about `RunLoop`, thus we will use it next. To do so, u can check my [article about `RunLoop`]({% post_url 2020-11-29-runloop-in-depth %}). Simply speaking `RunLoop` - is a mechanism that allows us to manage `inputSources` and timers using `Thread`.


**Related articles:**

* [Schedulers in Combine. Part 1: ImmediateScheduler]({% post_url 2020-11-26-schedulers-in-combine %})

## RunLoop Scheduler

`RunLoop` scheduler associated with concrete `Thread`, thus `Thread` works with `RunLoop` and may create it if needed for us.

The main functions of any `Scheduler` are to define how (using some options) and when (now or in future) code will be executed.

> `RunLoop+Scheduler` is openSource and [available here](https://github.com/apple/swift/blob/b5570a1aa923d18f5b7a28b06ea2a7424ba65e3b/stdlib/public/Darwin/Foundation/Schedulers+RunLoop.swift) for inspection.

So, let's try to use `RunLoop` as `Scheduler` and check **HOW** code can be executed. The simplest case - we just setup scheduler and run in using RunLoop as a Scheduler:

{% highlight swift %}
print("The start thread is \(Thread.current)")
[1, 2, 3, 4].publisher
    .print()
    // current mode - default
    .subscribe(on: RunLoop.current)
    .handleEvents(receiveRequest:  { (_) in
        print("Event handle at thread is \(Thread.current)")
    })
    // current mode - default for main runLoop
    .receive(on: RunLoop.main)
    .sink { (_) in
        print("Event recevide at thread is \(Thread.current)")
    }
    .store(in: &subscription)
{% endhighlight %}

So, the result is as we expected - everything up and running.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-01-schedulers-in-combine-runLoop/runLoop-scheduler_1.png" alt="runLoop-scheduler_simple" width="550"/>
</div>

Let's try to play a bit with process (make it more likely to real one) and change the code, so we do same but on different Thread:

{% highlight swift %}
let queue = DispatchQueue(label: "sample.scheduler.runLoop")
var subscription = Set<AnyCancellable>()

var loop: RunLoop?
queue.async {
    print("The start thread is \(Thread.current)")
    
    [1, 2, 3, 4].publisher
        .print()
        // current mode - default
        .subscribe(on: RunLoop.current)
        .handleEvents(receiveRequest:  { (_) in
            print("Event handle at thread is \(Thread.current)")
        })
        // current mode - default for main runLoop
        .receive(on: RunLoop.main)
        .sink { (_) in
            print("Event recevide at thread is \(Thread.current)")
        }
        .store(in: &subscription)
}
{% endhighlight %}

What we will receive? Let's run and check this:


<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-01-schedulers-in-combine-runLoop/runLoop-scheduler_2.png" alt="runLoop-scheduler_from_thread" width="550"/>
</div>

Well - we just see that process started and that it. Why? Remember I mentioned above that `RunLoop` created by `Thread` if needed, so maybe it does not exist? Let's check this by calling `RunLoop.current` within the selected queue.

{% highlight swift %}
// <CFRunLoop 0x600001810400 [0x7fff8002e7f0]>{wakeup port = 0xa003, stopped = false, ignoreWakeUps = true,
loop = RunLoop.current
{% endhighlight %}

Looks like `RunLoop` exists and created for us... What's wrong then? Maybe we should explicitly call `run`? 

But before we do so, how do we know that run executed successfully? Let's use API that let us know about this - `run(mode:before) -> Bool` - [return value](https://developer.apple.com/documentation/foundation/runloop/1411525-run) is *true if the run loop ran and processed an input source or if the specified timeout value was reached; otherwise, false if the run loop could not be started.*. 

Add this right before the publisher:

{% highlight swift %}
RunLoop.current.run(mode: .default, before: Date.distantFuture)
{% endhighlight %}

and nothing...  When we checked the result, we see **false**... So `RunLoop` is simple don't run and that the reason why we didn't see any output from the publisher that uses `RunLoop` as a `Scheduler`.

Why? Because *if no input sources or timers are attached to the run loop, this method exits immediately and returns false; otherwise, it returns after either the first input source is processed or limitDate is reached.* This means that calling this func is not enough - we should call it from the right place. So let's move it to the very end - right after we configure publisher and event receiving. 

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-01-schedulers-in-combine-runLoop/runLoop-scheduler_3.png" alt="runLoop-scheduler_from_thread_success" width="550"/>
</div>

Finally, all works as expected. Now we "informed" `RunLoop` from selected Thread that it has something to do, and it does. We can even change `.receive(on: RunLoop.main)` to `.receive(on: RunLoop.current)`, and instead

{% highlight swift %}
Event recevide at thread is <NSThread: 0x600000af0780>{number = 1, name = main}
{% endhighlight %}

we will get somethig like (number of the `Thread` may be different on your side):

{% highlight swift %}
Event recevide at thread is <NSThread: 0x600001921400>{number = 7, name = (null)}
{% endhighlight %}

So - everything works as we expect. But there is one more point that I would like to clarify - `RunLoop mode`. 

In the call above we used `default` mode - mode usage is a bit tricky and we used as it visible from the name - the `default` one. 

Try to change it to `common`. Yep, nothing works - it's because `RunLoop` can be only in **ONE** mode, and by default, it's in `default` mode. 

> check more about `RunLoop` and `modes` in my other [article]({% post_url 2020-11-29-runloop-in-depth %})

We already discuss a bit the `RunLoop` mode and how it works. But here is one more point that needs to be mentioned - *`UIKit` and `AppKit` run the `RunLoop` in the `default` mode when idle. But, in particular, when tracking a user interaction (like a touch or a mouse button press), they run the `RunLoop` in a different, non-default mode. So a `Combine` pipeline that uses `receive(on: RunLoop.main)` will not deliver signals while the user is touching or dragging.*

> Thanks Rob Mayoff for his comments on [Swift forum](https://forums.swift.org/t/runloop-main-or-dispatchqueue-main-when-using-combine-scheduler/26635/27) and well known [StackOverflow](https://stackoverflow.com/a/61107764)

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-01-schedulers-in-combine-runLoop/escimo_comment.png" alt="excimos comments" width="650"/>
</div>

> [source](https://forums.swift.org/t/runloop-main-or-dispatchqueue-main-when-using-combine-scheduler/26635/28)

Also, it's good to know how RunLoop Scheduler executes the code, and according to the source:

{% highlight swift %}
public func schedule(options: SchedulerOptions?,
                     _ action: @escaping () -> Void) {
    self.perform(action)
}
{% endhighlight %}

as u can see here `perfrom` is called an action that will be executed in the next iteration or `RunLoop` loop, so almost immediately.

> [source](https://github.com/apple/swift/blob/b5570a1aa923d18f5b7a28b06ea2a7424ba65e3b/stdlib/public/Darwin/Foundation/Schedulers%2BRunLoop.swift#L147)


Now it's time to check another art of responsibilities required by Scheduler and related to **WHEN** code should be executed.

As we discussed previously Scheduler may configure execution work either now either in the future. And For this purpose used `SchedulerTimeType`. 

> Not all Scheduler can execute work in future - for example, `ImmediateScheduler` can't

If we check source code or `API` for `RunLoop` scheduler, we can find that `SchedulerTimeTipe` for `RunLoop` works with `Date`:

{% highlight swift %}
public struct SchedulerTimeType: Strideable, Codable, Hashable {
    /// The date represented by this type.
    public var date: Date
    
    /// Initializes a run loop scheduler time with the given date.
    ///
    /// - Parameter date: The date to represent.
    public init(_ date: Date) {
        self.date = date
    }
   ...
{% endhighlight %}
   
> [source](https://github.com/apple/swift/blob/b5570a1aa923d18f5b7a28b06ea2a7424ba65e3b/stdlib/public/Darwin/Foundation/Schedulers%2BRunLoop.swift#L22)

This makes it possible to easily configure any future time. But before testing it we need to check one more type that represents SchedulerOptions - `RunLoop.SchedulerOptions`:

{% highlight swift %}
/// Options that affect the operation of the run loop scheduler.
public struct SchedulerOptions { }
{% endhighlight %}

Yep, there is no option available. And if we check source code, this param is never used also, so just ignored:


<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-01-schedulers-in-combine-runLoop/runloop-scheduler-options.png" alt="runloop-scheduler-options" width="450"/>
</div>

Now we can test how this work:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-01-schedulers-in-combine-runLoop/runLoop_scheduler.png" alt="runLoop_scheduler" width="450"/>
</div>

> u can replace `RunLoop.current` to `RunLoop.main` and skip run call, or just ommit using `queue.async`


## pitfalls

* Make sure that `RunLoop` you are using is running and in expected mode.
* `receive(on: RunLoop.main)` will not deliver signals while the user is touching or dragging.
* there is a possible minimal delay while `perform` executed (usually not important)
* `RunLoop` is not Thread-safe - so be careful when using it.
* avoid `RunLoop.current` if u not sure in usage and instead use `RunLoop.main` or `DispatchQueue`

## usage example

* `Timers` require `RunLoop` to run on and specific mode, so without RunLoop Timer publisher can't be created:
{% highlight swift %}
Timer.publish(every: 1.0, on: RunLoop.main, in: .common)
{% endhighlight %}

* Gesture's can't be processed without `RunLoop`
* Good sample of usage may be backgroundLogger - when u need to log everything u can use your own `Thread` and `RunLoop` for this. Then logging will be done efficiently. [Sample](https://academy.realm.io/posts/realm-notifications-on-background-threads-with-swift/)
* downloading a lot of images in some Feed - here u can also use RunLoop in default mode - check [AliExpress app](https://apps.apple.com/us/app/aliexpress-shopping-app/id436672029): when u scroll the feed, images are not loading, but when u stop, they are.
* check [AsyncDisplayLink](https://github.com/facebookarchive/AsyncDisplayKit) - another good sample

In the next part, I will cover `DispatchQueue Scheduler`.

[download source playground]({% link assets/posts/images/2020-12-01-schedulers-in-combine-runLoop/playground/runLoop_scheduler.playground.zip %})


Related articles:

* [Schedulers in Combine. Part 1: ImmediateScheduler]({% post_url 2020-11-26-schedulers-in-combine %})
