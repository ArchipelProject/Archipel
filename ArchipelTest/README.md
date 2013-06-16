# What is Archipel Test ?

ArchipelTest is a suite of scripts which test all aspects of Archipel code on a self-contained machine like your laptop.
It leverages ANSOS and nested virtualization capabilities to launch several Archipel hypervisors and then virtual machines inside them.
See Documentation.

# License

Archipel is distributed under AGPL v3. See the LICENSE files in eggs


# Read me!

Please, read this document completely before typing anything!


# Get help

* Website : <http://archipelproject.org>
* Nighty Builds : <http://nightlies.archipelproject.org>
* Test application : <http://app.archipelproject.org>
* Mailing list : <http://groups.google.com/group/archipelproject>
* IRC : <irc://irc.freenode.net/#archipel>
* Sources : <https://github.com/archipelproject/archipel>
* Wiki : <https://github.com/archipelproject/archipel/wiki>
* Bugtracker : <https://github.com/archipelproject/archipel/issues>
* FAQ : <https://github.com/archipelproject/Archipel/wiki/Faq>


# Requirements

You need an OS with nested virtualization support in order to start VMs inside virtual hypervisors. Ubuntu 12.04LTS and Fedora 18 support this by default.

You need a PXE-boot image of ANSOS. It consists of 2 files, namely the kernel (vmlinuz) and a large initrd (initrd0.img) which contains the ISO file in it. This can be downloaded from the website (soon) or generated using Red Hat's livecd-iso-to-pxeboot utility.

# Preparing your test environment

As root, do :
cd ArchipelTest
sh createNestedHyps.sh

This will:
* create a full stateless environment
* create and start 2 instances of ANSOS
* mount your current Archipel workspace in these 2 instances
* perform developer installation
* start Archipel from your working directory.

This way, your current code is deployed in all nested hypervisors.

# Run the tests

sh ArchipelTest/archipelTest.sh

This will:
* flush your ejabberd database (be warned!)
* install the necessary archipel pubsubs
* start archipel in the nested hypervisors
* perform tests, starting from a clean environment


## Advanced users

The buildAgent script has several other options that can be usefull.

### Generate EGGS packages

# Team

* Antoine Mercadal : Lead developer
* Nicolas Ochem
