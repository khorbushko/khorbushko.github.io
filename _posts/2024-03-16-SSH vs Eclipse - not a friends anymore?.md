---
layout: post
comments: true
title: "SSH vs Eclipse - not a friend anymore?"
categories: article
tags: [linux, ssh, ED25519, Eclipse, remote-debug]
excerpt_separator: <!--more-->
comments_id: 98

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

Often during development, we need to have access to the filesystem.  Password-based access is not always a way u want to use, ssh is here for rescue. 
<!--more-->

Using ssh from u'r development IDE is even better - all in one place. Configuring ssh in [Eclipse using Remote Explorer](https://help.eclipse.org/latest/index.jsp?topic=%2Forg.eclipse.rse.doc.user%2Fgettingstarted%2Fg_start.html) looks like a good way to go. But as always - we have a few tricky moments here.

## SSH config

To configure the remote system, we want to use [ED25519](https://en.wikipedia.org/wiki/EdDSA) key - a relatively new cryptography solution implementing [Edwards-curve Digital Signature Algorithm (EdDSA)](https://en.wikipedia.org/wiki/EdDSA). 

> If u wondering why ed25519 is better than rsa, below few cons:
> 
> - it’s faster: to generate and verify
> - it’s more secure
> - collision resilience – this means that it’s more resilient against hash-function collision attacks (types of attacks where large numbers of keys are generated with the hope of getting two different keys to have matching hashes)
> - keys are smaller – this, for instance, means that it’s easier to transfer and copy/paste them
>
> [source](https://www.unixtutorial.org/how-to-generate-ed25519-ssh-key/)

To generate such a key, execute:

```
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/id_ed25519 -C "khorbushko@gmail.com"

```

where:

* `-o` : tells to save the private key with OpenSSH format, implied when used type as `ed25519`.
* `-a`: numbers of KDF (Key Derivation Function) rounds. Higher numbers - slower passphrase verification, but bigger resistance to brute-force password cracking.
* `-t`: the type of the key to create.
* `-f`: the filename of the generated key file.
* `-C`: an option to specify a comment, which can be anything, usually email.

To allow u'r [ssh-agent](https://en.wikipedia.org/wiki/Ssh-agent) to discover this new file automatically - store it in your `~/.ssh` directory.

> You may also want to configure [ssh config](https://linuxize.com/post/using-the-ssh-config-file/) file to speed up future connections, but this is a bit another story.

So, now we have a key and we need to add a public key to the remote server's auth keys:

```
cd ~
mkdir .ssh
chmod 700 .ssh
nano .ssh/authorized_keys 
// and paste the public key - content of generated .pub file
```

> If u connect to just a configured connection and get an error like `btroot@192.168.0.1: Permission denied (publickey).` - u should setup *readable only by the user* permissions to u'r key, using `chmod 600 ~/.ssh/<your key without .pub>`. U can also use the `-v` flag to get a verbose description of the problem with `ssh`.

If everything is done correctly, u can connect via terminal to the remote server:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/ssh-terminal.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/ssh-terminal.png" alt="ssh-terminal" width="500"/>
</a>
</div>
<br>
<br>

Looks good.

Now we can configure [Eclipse Remote Explorer](https://help.eclipse.org/latest/index.jsp?topic=%2Forg.eclipse.rse.doc.user%2Fgettingstarted%2Fg_start.html).

## Eclipse Remote Explorer - The Problem

Now we know, that we can connect to the remote via configured ssh, and it's time to set up remote explorer using this ssh-connection.

After [configuring remote connection](https://help.eclipse.org/latest/index.jsp?topic=%2Forg.eclipse.rse.doc.user%2Fgettingstarted%2Fg_start.html) for the explorer, using the same IP, port (probably default for ssh - 22) and just created, workable ssh key, we trying to connect... But, we got an error.

Error that has quite a detailed description, so we can determine the root cause:

```
Auth fail
```

;[.


That's all, no more details. Great.

After reading a bit about where Eclipse stores its logs, I found the following:

Help->About Eclipse IDE->Installation details->Configuration tab and at the bottom, u can see the button "View Error Log":

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/error log.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/error log.png" alt="ssh-terminal" width="500"/>
</a>
</div>
<br>
<br>

When u press it, u can see detailed logs with failures. The last failure description is probably the one that we are looking for (use timestamp for clarity):

```
!ENTRY org.eclipse.jsch.core 4 150 2024-03-13 21:26:12.346
!MESSAGE An error occurred loading the SSH2 private keys
!STACK 1
com.jcraft.jsch.JSchException: invalid privatekey
...
```

After looking for workarounds for Eclipse, I found [this post](https://cmljnelson.blog/2020/12/11/problem-using-ssh-keys-and-eclipses-remote-system-explorer/) - where a similar problem is described. 

The [solution](https://stackoverflow.com/a/53783283/1493883) that the author describes - is just to replace the ssh key with the old one:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/reason.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/reason.png" alt="reason" width="500"/>
</a>
</div>
<br>
<br>

Also, from the log of the error we can see, that Eclipse uses [Jsch](http://www.jcraft.com/jsch/) - Java secure channel lib. And this libs [has](https://stackoverflow.com/questions/53134212/invalid-privatekey-when-using-jsch) a [few](https://stackoverflow.com/questions/72743823/public-key-authentication-fails-with-jsch-but-work-with-openssh-with-the-same-ke) [points](https://stackoverflow.com/questions/65916546/getting-com-jcraft-jsch-jschexception-auth-fail-but-ssh-can-login-using-p) for improvements.

> the [forked version](https://github.com/mwiede/jsch) already contains fix

## Solution

So the fix is pretty simple:

### Step 1: regenerate the key

```
ssh-keygen -f eclipse_remote_explorer_id_rsa -m pem 
```

where [-m pem](https://man.openbsd.org/ssh-keygen#m) force a classic key

> We can omit `-t rsa`, thus, as mentioned on man page:
> 
> ```
> ssh-keygen can create RSA keys for use by SSH protocol version 1 and
> DSA, ECDSA, or RSA keys for use by SSH protocol version 2. The type of
> key to be generated is specified with the -t option. If invoked without
> any arguments, ssh-keygen will generate an RSA key for use in SSH
> protocol 2 connections.
> ```

> Note, that `ssh-keygen` also prints out the type of key it is generating in its first line of output.


```
khb@localhost: ssh-keygen -f eclipse_remote_explorer_id_rsa -m pem 
Generating public/private RSA key pair.
Enter passphrase (empty for no passphrase): 
Enter the same passphrase again: 
Your identification has been saved in eclipse_remote_explorer_id_rsa
Your public key has been saved in eclipse_remote_explorer_id_rsa.pub
The key fingerprint is:
SHA256:XCEzSldxh5IvEIsBxJk/cwxHwtfbiPgGPIE1I/iquTA khb@localhost.local
The key's randomart image is:
+---[RSA 3072]----+
|   ++BB.B++o...  |
|  . =o+O+=+o..   |
|   . ooB.o.*     |
|    . O.+.+ o    |
|   .   BS  .     |
|  .     o        |
|Eo     .         |
|+.               |
|..               |
+----[SHA256]-----+
```

Now looks like rsa private key as expected by Eclipse:

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/rsa.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/rsa.png" alt="reason" width="500"/>
</a>
</div>
<br>
<br>

### Step 2: update `known_host` on remote
### Step 3: re-connect to the device via remote explorer

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/done.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-16-SSH vs Eclipse - not a friends anymore/done.png" alt="reason" width="500"/>
</a>
</div>
<br>
<br>

## Conclusion

To determine where the problem is - u can always use the approach "split and conquer" - here, for example, I divided the task into 2 parts from the very beginning - ssh config itself and remote explorer config (with ssh under the hood). 

By configuring and testing each part separately we can easily figure out the problem and look for a solution.

## Resources 

- [Eclipse Remote Explorer](https://help.eclipse.org/latest/index.jsp?topic=%2Forg.eclipse.rse.doc.user%2Fgettingstarted%2Fg_start.html)
- [ED25519](https://en.wikipedia.org/wiki/EdDSA)
- [RSA – ed25519](https://www.unixtutorial.org/how-to-generate-ed25519-ssh-key/)
- [ssh config](https://linuxize.com/post/using-the-ssh-config-file/)
- [ssh-agent](https://en.wikipedia.org/wiki/Ssh-agent)
- [configuring remote connection in eclipse](https://help.eclipse.org/latest/index.jsp?topic=%2Forg.eclipse.rse.doc.user%2Fgettingstarted%2Fg_start.html)
- [Eclipse error logs](https://www.eclipse.org/forums/index.php/t/789220/)
- [SO solution for SSH](https://stackoverflow.com/a/53783283/1493883)