---
layout: post
comments: true
title: "MacBook's Journey to Linux - Part 4: Speak to me."
categories: article
tags: [linux, Debian, audio, driver]
excerpt_separator: <!--more-->
comments_id: 96

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

In the last few articles, I cover the process of Linux configuration using MacBookPro14,3 hardware. Not every aspect of the system works as expected out of the box - video, audio, wifi, and other system components need additional attention. In this article, I'll cover how u can fix audio.
<!--more-->

If u are looking for previous parts related to this topic, they are listed below:

- [MacBook's Journey to Linux - Part 1: Hello world!]({% post_url 2024-03-03-MacBook's Journey to Linux - part1 %})
- [MacBook's Journey to Linux - Part 2: Bring the light!]({% post_url 2024-03-04-MacBooks Journey to Linux - part2 %})
- [MacBook's Journey to Linux - Part 3: My little fairies]({% post_url 2024-03-05-MacBooks Journey to Linux - part3 %})
- MacBook's Journey to Linux - Part 4: Speak to me.
 
## The problem

The first step is to determine the problem and all related aspects. If we are talking about audio - we for sure need to know what exact device we want to fix. 

We can try to check system preferences, but there nothing useful exists - just a Dummy Output present - which means no device detected.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-14-MacBook's Journey to Linux - part 4/dummy.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-14-MacBook's Journey to Linux - part 4/dummy.png" alt="disk" width="500"/>
</a>
</div>
<br>
<br>

So, to get this info we can use one of the other existing ways (there are plenty of ways to do this on Linux), and I used the command [lspci](https://man7.org/linux/man-pages/man8/lspci.8.html) with filter *Audio*:
 
```
 lspci -v | grep Audio
```
 
 As result:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-14-MacBook's Journey to Linux - part 4/lspci.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-14-MacBook's Journey to Linux - part 4/lspci.png" alt="disk" width="500"/>
</a>
</div>
<br>
<br>

From the output above u can see our audio device - `Intel Corporation 100 Series/C230 Series Chipset Family HD Audio Controller (rev 31)` (this is the primary one).

Knowing the card name we can try to [update drivers](https://www.intel.com/content/www/us/en/download/18895/intel-system-support-utility-for-the-linux-operating-system.html). 

For me, this way gave 0 results. ;[.

My next step - read about the sound system on [Debian wiki](https://wiki.debian.org/ALSA). 

> Note, u can also check system logs to check what going on with u'r audio device [with](https://man7.org/linux/man-pages/man1/dmesg.1.html) `dmesg | grep -iE "snd|sound"`
 
Using the link above, I read, that there could be a problem with alsa config. 

Following the [alsa project](https://www.alsa-project.org/wiki/Main_Page) main page. I checked again a list of audio cards that is visible for Alsa with `aplay -l` - only `100 Series/C230` was visible at position 0.

I read that the system configuration file is `/etc/asound.conf`, and the per-user configuration file is `~/.asoundrc`. I checked my one at `/etc/asound.conf` and it was empty.

So I added the next lines, according to the docs and output received earlier:

```
default.pcm.card 0
default.pcm.device 0
```

 
<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-14-MacBook's Journey to Linux - part 4/conf.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-14-MacBook's Journey to Linux - part 4/conf.png" alt="disk" width="500"/>
</a>
</div>
<br>
<br>

As a result, nothing changed, but, Dummy Output in system settings periodically blinked with some audio card name. So, at least I see, that the device is recognizable, but due to some reason not fully initiated, so can't be used.

On ALSA wiki page I read *"A sound server will sit between ALSA and your applications. These will traditionally be PulseAudio (for easy and automatic audio), JACK (for professional-grade low-latency audio), or PipeWire (for any use-case, but is still experimental)."* So, I think, that something is wrong with the sound server maybe - pulseAudio was already installed on my distribution. So I decided to test another option - [PipeWire](https://wiki.debian.org/PipeWire) - a server and API for handling multimedia on Linux.

[Installation instruction](https://wiki.debian.org/PipeWire#Debian_12) is pretty simple:

```
apt install wireplumber pipewire-media-session
systemctl --user --now enable wireplumber.service
```

As a result - I saw in the logs, that `wireplumber.service` started and then immediately stoped. A simple relaunch system solves this problem - the audio card is correctly recognized by the system and sound is present.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-14-MacBook's Journey to Linux - part 4/audio.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-14-MacBook's Journey to Linux - part 4/audio.png" alt="disk" width="500"/>
</a>
</div>
<br>
<br>
 
## Resources
 
 - [lspci](https://man7.org/linux/man-pages/man8/lspci.8.html)
 - [Intel® System Support Utility (Intel® SSU) for Linux](https://www.intel.com/content/www/us/en/download/18895/intel-system-support-utility-for-the-linux-operating-system.html)
 - [dmesg](https://man7.org/linux/man-pages/man1/dmesg.1.html) 
 - [Debian wiki](https://wiki.debian.org/ALSA)
 - [alsa project](https://www.alsa-project.org/wiki/Main_Page)
 - [PipeWire](https://wiki.debian.org/PipeWire)
 