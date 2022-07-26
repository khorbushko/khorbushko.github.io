---
layout: post
comments: true
title: "c function replacement"
categories: article
tags: [dlyb, dlopen, dlsym, debug]
excerpt_separator: <!--more-->
comments_id: 85

author:
- kyryl horbushko
- Lviv
---

Development is a complex process and consists of a lot of parts. Sometimes we use parts that we didn't write and so have no control over them. 
<!--more-->

In this case, we must think about an alternative solution, or even about partial functionality replacement. To do so we have a lot of techniques. One of them - [swizzling](https://developer.apple.com/documentation/objectivec/objective-c_runtime) was covered in one of my [prev posts]({% post_url 2021-01-11-do-that-instead-of-this %}).

Working with Swift and Obj-c is good, but sometimes not enough, and we may need to use another language for example C. Let's review the way how implementation can be replaced in C.

## C function

For example, let's use for experiment [`atoll`](https://cplusplus.com/reference/cstdlib/atoll/) function - a function that *converts string to long long integer*. In swift this function is declared as:

```
public func atoll(_: UnsafePointer<CChar>!) -> Int64
```

What we need - is a c-style declaration:

```
long long int atoll (const char * str);
```

If we execute the function, we receive the expected output:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-08-01-c-replacement/atoll_original.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-08-01-c-replacement/atoll_original.png" alt="atoll_original.png" width="450"/>
</a>
</div>
<br>
<br>

With the C function it's easy to do a full replacement - just declare a function with the same definition and u done. Let's do this:

```
long long atoll(const char * str) {
  return 100;
}
```

Let's run again the code:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-08-01-c-replacement/atoll_replacement.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-08-01-c-replacement/atoll_replacement.png" alt="atoll_replacement" width="300"/>
</a>
</div>
<br>
<br>

Looks easy. And in most cases it's ok, but sometimes we need to replace functionality only under certain conditions. For such behavior, we need to check this condition and if it's true - call our logic, in other cases - original implementation.

To do so, we need to use some help from [`dyld`](https://github.com/apple-opensource/dyld) (dynamic library loader) with [`dlopen`](https://man7.org/linux/man-pages/man3/dlopen.3.html) and [`dlsym`](https://man7.org/linux/man-pages/man3/dlsym.3.html).

> `dlopen` - The function dlopen() loads the dynamic shared object (shared library) file named by the null-terminated string filename and returns an opaque "handle" for the loaded object.
> 
> `dlsym`, `dlvsym` - obtain the address of a symbol in a shared object or executable

This function helps us to obtain a reference to a module where the target function is declared and implemented and to obtain the function address.

Of cause, this can't be used without our debugger - [`lldb`](https://lldb.llvm.org/index.html). 

We will use a command for dumping the implementation address of the function - `image lookup`:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-08-01-c-replacement/image_lookup_result.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-08-01-c-replacement/image_lookup_result.png" alt="image_lookup_result.png" width="300"/>
</a>
</div>
<br>
<br>

As u can see - I used `image lookup -rn atoll` where:

```
 -n <function-or-symbol> ( --name <function-or-symbol> )
    Lookup a function or symbol by name in one or more target modules.
 -r ( --regex )
    The <name> argument for name lookups is regular expressions.
```

> to look up more check the command `help image lookup`. Note, that `image` - is an abbreviation for `target modules`

`RuntimeRoot` - is a place from where all our code is executed, so the interested path is `usr/lib/system/libsystem_c.dylib`.

The next step - is to obtain the address of our function:

{% highlight c %}
#import <dlfcn.h>
#import <assert.h>

// ... then in u'r function

void *handle;
long long (*original)(const char *);

handle = dlopen("/usr/lib/system/libsystem_c.dylib", RTLD_NOW);
assert(handle);
original = dlsym(handle, "atoll");
{% endhighlight %}

> `handle` will store the reference to the lib, and `original` will hold the original implementation of the `atoll`

Now, we may use some predicate to decide when to use the original implementation and when - our own.

{% highlight c %}
bool needToReplace = strcmp(input, "222") == 0;
if (needToReplace) {
   return 111;
}
{% endhighlight %}

The good moment here - is that we may store our `handle` and `original` as a static variable once and reuse them later. For this we may use singleton pattern and gcd from `#import <dispatch/dispatch.h>`:

{% highlight c %}
static void *handle;
static long long (*original)(const char *);

static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
	handle = dlopen("/usr/lib/system/libsystem_c.dylib", RTLD_NOW);
	assert(handle);
	original = dlsym(handle, "atoll");
});
{% endhighlight %}

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-08-01-c-replacement/demo.gif">
<img src="{{site.baseurl}}/assets/posts/images/2022-08-01-c-replacement/demo.gif" alt="demo.gif" width="300"/>
</a>
</div>
<br>
<br>

<details><summary> Complete solution </summary>
<p>

{% highlight c %}
long long atoll(const char * input) {
  static void *handle;
  static long long (*original)(const char *);

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    handle = dlopen("/usr/lib/system/libsystem_c.dylib", RTLD_NOW);
    assert(handle);
    original = dlsym(handle, "atoll");
  });

  bool needToReplace = strcmp(input, "222") == 0;
  if (needToReplace) {
    return 111;
  }

  return original(input);
}
{% endhighlight %}

</p>
</details>


## resources

* [monkey patch](https://en.wikipedia.org/wiki/Monkey_patch) 
* [obj-c runtime](https://developer.apple.com/documentation/objectivec/objective-c_runtime)
* [`dyld`](https://github.com/apple-opensource/dyld)
* [`dlsym`](https://man7.org/linux/man-pages/man3/dlsym.3.html)
* [`dlopen`](https://man7.org/linux/man-pages/man3/dlopen.3.html)
* [`lldb`](https://lldb.llvm.org/index.html)
* [Advanced apple debugging by Darek S.](https://www.raywenderlich.com/books/advanced-apple-debugging-reverse-engineering/v3.0)