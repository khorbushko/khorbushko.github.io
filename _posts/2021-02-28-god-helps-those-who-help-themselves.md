---
layout: post
comments: true
title: "God helps those who help themselves"
categories: article
tags: [iOS, Combine]
excerpt_separator: <!--more-->
comments_id: 31

author:
- kyryl horbushko
- Lviv
---

`Combine` improves our code and makes development much faster and easier. But, even with such an idea in mind, we can often face some issues (like *"unresolved type of result"*). A swift compiler is very strong-typed, so when we use it within the `Combine` framework we can face different errors (like *"Generic parameter 'T' could not be inferred"*). 

There is no limit for improvements, so some tricks can not only make coding much pleasant but also may bring some improvement into it.

I would like to list here some tricks and a few pieces of advice that I found, during the last few months of life with `Combine`.

## Understand what are u doing

Yep, such simple but yet powerful advice. If u have a chained transformation from some publisher(s), and u use different functions, at some point, u may lose the understanding what the type of value u operate inside the transform closure. 

U even may try to check the type by calling QuickHelp or checking Inspector panel, but result usually - `<unknown type>` or `No Quick Help`:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-02-28-god-helps-those-who-help-themselves/no_help.png" alt="no_help" width="350"/>
</div>
<br>

This mean, that compiler don't understand what u are trying to do, because downside of tranforms chaining may be a type with very complex declaration:

{% highlight swift %}
func flatMap<T, P>(maxPublishers: Subscribers.Demand = .unlimited, _ transform: @escaping (Tour.Bus.Info) -> P) -> Publishers.FlatMap<P, Publishers.FlatMap<Publishers.Map<Publishers.Collect<Publishers.FlatMap<AnyPublisher <ResultHolder>, Publishers.Map<AnyPublisher<Tour.Bus.DataResponse, Error>, ResultHolder>.Failure>, Publishers.Sequence<[AnyPublisher<ResultHolder, Publishers.Map<AnyPublisher<Tour.Bus.DataResponse, Error>, ResultHolder>.Failure>], Error>>>, Tour.Bus.Info>, AnyPublisher<Void, Error>>> where T == P.Output, P : Publisher, Self.Failure == P.Failure
{% endhighlight %}

If u don't know the type, how the compiler can? So, understand what u are doing. Be sure that u know `Input` and `Output` types on all steps required for transformations.

## Erase the publisher's type

As I mentioned above, the result type of transformation can be very complex, so erase it as often as u can, to simplify the result type.

{% highlight swift %}
 }
 .eraseToAnyPublisher()
{% endhighlight %}

## Do not use `$0` in the transformation

This rule just makes u'r code a bit more declarative - I, personally, forget everything I have done in a week or so, so I always try to write a code, that describes by itself what is going there.

We may compare 2 code snipets:

{% highlight swift %}
rawData
  .publisher
  .setFailureType(to: Error.self)
  .flatMap(maxPublishers: .max(1), { $0 })
  .collect()
  .map {
    Device.Raw.Info(
      program: $0.compactMap {
          if case .program(let i) = $0 {
            return ProgramTransformation(i)
          } else {
            return nil
          }
      }.first!,
      diodes: $0.compactMap {
        if case .diodes(let i, let z) = $0 {
          return MagnitoTransformation(rawCouple: (i, z))
        } else {
          return nil
        }
      }.first!
    )
  }
.eraseToAnyPublisher()
{% endhighlight %}

with

{% highlight swift %}
rawData
.publisher
.setFailureType(to: Error.self)
.flatMap(maxPublishers: .max(1), { processingData in
  processingData
})
.collect()
.map { processedData in
  Device.Raw.Info(
    program: processedData.compactMap { currentResult in
      if case .program(let value) = currentResult {
        return ProgramTransformation(value)
      } else {
        return nil
      }
    }.first,
    diodes: processedData.compactMap { currentResult in
      if case .diodes(let diodes, let anodes) = currentResult {
        return MagnitoTransformation(rawCouple:(diodes, anodes))
      } else {
        return nil
      }
    }.first
  )
}
.eraseToAnyPublisher()
{% endhighlight %}

The second variant more declarative and tell the story better than the first one. So - descriptively write u'r code, so later u can read it as a book.


## Set explicit return type

Sometimes (more often than we want ;]), a compiler may report an error like

{% highlight swift %}
Generic parameter 'T' could not be inferred.
{% endhighlight %}

Example contains few tranforms, that without explicit return type produce and error:

{% highlight swift %}
private func createConnection() -> AnyPublisher<Iglu.Motor.Device, Error> {
  enum Failure: Error {
    case deviceNotAvailable
  }

  return
    Deferred {
      self.keychainIgluStorage.load()
        .publisher
    }
    .tryMap { (device) -> API.IgluDevice in
      if let device = device {
        return device
      } else {
        throw Failure.deviceNotAvailable
      }
   }
  .flatMap { storedDevice -> AnyPublisher<Iglu.Stored.Device, Error> in
      Just(self.connection)
      .setFailureType(to: Swift.Error.self)
      .flatMap { connection in
        self.performSearch(using: connection, target: storedDevice)
          .eraseToAnyPublisher()
      }
      .retryWhen { error -> AnyPublisher<Void, Error> in
        switch error {
          case Iglu.Failure.unknownState:
            Just(())
              .delay(for: 100, scheduler: schedulerQueue)
              .setFailureType(to: Swift.Error.self)
              .eraseToAnyPublisher()
        }
      }
   }
  .flatMap { device -> AnyPublisher<Iglu.Motor.Device, Error> in
    Just(self.connection)
      .setFailureType(to: Swift.Error.self)
      .flatMap { connection in
        self.performConnection(using: connection, on: device)
          .eraseToAnyPublisher()
      }
   }
  .eraseToAnyPublisher()
}
{% endhighlight %}

> Off cause - such function is hard to read and understand, so it's better to divide the code into smaller parts. See next advice.

## Put in a function just 1 functionality

This is yet another simple rule - 1 function should perform 1 function. Such a way allows u to reuse functionality across different pipelines. 

Ur code becomes much cleaner and compact. This also makes it more readable and understandable.

## Use `print`, `breakpointOnError` ,and `breakpoint`

These few additions to u'r pipeline can greatly improve the understanding of the situation and debug the code.

I like to check each pipeline in detail before going to the next steps. These small utilities help a lot, with minimal effort.

> U can attach them at any step of u'r pipe
