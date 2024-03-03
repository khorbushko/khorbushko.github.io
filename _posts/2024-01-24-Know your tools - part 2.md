---
layout: post
comments: true
title: "Know your tools - Part 2"
categories: article
tags: [swift, SwiftUI, algorithms, Dijkstra, iOS, macOS]
excerpt_separator: <!--more-->
comments_id: 92

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

This is a second part of the post related to practical usafe of well-known algorithm.

In this part I just want to cover the idea of visualization for the process.
<!--more-->

Articles in this series:

* [Know your tools]({% post_url 2023-11-26-Know your tools %})
* Know your tools - part 2

### The problem

The last part just covert practical part for *engine* of solution search, but for user in this moment we show nothing... As u remember, we have na process that can take at least 10s or even more (depending on device and available resources).

My idea is to show the map and cities with routes on it and the process of iteration and selection of the route - so the user was able to *feel* the process.

### Solution

We can as usual split the problem and complete it step by step:

- show the map
- show cities
- show iteration process

#### the map

As I mention in last part, the idea of the game - is just to select the best route in between selected set of Ukrainian's cities. So we need to show the Ukraine map.

To achieve this we can use one of many available ways. I selected the way that use *Shape* type from SwiftUI, in other words - a set of points, that represent a shape of the country.

> In [this post]({% post_url 2023-11-09-All the world around %}) I describe the way how it can be done and where the data for various geo-objects can be obtained

Selected solution require just to grab the set of points and to prepare a *Path* object in *Shape*: 

{% highlight swift %}
struct Ukraine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let width = rect.size.width
    let height = rect.size.height
    path.move(to: CGPoint(x: 0.5342*width, y: 0.03598*height))
    path.addLine(to: CGPoint(x: 0.53943*width, y: 0.03607*height))
...
{% endhighlight %}


<details><summary> The full code for shape: </summary>
<p>

{% highlight swift %}
struct Ukraine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let width = rect.size.width
    let height = rect.size.height
    path.move(to: CGPoint(x: 0.5342*width, y: 0.03598*height))
    path.addLine(to: CGPoint(x: 0.53943*width, y: 0.03607*height))
    path.addLine(to: CGPoint(x: 0.54229*width, y: 0.04489*height))
    path.addLine(to: CGPoint(x: 0.56015*width, y: 0.03846*height))
    path.addLine(to: CGPoint(x: 0.56906*width, y: 0.00784*height))
    path.addLine(to: CGPoint(x: 0.59754*width, y: 0.01851*height))
    path.addLine(to: CGPoint(x: 0.6127*width, y: 0.00281*height))
    path.addLine(to: CGPoint(x: 0.62917*width, y: 0.00399*height))
    path.addLine(to: CGPoint(x: 0.6308*width, y: 0.01272*height))
    path.addLine(to: CGPoint(x: 0.64707*width, y: 0.00438*height))
    path.addLine(to: CGPoint(x: 0.66153*width, y: 0.02876*height))
    path.addLine(to: CGPoint(x: 0.66324*width, y: 0.05449*height))
    path.addLine(to: CGPoint(x: 0.68075*width, y: 0.07615*height))
    path.addLine(to: CGPoint(x: 0.67874*width, y: 0.08475*height))
    path.addLine(to: CGPoint(x: 0.66285*width, y: 0.08997*height))
    path.addLine(to: CGPoint(x: 0.67029*width, y: 0.10885*height))
    path.addLine(to: CGPoint(x: 0.6682*width, y: 0.12388*height))
    path.addLine(to: CGPoint(x: 0.675*width, y: 0.13126*height))
    path.addLine(to: CGPoint(x: 0.6682*width, y: 0.14194*height))
    path.addLine(to: CGPoint(x: 0.69157*width, y: 0.14379*height))
    path.addLine(to: CGPoint(x: 0.69526*width, y: 0.15202*height))
    path.addLine(to: CGPoint(x: 0.7176*width, y: 0.14708*height))
    path.addLine(to: CGPoint(x: 0.7212*width, y: 0.16562*height))
    path.addLine(to: CGPoint(x: 0.7329*width, y: 0.16972*height))
    path.addLine(to: CGPoint(x: 0.72901*width, y: 0.17983*height))
    path.addLine(to: CGPoint(x: 0.7392*width, y: 0.21413*height))
    path.addLine(to: CGPoint(x: 0.73415*width, y: 0.21994*height))
    path.addLine(to: CGPoint(x: 0.73677*width, y: 0.23503*height))
    path.addLine(to: CGPoint(x: 0.74707*width, y: 0.25354*height))
    path.addLine(to: CGPoint(x: 0.75959*width, y: 0.24463*height))
    path.addLine(to: CGPoint(x: 0.77444*width, y: 0.24492*height))
    path.addLine(to: CGPoint(x: 0.78347*width, y: 0.26228*height))
    path.addLine(to: CGPoint(x: 0.79127*width, y: 0.25941*height))
    path.addLine(to: CGPoint(x: 0.80147*width, y: 0.27185*height))
    path.addLine(to: CGPoint(x: 0.81554*width, y: 0.25702*height))
    path.addLine(to: CGPoint(x: 0.8469*width, y: 0.24357*height))
    path.addLine(to: CGPoint(x: 0.85707*width, y: 0.2611*height))
    path.addLine(to: CGPoint(x: 0.85696*width, y: 0.27278*height))
    path.addLine(to: CGPoint(x: 0.87927*width, y: 0.30975*height))
    path.addLine(to: CGPoint(x: 0.88845*width, y: 0.30469*height))
    path.addLine(to: CGPoint(x: 0.88888*width, y: 0.2898*height))
    path.addLine(to: CGPoint(x: 0.89585*width, y: 0.28978*height))
    path.addLine(to: CGPoint(x: 0.89895*width, y: 0.29972*height))
    path.addLine(to: CGPoint(x: 0.91603*width, y: 0.30163*height))
    path.addLine(to: CGPoint(x: 0.93112*width, y: 0.32174*height))
    path.addLine(to: CGPoint(x: 0.94321*width, y: 0.31301*height))
    path.addLine(to: CGPoint(x: 0.94903*width, y: 0.32907*height))
    path.addLine(to: CGPoint(x: 0.96544*width, y: 0.33163*height))
    path.addLine(to: CGPoint(x: 0.96906*width, y: 0.34537*height))
    path.addLine(to: CGPoint(x: 0.97894*width, y: 0.35424*height))
    path.addLine(to: CGPoint(x: 0.98981*width, y: 0.34601*height))
    path.addLine(to: CGPoint(x: 0.99715*width, y: 0.34955*height))
    path.addLine(to: CGPoint(x: 0.99185*width, y: 0.3611*height))
    path.addLine(to: CGPoint(x: 0.99875*width, y: 0.3802*height))
    path.addLine(to: CGPoint(x: 0.99734*width, y: 0.3923*height))
    path.addLine(to: CGPoint(x: 0.98542*width, y: 0.41573*height))
    path.addLine(to: CGPoint(x: 0.97228*width, y: 0.41916*height))
    path.addLine(to: CGPoint(x: 0.97657*width, y: 0.43469*height))
    path.addLine(to: CGPoint(x: 0.9929*width, y: 0.43795*height))
    path.addLine(to: CGPoint(x: 0.98855*width, y: 0.44784*height))
    path.addLine(to: CGPoint(x: 0.97771*width, y: 0.44559*height))
    path.addLine(to: CGPoint(x: 0.96954*width, y: 0.47306*height))
    path.addLine(to: CGPoint(x: 0.98081*width, y: 0.47475*height))
    path.addLine(to: CGPoint(x: 0.98573*width, y: 0.4993*height))
    path.addLine(to: CGPoint(x: 0.97974*width, y: 0.50775*height))
    path.addLine(to: CGPoint(x: 0.98955*width, y: 0.51208*height))
    path.addLine(to: CGPoint(x: 0.98124*width, y: 0.53118*height))
    path.addLine(to: CGPoint(x: 0.98124*width, y: 0.54154*height))
    path.addLine(to: CGPoint(x: 0.97664*width, y: 0.54421*height))
    path.addLine(to: CGPoint(x: 0.97659*width, y: 0.56685*height))
    path.addLine(to: CGPoint(x: 0.92524*width, y: 0.56494*height))
    path.addLine(to: CGPoint(x: 0.9199*width, y: 0.58624*height))
    path.addLine(to: CGPoint(x: 0.89549*width, y: 0.60048*height))
    path.addLine(to: CGPoint(x: 0.8898*width, y: 0.63104*height))
    path.addLine(to: CGPoint(x: 0.8959*width, y: 0.63612*height))
    path.addLine(to: CGPoint(x: 0.89051*width, y: 0.64654*height))
    path.addLine(to: CGPoint(x: 0.89124*width, y: 0.65764*height))
    path.addLine(to: CGPoint(x: 0.88524*width, y: 0.66719*height))
    path.addLine(to: CGPoint(x: 0.88321*width, y: 0.65806*height))
    path.addLine(to: CGPoint(x: 0.85415*width, y: 0.66031*height))
    path.addLine(to: CGPoint(x: 0.84246*width, y: 0.68508*height))
    path.addLine(to: CGPoint(x: 0.83649*width, y: 0.67831*height))
    path.addLine(to: CGPoint(x: 0.81582*width, y: 0.69528*height))
    path.addLine(to: CGPoint(x: 0.81115*width, y: 0.71559*height))
    path.addLine(to: CGPoint(x: 0.81299*width, y: 0.70472*height))
    path.addLine(to: CGPoint(x: 0.8071*width, y: 0.69784*height))
    path.addLine(to: CGPoint(x: 0.79073*width, y: 0.7048*height))
    path.addLine(to: CGPoint(x: 0.78399*width, y: 0.7193*height))
    path.addLine(to: CGPoint(x: 0.77906*width, y: 0.71166*height))
    path.addLine(to: CGPoint(x: 0.76314*width, y: 0.71368*height))
    path.addLine(to: CGPoint(x: 0.74045*width, y: 0.73913*height))
    path.addLine(to: CGPoint(x: 0.72347*width, y: 0.77677*height))
    path.addLine(to: CGPoint(x: 0.71325*width, y: 0.7857*height))
    path.addLine(to: CGPoint(x: 0.73218*width, y: 0.75309*height))
    path.addLine(to: CGPoint(x: 0.72805*width, y: 0.75121*height))
    path.addLine(to: CGPoint(x: 0.72899*width, y: 0.74045*height))
    path.addLine(to: CGPoint(x: 0.72368*width, y: 0.73112*height))
    path.addLine(to: CGPoint(x: 0.72484*width, y: 0.74556*height))
    path.addLine(to: CGPoint(x: 0.71925*width, y: 0.75784*height))
    path.addLine(to: CGPoint(x: 0.70736*width, y: 0.76354*height))
    path.addLine(to: CGPoint(x: 0.70286*width, y: 0.77289*height))
    path.addLine(to: CGPoint(x: 0.71335*width, y: 0.82857*height))
    path.addLine(to: CGPoint(x: 0.7328*width, y: 0.87643*height))
    path.addLine(to: CGPoint(x: 0.75388*width, y: 0.87949*height))
    path.addLine(to: CGPoint(x: 0.76204*width, y: 0.85812*height))
    path.addLine(to: CGPoint(x: 0.76815*width, y: 0.8734*height))
    path.addLine(to: CGPoint(x: 0.78515*width, y: 0.8627*height))
    path.addLine(to: CGPoint(x: 0.8035*width, y: 0.86576*height))
    path.addLine(to: CGPoint(x: 0.80283*width, y: 0.87949*height))
    path.addLine(to: CGPoint(x: 0.79535*width, y: 0.88868*height))
    path.addLine(to: CGPoint(x: 0.79535*width, y: 0.91008*height))
    path.addLine(to: CGPoint(x: 0.78379*width, y: 0.91772*height))
    path.addLine(to: CGPoint(x: 0.76882*width, y: 0.9223*height))
    path.addLine(to: CGPoint(x: 0.74368*width, y: 0.90548*height))
    path.addLine(to: CGPoint(x: 0.73824*width, y: 0.91924*height))
    path.addLine(to: CGPoint(x: 0.71647*width, y: 0.94522*height))
    path.addLine(to: CGPoint(x: 0.68385*width, y: 0.95287*height))
    path.addLine(to: CGPoint(x: 0.65529*width, y: 0.99719*height))
    path.addLine(to: CGPoint(x: 0.62265*width, y: 0.97427*height))
    path.addLine(to: CGPoint(x: 0.63285*width, y: 0.96663*height))
    path.addLine(to: CGPoint(x: 0.63354*width, y: 0.90548*height))
    path.addLine(to: CGPoint(x: 0.6179*width, y: 0.9009*height))
    path.addLine(to: CGPoint(x: 0.59886*width, y: 0.87492*height))
    path.addLine(to: CGPoint(x: 0.57303*width, y: 0.87034*height))
    path.addLine(to: CGPoint(x: 0.63965*width, y: 0.81225*height))
    path.addLine(to: CGPoint(x: 0.64695*width, y: 0.76966*height))
    path.addLine(to: CGPoint(x: 0.63967*width, y: 0.76772*height))
    path.addLine(to: CGPoint(x: 0.63736*width, y: 0.77933*height))
    path.addLine(to: CGPoint(x: 0.6342*width, y: 0.77629*height))
    path.addLine(to: CGPoint(x: 0.63115*width, y: 0.7891*height))
    path.addLine(to: CGPoint(x: 0.62604*width, y: 0.78823*height))
    path.addLine(to: CGPoint(x: 0.61864*width, y: 0.78309*height))
    path.addLine(to: CGPoint(x: 0.62005*width, y: 0.77857*height))
    path.addLine(to: CGPoint(x: 0.61445*width, y: 0.7789*height))
    path.addLine(to: CGPoint(x: 0.61559*width, y: 0.76702*height))
    path.addLine(to: CGPoint(x: 0.60938*width, y: 0.77795*height))
    path.addLine(to: CGPoint(x: 0.60388*width, y: 0.77374*height))
    path.addLine(to: CGPoint(x: 0.60359*width, y: 0.77899*height))
    path.addLine(to: CGPoint(x: 0.58965*width, y: 0.77798*height))
    path.addLine(to: CGPoint(x: 0.5751*width, y: 0.78539*height))
    path.addLine(to: CGPoint(x: 0.56176*width, y: 0.7789*height))
    path.addLine(to: CGPoint(x: 0.56215*width, y: 0.76941*height))
    path.addLine(to: CGPoint(x: 0.55436*width, y: 0.76879*height))
    path.addLine(to: CGPoint(x: 0.54092*width, y: 0.75506*height))
    path.addLine(to: CGPoint(x: 0.54074*width, y: 0.76014*height))
    path.addLine(to: CGPoint(x: 0.5354*width, y: 0.75848*height))
    path.addLine(to: CGPoint(x: 0.53616*width, y: 0.7523*height))
    path.addLine(to: CGPoint(x: 0.54549*width, y: 0.75121*height))
    path.addLine(to: CGPoint(x: 0.55021*width, y: 0.74435*height))
    path.addLine(to: CGPoint(x: 0.53333*width, y: 0.73267*height))
    path.addLine(to: CGPoint(x: 0.5299*width, y: 0.7414*height))
    path.addLine(to: CGPoint(x: 0.52004*width, y: 0.72177*height))
    path.addLine(to: CGPoint(x: 0.52409*width, y: 0.72705*height))
    path.addLine(to: CGPoint(x: 0.56481*width, y: 0.73711*height))
    path.addLine(to: CGPoint(x: 0.58296*width, y: 0.71407*height))
    path.addLine(to: CGPoint(x: 0.56583*width, y: 0.72494*height))
    path.addLine(to: CGPoint(x: 0.56098*width, y: 0.7193*height))
    path.addLine(to: CGPoint(x: 0.55534*width, y: 0.72517*height))
    path.addLine(to: CGPoint(x: 0.54851*width, y: 0.7166*height))
    path.addLine(to: CGPoint(x: 0.54394*width, y: 0.70048*height))
    path.addLine(to: CGPoint(x: 0.54596*width, y: 0.6693*height))
    path.addLine(to: CGPoint(x: 0.53979*width, y: 0.66719*height))
    path.addLine(to: CGPoint(x: 0.54154*width, y: 0.65893*height))
    path.addLine(to: CGPoint(x: 0.53295*width, y: 0.63823*height))
    path.addLine(to: CGPoint(x: 0.54029*width, y: 0.65879*height))
    path.addLine(to: CGPoint(x: 0.53825*width, y: 0.66941*height))
    path.addLine(to: CGPoint(x: 0.54431*width, y: 0.67059*height))
    path.addLine(to: CGPoint(x: 0.54168*width, y: 0.67747*height))
    path.addLine(to: CGPoint(x: 0.54549*width, y: 0.67831*height))
    path.addLine(to: CGPoint(x: 0.53976*width, y: 0.69452*height))
    path.addLine(to: CGPoint(x: 0.54168*width, y: 0.71407*height))
    path.addLine(to: CGPoint(x: 0.51919*width, y: 0.71666*height))
    path.addLine(to: CGPoint(x: 0.52611*width, y: 0.69368*height))
    path.addLine(to: CGPoint(x: 0.52004*width, y: 0.70216*height))
    path.addLine(to: CGPoint(x: 0.5163*width, y: 0.69528*height))
    path.addLine(to: CGPoint(x: 0.5199*width, y: 0.70525*height))
    path.addLine(to: CGPoint(x: 0.51494*width, y: 0.7166*height))
    path.addLine(to: CGPoint(x: 0.48033*width, y: 0.7261*height))
    path.addLine(to: CGPoint(x: 0.47933*width, y: 0.74556*height))
    path.addLine(to: CGPoint(x: 0.47265*width, y: 0.75199*height))
    path.addLine(to: CGPoint(x: 0.47434*width, y: 0.75761*height))
    path.addLine(to: CGPoint(x: 0.46392*width, y: 0.78486*height))
    path.addLine(to: CGPoint(x: 0.44791*width, y: 0.81281*height))
    path.addLine(to: CGPoint(x: 0.44424*width, y: 0.81728*height))
    path.addLine(to: CGPoint(x: 0.44362*width, y: 0.80837*height))
    path.addLine(to: CGPoint(x: 0.44181*width, y: 0.81789*height))
    path.addLine(to: CGPoint(x: 0.43484*width, y: 0.81492*height))
    path.addLine(to: CGPoint(x: 0.43284*width, y: 0.82919*height))
    path.addLine(to: CGPoint(x: 0.43036*width, y: 0.82407*height))
    path.addLine(to: CGPoint(x: 0.42564*width, y: 0.82753*height))
    path.addLine(to: CGPoint(x: 0.4291*width, y: 0.83562*height))
    path.addLine(to: CGPoint(x: 0.42184*width, y: 0.84284*height))
    path.addLine(to: CGPoint(x: 0.41655*width, y: 0.81646*height))
    path.addLine(to: CGPoint(x: 0.41388*width, y: 0.84972*height))
    path.addLine(to: CGPoint(x: 0.42036*width, y: 0.84795*height))
    path.addLine(to: CGPoint(x: 0.41476*width, y: 0.85978*height))
    path.addLine(to: CGPoint(x: 0.42071*width, y: 0.865*height))
    path.addLine(to: CGPoint(x: 0.42176*width, y: 0.86008*height))
    path.addLine(to: CGPoint(x: 0.42306*width, y: 0.86604*height))
    path.addLine(to: CGPoint(x: 0.42163*width, y: 0.88969*height))
    path.addLine(to: CGPoint(x: 0.41771*width, y: 0.89242*height))
    path.addLine(to: CGPoint(x: 0.41722*width, y: 0.87621*height))
    path.addLine(to: CGPoint(x: 0.40508*width, y: 0.86573*height))
    path.addLine(to: CGPoint(x: 0.39386*width, y: 0.86654*height))
    path.addLine(to: CGPoint(x: 0.37736*width, y: 0.88455*height))
    path.addLine(to: CGPoint(x: 0.36961*width, y: 0.87927*height))
    path.addLine(to: CGPoint(x: 0.37033*width, y: 0.88888*height))
    path.addLine(to: CGPoint(x: 0.3652*width, y: 0.89104*height))
    path.addLine(to: CGPoint(x: 0.34417*width, y: 0.8791*height))
    path.addLine(to: CGPoint(x: 0.33695*width, y: 0.86183*height))
    path.addLine(to: CGPoint(x: 0.34087*width, y: 0.85438*height))
    path.addLine(to: CGPoint(x: 0.35369*width, y: 0.85598*height))
    path.addLine(to: CGPoint(x: 0.35561*width, y: 0.84713*height))
    path.addLine(to: CGPoint(x: 0.35214*width, y: 0.83742*height))
    path.addLine(to: CGPoint(x: 0.36676*width, y: 0.81508*height))
    path.addLine(to: CGPoint(x: 0.36686*width, y: 0.80067*height))
    path.addLine(to: CGPoint(x: 0.37885*width, y: 0.79469*height))
    path.addLine(to: CGPoint(x: 0.37785*width, y: 0.78376*height))
    path.addLine(to: CGPoint(x: 0.38209*width, y: 0.77216*height))
    path.addLine(to: CGPoint(x: 0.37756*width, y: 0.76264*height))
    path.addLine(to: CGPoint(x: 0.37824*width, y: 0.73829*height))
    path.addLine(to: CGPoint(x: 0.39144*width, y: 0.72795*height))
    path.addLine(to: CGPoint(x: 0.39235*width, y: 0.75045*height))
    path.addLine(to: CGPoint(x: 0.39821*width, y: 0.73615*height))
    path.addLine(to: CGPoint(x: 0.40197*width, y: 0.74309*height))
    path.addLine(to: CGPoint(x: 0.40656*width, y: 0.73458*height))
    path.addLine(to: CGPoint(x: 0.41531*width, y: 0.74986*height))
    path.addLine(to: CGPoint(x: 0.42076*width, y: 0.73626*height))
    path.addLine(to: CGPoint(x: 0.42706*width, y: 0.75264*height))
    path.addLine(to: CGPoint(x: 0.44106*width, y: 0.74831*height))
    path.addLine(to: CGPoint(x: 0.44386*width, y: 0.74228*height))
    path.addLine(to: CGPoint(x: 0.43115*width, y: 0.72882*height))
    path.addLine(to: CGPoint(x: 0.4326*width, y: 0.69413*height))
    path.addLine(to: CGPoint(x: 0.41216*width, y: 0.67722*height))
    path.addLine(to: CGPoint(x: 0.41456*width, y: 0.66289*height))
    path.addLine(to: CGPoint(x: 0.40769*width, y: 0.6566*height))
    path.addLine(to: CGPoint(x: 0.41139*width, y: 0.6536*height))
    path.addLine(to: CGPoint(x: 0.41204*width, y: 0.63017*height))
    path.addLine(to: CGPoint(x: 0.40785*width, y: 0.6284*height))
    path.addLine(to: CGPoint(x: 0.4039*width, y: 0.63567*height))
    path.addLine(to: CGPoint(x: 0.39411*width, y: 0.61494*height))
    path.addLine(to: CGPoint(x: 0.38985*width, y: 0.61449*height))
    path.addLine(to: CGPoint(x: 0.38774*width, y: 0.60413*height))
    path.addLine(to: CGPoint(x: 0.3943*width, y: 0.56216*height))
    path.addLine(to: CGPoint(x: 0.3881*width, y: 0.54907*height))
    path.addLine(to: CGPoint(x: 0.3785*width, y: 0.55419*height))
    path.addLine(to: CGPoint(x: 0.37014*width, y: 0.53216*height))
    path.addLine(to: CGPoint(x: 0.35765*width, y: 0.5268*height))
    path.addLine(to: CGPoint(x: 0.35245*width, y: 0.53801*height))
    path.addLine(to: CGPoint(x: 0.34869*width, y: 0.52483*height))
    path.addLine(to: CGPoint(x: 0.34347*width, y: 0.52924*height))
    path.addLine(to: CGPoint(x: 0.3457*width, y: 0.5164*height))
    path.addLine(to: CGPoint(x: 0.33106*width, y: 0.51654*height))
    path.addLine(to: CGPoint(x: 0.33014*width, y: 0.50691*height))
    path.addLine(to: CGPoint(x: 0.30404*width, y: 0.48584*height))
    path.addLine(to: CGPoint(x: 0.2929*width, y: 0.49489*height))
    path.addLine(to: CGPoint(x: 0.28951*width, y: 0.49183*height))
    path.addLine(to: CGPoint(x: 0.28211*width, y: 0.50121*height))
    path.addLine(to: CGPoint(x: 0.27264*width, y: 0.49635*height))
    path.addLine(to: CGPoint(x: 0.26744*width, y: 0.50239*height))
    path.addLine(to: CGPoint(x: 0.26128*width, y: 0.49739*height))
    path.addLine(to: CGPoint(x: 0.25871*width, y: 0.50949*height))
    path.addLine(to: CGPoint(x: 0.25285*width, y: 0.505*height))
    path.addLine(to: CGPoint(x: 0.24942*width, y: 0.51388*height))
    path.addLine(to: CGPoint(x: 0.23203*width, y: 0.51969*height))
    path.addLine(to: CGPoint(x: 0.22481*width, y: 0.54694*height))
    path.addLine(to: CGPoint(x: 0.17439*width, y: 0.55871*height))
    path.addLine(to: CGPoint(x: 0.16432*width, y: 0.57806*height))
    path.addLine(to: CGPoint(x: 0.15419*width, y: 0.58213*height))
    path.addLine(to: CGPoint(x: 0.13456*width, y: 0.55306*height))
    path.addLine(to: CGPoint(x: 0.11615*width, y: 0.55882*height))
    path.addLine(to: CGPoint(x: 0.10505*width, y: 0.5509*height))
    path.addLine(to: CGPoint(x: 0.09656*width, y: 0.55427*height))
    path.addLine(to: CGPoint(x: 0.0924*width, y: 0.54764*height))
    path.addLine(to: CGPoint(x: 0.07474*width, y: 0.54963*height))
    path.addLine(to: CGPoint(x: 0.05692*width, y: 0.53388*height))
    path.addLine(to: CGPoint(x: 0.05273*width, y: 0.54514*height))
    path.addLine(to: CGPoint(x: 0.04504*width, y: 0.54548*height))
    path.addLine(to: CGPoint(x: 0.04246*width, y: 0.5527*height))
    path.addLine(to: CGPoint(x: 0.03825*width, y: 0.53478*height))
    path.addLine(to: CGPoint(x: 0.0274*width, y: 0.53402*height))
    path.addLine(to: CGPoint(x: 0.02054*width, y: 0.5159*height))
    path.addLine(to: CGPoint(x: 0.01366*width, y: 0.51584*height))
    path.addLine(to: CGPoint(x: 0.00894*width, y: 0.4959*height))
    path.addLine(to: CGPoint(x: 0.00125*width, y: 0.49573*height))
    path.addLine(to: CGPoint(x: 0.00158*width, y: 0.47522*height))
    path.addLine(to: CGPoint(x: 0.01107*width, y: 0.46129*height))
    path.addLine(to: CGPoint(x: 0.02376*width, y: 0.4127*height))
    path.addLine(to: CGPoint(x: 0.04122*width, y: 0.42242*height))
    path.addLine(to: CGPoint(x: 0.04112*width, y: 0.41115*height))
    path.addLine(to: CGPoint(x: 0.03163*width, y: 0.40163*height))
    path.addLine(to: CGPoint(x: 0.03472*width, y: 0.38742*height))
    path.addLine(to: CGPoint(x: 0.03074*width, y: 0.3511*height))
    path.addLine(to: CGPoint(x: 0.08699*width, y: 0.25149*height))
    path.addLine(to: CGPoint(x: 0.10354*width, y: 0.24694*height))
    path.addLine(to: CGPoint(x: 0.11052*width, y: 0.23*height))
    path.addLine(to: CGPoint(x: 0.10905*width, y: 0.2086*height))
    path.addLine(to: CGPoint(x: 0.10222*width, y: 0.19677*height))
    path.addLine(to: CGPoint(x: 0.11249*width, y: 0.19076*height))
    path.addLine(to: CGPoint(x: 0.10342*width, y: 0.18067*height))
    path.addLine(to: CGPoint(x: 0.09703*width, y: 0.15444*height))
    path.addLine(to: CGPoint(x: 0.08439*width, y: 0.135*height))
    path.addLine(to: CGPoint(x: 0.08784*width, y: 0.12258*height))
    path.addLine(to: CGPoint(x: 0.08278*width, y: 0.10854*height))
    path.addLine(to: CGPoint(x: 0.08404*width, y: 0.09463*height))
    path.addLine(to: CGPoint(x: 0.10354*width, y: 0.1*height))
    path.addLine(to: CGPoint(x: 0.11807*width, y: 0.08354*height))
    path.addLine(to: CGPoint(x: 0.12502*width, y: 0.06404*height))
    path.addLine(to: CGPoint(x: 0.17005*width, y: 0.05475*height))
    path.addLine(to: CGPoint(x: 0.21804*width, y: 0.06034*height))
    path.addLine(to: CGPoint(x: 0.26254*width, y: 0.07969*height))
    path.addLine(to: CGPoint(x: 0.27894*width, y: 0.07876*height))
    path.addLine(to: CGPoint(x: 0.28104*width, y: 0.09034*height))
    path.addLine(to: CGPoint(x: 0.28592*width, y: 0.09191*height))
    path.addLine(to: CGPoint(x: 0.28537*width, y: 0.0998*height))
    path.addLine(to: CGPoint(x: 0.29699*width, y: 0.09531*height))
    path.addLine(to: CGPoint(x: 0.3089*width, y: 0.09961*height))
    path.addLine(to: CGPoint(x: 0.3101*width, y: 0.11522*height))
    path.addLine(to: CGPoint(x: 0.31657*width, y: 0.09666*height))
    path.addLine(to: CGPoint(x: 0.32983*width, y: 0.10354*height))
    path.addLine(to: CGPoint(x: 0.33752*width, y: 0.0918*height))
    path.addLine(to: CGPoint(x: 0.34437*width, y: 0.10716*height))
    path.addLine(to: CGPoint(x: 0.35142*width, y: 0.10177*height))
    path.addLine(to: CGPoint(x: 0.35932*width, y: 0.10404*height))
    path.addLine(to: CGPoint(x: 0.36624*width, y: 0.12298*height))
    path.addLine(to: CGPoint(x: 0.37016*width, y: 0.10663*height))
    path.addLine(to: CGPoint(x: 0.38474*width, y: 0.09444*height))
    path.addLine(to: CGPoint(x: 0.39011*width, y: 0.09784*height))
    path.addLine(to: CGPoint(x: 0.39895*width, y: 0.12742*height))
    path.addLine(to: CGPoint(x: 0.40704*width, y: 0.125*height))
    path.addLine(to: CGPoint(x: 0.41654*width, y: 0.11183*height))
    path.addLine(to: CGPoint(x: 0.4271*width, y: 0.11941*height))
    path.addLine(to: CGPoint(x: 0.4448*width, y: 0.11264*height))
    path.addLine(to: CGPoint(x: 0.4543*width, y: 0.12287*height))
    path.addLine(to: CGPoint(x: 0.45623*width, y: 0.13492*height))
    path.addLine(to: CGPoint(x: 0.46644*width, y: 0.14365*height))
    path.addLine(to: CGPoint(x: 0.4723*width, y: 0.12719*height))
    path.addLine(to: CGPoint(x: 0.46508*width, y: 0.09781*height))
    path.addLine(to: CGPoint(x: 0.47761*width, y: 0.06121*height))
    path.addLine(to: CGPoint(x: 0.48866*width, y: 0.04927*height))
    path.addLine(to: CGPoint(x: 0.48741*width, y: 0.04115*height))
    path.addLine(to: CGPoint(x: 0.49724*width, y: 0.0386*height))
    path.addLine(to: CGPoint(x: 0.50457*width, y: 0.04374*height))
    path.addLine(to: CGPoint(x: 0.51311*width, y: 0.03388*height))
    path.addLine(to: CGPoint(x: 0.5342*width, y: 0.03598*height))
    path.closeSubpath()
    path.move(to: CGPoint(x: 0.43208*width, y: 0.83334*height))
    path.addLine(to: CGPoint(x: 0.44355*width, y: 0.81831*height))
    path.addLine(to: CGPoint(x: 0.42169*width, y: 0.8457*height))
    path.addLine(to: CGPoint(x: 0.43208*width, y: 0.83334*height))
    path.closeSubpath()
    path.move(to: CGPoint(x: 0.60199*width, y: 0.78955*height))
    path.addLine(to: CGPoint(x: 0.60576*width, y: 0.79174*height))
    path.addLine(to: CGPoint(x: 0.58153*width, y: 0.78742*height))
    path.addLine(to: CGPoint(x: 0.60199*width, y: 0.78955*height))
    path.closeSubpath()
    path.move(to: CGPoint(x: 0.54394*width, y: 0.76941*height))
    path.addLine(to: CGPoint(x: 0.55645*width, y: 0.77629*height))
    path.addLine(to: CGPoint(x: 0.52403*width, y: 0.76219*height))
    path.addLine(to: CGPoint(x: 0.51982*width, y: 0.74843*height))
    path.addLine(to: CGPoint(x: 0.52611*width, y: 0.76261*height))
    path.addLine(to: CGPoint(x: 0.54394*width, y: 0.76941*height))
    path.closeSubpath()
    return path
  }
}
{% endhighlight %}

</p>
</details>
<br>

To draw the shape we just need to call 1 line of code in SwiftUI - as simple as just:

{% highlight swift %}
Ukraine()
  .fill(.brown.opacity(0.5))
  .stroke(.brown, lineWidth: 1)
  .aspectRatio(1.5, contentMode: .fit)
{% endhighlight %}


The result I got is next:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-01-24-Know your tools - part 2/map.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-01-24-Know your tools - part 2/map.png" alt="map" width="300"/>
</a>
</div>
<br>
<br>

#### cities

Now, we need to show somehow each city and route in between them. 

To achieve this we can introduce local coordinate system - divide the map into XY grid and determine coordinate of each city.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-01-24-Know your tools - part 2/localCoord.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-01-24-Know your tools - part 2/localCoord.png" alt="localCoord" width="400"/>
</a>
</div>
<br>
<br>

Then, we can append coordinate data to each model of the city:


{% highlight swift %}
  static let lviv: City = .init(region: .pink, name: "Львів", position: .init(x: 4, y: 5.5))
  static let uzhgorod: City = .init(region: .pink, name: "Ужгород", position: .init(x: 1, y: 8.5))
  static let drohobuch: City = .init(region: .pink, name: "Дрогобич", position: .init(x: 2.5, y: 6.2))
  ...
{% endhighlight %}

Now the interesting part - we need to draw the city and routes between them. To achieve this we can use simple shapes like circle and line.
All information we have - we just apply simple math for converting coordinates into local, map-dependent coordinate system and by adding overlay to the map:


{% highlight swift %}
  @ViewBuilder
  private func drawCities() -> some View {
    ZStack {
      ForEach(Array(viewModel.source.adjacencyDict.keys), id: \.self) { key in
        let items = viewModel.source.adjacencyDict[key]?.filter({ $0.source.data == key.data }) ?? []

        ForEach(items, id: \.self) { value in
          CarLine(vertext: key, value: value)
            .stroke(.black, lineWidth: 2)
        }

        GeometryReader { proxy in
          Circle()
            .fill(key.data.color)
            .frame(width: proxy.size.width / 100 * 3, height: proxy.size.width / 100 * 3)
            .offset(
              x: proxy.size.width / 31.0 * CGFloat(key.data.place.x) - proxy.size.width / 100 * 3 / 2,
              y: proxy.size.height / 17.0 * CGFloat(key.data.place.y) - proxy.size.width / 100 * 3 / 2
            )
            .id(key.data.name)
        }
        .zIndex(1)
      }
    }
  }
  
  struct CarLine: Shape {

  let vertext: Vertex<City>
  let value: Graph.Edge<City>

  func path(in rect: CGRect) -> Path {
      Path { path in
        path.move(to: .init(
          x: rect.size.width / 31.0 * CGFloat(value.source.data.place.x),
          y: rect.size.height / 17.0 * CGFloat(value.source.data.place.y)
        ))
        path.addLine(to: .init(
          x: rect.size.width / 31.0 * CGFloat(value.destination.data.place.x),
          y: rect.size.height / 17.0 * CGFloat(value.destination.data.place.y)
        ))
      }
  }
}
{% endhighlight %}

To show this on map, we just add this code:

{% highlight swift %}
...
.overlay {
   drawCities()
}
{% endhighlight %}

Result:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-01-24-Know your tools - part 2/mapWithCities.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-01-24-Know your tools - part 2/mapWithCities.png" alt="localCoord" width="300"/>
</a>
</div>
<br>
<br>

#### iteration process

The most part is done, now the most interesting stuff - showing iteration from alg. To achieve this we can use [AsyncStream](https://developer.apple.com/documentation/swift/asyncstream) from *Concurency* framework (as well as much more other options, but let's just use the latest one provided by Apple ;]).

If we dive in the code - we can see, that we have a lot of parallel processes, so showing each iteration for each selection (that is a huge option set) is almoust imposible, at least due to rendering process - calculation much faster that redrawing, thankfully.

So, we can show for example only completely selected path.  

To achieve this, we need to add [continuation](https://developer.apple.com/documentation/swift/asyncstream/continuation) as param for alg function. This continuation should return that selected path, that we then can show to user - `AsyncStream<[Graph.Edge<City>]>.Continuation`.

All we need to modify in the algorithm - just notify via continuation when we got an path-option:

{% highlight swift %}
stream.yield(currentPath)
{% endhighlight %}

The next part is also simple - on every stream event just redraw the screen:

{% highlight swift %}
// determine source
@Published var data: [Graph.Edge<City>] = []

// create stream and feed continuation
let stream = AsyncStream<[Graph.Edge<City>]> { continuation in
   Task {
    let result = await MoveAroundUkraine.calculateFastestTripBetween(
      cities,
      stream: continuation
    )
    ...

// send update on main thread
Task.detached { @MainActor in
  for await path in stream {
    self.data = path
  }
}

// redraw
  @ViewBuilder
private func drawSearchBestPathProcess() -> some View {
    ForEach(viewModel.data, id: \.self) { value in
      CarLine(vertext: value.source, value: value)
        .stroke(.red, lineWidth: 4)
    }
}
{% endhighlight %}

The result is next:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-01-24-Know your tools - part 2/demo.gif">
<img src="{{site.baseurl}}/assets/posts/images/2024-01-24-Know your tools - part 2/demo.gif" alt="demo" width="300"/>
</a>
</div>
<br>
<br>

The main target is achieved - we can visualize the process!

## Improvements

We still have a few moments to do here:

- the strike line that ignore car routes - this is train ticket. We might draw a curve with train above, to improve this
- in console I can observe error related to multiply redraw. This error we receive as and expected - so we might want to skip even more events
> 
> *ForEach<Array<Edge<City>>, Edge<City>, StrokeShapeView<CarLine, Color, EmptyView>>: the ID Edge<City>(source: Умань, destination: Черкаси, weight: Optional(4.0)) occurs multiple times within the collection, this will give undefined results!*
> 
- we might want to show overall progress of process, to improve UX

In addition to this, this app needs to be modified in a way, so user can select a set of cities instead of hardcoded set in a code.

But, looking at this project from the top, we may take out the most usefull stuff for our daily-basis work.

## Resources

- [AsyncStream](https://developer.apple.com/documentation/swift/asyncstream)
- [Continuation](https://developer.apple.com/documentation/swift/asyncstream/continuation)