#!/bin/bash
set -x

# PART 1 : Sanity
# check that ANSOS iso is present
# check that ejabberd is present

# PART 2 : initial
# we start from a clean archipel installation
service ejabberd stop
ejabberdctl status
rm -vf vm/central_db.sqlite3
rm -vrf stateless/lib/*
rm -vrf stateless/qemu/*/*.xml
rm -vrf stateless/logs/*

# reset ejabberd fully
# TODO fetch ejabberd configuration from the docu wiki

rm -rvf /var/lib/ejabberd/*
service ejabberd start
sleep 5
ejabberdctl status

ejabberdctl register admin archipel-test.archipel.priv admin
python ../ArchipelAgent/buildAgent -d

# create archipel pubsubs
archipel-centralagentnode -j admin@archipel-test.archipel.priv -p admin -c
archipel-adminaccounts -j admin@archipel-test.archipel.priv -p admin -c
archipel-tagnode -j admin@archipel-test.archipel.priv -p admin -c
archipel-rolesnode -j admin@archipel-test.archipel.priv -p admin -c

ejabberdctl register professeur archipel-test.archipel.priv professeur
#ejabberdctl add_rosteritem admin archipel-test.archipel.priv professeur archipel-test.archipel.priv professeur general both
#ejabberdctl add_rosteritem professeur archipel-test.archipel.priv admin archipel-test.archipel.priv admin general both
archipel-adminaccounts -j admin@archipel-test.archipel.priv -p admin -a professeur@archipel-test.archipel.priv

#/etc/init.d/archipel start


# start python tests
python archipelTest.py
