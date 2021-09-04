---
layout: post
comments: true
title: "Watch u'r language"
categories: article
tags: [swift, SIL, codeStyle, asm, swiftc, compiler]
excerpt_separator: <!--more-->
comments_id: 57

author:
- kyryl horbushko
- Lviv
---

Code style always important. There are a lot of various rules which if followed can greatly improve the code quality - [S.O.L.I.D.](https://en.wikipedia.org/wiki/SOLID), [GRASP](https://en.wikipedia.org/wiki/GRASP_(object-oriented_design)), [KISS](https://en.wikipedia.org/wiki/KISS_principle), [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself), [OAOO](http://wiki.c2.com/?OnceAndOnlyOnce), [YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it), etc. 

But why is so important? Does the compiler care about the quality of the code? 
<!--more-->

To answer this question we should dive a bit into the process of how the compiler work.

## SIL

Below the scheme shows how swift code transformed into machine code:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-09-05-watch-your-language/compiler.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-09-05-watch-your-language/compiler.png" alt="all_styles_iOS" width="750"/>
</a>
</div>
<br>
<br>

One of the most interesting things here is SIL - Swift Intermediate Language. SIL can be used for analyzing data flow, optimization, generic specification, etc.

In another world - code is converted to a specific representation, that is much easier for the compiler to optimize. And this is a perfect place to review how exactly our code (with good quality or without it) is processed.

> SIL use Static Single Assignment notation. SSA allows representing program code as a graph. Every value is assigned only once, all is simplified and optimized. As shown above, SIL can be represented as RAW SIL (`swiftc -O -emit-silgen FILE.swift > OUTPUT.rawsil`) and as Canonical SIL (`swiftc -O -emit-sil FILE.swift > OUTPUT.sil`).

SIL:

* Represents program semantics
* Specially created for code generation and analysis
* The place where SIL is created/used - is in an optimized position for SIL main tasks
* Bridges source and LLVM

### Code to investigate

To explore SIL and all components let's create a very simple code example.

Let's create some functions that replace optional values with the default value.

The very first version can look like this:

{% highlight swift %}
func valueOfDefault(value: String?, defaultValue: String) -> String {
  value ?? defaultValue
}
{% endhighlight %}

We can improve this by adding additional abstractions and supportive features from the Swift language. We can add:

- generics - to cover more types

{% highlight swift %}
func valueOfDefault1<T>(value: T?, defaultValue: T) -> T {
  value ?? defaultValue
}
{% endhighlight %}

> more about [generics](https://docs.swift.org/swift-book/LanguageGuide/Generics.html)

- add support for higher-order functions - to meet functional programming

{% highlight swift %}
func valueOfDefault2<T>(value: @autoclosure () -> T?, defaultValue: @autoclosure () -> T) -> T {
  value() ?? defaultValue()
}
{% endhighlight %}

> more about [`@autoclosure`](https://docs.swift.org/swift-book/LanguageGuide/Closures.html#ID543)

- add error handling

{% highlight swift %}
func valueOfDefault3<T>(value: @autoclosure () throws -> T?, defaultValue: @autoclosure () throws -> T) rethrows -> T {
  try value() ?? (try defaultValue())
}
{% endhighlight %}

> more about [error handling](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html)

- minimize the overhead of function call

{% highlight swift %}
@inlinable
func valueOfDefault4<T>(value: @autoclosure () throws -> T?, defaultValue: @autoclosure () throws -> T) rethrows -> T {
  try value() ?? (try defaultValue())
}
{% endhighlight %}

> more about [`@inlinable`](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html#ID587)


### SIL Representation

If we generate SIL from this code, we can get a set of instructions, that can help us to demystify and answer the question

<details><summary>SIL output</summary>
<p>

{% highlight sil %}
sil_stage canonical

import Builtin
import Swift
import SwiftShims

import Foundation

@inlinable func valueORDefault<T>(value: @autoclosure () throws -> T?, defaultValue: @autoclosure () throws -> T) rethrows -> T

@_hasStorage @_hasInitialValue var optionalValue: String? { get set }

@_hasStorage @_hasInitialValue let defaultValue: String { get }

func test__1() -> String

func test__2() -> String

// optionalValue
sil_global hidden @$s4test13optionalValueSSSgvp : $Optional<String>

// defaultValue
sil_global hidden [let] @$s4test12defaultValueSSvp : $String

// main
sil @main : $@convention(c) (Int32, UnsafeMutablePointer<Optional<UnsafeMutablePointer<Int8>>>) -> Int32 {
bb0(%0 : $Int32, %1 : $UnsafeMutablePointer<Optional<UnsafeMutablePointer<Int8>>>):
  alloc_global @$s4test13optionalValueSSSgvp      // id: %2
  %3 = global_addr @$s4test13optionalValueSSSgvp : $*Optional<String> // user: %12
  %4 = integer_literal $Builtin.Int64, 7142820568359510089 // user: %5
  %5 = struct $UInt64 (%4 : $Builtin.Int64)       // user: %8
  %6 = integer_literal $Builtin.Int64, -1369093851227724177 // user: %7
  %7 = value_to_bridge_object %6 : $Builtin.Int64 // user: %8
  %8 = struct $_StringObject (%5 : $UInt64, %7 : $Builtin.BridgeObject) // user: %9
  %9 = struct $_StringGuts (%8 : $_StringObject)  // user: %10
  %10 = struct $String (%9 : $_StringGuts)        // user: %11
  %11 = enum $Optional<String>, #Optional.some!enumelt, %10 : $String // user: %12
  store %11 to %3 : $*Optional<String>            // id: %12
  alloc_global @$s4test12defaultValueSSvp         // id: %13
  %14 = global_addr @$s4test12defaultValueSSvp : $*String // user: %22
  %15 = integer_literal $Builtin.Int64, 7366009   // user: %16
  %16 = struct $UInt64 (%15 : $Builtin.Int64)     // user: %19
  %17 = integer_literal $Builtin.Int64, -2089670227099910144 // user: %18
  %18 = value_to_bridge_object %17 : $Builtin.Int64 // user: %19
  %19 = struct $_StringObject (%16 : $UInt64, %18 : $Builtin.BridgeObject) // user: %20
  %20 = struct $_StringGuts (%19 : $_StringObject) // user: %21
  %21 = struct $String (%20 : $_StringGuts)       // user: %22
  store %21 to %14 : $*String                     // id: %22
  %23 = integer_literal $Builtin.Int32, 0         // user: %24
  %24 = struct $Int32 (%23 : $Builtin.Int32)      // user: %25
  return %24 : $Int32                             // id: %25
} // end sil function 'main'

// valueORDefault<A>(value:defaultValue:)
sil @$s4test14valueORDefault0B012defaultValuexxSgyKXK_xyKXKtKlF : $@convention(thin) <T> (@noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out Optional<τ_0_0>, @error Error) for <T>, @noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out τ_0_0, @error Error) for <T>) -> (@out T, @error Error) {
// %0 "$return_value"                             // users: %14, %12
// %1 "value"                                     // users: %6, %3
// %2 "defaultValue"                              // users: %14, %4
bb0(%0 : $*T, %1 : $@noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out Optional<τ_0_0>, @error Error) for <T>, %2 : $@noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out τ_0_0, @error Error) for <T>):
  debug_value %1 : $@noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out Optional<τ_0_0>, @error Error) for <T>, let, name "value", argno 1 // id: %3
  debug_value %2 : $@noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out τ_0_0, @error Error) for <T>, let, name "defaultValue", argno 2 // id: %4
  %5 = alloc_stack $Optional<T>                   // users: %9, %19, %22, %23, %29, %6
  try_apply %1(%5) : $@noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out Optional<τ_0_0>, @error Error) for <T>, normal bb1, error bb7 // id: %6

bb1(%7 : $()):                                    // Preds: bb0
  %8 = alloc_stack $Optional<T>                   // users: %10, %18, %21, %11, %9
  copy_addr %5 to [initialization] %8 : $*Optional<T> // id: %9
  switch_enum_addr %8 : $*Optional<T>, case #Optional.some!enumelt: bb2, case #Optional.none!enumelt: bb3 // id: %10

bb2:                                              // Preds: bb1
  %11 = unchecked_take_enum_data_addr %8 : $*Optional<T>, #Optional.some!enumelt // user: %12
  copy_addr [take] %11 to [initialization] %0 : $*T // id: %12
  br bb6                                          // id: %13

bb3:                                              // Preds: bb1
  try_apply %2(%0) : $@noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out τ_0_0, @error Error) for <T>, normal bb4, error bb5 // id: %14

bb4(%15 : $()):                                   // Preds: bb3
  br bb6                                          // id: %16

// %17                                            // user: %20
bb5(%17 : $Error):                                // Preds: bb3
  dealloc_stack %8 : $*Optional<T>                // id: %18
  destroy_addr %5 : $*Optional<T>                 // id: %19
  br bb8(%17 : $Error)                            // id: %20

bb6:                                              // Preds: bb4 bb2
  dealloc_stack %8 : $*Optional<T>                // id: %21
  destroy_addr %5 : $*Optional<T>                 // id: %22
  dealloc_stack %5 : $*Optional<T>                // id: %23
  %24 = tuple ()                                  // user: %25
  return %24 : $()                                // id: %25

// %26                                            // user: %27
bb7(%26 : $Error):                                // Preds: bb0
  br bb8(%26 : $Error)                            // id: %27

// %28                                            // user: %30
bb8(%28 : $Error):                                // Preds: bb5 bb7
  dealloc_stack %5 : $*Optional<T>                // id: %29
  throw %28 : $Error                              // id: %30
} // end sil function '$s4test14valueORDefault0B012defaultValuexxSgyKXK_xyKXKtKlF'

// test__1()
sil hidden @$s4test0A3__1SSyF : $@convention(thin) () -> @owned String {
bb0:
  %0 = global_addr @$s4test13optionalValueSSSgvp : $*Optional<String> // user: %1
  %1 = begin_access [read] [dynamic] [no_nested_conflict] %0 : $*Optional<String> // users: %3, %2
  %2 = load %1 : $*Optional<String>               // users: %15, %4, %5
  end_access %1 : $*Optional<String>              // id: %3
  switch_enum %2 : $Optional<String>, case #Optional.some!enumelt: bb1, case #Optional.none!enumelt: bb2 // id: %4

bb1:                                              // Preds: bb0
  %5 = unchecked_enum_data %2 : $Optional<String>, #Optional.some!enumelt // user: %6
  br bb3(%5 : $String)                            // id: %6

bb2:                                              // Preds: bb0
  %7 = global_addr @$s4test12defaultValueSSvp : $*String // user: %8
  %8 = load %7 : $*String                         // users: %9, %13
  %9 = struct_extract %8 : $String, #String._guts // user: %10
  %10 = struct_extract %9 : $_StringGuts, #_StringGuts._object // user: %11
  %11 = struct_extract %10 : $_StringObject, #_StringObject._object // user: %12
  strong_retain %11 : $Builtin.BridgeObject       // id: %12
  br bb3(%8 : $String)                            // id: %13

// %14                                            // user: %16
bb3(%14 : $String):                               // Preds: bb1 bb2
  retain_value %2 : $Optional<String>             // id: %15
  return %14 : $String                            // id: %16
} // end sil function '$s4test0A3__1SSyF'

// test__2()
sil hidden @$s4test0A3__2SSyF : $@convention(thin) () -> @owned String {
bb0:
  %0 = global_addr @$s4test13optionalValueSSSgvp : $*Optional<String> // user: %1
  %1 = begin_access [read] [dynamic] [no_nested_conflict] %0 : $*Optional<String> // users: %2, %3
  %2 = load %1 : $*Optional<String>               // users: %15, %5, %4
  end_access %1 : $*Optional<String>              // id: %3
  switch_enum %2 : $Optional<String>, case #Optional.some!enumelt: bb1, case #Optional.none!enumelt: bb2 // id: %4

bb1:                                              // Preds: bb0
  %5 = unchecked_enum_data %2 : $Optional<String>, #Optional.some!enumelt // user: %6
  br bb3(%5 : $String)                            // id: %6

bb2:                                              // Preds: bb0
  %7 = global_addr @$s4test12defaultValueSSvp : $*String // user: %8
  %8 = load %7 : $*String                         // users: %13, %9
  %9 = struct_extract %8 : $String, #String._guts // user: %10
  %10 = struct_extract %9 : $_StringGuts, #_StringGuts._object // user: %11
  %11 = struct_extract %10 : $_StringObject, #_StringObject._object // user: %12
  strong_retain %11 : $Builtin.BridgeObject       // id: %12
  br bb3(%8 : $String)                            // id: %13

// %14                                            // user: %16
bb3(%14 : $String):                               // Preds: bb1 bb2
  retain_value %2 : $Optional<String>             // id: %15
  return %14 : $String                            // id: %16
} // end sil function '$s4test0A3__2SSyF'



// Mappings from '#fileID' to '#filePath':
//   'test/test.swift' => '/Users/khb/Desktop/test.swift'
{% endhighlight %}

</p>
</details>
<br>

As u can see, this is SIL canonical output, thus we used `-emit-sil` params.

`sil_stage canonical`

The next part - is imports of required components:

{% highlight sil %}
import Builtin
import Swift
import SwiftShims

import Foundation
{% endhighlight %}

and declaration of all components:

{% highlight sil %}
@inlinable func valueORDefault<T>(value: @autoclosure () throws -> T?, defaultValue: @autoclosure () throws -> T) rethrows -> T

@_hasStorage @_hasInitialValue var optionalValue: String? { get set }

@_hasStorage @_hasInitialValue let defaultValue: String { get }

func test__1() -> String

func test__2() -> String

// optionalValue
sil_global hidden @$s4test13optionalValueSSSgvp : $Optional<String>

// defaultValue
sil_global hidden [let] @$s4test12defaultValueSSvp : $String
{% endhighlight %}

In the next part, we can see `@main` - the entry point. As u know, swift code can be written in the empty file at global scope, SIL generates the entry point anyway - all code from our program is situated inside this function.

The code inside tells us next: at the left side there are pseudo-register values and at the right side instruction with various params and comments that contains the result from the instruction.

> As u can see all functions and params have slightly different names with a prefix, suffix, and some other additions - they are mangled. More about this process can be found in [official doc.](https://github.com/apple/swift/blob/main/docs/ABI/Mangling.rst)

For example, from generated code u can see that value from `%11` will be stored to `%3`: 

{% highlight sil %}
store %11 to %3 : $*Optional<String>            // id: %12
{% endhighlight %}

where `%3` is a reference to the address of a global variable initialized in pres step:

{% highlight sil %}
// storage for a global variable
alloc_global @$s4test13optionalValueSSSgvp      // id: %2
// reference to the address of a global variable from prev step
%3 = global_addr @$s4test13optionalValueSSSgvp : $*Optional<String> // user: %12
...

// create enum for Optional string 
%11 = enum $Optional<String>, #Optional.some!enumelt, %10 : $String // user: %12
{% endhighlight %}

> as u know optional is just a enum with 2 cases - `.none` and `.some(T)`. To get more info - check out the header file.

All other instructions in the `@main` function declare and create all values that are needed for our code.

Next in the generated code is a function. All functions in SIL starts within `sil` keyword and has a mangled name:

{% highlight sil %}
// valueORDefault<A>(value:defaultValue:)
sil @$s4test14valueORDefault0B012defaultValuexxSgyKXK_xyKXKtKlF : $@convention(thin) <T> (@noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out Optional<τ_0_0>, @error Error) for <T>, @noescape @callee_guaranteed @substituted <τ_0_0> () -> (@out τ_0_0, @error Error) for <T>) -> (@out T, @error Error) {
// %0 "$return_value"                             // users: %14, %12
// %1 "value"                                     // users: %6, %3
// %2 "defaultValue"                              // users: %14, %4
{% endhighlight %}

where 

`@$s4test14valueORDefault0B012defaultValuexxSgyKXK_xyKXKtKlF` is name for `valueORDefault<A>`

> Mangled name needed for creating a unique name for function in diff modules with the same name and for overloaded functions (that's why u can find the name of the input arguments in the function name).

After we can see a few `basic blocks` - `bb`.

> From the [official doc](https://github.com/apple/swift/blob/main/docs/SIL.rst#basic-blocks): *A function body consists of one or more basic blocks that correspond to the nodes of the function's control flow graph. Each basic block contains one or more instructions and ends with terminator instruction. The function's entry point is always the first basic block in its body.*

The content of this block is not important for us right now. The most interesting part is how our functions that use the same logic but various logic implementation are translated into SIL.

{% highlight sil %}
// test__1()
sil hidden @$s4test0A3__1SSyF : $@convention(thin) () -> @owned String {
{% endhighlight %}

and

{% highlight sil %}
// test__2()
sil hidden @$s4test0A3__2SSyF : $@convention(thin) () -> @owned String {
{% endhighlight %}

In both cases, we have 4 basic blocks - `bb0-bb3`.

`bb0`:
 - create a reference to the address of a global variable
 - begins access to the target memory
 - loads the value at a specific address from memory
 - ends an access
 - conditionally branches to one of several destinations basic blocks

`bb1`:
 - unsafely extracts the payload data for an enum
 - unconditionally transfers control from the current basic block to the block labeled

`bb2`: 
 - create a reference to the address of a global variable
 - loads the value at a specific address from memory
 - extracts a physical field from a loadable struct value
 - extracts a physical field from a loadable struct value
 - extracts a physical field from a loadable struct value
 - increases the strong retain count of the heap object referenced by specific ref
 - unconditionally transfers control from the current basic block to the block labeled

`bb3`: 
 - retains a loadable value, which simply retains any references it holds at a specific ref
 - exits the current function and returns control to the calling function
 
Now, let's compare the result of the simple nil-coalescing operator and our well-crafted function:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-09-05-watch-your-language/comparison.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-09-05-watch-your-language/comparison.png" alt="all_styles_iOS" width="750"/>
</a>
</div>
<br>
<br>

As u can see - they are identical, except for the values. Remember - we are at SIL level - and according to swift compiler there are a lot of additional steps until we can get an assembly - machine code.

Let's do this: run `swiftc -O -emit-assembly INPUT.swift > OUTPUT.asm`.

This will generate the assembly file. For our example it may look like next:

{% highlight asm %}
	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 11, 0	sdk_version 11, 3
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4
lCPI0_0:
	.quad	7142820568359510089
	.quad	-1369093851227724177
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_main
	.p2align	2
_main:
Lloh0:

....

	.weak_reference __swift_FORCE_LOAD_$_swiftXPC
.subsections_via_symbols
{% endhighlight %}

<details><summary>Whole output</summary>
<p>

{% highlight asm %}
	.section	__TEXT,__text,regular,pure_instructions
	.build_version macos, 11, 0	sdk_version 11, 3
	.section	__TEXT,__literal16,16byte_literals
	.p2align	4
lCPI0_0:
	.quad	7142820568359510089
	.quad	-1369093851227724177
	.section	__TEXT,__text,regular,pure_instructions
	.globl	_main
	.p2align	2
_main:
Lloh0:
	adrp	x8, lCPI0_0@PAGE
Lloh1:
	ldr	q0, [x8, lCPI0_0@PAGEOFF]
Lloh2:
	adrp	x8, _$s4test13optionalValueSSSgvp@PAGE
Lloh3:
	adrp	x9, _$s4test12defaultValueSSvp@PAGE
Lloh4:
	add	x9, x9, _$s4test12defaultValueSSvp@PAGEOFF
	str	q0, [x8, _$s4test13optionalValueSSSgvp@PAGEOFF]
	mov	w8, #25977
	movk	w8, #112, lsl #16
	mov	x10, #-2089670227099910144
	stp	x8, x10, [x9]
	mov	w0, #0
	ret
	.loh AdrpAdd	Lloh3, Lloh4
	.loh AdrpAdrp	Lloh0, Lloh2
	.loh AdrpLdr	Lloh0, Lloh1

	.globl	_$s4test14valueORDefault0B012defaultValuexxSgyKXK_xyKXKtKlF
	.p2align	2
_$s4test14valueORDefault0B012defaultValuexxSgyKXK_xyKXKtKlF:
	.cfi_startproc
	str	x28, [sp, #-96]!
	stp	x27, x26, [sp, #16]
	stp	x25, x24, [sp, #32]
	stp	x23, x22, [sp, #48]
	stp	x20, x19, [sp, #64]
	stp	x29, x30, [sp, #80]
	add	x29, sp, #80
	sub	sp, sp, #16
	.cfi_def_cfa w29, 16
	.cfi_offset w30, -8
	.cfi_offset w29, -16
	.cfi_offset w19, -24
	.cfi_offset w20, -32
	.cfi_offset w22, -40
	.cfi_offset w23, -48
	.cfi_offset w24, -56
	.cfi_offset w25, -64
	.cfi_offset w26, -72
	.cfi_offset w27, -80
	.cfi_offset w28, -96
	mov	x22, x21
	mov	x24, x4
	stur	x3, [x29, #-72]
	stur	x2, [x29, #-88]
	mov	x20, x1
	mov	x25, x0
	mov	x27, x8
	mov	x0, #0
	mov	x1, x4
	bl	_$sSqMa
	mov	x19, x0
	ldur	x26, [x0, #-8]
	ldr	x8, [x26, #64]
	add	x8, x8, #15
	and	x8, x8, #0xfffffffffffffff0
	mov	x9, sp
	sub	x28, x9, x8
	mov	sp, x28
	mov	x9, sp
	sub	x23, x9, x8
	mov	sp, x23
	mov	x8, x23
	mov	x21, x22
	blr	x25
	mov	x22, x21
	cbnz	x21, LBB1_5
	ldur	x20, [x29, #-72]
	ldr	x8, [x26, #16]
	mov	x0, x28
	mov	x1, x23
	mov	x2, x19
	blr	x8
	ldur	x25, [x24, #-8]
	ldr	x8, [x25, #48]
	mov	x0, x28
	mov	w1, #1
	mov	x2, x24
	blr	x8
	cmp	w0, #1
	b.ne	LBB1_3
	mov	x8, x27
	mov	x21, x22
	ldur	x9, [x29, #-88]
	blr	x9
	mov	x22, x21
	b	LBB1_4
LBB1_3:
	ldr	x8, [x25, #32]
	mov	x0, x27
	mov	x1, x28
	mov	x2, x24
	blr	x8
LBB1_4:
	ldr	x8, [x26, #8]
	mov	x0, x23
	mov	x1, x19
	blr	x8
LBB1_5:
	mov	x21, x22
	sub	sp, x29, #80
	ldp	x29, x30, [sp, #80]
	ldp	x20, x19, [sp, #64]
	ldp	x23, x22, [sp, #48]
	ldp	x25, x24, [sp, #32]
	ldp	x27, x26, [sp, #16]
	ldr	x28, [sp], #96
	ret
	.cfi_endproc

	.private_extern	_$s4test0A3__1SSyF
	.globl	_$s4test0A3__1SSyF
	.p2align	2
_$s4test0A3__1SSyF:
	sub	sp, sp, #64
	stp	x20, x19, [sp, #32]
	stp	x29, x30, [sp, #48]
	add	x29, sp, #48
Lloh5:
	adrp	x19, _$s4test13optionalValueSSSgvp@PAGE
Lloh6:
	add	x19, x19, _$s4test13optionalValueSSSgvp@PAGEOFF
	add	x1, sp, #8
	mov	x0, x19
	mov	x2, #0
	mov	x3, #0
	bl	_swift_beginAccess
	ldr	x0, [x19, #8]
	cbz	x0, LBB2_2
Lloh7:
	adrp	x8, _$s4test13optionalValueSSSgvp@PAGE
Lloh8:
	ldr	x19, [x8, _$s4test13optionalValueSSSgvp@PAGEOFF]
	mov	x20, x0
	b	LBB2_3
LBB2_2:
Lloh9:
	adrp	x8, _$s4test12defaultValueSSvp@PAGE
Lloh10:
	add	x8, x8, _$s4test12defaultValueSSvp@PAGEOFF
	ldp	x19, x20, [x8]
	mov	x0, x20
	bl	_swift_bridgeObjectRetain
	mov	x0, #0
LBB2_3:
	bl	_swift_bridgeObjectRetain
	mov	x0, x19
	mov	x1, x20
	ldp	x29, x30, [sp, #48]
	ldp	x20, x19, [sp, #32]
	add	sp, sp, #64
	ret
	.loh AdrpAdd	Lloh5, Lloh6
	.loh AdrpLdr	Lloh7, Lloh8
	.loh AdrpAdd	Lloh9, Lloh10

	.private_extern	_$s4test0A3__2SSyF
	.globl	_$s4test0A3__2SSyF
	.p2align	2
_$s4test0A3__2SSyF:
	b	_$s4test0A3__1SSyF

	.private_extern	_$s4test13optionalValueSSSgvp
	.globl	_$s4test13optionalValueSSSgvp
.zerofill __DATA,__common,_$s4test13optionalValueSSSgvp,16,4
	.private_extern	_$s4test12defaultValueSSvp
	.globl	_$s4test12defaultValueSSvp
.zerofill __DATA,__common,_$s4test12defaultValueSSvp,16,3
	.section	__TEXT,__swift5_entry,regular,no_dead_strip
	.p2align	2
l_entry_point:
	.long	_main-l_entry_point

	.private_extern	__swift_FORCE_LOAD_$_swiftFoundation_$_test
	.section	__DATA,__const
	.globl	__swift_FORCE_LOAD_$_swiftFoundation_$_test
	.weak_definition	__swift_FORCE_LOAD_$_swiftFoundation_$_test
	.p2align	3
__swift_FORCE_LOAD_$_swiftFoundation_$_test:
	.quad	__swift_FORCE_LOAD_$_swiftFoundation

	.private_extern	__swift_FORCE_LOAD_$_swiftObjectiveC_$_test
	.globl	__swift_FORCE_LOAD_$_swiftObjectiveC_$_test
	.weak_definition	__swift_FORCE_LOAD_$_swiftObjectiveC_$_test
	.p2align	3
__swift_FORCE_LOAD_$_swiftObjectiveC_$_test:
	.quad	__swift_FORCE_LOAD_$_swiftObjectiveC

	.private_extern	__swift_FORCE_LOAD_$_swiftDarwin_$_test
	.globl	__swift_FORCE_LOAD_$_swiftDarwin_$_test
	.weak_definition	__swift_FORCE_LOAD_$_swiftDarwin_$_test
	.p2align	3
__swift_FORCE_LOAD_$_swiftDarwin_$_test:
	.quad	__swift_FORCE_LOAD_$_swiftDarwin

	.private_extern	__swift_FORCE_LOAD_$_swiftCoreFoundation_$_test
	.globl	__swift_FORCE_LOAD_$_swiftCoreFoundation_$_test
	.weak_definition	__swift_FORCE_LOAD_$_swiftCoreFoundation_$_test
	.p2align	3
__swift_FORCE_LOAD_$_swiftCoreFoundation_$_test:
	.quad	__swift_FORCE_LOAD_$_swiftCoreFoundation

	.private_extern	__swift_FORCE_LOAD_$_swiftDispatch_$_test
	.globl	__swift_FORCE_LOAD_$_swiftDispatch_$_test
	.weak_definition	__swift_FORCE_LOAD_$_swiftDispatch_$_test
	.p2align	3
__swift_FORCE_LOAD_$_swiftDispatch_$_test:
	.quad	__swift_FORCE_LOAD_$_swiftDispatch

	.private_extern	__swift_FORCE_LOAD_$_swiftCoreGraphics_$_test
	.globl	__swift_FORCE_LOAD_$_swiftCoreGraphics_$_test
	.weak_definition	__swift_FORCE_LOAD_$_swiftCoreGraphics_$_test
	.p2align	3
__swift_FORCE_LOAD_$_swiftCoreGraphics_$_test:
	.quad	__swift_FORCE_LOAD_$_swiftCoreGraphics

	.private_extern	__swift_FORCE_LOAD_$_swiftIOKit_$_test
	.globl	__swift_FORCE_LOAD_$_swiftIOKit_$_test
	.weak_definition	__swift_FORCE_LOAD_$_swiftIOKit_$_test
	.p2align	3
__swift_FORCE_LOAD_$_swiftIOKit_$_test:
	.quad	__swift_FORCE_LOAD_$_swiftIOKit

	.private_extern	__swift_FORCE_LOAD_$_swiftXPC_$_test
	.globl	__swift_FORCE_LOAD_$_swiftXPC_$_test
	.weak_definition	__swift_FORCE_LOAD_$_swiftXPC_$_test
	.p2align	3
__swift_FORCE_LOAD_$_swiftXPC_$_test:
	.quad	__swift_FORCE_LOAD_$_swiftXPC

	.private_extern	___swift_reflection_version
	.section	__TEXT,__const
	.globl	___swift_reflection_version
	.weak_definition	___swift_reflection_version
	.p2align	1
___swift_reflection_version:
	.short	3

	.no_dead_strip	l_entry_point
	.no_dead_strip	_$s4test14valueORDefault0B012defaultValuexxSgyKXK_xyKXKtKlF
	.no_dead_strip	___swift_reflection_version
	.no_dead_strip	__swift_FORCE_LOAD_$_swiftCoreFoundation_$_test
	.no_dead_strip	__swift_FORCE_LOAD_$_swiftCoreGraphics_$_test
	.no_dead_strip	__swift_FORCE_LOAD_$_swiftDarwin_$_test
	.no_dead_strip	__swift_FORCE_LOAD_$_swiftDispatch_$_test
	.no_dead_strip	__swift_FORCE_LOAD_$_swiftFoundation_$_test
	.no_dead_strip	__swift_FORCE_LOAD_$_swiftIOKit_$_test
	.no_dead_strip	__swift_FORCE_LOAD_$_swiftObjectiveC_$_test
	.no_dead_strip	__swift_FORCE_LOAD_$_swiftXPC_$_test
	.no_dead_strip	_main
	.linker_option "-lswiftFoundation"
	.linker_option "-lswiftCore"
	.linker_option "-lswiftObjectiveC"
	.linker_option "-lswiftDarwin"
	.linker_option "-framework", "Foundation"
	.linker_option "-lswiftCoreFoundation"
	.linker_option "-framework", "CoreFoundation"
	.linker_option "-lswiftDispatch"
	.linker_option "-framework", "Combine"
	.linker_option "-framework", "ApplicationServices"
	.linker_option "-lswiftCoreGraphics"
	.linker_option "-framework", "CoreGraphics"
	.linker_option "-lswiftIOKit"
	.linker_option "-framework", "IOKit"
	.linker_option "-framework", "ColorSync"
	.linker_option "-framework", "ImageIO"
	.linker_option "-framework", "CoreServices"
	.linker_option "-framework", "Security"
	.linker_option "-lswiftXPC"
	.linker_option "-framework", "CFNetwork"
	.linker_option "-framework", "DiskArbitration"
	.linker_option "-framework", "CoreText"
	.linker_option "-lobjc"
	.section	__DATA,__objc_imageinfo,regular,no_dead_strip
L_OBJC_IMAGE_INFO:
	.long	0
	.long	84150080

	.weak_reference __swift_FORCE_LOAD_$_swiftFoundation
	.weak_reference __swift_FORCE_LOAD_$_swiftObjectiveC
	.weak_reference __swift_FORCE_LOAD_$_swiftDarwin
	.weak_reference __swift_FORCE_LOAD_$_swiftCoreFoundation
	.weak_reference __swift_FORCE_LOAD_$_swiftDispatch
	.weak_reference __swift_FORCE_LOAD_$_swiftCoreGraphics
	.weak_reference __swift_FORCE_LOAD_$_swiftIOKit
	.weak_reference __swift_FORCE_LOAD_$_swiftXPC
.subsections_via_symbols
{% endhighlight %}

</p>
</details>
<br>

But the most interesting part - is how our function converted into instructions. For the function `test__1`, we can find

{% highlight asm %}
_$s4test0A3__1SSyF:
// and a lot of instructions
{% endhighlight %}

and for `test__2`:

{% highlight asm %}
_$s4test0A3__2SSyF:
	b	_$s4test0A3__1SSyF
{% endhighlight %}

where, if we look at [ARM reference](https://www.element14.com/community/servlet/JiveServlet/previewBody/41836-102-1-229511/ARM.Reference_Manual.pdf):

{% highlight asm %}
B label
	Branch: unconditionally jumps to pc-relative label.
{% endhighlight %}

> section 5.1.2 Unconditional Branch (immediate)

and label is our first function instruction set.

This means, that both functions - with and without abstraction will be treated by the compiler in the same way.

**The compiler doesn't care** - is u'r code is in a good shape or not. (at least at some level)

## Conclusion

Does it mean that we should skip all these patterns, principles, and other stuff, thus for the machine it looks in the same way? My opinion - NO. If u have some doubts - NO, NO, and NO.

The quality of the code is a key principle for any program. Scalability, maintainability, and more other differents *ability is the key concept for any programmer. 

We wrote code that will be supported and read by humans, not by machines, this means that code style is very important. All existing articles and principles, discussions, and forums dedicated to the quality of the code and its important role are right. 

To those, who think that *Customer doesn't care about the quality of the code*, *machine don't care* and other stuff like this, I can tell that first of all, we write code for other programmers, humans and they care, a lot!

Code style, principles, and patterns - are some of the key concepts of a good programmer, good program, good code. 

**Because programmers care**.
 
<br> 
[download files]({% link assets/posts/images/2021-09-05-watch-your-language/sources.zip %})


## Resource

* [Swift Intermediate Language (SIL)](https://github.com/apple/swift/blob/main/docs/SIL.rst)
* [GRASP](https://en.wikipedia.org/wiki/GRASP_(object-oriented_design))
* [KISS](https://en.wikipedia.org/wiki/KISS_principle)
* [DRY](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
* [OAOO](http://wiki.c2.com/?OnceAndOnlyOnce)
* [S.O.L.I.D.](https://en.wikipedia.org/wiki/SOLID)
* [YAGNI](https://en.wikipedia.org/wiki/You_aren%27t_gonna_need_it)
* [swift compiler arch](https://swift.org/swift-compiler/#compiler-architecture)
* [About SIL](https://llvm.org/devmtg/2015-10/slides/GroffLattner-SILHighLevelIR.pdf)
* [Mangling](https://github.com/apple/swift/blob/main/docs/ABI/Mangling.rst)
* [ARM reference](https://www.element14.com/community/servlet/JiveServlet/previewBody/41836-102-1-229511/ARM.Reference_Manual.pdf)
* [About ARM Assembly](https://mikejfromva.com/2018/05/26/arm64-assembly-with-swift-and-xcode/)
* [`@inlinable`](https://docs.swift.org/swift-book/ReferenceManual/Attributes.html#ID587)
* [`@autoclosure`](https://docs.swift.org/swift-book/LanguageGuide/Closures.html#ID543)
* [generics](https://docs.swift.org/swift-book/LanguageGuide/Generics.html)
* [error handling](https://docs.swift.org/swift-book/LanguageGuide/ErrorHandling.html)