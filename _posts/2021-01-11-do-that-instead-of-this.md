---
layout: post
comments: true
title: "Do that instead of this"
categories: article
tags: [iOS, Swift, Objective-C]
excerpt_separator: <!--more-->
comments_id: 23

author:
- kyryl horbushko
- Lviv
---

Sometimes we need to replace some functionality in existing code, but the source is unavailable to us due to some reason. As option developers could use method swizzling - overriding or in other words replacing the original method implementation with a custom one.

Such technic a bit dangerous and in most cases non needed at all and can be replaced with one of some more safe alternatives. We could use this possibility if no other way is visible or just to experiment and investigate some functionality.
<!--more-->

Well, swizzling for iOS originally available thankfully for [`Objective-C` `Runtime`](https://developer.apple.com/documentation/objectivec/objective-c_runtime#//apple_ref/c/func/method_getImplementation). Now, when most iOS developers use swift, this language provides a convenient way to use `Objective-C` swizzling in it and also introduce it's own native wat to swizzle methods.

## Objective-C

Thus method dispatch is handled in runtime by `Objective-C`, this allows us to replace any method implementation in runtime before it will be called. 

Dispatch system use class object's [`isa`](https://developer.apple.com/documentation/objectivec/objc_object/1418809-isa) pointer to get metaclass object. The next step is checking the method's table for the selected metaclass object (or its superclass if not found). 

The trick with swizzling is that when we use it, we exchange the identifiers of two methods so they point to each other’s implementations. As result at runtime, we can call replaced implementation instead of the original one.

To understand how it works we can check an opensource file for [`runtime.h`](https://opensource.apple.com/source/objc4/objc4-437/runtime/runtime.h)

{% highlight c %}
struct objc_method {
    SEL method_name                                          OBJC2_UNAVAILABLE;
    char *method_types                                       OBJC2_UNAVAILABLE;
    IMP method_imp                                           OBJC2_UNAVAILABLE;
}                                                            OBJC2_UNAVAILABLE;
{% endhighlight %}

where:

* `method_name` - an opaque type that represents a method selector ([more](https://developer.apple.com/documentation/objectivec/sel))

`SEL` is a string that hashed according to the method name

{% highlight swift %}
 @selector(viewDidLoad)
 SEL NSSelectorFromString(NSString *aSelectorName)
 SEL method_getName ( Method m );
 ...
{% endhighlight %}

* `method_types` - encoded the return and argument types for method in a character string ([more](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html))
* `method_imp` - a pointer to the start of a method implementation (`typedef id (*IMP)(id self,SEL _cmd,…);`) ([more](https://developer.apple.com/documentation/objectivec/objective-c_runtime/imp))

> few methods can have same `SEL`, to resolve this collision `IMP` used - as u can see in params of `IMP` there is a place for `SEL`.

All this combination used to introduce the `Method` (the type that describes the methods in the class):

{% highlight c %}
typedef struct objc_method *Method;
{% endhighlight %}

To get Method in Objective-C runtime we can use something like this

{% highlight C %}
IMP imp ＝ method_getImplementation(Method m)；
// many more functions available for work with Method 
{% endhighlight %}

> [check official doc for more](https://developer.apple.com/documentation/objectivec/1418551-method_getimplementation)

Now u can see, that to *change implementation* we only need to replace `Method`'s `method_imp` is of type `IMP` using [`method_setImplementation`](https://developer.apple.com/documentation/objectivec/1418707-method_setimplementation).

### Example

The simplest example would be to swizzle some method from `UIViewController`, for example, `viewDidLoad`.

{% highlight objective-c %}
#import "ViewController.h"
#import <objc/runtime.h>

@interface ViewController ()

@end

@implementation ViewController

// Invoked whenever a class or category is added to the Objective-C runtime;
// implement this method to perform class-specific behavior upon loading.

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL viewDidLoadMethodSelector = @selector(viewDidLoad);
        SEL myViewDidLoadMethodSelector = @selector(myViewDidLoad);
        
        Method viewDidLoadMethod = class_getInstanceMethod(self, viewDidLoadMethodSelector);
        Method myViewDidLoadMethod = class_getInstanceMethod(self, myViewDidLoadMethodSelector);
        IMP myViewDidLoadIMP = method_getImplementation(myViewDidLoadMethod);
        IMP viewDidLoadIMP = method_getImplementation(viewDidLoadMethod);
        
        const char * myViewDidLoadEncoding = method_getTypeEncoding(myViewDidLoadMethod);
        const char * viewDidLoadEncoding = method_getTypeEncoding(viewDidLoadMethod);

        BOOL methodAdded = class_addMethod([self class],
                                           viewDidLoadMethodSelector,
                                           myViewDidLoadIMP,
                                           myViewDidLoadEncoding);

        if (methodAdded) {
            class_replaceMethod([self class],
                                myViewDidLoadMethodSelector,
                                viewDidLoadIMP,
                                viewDidLoadEncoding);
        } else {
            
            // This is an atomic version of the following:
            // IMP imp1 = method_getImplementation(m1);
            // IMP imp2 = method_getImplementation(m2);
            // method_setImplementation(m1, imp2);
            // method_setImplementation(m2, imp1);
            method_exchangeImplementations(viewDidLoadMethod, myViewDidLoadMethod);
        }
    });

}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSLog(@"original viewDidLoad called");
}

- (void)myViewDidLoad {
	[self myViewDidLoad]; // will call viewDidLoad !!! During swizzling, myViewDidLoad has been reassigned to the original implementation of UIViewController -viewDidLoad
	
    NSLog(@"my viewDidLoad called");
}

@end
{% endhighlight %}

When u run this code, u should see console output similar to this:

> 2021-01-09 22:36:46.733595+0200 swizzlingObjC[43427:4884488] my viewDidLoad called

### Pitfall

The downside of such swizzling is that if we would like to call the original method then we should execute the swizzled method instead, but `_cmd` that will be passed to the original method will be from a swizzled method. This may be a problem (some part of functionality may depend on `_cmd`).

If we would like to avoid this behavior, we could use the C function for swizzling as suggested by Bryce Buchanan in his article available [here](https://blog.newrelic.com/engineering/right-way-to-swizzle). 

He suggests to use C function that simulates a method (*An Objective-C method is simply a C function that takes at least two arguments—**self** and **_cmd**.* [Apple](https://developer.apple.com/documentation/objectivec/1418901-class_addmethod)) and also leaves no trace (such as additional selector).

{% highlight objective-c %}
#import <objc/runtime.h>

@interface SwizzleExampleClass : NSObject
- (void)swizzleExample;
- (int) originalMethod;
@end

static IMP __original_Method_Imp;
int _replacement_Method(id self, SEL _cmd)
{
    assert([NSStringFromSelector(_cmd) isEqualToString:@"originalMethod"]);
        //code
    int returnValue = ((int(*)(id,SEL))__original_Method_Imp)(self, _cmd);
    return returnValue + 1;
}

@implementation SwizzleExampleClass
- (void) swizzleExample //call me to swizzle
{
    Method m = class_getInstanceMethod([self class],
                                       @selector(originalMethod));
    __original_Method_Imp = method_setImplementation(m,
                                                     (IMP)_replacement_Method);
}
- (int) originalMethod
{
        //code
    assert([NSStringFromSelector(_cmd) isEqualToString:@"originalMethod"]);
    return 1;
}
@end

// test

- (void)testSwizleExample {
    SwizzleExampleClass* example = [[SwizzleExampleClass alloc] init];
    int originalReturn = [example originalMethod];
    [example swizzleExample];
    int swizzledReturn = [example originalMethod];
    assert(originalReturn == 1); //true
    assert(swizzledReturn == 2); //true
}
{% endhighlight %}

> Be careful: This is a sample code that does not contain protection from double swizzling. If u execute this code twice - then u will swizzle IMP by the same IMP and it will cause an infinite loop...


## Swift

`Swift` - is a powerful yet young programming language. It contains a bunch of additions that make programming comfortable and functional. Most swift developers come to it from Objective-C, so we know **the power** of `Runtime`. Thus we change the language, the problems we solve are still the same, so the same situations that may require swizzling may occur. The only question - how.

### Objective-C Runtime usage

The simplest approach - is to use `Runtime` from `Objective-C` in `Swift`:

{% highlight swift %}
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print("original viewDidLoad called")
    }
}

extension ViewController {
    
    @objc dynamic func myViewDidLoad() {
        myViewDidLoad()
        
        print("myViewDidLoad called")
    }
    
    private static let swizzleViewDidLoad: Void = {
        
        let viewDidLoadMethodSelector: Selector = #selector(ViewController.viewDidLoad)
        let myViewDidLoadMethodSelector: Selector = #selector(ViewController.myViewDidLoad)
        
        let viewDidLoadMethod: Method = class_getInstanceMethod(ViewController.self, viewDidLoadMethodSelector)!
        let myViewDidLoadMethod: Method = class_getInstanceMethod(ViewController.self, myViewDidLoadMethodSelector)!

        let myViewDidLoadIMP: IMP = method_getImplementation(myViewDidLoadMethod)
        let viewDidLoadIMP: IMP = method_getImplementation(viewDidLoadMethod)

        let myViewDidLoadEncoding: UnsafePointer<Int8> = method_getTypeEncoding(myViewDidLoadMethod)!
        let viewDidLoadEncoding: UnsafePointer<Int8> = method_getTypeEncoding(viewDidLoadMethod)!

        let methodAdded = class_addMethod(
            ViewController.self,
            viewDidLoadMethodSelector,
            myViewDidLoadIMP,
            myViewDidLoadEncoding
        )
        
        if methodAdded {
            class_replaceMethod(
                ViewController.self,
                myViewDidLoadMethodSelector,
                viewDidLoadIMP,
                viewDidLoadEncoding
            )
        } else {
            method_exchangeImplementations(viewDidLoadMethod, myViewDidLoadMethod)
        }
    }()
    
    static func execute_swizzleViewDidLoad() {
        _ = self.swizzleViewDidLoad
    }
}
{% endhighlight %}

And then somewhere before creating `ViewController`:

{% highlight swift %}
ViewController.execute_swizzleViewDidLoad()
{% endhighlight %}

> Unfortuantly [`+load`](https://developer.apple.com/documentation/objectivec/nsobject/1418815-load) is not available in Swift: 
> 
> *Method 'load()' defines Objective-C class method 'load', which is not permitted by Swift*


Thus this is works, we still need to use `Objective-C` `Runtime` and as u saw `@obj` and `dynamic` attributes for the method. Another moment - we can't use it if the object is not inherited from `NSObject`.

> While the `@objc` attribute exposes your `Swift` API to the `Objective-C` runtime, it does not guarantee dynamic dispatch of a property, method, subscript, or initializer. The `Swift` compiler may still devirtualize or inline member access to optimize the performance of your code, bypassing the `Objective-C` runtime. When you mark a member declaration with the dynamic modifier, access to that member is always dynamically dispatched. Because declarations marked with the dynamic modifier are dispatched using the `Objective-C` runtime, they’re implicitly marked with the `@objc` attribute.
> 
> Requiring dynamic dispatch is rarely necessary. However, **you must use the dynamic modifier when you know that the implementation of an API is replaced at runtime**. For example, you can use the `method_exchangeImplementations` function in the `Objective-C` runtime to swap out the implementation of a method while an app is running. If the `Swift` compiler inlined the implementation of the method or devirtualized access to it, the new implementation would not be used.
> 
> [source](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithObjective-CAPIs.html)

### Swift native swizzling

From `Swift 5.1` **native** functions and method swizzling was introduced.

> Pitch available [here](https://forums.swift.org/t/dynamic-method-replacement/16619)

Now we have `@_dynamicReplacement(for:)` which can handle magic for us.

{% highlight swift %}
class NativeSwiftClass {
    
    dynamic func original() {
        print("original")
    }
}

extension NativeSwiftClass {
    @_dynamicReplacement(for: original)
    func replacement() {
        print("replacement")
    }
}
{% endhighlight %}

> Note: u can't declare `@_dynamicReplacement(for: original)` in class - there is not much sense in it and as result u receive an error
> 
> *DynamicReplacement(for:) of 'replacement' is not defined in an extension or at the file level*

Here also `dynamic` attribute used as before.

> u can skip this attribute if u use `-enable-dynamic-replacement-chaining` compilation flag

Now u may think - what if someone defined few functions as a replacement for one function? 

{% highlight swift %}
class NativeSwiftClass {
    
    dynamic func original() {
        print("original")
    }
}

extension NativeSwiftClass {
    @_dynamicReplacement(for: original)
    func replacement() {
	     original()
        print("replacement")
    }
    
    @_dynamicReplacement(for: original)
    func replacement2() {
	     original()
        print("replacement2")
    }
}
{% endhighlight %}

Be **default** u receive output:

> 1. original
> 2. replacement2 // the latest defined


But there is 2 behavior of swizzling in `Swift`:

- default behavior
- chaining behavior

The difference is simple - if u have multiply swizzling for the same function/method, with **chaining** behavior they will be called one-by-one and with **default** behavior - only first-one.

To enable **chaining** go to BuildSetting->Other Swift Flags -> add `-Xfrontend -enable-dynamic-replacement-chaining`.

Build and run, the output will be as following:

> 1. original
> 2. replacement
> 3. replacement2

Now u have few options to select.

> [Here](https://tech.guardsquare.com/posts/swift-native-method-swizzling/) is an excellent article about both behaviors and how it works under the hood.

## Notes

- Swizzling is danger operation - always try to avoid it unless u understand the process and there is no other way
- With swizzling - make sure that u call it only once - in other cases, u will get an unexpected result
- in Objective-C use `+load` method for u'r class
- remember about an exchange of `IMP`
- If you want to swizzle, the best outcome is to leave no trace [source](https://blog.newrelic.com/engineering/right-way-to-swizzle)
- Follow DRY and extract your swizzling code into a category or extension
- Swizzling is not atomic
- Difficult to debug
- Possible naming conflicts
- If u have a few swizzled methods - the order is matter

[download source code]({% link assets/posts/images/2021-01-11-do-that-instead-of-this/source/source.zip %})

## Resources

- [Objective-C runtime](https://developer.apple.com/documentation/objectivec/objective-c_runtime#//apple_ref/c/func/method_getImplementation)
- [SEL, Method, IMP](https://www.programmersought.com/article/2375992056/)
- [Monkey-Patching iOS with Objective-C Categories Part III: Swizzling
](https://blog.carbonfive.com/monkey-patching-ios-with-objective-c-categories-part-iii-swizzling/)
- [The Right Way to Swizzle in Objective-C](https://blog.newrelic.com/engineering/right-way-to-swizzle/)
- [Method swizzling](https://nshipster.com/method-swizzling/)
- [SO: Danger with swizzling](https://stackoverflow.com/a/8636521/2012219)
- [MethodSwizzling](https://web.archive.org/web/20130308110627/http://cocoadev.com/wiki/MethodSwizzling)
- [Using Swift with Cocoa and Objective-C](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/BuildingCocoaApps/InteractingWithObjective-CAPIs.html)
- [SF: How to use runtime in Swift?](https://forums.swift.org/t/how-to-use-runtime-in-swift/17217)
- [SF: Dynamic method replacement](https://forums.swift.org/t/dynamic-method-replacement/16619)