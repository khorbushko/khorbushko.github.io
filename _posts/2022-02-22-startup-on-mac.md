---
layout: post
comments: true
title: "Startup on macOS"
categories: article
tags: [macOS, startup, launchd, daemons]
excerpt_separator: <!--more-->
comments_id: 71

author:
- kyryl horbushko
- Lviv
---

More and more providers would like if someone to use the app they produce. One option - make them auto-runnable within OS, or by introducing some additional services that can do the *dirty* job for them. *Dirty* - because the app didn't ask u about this - like u or not.
<!--more-->

In my understanding, good behavior - is when the app has a checkbox that u can use to add it to start-up items. This checkbox shouldn't be somehow auto-enabled by the app - only by u, a user.

A quick example - Google or Microsoft likes to help us do stuff that they think we want to do - to add 100500 auto-starting services that constantly collect some data and statistics, check updates, or... just eat u'r resources... literally.

Another example: if u work in some company and u'r mac is maintained by admins - it's likely that u have a lot of bg services or some other not-very useful soft for u that runs on every start-up, maybe even with some profiles...

Or maybe simply u have an old mac and over time it's become slower and slower.

> Why I'm talking about this? Well, I was faced with an issue, that after every startup the mac (I have the old one from 2017) is very slow due to some 3rd party services that I didn't want to run.


I won't cover the basic approaches that can be used for enabling/disabling autostart (like prefs or context menu), instead - let's review the places in the system that can be used for this.

## from the beginning...

The first action - turn on the mac ;]. This gives the power to the hardware and special soft is started for initializing hardware parts (like OpenFirmware of Extensible Firmware Interface (EFI)).

This part is done - and inaction comes boot loader(s).

> if u do nothing(default) - the macOS will be loaded graphically. U can use some options (like CMD+V) to change this. The full list of these options can be found [here](https://support.apple.com/en-us/HT201255)

macOS has BootX and boot.efi boot loaders at `/System/Library/CoreServices`. Boot loaders draw the logo and load kernel extensions - kexts: 

* `/System/Library/Extensions`.

When boot loaders are done - the control goes to the kernel - `/mach_kernel`.

The kernel initializes all components needed for the system and does a bit more additional stuff. What is interesting for us - is that he also launch the very first process - [`launchd`](https://en.wikipedia.org/wiki/Launchd). This process launches the daemons and starts [`SystemStarter`](https://en.wikipedia.org/wiki/SystemStarter) (this one starts programs) in older versions.

> `SystemStarter` appears to have been removed from OS X 10.10 and later.

`LaunchDaemons` and `LaunchAgents` - Processes that launchd starts. `LaunchAgents` starts only when user logged in. `LaunchDaemons` - starts always in background.

The interesting moments here is about what locations are used for getting preferences files for `LaunchDaemons`:

* `/System/Library/LaunchDaemons`
* `/Library/LaunchDaemons`

`launchd` also loads startup items and launch agents with login items on login. 

> The `PID` of this process - 1. 

`LaunchAgent` can be placed in a few places:

* `/System/Library/LaunchAgents` - system
* `/Library/LaunchAgents` - locally
* `~/Library/LaunchAgents` - for specific user

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-02-22-startup-on-mac/launchd.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-02-22-startup-on-mac/launchd.png" alt="launchd.png" width="350"/>
</a>
</div>
<br>
<br>

One more interesting process - `SystemStarter`. The places which are checkeds:

* `/System/Library/StartupItems`
* `/Library/StartupItems`

> I mention that `SystemStarter` is not used in a way as it was before and so part of its responsibilities are now at `launchd`.

Apps, that starts every time u logged in can be at `LoginItems` and they are stored in preferences:

* `/Library/Preferences/loginwindow.plist` - global
* `~/Library/Preferences/loginwindow.plist` - user specific

> This is also available via the `Settings.app`.

### `launchctl`

[`launchctl`](https://ss64.com/osx/launchctl.html) is a small utility that can help u to control the launch daemons.

We can list all daemons, load or unload them. The most used commands:

```
// list 
launcgctl list
// load
launchctl load -w <prefs>
// unload
launchctl unload -w <prefs>
// show for specific id
launchctl print gui/504
// persistent config
launchctl config user umask <mask>
// reboot
launchctl reboot <params>
```

> **Umasks**. Every file and folder on your Mac has a set of permissions. When you create a new file or folder, the umask determines these permissions.
> 
> [source](https://support.apple.com/en-us/HT201684)


<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-02-22-startup-on-mac/list.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-02-22-startup-on-mac/list.png" alt="list.png" width="350"/>
</a>
</div>
<br>
<br>

## periodic

Some periodic items can be registered in the u'r system - [`cron`](https://en.wikipedia.org/wiki/Cron).

Previously config file contains a periodic list of tasks.
Now, 3 different daemons runs for each type of tasks - for daily, weekly and monthly activities:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-02-22-startup-on-mac/periodic.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-02-22-startup-on-mac/periodic.png" alt="periodic.png" width="350"/>
</a>
</div>
<br>
<br>

These daemons runs scripts at `/etc/periodic`:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2022-02-22-startup-on-mac/etc-periodic.png">
<img src="{{site.baseurl}}/assets/posts/images/2022-02-22-startup-on-mac/etc-periodic.png" alt="etc-periodic.png" width="350"/>
</a>
</div>
<br>
<br>

## now what?

I listed above the main places where some app can register itself or some services for his needs in a system. U can check these places and cleanUp unwanted items there.

> be careful when u delete something - make sure u aware of what exactly u do ;]

Alternatively, u can use a lot of apps, that provide such options. Note, that the biggest part of them register their processes).

I'd prefer to do everything manually - longer, but u definitely do it right. Alternative - a good script that can do the trick.

## Resources

* [Mac startup key combinations](https://support.apple.com/en-us/HT201255)
* [`launchd`](https://en.wikipedia.org/wiki/Launchd)
* [`SystemStarter`](https://www.usenix.org/legacy/publications/library/proceedings/bsdcon02/full_papers/sanchez/sanchez_html/index.html)
* [Mac os essentials](https://training.apple.com/content/dam/appletraining/us/en/2021/documents/macos_support_essentials_11_exam_preparation_guide.pdf)
* [`launchctl`](https://ss64.com/osx/launchctl.html)
* [umask](https://support.apple.com/en-us/HT201684)
* [Daemons and Agents](https://developer.apple.com/library/archive/technotes/tn2083/_index.html)
* [Lingon](https://www.peterborgapps.com/lingon/)
* [`cron`](https://en.wikipedia.org/wiki/Cron)
* Mac OS X for Unix Geeks by Ernest E. Rothman & Brian Jepson & Rich Rosen