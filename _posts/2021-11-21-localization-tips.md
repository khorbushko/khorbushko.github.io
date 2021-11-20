---
layout: post
comments: true
title: "Localization - do it right!"
categories: article
tags: [iOS, localization, L10n]
excerpt_separator: <!--more-->
comments_id: 64

author:
- kyryl horbushko
- Lviv
---

Our apps can be used by different people, that use different languages. To help us achieve the best experience, we have to perform app localization. This is a process that includes a lot of steps and sometimes may be a bit painful when using it with iOS.
<!--more-->

Below are a few tips, that can help while localizing the app.

## reinvent the wheel?

A lot of times during various app preparation I was asked to prepare a system that can do something special with localization - like "switch language on the fly" or "support RTL/LTR only on some screens" or even more exciting feature(s).

> To be honest I [did stuff like mentioned above](https://stackoverflow.com/a/45055545/2012219) and as Apple engineers told, in some of their [answers](https://developer.apple.com/forums/thread/13155?answerId=36704022#36704022) on forums, I have faced with issues that can't just be resolved. Result - a lot of custom components that mimic native one and a few workarounds... Not the best experience and not something that I'm very proud of.
>
> There are a few more resources (like [this](https://medium.com/swift2go/forcing-ios-localization-at-runtime-the-right-way-8afa0569162a)) that tell us that "reinventing the wheel" in terms of localization is a bad idea

The good thing here - is the knowledge that u receive when u try to create something, already created and well designed. But in most cases, this is just a time waste.

There is an old post from [Jeff Atwood](https://stackoverflow.com/users/1/jeff-atwood) about ["reinventing the wheel"](https://blog.codinghorror.com/dont-reinvent-the-wheel-unless-you-plan-on-learning-more-about-wheels/) - (actually I grab an idea for this section name from his post), where he put an interesting quote from another developer:

> *" I reinvented the wheel last week. I sat down and deliberately coded something that I knew already existed, and had probably also been done by many many other people. In conventional programming terms, I wasted my time. But it was worthwhile, and what's more, I would recommend almost any serious programmer do precisely the same thing."*

So I want to believe that this experience was very useful for me, but... I won't repeat that. 

Another moment that u need to be sure of before starting implementing something (and this is not just related to localization) - is that such a case is not handled for u by one of the available functions. A good example here is plural handling. Often, I saw some workarounds for this, which usually has a lot of code and unnecessary work.

## devil in the details

Another moment that I want to highlight is small details, that are often not completely understood. This is not something specific and unique to the localization, so I guess this can become a good rule for any new thing u want to learn.

> As for me, I like to read all docs firstly and create a solid theoretical background before making my hands dirty. But such an approach requires a lot of time and is sometimes just not applicable.

In regards to localization I think that is good to know a few things:

- difference between [localization - L10n](https://en.wikipedia.org/wiki/Language_localisation) and [internalization - i18n](https://en.wikipedia.org/wiki/Internationalization_and_localization). There is also a [globalization - g11n](https://en.wikiversity.org/wiki/Localization#Internationalization). So it's good to be sure that all these names are correctly mapped in your brain before u start.
- difference between [Locale and Language](https://docs.microsoft.com/en-us/windows/win32/intl/locales-and-languages)
- understand [Base Internationalization](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/InternationalizingYourUserInterface/InternationalizingYourUserInterface.html#//apple_ref/doc/uid/10000171i-CH3-SW2) for xCode
- [RTL vs LTR](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/SupportingRight-To-LeftLanguages/SupportingRight-To-LeftLanguages.html#//apple_ref/doc/uid/10000171i-CH17-SW1)
- [plist localization](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html)
- [testing localization with xCode](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/TestingYourInternationalApp/TestingYourInternationalApp.html)
- don't forget about audio/video/image localization. Try to exclude texts from images

I guess this is must to know things that will make u'r app localization easy and fast.

I won't cover all of these points, thus a lot of nice tutorials are available over the network - instead, I just listed them all in one place.

> Various services for localization provide a nice tutorial like [this one](https://www.oneskyapp.com/blog/the-ultimate-guide-to-ios-localization/) from Oneskyapp.

## continuous localization

Every project that has a few platforms support if not use a common base for localization earlier or later will face translation sync. The easy to solve this issue problem is to use continuous localization. 

A lot of services are available for this - free and paid. 

Here are a few examples:

- [POEditor](https://poeditor.com/projects/)
- [Phrase](https://phrase.com)
- [Crowdin](https://crowdin.com)
- [LocalizationKit](https://github.com/willpowell8/LocalizationKit_iOS)
- [Spreadsheet Localization](https://github.com/NeverwinterMoon/localize-with-spreadsheet-2)

Often it looks that this requires more work at the start, but, believe me - this process must be added to u'r project.

> Recently, I was asked to prepare a *free* version of continuous localization using some service. I choose POEditor - thus it has a good free plan and a nice API. Of cause, without live connection, using sockets for example (like in `LocalizationKit`), it's hard to implement this. 
> 
> The result for a demo was an approach that can be named as a delayed continuous localization - the app tries to update the translation every time it's become active.
> 
>  Using initial values and receiving one, the demo goal was achieved.
> 
{% highlight swift %}
extension L10n {
  static func translateWithPOEditor(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    if let value = POEditorData.instance[key] {
      return value
    } else {
      let format = BundleToken.bundle.localizedString(forKey: key, value: nil, table: table)
      return String(format: format, locale: Locale.current, arguments: args)
    }
  }
}
>
private final class BundleToken {
  static let bundle: Bundle = {
    return Bundle(for: BundleToken.self)
  }()
}
{% endhighlight %}
>
> Off cause, for production purposes it's hardly usable, but for a demo, it works just fine. If u interested in source code - [download files]({% link assets/posts/images/2021-11-21-localization-tips/source/POEditor.zip %}).

## strong string

Strings provide us a lot of options to make a typo, and so introduce a mistake, that can be hard to detect. To exclude (or minimize) such moments, I suggest using an approach that replaces strings with some strongly typed variables/constants.

As an option, we can use already created approaches. 

> I recently wrote an article about [one of such approaches]({% post_url 2021-04-04-strings %})

I also can suggest dividing the `Localizable. strings` file by functionality. I saw a project where strings file contains more than 4k lines... can u imagine how to maintain this?

### tech tips

#### ASC||Property list

Of cause, some sort of errors can be easily found. For example - if u miss `;` or `=` at the line u can try to open it using `ASC||Property list`

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-11-21-localization-tips/open.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-11-21-localization-tips/open.png" alt="open.png" width="250"/>
</a>
</div>
<br>
<br>

and u will get the line number with error:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-11-21-localization-tips/error.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-11-21-localization-tips/error.png" alt="error.png" width="250"/>
</a>
</div>
<br>
<br>

But searching and managing big files always require more attention and effort than for smaller ones.

#### plutil

Another option that u have - is to use [`plutil`](https://www.theiphonewiki.com/wiki/Plutil) - *is a program that can convert .plist files between a binary version and an XML version.*

This utils can help us to inspect localization for some syntax errors:

{% highlight swift %}
plutil -lint <filePath>
{% endhighlight %}

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-11-21-localization-tips/plutil.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-11-21-localization-tips/plutil.png" alt="plutil.png" width="450"/>
</a>
</div>
<br>
<br>

> U can see success check and failed one with concrete line number.

These utils also allow modification and conversion of the file, but it's not very useful when dealing with localization.

#### localization preview

In SwiftUI u also now able to preview the localized content:

{% highlight swift %}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.locale, .init(identifier: "uk"))
    }
}
{% endhighlight %}

This is easy to use, but often not used. xCode also provides a lot of tools for localization testing. I won't cover them all, thus they are well described [here](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/TestingYourInternationalApp/TestingYourInternationalApp.html).

Below is a table with arguments that can be used for debug localization in xCode:

|   Launch Option  |   Values  |   Usage  |
|---|---|---|
|   -AppleLocale  |   Any locale identifier (e.g. 'en', 'it', 'es')  |   Force the locale on app launch  |
|   -NSDoubleLocalizedStrings  |   YES, NO  |   Doubles the length of all localized strings, e.g. "Word" => "Word Word" to debug layout issues  |
|   -NSShowNonLocalizedStrings  |   YES, NO  |   Shows non-localized strings in ALL CAPS so they're easier to spot  |
|   -NSForceRightToLeftWritingDirection  |   YES, NO  |   YES to force right-to-left mode to engage (even in non-RTL languages)  |
|   -AppleLanguages  |     |   starts app with selected locale  |

#### use Pluralization

Handling different plural variants depending on an input value is a common task. Often developers just use a code like this:

{% highlight swift %}
let singleBox = L10n.Step1.Hint.singleBox
let fewBox = L10n.Step1.Hint.fewBoxes
let localization = boxPositions.count > 1 ? fewBox : singleBox
let boxCountLocalizedValue = "\(boxPositions.count) \(localization)"
{% endhighlight %}

The complexity of the codebase increased. And same code will be repeated in case of a few places where it needs to be used.

Pluralization simplifies this process. A good process description can be found [here](https://developer.apple.com/documentation/xcode/localizing-strings-that-contain-plurals)

#### formatting

Don't forget about various formatting like currency, date, numbers, etc. A lot of formatters from `Foundation` can handle this for us. Try to use them instead of a custom one.

#### images

I already mentioned this above, but I think it needs to be repeated - DON'T include text in images. yes, u can localize images, but this is a bad approach. The downsides of this process are visible (additional size, additional work for designer, minimal flexibility, etc), but sometimes it's still usable.

As for me - this is the same as if u use a set of images for [UIImage.animatedImages](https://developer.apple.com/documentation/uikit/uiimage/1624149-animatedimage). 

This is possible, but, as for me, this introduces more problems for u'r project.

#### 3rd party tools 

Sometimes u can't influence the already created processes, as result, u just have an excel or CSV file with keys and translated values. The best that u can do in this case - is to automate this process.

A year ago (or so) I have a project where was exactly this situation. As result, I prepare some utility apps, that parse and update localization files whenever a new xlsx comes with updates.

This looks something like this:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-11-21-localization-tips/custom_tool.gif">
<img src="{{site.baseurl}}/assets/posts/images/2021-11-21-localization-tips/custom_tool.gif" alt="custom_tool.gif" width="450"/>
</a>
</div>
<br>
<br>

This is not something that needs to use everywhere, but at least u can simplify the process.

U can find some similar tools prepared for solving the same problem, for example [this one](https://github.com/NeverwinterMoon/localize-with-spreadsheet-2).

#### hire professional to translate the app

I have a project, where was decided to save some money on translation services and use automated translation (aka google-translation). The result was, as u can imagine, not the best one. The translation sometimes was out of context, so UX was very poor.

## Resources

* [Apple forum: Swift localization](https://developer.apple.com/forums/thread/13155?answerId=36704022#36704022)
* [How does iOS determine the language for my app?](https://developer.apple.com/library/archive/qa/qa1828/_index.html)
* [Don't Reinvent The Wheel, Unless You Plan on Learning More About Wheels](https://blog.codinghorror.com/dont-reinvent-the-wheel-unless-you-plan-on-learning-more-about-wheels/)
* [Localization - L10n](https://en.wikipedia.org/wiki/Language_localisation) 
* [Internalization - i18n](https://en.wikipedia.org/wiki/Internationalization_and_localization)
* [Globalization - g11n](https://en.wikiversity.org/wiki/Localization#Internationalization)
* [Locale and Language](https://docs.microsoft.com/en-us/windows/win32/intl/locales-and-languages)
* [Base Internationalization](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/InternationalizingYourUserInterface/InternationalizingYourUserInterface.html#//apple_ref/doc/uid/10000171i-CH3-SW2)
* [RTL vs LTR](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/SupportingRight-To-LeftLanguages/SupportingRight-To-LeftLanguages.html#//apple_ref/doc/uid/10000171i-CH17-SW1)
* [Plist localization](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/AboutInformationPropertyListFiles.html)
* [Testing localization with xCode](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPInternational/TestingYourInternationalApp/TestingYourInternationalApp.html)
* [`plutil`](https://www.theiphonewiki.com/wiki/Plutil)
* [Pluralization](https://developer.apple.com/documentation/xcode/localizing-strings-that-contain-plurals)