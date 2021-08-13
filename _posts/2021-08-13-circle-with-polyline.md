---
layout: post
comments: true
title: "Draw circle with polyline"
categories: article
tags: [geo, circle, swift, algorithm]
excerpt_separator: <!--more-->
comments_id: 55

author:
- kyryl horbushko
- Lviv
---

Displaying maps on iOS often is not enough. We would like to show some kind of tips, identifiers or other objects. 

If u deal with not only displayable information but also provides functionality for rich editing or creating/managing something - drawing different shapes can be an essential part of this process.
<!--more-->

Previously, I already cover few subjects related to the map, and in this article, I would like to show how we can draw a circle on the map using polyline only. 

> Previous posts related to tasks with map:
> 
* [Covering an arbitary area with circles of equal radius]({% post_url 2021-06-29-covering-an-arbitary-area-with-circles-of-equal-radius %})
* [The area polygon or how to detect line segments intersection]({% post_url 2021-07-15-the-area-polygon-or-how-to-detect-line-segments-intersection %})
* [Area calculation]({% post_url 2021-07-08-area-calculation %})


## The problem

In the current project, we are using maps extensively, but the SDK that we use has some limited out-of-the-box functionality, and drawing the circle is not one of them. What can be done - is just drawing a filled circle, line or polygon. :[

The purpose of such function can be simple hightlight of some circular zone (for example selected spot):


<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-08-13-circle-with-polyline/design.png" alt="design" width="450"/>
</div>
<br>
<br>

> Left side: unselected blue circle and selected white and on right - blue circle selected, white unselected

## The solution

The solution to the problem can be a circle drawn with some kind of simplicity.

The good question here - is "how the circle can be drawn on the screen, in the simplest way possible?". The answer is in the next picture.

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-08-13-circle-with-polyline/sccir03a.gif" alt="how the circle can be drawn on the screen, in the simplest way?" width="250"/>
</div>
<br>
<br>

> This image is from the page [Simple Circle Algorithms](https://www.cs.helsinki.fi/group/goa/mallinnus/ympyrat/ymp1.html)

Also, the equation of the circle can helps us a lot:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-08-13-circle-with-polyline/circleEqn1.gif" alt="equation of the circle" width="350"/>
</div>
<br>
<br>

Unfortunately, I'm not a math guy... so I just looked for some existing algorithms for drawing circles and found [a few already well-explained](http://groups.csail.mit.edu/graphics/classes/6.837/F98/Lecture6/circle.html).

All I need to do - is just use them in the code - [generate the points](https://math.stackexchange.com/questions/260096/find-the-coordinates-of-a-point-on-a-circle) and draw a polyline using a set of these points.

The possible solution could be next:

{% highlight swift %}
public static func circlePolylinePointsWithCenterAt(
    point: CLLocationCoordinate2D,
    radiusInMeters: Double,
    pointsCount: Int = 72
  ) -> [CLLocationCoordinate2D] {
    let earthsRadius = point.earthRadius()
    let radiusLatitude = (radiusInMeters / earthsRadius).radiansToDegrees
    let radiusLongitude = radiusLatitude / cos(point.latitude.degreesToRadians)
    
    var circlePoints: [CLLocationCoordinate2D] = []
    for i in 0... pointsCount {
      let theta = Double.pi * (Double(i) / Double(pointsCount/2))
      let longitudePoint = point.longitude + (radiusLongitude * cos(theta))
      let latitudePoint = point.latitude + (radiusLatitude * sin(theta))
      circlePoints.append(.init(latitude: latitudePoint, longitude: longitudePoint))
    }
    
    return circle points
}
{% endhighlight %}

where the Earch radius (as described in [prev post]({% post_url 2021-06-29-covering-an-arbitary-area-with-circles-of-equal-radius %})):

{% highlight swift %}
extension CLLocationCoordinate2D {
  
  public func earthRadius() -> CLLocationDistance {
    let earthRadiusInMetersAtSeaLevel = 6378137.0
    let earthRadiusInMetersAtPole = 6356752.314
    
    let r1 = earthRadiusInMetersAtSeaLevel
    let r2 = earthRadiusInMetersAtPole
    let beta = latitude.degreesToRadians
    
    let earthRadiuseAtGivenLatitude = (
      ( pow(pow(r1, 2) * cos(beta), 2) + pow(pow(r2, 2) * sin(beta), 2) ) /
        ( pow(r1 * cos(beta), 2) + pow(r2 * sin(beta), 2) )
    )
    .squareRoot()
    
    return earthRadiuseAtGivenLatitude
  }
}

{% endhighlight %}

Then, we can just draw a polyline using the array of the `CLLocationCoordinate2D`.

The result:

<div style="text-align:center">
<img src="{{site.baseurl}}/assets/posts/images/2021-08-13-circle-with-polyline/result.png" alt="the result" width="350"/>
</div>
<br>
<br>

> changing the `pointsCount` can leads to the change of the quality and performance, so try it out and select the trade-off most suitable for u.

## Resources

* [Simple Circle Algorithms](https://www.cs.helsinki.fi/group/goa/mallinnus/ympyrat/ymp1.html)
* [Circle-Drawing Algorithms](http://groups.csail.mit.edu/graphics/classes/6.837/F98/Lecture6/circle.html)
* [Generate a point on a circle](https://math.stackexchange.com/questions/260096/find-the-coordinates-of-a-point-on-a-circle)