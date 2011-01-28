from setuptools import setup, find_packages
import sys, os

version = '1.0beta'

setup(name='Archipel',
      version=version,
      description="The hypervisor's agent part of Archipel",
      long_description="""\
This package contains the agent you need to install on your hypervisor in order to use them with Archipel""",
      classifiers=[], # Get strings from http://pypi.python.org/pypi?%3Aaction=list_classifiers
      keywords='archipel, virtualization, libvirt, orchestration',
      author='Antoine Mercadal',
      author_email='primalmotion@archipelproject.org',
      url='http://archipelproject.org',
      license='AGPLv3',
      packages=find_packages(exclude=['ez_setup', 'examples', 'tests']),
      include_package_data=True,
      zip_safe=False,
      install_requires=[
        "xmpppy>= 0.5.0rc1",
        "sqlobject>=0.14.1",
        "apscheduler>=1.3.1"
      ],
      entry_points="""
      # -*- Entry points: -*-
      """,
      exclude_package_data = {"": ["data"]},
      scripts = [
        'data/bin/arch-importvirtualmachine',
        'data/bin/arch-rolesnode',
        'data/bin/arch-tagnode',
        'data/bin/arch-updatedomain',
        'data/bin/runarchipel',
        ]
      )


os.system("./data/configure.py")
