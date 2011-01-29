# 
# setup.py
# 
# Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import os
from setuptools import setup, find_packages
from distutils.core import Command
import sys, os


VERSION = "1.0beta"
PREFIX= ""
DESCRIPTION="""\
** Archipel Server **

Copyright (c) 2011 Antoine Mercadal

This package contains the agent you need to install on your hypervisor 
in order to use them with Archipel. You need a running XMPP server in 
order to use Archipel and a recent version of Libvirt.

For more information, please go to http://archipelproject.org
"""

WORKINGFOLDERS  = { "drives"    : "%s/vm/drives"  % PREFIX, 
                    "iso"       : "%s/vm/iso"     % PREFIX, 
                    "repo"      : "%s/vm/repo"    % PREFIX, 
                    "tmp"       : "%s/vm/tmp"     % PREFIX, 
                    "vmcasts"   : "%s/vm/vmcasts" % PREFIX}



def create_avatar_list(folder):
    ret = []
    for avatar in os.listdir(folder):
        ret.append("%s%s" % (folder, avatar))
    return ret    


setup(name='archipel-server',
      version=VERSION,
      description="The hypervisor's agent part of Archipel",
      long_description=DESCRIPTION,
      classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Environment :: No Input/Output (Daemon)',
        'Intended Audience :: Developers',
        'Intended Audience :: Education',
        'Intended Audience :: End Users/Desktop',
        'Intended Audience :: Science/Research',
        'Intended Audience :: System Administrators',
        'Intended Audience :: Telecommunications Industry',
        'License :: OSI Approved :: GNU Affero General Public License v',
        'Operating System :: POSIX :: Linux',
        'Programming Language :: Python',
        'Topic :: Internet',
        'Topic :: System :: Emulators',
        'Topic :: System :: Operating System'],
      keywords='archipel, virtualization, libvirt, orchestration',
      author='Antoine Mercadal',
      author_email='primalmotion@archipelproject.org',
      url='http://archipelproject.org',
      license='AGPLv3',
      packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
      include_package_data=True,
      include_empty_folders=True,
      zip_safe=False,
      provides=["archipel"],
      install_requires=[
        "xmpppy>=0.5.0rc1",
        "sqlobject>=0.14.1",
        "apscheduler>=1.3.1"
      ],
      entry_points="""
      # -*- Entry points: -*-
      """,
      scripts = [
        'install/bin/arch-importvirtualmachine',
        'install/bin/arch-rolesnode',
        'install/bin/arch-tagnode',
        'install/bin/arch-updatedomain',
        'install/bin/runarchipel',
        ],
      data_files=[
        ('%s/var/lib/archipel/avatars'  % PREFIX, create_avatar_list("install/var/lib/archipel/avatars/")),
        ('%s/var/lib/archipel/'         % PREFIX, ['install/var/lib/archipel/names.txt']),
        ('%s/etc/init.d'                % PREFIX, ['install/etc/init.d/archipel']),
        ('%s/etc/archipel/'             % PREFIX, ['install/etc/archipel/archipel.conf', 'install/etc/archipel/vnc.pem'])
        ]
      )
