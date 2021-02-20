---
layout: post
comments: true
title: "Save resources"
categories: article
tags: [iOS, Combine]
excerpt_separator: <!--more-->
comments_id: 30

author:
- kyryl horbushko
- Lviv
---

Resource sharing is a process when we use something wisely. And nowadays, this point is very hot - a lot of contributors would like to have something. 

If we think about resources from a developer's point of view, we can highlight few hot points also - server resource, or BLE device resource, or even CPU computation result. To make things better, we should save as much as possible. Our world becomes smaller and smaller every second, and resource-saving questions become more and more "popular".
<!--more-->

Think about `Swift` language and `Combine` framework - how often we can do the same things again and again. To minimize such behavior, `Combine` provides for us few possible solutions:

- [`share`](https://developer.apple.com/documentation/combine/publishers/merge/share())
- [`multicast`](https://developer.apple.com/documentation/combine/publishers/multicast)

But, Rx world also knows an additional one:

- [`share(replay:)`](https://github.com/CombineCommunity/CombineExt#sharereplay)

Why do we need a separate function to share the output? Think about publishers - they are struct. So within every subscription, u will get a copy, and so, the operation will be repeated. Sometimes (in most cases) it's ok, but, in some cases, we don't want to get this behavior. 

Imagine a situation when u would like to get the same information from a server within few publishers - u will repeat the request few times. This is not something u want to get. U want to save u'r resources, to bring a better UX.

## Share

[`share`](https://developer.apple.com/documentation/combine/publishers/merge/share()) - *"shares elements received from its upstream to multiple subscribers"*.

This is useful when few subscribers ask a publisher to provide the same information in relatively close time.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-20-save-resources/share_example.png" alt="share_example" width="550"/>
</div>
<br>

Example:

{% highlight swift %}
var tokens: Set<AnyCancellable> = []
let dataPublisher =
  [1, 2, 3, 4]
  .publisher
  .delay(for: 1, scheduler: DispatchQueue.main)
  .map { _ -> String in
    let charCode = Int.random(in: 9_000...10_000)
    return String(Character(UnicodeScalar(charCode)!))
  }

dataPublisher
  .sink { (value) in
    print("Pub1 : \(value)")
  }
  .store(in: &tokens)

dataPublisher
  .sink { (value) in
    print("Pub2 : \(value)")
  }
  .store(in: &tokens)
{% endhighlight %}

Output:

{% highlight swift %}
Pub1 : ⏚
Pub1 : ▿
Pub1 : ␵
Pub1 : ☭
Pub2 : ⒣
Pub2 : ⑟
Pub2 : ╞
Pub2 : ⛯
{% endhighlight %}

As u can see, we perform the same operation twice and the result is different. Now, let's add `share` to a publisher.

Output:

{% highlight swift %}
Pub1 : ⑩
Pub2 : ⑩
Pub1 : ⎞
Pub2 : ⎞
Pub1 : ⎄
Pub2 : ⎄
Pub1 : ╍
Pub2 : ╍
{% endhighlight %}

As u can see - now, we share the same result for all publishers.

Another sample that also can demonstrate how `share` works - sample with `Timer`:

{% highlight swift %}
let publisher = Timer.publish(every: 1, on: .main, in: .default)
  .autoconnect()
  .scan(0, { (x, y) -> Int in x + 1 })

publisher
  .sink {
    print("1 - ", $0)
  }
  .store(in: &tokens)

DispatchQueue.global().asyncAfter(deadline: .now() + 4) {
  publisher
    .sink {
      print("2 - ", $0)
    }
    .store(in: &tokens)
}
{% endhighlight %}

> This great idea of explanation I grab from [SO `matt`s post](https://stackoverflow.com/a/59594915) 

The output will be something like this:

{% highlight swift %}
1 -  1
1 -  2
1 -  3
1 -  4
2 -  1
1 -  5
2 -  2
1 -  6
2 -  3
1 -  7
{% endhighlight %}

But if u add `share` to a publisher:

{% highlight swift %}
1 -  1
1 -  2
1 -  3
1 -  4
2 -  5
1 -  5
2 -  6
1 -  6
2 -  7
1 -  7
{% endhighlight %}

> Using `share` may also trigger some unexpected result, for example [this post](https://forums.swift.org/t/combine-inconsistent-share-behavior/39029).

The weak side of this publisher - there is no possibility to store the result and share it with a new subscriber after an operation is done. But for this purpose, there is another 3rd party publisher - [`share(replay:)`](https://github.com/CombineCommunity/CombineExt#sharereplay). 


## Multicast

[`multicast`](https://developer.apple.com/documentation/combine/publishers/multicast) - allow to share responsibility for all the subscriber as soon as they are connected. Because the multicast publisher is a `ConnectablePublisher`, events will be sent only after a call to `ConnectablePublisher.connect()`.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-20-save-resources/multicast_example.png" alt="multicast_example" width="550"/>
</div>
<br>

This publisher accepts one parameter: either a `Subject` or a function that produces a `Subject`.

> `Subject` an object that can emit a value on request. It's a class, so it can be shared. [read more](https://www.apeth.com/UnderstandingCombine/publishers/publisherssubject.html).

If we check the behavior of `share` and `multicast` publishers, we can tell that `Share` object is a `Multicast` object. `share` is just a convenient wrapper for `multicast`. 

We can use the same example as for a `share` publisher, with little modification:

{% highlight swift %}
let pass = PassthroughSubject<String, Never>()

let dataPublisher =
  [1, 2, 3, 4]
  .publisher
  .map { _ -> String in
    let charCode = Int.random(in: 9_000...10_000)
    return String(Character(UnicodeScalar(charCode)!))
  }
  .multicast(subject: pass)

dataPublisher
  .sink { (value) in
    print("Pub1 : \(value)")
  }
  .store(in: &tokens)

dataPublisher
  .sink { (value) in
    print("Pub2 : \(value)")
  }
  .store(in: &tokens)

dataPublisher.connect()
{% endhighlight %}

Output:

{% highlight swift %}
Pub2 : ╂
Pub1 : ╂
Pub2 : ☕
Pub1 : ☕
Pub2 : ♁
Pub1 : ♁
Pub2 : ⒕
Pub1 : ⒕
{% endhighlight %}

As u can see - as soon as we call `connect`, we start to receive values. `Multicast` has a `Subject` inside, and when events are received from upstream, this subject just resents them downstream.

## ShareReplay

Apple does not include this into `Combine` framework, instead, this additional publisher described in many sources ([RW](https://www.raywenderlich.com/books/combine-asynchronous-programming-with-swift/v1.0/chapters/18-custom-publishers-handling-backpressure)), [CombineExt](https://github.com/CombineCommunity/CombineExt#sharereplay), etc).

The main purpose of this publisher - is *"to create a publisher instance with reference semantics which replays a pre-defined amount of value events to further subscribers"*. ([source](https://github.com/CombineCommunity/CombineExt#sharereplay)). In two words - it's like `share`, but with buffer.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-20-save-resources/shareReplay_example.png" alt="shareReplay_example" width="550"/>
</div>
<br>

Example:

{% highlight swift %}
let dataPublisher =
  [1, 2, 3, 4]
  .publisher
  .delay(for: 1, scheduler: DispatchQueue.main)
  .map { _ -> String in
    let charCode = Int.random(in: 9_000...10_000)
    return String(Character(UnicodeScalar(charCode)!))
  }
  .shareReplay()

dataPublisher
  .sink { (value) in
    print("Pub1 : \(value)")
  }
  .store(in: &tokens)

dataPublisher
  .delay(for: 1, scheduler: DispatchQueue.main)
  .sink { (value) in
    print("Pub2 : \(value)")
  }
  .store(in: &tokens)
{% endhighlight %}

Output:

{% highlight swift %}
Pub1 : ⚛
Pub1 : ⓴
Pub1 : ⓵
Pub1 : ⛆
Pub2 : ⚛
Pub2 : ⓴
Pub2 : ⓵
Pub2 : ⛆
{% endhighlight %}

[download source code]({% link assets/posts/images/2021-02-20-save-resources/source/source.zip %})


## Resources

* [Working with Multiple Subscribers](https://developer.apple.com/documentation/combine/publisher)
* [Custom Publishers & Handling Backpressure](https://www.raywenderlich.com/books/combine-asynchronous-programming-with-swift/v1.0/chapters/18-custom-publishers-handling-backpressure)
* [Share-Replay](https://www.onswiftwings.com/posts/share-replay-operator/)
* [Multicasting, Publisher.share(replay:), and ReplaySubject](https://jasdev.me/multicasting)
* [Marble diagram generator](https://rx-marbles-online.herokuapp.com/.)
* [Understanding share in Combine](https://stackoverflow.com/questions/59593139/understanding-share-in-combine)
* [Combine: what are those multicast functions for?](https://forums.swift.org/t/combine-what-are-those-multicast-functions-for/26677)
* [Share](https://www.apeth.com/UnderstandingCombine/operators/operatorsSplitters/operatorsshare.html)
* [Multicast](https://www.apeth.com/UnderstandingCombine/operators/operatorsSplitters/operatorsmulticast.html)
* [Multicast](https://heckj.github.io/swiftui-notes/#reference-multicast) 
* [ShareReplay](https://www.onswiftwings.com/posts/share-replay-operator/)
