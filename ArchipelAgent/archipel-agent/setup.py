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

VERSION             = '0.6.0'

DESCRIPTION="""\
** Archipel Agent **

Copyright (c) 2011 Antoine Mercadal

This package contains the agent you need to install on your hypervisor
in order to use them with Archipel. You need a running XMPP agent in
order to use Archipel and a recent version of Libvirt.

For more information, please go to http://archipelproject.org
"""

#RPM_REQUIRED_DEPS = "archipel-core, python-imaging, libvirt-python"
RPM_REQUIRED_DEPS = "archipel-core, python-imaging, libvirt, libvirt-python"
RPM_POST_INSTALL = "%post\narchipel-initinstall -i\n"

## HACK FOR DEPS IN RPMS
from setuptools.command.bdist_rpm import bdist_rpm
def custom_make_spec_file(self):
    spec = self._original_make_spec_file()
    lineDescription = "%description"
    spec.insert(spec.index(lineDescription) - 1, "requires: %s" % RPM_REQUIRED_DEPS)
    spec.append(RPM_POST_INSTALL)
    return spec
bdist_rpm._original_make_spec_file = bdist_rpm._make_spec_file
bdist_rpm._make_spec_file = custom_make_spec_file
## END OF HACK

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
        "archipel-core>=0.6.0beta",
        "archipel-agent-action-scheduler>=0.6.0beta",
        "archipel-agent-hypervisor-geolocalization>=0.6.0beta",
        "archipel-agent-hypervisor-health>=0.6.0beta",
        "archipel-agent-hypervisor-network>=0.6.0beta",
        "archipel-agent-iphone-notification>=0.6.0beta",
        "archipel-agent-virtualmachine-oomkiller>=0.6.0beta",
        "archipel-agent-virtualmachine-snapshoting>=0.6.0beta",
        "archipel-agent-virtualmachine-storage>=0.6.0beta",
        "archipel-agent-vmcasting>=0.6.0beta",
        "archipel-agent-xmppserver>=0.6.0beta",
        "archipel-agent-virtualmachine-vnc>=0.6.0beta",
        "archipel-agent-vmparking>=0.6.0beta",
        "PIL"
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
        'install/bin/archipel-testxmppserver',
        'install/bin/archipel-commandsbytag',
        'install/bin/archipel-adminaccounts',
        'install/bin/archipel-command',
        'install/bin/runarchipel'
        ],
      data_files=[
        ('install/var/lib/archipel/avatars', create_avatar_list("install/var/lib/archipel/avatars/")),
        ('install/var/lib/archipel/'       , ['install/var/lib/archipel/names.txt']),
        ('install/etc/init.d/'             , ['install/etc/init.d/archipel']),
        ('install/usr/lib/systemd/system/' , ['install/usr/lib/systemd/system/archipel-agent.service']),
        ('install/etc/archipel/'           , ['install/etc/archipel/archipel.conf', 'install/etc/archipel/vnc.pem'])
        ]
      )
