---
layout: post
comments: true
title: "Knowledge is our power"
categories: article
tags: [programming, Pascal]
excerpt_separator: <!--more-->
comments_id: 121

author:
- kyryl horbushko
- another world
- 🇺🇦 Ukraine 🇺🇦
---

I guess everyone has heard at least a few times during life, that "Your knowledge is your wealth"(or as it says in my country - "Знання за спиною не носити", which literally can be translated as "You can't carry knowledge on your back."). 
<!--more-->

And indeed, I have a few moments when I learn something, and an idea that "this may be something that I will never use in my life" may appear. But, u know, life is unpredictable (or at least hardly predictable - to friends with AI), and the road is so curvy. Here is an example of how such knowledge can be helpful.

## The story

Recently, I was faced with quite old software that is still doing some work with periodic success. And from time to time, I have some issues within it. 

Software has its own [`DSL`](https://en.wikipedia.org/wiki/Domain-specific_language) (derived from [`Pascal`](https://en.wikipedia.org/wiki/Pascal_(programming_language)) ). This software has some support personnel, but in general, it's almost not supported (due to its age). 

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2025-09-19-knowledge-is-our-power/old_software.png">
<img src="{{site.baseurl}}/assets/posts/images/2025-09-19-knowledge-is-our-power/old_software.png" alt="old_software.jpeg" width="500"/>
</a>
</div>
<br>
<br>

Without software support in case of some issue, we can always do the job manually - this, of course, will lead to some additional time spent and effort. I am a bit of a lazy person, so I prefer to do things only once. That's why I like to dive into a problem and solve it, so it never appears again. 

This time, the problem was with report handling - some data was not properly displayed in the report (to be honest, it was completely missing). So I started to look at a report source written in DSL that was based on a [`Pascal Script`](https://en.wikipedia.org/wiki/Pascal_Script). 

I was learning this programming language by myself when I was in 8th grade. I have a book named "Turbo Pascal 7.0".

>  I can't find a reference to this book, and the book itself is somewhere in an unknown place (sorry for this). 

 I remember that I wrote some simple programs that could sort arrays and other similar stuff, and that it wasn't until this last time I used this language again. 

But here we go - this report uses [`Pascal Script`](https://en.wikipedia.org/wiki/Pascal_Script) and some limited version of [`SQL`](https://en.wikipedia.org/wiki/SQL). I'm not an expert in these languages, but, knowing the basics, u can handle it and solve the problem. That's where even old knowledge can help a lot!

Indeed, I spend a day or so for reviewing DB tables (around 2500 tables in DB), figured out the place where data was stored by the app, and using [`SQL`](https://en.wikipedia.org/wiki/SQL) to wrote a simple query to DB, after that, using [`Pascal Script`](https://en.wikipedia.org/wiki/Pascal_Script) I integrated this query into report and voila - report now show missing data.

I don't want to put the code that I used for solving this issue, because it will give no benefits to anyone. Instead, here is just a quick sample of code I grabbed from a report, so u can look and taste the time when [`Pascal`](https://en.wikipedia.org/wiki/Pascal_(programming_language)) was in use:

{% highlight Pascal %}

procedure DeleteDelim(var str: string; delim: string);
var len, dlen: integer;
begin dlen:= Length(delim);
    len:= Length(str);
    
    if len > dlen then
        DeleteStr(str, len - dlen + 1, dlen);
end;

function Squeeze (arr: array of Variant; delim: string = ', '): string;
var i, len, dlen: integer;
    s, svalue: string;
begin 
    dlen:= Length(delim);
    len:= Length(arr) - 1;
    
    S:= ";
    for i:= O to len do 
    begin
       svalue:= Trim(VarToStr(arr[i]));
       if not empty(svalue) then
          S:= s + svalue + delim;
    end;
    
    DeleteDelim (s, delim); 
    result:= s;
end;

{% endhighlight %}

As u can see, similar construction that we use in modern languages - same `if`, same `for`, same `var`, and same `function` - the difference is only a syntax. 

Of course, this is not an assembler, not a language for machines (that was in use in the early days of programming, when only mathematicians could program) -  this is one of the [high-level languages](https://en.wikipedia.org/wiki/High-level_programming_language) that was in use more than 30 years ago. 

Do I have a chance to add a fix without knowing [`Pascal`](https://en.wikipedia.org/wiki/Pascal_(programming_language)) - Sure!. The only point is efficiency. Having some background, doing stuff is much easier.
 

## Conclusion

Nothing special in this story, I guess a lot of us have faced a similar situation, but someone - not (or better to say not YET). 

The truth is that our knowledge is our power, u can't have bad knowledge. A bit outdated - yes, is this bad - maybe, but in general, it's always good to have outdated knowledge in comparison to nothing. 

Do not misunderstand me - outdated information can be dangerous in certain situations (if we use it as non-outdated, especially), but this is not the same as outdated (maybe better to say deprecated) knowledge. 

It's still can be in use and usefull, it's still can work and do some stuff, and sometimes is even better (for some time at least) than a progressive variant (a good example is when [Ken Thompson](https://en.wikipedia.org/wiki/Ken_Thompson) from [Bell Labs](https://en.wikipedia.org/wiki/Bell_Labs) want to rewrite a core for [Unix](https://en.wikipedia.org/wiki/Unix) on [PDP/7](https://en.wikipedia.org/wiki/PDP-7) using a fresh [`C`](https://en.wikipedia.org/wiki/C_(programming_language)) lang - he tried 3 times and sad, that the language is bad, until `struct` not appears in the  [`C`](https://en.wikipedia.org/wiki/C_(programming_language)))

> “Thompson started in the summer of 1972 … and [had] the difficulty in getting the proper data structure, since the original version of C did not have structures.”
> 
> “These rewrites failed twice in the space of six months, I believe, because of problems with the language. … The third rewrite … was successful; it turned into version 5 in the labs and version 6 that got out to universities.”  ([source](https://www.cs.princeton.edu/courses/archive/spring03/cs333/thompson?utm_source=chatgpt.com))

<br>

As people say: 
"The devil knows many things because he is old"  ("Старий віл борозни не псує")

## Resources

* [`Pascal`](https://en.wikipedia.org/wiki/Pascal_(programming_language))
* [`Pascal Script`](https://en.wikipedia.org/wiki/Pascal_Script)
* [`SQL`](https://en.wikipedia.org/wiki/SQL)
* [`C`](https://en.wikipedia.org/wiki/C_(programming_language))
* [Bell Labs](https://en.wikipedia.org/wiki/Bell_Labs)
* [Ken Thompson](https://en.wikipedia.org/wiki/Ken_Thompson)
* [Unix](https://en.wikipedia.org/wiki/Unix)