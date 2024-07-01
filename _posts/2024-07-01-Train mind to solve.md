---
layout: post
comments: true
title: "Train the mind to solve"
categories: article
tags: [UI, tutorial, hack, problem-solving flutter, dart]
excerpt_separator: <!--more-->
comments_id: 107

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

Often, during development and in real life we face various problems that are hard or even impossible (at first look) to solve. As a result, some of us look for alternatives or even give up by accepting simpler or different ways, and another part continues to gnaw the problem until it's solved.

I want to believe that I'm a person from the second group - I like to solve problems and find solutions for unusual problems. Such an approach provides a lot of proc

- u'r mind becomes more flexible
- u can look at a problem from different points 
- it's simply interesting and fun

In this article, I want to describe one of such problem and how it can be solved.

## Problem

I'm still playing a bit with Flutter, and during one more task, I faced with problem, one of the UI components used in the project did not support dedicated functionality. Pretty usual use-case.

I have a slider, a range slider, and this slider works just great, but, it does not support a mask for a track bar with some image pattern.

Expected design: 

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/expected_slider.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/expected_slider.png" alt="expected_slider.png" width="300"/>
</a>
</div>
<br>
<br>


Existing UI: 

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/range_slider_no_pattern.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/range_slider_no_pattern.png" alt="range_slider_no_pattern.png" width="300"/>
</a>
</div>
<br>
<br>

API for UI element does not allow to put image with repeat pattern - the only thing it allows - is to send [Paint](https://api.flutter.dev/flutter/dart-ui/Paint-class.html) object:

{% highlight dart %}
...
Paint activePaint,
Paint inactivePaint,
...
{% endhighlight %}

> To be more precise, here is a library for slider used [SfSlider](https://help.syncfusion.com/flutter/slider/overview)

## Solution

As usual, we must have at least a few options to solve this, the tricky moment is to see them:

- to remake the components from scratch and to add all required functionality
- copy the library and remake functionality by converting UI-element to one that can do everything we need (in other words - same as solution 1 but with prepared code)
- find an alternative ui-element library

I decided to go in the next way:

- inspect [Paint](https://api.flutter.dev/flutter/dart-ui/Paint-class.html) and all related objects, also inspect in more detail API and then decide either
	- re-create components from scratch
	- find the option to modify the existing components to make them work as I need
	
### Painting

Thus I have quite a long background in iOS, especially with [CGContext](https://developer.apple.com/documentation/coregraphics/cgcontext), painting in flutter is pretty similar and it's easy to compare and see that the same things exist here but with different name.

The most interesting thing from all the APIs available for use is the possibility of creating a custom object for `TrackShape` with a rich *paint* function:

{% highlight dart %}
/// Paints the track based on the values passed to it.
void paint(PaintingContext context, Offset offset, Offset? thumbCenter,
  Offset? startThumbCenter, Offset? endThumbCenter,
  {required RenderBox parentBox,
  required SfSliderThemeData themeData,
  SfRangeValues? currentValues,
  dynamic currentValue,
  required Animation<double> enableAnimation,
  required Paint? inactivePaint,
  required Paint? activePaint,
  required TextDirection textDirection})
{% endhighlight %}

the most interesting for us - is access to `PaintingContext context` - a canvas for drawing. So in theory we can draw there anything we want.

So, quick inspection means, that in theory, we don't need to rewrite UI components (a huge time-saver), the only thing left - is to prepare a custom drawing that represents a repeating drawing pattern.

In my case, I need to draw kind of arrows - pretty simple shapes:


<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/expected_slider.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/expected_slider.png" alt="expected_slider.png" width="300"/>
</a>
</div>
<br>
<br>

So, we need to draw a few lines one by one in a kind of arrow shape. 

If I need to draw some shape, I always prepare a draft - that simplifies everything dramatically:


<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/draw_draft.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/draw_draft.png" alt="draw_draft.png" width="300"/>
</a>
</div>
<br>
<br>

Now we can see, that it's not a problem to calculate the line points needed to be drawn to get the dedicated pattern. Lines according to design must have some width. 

According to Scatch, we can see, that if we have a line, with some width - that part of the line will be out of the track border. We can apply some clip behavior (kind of mask), but as u can see, everything in the component is drawn on canvas, including thumbs, that intersects with the track.. so applying clip behavior will affect thumbs.

Quick test showing this behavior, as expected:


<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/draw_thinkness.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/draw_thinkness.png" alt="draw_thinkness.png" width="100"/>
</a>
</div>
<br>
<br>

As a quick hack, we can reduce the thickness of the line to 1px, and repeat the same color of the line as many times until we receive the required width. In other words, we repeat the same process N times, but the outer part will be much smaller.

Repeating the same math for drawing with smaller thickness gave us a dedicated result:


<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/draw_final.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/draw_final.png" alt="draw_final.png" width="100"/>
</a>
</div>
<br>
<br>

This option still has the same problem, but I'm much, much smaller way:


<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/final_enlarged.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/final_enlarged.png" alt="final_enlarged.png" width="300"/>
</a>
</div>
<br>
<br>

The demo of the result:


<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/demo.gif">
<img src="{{site.baseurl}}/assets/posts/images/2024-07-01-Train-mind-to-solve/demo_small.gif" alt="demo.gif" width="300"/>
</a>
</div>
<br>
<br>


<details><summary> The full code is here </summary>
<p>
{% highlight dart %}

... 
  //calculating rect and other stuff here

  context.canvas.drawRect(activeTrackRRect, activePaint);

  // Drawing hatch
  const double drawLineWidth = 1;
  final height = activeTrackRRect.height - drawLineWidth;

  // a/sin(A) = c/sin(C)
  const angle = 50;
  const angle2 = 180 - (90 + angle);
  final distance =
      (height / sin(degreeToRadian(angle))) * sin(degreeToRadian(angle2));

  var colorOne = Paint()
    ..color = hatchFirstColor ?? Colors.grey
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = drawLineWidth;

  var colorTwo = Paint()
    ..color = hatchSecondColor ?? Colors.black
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = drawLineWidth;

  const double yPoint = 0;
  double yOffset = activeTrackRRect.topLeft.dy;
  double xOffset = activeTrackRRect.topLeft.dx;

  const double hatchThinkness = 10;

  for (double i = drawLineWidth * 1.5 + drawLineWidth * hatchThinkness + xOffset, j = 0;
      i <= activeTrackRRect.width + xOffset + drawLineWidth * hatchThinkness;
      i += drawLineWidth * 1.5, j++) {
    var p1 = Offset(i, yPoint + yOffset);
    var p2 = Offset(i - distance + drawLineWidth / 3,
        startThumbCenter.dy + drawLineWidth / 3);
    var p3 = Offset(i - distance + drawLineWidth / 3,
        startThumbCenter.dy - drawLineWidth / 3);
    var p4 = Offset(i, (p2.dy - p1.dy) * 2 + yOffset);

    final colorSelector = (j ~/ hatchThinkness).isOdd;
    final colorPainter = colorSelector ? colorOne : colorTwo;
    context.canvas.drawLine(p1, p2, colorPainter);
    context.canvas.drawLine(p3, p4, colorPainter);
  }

{% endhighlight %}
</p>
</details>
<br>

## Conclusion

Do not hurry up in making a decision - invest some time into a detailed review of the problem, in the worst case just learn something new.


## Resources

- [Paint](https://api.flutter.dev/flutter/dart-ui/Paint-class.html)
- [SfSlider](https://help.syncfusion.com/flutter/slider/overview)