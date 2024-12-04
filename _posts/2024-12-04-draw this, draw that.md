---
layout: post
comments: true
title: "Draw this, draw that"
categories: article
tags: [openscad, CAD, 3D]
excerpt_separator: <!--more-->
comments_id: 112

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

Recently I was faced with the task of drawing 3D objects for my 3D printer. As a result, I searched a bit for a suitable tool. One of the very interesting solutions was [OpenSCAD](https://github.com/openscad/openscad).
<!--more-->

## A brief overview

OpenSCAD is a free, open source software application designed for the programmatic creation of 3D models. 

Unlike traditional 3D modelling software that relies on graphical interfaces, OpenSCAD uses a script-based approach. Users write code to define geometry, making it a powerful tool for parametric and high-precision design, particularly for engineering and 3D printing projects.

### a bit of history

OpenSCAD was first released in 2010 by Marius Kintel with the aim of providing a simple yet robust tool for code-based CAD modelling. Based on the OpenGL graphics system and CGAL (Computational Geometry Algorithms Library), it focuses on accuracy and customisation. Its core philosophy is reproducibility: designs created in OpenSCAD can be easily shared and modified by changing parameters in the script. Over time, OpenSCAD has become a popular tool for enthusiasts and professionals alike, particularly within the 3D printing community.

## Key features of OpenSCAD

* **Script-based modelling:**
Models are created using a scripting language. Users can define shapes, transformations and Boolean operations (union, difference, intersection) to build complex geometries.
* **Parametric design:**
Parameters allow the creation of scalable, customisable designs. By adjusting a few variables, an entire model can be resized or reconfigured.
* **Geometric Primitives:**
OpenSCAD includes built-in primitives such as cubes, spheres, cylinders and more, which can be combined or modified using mathematical operations.
* **Transformations:**
Operations such as translation, rotation, scaling and mirroring help to position and manipulate shapes.
* **Boolean operations:**
Combine shapes with union(), subtract parts with difference(), and find overlapping areas with intersection() to create intricate designs.
* **Modules and functions:**
Users can define reusable modules (like functions in programming) to streamline complex designs.
* **3D printing support:**
OpenSCAD outputs files in formats such as STL, AMF and 3MF, which are widely used in 3D printing. 


## Hello, world!

The best way to taste something - is to try it. As an example, let's build my logo ;] - Just "HK" letters in a circle.

We can start with naive approach - use simple geometry to build it.

Using the manual you can quickly find functions to create some geometry. 

{% highlight c %}
cube([30,30,100]);
{% endhighlight %}

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/1.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/1.png" width="300"/>
</a>
</div>
<br>
<br>

This will create for us a part of a letter, let it be a part of a "K". Using a similar approach, we can complete the drawing of this letter by simply translating and rotating a similar geometry object.

> In OpenScad, this function is applied to the following functions, so if you want to rotate something - set it after this.

{% highlight c %}
cube([30,30,100]);
    
rotate([45, 0, 0]) 
    translate([0, 25, 25]) cube([30,30,60]);
    
rotate([-45, 0, 0]) 
    translate([0, -50, -25]) cube([30,30,60]);
{% endhighlight %}

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/2.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/2.png" width="300"/>
</a>
</div>
<br>
<br>

It is even easier to create an "H" that intersects with a "K":

{% highlight c %}
translate([0, 50, 0]) cube([30,30,100]);
translate([0, 0, 35]) cube([30,80,30]);
{% endhighlight %}

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/3.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/3.png" width="300"/>
</a>
</div>
<br>
<br>

To create a circle with a hole around the letters, we can draw a circle and cut a smaller circle from it. The only problem is that the circle is a 2D object and we need 3D. After a quick search in the documentation, I found [linear_extrude](https://www.openscad.info/index.php/2020/06/14/linear_extrude/) - a function that can do much more than just extrude. Putting it all together:

{% highlight c %}
size = 50;
    
difference() {
    
translate([0, 20, 50]) 
    rotate([0, 90, 0])  
    linear_extrude(30) circle(size*2);
    
translate([0, 20, 50]) 
    rotate([0, 90, 0])  
    linear_extrude(30) circle(size*2*0.8);
}
{% endhighlight %}

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/4.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/4.png" width="300"/>
</a>
</div>
<br>
<br>

But we can do even better. With the function [linear_extrude](https://www.openscad.info/index.php/2020/06/14/linear_extrude/) we can extrude text in 1 line, and drawing a circle is no problem. The better solution might be like this:

{% highlight c %}
rotate([0, 90, 0]) 
difference() {
    cylinder(d = circle_diameter, h = circle_thickness, center = true);
    cylinder(d = circle_diameter - circle_thickness * 2, h = circle_thickness, center = true);
}

// Letters "HK" with adjusted alignment
rotate([90, 00, 0]) 
	rotate([0, 90, 0]) 
	translate([-font_size/4, 0, -circle_thickness/2])
	    linear_extrude(height = letter_depth)
	        text("H K", 
	            size = font_size, 
	            valign = "center", 
	            halign = "center", 
	            spacing = letter_spacing, 
	            font = font_style);
{% endhighlight %}

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/5.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/5.png" width="300"/>
</a>
</div>
<br>
<br>

The scripting approach is very interesting, creating a box for example is a trivial task:

{% highlight c %}
module box() {
    difference() {
        cube([width, depth, height], center = true);
        translate([wall_thickness / 2, 0, wall_thickness])
            cube([width - 2 * wall_thickness, depth - 1 * wall_thickness, height - wall_thickness], center = true);
    }
}
{% endhighlight %}

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/6.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/6.png" width="300"/>
</a>
</div>
<br>
<br>


> The source code available [here]({{site.baseurl}}/assets/posts/images/2024-12-04-draw this, draw that/logo.scad)

## Conclusion

OpenSCAD is a powerful and versatile 3D modelling tool, particularly suited to those who prefer a script-based, parametric approach to design. Its focus is on precision, reproducibility and flexibility. If you're looking for a modelling tool - take a look, it may be just what you're looking for.

## Resources

* [OpenSCAD info](https://www.openscad.info)
* OpenSCAD’s official [documentation](https://en.wikibooks.org/wiki/OpenSCAD_User_Manual)
* *"Programming for OpenSCAD"* by Jordan Dick
* *"OpenSCAD for 3D Printing"* by Al Williams
* the OpenSCAD user group [Reddit](https://www.reddit.com/r/OpenSCAD/)
* built-in example files accessible from the menu: `Help > Examples`.  
* [Thingiverse](https://www.thingiverse.com/) host OpenSCAD files