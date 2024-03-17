---
layout: post
comments: true
title: "BeagleBone® Blue - duplicate & distribute"
categories: article
tags: [BeagleBone® Blue, distribution]
excerpt_separator: <!--more-->
comments_id: 101

author:
- kyryl horbushko
- Kyiv
- 🇺🇦 Ukraine 🇺🇦
---

One more post related to [Beaglebone® Blue](https://www.beagleboard.org/boards/beaglebone-blue). At this time I just want to put here small notes about making a bootable self-flashing SD card with a pre-configured board config, so distribution becomes more painless.
<!--more-->

Related articles:

- [BeagleBone® Blue - initial config via serial port]({% post_url 2024-03-12-Beaglebone Blue - initial config via serial port %})
- [Beaglebone® Blue - environment setup]({% post_url 2024-03-15-Beaglebone Blue - environment setup %})
- [BeagleBone® Blue - remote debug]({% post_url 2024-03-16-Beaglebone Blue - remote debug %})
- [BeagleBone® Blue - debug remote app with root]({% post_url 2024-03-17-Beaglebone Blue - debug remote app with root %})
- BeagleBone® Blue - duplicate & distribute

There are many ways to get the contents of the eMMC to save and reuse. I selected 2, that require minimal efforts.

> This is just a note copied from other places, mostly for myself, so I can easily refresh my memory when needed.

## option 1

1. Boot master BBB with no SD card in
2. Insert SD card
3. Log in (e.g. with serial terminal, SSH etc.) and run [`sudo /opt/scripts/tools/eMMC/beaglebone-black-make-microSD-flasher-from-eMMC.sh`](https://github.com/RobertCNelson/boot-scripts/blob/master/tools/eMMC/beaglebone-black-make-microSD-flasher-from-eMMC.sh). LEDs will flash in sequence whilst SD card is being written.
4. When the LEDs stop and the script terminates, remove the SD card.
5. Insert SD card into new BBB then power on.
6. eMMC will be flashed; LEDs on new BBB will flash in sequence until complete.

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-18-Beaglebone Blue - duplicate and distribute/run-option1.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-18-Beaglebone Blue - duplicate and distribute/run-option1.png" alt="run-option1" width="500"/>
</a>
</div>
<br>
<br>

<div style="text-align:center">
<a href="{{site.baseurl}}/assets/posts/images/2024-03-18-Beaglebone Blue - duplicate and distribute/ run-option1-complete.png">
<img src="{{site.baseurl}}/assets/posts/images/2024-03-18-Beaglebone Blue - duplicate and distribute/run-option1-complete.png" alt="run-option1" width="500"/>
</a>
</div>
<br>
<br>

> author [emmoris](https://stackoverflow.com/users/1333925/emorris) from [here](https://stackoverflow.com/a/36153910/22678415)

## option 2 

**Backup the eMMC**

1. FAT format a 4GB or larger SD card (must be a MBR/bootable formatted microSD card)
2. Download [beagleboneblack-save-emmc.zip](https://s3.amazonaws.com/beagle/beagleboneblack-save-emmc.zip) and extract the contents onto your SD card

	> Note: this is an image from Jason Krinder at his github https://github.com/jadonk/buildroot using the save-emmc-0.0.1 tag

3. Put the card into your powered off Beaglebone Black
4. Power on your Beaglebone Black while holding the S2 Button
5. The USR0 led will blink for about 10 minutes, when it's steady on you have an SD card with a copy of your eMMC in a .img file

**Use the eMMC to flash a new Beaglebone Black**

1. On the SD card edit autorun.sh

	```
	#!/bin/sh
	echo timer > /sys/class/leds/beaglebone\:green\:usr0/trigger 
	dd if=/mnt/<image-file>.img of=/dev/mmcblk1 bs=10M
	sync
	echo default-on > /sys/class/leds/beaglebone\:green\:usr0/trigger
	```
	> where <image-file> is the image file you got after copying backing up your eMMC
	
2. Insert the card into your powered off Beaglebone Black
3. Power on your Beaglebone Black while holding the S2 Button
4. The Beaglebone Black should go into rebuilding mode and within about 20 minutes you'll have a newly flashed Beaglebone Black (when all 4 USR LEDs are solid) with a copy of your original

> author [Paul Ryan](https://stackoverflow.com/users/281335/paul-ryan) from [here](https://stackoverflow.com/a/23583034/22678415)

## Resources

- [Beaglebone® Blue](https://www.beagleboard.org/boards/beaglebone-blue) 
- [BeagleBone Black Extracting eMMC contents](https://elinux.org/BeagleBone_Black_Extracting_eMMC_contents)
- [SO post](https://stackoverflow.com/questions/17834561/duplicating-identical-beaglebone-black-setups)
- [scripts](https://github.com/RobertCNelson/tools/tree/master/scripts)
- [`sudo /opt/scripts/tools/eMMC/beaglebone-black-make-microSD-flasher-from-eMMC.sh`](https://github.com/RobertCNelson/boot-scripts/blob/master/tools/eMMC/beaglebone-black-make-microSD-flasher-from-eMMC.sh)