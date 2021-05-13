---
layout: post
comments: true
title: "The LLDB Debugger - Part 2: Breakpoints"
categories: article
tags: [lldb, debug, breakpoint]
excerpt_separator: <!--more-->
comments_id: 43

author:
- kyryl horbushko
- Lviv
---

To correctly prepare the application logic we should define some instructions and execute them at a certain moment, in other words - execute instructions. But, sometimes it's hard to tell if it works in a way, we expect or not.

A great helper here - a `breakpoint` - an ability of our debugger to stop the code execution at some point (with or without some conditions).
<!--more-->

Knowing the main commands and how we can use them, can improve u'r understanding of the code and u'r performance as a developer.

Articles in this series:

* [The LLDB Debugger - Part 1: Basics]({% post_url 2021-05-10-the-lldb-debugger-part1-basics %})
* The LLDB Debugger - Part 2: Breakpoints


## The breakpoint

A breakpoint is a great ability for us, developers. [Last time]({% post_url 2021-05-10-the-lldb-debugger-part1-basics %}), I described some basic usage of `breakpoints` within `lldb`, so check it out for basic usage.

> Check this [official doc](https://lldb.llvm.org/use/map.html?highlight=breakpoint#breakpoint-commands) for all available options

### man

If u don't know how some commands work, the best option is to try it out and check the man page for it.

So, if u type:

```
(lldb) help breakpoint
```

The output will provide for u all necessary information:

{% highlight c %}
Commands for operating on breakpoints (see 'help b' for shorthand.)

Syntax: breakpoint <subcommand> [<command-options>]

The following subcommands are supported:

      clear   -- Delete or disable breakpoints matching the specified source
                 file and line.
      command -- Commands for adding, removing, and listing LLDB commands
                 executed when a breakpoint is hit.
      delete  -- Delete the specified breakpoint(s).  If no breakpoints are
                 specified, delete them all.
      disable -- Disable the specified breakpoint(s) without deleting them.  If
                 none are specified, disable all breakpoints.
      enable  -- Enable the specified disabled breakpoint(s). If no breakpoints
                 are specified, enable all of them.
      list    -- List some or all breakpoints at configurable levels of detail.
      modify  -- Modify the options on a breakpoint or set of breakpoints in
                 the executable.  If no breakpoint is specified, acts on the
                 last created breakpoint.  With the exception of -e, -d, and -i,
                 passing an empty argument clears the modification.
      name    -- Commands to manage name tags for breakpoints
      read    -- Read and set the breakpoints previously saved to a file with
                 "breakpoint write".  
      set     -- Sets a breakpoint or set of breakpoints in the executable.
      write   -- Write the breakpoints listed to a file that can be read in
                 with "breakpoint read".  If given no arguments, writes all
                 breakpoints.

For more help on any particular subcommand, type 'help <command> <subcommand>'.
{% endhighlight %}

U can go on and try to ask for help for each subcommand:

```
(lldb) help br set
```

and so on.

### image

Looking into `man` pages is a good approach, but sometimes u just want to get the required information and that's it. 

To do so, we can use additional details about our code within breakpoints. How do get them? Well, our code is organized in different targets and targets contain different modules. So the idea here is quite simple - we should find interesting details about modules where our code is declared and then, using them, add breakpoints specific to some concrete situation or event.

Luckily for us, there is a bunch of great commands for this (commands for accessing information for one or more target modules) - `target modules`. The abbreviation for this - is `image`.

`image` has subcommands that can do exactly what we want - `lookup`:

```
lookup       -- Look up information within executable and
                dependent shared library images.
```

To get information about some method use the next command:

```
(lldb) image lookup -n "<SymbolName>"
```

As result, u can get something like this:

{% highlight c %}
(lldb) image lookup -n "+[UIViewController initialize]"

1 match found in /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore:
        Address: UIKitCore[0x000000000045f3f8] (UIKitCore.__TEXT.__text + 4573716)
        Summary: UIKitCore`+[UIViewController initialize]
{% endhighlight %}

> different options can improve lookup, for example `-r` - regex

in output for the command above u can see 3 components:

1) place where this method declared (path)
2) address
3) summary with symbol info and module name

In Obj-C, the symbol is just a method declaration with a sign `-` for instance method or `+` for type methods. One more example: `[UILabel setText:]` or `-[UIImage setImage:]`. 

It's good to mention, that there are few special symbols for `UIKit` (similar exists for `AppKit`. Check [this article]({ url_post 2021-02-01-make-xCode-great-again#debug-hints }), where I cover few of the most useful as for me.

By the way, we can check where these symbols declared within `image lookup`:

{% highlight c %}
(lldb) image lookup -n UIColorBreakForOutOfRangeColorComponents

1 match found in /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore:
        Address: UIKitCore[0x00000000006e188c] (UIKitCore.__TEXT.__text + 7204520)
        Summary: UIKitCore`UIColorBreakForOutOfRangeColorComponents
{% endhighlight %}

Such symbol's syntax is valid for Obj-C language. 

For Swift, syntax a bit different - we should use next: `Module.Type.Method`. 

To be more precise, let's create a new class:

{% highlight swift %}
class SomeClass {
  
  func myFunc() {
    
  }
  
  func myFunc(_ input: Bool) {
    
  }
  
  func myFunc(_ input: Bool) -> Bool {
    true
  }
}
{% endhighlight %}

Now, we can use `image lookup -n MyApp.SomeClass.myFunc` - everything that **contains** *myFunc* will be displayed:

{% highlight c %}
(lldb) image lookup -n MyApp.SomeClass.myFunc

3 matches found in /Users/khb/Library/Developer/Xcode/DerivedData/MyApp-eumhnhiegfnqadgozrowpiypmkyc/Build/Products/Debug-iphonesimulator/MyApp.app/MyApp:
        Address: MyApp[0x000000010000b344] (MyApp.__TEXT.__text + 40252)
        Summary: MyApp`MyApp.SomeClass.myFunc() -> () at SomeClass.swift:30        Address: MyApp[0x000000010000b358] (MyApp.__TEXT.__text + 40272)
        Summary: MyApp`MyApp.SomeClass.myFunc(Swift.Bool) -> () at SomeClass.swift:34        Address: MyApp[0x000000010000b37c] (MyApp.__TEXT.__text + 40308)
        Summary: MyApp`MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool at SomeClass.swift:38
{% endhighlight %}

Here u can see, that we have 3 symbols for method in swift:

{% highlight swift %}
MyApp.SomeClass.myFunc() -> ()
MyApp.SomeClass.myFunc(Swift.Bool) -> ()
MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool
{% endhighlight %}

These are exactly symbols that we should use when we have to deal with within Swift.

> By the way, when we stop an app, by default context is set to Obj-C language. To switch it into another language u may use `-l` parameter, where value - one of the supported languages.
> 
> to get a list of supported languages - `help language`

{% highlight c %}
The following subcommands are supported:

cplusplus    -- Commands for operating on the C++ language 
                 runtime.
objc         -- Commands for operating on the Objective-C 
                language runtime.
renderscript -- Commands for operating on the RenderScript 
                runtime.
swift        -- A set of commands for operating on the Swift
				   Language Runtime.
{% endhighlight %}

Now, we can use this knowledge to be able to create any symbolic breakpoint, even to code, to which we haven't access:

{% highlight c %}
(lldb) breakpoint set --name 'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool'

Breakpoint 5: where = MyApp`MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool + 32 at SomeClass.swift:40:3, address = 0x0000000100e7339c

(lldb) breakpoint list

Current breakpoints:
5: names = {'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool', 'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool'}, locations = 1, resolved = 1, hit count = 0
  5.1: where = MyApp`MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool + 32 at SomeClass.swift:40:3, address = 0x0000000100e7339c, resolved, hit count = 0 
{% endhighlight %}

> The `b` command and the `breakpoint set` command are quite different.  `b` is a DWIM type command that tries as much as possible to emulate the gdb breakpoint parser's syntax. It eventually dispatches to `break set with the appropriate breakpoint type. [source](https://stackoverflow.com/a/42794996/2012219)

We can also use `rb` command - `rb` is an abbreviation for `breakpoint set -r %1`. This command has a lot of options. Most used are:

* -n - Set the breakpoint by function name
* -l - Specifies the line number on which to set this breakpoint
* -i - Set the number of times this breakpoint is skipped before stopping
* -s - Specify scope
* -f - Specifies the source file in which to set this breakpoint
* -F - Set the breakpoint by fully qualified function names
* -A - All files are searched for source pattern matches
* -C - Add command that can be run when br is hit

> to get more run `help rb`

Run `rb .` - this will create a breakpoint on everything :).

### command on hit

A very interesting option that can be used within `breakpoint set` is `-C`. According to doc - *A command to run when the breakpoint is hit can be provided more than once, the commands will get run in order left to right.* 

This is how in xCode u can specify few actions when a breakpoint hit has occurred. Within `lldb` console this can be done as follow:

{% highlight c %}
(lldb) breakpoint set --name 'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool' -C "po Hello" -C "po $arg1"

Breakpoint 10: where = MyApp`MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool + 32 at SomeClass.swift:40:3, address = 0x0000000100e7339c

(lldb) breakpoint list

Current breakpoints:
10: names = {'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool', 'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool'}, locations = 1, resolved = 1, hit count = 0
    Breakpoint commands:
      po Hello
      po $arg1

  10.1: where = MyApp`MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool + 32 at SomeClass.swift:40:3, address = 0x0000000100e7339c, resolved, hit count = 0 
{% endhighlight %}

Another option - is to use `breakpoint command add <ID of breakpoint>`:

{% highlight c %}
(lldb) breakpoint list

Current breakpoints:
10: names = {'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool', 'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool'}, locations = 1, resolved = 1, hit count = 0
    Breakpoint commands:
      po Hello
      po $arg1

Condition: x == 999

  10.1: where = MyApp`MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool + 32 at SomeClass.swift:40:3, address = 0x0000000100e7339c, resolved, hit count = 0 

(lldb) breakpoint command add 10.1
Enter your debugger command(s).  Type 'DONE' to end.
> bt
> DONE

(lldb) breakpoint list

Current breakpoints:
10: names = {'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool', 'MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool'}, locations = 1, resolved = 1, hit count = 0
    Breakpoint commands:
      po Hello
      po $arg1

Condition: x == 999

  10.1: where = MyApp`MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool + 32 at SomeClass.swift:40:3, address = 0x0000000100e7339c, resolved, hit count = 0 
    Breakpoint commands:
      bt
{% endhighlight %}


### conditions

It's also good to know how to set some conditions for `breakpoint` - `-c` or `--condition`.

```
-c <expr> ( --condition <expr> )
          The breakpoint stops only if this condition 
          expression evaluates to true.
```

Let's modify our function in `SomeClass`:

{% highlight swift %}
func myFunc(_ input: Bool) -> Bool {
	var x = 0
	repeat {
	  x += 1
	} while x < 1000
	    
	return true
}
{% endhighlight %}

And now, we can add a condition for the previously added breakpoint:

{% highlight c %}
(lldb) breakpoint list

Current breakpoints:
10: names = {'Signals.SwiftTestClass.myFunc(Swift.Bool) -> Swift.Bool', 'Signals.SwiftTestClass.myFunc(Swift.Bool) -> Swift.Bool'}, locations = 1, resolved = 1, hit count = 0
    Breakpoint commands:
      po Hello
      po $arg1

  10.1: where = Signals`Signals.SwiftTestClass.myFunc(Swift.Bool) -> Swift.Bool + 32 at SwiftTestClass.swift:40:3, address = 0x0000000100e7339c, resolved, hit count = 0 

(lldb) breakpoint modify -c "x == 999" 10

(lldb) breakpoint list
Current breakpoints:
10: names = {'Signals.SwiftTestClass.myFunc(Swift.Bool) -> Swift.Bool', 'Signals.SwiftTestClass.myFunc(Swift.Bool) -> Swift.Bool'}, locations = 1, resolved = 1, hit count = 0
    Breakpoint commands:
      po Hello
      po $arg1

Condition: x == 999

  10.1: where = Signals`Signals.SwiftTestClass.myFunc(Swift.Bool) -> Swift.Bool + 32 at SwiftTestClass.swift:40:3, address = 0x0000000100e7339c, resolved, hit count = 0 
{% endhighlight %}

> here I also used `modify` command to edit and change the existing breakpoint. But u can use `-c` argument even when u create a breakpoint.

To remove condition - set if blank - `-c ""`.

### modification

As was shown in the previous example, we can modify the breakpoint. Other options are (from [Apple doc](https://developer.apple.com/library/archive/documentation/General/Conceptual/lldb-guide/chapters/C3-Breakpoints.html)):

* `--condition` (`-c`) Specifies an expression that must evaluate to true in order for the breakpoint to stop
* `--ignore-count` (`-i`) Specifies the number of times the breakpoint is skipped before stopping
* `--one-shot` (`-o`) Removes the breakpoint the first time it stops
* `--queue-name` (`-q`) Specifies the name of the queue on which the breakpoint stops
* `--thread-name` (`-T`) Specifies the name of the thread on which the breakpoint stops
* `--thread-id` (`-t`) Specifies the ID (TID) of the thread on which the breakpoint stops
* `--thread-index` (`-x`) Specifies the index of the thread on which the breakpoint stops


### errors

Another useful feature is the ability to set a breakpoint to any error in Swift or Objective-C:

```
(lldb) breakpoint set -E Swift 
(lldb) breakpoint set -E objc
```

In addition, we can add the concrete type (exception-typename) for such breakpoint using `-O` option:

```
(lldb) breakpoint set -E Swift -O MyErrorType
```

### managing

This is a simple one and easy-to-remember :)

1. To list breakpoints use `list` command. 
2. To disable breakpoints use `disable` command. 
3. To delete breakpoints use `delete` command.

### support

#### stepping 

Often it's useful to make the next step from a stopped point. For this purpose, we can use `thread step-in` command. Keep in mind, that using `-c` option we can tell how many steps to do at once.

Another supportive command - `thread step-over` performs stepping-over calls.

There are a few more options related to the stepping process:

`step-out`, `step-in`, `step-scripted`, `step-inst-over` - run `help` within them to inspect and play a bit with them!

#### backtrace

Sometimes, we also would like to see a full stack of information - in this case, `thread backtrace` or simply `bt` is very helpful.

{% highlight c %}
(lldb) bt
* thread #1, queue = 'com.apple.main-thread', stop reason = signal SIGSTOP
* frame #0: 0x00000001bc9fe470 libsystem_kernel.dylib`mach_msg_trap + 8
...
{% endhighlight %}

#### type look

`type look` another helpful command that can quickly review type definition without switching context:

{% highlight swift %}
(lldb) type look Hashable
protocol Hashable : Swift.Equatable {
  var hashValue: Swift.Int { get }
  func hash(into hasher: inout Swift.Hasher)
  func _rawHashValue(seed: Swift.Int) -> Swift.Int
}
extension Hashable {
  @inlinable @inline(__always) func _rawHashValue(seed: Swift.Int) -> Swift.Int
}
{% endhighlight %}

#### variable

And of cause inspecting the variable can be done using `frame variable`.

#### sharing

To share breakpoint using a file, we can use command `write` and `read` :

{% highlight c %}
(lldb) breakpoint write -f /Users/khb/Desktop/breakpoints.txt
{% endhighlight %}

Result - file with current breakpoints:

{% highlight json %}
[
  {
    "Breakpoint": {
      "BKPTOptions": {
        "AutoContinue": false,
        "BKPTCMDData": {
          "ScriptSource": "None",
          "StopOnError": true,
          "UserSource": [
            "po Hello",
            "po $arg1"
          ]
        },
        "ConditionText": "",
        "EnabledState": true,
        "IgnoreCount": 0,
        "OneShotState": false
      },
      "BKPTResolver": {
        "Options": {
          "NameMask": [
            56,
            24
          ],
          "Offset": 0,
          "SkipPrologue": true,
          "SymbolNames": [
            "MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool",
            "MyApp.SomeClass.myFunc(Swift.Bool) -> Swift.Bool"
          ]
        },
        "Type": "SymbolName"
      },
      "Hardware": false,
      "SearchFilter": {
        "Options": {},
        "Type": "Unconstrained"
      }
    }
  }
]
{% endhighlight %}

Export can be done using next command

{% highlight c %}
(lldb) breakpoint read -f /Users/khb/Desktop/breakpoints.txt
{% endhighlight %}

or load from the file

{% highlight c %}
lldb -S /Users/khb/Desktop/breakpoints.txt
{% endhighlight %}

## Conclusion

Breakpoints - are great when u need to stop and inspect the code and variables around. Thankfully to `lldb` they have rich support of most required and commonly used commands.

Knowing the name of the operation (`breakpoint`) and a `help` command can provide for u additional benefits during application development.

<br>

Articles in this series:

* [The LLDB Debugger - Part 1: Basics]({% post_url 2021-05-10-the-lldb-debugger-part1-basics %})
* The LLDB Debugger - Part 2: Breakpoints

## Resources

* [Breakpoints in LLDB](https://lldb.llvm.org/use/map.html?highlight=breakpoint#breakpoint-commands)
* [Managing Breakpoints](https://developer.apple.com/library/archive/documentation/General/Conceptual/lldb-guide/chapters/C3-Breakpoints.html)
* [Advanced Apple Debugging & Reverse Engineering By Derek Selander](https://www.raywenderlich.com/books/advanced-apple-debugging-reverse-engineering/v3.0)
* [lldb cheat sheet](https://www.nesono.com/sites/default/files/lldb%20cheat%20sheet.pdf)
* [Advanced Debugging with Xcode and LLDB #412](https://developer.apple.com/videos/play/wwdc2018/412/)
* [Improve debugging efficiency](http://www.topcoder.com/thrive/articles/Improve%20Debugging%20Efficiency%20with%20LLDB)