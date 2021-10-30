---
layout: post
comments: true
title: "Font magic"
categories: article
tags: [swift, font, ftxdumperfuser, descender]
excerpt_separator: <!--more-->
comments_id: 61

author:
- kyryl horbushko
- Lviv
---

Making a good app requires that all components was done properly and look and feel natively. Every button, every message should be perfectly aligned and configured.

But sometimes the problem waits for u in the most unexpected places. 
<!--more-->

Recently I have faced with custom font problem - the font is not properly aligned vertically. I'm talking about a font, that was used for Arabic localization and has the name `FFShamelFamily`. 

The reason of issue was that [`Descender`](https://en.wikipedia.org/wiki/Descender) property of the font was incorrectly configured. And this results into next:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/issue.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/issue.png" alt="issue" width="300"/>
</a>
</div>
<br>
<br>

## Font

To fix this problem we can try to use some *dark magic* regarding every element that can show text, aka:

{% highlight swift %}
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.lineSpacing = lineSpacing
paragraphStyle.lineHeightMultiple = lineHeightMultiple
{% endhighlight %}

This is a naive and error-prone approach that should be skipped at the very beginning.

The better way to do this - is to dive a bit into fonts, and understood how it works and which components it has.

As always, 1 image worce a 1000 words. In this case I found at some post this:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/font_components.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/font_components.png" alt="font_components" width="400"/>
</a>
</div>
<br>
<br>

Now, even without deep dive into font anatomy, we can see the problem-making part of the issue - descender. 

The good question here is how we can modify this descender. Reading a bit more about the font and how do they create and managed, I found that there is a special table, that can control a lot of font parameters. The name for this table - [`hhea` (Horizontal Header Table)](https://docs.microsoft.com/en-us/typography/opentype/spec/hhea)

### The `hhea` table

If we check Apple's post about it [available here](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6hhea.html), we can find that *The 'hhea' table contains information needed to layout fonts whose characters are written horizontally, that is, either left to right or right to left. This table contains information that is general to the font as a whole. The information which pertains to specific glyphs is given in the 'hmtx' table.* 

There are a lot of params that we can use to modify the font:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/hhea.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/hhea.png" alt="font_components" width="400"/>
</a>
</div>
<br>
<br>

> [source](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6hhea.html)

There are a lot of other components in fonts, to know all about which required a separate book at least. But for us, this information is enough and we can move forward.

## Font modification

The next step - we should find a way how we can modify the font. Luckily for us, Apple prepared a set of tools, that can be used for such modification and is available [here](https://developer.apple.com/fonts/).

U can check this [link ](https://developer.apple.com/download/all/?q=font) to find out the latest font tools available. The good thing is that this package contains a lot of the tutorials and information needed for working with a font.

In our case, the problem can be solved with `ftxdumperfuser` that can modify font attributes.

First - we should read attributes:

{% highlight sh %}
ftxdumperfuser -t hhea -A d <font>
{% endhighlight %}

in my case:

{% highlight sh %}
khb@MacBook-Pro-Kyryl test % ftxdumperfuser -t hhea -A d /Users/khb/Desktop/example/FFShamelFamily-SemiRoundBold.otf
{% endhighlight %}

This produce additional file `FFShamelFamily-SemiRoundBold.hhea.xml`:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/file.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/file.png" alt="file" width="300"/>
</a>
</div>
<br>
<br>

With content:

{% highlight xml %}
<?xml version="1.0" encoding="UTF-8" standalone="no" ?>
<!DOCTYPE hheaTable [
<!ELEMENT hheaTable EMPTY>
<!ATTLIST hheaTable versionMajor CDATA #IMPLIED
	versionMinor CDATA #IMPLIED
	ascender CDATA #IMPLIED
	descender CDATA #IMPLIED
	lineGap CDATA #IMPLIED
	advanceWidthMax CDATA #IMPLIED
	minLeftSideBearing CDATA #IMPLIED
	minRightSideBearing CDATA #IMPLIED
	xMaxExtent CDATA #IMPLIED
	caretSlopeRise CDATA #IMPLIED
	caretSlopeRun CDATA #IMPLIED
	caretOffset CDATA #IMPLIED
	metricDataFormat CDATA #IMPLIED
	numberOfHMetrics CDATA #IMPLIED
>
]>
<!--
	
	Data generated 	2021-10-30, 09:56:19 GMT+3
	Generated by ftxdumperfuser build 359,
		FontToolbox.framework build 353
	
	Font full name: 'FF Shamel Family SemiRound Bold'
	Font PostScript name: 'FFShamelFamily-SemiRoundBold'
	
-->
<hheaTable
	versionMajor="1"
	versionMinor="0"
	ascender="1100"
	descender="-1100"
	lineGap="0"
	advanceWidthMax="1564"
	minLeftSideBearing="-329"
	minRightSideBearing="-330"
	xMaxExtent="1564"
	caretSlopeRise="1"
	caretSlopeRun="0"
	caretOffset="0"
	metricDataFormat="0"
	numberOfHMetrics="254"
	/>
{% endhighlight %}

Here we can easily found the trouble-maker:

{% highlight xml %}
descender="-1100"
{% endhighlight %}

We can change this value (in my case to -500) and pack it back to font, using a similar command:

{% highlight sh %}
ftxdumperfuser -t hhea -A f <font>
{% endhighlight %}

{% highlight sh %}
khb@MacBook-Pro-Kyryl test % ftxdumperfuser -t hhea -A f /Users/khb/Desktop/test/FFShamelFamily-SemiRoundBold.otf 
{% endhighlight %}

Result:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/fixed_issue.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/fixed_issue.png" alt="fixed_issue" width="300"/>
</a>
</div>
<br>
<br>

## pitfalls

On prev os version OS fonts packadge failed during installation:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/failed.png">
<img src="{{site.baseurl}}/assets/posts/images/2021-10-30-font-magic/failed.png" alt="fixed_issue" width="400"/>
</a>
</div>
<br>
<br>

There is a great step-by-step guide available [here](https://apple.stackexchange.com/a/328214) if u faced with a similar problem

Alternatively, u can use various font-editing tools like [FontForge](http://fontforge.github.io/en-US/downloads/mac/) if u find this way not appropriate for u. Another alternative is [Glyphs](http://glyphsapp.com/). Example described [here](https://stackoverflow.com/a/16798036/2012219).

## Resources

* [Custom font line height](http://shaunseo.blogspot.com/2013/05/custom-font-line-height.html)
* [`Descender`](https://en.wikipedia.org/wiki/Descender)
* [`hhea` (Horizontal Header Table)](https://docs.microsoft.com/en-us/typography/opentype/spec/hhea)
* [The `hhea` table](https://developer.apple.com/fonts/TrueType-Reference-Manual/RM06/Chap6hhea.html)
* [Apple font tools](https://developer.apple.com/fonts/)
* [SO - install OS tools](https://apple.stackexchange.com/a/328214)