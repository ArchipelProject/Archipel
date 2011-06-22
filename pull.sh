#!/bin/bash

echo " * updating all submodules"
git submodule update
git submodule foreach git submodule update
echo " * DONE"
