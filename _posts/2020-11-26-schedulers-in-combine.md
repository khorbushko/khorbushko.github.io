---
layout: post
comments: true
title: "Schedulers in Combine. Part 1: ImmediateScheduler"
categories: article
tags: [iOS, Combine]
excerpt_separator: <!--more-->
comments_id: 6

author:
- kyryl horbushko
- Lviv
---

When we start dealing with `Combine`, soon we realize that threads and task managing between them are essential. Luckily for us, Combine has a build-in realization of this routine called `Scheduler` - *" a protocol that defines when and how to execute a closure"* (Apple).

So today I would like to tell you about `Scheduler` and how to use it. 

I'm going to cover all schedulers for `Combine` in this series.
<!--more-->

In this article we will cover next:

- introduction
- main functionality
- ImmediateScheduler

## intro

First aff all - is usage, thanks to Apple, it's can be done within minimal work from our side - only one call for both subscription and for receiving event:

* [subscribe(on:options:)](https://developer.apple.com/documentation/combine/publisher/subscribe(on:options:))
* [receive(on:options:)](https://developer.apple.com/documentation/combine/publisher/receive(on:options:))

Scheduler exist just to simplify everything. And instead of doing something like:

{% highlight swift %}
sink {
	DispatchQueue.main.async {
	   // do something with data
	}
}
{% endhighlight %}

we can simple use it like this:

{% highlight swift %}
publisher
	.receive(on: DispatchQueue.main)
	.sink {
		// do something with data
	}
{% endhighlight %}

So, how about `Scheduler` itself? `Scheduler` is simply an abstraction that helps you to define how and when performing some amount of work. 

So as we all can imagine there are a lot of work types and purposes, and keeping this in mind `Combine` provide for us a few predefined types of `Schedulers` implementation via different types. Here they are:

- `ImmediateScheduler`
- `RunLoop`
- `DispatchQueue` 
- `OperationQueue`

If this is not enough, we can also provide your implementation of this abstraction and handle this in your way. 

So, as I mentioned before, usage is quite simple and limited to a few functions within 2 main parameters - the type of `Scheduler` and the options. 

Let's dive into details of each `Scheduler` and review the pros/cons of each one and also check their use cases.

## Scheduler

Before we review each type, it's good to understand what this abstraction can do for us. To do so, we can simply inspect the `Scheduler` type, and as result, we will find that that using abstraction we can:

- execute code immediately
- schedule code execution in future
- add options to control how they execute the actions passed to them

Helper types for delivering functionality above are:

* [SchedulerTimeType](https://developer.apple.com/documentation/combine/scheduler/schedulertimetype) (Describes an instant in time for this scheduler)
* [SchedulerOptions](https://developer.apple.com/documentation/combine/scheduler/scheduleroptions) (A type that defines options accepted by the scheduler)

So, so far so good :]. Moving forward.


## ImmediateScheduler

Let’s start with the simplest one - `ImmediateScheduler`. This type of scheduler as u can see from the name used for *immediate* execution. 

If u check [official doc](https://developer.apple.com/documentation/combine/immediatescheduler), u can find next - *"A scheduler for performing synchronous actions"*. So, simply saying it's just a sync operation on the same thread where u create some task. Indeed this is the default scheduler.

This is quite a good option in case u want to execute the operation as is, without any delay (in the future).

<div style="text-align:center">
<img src="2020-11-26-schedulers-in-combine/immediate_sample_1.png" alt="preview_1" width="550"/>
</div>

U should also note, that if u even try to schedule execution on a future date - this scheduler will ignore it and execute your code immediately. If u check the `ImmediateScheduler.SchedulerTimeType` - parameter that can be used to schedule some work in the future, u can see that this struct has no available initialization, so it's simply blocking us from performing and future work within it. So u can't use any `schedule(after:)` variant from the `Schedule` protocol.

<div style="text-align:center">
<img src="2020-11-26-schedulers-in-combine/immediate_sample_2.png" alt="preview_1" width="550"/>
</div>

> Try to create instance of this struct like `ImmediateScheduler.SchedulerTimeType()` - and u will get error from compiler - *'ImmediateScheduler.SchedulerTimeType' cannot be constructed because it has no accessible initializers*

But, we can check available API and may found:

{% highlight swift %}
/// The immediate scheduler’s definition of the current moment in time.
public var now: ImmediateScheduler.SchedulerTimeType { get }
{% endhighlight %}

This means that in theory, we can set up some future date using `now` that is `ImmediateScheduler.SchedulerTimeType` and some of protocol required functions that `SchedulerTimeType` **should** implement, for example:

{% highlight swift %}
/// Returns the distance to another immediate scheduler time; this distance is always `0` in the context of an immediate scheduler.
///
/// - Parameter other: The other scheduler time.
/// - Returns: `0`, as a `Stride`.
public func distance(to other: ImmediateScheduler.SchedulerTimeType) -> ImmediateScheduler.SchedulerTimeType.Stride
{% endhighlight %}
Let's test this. Firstly let's check normal behaviour:

{% highlight swift %}
let queue = DispatchQueue(label: "sample.queue")
var subscriptions = Set<AnyCancellable>()

queue.async {
    print("Create on \(Thread.current)")
    
    let source = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .scan(0, { counter, _  in counter + 1})
    
    source
        .receive(on: ImmediateScheduler.shared)
        .sink { (value) in
            print("The value is \(value) in \(Thread.current) at \(Date())")
        }
        .store(in: &subscriptions)
}
{% endhighlight %}

<div style="text-align:center">
<img src="2020-11-26-schedulers-in-combine/immediate_normal.png" alt="preview_1" width="550"/>
</div>

In the log, we can see that events are coming as expected.

Well let's check now that we can't schedule ImmediateScheduler for future, as it mention in docs:

{% highlight swift %}
queue.async {
    print("Create on \(Thread.current)")
    
    let source = Timer
        .publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .scan(0, { counter, _  in counter + 1})
    
    subscription = source
        .receive(on: ImmediateScheduler.shared)
        .sink { (value) in
            print("The value is \(value) in \(Thread.current) at \(Date())")
        }
    
    ImmediateScheduler.shared
        .schedule(
                  after: ImmediateScheduler.shared.now
                    .advanced(by: ImmediateScheduler.SchedulerTimeType.Stride(Int.max)
                    )
        ) {
        subscription?.cancel()
        print("Canceled at \(Date())")
    }
}
{% endhighlight %}

And result is:

<div style="text-align:center">
<img src="2020-11-26-schedulers-in-combine/immediate_future cancel.png" alt="preview_1" width="550"/>
</div>

Here u can see that **cancel** operation is ***immediate***. As expected. It's a bit strange for me, that we didn't receive any warning or assertion from Apple, but ok, this is can be improved in the future, and we already know it.

One more moment to know - this scheduler haven't any options to use, and if we check API, we will find that 

{% highlight swift %}
// ImmediateScheduler.SchedulerOptions
typealias SchedulerOptions = Never
{% endhighlight %}

In next part i will cover `RunLoop Scheduler`.