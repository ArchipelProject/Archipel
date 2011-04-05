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

from setuptools import setup, find_packages

VERSION             = '0.2.0'
AUTHOR              = 'Antoine Mercadal'
MAIL                = 'antoine.mercadal@archipelproject.org'
URL                 = 'http://archipelproject.org'
LICENSE             = 'AGPL'
NAME                = 'archipel-agent-vmcasting'
SHORTDESCRIPTION    = "Manage all stuff about vmcasting"
LONGDESCRIPTION     = ""
ENTRY_POINTS        = { 'archipel.plugin.hypervisor' : [
                            'factory=archipelagentvmcasting:make_archipel_plugin'],
                        'archipel.plugin.virtualmachine': [
                            'factory=archipelagentvmcasting:make_archipel_plugin'],
                        'archipel.plugin' : [
                            'version=archipelagentvmcasting:version']}

setup(name=NAME,
      version=VERSION,
      description=SHORTDESCRIPTION,
      long_description=LONGDESCRIPTION,
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
      author=AUTHOR,
      author_email=MAIL,
      url=URL,
      license=LICENSE,
      packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
      include_package_data=True,
      zip_safe=False,
      install_requires=[
        "archipel-agent"
      ],
      entry_points=ENTRY_POINTS
      )