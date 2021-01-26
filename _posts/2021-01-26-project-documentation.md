---
layout: post
comments: true
title: "Document or die hard"
categories: article
tags: [development, documentation, userStory]
excerpt_separator: <!--more-->
comments_id: 26

author:
- kyryl horbushko
- Lviv
---

The requirement, feature description, goal of the project... How many times did u ask yourself about this during work on some project? As for me, these questions appear in my head very often. 

The problem of feature/requirements/idea documentation is not new at all, but people on the different project continue to shoot oneself in the foot. Same situation, same problems, same mistake... same result.
<!--more-->

To resolve this issue (*I hope that this post will be useful at least for some projects*) I would like to write a bit about documentation.

## Intro

I think, at a high level, we should divide this into a few phases: before actual implementation and after. Each phase has its methods (*way* if u like) of documentation.

> Of cause, if we refer to different great sources of agile methodologies and other techniques related to project management (like [this](https://www.amazon.com/Coaching-Agile-Teams-ScrumMasters-Addison-Wesley/dp/0321637704/ref=pd_sbs_1?pd_rd_w=oI6FD&pf_rd_p=ed1e2146-ecfe-435e-b3b5-d79fa072fd58&pf_rd_r=32VT6HRBD7JP6NM0W7T1&pd_rd_r=9ef8f59d-e514-4920-8d1b-32207586dfe2&pd_rd_wg=8Utwi&pd_rd_i=0321637704&psc=1) or [this](https://www.amazon.com/Mythical-Man-Month-Software-Engineering-Anniversary/dp/0201835959/ref=sr_1_1?crid=2RV3B3N4KDNHO&dchild=1&keywords=mythical+man+month&qid=1609161393&sprefix=mythical+man%2Caps%2C255&sr=8-1)), we can find, that there is much more than 2 phase of the project. 
> 
> But here, I divided it into 2 phases, just because it's very obvious where the terminator is - feature either implemented, either no. There is no other option. U can't tell that everything is done for 99.9% - this is still not implemented phase. In other words - if u need to select between black and white, u can't select gray.

At the *before implementation* stage we have not much, thus this is just an idea. To describe it, the best way, in my opinion, is to use a well-known user story approach. There are a few additional ways to do this - such as UML diagrams, flow charts, prototypes. All of them have their pros and cons. So the list may contain next items:

- user story
- UML-diagrams / flow charts
- prototype

Period, when some feature already implemented also has a few variants of documentation (even if no-one writes it explicitly):

- code
- tests
- explicit documentation
- steps are done during the phase "before implementation"

Let's review each way in a bit more detail.

## Before implementation

This period of the project is also known as planning. In this phase (*I think there is must be a much better name for this...*), the project is mostly just an idea, and everything is quite raw and easy-changeable, so the price of error - minimal. As result - we should make an error here, a lot. Then fix them and go to the next phase.

> Under price, I mean value, that can be measured in time and required effort (different resources). 
> 
> For error's price comparison, I would like to suggest a reference to a great book ["Code complete 2" by Steve McConnell](https://www.amazon.com/Code-Complete-Practical-Handbook-Construction/dp/0735619670). [Here is a photo](https://khorbushko.github.io/bookNotes/codeComplete#defect-cost) from a book, that describes the cost of errors on different project state.

When I go back to the very start of my work as a software engineer, I hate errors, I hate those moments when QA catches and describe some bug or error in work that was done by myself. Now, I like those moments, especially, if we talking about requirements for the feature. This is a chance, that allows reducing future efforts required to produce a qualitative product. 

As I said previously, we have a few ways to make these errors and to resolve them.

### User story

> A great book about [user story](https://www.amazon.com/User-Stories-Applied-Software-Development/dp/0321205685)

What is a user story? 

A user story is an informal, general explanation of a software feature written from the perspective of the end-user. Its purpose is to articulate how a software feature will provide value to the customer. [[source](https://www.atlassian.com/agile/project-management/user-stories)]

Using this technique - everyone can read and understand the idea of the feature. If someone didn't catch it - u change a user story, until it's become clear to everyone. 

This is great because u don't need to know some special language or dive too deep into tech details - all u need is just describe what the user needs, in words, that everyone can understand.

I have a project, where the user story was absent. The result - is messy. Every platform implements the same feature, indifferent way. Because no-one knows what should be done. One person at the company knew the *right way*. The good question here - *"What will happen to the product, when this person leaves this company?"* Does anyone will be able to support this product? I guess - no. This is the very first step to *"die-hard"* road.

I always wonder - why people on different projects don't want to write user stories. Instead, usually, PMs try to set up some meetings with 20-30 attendees for useless discussion, that no-one can remember. Usually, such projects store this recorded session within hundreds of other records, which are mostly poorly maintained, and to find something in them is like to look for a needle in a haystack.

A user story, in my opinion, is an essential part of the project, that wants to live a long period.

**Pro’s:** 

* Easy to start - only one sentence needed
* keep the focus on user
* allow not to dive too deep into tech details
* simplifies the requirements definition process 
* focuses on the business need
* easy to describe/structure requirements
* allow determining errors/gaps in functionality on early stage
* allows to prioritize story functional parts easily
* always accessible by any team member in the project, at any time
* require the collaboration of different departments (allow to build team)
* improve planning sessions

**Con’s:**

* may convert into a long conversation
* description can grow, that require time to understand all aspects
* require the collaboration of different departments (require additional time)
* can be overused and become a reason of a huge waste
* require to be maintained to reflect any changes

> This list is not full, and this is just my vision of it. If u have some comments - please left them at the bottom of this page.

Effective user story can follow [Bill Wake’s INVEST model](https://en.wikipedia.org/wiki/INVEST_(mnemonic)). [[chapter 15.3.4](https://www.agilebusiness.org/page/ProjectFramework_15_RequirementsandUserStories)]

#### Example

The template for the user story can be as next:

{% highlight text %}
As a [person, user, customer, etc], I want to [do something] so that I can [achieve something, some goal].
{% endhighlight %}

that can be transformed in 

{% highlight text %}
As a user, I want to be able to receive news about new articles available, so I can be notified about updates and read them.
{% endhighlight %}

Then, we can add some details and describe all moments/requirements that need to be covered for the current feature/functionality.

{% highlight text %}
The user is allowed to read an article that can be received via mail notification if a user subscribes to it. The email should contain a unique link to an article and a short description (up to 200 characters) of the article. Link on click should redirect to the site with the article. A link should allow tracking source (for now only email).
{% endhighlight %}

> Requirements is another topic, that requires a separate article, or even a book, and so I didn't cover it here.

These 2 parts can be done in different moments.

### UML diagrams

> Description of how to create and use them can be found in another [book about UML](https://www.amazon.com/UML-Distilled-Standard-Modeling-Language/dp/0321193687/ref=sr_1_1?crid=1DHSZI77Z7MKU&dchild=1&keywords=uml+distilled&qid=1608394116&sprefix=UML+di%2Caps%2C259&sr=8-1)

A UML diagram is a graphical representation of a system based on the UML (Unified Modeling Language). This diagram includes some actors, actions, artifacts, etc. Combining all information at once, we better and faster understand the system and how this system works.

UML requires a bit more time to develop, but at the same moment, it allows to quickly check the process (in comparison within user story). But the disadvantage is that some small details about implementation are missed.

This part as for me is good to have for a more complex system. For a simple one - it's just a waste of time.

**Pro’s:** 

* informative (easy to read and understand)
* flexible
* good visualization
* improve understanding of the system for all team member
* help to determine risks
* has few types - allow covering different processes

**Con’s:**

* does not contains low-level details/requirements
* formal notation is not needed
* can be big and complex
* spec for UML has more than 700 pages to read - sometimes too complex
* may consume a lot of time to be created

#### Example

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-01-26-project-documentation/uml-sample.png" alt="uml-sample" width="550"/>
</div>
<br>

> I grab this from [www.uml-diagrams.org](https://www.uml-diagrams.org/java-7-concurrent-uml-class-diagram-example.html)

### Prototype

The prototype is a great way for collecting fast feedback on the planning stage with zero effort related to programming and by providing a realistic feeling of the final product. All data if faked, all design is draft and can be changed almost in realtime. But customers can test and feel their product, they can provide u feedback, something that is highly needed for u. Feedback is an essential part of any project development.

Use prototypes always. Everywhere. It's cheap, fast to develop, and a valuable player in the process.

Unfortunately, often prototypes are done by developers. Even worst, these prototypes are used as a fundament for the project itself. I faced such approaches few times. The result is always the same - project dies hard. Always!  Die slowly, causing pain, agony, and torment to the developers and all the team members.

There are a lot of free tools such as [this one](https://www.justinmind.com) or [this](https://proto.io) or [this](https://www.invisionapp.com/cloud/prototype).

**Pro’s:** 

* fast and easy to develop
* Easy to update (flexible)
* allow finding missing functionality
* provide to a user feeling of real app
* collect feedback
* improves design 
* can be tested on a real device
* improve system understanding
* cheap

**Con’s:**

* may not reflect design fully
* can hide degree of complexity
* may require additional time (depend on tool and effects, detalization)
* may require a small investment
* may be used as a source of true, but provide no documentation

#### Example

Click [here](https://projects.invisionapp.com/share/AS8XKQYDX#/screens) to test the prototype.

> Yaya is a Silicon Valley-based startup that's building a whole new way to hire contractors, using the chat
> 
> [More prototypes](https://www.fullstacklabs.co/prototypes)

## After implementation

*"After implementation"* is one of the most interesting parts for me. 

We, as a developer, often can be joined to a project, that already has been started and released. We may require to change something. The biggest problem in changes - is to not break existing functionality - u never know for sure (until u check and test) how u'r change affect the app. Off cause, in greatly designed systems, this may sounds as non-sense - if u change something, and another part of the app also changed, then this a poor design. Yes, but this is life, and [stanger things](https://en.wikipedia.org/wiki/Stranger_Things) can happen.

All described above can be improved using documentation. 

### Code

Code should document itself. That's it - nothing more.

Objective-C (my favorite language) provide all mechanism for it. Swift, as Objective-C's successor, provides the same level of code documenting mechanism. In my understanding, u should read the code as u read the book. U read the story.

Code comments become deprecated as soon as u wrote them. NO ONE will update them. Never comment out the code - better remove it, git or other version control system will handle it in a better way. Name u'r variables, functions, methods, classes, and other components wisely. Rename it, as soon as u feel that u need few more seconds to think about the variable before using it.

This, as for me essential items, that u can follow and make u'r code self-describable.

#### Example

I can put here a ton of examples. Instead, u can develop examples by yourself - try to give u'r code to someone, who is not related to programming, and ask to read and guess, what going on in code. Line by line. This person, even not understanding the implementation, should be able to answer u. Describe all variables (or at least most of them). If so, this means that u'r code is self-documented.

I once heard, that an experienced developer is one, who doesn't write code that only he can understand. Instead, he can write code that everyone understands. For me - that's the idea and goal.

> I'll lie, if I tell u that I didn't write a code, that is too hard to understand in the same moment when u look at it. But now, I blame myself for that code :]. 

### Tests

U can read self-documented code, u know how it's work. But obviously, it's not enough - u can't be sure that this code does what the customer expects from it.

Tests - this is an additional component that u need. Tests describe the functionality and expected behavior. A test should be a source of true for your functionality.

I think, that the main advantage of tests - it's his ability to describing the functionality of the app. For me, this is documentation - rich and self-validatable.

### Explicit documentation

The last part, but not least. 

Once u have a project, additional information should be present for it.
How to setup the environment, what approach, architecture, CI/CD, code style, and other aspects are used within it.

If u provide such documentation, then anyone who is involved in the project can find answers quickly and without much effort.


#### Example 

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-01-26-project-documentation/demo_doc.gif" alt="demo_doc" width="550"/>
</div>
<br>


## Resources

* [User Stories Applied Software Development](https://www.amazon.com/User-Stories-Applied-Software-Development/dp/0321205685)
* [INVEST](https://en.wikipedia.org/wiki/INVEST_(mnemonic))
* [Requirements and user stories](https://www.agilebusiness.org/page/ProjectFramework_15_RequirementsandUserStories)
* [UML - Distilled Standard Modeling Language](https://www.amazon.com/UML-Distilled-Standard-Modeling-Language/dp/0321193687/ref=sr_1_1?crid=1DHSZI77Z7MKU&dchild=1&keywords=uml+distilled&qid=1608394116&sprefix=UML+di%2Caps%2C259&sr=8-1)
* [Agile](https://www.atlassian.com/agile)