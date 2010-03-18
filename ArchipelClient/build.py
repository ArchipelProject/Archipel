#!/usr/bin/python
import os, sys, commands, shutil;

config = "release"
if "debug" in sys.argv:
    config = "debug"

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
#modules_paths = [modules_base_paths + "VirtualMachineDefinition"];

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

    code = 0;
    if not "clean" in sys.argv:
        print "# jaking..."
        code = os.system("export CONFIG="+config+";jake");
        print "# Build result " + str(code)
        
        if not str(code) == "0":
            print "# Error in build : " + str(code)
            sys.exit("error during build")

        if path != ".":
            print "# linking module"
            os.chdir(base_path + "/Modules")
            os.system("rm -f " +  path.split("/")[-1]);
            os.system("cp -a " + path + "/Build/" + config + "/" + path.split("/")[-1] + " ./" + path.split("/")[-1]);
    
    print "# get back to " + base_path
    os.chdir(base_path);

os.system("cp ./Modules.src/modules.plist ./Modules")

build_dir= base_path + "/Build/"+config+"/Archipel/"
if os.path.isdir(build_dir):
    print "# Copying modules to the build " + base_path + " -> " + build_dir
    os.chdir(base_path +"/Build/"+config+"/Archipel/")
    os.system("cp -a "+base_path+"/Modules "+build_dir+"/");


native_app_dir = base_path + "/NativeApplications/MacOS/Archipel.app/Contents/Resources/Objective-J/Client/";

if "native-mac" in sys.argv:
    print "# generation of the native Mac OS Application"
    os.chdir(base_path);
    os.system("cp -a " + build_dir + " " + native_app_dir);
    os.system("cp -a "+ base_path + "/Modules " + native_app_dir + "/");
    
os.system("cd " + really_base_path);
sys.exit(0)