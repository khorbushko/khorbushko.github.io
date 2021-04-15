---
layout: post
comments: true
title: "Powerful trio"
categories: article
tags: [iOS, Swift, Combine, Publisher, Subscriber]
excerpt_separator: <!--more-->
comments_id: 28

author:
- kyryl horbushko
- Lviv
---

`Combine` brings in developer's life a lot of nice additions and make it's better. Using publishers improve data flow and allow us produce and transform input into required data representations. This save for us a lot of time and effort.
<!--more-->

I was wondering how this `Publisher`'s mechanism works in Combine, so i started from simplest thing - investigating key-components - `Publisher`, `Subscription` and `Subscribers`.

## Powerful trio

To get idea what's going on, let's inspect each components in details.

Looking forward, here is small scheme, that demonstrate this trio workflow:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-09-powerful-trio/trio.pdf" alt="trio" width="550"/>
</div>
<br>

### Subscriber

[`Subscriber`](https://developer.apple.com/documentation/combine/subscriber) - is a very first item that should be checked, thus it's, as mention in official doc, *"a protocol that declares a type that can receive input from a publisher"*.

So this component describe requirements for types, that can get information from source. If we check API, we can found a protocol declaration like following one:

{% highlight swift %}
public protocol Subscriber: CustomCombineIdentifierConvertible {
    associatedtype Input
    associatedtype Failure: Error

    func receive(subscription: Subscription)
    func receive(_ input: Self.Input) -> Subscribers.Demand
    func receive(completion: Subscribers.Completion<Self.Failure>)
}
{% endhighlight %}

Here, we can see few functions that should be available for such type.

As u can already guess, start points - is creating a `Subscriber`. You connect a subscriber to a publisher by calling the publisher’s [`subscribe(_:)`](https://developer.apple.com/documentation/combine/publisher/subscribe(_:)-4u8kn) method. Then publisher notify `Subscriber`, that he receive subscription by calling [`receive(subscription:)`](https://developer.apple.com/documentation/combine/subscriber/receive(subscription:)). Next step should be done by `Subscriber` - he ask in subscription some values, and subscription post them to publisher, which notify `Subscriber` about result by calling [`receive(_:)`](https://developer.apple.com/documentation/combine/subscriber/receive(_:)). 

Last, but not least - when there is nothing more to do or some error occured -  publisher calls [`receive(completion:)`](https://developer.apple.com/documentation/combine/subscriber/receive(completion:)).

We can show this process on earlier provided diagram as next:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-09-powerful-trio/subscriber-life.pdf" alt="subscriber-life" width="550"/>
</div>
<br>


### Publisher

Next one in our list - [`Publisher`](https://developer.apple.com/documentation/combine/publisher) - *"a type can transmit a sequence of values over time"*.

This type specially created for value transmitting to subsciber and has next requirements:

{% highlight swift %}
public protocol Publisher {

  associatedtype Output
  associatedtype Failure : Error

  func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input
}
{% endhighlight %}

As u can see, there is only 1 method - [`receive(subscriber:)`](https://developer.apple.com/documentation/combine/publisher/receive(subscriber:)). After publisher receive it's subscriber, he become able to call all methods from `Subscriber`, defined by it's contract.

Again, we can display this on our diagram as following:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-09-powerful-trio/publisher-life.pdf" alt="publisher-life" width="550"/>
</div>
<br>

### Subscription

[`Subscription`](https://developer.apple.com/documentation/combine/subscription) - last component, that combine previous components together. 

We may think about - as a bridge between `Publisher` and `Subscriber`.

Protocol for `Subscription`:

{% highlight swift %}
public protocol Subscription : Cancellable, CustomCombineIdentifierConvertible {
  func request(_ demand: Subscribers.Demand)
}
{% endhighlight %}

All that subscription can do - accept request to provide data using `request(_:)` method. Another option, that u can observe by looking at adopted protocols is `cancel`. Yes, u have an option to cancel u'r previous request.

And, as and before, here is diagram for `Subscription`:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-09-powerful-trio/subscription-life.pdf" alt="subscription-life" width="550"/>
</div>
<br>

## Practice

To make things fully understandable just theory is not good enough. Let's craft our own `Publisher` that simulate well-known [`map(_:)`](https://developer.apple.com/documentation/combine/publishers/merge/map(_:)-6v8fv) function.

According to Apple doc - this function *"transforms all elements from the upstream publisher with a provided closure"*. So, we can easelly transform our components in to alternative represenatation without changing data stream. Great.

> Before we go to next steps, it's good to understand meaning of `Upstream` and `Downstream` concepts. 
> 
> `Downstream` - it's an item, that add's value to another or depends on it in any other way, and `Upstream` - vise versa.
> 
> There is a good article about it available [here](https://reflectoring.io/upstream-downstream/)

### Custom Publisher

Let's start from `Publisher`, because we need to define our types and required input-output values.

To do so, we can place our publisher in an extension to `Publishers` (as it done with other publishers) - let's name it `Mapper`. 
 
> Note `Publishers` - `s` at the end, not `Publisher`

We also shoud define type of input and output, and transform closure (to allow data transformation). And last step - define `subscribe(:)` method, where we should subscribe our custom `Subscriber`.

All together it looks like next:

{% highlight swift %}
extension Publishers {
    public struct Mapper<Upstream: Publisher, Output>: Publisher {
        public typealias Failure = Upstream.Failure
        public let upstream: Upstream
        public let transformClosure: (Upstream.Output) -> Output
        
        public init(
            upstream: Upstream,
            transform: @escaping (Upstream.Output) -> Output
        ) {
            self.upstream = upstream
            self.transformClosure = transform
        }
        
        public func receive<S>(subscriber: S)
        where S: Subscriber,
              Output == S.Input,
              S.Failure == Upstream.Failure {
            upstream.subscribe(
                MapperSubscriber<S>( // this one is not yet defined
                    subscriber: subscriber,
                    mapClosure: transformClosure
                )
            )
        }
    }
}
{% endhighlight %}

### Custom Subscriber

The next step - `Subscriber`.

I named it `MapperSubscriber`, and we also would like to limit access to this subscriber and make it usable for our `Publisher` only - `MapperSubscriber` will be placed in extension to `Publishers.Mapper`.

Subscriber has `Input` and `Output` according to protocol requrements. So, to transform our values we should define `tranformClosure` that accept `Input` and return `Output`.

Next step - implement all method required by protocol. Here we simply dublicate functionality by calling similar functions on subscriber:

{% highlight swift %}
func receive(subscription: Subscription) {
    subscriber.receive(subscription: subscription)
}
    
func receive(_ input: Input) -> Subscribers.Demand {
    subscriber.receive(mapClosure(input))
}
    
func receive(completion: Subscribers.Completion<Upstream.Failure>) {
    subscriber.receive(completion: completion)
}
{% endhighlight %}

Take a closer look at `receive(_:)` - here, in the place where we get items, the magic begins - we call `mapClosure(input)`, and let someone else to deside, how to transform data in stream.

Combining all together:

{% highlight swift %}
extension Publishers.Mapper {
    private struct MapperSubscriber<S: Subscriber>: Subscriber
    where S.Input == Output,
          S.Failure == Upstream.Failure {
        
        typealias Input = Upstream.Output
        typealias Failure = Upstream.Failure
        
        private let subscriber: S
        private let mapClosure: (Input) -> Output
        let combineIdentifier: CombineIdentifier = .init()
        
        fileprivate init(
            subscriber: S,
            mapClosure: @escaping (Input) -> Output
        ) {
            self.subscriber = subscriber
            self.mapClosure = mapClosure
        }
        
        func receive(subscription: Subscription) {
            subscriber.receive(subscription: subscription)
        }
        
        func receive(_ input: Input) -> Subscribers.Demand {
            subscriber.receive(mapClosure(input))
        }
        
        func receive(completion: Subscribers.Completion<Upstream.Failure>) {
            subscriber.receive(completion: completion)
        }
    }
}
{% endhighlight %}

### Extension

To make it more usable and pretty - let's add an extension to `Publisher` type:

{% highlight swift %}
extension Publisher {
    public func mappper<Result>(
        _ transform: @escaping (Output) -> Result
    ) -> Publishers.Mapper<Self, Result> {
        Publishers.Mapper(upstream: self, transform: transform)
    }
}
{% endhighlight %}

### Test

To test our new addition, we can use simple snippet like following:

{% highlight swift %}
let token = [1,2,3,4] // remember to store token somewhere
    .publisher
    .mappper { value in
        "\(value)"
    }
    .sink { (completionn) in

    } receiveValue: { (result) in
        print("mapped values :", result, type(of: result))
    }
{% endhighlight %}

and output:

{% highlight swift %}
mapped values : 1 String
mapped values : 2 String
mapped values : 3 String
mapped values : 4 String
{% endhighlight %}

[download source code]({% link assets/posts/images/2021-02-09-powerful-trio/source/source.zip %})

## Resources

* [Combine](https://developer.apple.com/documentation/combine)
* [What is Upstream and Downstream in Software Development?](https://reflectoring.io/upstream-downstream/)
* [Understanding Combine’s publishers and subscribers](https://www.donnywals.com/understanding-combines-publishers-and-subscribers/)