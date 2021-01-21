---
layout: post
comments: true
title: "iOS entry point"
categories: article
tags: [iOS, lifecycle, attributes]
excerpt_separator: <!--more-->
comments_id: 25

author:
- kyryl horbushko
- Lviv
---

Did u ever wonder, how the program starts? Where is the entry point and how compiler know that he should start from this point? The answer is simple - the entry point is where the first instruction of the program and where the program has access to command-line arguments.

In simple case entry point is the very first address with some instruction. In a more complex system, this may be inside some runtime library or at some known memory address.
<!--more-->

Alternative option - use a named point for an entry point. Named point - is just a name defined by programming language. 

If we switch to iOS development, thus most part use C-family languages under the hood, an entry point for us has the name `main`. 

> Other languages also have similar entry points - in Java entry point also `main`, in C# `Main`.

Let's inspect the iOS app entry point when using different languages and approaches.

## Objective-C

When we create the iOS app and select the primary language like Objective-C, then u can easily find entry point in the project by checking file `main.m`:

{% highlight Objective-C %}
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
{% endhighlight %}

> - `int argc` - count of arguments
> - `char * argv[]` - list of arguments itself
> if u run program like `$ myapp hello`, u will receive `argc` equal to 2 and in `argv` something like:
> 
{% highlight console output %}
/Users/kyryl.horbushko/Desktop/myapp
hello
{% endhighlight %}

That's it. As u can see - the result of the `main` function is a call to [`UIApplicationMain`](https://developer.apple.com/documentation/uikit/1622933-uiapplicationmain) function call. 

This function takes input arguments and the name of the app delegate and instantiates the application object. 

> Here we pass `nil`. for it - so default [`UIApplication`](https://developer.apple.com/documentation/uikit/uiapplication) object one will be used

Another responsibility of this function is to set up the main event loop, including the application’s run loop, and processing events. It also checks metadata and displays UI if it's applicable. This makes the app be alive. 

It's also good to know that this function **never returns**, thus it has return type Int. So while this function executed - u'r app alive, even in the background.

U can also notice that inside there is an `autoreleasepool`. The `autoreleasepool` is a mechanism that allows the system to efficiently manage the memory your application uses as it creates new objects. [source](https://www.informit.com/articles/article.aspx?p=2159356&seqNum=2)

The simplest version (for console app) of the main function may be as follow:

{% highlight swift %}
int main (int argc, const char * argv[]) {
    @autoreleasepool {
       NSLog (@"Hello");
    }
    return 0;
}
{% endhighlight %}

Thus iOS app uses a specific place to run and has additional configurations to be done, `UIApplicationMain` used in addition.

## Swift

Create a new `Swift` project and try to find `main` function, even no `main.m` file:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-01-21-entry-point/swift-nomain.png" alt="swift-nomain" width="250"/>
</div>
<br>

> U can add symbolic breakpoint `main` and the app will be paused on the `main` function. Then use the `bt` command:
> 
{% highlight text %}
(lldb) bt
* thread #1, queue = 'com.apple.main-thread', stop reason = breakpoint 1.2
  * frame #0: 0x0000000100cd82f0 main-Swift`main at main.swift:0
(lldb) 
{% endhighlight %}
>
> As u can see - there is at frame #0 call to function `main`

Instead, u can observe the `@UIApplicationMain` or even the `@main` attribute at a class.

{% highlight swift %}
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
{% endhighlight %}

if use `Swift` 5.3:

{% highlight swift %}
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
{% endhighlight %}

### @UIApplicationMain

When u use an attribute on some class `@UIApplicationMain` u simply told the compiler which class he should use as a parameter to the same old [`UIApplicationMain`](https://developer.apple.com/documentation/uikit/1622933-uiapplicationmain) function that he will synthesize in runtime.

> in compiler source there is a define `SWIFT_ENTRY_POINT_FUNCTION "main"` [source](https://github.com/apple/swift/blob/d121d7d55fbcce8a4b4eb124dea0d045e697e4cb/include/swift/SIL/SILFunction.h#L30)
> 
{% highlight c++ %}
/// The symbol name used for the program entry point function.
#define SWIFT_ENTRY_POINT_FUNCTION "main"
{% endhighlight %}


U may remove this attribute and u'r app will terminate as soon as u run it - that's because the `main` function completes execution and `UIApplicationMain` is not executed and so no object is created.

> with older versions of Swift u may receive an error *Undefined symbols _main*.
> I tested on iOS 14 - and looks like the compiler just generate an empty `main` function

To check that this attribute works exactly as we think, we may try to replace the `@UIApplicationMain` attribute with a concrete implementation of the `UIApplicationMain` function. To do so we may define required input parameters in the file - a subclass of `UIApplication`, `UIApplicationDelegate`, and `CommandLine` args.

{% highlight c++ %}
int UIApplicationMain(int argc, char * _Nullable *argv, NSString *principalClassName, NSString *delegateClassName);
{% endhighlight %}

Then we should create a separate file `main.swift` and add a function in it:

{% highlight c++ %}
import UIKit

UIApplicationMain(
  CommandLine.argc,
  CommandLine.unsafeArgv,
  NSStringFromClass(MyApplication.self),
  NSStringFromClass(AppDelegate.self)
)
{% endhighlight %}

> If u wonder why we should put the code in a separate `main.swift` file, here is the perfect explanation:
> 
> Application Entry Points and “main.swift”
You’ll notice that earlier we said top-level code isn’t allowed in most of your app’s source files. The exception is a special file named “main.swift”, which behaves much like a playground file, but is built with your app’s source code. The “main.swift” file can contain top-level code, and the order-dependent rules apply as well. In effect, the first line of code to run in “main.swift” is implicitly defined as the main entry point for the program. This allows the minimal Swift program to be a single line — as long as that line is in “main.swift”.
> 
> In Xcode, Mac templates default to including a “main.swift” file, but for iOS apps the default for new iOS project templates is to add @UIApplicationMain to a regular Swift file. This causes the compiler to synthesize a main entry point for your iOS app, and eliminates the need for a “main.swift” file.
>
> Alternatively, you can link in the implementation of main written in Objective-C, common when incrementally migrating projects from Objective-C to Swift. [source](https://developer.apple.com/swift/blog/?id=7)

Now, we can run and our app without the attribute `@UIApplicationMain`.

> in Cocoa similar attribute called `@NSApplicationMain`

### @main

With `Swift` 5.3 we got new attribute [`@main` - Type-Based Program Entry Points](https://github.com/apple/swift-evolution/blob/master/proposals/0281-main-attribute.md).

From the official doc, this attribute may be applied to a structure, class, or enumeration declaration to indicate that it contains the top-level entry point for program flow. [source](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html)

The purpose of this attribute is to remove hardcoded attributes for iOS and macOS and instead make code more generic and thus simpler.

As mention in this proposal - *"When the program starts, the `static main()` method is called on the type marked with `@main`. "*.

With @main attribute we also have a few options:

- a single, non-generic type designated with the `@main` attribute
- a single `main.swift` file

So using this, we can define next:

{% highlight swift %}
class MyStartingPoint: EntryPointProvidable { }

protocol EntryPointProvidable { }

extension EntryPointProvidable {
    static func main() {
        print("hello")
    }
}
{% endhighlight %}

and in `main.swift`:

{% highlight swift %}
MyStartingPoint.main()
{% endhighlight %}

As expected, u will see `print` message, but the app will end as soon as it prints it. why? same reason as before - this function didn't initialize an object responsible for the lifecycle of the app, event handling, UI, etc.

> If u would like to use your own entry point, u still need to use function `UIApplicationMain`:
> 
{% highlight swift %}
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
{% endhighlight %}

As result - the `@main` attribute just simplifies a bit our life, reducing the amount of code that needs to be written in case if we still conform to `UIKit` protocol `UIApplicationDelegate`. We receive main, simply because of this:

{% highlight swift %}
extension UIApplicationDelegate {

    public static func main()
}
{% endhighlight %}

So, the purpose of the `@main` attribute is to allow frameworks to easily define custom entry point behavior without additional language features. An example may be [library from Apple](https://github.com/apple/swift-argument-parser)

> A `main.swift` file is always considered to be an entry point, even if it has no top-level code. Because of this, placing the `@main`-designated type in a `main.swift` file is an error.

[download test sources]({% link assets/posts/images/2021-01-21-entry-point/source/tests.zip %})

## Resource

- [`main` in C](https://en.wikipedia.org/wiki/Entry_point#C_and_C.2B.2B)
- [Entry point](https://en.wikipedia.org/wiki/Entry_point)
- [UIApplicationMain](https://developer.apple.com/documentation/uikit/1622933-uiapplicationmain?changes=_6&language=objc)
- [Attributes in Swift](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html)
- [SO related thread](https://stackoverflow.com/questions/24105690/what-is-the-entry-point-of-swift-code-execution/34804518#34804518)
- [Understanding iOS application entry po](https://olszanowski.blog/posts/understanding-ios-app-entrypoint/)
- [`@main` - Type-Based Program Entry Points](https://github.com/apple/swift-evolution/blob/master/proposals/0281-main-attribute.md)