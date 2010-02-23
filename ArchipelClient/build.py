#!/usr/bin/python
import os, sys, commands, shutil;

config = "Debug"
build_paths = [".", "./Modules.src/SampleModule", "./Modules.src/HypervisorSummary"];
copy_paths = ["./Modules/SampleModule", "./Modules/HypervisorSummary"];

base_path = commands.getoutput("pwd");
print "# base path is " + base_path;

for path in build_paths:
    print "# moving to " + path;
    os.chdir(path);
    shutil.rmtree("./Build", ignore_errors=True);
    os.system("export CONFIG="+config+";jake");
    print "# get back to " + base_path;
    os.chdir(base_path);
    

os.chdir("./Build/"+config+"/Archipel/")
os.system("ln -s ../../../Modules Modules");