---
layout: post
comments: true
title: "Slowloris"
categories: article
tags: [security, slowloris, DoS]
excerpt_separator: <!--more-->
comments_id: 74

author:
- kyryl horbushko
- Lviv
---

To protect something we should know about possible vulnerabilities. Often, the most dangerous one is the most simple one.

Well-known is a denial-of-service attack or simply a DoS attack.
<!--more-->

## overview

The idea behind this is simply shown as a usual actor that uses some remote service and makes it unavailable for another user by interrupting normal functionality. Usually, DoS is a flooding activity that may use some aspects of the system and may create a heavy load on the system until it's corrupted.

If for some reason used few sources then this is not a DoS attack but Distributed DoS or DDoS (for example using a botnet).

DoS attacks have 2 base types:

* buffer overflow
* flood attacks

**Buffer overflow** attacks consume all or some of the finite resources on the target machine - space, CPU, memory, etc.

**Flood Attack** uses a lot of flood packets that use all bandwidth on the target, so it can't respond to normal requests.

Buffer overflow may even cause physical damage (due to heat that can be produced and other side effects).

For now, there are a lot of different attack techniques - on [wiki](https://en.wikipedia.org/wiki/Denial-of-service_attack) u can find more than 25 types of them.

The indicators that can notify u that u under attack are next:

- atypically slow network performance
- the inability to load a particular website
- sudden loss of connectivity across devices on the same network

Of cause - depending on the attack these may vary and depends on the vector of the attack.

## slowloris

Knowing various abilities of the systems and platform it uses we can use some aspects as a weakness with correct use.

According to wiki: ***Slowloris** is a type of denial of service attack tool which allows a single machine to take down another machine's web server with minimal bandwidth and side effects on unrelated services and ports.*

Recently I read a book by [David Flanagan - JavaScript, The Definitive guide 7th edition](https://www.amazon.com/JavaScript-Definitive-Most-Used-Programming-Language/dp/1491952024). He wrote about the possibility to use web servers an ability of HTTP protocol to creating request and so the connection between server and client and not closing this.

> check chapter 15.11.2 Server-Sent Event for more

This is a useful feature that is supported by js using [`EventSource`](https://developer.mozilla.org/en-US/docs/Web/API/EventSource). The downside of this - is that resources needed for such behavior are used and not restored while it's active.

As u already understand, we may use this during an attack.
That's just a sample.

The idea of slowloris - it *tries to keep many connections to the target web server open and hold them open as long as possible. It accomplishes this by opening connections to the target web server and sending a partial request. Periodically, it will send subsequent HTTP headers, adding to, but never completed, the request. Affected servers will keep these connections open, filling their maximum concurrent connection pool, eventually denying additional connection attempts from clients*.

### attack

### theory

Let's review the idea example.

```
POST / HTTP/1.1\r\n Host: putinHuilo.ru\r\n User-Agent: Whatever\r\n Content-Length: 42\r\n X-a: b\r\n\r\n

// and

GET / HTTP/1.1\r\n
Host: putinHuilo.ru\r\n User-Agent: Mozilla/4.0 ...\r\n Connection: Keep-Alive\r\n Range: bytes=0-10\r\n
X-a: b\r\n\r\n
```

### practice

Using the flow described above we can follow the next steps:

For attacking u need a few things:

* Protection for your identity
* executer
* target

As protection, we can use a VPN. Ideally, if a country is the same as the country of the target. 

U can also use various tools. For example, we may use [kali](https://www.kali.org) and within kali u can use [whoami](https://github.com/owerdogan/whoami-project) for protection.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/kali.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/kali.png" alt="design" width="400"/>
</a>
</div>
<br>
<br>

U can hide yourself using one command:

```
sudo kali-whoami --start
```

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/kali-whoami.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/kali-whoami.png" alt="design" width="400"/>
</a>
</div>
<br>
<br>

To check that u'r IP, for example, if u select option 3 from `whoami`, changed, visit check.torproject.org or some other similar resource.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/ip_check.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/ip_check.png" alt="design" width="400"/>
</a>
</div>
<br>
<br>

Executer. U can write u'r own tool for this that requires some time and effort using for example `EventSource` and HTTP, or select one available. According to the wiki, there are a lot of them:

* **PyLoris** – A protocol-agnostic Python implementation supporting Tor and SOCKS proxies.
* **Slowloris** – A Python 3 implementation of Slowloris with SOCKS proxy support.
* **Goloris** – Slowloris for nginx, written in Go.
* **QSlowloris** – An executable form of Slowloris designed to run on Windows, featuring a Qt front end.
* An unnamed PHP version that can be run from an HTTP server.
* **SlowHTTPTest** – A highly configurable slow attacks simulator, written in C++.
* **SlowlorisChecker** – A Slowloris and Slow POST POC (Proof of concept). Written in Ruby.
* **Cyphon** - Slowloris for Mac OS X, written in Objective-C.
* **sloww** - Slowloris implementation written in Node.js.
* **dotloris** - Slowloris written in .NET Core
* **SlowDroid** - An enhanced version of Slowloris written in Java, reducing at minimum the attack bandwidth
* other

As example, lets select [slowloris.py](https://github.com/gkbrk/slowloris).

We can install this tool and run it on sample target:

```
python3 slowloris.py pytinHyilo.com -p 80
```

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/example_attack.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/example_attack.png" alt="design" width="400"/>
</a>
</div>
<br>
<br>

To be able to check the result u can use some resource for checking status of the remote source, for example [ping.pe](ping.pe):

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/result.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-04-05-slowloris/result.png" alt="design" width="400"/>
</a>
</div>
<br>
<br>

## protection

You can't protect fully from such an attack, but u may increase the work needed for the attacker to be done. To do so u may:

* Increase the maximum number of clients the Web server will allow
* Limit the number of connections a single IP address is allowed to attempt
* Place restrictions on the minimum transfer speed a connection is allowed
* Constrain the amount of time a client is permitted to stay connected.
* Use a hardware load balancer that accepts only complete HTTP connections.
* User 3-rd party services for web protection and proxying all requests or some tools like [this one](https://httpd.apache.org/docs/2.2/mod/mod_reqtimeout.html)


## resources

* [DoS](https://www.cloudflare.com/learning/ddos/glossary/denial-of-service/)
* [Denial-of-service attack](https://en.wikipedia.org/wiki/Denial-of-service_attack)
* [Slowloris (computer security)](https://en.wikipedia.org/wiki/Slowloris_(computer_security))
* [kali](https://www.kali.org)
* [whoami](https://github.com/owerdogan/whoami-project)
* [slowloris.py](https://github.com/gkbrk/slowloris)
* [attack](https://samsclass.info/seminars/slowloris.pdf)