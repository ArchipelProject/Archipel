#!/usr/bin/python
import os, sys, commands, shutil;

config = "Release"

really_base_path = commands.getoutput("pwd");
os.system("export PATH=/usr/local/narwhal/bin:$PATH");
base_path =  sys.path[0]
commands.getoutput("cd " + sys.path[0])

modules_base_paths = base_path + "/Modules.src/"
modules_paths = [];

for folder in os.listdir(modules_base_paths):
    if os.path.isdir(modules_base_paths + folder):
        modules_paths.append(modules_base_paths + folder)
    
        
### overide to define only a set of modules;        
#modules_paths = [modules_base_paths + "HypervisorHealth"];

if "modules" in sys.argv:
    build_paths = modules_paths
else:
    modules_paths.append(".")
    build_paths = modules_paths;


print "# base path is " + base_path

os.system("rm -rf " + base_path + "/Modules/*")

for path in build_paths:
    print "# moving to " + path 
    os.chdir(path);
    
    if not "keep" in sys.argv:
        print "# removing " + path + "/Build/"
        shutil.rmtree("./Build/", ignore_errors=True);
    
    if not "clean" in sys.argv:
        print "# jaking..."
        code = os.system("export CONFIG="+config+";jake");
        
        if not code == 0:
            sys.exit(code)

        if path != ".":
            print "# linking module"
            os.chdir(base_path + "/Modules")
            os.system("rm -f " +  path.split("/")[-1]);
            os.system("cp -a ../" + path + "/Build/" + config + "/" + path.split("/")[-1] + " ./" + path.split("/")[-1]);
    
    print "# get back to " + base_path
    os.chdir(base_path);

os.system("cp ./Modules.src/modules.plist ./Modules")

if os.path.isdir("./Build/"+config+"/Archipel/"):
    print "# linking main module directory to the main Build"
    os.chdir("./Build/"+config+"/Archipel/")
    os.system("cp -a ../../../Modules Modules");

os.system("cd " + really_base_path); 

sys.exit(0)