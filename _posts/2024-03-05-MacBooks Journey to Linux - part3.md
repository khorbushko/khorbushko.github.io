---
layout: post
comments: true
title: "MacBook's Journey to Linux - Part 3: My little fairies"
categories: article
tags: [linux, Debian, terminal]
excerpt_separator: <!--more-->
comments_id: 95

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

Configuration of the system requires a lot of actions and tasks. Without a terminal, this can quickly become a nightmare.
<!--more-->

Here, I just want to note a list of very useful commands, that can be used by everyone. Part of them are available on Mac, but some - are only for Linux.

## My little fairies

Below I noted just the most used commands by myself. 

> This is not a comprehensive guide or some [cheat sheet](https://www.linuxtrainingacademy.com/linux-commands-cheat-sheet/).

|**Dirs**| |
|:----|:----|
|Current|[`pwd`](https://man7.org/linux/man-pages/man1/pwd.1.html)|
|Change directory|[`cd dir`](https://man7.org/linux/man-pages/man1/cd.1p.html)|
|Go up|[`cd ..`](https://man7.org/linux/man-pages/man1/cd.1p.html)|
|Make dir|[`mkdir dir`](https://man7.org/linux/man-pages/man1/mkdir.1.html)|
|List files|[`ls`](https://man7.org/linux/man-pages/man1/ls.1.html)|
|**Process/Service**| |
|Show snapshot of processes|[`ps`](https://man7.org/linux/man-pages/man1/ps.1.html)|
|Show real-time processes|[`top`](https://man7.org/linux/man-pages/man1/top.1.html)|
|Kill process with id pid|[`kill -9 PID`](https://man7.org/linux/man-pages/man2/kill.2.html)|
|Find by name|[`pgrep -f <path to the service>`](https://man7.org/linux/man-pages/man1/pgrep.1.html)|
|Status|[`systemctl status <name>`](https://man7.org/linux/man-pages/man1/systemctl.1.html)|
|Stop/Start service|`systemctl stop <name>` and `systemctl start <name>`|
|**File**| |
|Mode GOD ;]|[`chmod 777 file`](https://man7.org/linux/man-pages/man1/chmod.1.html)|
|Permission to read/write|[`chmod 600 <file>`](https://man7.org/linux/man-pages/man1/chmod.1.html)|
|File owner|[`chown user:group <file>`](https://man7.org/linux/man-pages/man1/chown.1.html)|
|**PCKG**| |
|Search pckg|[`dpkg -l | grep <name>`](https://man7.org/linux/man-pages/man1/dpkg.1.html)|
||[`sudo ldconfig -p | grep <name>`](https://man7.org/linux/man-pages/man8/ldconfig.8.html)|
|List by pattern|[`sudo locate <name>`](https://man7.org/linux/man-pages/man1/locate.1.html)|
|Search in dirs|[`find -iname <name>* //partial name`](https://man7.org/linux/man-pages/man1/find.1.html)|
|**Archive**| |
|Unpack|[`tar xzf <name>.tgz`](https://man7.org/linux/man-pages/man1/tar.1.html)|
|Pack|[`gzip file.txt`](https://man7.org/linux/man-pages/man1/tar.1.html)|
|**Transfer**| |
|Copy a file to a server directory securely using the Linux scp command.|[`scp [source_file] [user]@[remote_host]:[destination_path]`](https://man7.org/linux/man-pages/man1/scp.1.html)|
|Synchronize the contents of a directory with a backup directory using the rsync command.|[`rsync -a [source_directory] [user]@[remote_host]:[destination_directory]`](https://man7.org/linux/man-pages/man1/rsync.1.html)|

Few other notes

- **Permission** code

The first digit is **owner** permis­sion, the second is **group**, and the third is **everyone**.
Calculate permission digits by adding the numbers below.


<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-05-MacBooks Journey to Linux - part3/linux-permissions-chart.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-05-MacBooks Journey to Linux - part3/linux-permissions-chart.png" alt="demo" width="400"/>
</a>
</div>
<br>
<br>

> 
> Example
> 
> 4 - read (r)
> 
> 2 - write (w)
> 
> 1 - execute (x)
> 
> rwx rwx rwx     chmod 777 filename
> 
> rw- --- ---     chmod 600 filename
>


- **Nano** shortcut

**Read** - Ctrl-R

**Save** - Ctrl-O

**Close** - Ctrl-X


## Resources

* [man7](https://man7.org/)
* [cheat-sheet](https://www.linuxtrainingacademy.com/linux-commands-cheat-sheet/)
