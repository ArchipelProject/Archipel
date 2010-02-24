#!/usr/bin/python
import os, sys, commands, shutil;

config = "Debug"

modules_paths = ["./Modules.src/HypervisorSummary", "./Modules.src/VirtualMachineControls",
                    "./Modules.src/VirtualMachineVNC"];

if "modules" in sys.argv:
    build_paths = modules_paths
else:
    build_paths = modules_paths.append(".");

base_path = commands.getoutput("pwd");
print "# base path is " + base_path;

for path in build_paths:
    print "# moving to " + path;
    os.chdir(path);
    shutil.rmtree("./Build", ignore_errors=True);
    os.system("export CONFIG="+config+";jake");
    print "# get back to " + base_path;
    os.chdir(base_path);


if os.path.isdir("./Build/"+config+"/Archipel/"):
    os.chdir("./Build/"+config+"/Archipel/")
    os.system("ln -s ../../../Modules Modules");
