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

import os, shutil
from setuptools import setup, find_packages

VERSION             = '1.0.13'
DESCRIPTION="""\
** Archipel Agent **

Copyright (c) 2011 Antoine Mercadal

This package contains the agent you need to install on your hypervisor 
in order to use them with Archipel. You need a running XMPP agent in 
order to use Archipel and a recent version of Libvirt.

For more information, please go to http://archipelproject.org
"""

def create_avatar_list(folder):
    ret = []
    for avatar in os.listdir(folder):
        ret.append("%s%s" % (folder, avatar))
    return ret

setup(name='archipel-agent',
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
        'License :: OSI Approved :: GNU Affero General Public License v3',
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
      zip_safe=False,
      provides=["archipel"],
      install_requires=[
        "xmpppy>=0.5.0rc1",
        "sqlobject>=0.14.1",
        "archipel-agent-action-scheduler>=1.0.12",
        "archipel-agent-hypervisor-geolocalization>=1.0.12",
        "archipel-agent-hypervisor-health>=1.0.12",
        "archipel-agent-hypervisor-network>=1.0.12",
        "archipel-agent-iphone-notification>=1.0.12",
        "archipel-agent-virtualmachine-oomkiller>=1.0.12",
        "archipel-agent-virtualmachine-snapshoting>=1.0.12",
        "archipel-agent-virtualmachine-storage>=1.0.12",
        "archipel-agent-vmcasting>=1.0.12",
        "archipel-agent-xmppserver>=1.0.13"
      ],
      entry_points="""
        # -*- Entry points: -*-
        """,
      scripts = [
        'install/bin/archipel-importvirtualmachine',
        'install/bin/archipel-rolesnode',
        'install/bin/archipel-tagnode',
        'install/bin/archipel-updatedomain',
        'install/bin/archipel-initinstall',
        'install/bin/runarchipel'
        ],
      data_files=[
        ('system/var/lib/archipel/avatars', create_avatar_list("install/var/lib/archipel/avatars/")),
        ('system/var/lib/archipel/'       , ['install/var/lib/archipel/names.txt']),
        ('system/etc/init.d'              , ['install/etc/init.d/archipel']),
        ('system/etc/archipel/'           , ['install/etc/archipel/archipel.conf', 'install/etc/archipel/vnc.pem'])
        ]
      )
