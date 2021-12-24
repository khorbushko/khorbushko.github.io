---
layout: post
comments: true
title: "Shitty-code feeling"
categories: article
tags: [swift, iOS, codeQuality]
excerpt_separator: <!--more-->
comments_id: 66

author:
- kyryl horbushko
- Lviv
---

Creating a program should be a fun and interesting task. But, often, when I work on some project (mostly in those where some support is needed), I have a feeling that I don't want to fix some bug or to resolve some issue or even to add some functionality. 

Personally, for me, this means that code is a bit <s>shitty</s>, sorry - in a state that needs to be improved. The main question here - why and how we, as developers, produce such code. Where is the root cause for this?
<!--more-->

I was thinking a bit and analyzing a few of the projects, taking in mind the team composition and schedules, development plan, and Customer requirement, and found a few causes for such state of code:

- developers have a small experience and have no/limited **supervising for** their **code**
- the team is distributed and there is **no "team spirit"** (heh, *"hello covid19"*)
- the issues/bugs are not fixed, but often just make to be disappeared from the code, effect of [**the *"broken window"***](https://www.britannica.com/topic/broken-windows-theory)
- there is no **clear vision** where the **project** is moving and whats the goal
- **developers** who work on the project **don't care**
- Customer don't care about the code quality - **functionality first**

Personally, for me, this is a pain point. In general, I like to work on a project where documentation is available, code style is defined and followed, and the team understands where to go; where every team member is responsible for the application, and not just for the code he/she wrote. 

> I already wrote some article about code quality and support activities like this one about [codestyle]({% post_url 2021-09-05-watch-your-language %}) and another one about [styleguide]({% post_url 2021-06-15-styleguide %}) or even this one about [documentation and it's role for the project]({% post_url 2021-01-26-project-documentation %})

I know, I know, this is more looks like an idealistic project, and often, building a team is a long process. But the result worst this. 

> To be honest, I can create a utility app or some similar POC app without following any style guide or code quality, but this is mostly my experiment. Sometimes I use it in development and then refactoring is my best friend. ;]

Let's review a bit in detail all aspects and reasons that I mention above in a bit more detail, to understand what can be done for improving the code and making this *shitty-code feeling* disappear.

> If u wonder what shitty-c0de means, u can visit one of the resources for this topic, like [this one](https://shitcode.net) or [this](https://shitcode.tech) and read about some aspects and it's characteristics.
>
> The big problem here is to be able truly to determine such kind of code and don't just tell that everything is bad, doing the same bad things by yourself (like described [here](https://devrant.com/rants/498999/so-i-had-a-guy-in-my-team-all-day-shouted-shitty-code-this-shitty-code-that-toda))

## Inexperienced developers produce low-quality code

When I just started, I was very happy when something is works as I want. This doesn't mean that the code was fine or well structured and clean. It's just working. I was happy ;].

In most cases this means that *it's work - don't touch it.* In other words - the code was poorly designed and often use some side effects or even something that is not needed at this moment. The only good news was that it worked. 

> For now, I always think about what I just wrote and imagine a case when I asked to change something in this feature. I ask myself - *"Do I want to go to this code and introduce some changes?"* If the answer is **NO** - then, I didn't complete the task yet. 

I guess such a situation (when we try to learn something and it's *just work*) is a good one for inexperienced developers - we learn something when we make a mistake. For the project itself, from the other side, this is a bad case. This may result in a quite big problem in the future. 

> Check out ["Clean architecture" from Uncle Bob](https://www.amazon.com/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164), chapter 1, where he described the case when with each release the code support becomes harder and harder if it's designed not well. I describe, I guess, one of the root cause for such a case.

The only way to go in such a situation (or the most obvious) - is to have a supervising from a more experienced developer, from the one, who can check and advise how to do something in a better way.

Skipping any actions, in this case, may work only if u need some MVP version or the one-shot app. Also if u don't care about the project and release only the first version and then u'r work is done. But, as u already think, this is not a good way of doing something.

In case, when u have a few junior developers on the project and a bunch of experienced ones, but who care only about their part of the code, the situation may become even worse. The customer may decide that codebase is quite good for supporting and developing the project in a long term.

As result, u can be faced with a project, that sometimes is not bad and even perfect, and sometimes is like a test-field for something. Often, with such a code-base developers try to move one part of the code and add some workarounds to make a new feature live, skipping the normal way.

If u facing with such projects, u often can find very interesting code, that does a lot and does nothing that u need. U can't just change something - u need to check all the app after even the smallest change.

Here are a few examples that include various issues:

> All examples is taken from the real mobile projects

{% highlight swift %}
func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let controller = self.viewControllers?[2], viewController == controller, !UserDefaults.standard.userExists() { // unsafe
            addInfoView(.standard) // side effect
            return false
        } else if let controller = self.viewControllers?[3], viewController == controller { // unsafe
            self.updateRootTabState()  // side effect
            switch rootTabState {
            case .none:
                addInfoView(.reserve)  // side effect
                return false
            case .loggedIn:
                presentFlowIntroView()  // side effect
                return false
            case .persisted:
                return true
            }
        } else {
            return true
        }
    }
{% endhighlight %}

The code above contains a lot of side effect. How can u change some navigation not breaking the logic?.

{% highlight swift %}
  ((tabBarViewController?.children.first as? UINavigationController)?.viewControllers.first(where: { $0.presentedViewController != nil }) as? BaseViewController)?.presentedViewController?.dismiss(animated: true, completion: { 
     presentee?.pushParentalControlPreviewInfoViewController(with: fetchItem)
  })
{% endhighlight %}

or how about this - hardcoded complex viewControllers stack and some deal with it.

There is a good rule exist - [composition over inheritance](https://en.wikipedia.org/wiki/Composition_over_inheritance). But sometimes even a good things can be transformed to a bad one:

{% highlight swift %}
final class HomeViewController: BaseTableViewController,
                                  TabsLoadableProtocol,
                                  ScrollableProtocol,
                                  SubscribeProtocol,
                                  NavigationBarConfigurableProtocol,
                                  ArtistInfoFetchableProtocol,
                                  GUITopViewControllerProtocol,
                                  DummyStatusBarProtocol,
                                  AdvanceInfoFetchableProtocol,
                                  DummyBackGestureProtocol {

// where BaseTableViewController is

class BaseTableViewController: BaseViewController,
                                  IConfigureDataSourceProtocol,
                                  IBaseTableViewController

// and BaseViewController

class BaseViewController: UIViewController,
                              OrientationalProtocol,
                              GUiHapticFeedbackProtocol,
                              IDataSourceProtocol,
                              BottomViewAnimatableProtocol,
                              TabBarFetchableProtocol,
                              INetworkServiceProperty,
                              IDestroyable,
                              FailureAlertableProtocol,
                              ObjectFetchableProtocol,
                              SafariPresentableProtocol,
                              IBaseViewController {

{% endhighlight %}

add to this that each protocol provides some default implementation for required properties or/and method (aka injection) and that some subclasses override this functionality.

Some of the protocols are composable from a few more. 

For example, this concrete class conforms to 28 protocols and has 3 levels of inheritance. In addition to this, there are a lot of extensions dedicated to types that conform to a few protocols... U can simply lost in functionality.

For me always works rule 3-5-7 - the numbers which humans can effectively operate with. and 28 (from the sample above) is not in that list.

> Actually, the original rule sad that humans can operate with 7 +/-2 items efficiently. The author of the rule - [Miller (1956)](https://en.wikipedia.org/wiki/The_Magical_Number_Seven,_Plus_or_Minus_Two)*. But, some of the [alternative research sad](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2864034/), that it's better to use 3-5-7 rule, a bit more efficient.

another example can be a method declaration like this:

{% highlight swift %}
static func configure(
  with title: String,
  placeholder: String,
  placeholderColor: UIColor,
  placeholderFont: UIFont,
  textInfo: String,
  borderColor: UIColor,
  borderWidth: CGFloat,
  shadowColor: UIColor,
  shadowOffset: CGSize,
  shadowOpacity: CGFloat,
  contentInset: UIEdgeInsets = UIEdgeInsets(
    top: .zero,
    left: .zero,
    bottom: Defaults.Sizes.plainTextBottomContentInset,
    right: .zero
  ),
  textAlignment: NSTextAlignment = .left,
  textFont: UIFont = UIFont.systemFont(
    ofSize: 16.0,
    weight: .medium
  ),
  textColor: UIColor = AppConfigManager.shared.design.textColor,
  isScrollEnabled: Bool = true
) -> PlainTextViewController? {
{% endhighlight %}

and so on... 

## Distributed team

The team spirit is very important. There is can be an exception when someone can efficiently work alone, but such cases have a limit - u can't deliver all at a required schedule. This works only for small projects.

When u know u'r teammates, u know the strength and weaknesses of each team player, u understand the mood of each developer, u know in what area someone is God-like and where and when it's better to give the task to another team player.

Understanding each person's abilities and being able to work as one organism it's sometimes more important than initial team knowledge - this can allow u to develop the team and make it more efficient.

There is an idea, that any success consists from 95% of work and 5% of talent. Knowing the team helps u to utilize all 95%.

> Alternative [quote](https://www.goodreads.com/quotes/115696-genius-is-1-talent-and-99-percent-hard-work) from **Albert Einstein** - *"Genius is 1% talent and 99% percent hard work..."*

I know the developers who are not talented, but who work hard and use all 95%. At some moment I have a friend of mine who is very talented and catches everything on the fly - his 5% works just great. But, he didn't work hard. And as result, in comparison, these 2 developers are even. 

If u'r team distributed and u don't know u'r teammate how can u utilize all 95%? U simply can't.

With covid19 this problem is even lighter for us. 

As for me, I need to know each member of my team. We can achieve this using remote communication, but the time needed for this is HUGE.

Working with unknown team members also can lead to the effect, that no one cares about someone's code. U never saw that person, u don't know who it's - why should I care about some stuff that he/she is working on. 

There is no one concrete solution for this. I can say only, that working with friends it's much better - because the work and spending time on it it's a part of the developer's life. And better spend this time with friends/family than with some guy.

## Resolved but not fixed

Often, I saw a case, when someone want to fix the bug, he tried to guess the root cause and provide *"momentary fix"*. The result is unexpected - sometimes it works, sometimes no.

Such an approach often fixes the result of the bug, but not the bug itself - the result, we hide the problem and let it become bigger and more powerful. It's like if u have a headache and u decided to break the finger - while u have a problem with u'r finger - u'r head is ok. ;].

> Someone may mention, that there is a well-known debug method when u guess the root cause and fix it. Yes, but this only works if u know the code-base and u know what are u doing. In case when u just guess what to change so the problem disappears - this is the wrong approach.

The last time when I found such code - the problem was quite simple - when u send a double number to the server - the server rounds up it. This number represents the coordinate of a point of view. As result, developers adjust the way how this point is used in the coordinate system, then, how this coordinate is interpreted during user interaction, and finally, how it is then processed with some data.

I was asked to modify it a bit the process. I started from the other side and implement the required functionality, but, it was a surprise for me, that new functionality can't be mapped to the existing one - of-cause - I used precise values, and devs update all the code to use with rounded values, losing precision. As a result, I reimplement all parts and ask server devs to fix the issue. 

The time spent on this was twice as big as my estimate. Of cause, I can also use this workaround, and the problem will be copy-pasted and raised for the next devs. But we would like to make our code better and better ([boy-scout rule](https://deviq.com/principles/boy-scout-rule)).

This is one of the thousands of examples of such situations. 

That's why fixing is important, not just resolving the issue.

My way to deal with bugs contains a few steps, combined with various approaches. Here they are:

- reproduce the issue
- find the code that is failing
- write a test (should fail also, due to bug)
- fix the bug
- check test from the step above

These simple steps make the code rock!

## Clear vision of the project

Why does this matter? Let me tell u one story. 

On some project "A", I and my team received a task, that a bunch of functionality should be done to a certain deadline. The target date was ambitious, but, with nights and some black magic, we did this. We not only complete all the tasks, but also we tried to produce clean and easy-to-support code with code coverage of about 85% for business logic. This took us 2.5 months.

The next day we complete this milestone, we got a new message, that now, we should make a turn for the app to 180 degrees and add completely different functionality, that not just discard our previous work, but has some conflicts with the previous idea. So the only solution was to start everything again. But the problem, that Customer has a presentation related to the product in a month. We were asked again to fit 3-month work into 1 month. We did it. Both supported mobile platforms and BE was done. Again, with the same quality and with the same idea as at the first time.

We were confused a bit and tired, but we were able to complete all the work. After a week or so, we were surprised again - the Customer change the whole idea of the app, one more time... And the release date for new functionality again was in a month or so... The team was exhausted. 

We simply were confused - what's going on? Where are we moving to?. 

Knowing the final destination can help a lot - we can improve all our processes and also our code. We know why we do this and we can predict how to code will be used and supported.

> The end of the story - 3rd release was the final one. After almost 6m of development, we released very simple functionality with advertisement and contact form. The future of the project? Hm... Few developers take a work-break, other change the project. 
 

## Developers who care

This reason is very simple - if u care, u think, u try to do all the best. If no, well - u don't.

Now imagine the developer who doesn't care about the project. What will u receive? 

The same rules applied not only to developers but to every team member. Only 1 can make the project fail. 

Same true, if Customers care about only functionality - **functionality first**. If we must do it quickly, then what quality we can talk about?

Remember these 3 circles with small intersections - quality, cost, speed.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-24-shitty-code feeling/cost-speed-quality-venn-diagrampng.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-24-shitty-code feeling/cost-speed-quality-venn-diagrampng.png" alt="components.png" width="450"/>
</a>
</div>
<br>
<br>

> I borrow this image somewhere on the web...

Remember always about these rules. 

## Conclusion

Why I'm writing about this? Well, when I think about some projects, ideas behind and how it's done - I have a shitty-code feeling. A bad feeling - I don't want to support it or change something there. 

The good point - is that we always can improve everything. I guess thinking about the reasons that I described above and working with the root cause of these problems, we can make the project, even the worst one, better. 

Thinking about these problems from the beginning - can make this feeling goes away.

## P.S.

I like to code and do something interesting, but, when I see something in code like in situations described above, I'd rather spend some time for something more valuable - like play with my son and assemble some lego toy:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-12-24-shitty-code feeling/raptor.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-12-24-shitty-code feeling/raptor.png" alt="raptor" width="350"/>
</a>
</div>
<br>
<br>

## Resources

* [shitcode.net](https://shitcode.net)
* [shitcode.tech](https://shitcode.tech)
* ["Clean architecture" from Uncle Bob](https://www.amazon.com/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164)


\* Miller GA. The magical number seven, plus or minus two: Some limits on our capacity for processing information. Psychological Review. [1956;63:81–97.](https://psycnet.apa.org/record/1957-02914-001)