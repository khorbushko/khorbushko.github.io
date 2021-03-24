---
layout: post
comments: true
title: "Dynamic swift - Part 1: KeyPath"
categories: article
tags: [Swift, KeyPath]
excerpt_separator: <!--more-->
comments_id: 33

author:
- kyryl horbushko
- Lviv
---

Dynamic features bring some flexibility and additional functionality into the programming language, but at the same moment, this can reduce compile-time safety. 
<!--more-->

Swift has a strongly-typed system. In the same moment during the last few years, a few dynamic features were added to it. The most interesting are:

- [keyPath](https://github.com/apple/swift-evolution/blob/master/proposals/0161-key-paths.md)
- [dynamic member lookup](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md)
- [dynamic replacement](https://forums.swift.org/t/dynamic-method-replacement/16619)

Also, it's good to mention about [opposite to @dynamicCallable - static Callable](https://github.com/apple/swift-evolution/blob/master/proposals/0253-callable.md)

Some dynamic features were present in language from the very beginning:

- [`Mirror`](https://developer.apple.com/documentation/swift/mirror).
- additions from Obj-C (such as KVO, dynamic dispatch, etc) (this still can be used by using `@objc`, `dynamic`, `NSObject` and other modifiers/techniques)

**Related articles:**

- Dynamic swift - Part 1: KeyPath
- [Dynamic swift - Part 2: @dynamicMemberLookup]({% post_url 2021-03-22-dynamic-swift-dynamic-member-lookup %})
- [Dynamic swift - Part 3: Opposite to @dynamicCallable - static Callable]({% post_url 2021-03-25-dynamic-swift-callable %})
- [Dynamic swift - Part 4: @dynamicReplacement]({% post_url 2021-01-11-do-that-instead-of-this %})

## dynamic or static?

Swift is a static type (or strong type) language - this means, that compiler should now all information about all classes, functions, and other types. This means, that all features, that somehow "close the all-seeing eye" of a compiler, can be named as a *dynamic* feature.

For comparison let's think about Obj-C - in this language all things are a bit more flexible than in Swift. This is because compiler deferring the bounding process for the all of components as long as it's possible, as result - u get a great flexibility and a wide possibilities ([dynamic typing](https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/DynamicTyping.html#//apple_ref/doc/uid/TP40008195-CH62-SW1), [dynamic binding](https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/DynamicBinding.html#//apple_ref/doc/uid/TP40008195-CH15-SW1), [kvc](https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/KeyValueCoding.html#//apple_ref/doc/uid/TP40008195-CH25-SW1), [kvo](https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/KVO.html#//apple_ref/doc/uid/TP40008195-CH16-SW1), [forward invokation](https://developer.apple.com/documentation/objectivec/nsobject/1571955-forwardinvocation), [swizzling]({% post_url 2021-01-11-do-that-instead-of-this %}), etc). 

The downside of such a process is safety. And Apple knows it.

> 
{% highlight objective-c %}
-(void)attentionClassDumpUser:(id)arg1 
		yesItsUsAgain:(id)arg2 
		althoughSwizzlingAndOverridingPrivateMethodsIsFun:(id)arg3 
		itWasntMuchFunWhenYourAppStoppedWorking:(id)arg4 
		pleaseRefrainFromDoingSoInTheFutureOkayThanksBye:(id)arg5;
{% endhighlight %}
> source [from iOS 3 dump of ViewController](https://openradar.appspot.com/7044974) or [wiki](https://iphonedevwiki.net/index.php/UIViewController)

Swift started obtaining a different dynamic feature when support for Linux was added. On Linux, there is no `Foundation` framework from Apple (at least at the beginning, for now, it's open-source), so runtime features from Obj-C are not available, but developers still need it, and open-source Swift allows them to do this. 

As of now, we have a few of them already added, and a few more are waiting for proposals.

## keyPath

*[KeyPath](https://developer.apple.com/documentation/swift/keypath) - A key path from a specific root type to a specific resulting value type.*

KeyPath allows us to get access to type variables using strongly-typed paths that are checked at compilation time.

There are few types of keyPath:

* [`AnyKeyPath`](https://developer.apple.com/documentation/swift/anykeypath) - a type-erased key path, from any root type to any resulting value type
* [`PartialKeyPath`](https://developer.apple.com/documentation/swift/partialkeypath) - a partially type-erased key path, from a concrete root type to any resulting value type.
* [`KeyPath`](https://developer.apple.com/documentation/swift/keypath): read-only.
* [`WritableKeyPath`](https://developer.apple.com/documentation/swift/writablekeypath): read-write.
* [`ReferenceWritableKeyPath`](https://developer.apple.com/documentation/swift/referencewritablekeypath): read-write, mutable, only for ref types.

> mentioned according to a class hierarchy

It's also important to understand, that `#keyPath` added in Swift 3 compiles down into a String. It was added mostly to support Obj-C KVO/KVC and so, requires that our object inherits from `NSObject`. This off cause introduces some constraints into Swift code.

Such an approach also does not provide any information about the type of object to which it below - it's just a String. This means, that we can't work with data processed with a key path as with concrete type data - only as `Any`.

`KeyPath` type, instead, is a fast, property traversal, statically type-safe, available for all values and on all platforms where Swift works.

### usage of keyPath

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-03-13-dynamic-features/usage.pdf" alt="files" width="450"/>
</div>
<br>

> subscript also allowed.

> based on [WWDC 17 #212 What's New in Foundation](https://developer.apple.com/videos/play/wwdc2017/212/)

## AnyKeypath

`AnyKeyPath` does not have some generic constraints, and this type is created for handling any keypath (:]) from any objects. So this type is fully erased, and don't know about its route and root object.

> `route` means expression, that describes how we can get this property from a specific (or unknown) object. Another name for this object - `root`

`AntKeyPath` is used when u have a deal with many keypaths from different objects. This can be an array of items, or input to u'r functions:

{% highlight swift %}
final class Bar {
  var foo: Int?
}

final class Foo {
  var bar: Bar?
}

let barObject = Bar()
barObject.foo = 1
let fooObject = Foo()
fooObject.bar = barObject

let fooBarKeyPath: AnyKeyPath = \Foo.bar!
let barFooKeyPath: AnyKeyPath = \Bar.foo

let value1 = barObject[keyPath: fooBarKeyPath]
// return 1

let value2 = fooObject[keyPath: fooBarKeyPath]
// return nil

let anyKeyPathArray = [
  fooBarKeyPath,
  barFooKeyPath
]
// Array<AnyKeyPath>
{% endhighlight %}

In addition to described above, this type conforms to protocol `_AppendKeyPath` - this protocol allows us to modify keyPath by appending some components.

> note: Apple mentions in header *"do not use this protocol directly."*

{% highlight swift %}
let fooBarKeyPath: AnyKeyPath = \Foo.bar!
let barFooKeyPath: AnyKeyPath = \Bar.foo

let appendedKeyPath = fooBarKeyPath.appending(path: barFooKeyPath)
// ReferenceWritableKeyPath<AnotherTestObject, Optional<Int>>

let value3 = fooObject[keyPath: appendedKeyPath!]
// return 1
{% endhighlight %}

To describe rules of appending here is a quick image:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-03-13-dynamic-features/appending_rule.pdf" alt="files" width="450"/>
</div>
<br>

> based on [WWDC 17 #212 What's New in Foundation](https://developer.apple.com/videos/play/wwdc2017/212/)

When we perform appending of different keyPath, we may receive different KeyPath class as result:


| First | Second | Result |
|-|-|-|
| AnyKeyPath | Anything | AnyKeyPath? |
| PartialKeyPath | AnyKeyPath or PartialKeyPath | PartialKeyPath? |
| PartialKeyPath | KeyPath or WritableKeyPath | KeyPath? |
| PartialKeyPath | ReferenceWritableKeyPath | ReferenceWritableKeyPath? |
| KeyPath | AnyKeyPath or PartialKeyPath | 💥 Not possible 💥  |
| KeyPath | KeyPath or WritableKeyPath | KeyPath |
| KeyPath | ReferenceWritableKeyPath | ReferenceWritableKeyPath |
| WritableKeyPath | AnyKeyPath or PartialKeyPath | 💥 Not possible 💥  |
| WritableKeyPath | KeyPath | KeyPath |
| WritableKeyPath | WritableKeyPath | WritableKeyPath |
| WritableKeyPath | ReferenceWritableKeyPath | ReferenceWritableKeyPath |
| ReferenceWritableKeyPath | AnyKeyPath or PartialKeyPath | 💥 Not possible 💥  |
| ReferenceWritableKeyPath | KeyPath | KeyPath |
| ReferenceWritableKeyPath | WritableKeyPath or ReferenceWritableKeyPath | ReferenceWritableKeyPath |

> source of this comparison table is [described by Kevin Lundberg](https://klundberg.com/blog/swift-4-keypaths-and-you/)

If we looked into the header we could also find, that we have few more available public properties: a few required by a `Hashable` protocol, and also 2 more, that describe `root` type and `value` type:

{% highlight swift %}
/// The root type for this key path.
@inlinable public static var rootType: Any.Type { get }

/// The value type for this key path.
@inlinable public static var valueType: Any.Type { get }
{% endhighlight %}

If we check [source code for `KeyPath`](https://github.com/apple/swift/blob/main/stdlib/public/core/KeyPath.swift) in swift, we can observe, that this values use `_rootAndValueType` value, that is implemented as follow:

{% highlight swift %}
@usableFromInline
internal class var _rootAndValueType: (root: Any.Type, value: Any.Type) {
	_abstract()
}
{% endhighlight %}

where `_abstract()` defined as:

{% highlight swift %}
internal func _abstract(
  methodName: StaticString = #function,
  file: StaticString = #file, line: UInt = #line
) -> Never {
#if INTERNAL_CHECKS_ENABLED
  _fatalErrorMessage("abstract method", methodName, file: file, line: line,
      flags: _fatalErrorFlags())
#else
  _conditionallyUnreachable()
#endif
{% endhighlight %}

For generic subclasses this method has a bit different implementation:
{% highlight swift %}
/// A key path from a specific root type to a specific resulting value type.
public class KeyPath<Root, Value>: PartialKeyPath<Root> {
  @usableFromInline
  internal final override class var _rootAndValueType: (
    root: Any.Type,
    value: Any.Type
  ) {
    return (Root.self, Value.self)
  }
  ...
{% endhighlight %} 

Indeed, if we try to grab this 2 values from `AnyKeyPath`, we will get an fatalError:

{% highlight swift %}
//let anyKeyPathRootValue = AnyKeyPath.rootType
// Fatal error: Method must be overridden: file Swift/KeyPath.swift, line 140
{% endhighlight %}

But for types that is inherit from `KeyPath` (including), value about this types become available and we can obtain it easelly:

{% highlight swift %}
let concreateKeyPathRootValue = KeyPath<Bar, Int>.rootType 
//__lldb_expr_7.Bar.Type

let concreateKeyPathValueType = KeyPath<Bar, Int>.valueType
//Int.Type
{% endhighlight %}

Why do this vaiables exists? This information used when different operations is tried to be performed within selected KeyPath. For example - appending, when we want to do this, on some internal step of this process:

{% highlight swift %}
@usableFromInline
internal func _tryToAppendKeyPaths<Result: AnyKeyPath>(
  root: AnyKeyPath,
  leaf: AnyKeyPath
) -> Result? {
  let (rootRoot, rootValue) = type(of: root)._rootAndValueType
  //_rootAndValueType - source for valueType and rootType
  let (leafRoot, leafValue) = type(of: leaf)._rootAndValueType
  ...
  // perform different comparison operations and 
  // append if possible based on input data
{% endhighlight %}

## PartialKeyPath

[`PartialKeyPath`](https://developer.apple.com/documentation/swift/partialkeypath) - A partially type-erased key path, from a concrete root type to any resulting value type. 

> More about idea - read [here](https://github.com/apple/swift-evolution/blob/master/proposals/0161-key-paths.md#unknown-path--known-root-type).

If we check implementation, we can see next:

{% highlight swift %}
public class PartialKeyPath<Root>: AnyKeyPath { }
{% endhighlight %}

Not much, the only difference is that this type holds information about the `Root` type. As result, this type knows about its base type:

{% highlight swift %}
final class Bar {
  var foo: Int?
  var fooBar: String?
}

let barObject = Bar()
barObject.foo = 1
barObject.fooBar = "hello"

let barPaths = [\Bar.foo, \Bar.fooBar]
// [PartialKeyPath<Bar>]

barPaths.forEach { (path) in
  print(barObject[keyPath: path])
}

// prints:
// Optional(1)
// Optional("hello")
{% endhighlight %}

This type of keyPath is also read-only.

## KeyPath

[`KeyPath`](https://developer.apple.com/documentation/swift/keypath). This is a type, that describes not just a Root object, but also a value type.

For `KeyPath` we can check `valueType` and `rootType`:

{% highlight swift %}
let concreateKeyPathRootValue = KeyPath<Bar, Int>.rootType 
//__lldb_expr_7.Bar.Type

let concreateKeyPathValueType = KeyPath<Bar, Int>.valueType
//Int.Type
{% endhighlight %}
> [realization](https://github.com/apple/swift/blob/9b016cbc061b9bb5500ace237f1c306ab04d13f8/stdlib/public/core/KeyPath.swift#L203)

But the most important - we have now information about valueType. Example of usage may be next:

{% highlight swift %}
extension Sequence {
  func transform<T, V>(
    transform byKeyPath: KeyPath<Element, T>,
    block: ((T) -> V)
  ) -> [V] {
    map { (object) -> V in
      block(object[keyPath: byKeyPath])
    }
  }
}

// Example:

struct FooBar {

  var bar: Int
}

let barsObjects = [
  FooBar(bar: 1),
  FooBar(bar: 2),
  FooBar(bar: 3)
]

let result = barsObjects
  .transform(transform: \FooBar.bar) {
    "\($0)"
  }

print(result) // ["1", "2", "3"]
{% endhighlight %}

or u may want to use it in some logic like next:

{% highlight swift %}
protocol DataExpressible { }

struct DataInfo<Element>: Collection where Element: DataExpressible {
  typealias Index = Array<Element>.Index

  subscript(position: Index) -> Element {
    components[position]
  }

  let components: [Element]

  var startIndex: Index {
    components.startIndex
  }

  var endIndex: Index {
    components.endIndex
  }

  func index(after i: Index) -> Index {
    components.index(after: i)
  }
}

extension String {
  static var newLine: String { "\n" }
}

extension DataInfo where Element: LocalizedError {
  var log: String {
    [
      description(for: \.errorDescription, separator: .newLine),
      description(for: \.failureReason, separator: .newLine),
      description(for: \.recoverySuggestion, separator: .newLine),
      description(for: \.helpAnchor, separator: .newLine)
    ]
    .compactMap({ $0 })
    .joined(separator: .newLine)
  }

  private func description(
  			for keyPath: KeyPath<Element, String?>,
  			separator: String
  ) -> String {
    components
      .compactMap { $0[keyPath: keyPath] }
      .joined(separator: separator)
  }
}
{% endhighlight %}

## WritableKeyPath

[`WritableKeyPath`](https://developer.apple.com/documentation/swift/writablekeypath) This is the same as the previous type, but allows perform write in addition to read. A good note about this key-path - it's only for value-type.

To explain this type it's better to provide an example:

{% highlight swift %}
struct Some {

  let variable: Int
}

let someVar = Some(variable: 2)

let someKeyPath = \Some.variable
someVar[keyPath: someKeyPath] = 2
{% endhighlight %}

Output:

{% highlight swift %}
error: play.playground:172:8: error: cannot assign through subscript: 'someKeyPath' is a read-only key path
someVar[keyPath: someKeyPath] = 2
{% endhighlight %}

If we check type of `someKeyPath`:

{% highlight swift %}
type(of: someKeyPath) // KeyPath<Some, Int>
{% endhighlight %}

As I mentioned before, `KeyPath` - read-only. Now, let's modify our `Some` struct:

{% highlight swift %}
struct Some {

   var variable: Int
// ^~~~~~~~~~~ changed let to var 
}
{% endhighlight %}

> u also could resolve this issue by adding mutation keyword to a method that calls this keypath, but this is not the right decision. 

If we now check `someKeyPath`:

{% highlight swift %}
type(of: someKeyPath) // WritableKeyPath<Some, Int>
{% endhighlight %}

Now, operations like `someVar[keyPath: someKeyPath] = 2` allowed.

Example of usage:

{% highlight swift %}
// describe settingsService

protocol SettingsService: class {
    var didChange: NSNotification.Name { get }
    
    var isSoundsEnabled: Bool { get set }
}

// helper to store settings in UserDefaults
@propertyWrapper
public struct UserDefaultValue<T> {
    private let key: String
    private let defaultValue: T

    public init(_ key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    public var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

// concrete realization of SettingsService
extension UserDefaults: SettingsService {
    private struct ValueStorage {
        @UserDefaultValue(SettingsDataKeys.isSoundsEnabled, defaultValue: true)
        static var isSoundsEnabled: Bool

        @UserDefaultValue(SettingsDataKeys.isVibroEnabled, defaultValue: true)
        static var isVibroEnabled: Bool
    }

    var didChange: NSNotification.Name {
        get {
            UserDefaults.didChangeNotification
        }
    }
    
    var isSoundsEnabled: Bool {
        set { ValueStorage.isSoundsEnabled = newValue }
        get { ValueStorage.isSoundsEnabled  }
    }
    
    // MARK: - Private
    
    private func value<T>(forKey key: String) -> T? {
        value(forKey: key) as? T
    }
}

// And class where we can use keyPath in combination with dynamicMemberLookup

@dynamicMemberLookup
final class SettingsViewModel: ObservableObject {
    subscript<T>(
    dynamicMember keyPath: WritableKeyPath<SettingsService, T>
	//		^~~~~~~~~~~~~~
    ) -> T {
        get { storage[keyPath: keyPath] }
        set { storage[keyPath: keyPath] = newValue }
    }
    
    let objectWillChange = PassthroughSubject<Void, Never>()
	// ...    
    
    private var storage: SettingsService
	// ..
}

// later on we can do something like:

viewModel.isSoundsEnabled = true
// or bind to 
$viewModel.isSoundsEnabled
{% endhighlight %}

> I will tell more about `dynamicMemberLookup` in the next article

Sometimes u can omit 

## ReferenceWritableKeyPath

[`ReferenceWritableKeyPath`](https://developer.apple.com/documentation/swift/referencewritablekeypath). Same as the previous one, but now for a reference type. So this type was created specifically to support reading from and writing to the resulting value using reference semantics.

If we compare `WritableKeyPath` vs `ReferenceWritableKeyPath` - the fists one writes directly into a value-type base (inout or mutating), the second one writes into a reference-type base (simply invoking setter on reference type).

## Bonus

### value observation

We also can use now keyPath for value obsevation:

{% highlight swift %}
var token: NSKeyvalueObservation = object
		.observe(\.bar, options: [.new]) { observer, changed in
	// do stuff with observer (object itself) and 
	// changed - NSKeyValueObsevedChange<Type> where Type - same as in \.bar
	}
	
	// ...
	
token?.invalidate() // when not needed
{% endhighlight %}

> [WWDC 17 #212 What's New in Foundation](https://developer.apple.com/videos/play/wwdc2017/212/?time=1214) 

### SE-0249

In proposal [SE-0249](https://github.com/apple/swift-evolution/blob/master/proposals/0249-key-path-literal-function-expressions.md) described ideat that can add to key paths the ability to be used as functions.

Now this is implemented and can be used within `Combine`:

```
let responsePublisher = publisher
				 .map(\.data)
	// 			  	  ^~~~~~~~~
               .decode(type: FeedItem.self, decoder: JSONDecoder())
               .receive(on: DispatchQueue.main)
```

### Obj-C #keyPath

It's also good to mention, that we still can use `#keyPath` for Objective-C code.

> more [Referencing Objective-C key-paths](https://github.com/apple/swift-evolution/blob/master/proposals/0062-objc-keypaths.md)

<br>

[download source code]({% link assets/posts/images/2021-03-13-dynamic-features/source/play.playground.zip %})
<br>
<br>

In the next articles, I will cover other dynamic aspects of Swift.

**Related articles:**

- Dynamic swift - Part 1: KeyPath
- [Dynamic swift - Part 2: @dynamicMemberLookup]({% post_url 2021-03-22-dynamic-swift-dynamic-member-lookup %})
- [Dynamic swift - Part 3: Opposite to @dynamicCallable - static Callable]({% post_url 2021-03-25-dynamic-swift-callable %})
- [Dynamic swift - Part 4: @dynamicReplacement]({% post_url 2021-01-11-do-that-instead-of-this %})

## Resources

- [Key-Path Expressions](https://developer.apple.com/documentation/swift/swift_standard_library/key-path_expressions)
- [Key Paths](https://github.com/apple/swift-evolution/blob/master/proposals/0161-key-paths.md)
- [Dynamic member lookup](https://github.com/apple/swift-evolution/blob/master/proposals/0195-dynamic-member-lookup.md)
- [Key Path Member Lookup](https://github.com/apple/swift-evolution/blob/master/proposals/0252-keypath-dynamic-member-lookup.md)
- [Dynamic replacement](https://forums.swift.org/t/dynamic-method-replacement/16619)
- [Callable](https://github.com/apple/swift-evolution/blob/master/proposals/0216-dynamic-callable.md)
- [The Objective-C Runtime & Swift Dynamism](https://academy.realm.io/posts/mobilization-roy-marmelstein-objective-c-runtime-swift-dynamic/)
- [WWDC 17 #212 What's New in Foundation](https://developer.apple.com/videos/play/wwdc2017/212/)
- [Swift 4 KeyPaths and You](https://klundberg.com/blog/swift-4-keypaths-and-you/)
- [Referencing Objective-C key-paths](https://github.com/apple/swift-evolution/blob/master/proposals/0062-objc-keypaths.md)
- [Key Path Expressions as Functions](https://github.com/apple/swift-evolution/blob/master/proposals/0249-key-path-literal-function-expressions.md)
- [Using Key-Value Observing in Swift](https://developer.apple.com/documentation/swift/cocoa_design_patterns/using_key-value_observing_in_swift)
