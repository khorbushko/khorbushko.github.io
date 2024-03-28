---
layout: post
comments: true
title: "Probe of software design with Alloy"
categories: article
tags: [Alloy, formal language]
excerpt_separator: <!--more-->
comments_id: 103

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

Sometimes we have an idea and we want to check that this idea has a realistic chance for life. In other words, we want to check the design of the idea. If we are talking about software - often we want to check the design of some approach. 
<!--more-->

## Intro

This is not something new, but due to some reason(s), not a very popular activity. To solve this, we may want to use some [formal language](https://en.wikipedia.org/wiki/Formal_language). 

One of the first approaches was a language specifically created for this and known as [Z notation](https://en.wikipedia.org/wiki/Z_notation). If u check the link, u can see, that this language is quite old. I didn't use it, so not sure about the pros and cons. 

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/z.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/z.png" alt="run-z" width="500"/>
</a>
</div>
<br>
<br>


More interesting for me - is the [Alloy language](https://en.wikipedia.org/wiki/Alloy_%28specification_language%29) - a [specification language](https://en.wikipedia.org/wiki/Specification_language) (a subtype of formal language). 

> I didn't know about such an approach despite the fact that I am often faced with such kinds of tasks, especially when designing some algorithms for solving different objectives. I was pointed to this language by [Luomein](https://stackoverflow.com/users/1995722/luomein). If u reading this post - thank you for this!

As mentioned in a book available at [alloytools](https://alloytools.org/book.html), the main ideas and concepts used in Alloy are not new:

> [Jim Horning and John Guttag described a basic logic description concepts approach in a paper in 1980](https://dl.acm.org/doi/pdf/10.1145/567446.567471), in which a theorem prover was used to answer questions interactively about a candidate design. That paper was a major source of inspiration for Alloy.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/concept.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/concept.png" alt="concept.png" width="500"/>
</a>
</div>
<br>
<br>

So we may think about Alloy as about modern tool for modeling and exploring software design, that uses well-defined, time-proved ideas.

> Off-cause this is not a silver bullet, and some problems and limitations still exist in Alloy.. but where it doesn`t?

Why do we need this? As for me, there are a few answers:

- to be sure that something is possible
- to be able to eliminate and fix problems with minimum costs for it
- to prove the concept
- to speed up design
- to inspect existing systems for weakness 
- to predict the behavior of the system

## Example

I like an approach when u have a lot of theory done and then u can switch to the practice. For theory I can recommend for sure [unofficial doc](https://alloy.readthedocs.io/)  and [lecture about Formal Methods](https://homepage.divms.uiowa.edu/~tinelli/classes/5810/Fall22/lectures.shtml), also [alloy-cheatsheet](https://esb-dev.github.io/mat/alloy-cheatsheet.pdf) may be useful.

For practice I like the example about [farmer, fox, chicken and grain](https://github.com/AlloyTools/models/blob/master/puzzles/farmer-chicken-fox/farmer.als) or about Königsberg bridges - [puzzle about bridge crossing](https://en.wikipedia.org/wiki/Seven_Bridges_of_K%C3%B6nigsberg)

```alloy
abstract sig Landmass {}

abstract sig Bridge { connects: set Landmass } { #connects = 2 }

one sig Bridge1 extends Bridge {} { connects = N + W }
one sig Bridge2 extends Bridge {} { connects = N + W }
one sig Bridge3 extends Bridge {} { connects = N + E }
one sig Bridge4 extends Bridge {} { connects = E + W }
one sig Bridge5 extends Bridge {} { connects = E + S }
one sig Bridge6 extends Bridge {} { connects = S + W }
one sig Bridge7 extends Bridge {} { connects = S + W }

sig Path { firstStep: Step }
sig Step {
	from, to: Landmass,
	via: Bridge,
	nextStep: lone Step
} {
	 via.connects = from + to 
}
fact {
	all curr:Step, next:curr.nextStep |
	next.from = curr.to
}
fun stepss(p:Path): set Step {
	p.firstStep.*nextStep
}
pred path() {
	some p:Path | stepss[p].via = Bridge
}
run path for 8  but exactly 1 Path
```

This will produce a nice task-solving graphical representation.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/bridge.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/bridge.png" alt="bridge.png" width="600"/>
</a>
</div>
<br>
<br>

Even these examples should stimulate u to learn Alloy. But to be more precise - let's create something on our own - only in this way can feel the language ;].

I decided to describe a coder and a coffee with or without sugar. ;]

> I won't cover all lexical aspects of the language, if u interested in it - check the link above.

So our goal - is to check the possibilities of the language within a useless model - coder vs coffee. This model will not cover some interaction or caffeine intake ) offcause.

So, the very first step - is to define the models: `Coffee`, `Coder`, and `Sugar`. We also can assume that we have few types of coffee and few types of coders:

```alloy
sig Sugar {}
abstract sig Coffee {
	 , contains: set Sugar
}
sig Espresso extends Coffee {}
sig Americano extends Coffee {}

abstract sig CoffeeDrinker {
	, drinks: set Coffee
	, has: set Sugar
}

sig Developer extends CoffeeDrinker {}
sig Programmer  in Developer {}
```

Here u already can see the power of the language - abstraction, inheritance, and relations. The main point from the declaration above - u need to think about everything in terms as u think about [set](https://en.wikipedia.org/wiki/Set_%28mathematics%29). I love things that ask u to *switch* the way u usually think - this will open additional possibilities for u.

The important moment here - is to understand every keyword and meaning in the code before going forward. For example, u need to understand the difference between **extend** and **in** keywords. The links above have a lot of examples and nice explanations like the one below (grabbed from slides to lectures):


<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/signature.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/signature.png" alt="signature.png" width="500"/>
</a>
</div>
<br>
<br>

> [source](https://homepage.divms.uiowa.edu/~tinelli/classes/5810/Fall22/Notes/03.1-intro-to-alloy.pdf)

The beauty and power of Alloy - is that u already can test u'r model -  having no rules and constraints, but just a declaration. 

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run1.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run1.png" alt="run1.png" width="500"/>
</a>
</div>
<br>
<br>

Offcause result - is just one of the tons possible model solutions - not much. Yet. We need rules and some **fact**s about how components of our model interact each with other.

We also can modify a code a bit by adding additional relations - for example, our developers can have a friend now:

```alloy
, friends: set CoffeeDrinker
```

And to make a picture a bit more interesting, let's inspect a few objects:

```alloy
run event {} for 7
```

The result is quite interesting:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run2.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run2.png" alt="run2.png" width="600"/>
</a>
</div>
<br>
<br>

We have a raw model here and a few problems. The most obvious are:

- **some** developer is a friend to itself (maybe someone can, but not in our models ;])
- **all** coffee and **all** sugar are shared between different instances

To provide a fix, we should modify our models and provide additional facts. We can add a rule, that says: "developer can't be a friend to itself":

```alloy
-- coffeeDrinker is not a friend to itself
fact selfFriend {
	no p: CoffeeDrinker | p in p.^friends
}
```

> The beauty of programming is that we can achieve the same effect in a different manner, and here, in Alloy, we can do the same as above in fact only by specifying the type of relation as **`disj`**

The result is a bit better model:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run3.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run3.png" alt="run3.png" width="600"/>
</a>
</div>
<br>
<br>

Better. Now imagine what we can achieve if we specify all the rules - quite a good and powerful solution for checking a theory, or design. Let's modify a bit our code, by making coffee and sugar not shared, with **disj** keyword.

If we want, we can make all coffee without sugar, or add some other rules:

```alloy
-- programmer does not like too much sugar
fact "named fact" {
	some c: Programmer | lone c.has 
}

fact {
	all s: Sugar | s in CoffeeDrinker.*drinks.contains and s in Coffee.*contains
}

fact "dev's coffee can have only sugar that developer have" {
	all d: CoffeeDrinker {
		d.has = d.drinks.contains
	}
}
```

The result can be received momentary:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run4.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run4.png" alt="run4.png" width="600"/>
</a>
</div>
<br>
<br>

we can even add style, for better understanding:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run4-styled.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-28-Probe of software design/run4-styled.png" alt="run4-styled.png" width="600"/>
</a>
</div>
<br>
<br>


<details><summary> The full code for this important model </summary>
<p>

{% highlight js %}

sig Sugar {}
abstract sig Coffee {
	-- no shared sugar
	 , contains: disj set Sugar
}
sig Espresso extends Coffee {}
sig Americano extends Coffee {}

abstract sig CoffeeDrinker {
	, drinks: disj set Coffee
	-- no shared sugar
	 , has: disj set Sugar
}

sig Developer extends CoffeeDrinker {
	, friends: set CoffeeDrinker
}
sig Programmer  in Developer {}

run event {} for 7


-- coffeeDrinker is not a friend to itself
fact selfFriend {
	no p: CoffeeDrinker | p in p.^friends
}

-- programmer does not like too much sugar
fact "named fact" {
	some c: Programmer | lone c.has 
}

-- not all CoffeeDrinker is a Programmer - does nothing,
-- thus this is from the declaration, just to demonstrate pred
pred notAProgrammer[c: CoffeeDrinker] { 
	not (c in Programmer)
}

fact { 
	some c: CoffeeDrinker | notAProgrammer[c] 
}

fact {
	all s: Sugar | s in CoffeeDrinker.*drinks.contains and s in Coffee.*contains
}

fact "dev's coffee can have only sugar that developer have" {
	all d: CoffeeDrinker {
		d.has = d.drinks.contains
	}
}
{% endhighlight %}
</p>
</details>
<br>

## Conclusion

We can apply this to real-life problems in programming and other areas. As mentioned in [this article](https://cacm.acm.org/research/alloy/)  the variety of the Alloy usage is wide - from analysis to improvement.

> _As we experimented with Alloy, we came to realize how helpful it is to have a tool that can generate provocative examples._

I see the perfect application for this language in complex software design and teaching - momentary results and powerful configuration - a key.


## Resources

- [formal language](https://en.wikipedia.org/wiki/Formal_language) 
- [Z notation - Wikipedia](https://en.wikipedia.org/wiki/Z_notation)
- [Alloy (specification language) - Wikipedia](https://en.wikipedia.org/wiki/Alloy_(specification_language))
- [Unofficial docs](https://alloy.readthedocs.io/en/latest/)
- [Post about alloy](https://www.hillelwayne.com/post/alloy6/)
- [alloytools.org](https://alloytools.org/)
- [alloy-cheatsheet](https://esb-dev.github.io/mat/alloy-cheatsheet.pdf)
- [stackoverflow feed](https://stackoverflow.com/questions/tagged/alloy)
- [alloy](https://bytes.zone/posts/alloy/)
- [git hub in alloy]( https://bytes.zone/posts/modeling-git-internals-in-alloy-part-1-blobs-and-trees/)
- [models](https://github.com/AlloyTools/models)
- [database in alloy](https://bytes.zone/posts/modeling-database-tables-in-alloy/)
- [lectures alloy](https://homepage.divms.uiowa.edu/~tinelli/classes/5810/Fall22/lectures.shtml)
- [intro to alloy](https://homepage.cs.uiowa.edu/~tinelli/classes/181/Fall22/Notes/03.1-intro-to-alloy.pdf)
- [Jim Horning and John Guttag described a basic logic description concepts approach in a paper in 1980](https://dl.acm.org/doi/pdf/10.1145/567446.567471)

