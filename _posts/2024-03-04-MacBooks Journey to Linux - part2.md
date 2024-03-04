---
layout: post
comments: true
title: "MacBook's Journey to Linux - Part 2: Bring the light!"
categories: article
tags: [linux, Debian, wifi, driver]
excerpt_separator: <!--more-->
comments_id: 94

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

In [previous post]({% post_url 2024-03-03-MacBook's Journey to Linux - part1 %}) related to the configuration of Linux on MacBookPro14,3 I mentioned, that we have a problem with wifi. In this article, I want to describe how to solve this.
<!--more-->

> This is just a note, mainly for me, that describes how to fix wifi on Debian with MacBook hardware

## Problem

The problem is clear - wifi can discover part(!) of networks (only 2.4GHz), but cannot connect to them.

> Workaround - create a fresh hotspot (every time with a new pwd) on the phone and connect to it, after u can reconnect to any wifi.

## Solution

The very first thing - we should determine which device has a problem. To do so, we can use [`lspci`](https://man7.org/linux/man-pages/man8/lspci.8.html) with [`grep`](https://man7.org/linux/man-pages/man8/lspci.8.html) command.

> I wrote a post some time ago about a great tool [`grep`]({% post_url 2022-07-07-grep %})

My output:

```
khb@localhost$ ispel | grep Network
03:00,0 Network controller: Broadcom ine, and subsidiaries BCM43602 802,11ac Wireless LAN SOC (rev 02)
khb@localhost$
```

Now we can see, that problem with the `bcm43602` wifi adapter. 

## Fix

To [fix](https://gist.github.com/torresashjian/e97d954c7f1554b6a017f07d69a66374) this problem, we should install the correct driver for this device. 

```
sudo apt-get purge bcmwl-kernel-source
sudo apt update
sudo update-pciids
sudo apt install firmware-b43-installer
```
perform a reboot, and start:

```
sudo iwconfig wlp3s0 txpower 10dBm
```
> The reason for me is unknown, but with less transmission power, the wifi adapter starts working well... Thanks to [`iwconfig`](https://linux.die.net/man/8/iwconfig), it's easy to do.

To determine name of the your card run `iwconfig`:

```
khb@localhost: $ sudo iconfig
lo				no wireless extensions.

wlp3s0
				IEEE 802.11 ESSID: "NAME"
				Mode: Managed Frequency:2.457 GHZ Access Point: 40:3F:8C:B7:B4:24
				Bit Rate=24 Mb/s Tx-Power=31 dBm
				Retry short limit:7
				RTS thr:off
				Fragment thr: off
				Encryption key:off
				Power Management: on
				Link Quality=29/70 Signal level=-81 dBm
				Rx invalid nwid:0 Rx invalid crypt:0 Rx invalid frag:0
				Tx excessive retries: 198 Invalid misc:0 Missed beacon:0
khb@localhost: ~$
```

Done. 

The problem here is that the last command must be executed after every reboot.

To automate this process, we can create a service that will be executed automatically with root (`sudo`) after every system starts. [`systemd`](https://systemd.io) will be used for this.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-04-MacBooks Journey to Linux - part2/startup-systemd.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-04-MacBooks Journey to Linux - part2/startup-systemd.png" alt="demo" width="400"/>
</a>
</div>
<br>
<br>

- create file:
`sudo touch /opt/netshift.sh`

- edit content:
`gedit admin:///opt/netshift.sh`

- add command (the last one from the above solution):

```
#!/bin/sh
sleep 20
iwconfig wlp3s0 txpower 10dBm
exit 0
```

> actual command does not (and must not) contain `sudo`! That's because in [`systemd`](https://systemd.io) it already has a root.

- save and close
- give execute permission to script `sudo chmod u+x /opt/netshift.sh`
- create new `systemd` service:

```
sudo touch /etc/systemd/system/netshift.service
```

- edit the new service:

```
gedit admin:///etc/systemd/system/netshift.service
```

- add content to the [service](https://debian-handbook.info/browse/stable/unix-services.html) file:

```
[Unit]
Description=Netshift service
After=network.target

[Service]
ExecStart=/opt/netshift.sh

[Install]
WantedBy=multi-user.target
```
- start service

```
sudo systemctl start netshift
```

- enable service so he can be started on boot:

```
sudo systemctl enable netshift
```

- reboot pc, wait 20 sec and wifi should auto-connect to prev network.

- to remove service:

```
sudo systemctl stop netshift
sudo systemctl disable netshift
sudo rm -v /opt/netshift.sh
sudo rm -v /etc/systemd/system/netshift.sh
```

> All this tutorial is available thanks to [this](https://easylinuxtipsproject.blogspot.com/p/root-command-startup.html) post

## Resources

- [`lspci`](https://man7.org/linux/man-pages/man8/lspci.8.html)
- [`grep`](https://man7.org/linux/man-pages/man8/lspci.8.html)
- [grep]({% post_url 2022-07-07-grep %})
- [`iwconfig`](https://linux.die.net/man/8/iwconfig)
- [wifi fix](https://gist.github.com/torresashjian/e97d954c7f1554b6a017f07d69a66374)
- [`systemd`](https://systemd.io)
- [service on unix](https://debian-handbook.info/browse/stable/unix-services.html) 