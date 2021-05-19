---
layout: post
comments: true
title: "The LLDB Debugger - Part 3: Watchpoint"
categories: article
tags: [lldb, debug, watchpoint]
excerpt_separator: <!--more-->
comments_id: 44

author:
- kyryl horbushko
- Lviv
---

Debugging - is not just a process for finding and fixing bugs - for me, this is a great way to find out how actually the program works. To do so, we should be able to detect any change at any memory address.

Often, `breakpoints` can help a lot within this task, but for some cases, such technique simply can't help us - imagine a case, when we would like to detect a moment, when some constant is read from the memory, of some variable is write to memory. In other words - when some value at a certain memory address is read or written. Breakpoints have no power here. Of cause, accessors (like getter and setter) can help a lot in some cases, but, not always.
<!--more-->

Watchpoint instead, does not require some instruction in code to be set, all that needs for them - is an address in memory which we would like to monitor and inspect.

Articles in this series:

* [The LLDB Debugger - Part 1: Basics]({% post_url 2021-05-10-the-lldb-debugger-part1-basics %})
* [The LLDB Debugger - Part 2: Breakpoints]({% post_url 2021-05-20-the-lldb-debugger-part2-breakpoints %})
* The LLDB Debugger - Part 3: Watchpoint

## watch the memory

### context

Thus `watchpoint` works with memory address and monitor memory change, we should somehow obtain the address of a variable or use the name of the variable that is available in the current scope. 

If we talking about the name of the variable - everything is quite simple - just use its name. But, if we would like to get a notification when some `ivar` changes (for example in Obj-C), we should use a memory address. To deal with it, we can use the next command:

{% highlight c %}
(lldb) language objc class-table dump <ClassName> -v
{% endhighlight %}

Let's play a bit. First, let's create a class:

{% highlight swift %}
class SomeClass {
  
  var myVariable: String?
  var mySecondVariable: Int?
}
{% endhighlight %}

then, we can create an instance and play a bit with this command:

{% highlight c %}
let classObj = SomeClass()
classObj.mySecondVariable = 2
classObj.myVariable = "Hello world!"    
{% endhighlight %}

The first try:

{% highlight c %}
(lldb) language objc class-table dump SomeClass -v
isa = 0x10219c210 name = _TtC7testApp9SomeClass instance size = 41 num ivars = 0 superclass = _TtCs12_SwiftObject
{% endhighlight %}

Let't add superclass for `SomeClass` as `NSObject` and repeat operation:

{% highlight c %}
(lldb) language objc class-table dump SomeClass -v
isa = 0x1007381f0 name = _TtC7testApp9SomeClass instance size = 33 num ivars = 0 superclass = NSObject
  instance method name = init type = @16@0:8
  instance method name = .cxx_destruct type = v16@0:8
{% endhighlight %}

As u can see, swift doesn't provide direct access to `ivars`, so an alternative to `watchpoints` here is `willGet` and `willSet`. 

Within Obj-C, we can see offset for each `ivar` from the base address. To check this out, let's create a pure Obj-C class:

**`DemoClass.h`**

{% highlight c %}
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DemoClass : NSObject

@property (nonatomic, copy) NSString *someVariable;

@end

NS_ASSUME_NONNULL_END
{% endhighlight %}

**`DemoClass.m`**

{% highlight objc %}
#import "DemoClass.h"

@implementation DemoClass

@end
{% endhighlight %}

And repeating the same operation:

{% highlight c %}
(lldb) po demoClass
<DemoClass: 0x600000794610>

(lldb) language objc class-table dump DemoClass -v
isa = 0x102c54330 name = DemoClass instance size = 16 num ivars = 1 superclass = NSObject
  ivar name = _someVariable type = id size = 8 offset = 8
  instance method name = setSomeVariable: type = v24@0:8@16
  instance method name = someVariable type = @16@0:8
  instance method name = .cxx_destruct type = v16@0:8
{% endhighlight %}

Now, we can see that `ivar` `_someVariable` has size 8 and offset 8. Using this information we can grab the base address and add this offset to get `ivar` memory address.

{% highlight c %}
(lldb) p/x 0x600000794610 + 8
(long) $1 = 0x0000600000794618
// or 
(lldb) print/x 0x600000794610 + 8
(long) $1 = 0x0000600000794618
{% endhighlight %}

> `p` (short for `print`) - is a command available in `lldb` that allows u to format types in a certain manner. `/x` mean `hex`. Here is the full [format list available in `lldb`](https://lldb.llvm.org/use/variable.html).

Here, we grab the base address of the object in the heap and add an offset equal to 8 (according to class-dumb info). As result, we got the address of *`ivar`*, which holds the `NSString` value.

### adding the watchpoint

To add a `watchpoint` we can use the next command:

{% highlight c %}
w e s -- 0x0000600000794618
{% endhighlight %}

> `w e s` is short for `watchpoint expression set` - `lldb` commands can be invoked with a short version of first symbols from commands if there is no conflict within other commands.

Output:

{% highlight c %}
(lldb) w s e -- 0x0000600000794618
Watchpoint created: Watchpoint 1: addr = 0x600000794618 size = 8 state = enabled type = w
    new value: -5147790661703735024
{% endhighlight %}

And here one more helpful command - `list`. These commands similar to the one used within `breakpoints` - simply return the list of available `watchpoints`:

{% highlight c %}
(lldb) watchpoint list
Number of supported hardware watchpoints: 4
Current watchpoints:
Watchpoint 1: addr = 0x600000794618 size = 8 state = enabled type = w
    new value: -5147790661703735024
{% endhighlight %}

Now, we can test this. To do so we should simply update the value of `someVariable`:

{% highlight c %}
(lldb) e -l objc -O -- [((DemoClass *)0x600000794610) setSomeVariable: @"Hello there!"];
{% endhighlight %}

The result will be interrupted due to the existing `watchpoint`:

{% highlight c %}
error: Execution was interrupted, reason: watchpoint 1.
The process has been returned to the state before expression evaluation.
{% endhighlight %}

As u can see, our `watchpoint` works as expected. To be more concrete - u can try to change the variable by any other action (for example button press) - the code will be interrupted and paused on created `watchpoint`.

Also, if we check the current value of the `someVariable` - it's updated as expected:

{% highlight c %}
(lldb) e -l objc -O -- [(DemoClass *)0x600000794610 someVariable];
Hello there!
{% endhighlight %}

We also can check variable directly:

{% highlight c %}
(lldb) po *((__unsafe_unretained NSString **)(0x600000794618));
Hello there!
{% endhighlight %}

> we used here double dereference, because we passing a pointer to `NSString *`, and this pointer also a pointer...
> 
> for debugging purpose we can ommit `__unsafe_unretained` and simply call `*(( NSString **)(0x600000794618));`
> 
> more about [`__unsafe_unretained`](https://clang.llvm.org/docs/AutomaticReferenceCounting.html#semantics). [Here](https://stackoverflow.com/a/8593731/2012219) also a good explanation by [Brad Larson](https://stackoverflow.com/users/19679/brad-larson)

As u can see, `watchpoint` is a powerful tool for monitoring any memory-related changes in objects and variables. Above I mention that we can monitor either address of memory either variable - keep in mind, that under *variable* I mean that we can set `watchpoint` even to some `ivar` inside another object that is currently available in context:

{% highlight c %}
w s variable <objec->ivar>
{% endhighlight %}

> Again, `w s` is just a short for `watchpoint set`

#### options

##### set type

We can also configure few options for `watchpoint set expression`:

{% highlight c %}
-s <byte-size> ( --size <byte-size> )
    Number of bytes to use to watch a region.
    Values: 1 | 2 | 4 | 8

-w <watch-type> ( --watch <watch-type> )
    Specify the type of watching to perform.
    Values: read | write | read_write
{% endhighlight %}

example:

{% highlight c %}
w s e -w write -s 8 -- 0x0000600001414298
{% endhighlight %}

##### set conditions

Another good moment - we can add a condition to `watchpoint` as it was done within `breakpoint` previously. To do so just create `watchpoint` and then modify it using `-c` flag:

{% highlight c %}
(lldb) w l
Number of supported hardware watchpoints: 4
Current watchpoints:
Watchpoint 1: addr = 0x600000b2c568 size = 8 state = enabled type = w
    old value: -8671835945046180749
    new value: -8671835945046279053
    
(lldb) w modify 1 -c '([*(( NSString **)(0x0000600000b2c568)) isEqual:@"15"])'
1 watchpoints modified.

(lldb) w l
Number of supported hardware watchpoints: 4
Current watchpoints:
Watchpoint 1: addr = 0x600000b2c568 size = 8 state = enabled type = w
    old value: -8671835945046180749
    new value: -8671835945046279053
    condition = '([*(( NSString **)(0x0000600000b2c568)) isEqual:@"15"])'
{% endhighlight %}

Here, we list all `watchpoints`, then modify the one using condition: 

*"stop when `someVariable` in `demoClass` instance object isEqual to 15"*. 

> I added a button and increment `tapCount` value, and in `someVariable` stored `stringRepresentation` of `tapCount` value.

When this condition is `true`, watchpoint is called:

{% highlight c %}
Watchpoint 1 hit:
old value: -8671835945046279053
new value: -8671835945046246285
(lldb) po ([*(( NSString **)(0x0000600000b2c568)) isEqual:@"15"])
true

(lldb) po (NSString *)-8671835945046246285
15
{% endhighlight %}

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-05-27-the-lldb-debugger-part3-watchpoint/demo_watchpoint_condition.gif" alt="devToolSec" width="450"/>
</div>
<br>
<br>

### edit

Editing a `watchpoint` can be done using `modify` command. There are not many ways to edit it:

{% highlight c %}
-c <expr> ( --condition <expr> )
    The watchpoint stops only if this condition expression evaluates to true.
{% endhighlight %}

> Real example of modification already shown above :] .

### list

Listing available `watchpoints` also can be done using similar command `list`:

{% highlight c %}
(lldb) w l
//or 
(lldb) watchpoint list
{% endhighlight %}

### delete

To delete a `watchpoint` simple use the same-name command:

{% highlight c %}
(lldb) watchpoint delete 1
(lldb) w delete 1
{% endhighlight %}

> to delete all - simply omit the last param

### understanding context

Setting the `watchpoint` is just a half of the job - another part is to understand whats causes the change.

To do so we can use same commands as we used for `breakpoints` (`thread backtrace` or `frame variable <name>`, etc) ([read about breakpoints here]({% post_url 2021-05-20-the-lldb-debugger-part2-breakpoints %})). 

One more good point to mention is when watchpoint hit, we will see a specific message:

{% highlight c %}
Watchpoint 1 hit:
old value: -8671887165918691125
new value: -8671835945045623701
{% endhighlight %}

This is nothing but values. To check the values:

{% highlight c %}
(lldb) po (NSString *)-8671887165918691125
Hello

(lldb) po (NSString *)-8671835945045623701
Hello there!
{% endhighlight %}

In addition, we can use few more useful commands:

{% highlight c %}
(lldb) disassemble -m -F intel
{% endhighlight %}

On my M1 mac I got an error - unsupported flavor:

{% highlight c %}
(lldb) disassemble -m -F intel
error: Disassembler flavors are currently only supported for x86 and x86_64 targets.
{% endhighlight %}

> read more about this command [here](https://www.raywenderlich.com/books/advanced-apple-debugging-reverse-engineering/v3.0)


Articles in this series:

* [The LLDB Debugger - Part 1: Basics]({% post_url 2021-05-10-the-lldb-debugger-part1-basics %})
* [The LLDB Debugger - Part 2: Breakpoints]({% post_url 2021-05-20-the-lldb-debugger-part2-breakpoints %})
* The LLDB Debugger - Part 3: Watchpoint 


## Resources

* [Watchpoints](https://lldb.llvm.org/use/map.html?highlight=breakpoint#watchpoint-commands)
* [Variable formatting](https://lldb.llvm.org/use/variable.html)
* [Advanced Apple Debugging & Reverse Engineering By Derek Selander](https://www.raywenderlich.com/books/advanced-apple-debugging-reverse-engineering/v3.0)
* [lvalue and rvalue in C language](https://www.geeksforgeeks.org/lvalue-and-rvalue-in-c-language/)
* [ARC Semantics](https://clang.llvm.org/docs/AutomaticReferenceCounting.html#semantics)
* [SO: ARC - The meaning of __unsafe_unretained?](https://stackoverflow.com/questions/8592289/arc-the-meaning-of-unsafe-unretained/8593731)