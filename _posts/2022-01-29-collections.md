---
layout: post
comments: true
title: "Collections"
categories: article
tags: [swift, iOS, COW, copy-on-write, collection, sequence]
excerpt_separator: <!--more-->
comments_id: 69

author:
- kyryl horbushko
- Lviv
---

Whenever u do something u need data. This can be anything - from a small set of information to a huge amount of bytes. The key moment in any case - is how we can handle this data. 

The answer - is by using data structures such as collections. 
<!--more-->

Swift come with a great set of collections - from [`Set`](https://developer.apple.com/documentation/swift/set), [`Array`](https://developer.apple.com/documentation/swift/array), [`Dictionary`](https://developer.apple.com/documentation/swift/dictionary) to some specific one like [`ArraySlice`](https://developer.apple.com/documentation/swift/arrayslice), [`CollectionOfOne`](https://developer.apple.com/documentation/swift/collectionofone) or [`KeyValuePairs`](https://developer.apple.com/documentation/swift/keyvaluepairs). 

The common stuff of all of these types are conformance to [`Collection`](https://developer.apple.com/documentation/swift/collection) and so to [`Sequence`](https://developer.apple.com/documentation/swift/sequence) protocols. 

## the Family

If we check official documentations, we can find the next structure of the relationship in collection's family:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-01-29-collections/collections.svg">
<img src="{{site.baseurl}}/assets/posts/images/2022-01-29-collections/collections.svg" alt="collections.svg" width="650"/>
</a>
</div>
<br>
<br>

Here we can see 2 fundamental types - [`Sequence`](https://developer.apple.com/documentation/swift/sequence) and [`Collection`](https://developer.apple.com/documentation/swift/collection). Using them, there are a few additional types, that bring to us great functionality.

## Sequence

According to doc - *"A type that provides sequential, iterated access to its elements."*.

### Iterator

`Sequence` gives to us the possibility to use *iterated access to its elements*.

To be more specific, the sequence has an [`Iterator`](https://developer.apple.com/documentation/swift/sequence/1641120-iterator) - a type that can help us to iterate over the elements in a sequence.

This process is well-known by everyone - each time u use a loop - u use an iterator. This can be done thanks to [`IteratorProtocol`](https://developer.apple.com/documentation/swift/iteratorprotocol).

A huge amount of types conform to this protocol. If u like, u also can adopt u'r type to this protocol. `Iterator` should generate elements from u'r data type:

{% highlight swift %}
public protocol IteratorProtocol {
    associatedtype Element
    mutating func next() -> Self.Element?
}
{% endhighlight %}

There are a lot of types that adopt `IteratorProtocol` like `StrideThroughIterator` or `IndexingIterator`.

We can use any of these types or we can directly adopt `IteratorProtocol` to our type.

{% highlight swift %}
let exampleData = [1,2,3,4,5]
// IndexingIterator<[Int]>
var exampleIterator = exampleData.makeIterator()
var element: Int? = exampleIterator.next()

repeat {
 print(element)
 element = exampleIterator.next()
}
while element != nil
{% endhighlight %}

The output:

{% highlight swift %}
Optional(1)
Optional(2)
Optional(3)
Optional(4)
Optional(5)
{% endhighlight %}

Or we can create our iterator:

{% highlight swift %}
final class Generator<Output>: IteratorProtocol {
  private let data: [Output]
  private var index: Int
  init(data: [Output]) {
    self.data = data

    // usage of index allows to use COW
    self.index = data.startIndex
  }

  func next() -> Output? {
    if index < data.endIndex {
      defer { index += 1 }
      return data[index]
    } else {
      return nil
    }
  }

  func hasMore() -> Bool {
    index != data.endIndex
  }
}

let generator = Generator(data: exampleData)

while generator.hasMore() {
  print(generator.next()!)
}
{% endhighlight %}

output:

{% highlight swift %}
1
2
3
4
5
{% endhighlight %}

We can also create some dedicated Iterator like this:

{% highlight swift %}
struct DataIterator<Element>: IteratorProtocol {
    var storage: [Element]

    mutating func next() -> Element? {
        storage.removeFirst()
    }
}
{% endhighlight %}

but be careful - thus this iterator requires a copy of the u'r data structure (as soon as u call `storage.removeFirst()`) and COW can't be used here.

> I wrote a separate article about [COW available here]({% post_url 2022-01-21-cow %})

At the same time, Apple uses a similar approach and is not worried about additional memory needed for iterators - for example, check this [`MinimalIterator`](https://github.com/apple/swift-collections/blob/2ce28a9eaac3a03c7403b09aae10fea3273de193/Sources/_CollectionsTestSupport/MinimalTypes/MinimalIterator.swift):

{% highlight swift %}
internal class _MinimalIteratorSharedState<Element> {
  internal init(_ data: [Element]) {
    self.data = data
  }

  internal let data: [Element]
  internal var i: Int = 0
  internal var underestimatedCount: Int = 0

  public func next() -> Element? {
    if i == data.count {
      return nil
    }
    defer { i += 1 }
    return data[i]
  }
}
{% endhighlight %}

### the `Sequence` power

`Sequence` - a set of elements of a given type. In other words - this is a set of data with which we want to make some operations.
 
`Sequence` protocol provides a lot of nice functions and additions for any type, that conforms it.

The one `hidden` (too many people, due to unknown reason for me) function that can bring u a lot of power - is lazy iteration. This can be done thanks to the [`LazySequenceProtocol`](https://developer.apple.com/documentation/swift/lazysequenceprotocol).

Every time, when u use the `.lazy` property on any sequence u got the `LazySequence<T>` type - this type allows u to make some lazy job by introducing the *eager approach*.

Thanks to this, we can have the only computations we need.

Example:

{% highlight swift %}
let transform = exampleData.lazy.map { "I'm a number \($0)" }
// at this moment nothing happens
print(transform[3]) 
// only 1 element was transformed
{% endhighlight %}

There is a lot of other useful functionality within `Sequence` like `zip`, `reduce`, `filter`, and others. I recommend reviewing it on u'r own.

## `Collection`

`Collection` - the protocol, that adopts to `Sequence` and so contains all the functions described above and some additional. The most useful - is indexing - which lets us access an element at a given index.

*A sequence whose elements can be traversed multiple times, nondestructively, and accessed by an indexed subscript.* as mentioned in [docs](https://developer.apple.com/documentation/swift/collection).

`Collection` also includes a lot of functionality as a gift for us ;]. In addition - there are a lot of subprotocols that bring even more functions - like mutation or random access.

> `Array` for example - adopt all collection-based protocols.

Let's briefly review each protocol and functionality that it brings to us.


### `MutableCollection`

Thanks to this collection, we can use subscript (a great syntax with square brackets - []). 

{% highlight swift %}
collection[2]
{% endhighlight %}

this allows us to get/set values, so opens doors for collection mutability. 

The one point that needs to remember - this protocol does not allow collection length change. The good moment - this improves performance.

It also needs to know, that each protocol offers additional functionality. The most interesting from this protocol are: `partition`, `reverse`, `sort`, `swap` and others. 

This protocol also provide functionality for manage memory of the collection - `withContiguousMutableStorageIfAvailable`. 

### `RangeReplaceableCollection`

The next one protocol - `RangeReplaceableCollection` - provide functionality for *replacement of an arbitrary subrange of elements with the elements of another collection*.

By adopting this protocol we can insert and remove elements from the collection, so the change of the collection can be changed.

The most interesting functions are - `+`, `removeLast`, `removeFirst`.

### `BidirectionalCollection`

This collection adds *supports for backward as well as for forwarding traversal*. This means that u can obtain some index before another one. The only method that needs to be implemented - is `index(before:)`.

The most used methods/properties that become available when adopting this collection - are `reversed`, `startIndex`, `endIndex`, and `indices`.

The most useful, as for me, - `indices`. This property returns valid indexes for subscripts.

{% highlight swift %}
let array = [1,2,3,4,5]
let range = array[1..<array.endIndex]

// crash - Out of bounds exception
// let value = range[0] 

// now ok
let value = array[range.indices.lowerBound]

// alternative
let value = Array(range)[0]
{% endhighlight %}

### `RandomAccessCollection`

`RandomAccessCollection` - *supports efficient random-access index traversal*.

This protocol brings some improvement in access to the elements - all at the same constant time. As sad in docs - *Random-access collections can move indices any distance and measure the distance between indices in O(1) time. Therefore, the fundamental difference between random-access and bidirectional collections is that operations that depend on index movement or distance measurement offer significantly improved efficiency.*

### `LazyCollectionProtocol` 

Similar to `LazySequenceProtocol`, but for collection and provides *operations such as map and filter* implemented lazily.

## Custom collection

To implement custom collection we should twice think if we need this. If so - select the needed functionality set and select protocols that must be adopted.

> For example `Array` implements all of the collection protocols

I won't provide some custom examples, instead - u can check the official git for Collection sp from Apple and any of its custom collections, for example [Deque](https://github.com/apple/swift-collections/blob/2ce28a9eaac3a03c7403b09aae10fea3273de193/Sources/DequeModule/Deque%2BCollection.swift).

The code will guide u over each possible protocol and steps that are needed. 

Few more advice:

* every type can be a collection (or at least adopt some of the protocols and receive a bunch of functionality for free). This can be u'r training plan, events in the calendar, budget, ROI set... anything.
* to make u'r collection even handier - use [`ExpressibleByArrayLiteral`](https://developer.apple.com/documentation/swift/expressiblebyarrayliteral) and [`ExpressibleByDictionaryLiteral`](https://developer.apple.com/documentation/swift/expressiblebydictionaryliteral). This will allow u to use well-know syntax for u'r collection.
* add custom subscripts - the one that accepts u'r data type.

## Resources

* [`Collection`](https://developer.apple.com/documentation/swift/collection)
* [`Sequence`](https://developer.apple.com/documentation/swift/sequence) 
* [swift-collections sp](https://github.com/apple/swift-collections)
* Book "Swift in depth" by Tjeerd in't Veen
