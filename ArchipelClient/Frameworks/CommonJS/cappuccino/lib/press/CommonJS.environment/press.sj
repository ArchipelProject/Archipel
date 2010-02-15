@STATIC;1.0;p;20;cib-analysis-tools.jI;23;Foundation/Foundation.jI;15;AppKit/AppKit.jc;1519;
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
objj_exception_throw(new objj_exception(OBJJClassNotFoundException,"*** Could not find definition for class \"CPCib\""));
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
p;6;main.jc;43;
require("narwhal").ensureEngine("rhino");
I;23;Foundation/Foundation.jI;15;AppKit/AppKit.ji;21;objj-analysis-tools.ji;20;cib-analysis-tools.jc;10415;
var _1=require("args");
var _2=require("file");
var OS=require("os");
var _3=require("browser/dom");
var _4=require("util");
var _5=require("interpreter");
var _6=new _3.XMLSerializer();
var _7=new _1.Parser();
_7.usage("INPUT_PROJECT OUTPUT_PROJECT");
_7.help("Optimizes Cappuccino applications for deployment to the web.");
_7.option("-m","--main","main").def("main.j").set().help("The relative path (from INPUT_PROJECT) to the main file (default: 'main.j')");
_7.option("-F","--framework","frameworks").def(["Frameworks"]).push().help("Add a frameworks directory, relative to INPUT_PROJECT (default: ['Frameworks'])");
_7.option("-E","--environment","environments").def(["W3C"]).push().help("Add a platform name (default: ['W3C', 'IE7', 'IE8'])");
_7.option("-l","--flatten","flatten").def(false).set(true).help("Flatten all code into a single Application.js file and attempt add script tag to index.html (useful for Adobe AIR and CDN deployment)");
_7.option("-f","--force","force").def(false).set(true).help("Force overwriting OUTPUT_PROJECT if it exists");
_7.option("-n","--nostrip","strip").def(true).set(false).help("Do not strip any files");
_7.option("-p","--pngcrush","png").def(false).set(true).help("Run pngcrush on all PNGs (pngcrush must be installed!)");
_7.option("-v","--verbose","verbose").def(false).set(true).help("Verbose logging");
_7.helpful();
main=function(_8){
var _9=_7.parse(_8);
if(_9.args.length<2){
_7.printUsage(_9);
return;
}
CPLogRegister(CPLogPrint);
var _a=_2.path(_9.args[0]).join("").absolute();
var _b=_2.path(_9.args[1]).join("").absolute();
if(_b.exists()){
if(_9.force){
_b.rmtree();
}else{
CPLog.error("OUTPUT_PROJECT "+_b+" exists. Use -f to overwrite.");
OS.exit(1);
}
}
press(_a,_b,_9);
};
press=function(_c,_d,_e){
CPLog.info("===========================================");
CPLog.info("Application root:    "+_c);
CPLog.info("Output directory:    "+_d);
var _f={};
_e.environments.forEach(function(_10){
pressEnvironment(_c,_f,_10,_e);
});
CPLog.error("PHASE 4: copy to output ("+_c+" to "+_d+")");
_2.copyTree(_c,_d);
for(var _11 in _f){
var _12=_d.join(_c.relative(_11));
var _13=_12.dirname();
if(!_13.exists()){
CPLog.warn(_13+" doesn't exist, creating directories.");
_13.mkdirs();
}
if(typeof _f[_11]!=="string"){
_f[_11]=_f[_11].join("");
}
CPLog.info((_12.exists()?"Overwriting: ":"Writing:     ")+_12);
_2.write(_12,_f[_11],{charset:"UTF-8"});
}
if(_e.png){
pngcrushDirectory(_d);
}
};
pressEnvironment=function(_14,_15,_16,_17){
var _18=String(_14.join(_17.main));
var _19=_17.frameworks.map(function(_1a){
return _14.join(_1a);
});
CPLog.info("===========================================");
CPLog.info("Main file:           "+_18);
CPLog.info("Frameworks:          "+_19);
CPLog.info("Environment:         "+_16);
var _1b=new _5.Context();
var _1c=setupObjectiveJ(_1b);
_1c.OBJJ_INCLUDE_PATHS=_19;
_1c.OBJJ_ENVIRONMENTS=[_16,"ObjJ"];
var _1d=_2.glob(_14.join("**","*.cib")).filter(function(_1e){
return !(/Frameworks/).test(_1e);
});
var _1f=[];
var _20=[];
var _21=[];
functionHookBefore(_1c.objj_search.prototype,"didReceiveBundleResponse",function(_22){
var _23={success:_22.success,filePath:_14.relative(_22.filePath).toString()};
if(_22.success){
var _24=_6.serializeToString(_22.xml);
_23.text=CPPropertyListCreate280NorthData(CPPropertyListCreateFromXMLData({string:_24})).string;
}
_1f.push(_23);
});
functionHookBefore(_1c.objj_search.prototype,"didReceiveExecutableResponse",function(_25){
_20.push(_25);
});
_1b.rootPath=_14;
_1b.scope=_1c;
CPLog.error("PHASE 1: Loading application...");
var _26=findGlobalDefines(_1b,_18,_21);
var _27=coalesceGlobalDefines(_26);
CPLog.trace("Global defines:");
Object.keys(_27).sort().forEach(function(_28){
CPLog.trace("    "+_28+" => "+_14.relative(_27[_28]));
});
CPLog.error("PHASE 2: Walk dependency tree...");
var _29={};
if(_17.nostrip){
_29=_1c.objj_files;
}else{
if(!_1c.objj_files[_18]){
CPLog.error("Root file not loaded!");
return;
}
CPLog.warn("Analyzing dependencies...");
_1b.dependencies=_27;
_1b.ignoreFrameworkImports=true;
_1b.importCallback=function(_2a,_2b){
_29[_2b]=true;
};
_1b.referenceCallback=function(_2c,_2d){
_29[_2d]=true;
};
_29[_18]=true;
traverseDependencies(_1b,_1c.objj_files[_18]);
_1d.forEach(function(_2e){
var _2f=findCibClassDependencies(_2e);
CPLog.debug(_2e+" => "+_2f);
var _30={};
markFilesReferencedByTokens(_2f,_1b.dependencies,_30);
checkReferenced(_1b,null,_30);
print(_4.repr(_30));
});
var _31=0,_32=0;
for(var _33 in _1c.objj_files){
if(/\.keyedtheme$/.test(_33)){
_29[_33]=true;
}
if(_29[_33]){
CPLog.debug("Included: "+_14.relative(_33));
_31++;
}else{
CPLog.info("Excluded: "+_14.relative(_33));
}
_32++;
}
CPLog.warn("Total required files: "+_31+" out of "+_32);
}
if(_17.flatten){
CPLog.error("PHASE 3a: Flattening...");
var _34="Application-"+_16+".js";
var _35="index-"+_16+".html";
var _36=function(_37){
var _38=new objj_bundle();
_38.path=_37.filePath;
if(_37.success){
var _39=new objj_data();
_39.string=_37.text;
_38.info=CPPropertyListCreateFrom280NorthData(_39);
}else{
_38.info=new objj_dictionary();
}
objj_bundles[_37.filePath]=_38;
};
var _3a=function(_3b){
var _3c=function(_3d){
return (_3d).substr(0,(_3d).lastIndexOf("/")+1);
};
for(var _3e in _3b){
if(objj_bundles[_3e]){
var _3f=_3b[_3e];
objj_bundles[_3e]._URIMap={};
for(var _40 in _3f){
var URI=_3f[_40];
if(URI.toLowerCase().indexOf("mhtml:")===0){
objj_bundles[_3e]._URIMap[_40]="mhtml:"+_3c(window.location.href)+"/"+URI.substr("mhtml:".length);
}
}
}else{
console.log("no bundle for "+_3e);
}
}
};
var _41=[];
var _42={};
Object.keys(_1c.objj_bundles).forEach(function(_43){
var _44=_1c.objj_bundles[_43];
var _45=_14.relative(_44.path);
if(_44._URIMap){
_42[_45]={};
Object.keys(_44._URIMap).forEach(function(_46){
var _47=_44._URIMap[_46];
var _48;
if(_48=_47.match(/^mhtml:[^!]*!(.*)$/)){
_47="mhtml:"+_34+"!"+_48[1];
}
_42[_45][_46]=_47;
});
}
});
_41.push("(function() {");
_41.push("    var didReceiveBundleResponse = "+String(_36));
_41.push("    var setupURIMaps = "+String(_3a));
_41.push("    var bundleArchiveResponses = "+JSON.stringify(_1f)+";");
_41.push("    for (var i = 0; i < bundleArchiveResponses.length; i++)");
_41.push("        didReceiveBundleResponse(bundleArchiveResponses[i]);");
_41.push("    var URIMaps = "+JSON.stringify(_42)+";");
_41.push("    setupURIMaps(URIMaps);");
_41.push("})();");
_21.forEach(function(_49){
if(_29[_49.file.path]){
_41.push("(function(OBJJ_CURRENT_BUNDLE) {");
_41.push(_49.info);
_41.push("})(objj_bundles['"+_14.relative(_49.bundle.path)+"']);");
}else{
CPLog.info("Stripping "+_14.relative(_49.file.path));
}
});
_41.push("if (window.addEventListener)");
_41.push("    window.addEventListener('load', main, false);");
_41.push("else if (window.attachEvent)");
_41.push("    window.attachEvent('onload', main);");
_20.forEach(function(_4a){
var _4b=_4a.text.lastIndexOf("/*");
var _4c=_4a.text.lastIndexOf("*/");
if(_4b>=0&&_4c>_4b){
_41.push(_4a.text.slice(_4b,_4c+2));
}
});
var _4d=_2.read(_2.join(_14,"index.html"),{charset:"UTF-8"});
_4d=_4d.replace(/(\bOBJJ_MAIN_FILE\s*=|\bobjj_import\s*\()/g,"//$&");
_4d=_4d.replace(/([ \t]*)(<\/head>)/,"$1    <script src = \""+_34+"\" type = \"text/javascript\"></script>\n$1$2");
_15[_14.join(_34)]=_41.join("\n");
_15[_14.join(_35)]=_4d;
}else{
CPLog.error("PHASE 3b: Rebuild .sj");
var _4e={};
for(var _33 in _29){
var _4f=_1c.objj_files[_33],_50=_2.basename(_33),_51=_2.dirname(_33);
if(_4f.path!=_33){
CPLog.warn("Sanity check failed (file path): "+_4f.path+" vs. "+_33);
}
if(_4f.bundle){
var _52=_2.path(_4f.bundle.path).dirname();
if(!_4e[_4f.bundle.path]){
_4e[_4f.bundle.path]=_4f.bundle;
}
if(_52!=_51){
CPLog.warn("Sanity check failed (directory path): "+_51+" vs. "+_52);
}
var _53=_4f.bundle.info,_54=objj_msgSend(_53,"objectForKey:","CPBundlePlatforms"),_55=objj_msgSend(_53,"objectForKey:","CPBundleReplacedFiles");
var _56="";
if(_54){
_56=objj_msgSend(_54,"firstObjectCommonWithArray:",_1c.OBJJ_PLATFORMS);
}
var _57=objj_msgSend(_55,"objectForKey:",_56);
if(_57&&objj_msgSend(_57,"containsObject:",_50)){
var _58=_52.join(_56+".platform",objj_msgSend(_53,"objectForKey:","CPBundleExecutable"));
if(!_15[_58]){
_15[_58]=[];
_15[_58].push("@STATIC;1.0;");
}
_15[_58].push("p;");
_15[_58].push(_50.length+";");
_15[_58].push(_50);
for(var i=0;i<_4f.fragments.length;i++){
if(_4f.fragments[i].type&FRAGMENT_CODE){
_15[_58].push("c;");
_15[_58].push(_4f.fragments[i].info.length+";");
_15[_58].push(_4f.fragments[i].info);
}else{
if(_4f.fragments[i].type&FRAGMENT_FILE){
var _59=false;
if(_4f.fragments[i].conditionallyIgnore){
var _5a=findImportInObjjFiles(_1c,_4f.fragments[i]);
if(!_5a||!_29[_5a]){
_59=true;
}
}
if(!_59){
if(_4f.fragments[i].type&FRAGMENT_LOCAL){
var _5b=pathRelativeTo(_4f.fragments[i].info,_51);
_15[_58].push("i;");
_15[_58].push(_5b.length+";");
_15[_58].push(_5b);
}else{
_15[_58].push("I;");
_15[_58].push(_4f.fragments[i].info.length+";");
_15[_58].push(_4f.fragments[i].info);
}
}else{
CPLog.info("Ignoring import fragment "+_4f.fragments[i].info+" in "+_14.relative(_33));
}
}else{
CPLog.error("Unknown fragment type");
}
}
}
}else{
_15[_33]=_4f.contents;
}
}else{
CPLog.warn("No bundle for "+_14.relative(_33));
}
}
CPLog.error("PHASE 3.5: fix bundle plists");
for(var _33 in _4e){
var _51=_2.dirname(_33),_53=_4e[_33].info,_57=objj_msgSend(_53,"objectForKey:","CPBundleReplacedFiles");
CPLog.info("Modifying .sj: "+_14.relative(_33));
if(_57){
var _5c=[];
objj_msgSend(_53,"setObject:forKey:",_5c,"CPBundleReplacedFiles");
for(var i=0;i<_57.length;i++){
var _5d=_51+"/"+_57[i];
if(!_29[_5d]){
CPLog.info("Removing: "+_57[i]);
}else{
_5c.push(_57[i]);
}
}
}
_15[_33]=CPPropertyListCreateXMLData(_53).string;
}
}
};
pngcrushDirectory=function(_5e){
var _5f=_2.path(_5e);
var _60=_5f.glob("**/*.png");
system.stderr.print("Running pngcrush on "+_60.length+" pngs:");
_60.forEach(function(dst){
var _61=_5f.join(dst);
var _62=_2.path(_61+".tmp");
var p=OS.popen(["pngcrush","-rem","alla","-reduce",_61,_62]);
if(p.wait()){
CPLog.warn("pngcrush failed. Ensure it's installed and on your PATH.");
}else{
_2.move(_62,_61);
system.stderr.write(".").flush();
}
});
system.stderr.print("");
};
functionHookBefore=function(_63,_64,_65){
var _66=_63[_64];
_63[_64]=function(){
_65.apply(this,arguments);
var _67=_66.apply(this,arguments);
return _67;
};
};
pathRelativeTo=function(_68,_69){
return _2.relative(_2.join(_69,""),_68);
};
p;21;objj-analysis-tools.jc;6046;
var _1=require("file");
traverseDependencies=function(_2,_3){
if(!_2.processedFiles){
_2.processedFiles={};
}
if(_2.processedFiles[_3.path]){
return;
}
_2.processedFiles[_3.path]=true;
var _4=false;
if(_2.ignoreAllImports){
CPLog.warn("Ignoring all import fragments. ("+_2.rootPath.relative(_3.path)+")");
_4=true;
}else{
if(_2.ignoreFrameworkImports){
var _5=_3.path.match(new RegExp("([^\\/]+)\\/([^\\/]+)\\.j$"));
if(_5&&_5[1]===_5[2]){
CPLog.warn("Framework import file! Ignoring all import fragments. ("+_2.rootPath.relative(_3.path)+")");
_4=true;
}
}
}
if(!_3.fragments){
if(_3.included){
CPLog.warn(_2.rootPath.relative(_3.path)+" is included but missing fragments");
}else{
CPLog.warn("Preprocessing "+_2.rootPath.relative(_3.path));
}
_3.fragments=objj_preprocess(_3.contents,_3.bundle,_3);
}
var _6={},_7={};
CPLog.debug("Processing "+_3.fragments.length+" fragments in "+_2.rootPath.relative(_3.path));
for(var i=0;i<_3.fragments.length;i++){
var _8=_3.fragments[i];
if(_8.type&FRAGMENT_CODE){
var _9=uniqueTokens(_8.info);
markFilesReferencedByTokens(_9,_2.dependencies,_6);
}else{
if(_8.type&FRAGMENT_FILE){
if(_4){
_8.conditionallyIgnore=true;
}else{
var _a=findImportInObjjFiles(_2.scope,_8);
if(_a){
if(_a!=_3.path){
_7[_a]=true;
}else{
CPLog.error("Ignoring self import (why are you importing yourself?!): "+_2.rootPath.relative(_3.path));
}
}else{
CPLog.error("Couldn't find file for import "+_8.info+" ("+_8.type+")");
}
}
}
}
}
checkImported(_2,_3.path,_7);
if(_2.importedFiles){
_2.importedFiles[_3.path]=_7;
}
checkReferenced(_2,_3.path,_6);
if(_2.referencedFiles){
_2.referencedFiles[_3.path]=_6;
}
};
checkImported=function(_b,_c,_d){
for(var _e in _d){
if(_e!=_c){
if(_b.importCallback){
_b.importCallback(_c,_e);
}
if(_b.scope.objj_files[_e]){
traverseDependencies(_b,_b.scope.objj_files[_e]);
}else{
CPLog.error("Missing imported file: "+_e);
}
}
}
};
checkReferenced=function(_f,_10,_11){
for(var _12 in _11){
if(_12!=_10){
if(_f.referenceCallback){
_f.referenceCallback(_10,_12,_11[_12]);
}
if(_f.scope.objj_files.hasOwnProperty(_12)){
traverseDependencies(_f,_f.scope.objj_files[_12]);
}else{
CPLog.error("Missing referenced file: "+_12);
}
}
}
};
uniqueTokens=function(_13){
var _14=new objj_lexer(_13,null);
var _15,_16={};
while(_15=_14.skip_whitespace()){
_16[_15]=true;
}
return Object.keys(_16);
};
markFilesReferencedByTokens=function(_17,_18,_19){
_17.forEach(function(_1a){
if(_18.hasOwnProperty(_1a)){
var _1b=_18[_1a];
for(var j=0;j<_1b.length;j++){
if(_1b[j]!=file.path){
if(!_19[_1b[j]]){
_19[_1b[j]]={};
}
_19[_1b[j]][_1a]=true;
}
}
}
});
};
findImportInObjjFiles=function(_1c,_1d){
var _1e=null;
if(_1d.type&FRAGMENT_LOCAL){
var _1f=_1d.info;
if(_1c.objj_files[_1f]){
_1e=_1f;
}
}else{
var _20=_1c.OBJJ_INCLUDE_PATHS.length;
while(_20--){
var _1f=_1c.OBJJ_INCLUDE_PATHS[_20].replace(new RegExp("\\/$"),"")+"/"+_1d.info;
if(_1c.objj_files[_1f]){
_1e=_1f;
break;
}
}
}
return _1e;
};
var _21=objj_allocateClassPair(CPObject,"PressBundleDelgate"),_22=_21.isa;
class_addIvars(_21,[new objj_ivar("didFinishLoadingCallback")]);
objj_registerClassPair(_21);
objj_addClassForBundle(_21,objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));
class_addMethods(_21,[new objj_method(sel_getUid("initWithCallback:"),function(_23,_24,_25){
with(_23){
if(_23=objj_msgSendSuper({receiver:_23,super_class:objj_getClass("CPObject")},"init")){
didFinishLoadingCallback=_25;
}
return _23;
}
}),new objj_method(sel_getUid("bundleDidFinishLoading:"),function(_26,_27,_28){
with(_26){
print("didFinishLoading: "+_28);
if(didFinishLoadingCallback){
didFinishLoadingCallback(_28);
}
}
})]);
findGlobalDefines=function(_29,_2a,_2b,_2c){
var _2d=cloneProperties(_29.scope,true);
_2d["bundle"]=true;
var _2e={};
var _2f=_29.scope.fragment_evaluate_file;
_29.scope.fragment_evaluate_file=function(_30){
return _2f(_30);
};
var _31=_29.scope.fragment_evaluate_code;
_29.scope.fragment_evaluate_code=function(_32){
CPLog.debug("Evaluating "+_29.rootPath.relative(_32.file.path)+" ("+_29.rootPath.relative(_32.bundle.path)+")");
var _33=cloneProperties(_29.scope);
if(_2b){
_2b.push(_32);
}
var _34=_31(_32);
var _35={};
diff(_33,_29.scope,_2d,_35,_35,null);
_2e[_32.file.path]=_35;
return _34;
};
var _36=objj_msgSend(objj_msgSend(PressBundleDelgate,"alloc"),"initWithCallback:",_2c);
var _37=[];
(_29.eval("("+(function(_38,_39,_3a){
with(require("objective-j").window){
objj_import(_38,true,function(){
_3a=_3a||[];
_3a.forEach(function(_3b){
var _3c=objj_msgSend(objj_msgSend(CPBundle,"alloc"),"initWithPath:",_3b);
objj_msgSend(_3c,"loadWithDelegate:",_39);
});
});
}
})+")"))(_2a,_36,_37);
_29.scope.require("browser/timeout").serviceTimeouts();
return _2e;
};
coalesceGlobalDefines=function(_3d){
var _3e={};
for(var _3f in _3d){
var _40=_3d[_3f];
for(var _41 in _40){
if(!_3e[_41]){
_3e[_41]=[];
}
_3e[_41].push(_3f);
}
}
return _3e;
};
setupObjectiveJ=function(_42,_43){
_42.global.NARWHAL_HOME=system.prefix;
_42.global.NARWHAL_ENGINE_HOME=_1.join(system.prefix,"engines","rhino");
var _44=_1.join(_42.global.NARWHAL_ENGINE_HOME,"bootstrap.js");
_42.evalFile(_44);
var _45=_42.global.require("objective-j");
addMockBrowserEnvironment(_45.window);
return _45.window;
};
addMockBrowserEnvironment=function(_46){
if(!_46.window){
_46.window=_46;
}
if(!_46.location){
_46.location={};
}
if(!_46.location.href){
_46.location.href="";
}
if(!_46.Element){
_46.Element=function(){
this.style={};
};
}
if(!_46.document){
_46.document={createElement:function(){
return new _46.Element();
}};
}
};
cloneProperties=function(_47,_48){
var _49={};
for(var _4a in _47){
_49[_4a]=_48?true:_47[_4a];
}
return _49;
};
diff=function(_4b,_4c,_4d,_4e,_4f,_50){
for(var i in _4c){
if(_4e&&!_4d[i]&&typeof _4b[i]=="undefined"){
_4e[i]=true;
}
}
for(var i in _4c){
if(_4f&&!_4d[i]&&typeof _4b[i]!="undefined"&&typeof _4c[i]!="undefined"&&_4b[i]!==_4c[i]){
_4f[i]=true;
}
}
for(var i in _4b){
if(_50&&!_4d[i]&&typeof _4c[i]=="undefined"){
_50[i]=true;
}
}
};
allKeys=function(_51){
var _52=[];
for(var i in _51){
_52.push(i);
}
return _52.sort();
};
e;