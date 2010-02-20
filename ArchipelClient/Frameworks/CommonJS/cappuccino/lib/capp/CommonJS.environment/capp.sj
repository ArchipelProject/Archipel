@STATIC;1.0;p;15;Configuration.jt;4345;@STATIC;1.0;I;25;Foundation/CPDictionary.jI;21;Foundation/CPString.jI;21;Foundation/CPObject.jt;4244;
objj_executeFile("Foundation/CPDictionary.j",false);
objj_executeFile("Foundation/CPString.j",false);
objj_executeFile("Foundation/CPObject.j",false);
var _1=require("file"),_2=require("system");
var _3=nil,_4=nil,_5=nil;
var _6=objj_allocateClassPair(CPObject,"Configuration"),_7=_6.isa;
class_addIvars(_6,[new objj_ivar("path"),new objj_ivar("dictionary"),new objj_ivar("temporaryDictionary")]);
objj_registerClassPair(_6);
class_addMethods(_6,[new objj_method(sel_getUid("initWithPath:"),function(_8,_9,_a){
with(_8){
_8=objj_msgSendSuper({receiver:_8,super_class:objj_getClass("Configuration").super_class},"init");
if(_8){
path=_a;
temporaryDictionary=objj_msgSend(CPDictionary,"dictionary");
if(path&&_1.isReadable(path)){
dictionary=CFPropertyList.readPropertyListFromFile(path);
}
if(!dictionary){
dictionary=objj_msgSend(CPDictionary,"dictionary");
}
}
return _8;
}
}),new objj_method(sel_getUid("path"),function(_b,_c){
with(_b){
return path;
}
}),new objj_method(sel_getUid("storedKeyEnumerator"),function(_d,_e){
with(_d){
return objj_msgSend(dictionary,"keyEnumerator");
}
}),new objj_method(sel_getUid("keyEnumerator"),function(_f,_10){
with(_f){
var set=objj_msgSend(CPSet,"setWithArray:",objj_msgSend(dictionary,"allKeys"));
objj_msgSend(set,"addObjectsFromArray:",objj_msgSend(temporaryDictionary,"allKeys"));
objj_msgSend(set,"addObjectsFromArray:",objj_msgSend(_3,"allKeys"));
return objj_msgSend(set,"objectEnumerator");
}
}),new objj_method(sel_getUid("valueForKey:"),function(_11,_12,_13){
with(_11){
var _14=objj_msgSend(dictionary,"objectForKey:",_13);
if(!_14){
_14=objj_msgSend(temporaryDictionary,"objectForKey:",_13);
}
if(!_14){
_14=objj_msgSend(_3,"objectForKey:",_13);
}
return _14;
}
}),new objj_method(sel_getUid("setValue:forKey:"),function(_15,_16,_17,_18){
with(_15){
objj_msgSend(dictionary,"setObject:forKey:",_17,_18);
}
}),new objj_method(sel_getUid("setTemporaryValue:forKey:"),function(_19,_1a,_1b,_1c){
with(_19){
objj_msgSend(temporaryDictionary,"setObject:forKey:",_1b,_1c);
}
}),new objj_method(sel_getUid("save"),function(_1d,_1e){
with(_1d){
if(!objj_msgSend(_1d,"path")){
return;
}
plist.writePlist(objj_msgSend(_1d,"path"),dictionary);
}
})]);
class_addMethods(_7,[new objj_method(sel_getUid("initialize"),function(_1f,_20){
with(_1f){
if(_1f!==objj_msgSend(Configuration,"class")){
return;
}
_3=objj_msgSend(CPDictionary,"dictionary");
objj_msgSend(_3,"setObject:forKey:","You","user.name");
objj_msgSend(_3,"setObject:forKey:","you@yourcompany.com","user.email");
objj_msgSend(_3,"setObject:forKey:","Your Company","organization.name");
objj_msgSend(_3,"setObject:forKey:","feedback @nospam@ yourcompany.com","organization.email");
objj_msgSend(_3,"setObject:forKey:","http://yourcompany.com","organization.url");
objj_msgSend(_3,"setObject:forKey:","com.yourcompany","organization.identifier");
var _21=new Date(),_22=["January","February","March","April","May","June","July","August","September","October","November","December"];
objj_msgSend(_3,"setObject:forKey:",_21.getFullYear(),"project.year");
objj_msgSend(_3,"setObject:forKey:",_22[_21.getMonth()]+" "+_21.getDate()+", "+_21.getFullYear(),"project.date");
}
}),new objj_method(sel_getUid("defaultConfiguration"),function(_23,_24){
with(_23){
if(!_4){
_4=objj_msgSend(objj_msgSend(_23,"alloc"),"initWithPath:",nil);
}
return _4;
}
}),new objj_method(sel_getUid("userConfiguration"),function(_25,_26){
with(_25){
if(!_5){
_5=objj_msgSend(objj_msgSend(_25,"alloc"),"initWithPath:",_1.join(_2.env["HOME"],".cappconfig"));
}
return _5;
}
})]);
config=function(){
var _27=0,_28=arguments.length,key=NULL,_29=NULL,_2a=NO,_2b=NO;
for(;_27<_28;++_27){
var _2c=arguments[_27];
switch(_2c){
case "--get":
_2a=YES;
break;
case "-l":
case "--list":
_2b=YES;
break;
default:
if(key===NULL){
key=_2c;
}else{
_29=_2c;
}
}
}
var _2d=objj_msgSend(Configuration,"userConfiguration");
if(_2b){
var key=nil,_2e=objj_msgSend(_2d,"storedKeyEnumerator");
while(key=objj_msgSend(_2e,"nextObject")){
print(key+"="+objj_msgSend(_2d,"valueForKey:",key));
}
}else{
if(_2a){
var _29=objj_msgSend(_2d,"valueForKey:",key);
if(_29){
print(_29);
}
}else{
if(key!==NULL&&_29!==NULL){
objj_msgSend(_2d,"setValue:forKey:",_29,key);
objj_msgSend(_2d,"save");
}
}
}
};
p;10;Generate.jt;6512;@STATIC;1.0;i;15;Configuration.jt;6473;
objj_executeFile("Configuration.j",true);
var OS=require("os"),_1=require("system"),_2=require("file"),_3=require("objective-j");
var _4=require("term").stream;
var _5=new (require("args").Parser)();
_5.usage("DESTINATION_DIRECTORY");
_5.help("Generate a Cappuccino project or Frameworks directory");
_5.option("-t","--template","template").set().def("Application").help("Selects a project template to use (default: Application).");
_5.option("-f","--frameworks","justFrameworks").set(true).help("Only generate or update Frameworks directory.");
_5.option("-F","--framework","framework","frameworks").def([]).push().help("Additional framework to copy/symlink (default: Objective-J, Foundation, AppKit)");
_5.option("--no-frameworks","noFrameworks").set(true).help("Don't copy any default frameworks (can be overridden with -F)");
_5.option("--symlink","symlink").set(true).help("Creates a symlink to each framework instead of copying.");
_5.option("--build","useCappBuild").set(true).help("Uses frameworks in the $CAPP_BUILD.");
_5.option("-l").action(function(o){
o.symlink=o.shouldUseCappBuild=true;
}).help("Enables both the --symlink and --build options.");
_5.option("--force","force").set(true).help("Overwrite update existing frameworks.");
_5.option("--noconfig","noconfig").set().help("Selects a project template to use.");
_5.option("--list-templates","listTemplates").set(true).help("Lists available templates.");
_5.option("--list-frameworks","listFrameworks").set(true).help("Lists available frameworks.");
_5.helpful();
var _6=require("packages").catalog["cappuccino"].directory;
var _7=_2.join(_6,"lib","capp","Resources","Templates");
gen=function(){
var _8=["capp gen"].concat(Array.prototype.slice.call(arguments));
var _9=_5.parse(_8);
if(_9.listTemplates){
listTemplates();
return;
}
if(_9.listFrameworks){
listFrameworks();
return;
}
var _a=_9.args[0];
if(!_a){
if(_9.justFrameworks){
_a=".";
}else{
_5.printUsage(_9);
OS.exit(1);
}
}
var _b=null;
if(_2.isAbsolute(_9.template)){
_b=_2.join(_9.template);
}else{
_b=_2.join(_7,_9.template);
}
var _c=_2.join(_b,"template.config"),_d={};
if(_2.isFile(_c)){
_d=JSON.parse(_2.read(_c,{charset:"UTF-8"}));
}
var _e=_a,_f=_9.noconfig?objj_msgSend(Configuration,"defaultConfiguration"):objj_msgSend(Configuration,"userConfiguration");
var _10=_9.frameworks;
if(!_9.noFrameworks){
_10.push("Objective-J","Foundation","AppKit");
}
if(_9.justFrameworks){
createFrameworksInFile(_10,_e,_9.symlink,_9.useCappBuild,_9.force);
}else{
if(!_2.exists(_e)){
_2.copyTree(_b,_e);
var _11=_2.glob(_2.join(_e,"**","*")),_12=0,_13=_11.length,_14=_2.basename(_e),_15=objj_msgSend(_f,"valueForKey:","organization.identifier")||"";
objj_msgSend(_f,"setTemporaryValue:forKey:",_14,"project.name");
objj_msgSend(_f,"setTemporaryValue:forKey:",_15+"."+toIdentifier(_14),"project.identifier");
objj_msgSend(_f,"setTemporaryValue:forKey:",toIdentifier(_14),"project.nameasidentifier");
for(;_12<_13;++_12){
var _16=_11[_12];
if(_2.isDirectory(_16)){
continue;
}
if(_2.basename(_16)===".DS_Store"){
continue;
}
if([".png",".jpg",".jpeg",".gif",".tif",".tiff"].indexOf(_2.extension(_16).toLowerCase())!==-1){
continue;
}
try{
var _17=_2.read(_16,{charset:"UTF-8"}),key=nil,_18=objj_msgSend(_f,"keyEnumerator");
while(key=objj_msgSend(_18,"nextObject")){
_17=_17.replace(new RegExp("__"+RegExp.escape(key)+"__","g"),objj_msgSend(_f,"valueForKey:",key));
}
_2.write(_16,_17,{charset:"UTF-8"});
}
catch(anException){
_4.print("Copying and modifying "+_16+" failed.");
}
}
var _19=_e;
if(_d.FrameworksPath){
_19=_2.join(_19,_d.FrameworksPath);
}
createFrameworksInFile(_10,_19,_9.symlink,_9.useCappBuild);
}else{
_4.print("Directory already exists");
}
}
};
createFrameworksInFile=function(_1a,_1b,_1c,_1d,_1e){
var _1f=_2.path(_2.absolute(_1b));
if(!_1f.isDirectory()){
throw new Error("Can't create Frameworks. Directory does not exist: "+_1f);
}
var _20=_1f.join("Frameworks"),_21=_1f.join("Frameworks","Debug");
_4.print("Creating Frameworks directory in "+_20+".");
_21.mkdirs();
if(_1d){
if(!(_1.env["CAPP_BUILD"]||_1.env["STEAM_BUILD"])){
throw "CAPP_BUILD or STEAM_BUILD must be defined";
}
var _22=_2.path(_1.env["CAPP_BUILD"]||_1.env["STEAM_BUILD"]);
var _23=_22.join("Release"),_24=_22.join("Debug");
_1a.forEach(function(_25){
installFramework(_23.join(_25),_20.join(_25),_1e,_1c);
installFramework(_24.join(_25),_21.join(_25),_1e,_1c);
});
}else{
_1a.forEach(function(_26){
if(_26==="Objective-J"){
var _27=_2.path(_3.OBJJ_HOME);
var _28=_27.join("Frameworks","Objective-J");
var _29=_27.join("Frameworks","Debug","Objective-J");
installFramework(_28,_20.join("Objective-J"),_1e,_1c);
installFramework(_29,_21.join("Objective-J"),_1e,_1c);
return;
}
var _2a;
for(var i=0,_2a=false;!_2a&&i<_3.objj_frameworks.length;i++){
var _2b=_2.path(_3.objj_frameworks[i]).join(_26);
if(_2.isDirectory(_2b)){
installFramework(_2b,_20.join(_26),_1e,_1c);
_2a=true;
}
}
if(!_2a){
_4.print("\x00yellow(Warning:\x00) Couldn't find framework \x00cyan("+_26+"\x00)");
}
for(var i=0,_2a=false;!_2a&&i<_3.objj_debug_frameworks.length;i++){
var _2c=_2.path(_3.objj_debug_frameworks[i]).join(_26);
if(_2.isDirectory(_2c)){
installFramework(_2c,_21.join(_26),_1e,_1c);
_2a=true;
}
}
if(!_2a){
_4.print("\x00yellow(Warning:\x00) Couldn't find debug framework \x00cyan("+_26+"\x00)");
}
});
}
};
installFramework=function(_2d,_2e,_2f,_30){
if(_2e.exists()){
if(_2f){
_2e.rmtree();
}else{
_4.print("\x00yellow(Warning:\x00) "+_2e+" already exists. Use --force to overwrite.");
return;
}
}
if(_2d.exists()){
_4.print((_30?"Symlinking ":"Copying ")+_2d+" to "+_2e);
if(_30){
_2.symlink(_2d,_2e);
}else{
_2.copyTree(_2d,_2e);
}
}else{
_4.print("\x00yellow(Warning:\x00) "+_2d+" doesn't exist.");
}
};
toIdentifier=function(_31){
var _32="",_33=0,_34=_31.length,_35=NO,_36=new RegExp("^[a-zA-Z_$]"),_37=new RegExp("^[a-zA-Z_$0-9]");
for(;_33<_34;++_33){
var _38=_31.charAt(_33);
if((_33===0)&&_36.test(_38)||_37.test(_38)){
if(_35){
_32+=_38.toUpperCase();
}else{
_32+=_38;
}
_35=NO;
}else{
_35=YES;
}
}
return _32;
};
listTemplates=function(){
_2.list(_7).forEach(function(_39){
_4.print(_39);
});
};
listFrameworks=function(){
_4.print("Frameworks:");
_3.objj_frameworks.forEach(function(_3a){
_4.print("  "+_3a);
_2.list(_3a).forEach(function(_3b){
_4.print("    + "+_3b);
});
});
_4.print("Frameworks (Debug):");
_3.objj_debug_frameworks.forEach(function(_3c){
_4.print("  "+_3c);
_2.list(_3c).forEach(function(_3d){
_4.print("    + "+_3d);
});
});
};
p;6;main.jt;2218;@STATIC;1.0;I;23;Foundation/Foundation.ji;15;Configuration.ji;10;Generate.jt;2136;
objj_executeFile("Foundation/Foundation.j",false);
objj_executeFile("Configuration.j",true);
objj_executeFile("Generate.j",true);
main=function(_1){
_1.shift();
if(_1.length<1){
return printUsage();
}
var _2=0,_3=_1.length;
for(;_2<_3;++_2){
var _4=_1[_2];
switch(_4){
case "version":
case "--version":
return print("capp version 0.7.1");
case "-h":
case "--help":
return printUsage();
case "config":
return config.apply(this,_1.slice(_2+1));
case "gen":
return gen.apply(this,_1.slice(_2+1));
default:
print("unknown command "+_4);
}
}
};
printUsage=function(){
print("capp [--version] COMMAND [ARGS]");
print("    --version         Print version");
print("    -h, --help        Print usage");
print("");
print("    gen PATH          Generate new project at PATH from a predefined template");
print("    -l                Symlink the Frameworks folder to your $CAPP_BUILD or $STEAM_BUILD directory");
print("    -t, --template    Specify the template name to use (listed in capp/Resources/Templates)");
print("    -f, --frameworks  Create only frameworks, not a full application");
print("    --force           Overwrite Frameworks directory if it already exists");
print("    --symlink         Create a symlink to the source Frameworks");
print("    --build           Source the Frameworks directory files from your $CAPP_BUILD or $STEAM_BUILD directory");
print("");
print("    config ");
print("    name value        Set a value for a given key");
print("    -l, --list        List all variables set in config file.");
print("    --get name        Get the value for a given key");
};
getFiles=function(_5,_6,_7){
var _8=[],_9=_5.listFiles(),_a=typeof _6!=="string";
if(_9){
var _b=0,_c=_9.length;
for(;_b<_c;++_b){
var _d=_9[_b],_e=FILE.basename(_d),_f=!_6;
if(_7&&fileArrayContainsFile(_7,_d)){
continue;
}
if(!_f){
if(_a){
var _10=_6.length;
while(_10--&&!_f){
var _11=_6[_10];
if(_e.substring(_e.length-_11.length-1)===("."+_11)){
_f=true;
}
}
}else{
if(_e.substring(_e.length-_6.length-1)===("."+_6)){
_f=true;
}
}
}
if(FILE.isDirectory(_d)){
_8=_8.concat(getFiles(_d,_6,_7));
}else{
if(_f){
_8.push(_d);
}
}
}
}
return _8;
};
e;