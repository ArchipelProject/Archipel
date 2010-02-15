@STATIC;1.0;p;15;Configuration.jI;25;Foundation/CPDictionary.jI;21;Foundation/CPString.jI;21;Foundation/CPObject.jc;4157;
var _1=require("file"),_2=require("system"),_3=require("objective-j/plist");
var _4=nil,_5=nil,_6=nil;
var _7=objj_allocateClassPair(CPObject,"Configuration"),_8=_7.isa;
class_addIvars(_7,[new objj_ivar("path"),new objj_ivar("dictionary"),new objj_ivar("temporaryDictionary")]);
objj_registerClassPair(_7);
objj_addClassForBundle(_7,objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));
class_addMethods(_7,[new objj_method(sel_getUid("initWithPath:"),function(_9,_a,_b){
with(_9){
_9=objj_msgSendSuper({receiver:_9,super_class:objj_getClass("CPObject")},"init");
if(_9){
path=_b;
temporaryDictionary=objj_msgSend(CPDictionary,"dictionary");
if(path&&_1.isReadable(path)){
dictionary=_3.readPlist(path);
}
if(!dictionary){
dictionary=objj_msgSend(CPDictionary,"dictionary");
}
}
return _9;
}
}),new objj_method(sel_getUid("path"),function(_c,_d){
with(_c){
return path;
}
}),new objj_method(sel_getUid("storedKeyEnumerator"),function(_e,_f){
with(_e){
return objj_msgSend(dictionary,"keyEnumerator");
}
}),new objj_method(sel_getUid("keyEnumerator"),function(_10,_11){
with(_10){
var set=objj_msgSend(CPSet,"setWithArray:",objj_msgSend(dictionary,"allKeys"));
objj_msgSend(set,"addObjectsFromArray:",objj_msgSend(temporaryDictionary,"allKeys"));
objj_msgSend(set,"addObjectsFromArray:",objj_msgSend(_4,"allKeys"));
return objj_msgSend(set,"objectEnumerator");
}
}),new objj_method(sel_getUid("valueForKey:"),function(_12,_13,_14){
with(_12){
var _15=objj_msgSend(dictionary,"objectForKey:",_14);
if(!_15){
_15=objj_msgSend(temporaryDictionary,"objectForKey:",_14);
}
if(!_15){
_15=objj_msgSend(_4,"objectForKey:",_14);
}
return _15;
}
}),new objj_method(sel_getUid("setValue:forKey:"),function(_16,_17,_18,_19){
with(_16){
objj_msgSend(dictionary,"setObject:forKey:",_18,_19);
}
}),new objj_method(sel_getUid("setTemporaryValue:forKey:"),function(_1a,_1b,_1c,_1d){
with(_1a){
objj_msgSend(temporaryDictionary,"setObject:forKey:",_1c,_1d);
}
}),new objj_method(sel_getUid("save"),function(_1e,_1f){
with(_1e){
if(!objj_msgSend(_1e,"path")){
return;
}
_3.writePlist(objj_msgSend(_1e,"path"),dictionary);
}
})]);
class_addMethods(_8,[new objj_method(sel_getUid("initialize"),function(_20,_21){
with(_20){
if(_20!==objj_msgSend(Configuration,"class")){
return;
}
_4=objj_msgSend(CPDictionary,"dictionary");
objj_msgSend(_4,"setObject:forKey:","You","user.name");
objj_msgSend(_4,"setObject:forKey:","you@yourcompany.com","user.email");
objj_msgSend(_4,"setObject:forKey:","Your Company","organization.name");
objj_msgSend(_4,"setObject:forKey:","feedback @nospam@ yourcompany.com","organization.email");
objj_msgSend(_4,"setObject:forKey:","http://yourcompany.com","organization.url");
objj_msgSend(_4,"setObject:forKey:","com.yourcompany","organization.identifier");
var _22=new Date(),_23=["January","February","March","April","May","June","July","August","September","October","November","December"];
objj_msgSend(_4,"setObject:forKey:",_22.getFullYear(),"project.year");
objj_msgSend(_4,"setObject:forKey:",_23[_22.getMonth()]+" "+_22.getDate()+", "+_22.getFullYear(),"project.date");
}
}),new objj_method(sel_getUid("defaultConfiguration"),function(_24,_25){
with(_24){
if(!_5){
_5=objj_msgSend(objj_msgSend(_24,"alloc"),"initWithPath:",nil);
}
return _5;
}
}),new objj_method(sel_getUid("userConfiguration"),function(_26,_27){
with(_26){
if(!_6){
_6=objj_msgSend(objj_msgSend(_26,"alloc"),"initWithPath:",_1.join(_2.env["HOME"],".cappconfig"));
}
return _6;
}
})]);
config=function(){
var _28=0,_29=arguments.length,key=NULL,_2a=NULL,_2b=NO,_2c=NO;
for(;_28<_29;++_28){
var _2d=arguments[_28];
switch(_2d){
case "--get":
_2b=YES;
break;
case "-l":
case "--list":
_2c=YES;
break;
default:
if(key===NULL){
key=_2d;
}else{
_2a=_2d;
}
}
}
var _2e=objj_msgSend(Configuration,"userConfiguration");
if(_2c){
var key=nil,_2f=objj_msgSend(_2e,"storedKeyEnumerator");
while(key=objj_msgSend(_2f,"nextObject")){
print(key+"="+objj_msgSend(_2e,"valueForKey:",key));
}
}else{
if(_2b){
var _2a=objj_msgSend(_2e,"valueForKey:",key);
if(_2a){
print(_2a);
}
}else{
if(key!==NULL&&_2a!==NULL){
objj_msgSend(_2e,"setValue:forKey:",_2a,key);
objj_msgSend(_2e,"save");
}
}
}
};
p;10;Generate.ji;15;Configuration.jc;4403;
var OS=require("os"),_1=require("system"),_2=require("file"),_3=require("objective-j");
var _4=require("packages").catalog["cappuccino"].directory;
gen=function(){
var _5=0,_6=arguments.length,_7=false,_8=false,_9=false,_a=false,_b="Application",_c="";
for(;_5<_6;++_5){
var _d=arguments[_5];
switch(_d){
case "-l":
_7=true;
break;
case "-t":
case "--template":
_b=arguments[++_5];
break;
case "-f":
case "--frameworks":
_8=true;
break;
case "--noconfig":
_9=true;
break;
case "--force":
_a=true;
break;
default:
_c=_d;
}
}
if(_c.length===0){
_c=_8?".":"Untitled";
}
var _e=null;
if(_2.isAbsolute(_b)){
_e=_2.join(_b);
}else{
_e=_2.join(_4,"lib","capp","Resources","Templates",_b);
}
var _f=_2.join(_e,"template.config"),_10={};
if(_2.isFile(_f)){
_10=JSON.parse(_2.read(_f,{charset:"UTF-8"}));
}
var _11=_c,_12=_9?objj_msgSend(Configuration,"defaultConfiguration"):objj_msgSend(Configuration,"userConfiguration");
if(_8){
createFrameworksInFile(_11,_7,_a);
}else{
if(!_2.exists(_11)){
_2.copyTree(_e,_11);
var _13=_2.glob(_2.join(_11,"**","*")),_5=0,_6=_13.length,_14=_2.basename(_11),_15=objj_msgSend(_12,"valueForKey:","organization.identifier")||"";
objj_msgSend(_12,"setTemporaryValue:forKey:",_14,"project.name");
objj_msgSend(_12,"setTemporaryValue:forKey:",_15+"."+toIdentifier(_14),"project.identifier");
objj_msgSend(_12,"setTemporaryValue:forKey:",toIdentifier(_14),"project.nameasidentifier");
for(;_5<_6;++_5){
var _16=_13[_5];
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
var _17=_2.read(_16,{charset:"UTF-8"}),key=nil,_18=objj_msgSend(_12,"keyEnumerator");
while(key=objj_msgSend(_18,"nextObject")){
_17=_17.replace(new RegExp("__"+RegExp.escape(key)+"__","g"),objj_msgSend(_12,"valueForKey:",key));
}
_2.write(_16,_17,{charset:"UTF-8"});
}
catch(anException){
print("Copying and modifying "+_16+" failed.");
}
}
var _19=_11;
if(_10.FrameworksPath){
_19=_2.join(_19,_10.FrameworksPath);
}
createFrameworksInFile(_19,_7);
}else{
print("Directory already exists");
}
}
};
createFrameworksInFile=function(_1a,_1b,_1c){
var _1d=_2.path(_2.absolute(_1a));
var _1e=["Foundation","AppKit"];
if(!_1d.isDirectory()){
throw new Error("Can't create Frameworks. Directory does not exist: "+_1d);
}
var _1f=_1d.join("Frameworks"),_20=_1d.join("Frameworks","Debug");
print("Creating Frameworks directory in "+_1f+".");
_20.mkdirs();
if(_1b){
if(!(_1.env["CAPP_BUILD"]||_1.env["STEAM_BUILD"])){
throw "CAPP_BUILD or STEAM_BUILD must be defined";
}
var _21=_2.path(_1.env["CAPP_BUILD"]||_1.env["STEAM_BUILD"]);
var _22=_21.join("Release"),_23=_21.join("Debug");
_1e.concat("Objective-J").forEach(function(_24){
installFramework(_22.join(_24),_1f.join(_24),_1c,true);
installFramework(_23.join(_24),_20.join(_24),_1c,true);
});
}else{
var _25=_2.path(_3.OBJJ_HOME);
var _26=_25.join("Frameworks","Objective-J");
var _27=_25.join("Frameworks","Debug","Objective-J");
installFramework(_26,_1f.join("Objective-J"),_1c,false);
installFramework(_27,_20.join("Objective-J"),_1c,false);
_1e.forEach(function(_28){
var _29;
for(var i=0,_29=false;!_29&&i<_3.objj_frameworks.length;i++){
var _2a=_2.path(_3.objj_frameworks[i]).join(_28);
if(_2.isDirectory(_2a)){
installFramework(_2a,_1f.join(_28),_1c,false);
_29=true;
}
}
if(!_29){
print("Warning: Couldn't find framework \""+_28+"\"");
}
for(var i=0,_29=false;!_29&&i<_3.objj_debug_frameworks.length;i++){
var _2b=_2.path(_3.objj_debug_frameworks[i]).join(_28);
if(_2.isDirectory(_2b)){
installFramework(_2b,_20.join(_28),_1c,false);
_29=true;
}
}
if(!_29){
print("Warning: Couldn't find debug framework \""+_28+"\"");
}
});
}
};
installFramework=function(_2c,_2d,_2e,_2f){
if(_2d.exists()){
if(_2e){
_2d.rmtree();
}else{
print("Warning: "+_2d+" already exists. Use --force to overwrite.");
return;
}
}
if(_2c.exists()){
print((_2f?"Symlinking ":"Copying ")+_2c+" to "+_2d);
if(_2f){
_2.symlink(_2c,_2d);
}else{
_2.copyTree(_2c,_2d);
}
}else{
print("Warning: "+_2c+" doesn't exist.");
}
};
toIdentifier=function(_30){
var _31="",_32=0,_33=_30.length,_34=NO,_35=new RegExp("^[a-zA-Z_$]"),_36=new RegExp("^[a-zA-Z_$0-9]");
for(;_32<_33;++_32){
var _37=_30.charAt(_32);
if((_32===0)&&_35.test(_37)||_36.test(_37)){
if(_34){
_31+=_37.toUpperCase();
}else{
_31+=_37;
}
_34=NO;
}else{
_34=YES;
}
}
return _31;
};
p;6;main.jI;23;Foundation/Foundation.ji;15;Configuration.ji;10;Generate.jc;1887;
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
print(ANSITextApplyProperties("    gen",ANSI_BOLD)+" PATH          Generate new project at PATH from a predefined template");
print("    -l                Symlink the Frameworks folder to your $CAPP_BUILD or $STEAM_BUILD directory");
print("    -t, --template    Specify the template name to use (listed in capp/Resources/Templates)");
print("    -f, --frameworks  Create only frameworks, not a full application");
print("    --force           Overwrite Frameworks directory if it already exists");
print("");
print(ANSITextApplyProperties("    config ",ANSI_BOLD));
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