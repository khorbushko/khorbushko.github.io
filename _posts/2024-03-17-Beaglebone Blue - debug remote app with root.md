---
layout: post
comments: true
title: "BeagleBone® Blue - debug as root"
categories: article
tags: [BeagleBone® Blue, Eclipse, remote-debug, root, cross-compile]
excerpt_separator: <!--more-->
comments_id: 101

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

Depending on the app's functionality and our needs, u may faced with a situation, when u need root permission to do certain things on the PC - open some port for network connection or use memory binding or some other stuff.

During developing an app for [Beaglebone® Blue](https://www.beagleboard.org/boards/beaglebone-blue) I faced the same issue. In this article, I would like to cover how to configure the root user for the u'r ssh connection needed for remote debugging.

Related articles:

- [BeagleBone® Blue - initial config via serial port]({% post_url 2024-03-12-Beaglebone Blue - initial config via serial port %})
- [Beaglebone® Blue - environment setup]({% post_url 2024-03-15-Beaglebone Blue - environment setup %})
- [BeagleBone® Blue - remote debug]({% post_url 2024-03-16-Beaglebone Blue - remote debug %})
- BeagleBone® Blue - debug remote app with root

## Problem

We already have configured an environment for remote debugging BBB with [Eclipse](https://www.eclipse.org/downloads/), but the app requires an additional level of access to be able to execute some commands.

In my case - I need to open port **80** while deploying a small server for further communication. 

This port is in [privileged group](https://www.w3.org/Daemon/User/Installation/PrivilegedPorts.html):

*The TCP/IP port numbers below 1024 are special in that normal users are not allowed to run servers on them. This is a security feature, in that if you connect to a service on one of these ports you can be fairly sure that you have the real thing and not a fake that some hacker has put up for you.*

There are a few workarounds proposed by the community for this - like next:

- [`authbind`](https://en.wikipedia.org/wiki/Authbind) 
- trafic [redirect](https://www.frozentux.net/iptables-tutorial/iptables-tutorial.html#REDIRECTTARGET)
```
iptables -A PREROUTING -t nat -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3000
```
- using the `sudo` command as a prefix for an app that will be executed
- config [`CAP_NET_BIND_SERVICE`](https://superuser.com/questions/710253/allow-non-root-process-to-bind-to-port-80-and-443/892391#892391) with `sudo setcap CAP_NET_BIND_SERVICE=+eip /path/to/binary`
- [`sysctl`](https://en.wikipedia.org/wiki/Sysctl) [method](https://bbs.archlinux.org/viewtopic.php?id=242375) :
-  
```
sysctl net.ipv4.ip_unprivileged_port_start=80
sysctl -w net.ipv4.ip_unprivileged_port_start=80 // persistent version
```
with blocking other ports 

```
iptables -I INPUT -p tcp --dport 444:1024 -j DROP
iptables -I INPUT -p udp --dport 444:1024 -j DROP
```

The best as for me way to handle this is to use `sysctl -w net.ipv4.ip_unprivileged_port_start=80` command, but, we also have other parts of the app, that require root access - in my case, initialization of [`librobotcontrol`](https://github.com/beagleboard/librobotcontrol) functionality related to the motor control require some memory binding, that require root. 

```
ERROR: in rc_pru_shared_mem_ptr could not open /dev/mem: Permission denied
Need to be root to access PRU shared memory
ERROR in rc_servo_init, failed to map shared memory pointer
```

> when call `rc_servo_init()` from the lib.

So looking workaround for each case is not an option.

> Off cause, making something with root access is used only for development, and for prod, we can register some service that can run root routines. In general, this is a bad idea to use root access for the app.

I found [this post](https://discuss.96boards.org/t/remote-debug-gdb-as-root/6035/2) very interesting - exactly my problem.

And as suggested by [danielt](https://discuss.96boards.org/u/danielt), we have 3 ways how to handle this with Eclipse:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-17-Beaglebone Blue - debug remote app with root/ways.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-17-Beaglebone Blue - debug remote app with root/ways.png" alt="ways" width="600"/>
</a>
</div>
<br>
<br>

The good way to go for me - is option #3: *"Configure eclipse to connect as the root user (e.g. set up SSH to make it possible to ssh root@linaro-alip and change the username eclipse uses to connect with)."*

So our next task consists of 2 parts:

- make the current user that is used for debugging a root user
- enable ssh for root user ([by design](https://cvsweb.openbsd.org/cgi-bin/cvsweb/src/usr.bin/ssh/auth2.c?rev=1.156&content-type=text/x-cvsweb-markup) is [forbidden](https://unix.stackexchange.com/a/537469) due to privacy)

## Making user as root

Switching users to root is not a problem - there are plenty of ways to do this. Our goal - is to not only allow user to run root commands with [`sudo`](https://www.man7.org/linux/man-pages/man8/sudo.8.html) without password (using [`sudoers`](https://man7.org/linux/man-pages/man5/sudoers.5.html) for [example](https://askubuntu.com/questions/1268638/sudo-privilege-is-not-working-even-after-adding-to-sudo-users)) but eliminate the sudo prefix - because for Eclipse there is no option to add sudo before program executing with [`gdbserver`](https://en.wikipedia.org/wiki/Gdbserver).


### make a new root user

There are a lot of ways to do this, I just modify `/etc/passwd` by setting group and access level to the user for `0:0` - making the user a root one:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-17-Beaglebone Blue - debug remote app with root/root user.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-17-Beaglebone Blue - debug remote app with root/root user.png" alt=" root user" width="500"/>
</a>
</div>
<br>
<br>

> To do so run `sudo su` and then `nano /etc/passwd`, modify, Ctrl+X, Y, enter.
> Note: create one more backup connection to the board via SSH, because if u close the active one with some changes u may lose access to the board.

### enable ssh for root user

To enable ssh for root we need to modify `sshd_config` file:

```
sudo su
nano /etc/ssh/sshd_config
```

search for `PermitRootLogin`, uncomment, and set to `yes`, but u also want to modify the root user for which u allow this action by adding `AllowUsers <username1>, <usernanem2>`.

> Note - u should add this near `PermitRootLogin` pref because in another case u can put this line near some [`Match`](https://www.man7.org/linux/man-pages/man5/ssh_config.5.html) that will hold value for own purposes.
> Also, make sure that u uncomment value and not adding a new one.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-17-Beaglebone Blue - debug remote app with root/ssh_root.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-17-Beaglebone Blue - debug remote app with root/ssh_root.png" alt="ssh_root" width="500"/>
</a>
</div>
<br>
<br>

> If u not enabled an SSH account before u may need to set the root password by executing `sudo passwd`

Restart SSH service:

```
service ssh restart
```

> Alternative way:

```
root@debian:~$ grep PermitRootLogin /etc/ssh/sshd_config
#PermitRootLogin prohibit-password
# the setting of "PermitRootLogin without-password".
root@debian:~$
root@debian:~$ man sshd_config | grep -C 1 prohibit-password
     PermitRootLogin
             Specifies whether the root can log in using ssh(1).  The argument must be yes, prohibit-password, forced-commands-only, or no.  The default
             is prohibit-password.

             If this option is set to prohibit-password (or it's deprecated alias, without-password), password and keyboard-interactive authentication
             are disabled for root.
root@debian:~$
root@debian:~$ sudo systemctl restart ssh
root@debian:~$
```

Now u can connect via SSH to u'r root user and Eclipse is happy because u run all commands as root in debug.

## Resources

- [Beaglebone® Blue](https://www.beagleboard.org/boards/beaglebone-blue) 
- [Eclipse](https://www.eclipse.org/downloads/)
- [authbind](https://en.wikipedia.org/wiki/Authbind)
- [`sysctl method`](https://stackoverflow.com/a/27989419/22678415)
- [privileged ports](https://www.w3.org/Daemon/User/Installation/PrivilegedPorts.html)
- [`librobotcontrol`](https://github.com/beagleboard/librobotcontrol)
- [`sudo`](https://www.man7.org/linux/man-pages/man8/sudo.8.html)
- [`sudoers`](https://man7.org/linux/man-pages/man5/sudoers.5.html) 
- [Sudo privilege issue SO](https://askubuntu.com/questions/1268638/sudo-privilege-is-not-working-even-after-adding-to-sudo-users)
- [Remote debug GDB as Root](https://discuss.96boards.org/t/remote-debug-gdb-as-root/6035/2)
- [kali root](https://www.kali.org/docs/general-use/enabling-root/) 