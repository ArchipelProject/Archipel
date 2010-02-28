#!/usr/bin/python
import os, sys, commands, shutil;

config = "Release"



modules_base_paths = "./Modules.src/"
#modules_paths = [modules_base_paths + "UserChat"];
modules_paths = [];

for folder in os.listdir(modules_base_paths):
    if os.path.isdir(modules_base_paths + folder):
        modules_paths.append(modules_base_paths + folder)

if "modules" in sys.argv:
    build_paths = modules_paths
else:
    modules_paths.append(".")
    build_paths = modules_paths;

base_path = commands.getoutput("pwd");
print "# base path is " + base_path;

for path in build_paths:
    print "# moving to " + path;
    os.chdir(path);
    
    if not "keep" in sys.argv:
        print "# removing " + path + "/Build/"
        shutil.rmtree("./Build/", ignore_errors=True);
    
    if not "clean" in sys.argv:
        print "# jaking...";
        os.system("export CONFIG="+config+";jake");
    
        if path != ".":
            print "# linking module";
            os.chdir(base_path + "/Modules")
            os.system("rm -f " +  path.split("/")[-1]);
            os.system("ln -s ../" + path + "/Build/" + config + "/" + path.split("/")[-1] + " ./" + path.split("/")[-1]);
    
    print "# get back to " + base_path;
    os.chdir(base_path);



if os.path.isdir("./Build/"+config+"/Archipel/"):
    print "# linking main module directory to the main Build"
    os.chdir("./Build/"+config+"/Archipel/")
    os.system("ln -s ../../../Modules Modules");

    