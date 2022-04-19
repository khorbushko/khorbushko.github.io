---
layout: post
comments: true
title: "Android measurement units"
categories: article
tags: [android, measurement, quick-note]
excerpt_separator: <!--more-->
comments_id: 77

author:
- kyryl horbushko
- Lviv
---

How we can determine the value of something - measure it. 

In programming the same thing - we need to have the ability to measure every component and detail of the app UI to make it *pixel perfect*. 
<!--more-->

## intro

On iOS, we use [Points (pts) and Pixels](https://developer.apple.com/library/ios/documentation/2ddrawing/conceptual/drawingprintingios/GraphicsDrawingOverview/GraphicsDrawingOverview.html#//apple_ref/doc/uid/TP40010156-CH14-SW7) and [scale factor](https://developer.apple.com/documentation/uikit/uiscreen/1617836-scale) for [varios displays](https://developer.apple.com/library/archive/documentation/DeviceInformation/Reference/iOSDeviceCompatibility/Displays/Displays.html). Pixels used in rare cases and they used under-the-hood by points, so everyone just uses points. That's it. 

For Android, situation a bit more <s>complex</s> flexible.

## units

In Android, there are a lot of different types of units that can be used in various parts of the app. The big amount of units is due to the evolution and physical characteristics of new screens used on different devices. 

Sometimes real-world measurement values were used, at other times - relative units. But in general - all of them are still available (for back compatibility and great flexibility).

To properly use these units, it's better to one time spend some time and close the question rather than return to this whenever u use some unit.

So, the good points to start - is to list all of the available units:

* dp/dip/dps - **Density-independent Pixels** ( abstract unit that is based on the physical density of the screen)
* sp/sip - **Scalable Pixels** or **Scale-independent pixels** (like dp, but scaled by user font size pref)
* pt - **Points** (1/72 of an inch, based on physical size of the screen)
* px - **Pixels** (actual pixels on screen)
* mm - **Millimeters** (based on physical size of the screen)
* in - **Inches** (based on physical size of the screen)

### dpi

It's also good to know about **dpi** - dots per inches - measuring the pixel density of the screen:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-04-20-android-measurement-units/comparison_dencity.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-04-20-android-measurement-units/comparison_dencity.png" alt="comparison_dencity.png" width="300"/>
</a>
</div>
<br>
<br>

the formula for pixel density:

```
density = screen width/height in px / screen width/height in inches
```

To support different screens and so different pixel densities, Android introduces the next clarifiers:

| Density Qualifier | Density Value | Scale | Description |
|---|---|---|---|
| ldpi | ~120dpi | 0.75x | Resources for low-density (ldpi) screens. |
| mdpi | ~160dpi | 1x | Resources for medium-density (mdpi) screens. (This is the baseline density.) |
| hdpi | ~240dpi | 1.5x | Resources for high-density (hdpi) screens. |
| xhdpi | ~320dpi | 2x | Resources for extra-high-density (xhdpi) screens. |
| xxhdpi | ~480dpi | 3x | Resources for extra-extra-high-density (xxhdpi) screens. |
| xxxhdpi | ~640dpi | 4x | Resources for extra-extra-extra-high-density (xxxhdpi) uses. |
| nodpi | n/a | n/a | Resources for all densities. These are density-independent resources. The system does not scale resources tagged with this qualifier, regardless of the current screen's density. |
| tvdpi | ~213dpi | 1.33x | Resources for screens somewhere between mdpi and hdpi; approximately 213dpi. This is not considered a "primary" density group. It is mostly intended for televisions and most apps shouldn't need it—providing mdpi and hdpi resources is sufficient for most apps and the system will scale them as appropriate. If you find it necessary to provide tvdpi resources, you should size them at a factor of 1.33*mdpi. For example, a 100px x 100px image for mdpi screens should be 133px x 133px for tvdpi. |

> [source](https://material.io/blog/device-metrics)

To convert units we can use the next formula:

```
dp = (px * 160) / dpi
// and back
px = dp * (dpi / 160)
```

> 160 - from baseline density

and in code this can be a bit simplified:

{% highlight kotlin %}
val px = dp * resources.displayMetrics.density
// or
val px = TypedValue.applyDimension(
	TypedValue.COMPLEX_UNIT_DIP,
	dp,
	resources.displayMetrics
  )
{% endhighlight %}

> more about [TypedValue](https://developer.android.com/reference/android/util/TypedValue#applyDimension(int,%20float,%20android.util.DisplayMetrics))

one more notable comparison:

| Unit | Description | Units Per Physical Inch | Density Independent? | Same Physical Size On Every Screen? |
|---|---|---|---|---|
| px | Pixels | Varies | No | No |
| in | Inches | 1 | Yes | Yes |
| mm | Millimeters | 25.4 | Yes | Yes |
| pt | Points | 72 | Yes | Yes |
| dp/dip/dps | Density Independent Pixels | ~160 | Yes | No |
| sp/sip | Scale Independent Pixels | ~160 | Yes | No |

> [source](https://stackoverflow.com/a/2025541) 

## tips

* use **sp** for font sizes and **dip** / **dp** for everything else
* use `wrap_content`, `fill_parent`, or dp units when specifying dimensions in an XML layout file
* don't hardcode pixel values
* don't use AbsoluteLayout (deprecated)
* reuse u'r dimensions using [`<dimen>`](https://developer.android.com/guide/topics/resources/more-resources) ([here](https://stackoverflow.com/a/47321385) is a perfect intrduction)
* use constant values defined by Android SDK in calculations (like `TypedValue.COMPLEX_UNIT_DIP`)

## Resources

* [Dimensions](https://developer.android.com/guide/topics/resources/more-resources.html#Dimension)
* [Pixel density](https://material.io/design/layout/pixel-density.html#pixel-density-on-the-web)
* [Understanding density](https://blog.mindorks.com/understanding-density-independent-pixel-sp-dp-dip-in-android)
* [DP/PX CONVERTER](https://www.pixplicity.com/dp-px-converter)
* [Android units of measurement](https://www.mysamplecode.com/2011/06/android-units-of-measurements.html)