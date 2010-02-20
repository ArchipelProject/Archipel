@STATIC;1.0;p;20;cib-analysis-tools.jt;1634;@STATIC;1.0;I;23;Foundation/Foundation.jI;15;AppKit/AppKit.jt;1567;
objj_executeFile("Foundation/Foundation.j",false);
objj_executeFile("AppKit/AppKit.j",false);
findCibClassDependencies=function(_1){
var _2=objj_msgSend(objj_msgSend(CPCib,"alloc"),"initWithContentsOfURL:",_1);
var _3={};
var _4=CPClassFromString;
CPClassFromString=function(_5){
var _6=_4(_5);
_3[_5]=true;
return _6;
};
objj_msgSend(CPApplication,"sharedApplication");
try{
var x=objj_msgSend(_2,"pressInstantiate");
}
catch(e){
CPLog.warn("Exception thrown when instantiating "+_1+": "+e);
}
finally{
CPClassFromString=_4;
}
return Object.keys(_3);
};
var _7=objj_getClass("CPCib");
if(!_7){
throw new SyntaxError("*** Could not find definition for class \"CPCib\"");
}
var _8=_7.isa;
class_addMethods(_7,[new objj_method(sel_getUid("pressInstantiate"),function(_9,_a){
with(_9){
var _b=_bundle,_c=nil;
if(!_b&&_c){
_b=objj_msgSend(CPBundle,"bundleForClass:",objj_msgSend(_c,"class"));
}
var _d=objj_msgSend(objj_msgSend(_CPCibKeyedUnarchiver,"alloc"),"initForReadingWithData:bundle:awakenCustomResources:",_data,_b,_awakenCustomResources),_e=nil;
if(_e){
var _f=nil,_10=objj_msgSend(_e,"keyEnumerator");
while(_f=objj_msgSend(_10,"nextObject")){
objj_msgSend(_d,"setClass:forClassName:",objj_msgSend(_e,"objectForKey:",_f),_f);
}
}
objj_msgSend(_d,"setExternalObjectsForProxyIdentifiers:",nil);
var _11=objj_msgSend(_d,"decodeObjectForKey:","CPCibObjectDataKey");
if(!_11||!objj_msgSend(_11,"isKindOfClass:",objj_msgSend(_CPCibObjectData,"class"))){
return NO;
}
var _12=nil;
objj_msgSend(_11,"instantiateWithOwner:topLevelObjects:",_c,_12);
return YES;
}
})]);
p;6;main.jt;7008;@STATIC;1.0;I;23;Foundation/Foundation.jI;15;AppKit/AppKit.ji;21;objj-analysis-tools.ji;20;cib-analysis-tools.jt;6890;
require("narwhal").ensureEngine("rhino");
objj_executeFile("Foundation/Foundation.j",false);
objj_executeFile("AppKit/AppKit.j",false);
objj_executeFile("objj-analysis-tools.j",true);
objj_executeFile("cib-analysis-tools.j",true);
var _1=require("file");
var OS=require("os");
var _2=require("term").stream;
var _3=new (require("args").Parser)();
_3.usage("INPUT_PROJECT OUTPUT_PROJECT");
_3.help("Analyze and strip unused files from a Cappuccino project's .sj bundles.");
_3.option("-m","--main","main").def("main.j").set().help("The relative path (from INPUT_PROJECT) to the main file (default: 'main.j')");
_3.option("-F","--framework","frameworks").def(["Frameworks"]).push().help("Add a frameworks directory, relative to INPUT_PROJECT (default: ['Frameworks'])");
_3.option("-E","--environment","environments").def(["Browser"]).push().help("Add a platform name (default: ['Browser'])");
_3.option("-f","--force","force").def(false).set(true).help("Force overwriting OUTPUT_PROJECT if it exists");
_3.option("-p","--pngcrush","png").def(false).set(true).help("Run pngcrush on all PNGs (pngcrush must be installed!)");
_3.option("-v","--verbose","verbose").def(false).set(true).help("Verbose logging");
_3.helpful();
main=function(_4){
var _5=_3.parse(_4);
if(_5.args.length<2){
_3.printUsage(_5);
return;
}
CPLogRegister(CPLogPrint);
var _6=_1.path(_5.args[0]).join("").absolute();
var _7=_1.path(_5.args[1]).join("").absolute();
if(_7.exists()){
if(_5.force){
OS.system(["rm","-rf",_7]);
}else{
CPLog.error("OUTPUT_PROJECT "+_7+" exists. Use -f to overwrite.");
OS.exit(1);
}
}
press(_6,_7,_5);
};
press=function(_8,_9,_a){
_2.print("\x00yellow("+Array(81).join("=")+"\x00)");
_2.print("Application root:    \x00green("+_8+"\x00)");
_2.print("Output directory:    \x00green("+_9+"\x00)");
var _b={};
_a.environments.forEach(function(_c){
pressEnvironment(_8,_b,_c,_a);
});
_2.print("\x00red(PHASE 4:\x00) copy to output \x00green("+_8+"\x00) => \x00green("+_9+"\x00)");
_1.copyTree(_8,_9);
for(var _d in _b){
var _e=_9.join(_8.relative(_d));
var _f=_e.dirname();
if(!_f.exists()){
CPLog.warn(_f+" doesn't exist, creating directories.");
_f.mkdirs();
}
if(typeof _b[_d]!=="string"){
_b[_d]=_b[_d].join("");
}
_2.print((_e.exists()?"\x00red(Overwriting:\x00) ":"\x00green(Writing:\x00)     ")+_e);
_1.write(_e,_b[_d],{charset:"UTF-8"});
}
if(_a.png){
pngcrushDirectory(_9);
}
};
pressEnvironment=function(_10,_11,_12,_13){
var _14=String(_10.join(_13.main));
var _15=_13.frameworks.map(function(_16){
return _10.join(_16);
});
_2.print("\x00yellow("+Array(81).join("=")+"\x00)");
_2.print("Main file:           \x00green("+_14+"\x00)");
_2.print("Frameworks:          \x00green("+_15+"\x00)");
_2.print("Environment:         \x00green("+_12+"\x00)");
var _17=new ObjectiveJRuntimeAnalyzer(_10);
var _18=_17.require("objective-j");
_17.setIncludePaths(_15);
_17.setEnvironments([_12,"ObjJ"]);
var _19=_1.glob(_10.join("**","*.cib")).filter(function(_1a){
return !(/Frameworks/).test(_1a);
});
_2.print("\x00red(PHASE 1:\x00) Loading application...");
_17.initializeGlobalRecorder();
_17.load(_14);
_17.finishLoading();
var _1b=_17.mapGlobalsToFiles();
_2.print("Global defines:");
Object.keys(_1b).sort().forEach(function(_1c){
_2.print("\x00blue("+_1c+"\x00) => \x00cyan("+_1b[_1c].map(_10.relative.bind(_10))+"\x00)");
});
_2.print("\x00red(PHASE 2:\x00) Traverse dependency graph...");
var _1d={};
_1d[_14]=true;
var _1e={ignoreFrameworkImports:true,importCallback:function(_1f,_20){
_1d[_20]=true;
},referenceCallback:function(_21,_22){
_1d[_22]=true;
},progressCallback:function(_23){
_2.print("Processing \x00cyan("+_23+"\x00)");
},ignoreFrameworkImportsCallback:function(_24){
_2.print("\x00yellow(Ignoring imports in "+_24+"\x00)");
}};
mainExecutable=_17.executableForImport(_14);
_17.traverseDependencies(mainExecutable,_1e);
var _25=_17.mapGlobalsToFiles();
_19.forEach(function(_26){
var _27=findCibClassDependencies(_26);
_2.print("Cib: \x00green("+_10.relative(_26)+"\x00) => \x00cyan("+_27+"\x00)");
var _28={};
markFilesReferencedByTokens(_27,_25,_28);
_17.checkReferenced(_1e,null,_28);
});
var _29=0,_2a=0;
var _2b=0,_2c=0;
_18.FileExecutable.allFileExecutables().forEach(function(_2d){
var _2e=_2d.path();
if(/\.keyedtheme$/.test(_2e)){
_1d[_2e]=true;
}
if(_1d[_2e]){
_2.print("Included: \x00green("+_10.relative(_2e)+"\x00)");
_29++;
_2b+=_2d.code().length;
}else{
_2.print("Excluded: \x00red("+_10.relative(_2e)+"\x00)");
}
_2a++;
_2c+=_2d.code().length;
},this);
_2.print(sprintf("Saved \x00green(%f%%\x00) (\x00blue(%s\x00)); Total required files: \x00magenta(%d\x00) (\x00blue(%s\x00)) of \x00magenta(%d\x00) (\x00blue(%s\x00));",Math.round(((_2b-_2c)/_2c)*-100),bytesToString(_2c-_2b),_29,bytesToString(_2b),_2a,bytesToString(_2c)));
_2.print("\x00red(PHASE 3b:\x00) Rebuild .sj files");
for(var _2f in _1d){
var _30=_17.executableForImport(_2f),_31=_18.CFBundle.bundleContainingPath(_30.path()),_32=_1.relative(_1.join(_31.path(),""),_30.path());
if(_30.path()!==_2f){
CPLog.warn("Sanity check failed (file path): "+_30.path()+" vs. "+_2f);
}
if(_31&&_31.infoDictionary()){
var _33=_31.executablePath();
if(_33){
if(_1e.ignoredImports[_2f]){
_2.print("Stripping extra imports from \x00blue("+_2f+"\x00)");
var _34=_30.code();
var _1b=_30.fileDependencies();
for(var i=0;i<_1b.length;i++){
var _35=_1b[i];
var _36=new _18.FileExecutableSearch(_35.isLocal()?_1.join(_1.dirname(_2f),_35.path()):_35.path(),_35.isLocal()).result();
var _37=_36.path();
if(!_1d[_37]){
_2.print(" -> \x00red("+_37+"\x00)");
var _38=new RegExp([RegExp.escape("objj_executeFile"),RegExp.escape("("),"[\"']"+RegExp.escape(_35.path())+"[\"']",RegExp.escape(","),RegExp.escape(_35.isLocal()?"true":"false"),RegExp.escape(")")].join("\\s*"),"g");
_34=_34.replace(_38,"/* $& */ (undefined)");
_1b.splice(i--,1);
}
}
if(_34!==_30.code()){
_30.setCode(_34);
}
}
if(!_11[_33]){
_11[_33]=[];
_11[_33].push("@STATIC;1.0;");
}
var _39=_30.toMarkedString();
_11[_33].push("p;"+_32.length+";"+_32);
_11[_33].push("t;"+_39.length+";"+_39);
_2.print("Adding \x00green("+_10.relative(_2f)+"\x00) to \x00cyan("+_10.relative(_33)+"\x00)");
}else{
_2.print("Passing .j through: \x00green("+_10.relative(_2f)+"\x00)");
}
}else{
CPLog.warn("No bundle (or info dictionary for) "+_10.relative(_2f));
}
}
};
pngcrushDirectory=function(_3a){
var _3b=_1.path(_3a);
var _3c=_3b.glob("**/*.png");
system.stderr.print("Running pngcrush on "+_3c.length+" pngs:");
_3c.forEach(function(dst){
var _3d=_3b.join(dst);
var _3e=_1.path(_3d+".tmp");
var p=OS.popen(["pngcrush","-rem","alla","-reduce",_3d,_3e]);
if(p.wait()){
CPLog.warn("pngcrush failed. Ensure it's installed and on your PATH.");
}else{
_1.move(_3e,_3d);
system.stderr.write(".").flush();
}
});
system.stderr.print("");
};
bytesToString=function(_3f){
var n=0;
while(_3f>1024){
_3f/=1024;
n++;
}
return Math.round(_3f*100)/100+" "+["","K","M"][n]+"B";
};
p;21;objj-analysis-tools.jt;7299;@STATIC;1.0;t;7280;
var _1=require("file");
var _2=require("objective-j");
var _3=require("interpreter").Context;
ObjectiveJRuntimeAnalyzer=function(_4){
this.rootPath=_4;
this.context=new _3();
this.scope=setupObjectiveJ(this.context);
this.require=this.context.global.require;
};
ObjectiveJRuntimeAnalyzer.prototype.setIncludePaths=function(_5){
this.context.global.OBJJ_INCLUDE_PATHS=_5;
};
ObjectiveJRuntimeAnalyzer.prototype.setEnvironments=function(_6){
this.require("objective-j").environments=function(){
return _6;
};
};
ObjectiveJRuntimeAnalyzer.prototype.initializeGlobalRecorder=function(){
this.initializeGlobalRecorder=function(){
};
this.ignore=cloneProperties(this.scope,true);
this.files={};
var _7=[];
var _8=null;
var _9=null;
var _a=this;
recordAndReset=function(){
var _b=cloneProperties(_a.scope);
if(_8){
_a.files[_9]=_a.files[_9]||{};
_a.files[_9].globals=_a.files[_9].global||{};
diff({before:_8,after:_b,ignore:_a.ignore,added:_a.files[_9].globals,changed:_a.files[_9].globals});
}
_8=_b;
};
var _c=this.require("objective-j");
var _d=_c.fileExecuterForPath;
_c.fileExecuterForPath=function(_e){
var _f=_d.apply(this,arguments);
return function(_10,_11,_12){
recordAndReset();
_7.push(_9);
if(_11){
_9=_1.normal(_1.join(_e,_10));
}else{
_9=_10;
}
system.stderr.write(">").flush();
_f.apply(this,arguments);
system.stderr.write("<").flush();
recordAndReset();
_9=_7.pop();
};
};
};
ObjectiveJRuntimeAnalyzer.prototype.load=function(_13){
this.require("objective-j").objj_eval("("+(function(_14){
fileImporterForPath("/")(_14,true,function(){
print("Done importing and evaluating: "+_14);
});
})+")")(_13);
};
ObjectiveJRuntimeAnalyzer.prototype.finishLoading=function(_15){
this.require("browser/timeout").serviceTimeouts();
};
ObjectiveJRuntimeAnalyzer.prototype.mapGlobalsToFiles=function(){
this.mergeLibraryImports();
var _16={};
for(var _17 in this.files){
for(var _18 in this.files[_17].globals){
(_16[_18]=_16[_18]||[]).push(_17);
}
}
return _16;
};
ObjectiveJRuntimeAnalyzer.prototype.mapFilesToGlobals=function(){
this.mergeLibraryImports();
var _19={};
for(var _1a in this.files){
_19[_1a]={};
for(var _1b in this.files[_1a].globals){
_19[_1a][_1b]=true;
}
}
return _19;
};
ObjectiveJRuntimeAnalyzer.prototype.mergeLibraryImports=function(){
for(var _1c in this.files){
if(_1.isRelative(_1c)){
var _1d=this.executableForImport(_1c,false).path();
this.files[_1d]=this.files[_1d]||{};
this.files[_1d].globals=this.files[_1d].globals||{};
for(var _1e in this.files[_1c].globals){
this.files[_1d].globals[_1e]=true;
}
delete this.files[_1c];
}
}
};
ObjectiveJRuntimeAnalyzer.prototype.executableForImport=function(_1f,_20){
if(_20===undefined){
_20=true;
}
var _21=this.require("objective-j");
return new _21.FileExecutableSearch(_1f,_20).result();
};
ObjectiveJRuntimeAnalyzer.prototype.traverseDependencies=function(_22,_23){
_23=_23||{};
_23.processedFiles=_23.processedFiles||{};
_23.importedFiles=_23.importedFiles||{};
_23.referencedFiles=_23.referencedFiles||{};
_23.ignoredImports=_23.ignoredImports||{};
var _24=_22.path();
if(_23.processedFiles[_24]){
return;
}
_23.processedFiles[_24]=true;
var _25=false;
if(_23.ignoreAllImports){
_25=true;
}else{
if(_23.ignoreFrameworkImports){
var _26=_24.match(new RegExp("([^\\/]+)\\/([^\\/]+)\\.j$"));
if(_26&&_26[1]===_26[2]){
_25=true;
}
}
}
var _27={},_28={};
if(_23.progressCallback){
_23.progressCallback(this.rootPath.relative(_24),_24);
}
var _29=_22.code();
var _2a=uniqueTokens(_29);
markFilesReferencedByTokens(_2a,this.mapGlobalsToFiles(),_27);
delete _27[_24];
if(_25){
if(_23.ignoreImportsCallback){
_23.ignoreImportsCallback(this.rootPath.relative(_24),_24);
}
_23.ignoredImports[_24]=true;
}else{
_22.fileDependencies().forEach(function(_2b){
var _2c=null;
if(_2b.isLocal()){
_2c=this.executableForImport(_1.normal(_1.join(_1.dirname(_24),_2b.path())),true);
}else{
_2c=this.executableForImport(_2b.path(),false);
}
if(_2c){
var _2d=_2c.path();
if(_2d!==_24){
_28[_2d]=true;
}else{
CPLog.error("Ignoring self import (why are you importing yourself?!): "+this.rootPath.relative(_2d));
}
}else{
CPLog.error("Couldn't find file for import "+_2b.path()+" ("+_2b.isLocal()+")");
}
},this);
}
this.checkImported(_23,_24,_28);
_23.importedFiles[_24]=_28;
this.checkReferenced(_23,_24,_27);
_23.referencedFiles[_24]=_27;
return _23;
};
ObjectiveJRuntimeAnalyzer.prototype.checkImported=function(_2e,_2f,_30){
for(var _31 in _30){
if(_31!==_2f){
if(_2e.importCallback){
_2e.importCallback(_2f,_31);
}
var _32=this.executableForImport(_31,true);
if(_32){
this.traverseDependencies(_32,_2e);
}else{
CPLog.error("Missing imported file: "+_31);
}
}
}
};
ObjectiveJRuntimeAnalyzer.prototype.checkReferenced=function(_33,_34,_35){
for(var _36 in _35){
if(_36!==_34){
if(_33.referenceCallback){
_33.referenceCallback(_34,_36,_35[_36]);
}
var _37=this.executableForImport(_36,true);
if(_37){
this.traverseDependencies(_37,_33);
}else{
CPLog.error("Missing referenced file: "+_36);
}
}
}
};
ObjectiveJRuntimeAnalyzer.prototype.fileExecutables=function(){
var _38=this.require("objective-j");
return _38.FileExecutablesForPaths;
};
uniqueTokens=function(_39){
var _3a=new _2.Lexer(_39,null);
var _3b,_3c={};
while(_3b=_3a.skip_whitespace()){
_3c[_3b]=true;
}
return Object.keys(_3c);
};
markFilesReferencedByTokens=function(_3d,_3e,_3f){
_3d.forEach(function(_40){
if(_3e.hasOwnProperty(_40)){
var _41=_3e[_40];
for(var i=0;i<_41.length;i++){
_3f[_41[i]]=_3f[_41[i]]||{};
_3f[_41[i]][_40]=true;
}
}
});
};
var _42=objj_allocateClassPair(CPObject,"PressBundleDelgate"),_43=_42.isa;
class_addIvars(_42,[new objj_ivar("didFinishLoadingCallback")]);
objj_registerClassPair(_42);
class_addMethods(_42,[new objj_method(sel_getUid("initWithCallback:"),function(_44,_45,_46){
with(_44){
if(_44=objj_msgSendSuper({receiver:_44,super_class:objj_getClass("PressBundleDelgate").super_class},"init")){
didFinishLoadingCallback=_46;
}
return _44;
}
}),new objj_method(sel_getUid("bundleDidFinishLoading:"),function(_47,_48,_49){
with(_47){
print("didFinishLoading: "+_49);
if(didFinishLoadingCallback){
didFinishLoadingCallback(_49);
}
}
})]);
setupObjectiveJ=function(_4a){
_4a.global.NARWHAL_HOME=system.prefix;
_4a.global.NARWHAL_ENGINE_HOME=_1.join(system.prefix,"engines","rhino");
var _4b=_1.join(_4a.global.NARWHAL_ENGINE_HOME,"bootstrap.js");
_4a.evalFile(_4b);
_4a.global.require("browser");
var _4c=_4a.global.require("objective-j");
addMockBrowserEnvironment(_4c.window);
return _4c.window;
};
addMockBrowserEnvironment=function(_4d){
if(!_4d.window){
_4d.window=_4d;
}
if(!_4d.location){
_4d.location={};
}
if(!_4d.location.href){
_4d.location.href="";
}
if(!_4d.Element){
_4d.Element=function(){
this.style={};
};
}
if(!_4d.document){
_4d.document={createElement:function(){
return new _4d.Element();
}};
}
};
cloneProperties=function(_4e,_4f){
var _50={};
for(var _51 in _4e){
_50[_51]=_4f?true:_4e[_51];
}
return _50;
};
diff=function(o){
for(var i in o.after){
if(o.added&&!o.ignore[i]&&typeof o.before[i]=="undefined"){
o.added[i]=true;
}
}
for(var i in o.after){
if(o.changed&&!o.ignore[i]&&typeof o.before[i]!="undefined"&&typeof o.after[i]!="undefined"&&o.before[i]!==o.after[i]){
o.changed[i]=true;
}
}
for(var i in o.before){
if(o.deleted&&!o.ignore[i]&&typeof o.after[i]=="undefined"){
o.deleted[i]=true;
}
}
};
e;