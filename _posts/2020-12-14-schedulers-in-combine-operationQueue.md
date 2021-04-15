---
layout: post
comments: true
title: "Schedulers in Combine: Part 4: OperationQueue Scheduler"
categories: article
tags: [iOS, Combine]
excerpt_separator: <!--more-->
comments_id: 13

author:
- kyryl horbushko
- Lviv
---

In this article we review last, but not least (in the list of available schedulers for `Combine` framework), scheduler - `OperationQueue`.

As u remember from previous articles, `Scheduler` it's just a protocol that requires from type define **WHEN** and **HOW** execute a selected task. 
<!--more-->

`OperationQueue` functionality and purpose - it's another quite interesting mechanism. I will not cover the full possibilities of it in this article, instead, u can jump [here](https://developer.apple.com/documentation/foundation/operationqueue) to refresh the knowledge about it.  

In 2 words, `OperationQueue` it's a queue that controls how operations can be executed.

> An operation queue executes its queued Operation objects based on their priority and readiness. After being added to an operation queue, the operation remains in its queue until it reports that it is finished with its task. You can’t directly remove an operation from a queue after it has been added.

It's also good to know, that under the hood `OperationQueue` use `GCD`, but provide an additional level of control for each task that can be executed.

**Related articles:**

* [Schedulers in Combine. Part 1: ImmediateScheduler]({% post_url 2020-11-26-schedulers-in-combine %})
* [Schedulers in Combine. Part 2: RunLoop Scheduler]({% post_url 2020-12-01-schedulers-in-combine-runLoop %})
* [Schedulers in Combine. Part 3: DispatchQueue Scheduler]({% post_url 2020-12-05-schedulers-in-combine-DispatchQueue %})
* Schedulers in Combine. Part 4: OperationQueue Scheduler

## OperationQueue Scheduler

As we did in previous articles from this series, we start to review `OperationQueue` as a Scheduler from the checking **HOW** approach. And this can be done within simple code:

{% highlight swift %}
var subscription = Set<AnyCancellable>()

let operation = OperationQueue()
let publisher = [1,2,3,4,5].publisher

publisher
    .receive(on: operation)
    .sink { (value) in
        print("Recevied value \(value) on \(Thread.current)")
    }
    .store(in: &subscription)
{% endhighlight %}

If u expect to receive output like:

> Recevied value 1 on <NSThread: 0x600000b01000>{number = 1, name = (null)}
> 
> Recevied value 2 on <NSThread: 0x600000b00b80>{number = 1, name = (null)}
> 
> Recevied value 3 on <NSThread: 0x600000b1a140>{number = 1, name = (null)}
> 
> Recevied value 4 on <NSThread: 0x600000b16c40>{number = 1, name = (null)}
> 
> Recevied value 5 on <NSThread: 0x600000b04b40>{number = 1, name = (null)}

u will be surprised. The real output is like

> Recevied value 2 on <NSThread: 0x600000b01000>{number = 5, name = (null)}
> 
> Recevied value 5 on <NSThread: 0x600000b00b80>{number = 3, name = (null)}
> 
> Recevied value 4 on <NSThread: 0x600000b1a140>{number = 8, name = (null)}
> 
> Recevied value 3 on <NSThread: 0x600000b16c40>{number = 9, name = (null)}
> 
> Recevied value 1 on <NSThread: 0x600000b04b40>{number = 6, name = (null)}

First of all, u may notice, that values come in *different order*. Also - on *different `Threads`*.

Why? As was mention above, `OperationQueue` works under `GCD`, and so, to deliver these values it may use different `Threads`, so the order is not guaranteed at all.

If u want to check how it's work under the hood, then we may refer to [open-source code](https://github.com/apple/swift/blob/b5570a1aa923d18f5b7a28b06ea2a7424ba65e3b/stdlib/public/Darwin/Foundation/Schedulers%2BOperationQueue.swift#L181), and we may found:

{% highlight swift %}
public func schedule(options: OperationQueue.SchedulerOptions?,
                     _ action: @escaping () -> Void) {
    let op = BlockOperation(block: action)
    addOperation(op)
}
{% endhighlight %}

As u can see, [`BlockOperation`](https://developer.apple.com/documentation/foundation/blockoperation) is used. This means that any of the available `global()` `Thread` is used. And this explains the output.

> definition:
> 
{% highlight swift %}
@available(iOS 4.0, *)
class BlockOperation : Operation {    
    public convenience init(block: @escaping () -> Void)
    open func addExecutionBlock(_ block: @escaping () -> Void)
    open var executionBlocks: [@convention(block) () -> Void] { get }
}
{% endhighlight %}

But remember, `OperationQueue` provide few additional points of control in comparison to `GCD`. One of them - [`maxConcurrentOperationCount`](https://developer.apple.com/documentation/foundation/nsoperationqueue/1414982-maxconcurrentoperationcount) (allow to determine max task executed in concurency).

> The default maximum number of operations to be executed concurrently in a queue equal to maxPossibleCount. If u print this value (default) u will see `-1`, that's indicated as much as possible.
>
{% highlight swift %}
print(operation.maxConcurrentOperationCount) // -1
{% endhighlight %}

To fix `random` execution of tasks we may modify operation by adding 

{% highlight swift %}
operation.maxConcurrentOperationCount = 1
{% endhighlight %}

Output now - is ordered, as we want, but note the `Thread`:

> Recevied value 1 on <NSThread: 0x6000026f0d40>{number = 5, name = (null)}
> 
> Recevied value 2 on <NSThread: 0x6000026f0d40>{number = 5, name = (null)}
> 
> Recevied value 3 on <NSThread: 0x6000026f0d40>{number = 5, name = (null)}
> 
> Recevied value 4 on <NSThread: 0x6000026f9c00>{number = 3, name = (null)}
> 
> Recevied value 5 on <NSThread: 0x6000026f9c00>{number = 3, name = (null)}

So, even we got an order, but the `Thread` is still - any available as before. To get the **`main`** `Thread` using `OperationQueue` we may do next:

{% highlight swift %}
.receive(on: OperationQueue.main)
{% endhighlight %}

or even

{% highlight swift %}
operation.underlyingQueue = .main
{% endhighlight %}

The result will be ordered and on the `main Thread`.

We also can modify other properties of `OperationQueue` such as `qualityOfService` or `underlyingQueue`.

Another moment that we should think about when using `OperationQueue` as a scheduler is the `priority` of operations.

Priority defined as:

{% highlight swift %}
extension Operation {
    public enum QueuePriority : Int {
        case veryLow = -8
        case low = -4
        case normal = 0
        case high = 4
        case veryHigh = 8
    }
}
{% endhighlight %}

The **default** value is `normal = 0`. This means, that if u have `OperationQueue` with the operation of highest priority and try to publish some other values - the result may surprise u.

To test this approach, let's create a custom AsyncOperation that may take some time to process. To do so we may create something like this:

{% highlight swift %}
public class AsyncOperation: Operation {
    
    // MARK: - AsyncOperation
    
    public enum State: String {
        
        case ready
        case executing
        case finished
        
        fileprivate var keyPath: String {
            return "is" + rawValue.capitalized
        }
    }
    
    public var state = State.ready {
        willSet {
            willChangeValue(forKey: newValue.keyPath)
            willChangeValue(forKey: state.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
}

public extension AsyncOperation {
    
    // MARK: - AsyncOperation+Addition
    
    override var isReady: Bool {
        return super.isReady && state == .ready
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    override func start() {
        if isFinished {
            return
        }
        
        if isCancelled {
            state = .finished
            return
        }
        
        main()
        state = .executing
    }
    
    override func cancel() {
        super.cancel()
        state = .finished
    }
    
    override func main() {
        preconditionFailure("Subclasses must implement `main`."
	 }
}

// subclass 
final class AsyncLongAndHightPriorityOperation: AsyncOperation {
    
    override func main() {
        print("started heavy operation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.state = .finished
            print("finished heavy operation")
        }
    }
}
{% endhighlight %}

> better AsyncOperation can be found [here](https://gist.github.com/ole/5034ce19c62d248018581b1db0eabb2b)

{% highlight swift %}
let heavyOperation = AsyncLongAndHightPriorityOperation()
heavyOperation.queuePriority = .high

let queue = OperationQueue()
queue.maxConcurrentOperationCount = 1

print("Started at date \(Date())")
queue.addOperation(heavyOperation)

publisher
    .receive(on: queue)
    .sink(receiveCompletion: { (completion) in
        print("Recevied completion \(completion) on \(Thread.current), date \(Date())")
    }, receiveValue: { (value) in
        print("Recevied value \(value) on \(Thread.current), date \(Date())")
    })
    .store(in: &subscription)
{% endhighlight %}

The result - as u may expect has a delay between output:


> Started at date 2020-12-13 10:39:58 +0000
> 
> started heavy operation
> 
> Recevied value 1 on <NSThread: 0x600003f38dc0>{number = 3, name = (null)}, date 2020-12-13 10:40:02 +0000
> 
> finished the heavy operation
> 
> Recevied value 2 on <NSThread: 0x600003f3cb40>{number = 5, name = (null)}, date 2020-12-13 10:40:02 +0000
> 
> Recevied value 3 on <NSThread: 0x600003f38dc0>{number = 3, name = (null)}, date 2020-12-13 10:40:02 +0000
> 
> Recevied value 4 on <NSThread: 0x600003f0d100>{number = 7, name = (null)}, date 2020-12-13 10:40:02 +0000
> 
> Recevied value 5 on <NSThread: 0x600003f0d100>{number = 7, name = (null)}, date 2020-12-13 10:40:02 +0000
> 
> Recevied completion finished on <NSThread: 0x600003f0d100>{number = 7, name = (null)}, date 2020-12-13 10:40:02 +0000

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-14-schedulers-in-combine-operationQueue/OperationQueue_test1.png" alt="OperationQueue_test1" width="550"/>
</div>

Think about it in cases when u haven't specified `queue.maxConcurrentOperationCount = 1` or if u set non-concurrent target queue or even if u use `OperationQueue.main`. The result may surprise u. 

Such additional operation may even affect `sink` output. Try to do next:

{% highlight swift %}
let heavyOperation = AsyncLongAndHightPriorityOperation()
heavyOperation.queuePriority = .high

let queue = OperationQueue()
//queue.maxConcurrentOperationCount = 1 // <- comment this

print("Started at date \(Date())")
queue.addOperation(heavyOperation)

publisher
    .receive(on: queue)
    .sink(receiveCompletion: { (completion) in
        print("Recevied completion \(completion) on \(Thread.current), date \(Date())")
    }, receiveValue: { (value) in
        print("Recevied value \(value) on \(Thread.current), date \(Date())")
    })
    .store(in: &subscription)
{% endhighlight %}

Output shows us, that few values are not received at all.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-14-schedulers-in-combine-operationQueue/OperationQueue_test2.png" alt="OperationQueue_test2" width="550"/>
</div>

To resolve this, we may do next:

{% highlight swift %}
    .subscribe(on: queue)
    .receive(on: OperationQueue.main)
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-14-schedulers-in-combine-operationQueue/OperationQueue_test3.png" alt="OperationQueue_test3" width="550"/>
</div>

As u can see, `OperationQueue` provides for us additional options of controlling task executing, but be careful within it and make sure u correctly configure `OperationQueue`.

> by default `OperationQueue` execute task concurently

## SchedulerOptions

If we check API, we may found that these options contain nothing, so nothing here to do.

{% highlight swift %}
/// Options that affect the operation of the operation queue scheduler.
public struct SchedulerOptions { }
{% endhighlight %}

## SchedulerTimeType

`SchedulerTimeType` is `Date`:

{% highlight swift %}
public struct SchedulerTimeType: Strideable, Codable, Hashable {
    /// The date represented by this type.
    public var date: Date
    
    /// Initializes an operation queue scheduler time with the given date.
    ///
    /// - Parameter date: The date to represent.
    public init(_ date: Date) {
        self.date = date
    }
    
    ...
}
{% endhighlight %}

> [source](https://github.com/apple/swift/blob/b5570a1aa923d18f5b7a28b06ea2a7424ba65e3b/stdlib/public/Darwin/Foundation/Schedulers%2BOperationQueue.swift#L22)

To setup future work we may do as we alredy done within other Schedulers:

{% highlight swift %}
let source = Timer
    .publish(every: 1, on: .main, in: .common)
    .autoconnect()
    .scan(0, { counter, _  in
        let value = counter + 1
        print("tick ", value)
        return value
    })

source
    .receive(on: DispatchQueue.main)
    .sink { (value) in
        print("The value is \(value) in \(Thread.current) at \(Date())")
    }
    .store(in: &subscription)
    
operation
    .schedule(
        after: .init(Date(timeIntervalSinceNow: 4.5)),
        tolerance: .seconds(1),
        options: nil
    ) {
        print("cancelation")
        subscription.removeAll()
    }
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2020-12-14-schedulers-in-combine-operationQueue/operationQueue_future_test.png" alt="operationQueue_future_test" width="550"/>
</div>

Under the hood, schedule use serial queue and execute every task using [`asyncAfter(deadline:)`](https://github.com/apple/swift/blob/b5570a1aa923d18f5b7a28b06ea2a7424ba65e3b/stdlib/public/Darwin/Foundation/Schedulers%2BOperationQueue.swift#L155):

{% highlight swift %}
init(_ action: @escaping() -> Void, after: OperationQueue.SchedulerTimeType) {
    self.action = action
    readyFromAfter = false
    super.init()
    let deadline = DispatchTime.now() + after.date.timeIntervalSinceNow            
    DelayReadyOperation.readySchedulingQueue.asyncAfter(deadline: deadline) { [weak self] in
        self?.becomeReady()
    }
}
{% endhighlight %}

> note [the difference `asynchAfter(deadline:)` and `asynchAfter(wallDeadline:)`](https://developer.apple.com/forums/thread/49361)

## Pitfalls

* Be careful when use OperationQueue - make sure it's available for dedicated tasks
* Remember that every task by default will be executed async concurrently on available `Threads`, so the order is not guaranteed

[download source playground]({% link assets/posts/images/2020-12-14-schedulers-in-combine-operationQueue/source/operationQueue_scheduler.playground.zip %})


**Related articles:**

* [Schedulers in Combine. Part 1: ImmediateScheduler]({% post_url 2020-11-26-schedulers-in-combine %})
* [Schedulers in Combine. Part 2: RunLoop Scheduler]({% post_url 2020-12-01-schedulers-in-combine-runLoop %})
* [Schedulers in Combine. Part 3: DispatchQueue Scheduler]({% post_url 2020-12-05-schedulers-in-combine-DispatchQueue %})
* Schedulers in Combine. Part 4: OperationQueue Scheduler