# What is Archipel Agent ?

Archipel Agent is the small piece of software you need to install on each of your hypervisors.
It will perform bridging between XMPP and Libvirt, and allows to add extensions. It will
create a thread for the hypervisor and each virtual machines you run an the hypervisor.
It it distribute under python setuptools package. You can install it directly from


# Get help

* Website : <http://archipelproject.org>
* Nighty Builds : <http://nightlies.archipelproject.org>
* Test application : <http://app.archipelproject.org>
* Mailing list : <http://groups.google.com/group/archipelproject>
* IRC : <irc://irc.freenode.net/#archipel>
* Sources : <https://github.com/primalmotion/archipel>
* Wiki : <https://github.com/primalmotion/archipel/wiki>
* Bugtracker : <https://github.com/primalmotion/archipel/issues>
* FAQ : <https://github.com/primalmotion/Archipel/wiki/Faq>


# Installation

run :

    # sudo python setup.py install && archipel-initinstall

Then edit the first line of /etc/archipel/archipel.conf to match your ejabberd server.
Finally start it using :
    
    # /etc/init.d/archipel start

You can check the log at /var/log/archipel/archipel.log


# Team

* Antoine Mercadal : Lead developer


# License

Archipel is distributed under AGPL v3. See the LICENSE file