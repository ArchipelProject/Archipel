#!/bin/bash

echo " * updating all submodules"
git submodule update --init
git submodule foreach --recursive git submodule update --init
echo " * DONE"
