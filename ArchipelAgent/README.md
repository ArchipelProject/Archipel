# What is Archipel Agent ?

Archipel Agent is the small piece of software you need to install on each of your hypervisors.
It will perform bridging between XMPP and Libvirt, and allows to add extensions. It will
create a thread for the hypervisor and each virtual machines you run on the hypervisor.
It it distribute under python setuptools package. See <Installation>.


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

Note that you can install the latest realease of archipel agent directly from pypi, running

    # sudo easy_install archipel-agent && archipel-initinstall

To update:

    # sudo easy_install -U archipel-agent


But if you are a developper, you may want to try your changes. To force
eggs installation from your machine just run

    # sudo ./buildAgent -d

Then edit the first line of /etc/archipel/archipel.conf to match your ejabberd server.
Finally start it using :

    # /etc/init.d/archipel start

You can check the log at /var/log/archipel/archipel.log


# Team

* Antoine Mercadal : Lead developer


# License

Archipel is distributed under AGPL v3. See the LICENSE files in eggs
