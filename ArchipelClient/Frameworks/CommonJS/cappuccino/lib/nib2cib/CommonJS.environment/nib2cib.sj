@STATIC;1.0;p;15;_NSCornerView.jt;862;@STATIC;1.0;I;26;AppKit/CPTableHeaderView.jt;813;
objj_executeFile("AppKit/CPTableHeaderView.j",false);
var _1=objj_getClass("_CPCornerView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"_CPCornerView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
return _3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("_CPCornerView").super_class},"NS_initWithCoder:",_5);
}
})]);
var _1=objj_allocateClassPair(_CPCornerView,"_NSCornerView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(_CPCornerView,"class");
}
})]);
p;15;Converter+Mac.jt;1595;@STATIC;1.0;i;11;Converter.jt;1560;
objj_executeFile("Converter.j",true);
var _1=objj_getClass("Converter");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"Converter\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("convertedDataFromMacData:resourcesPath:"),function(_3,_4,_5,_6){
with(_3){
var _7=objj_msgSend(objj_msgSend(Nib2CibKeyedUnarchiver,"alloc"),"initForReadingWithData:resourcesPath:",_5,_6),_8=objj_msgSend(_7,"decodeObjectForKey:","IB.objectdata");
var _9=objj_msgSend(_7,"allObjects"),_a=objj_msgSend(_9,"count");
while(_a--){
var _b=_9[_a];
if(!objj_msgSend(_b,"isKindOfClass:",objj_msgSend(CPView,"class"))){
continue;
}
var _c=objj_msgSend(_b,"superview");
if(!_c||objj_msgSend(_c,"NS_isFlipped")){
continue;
}
var _d=CGRectGetHeight(objj_msgSend(_c,"bounds")),_e=objj_msgSend(_b,"frame");
objj_msgSend(_b,"setFrameOrigin:",CGPointMake(CGRectGetMinX(_e),_d-CGRectGetMaxY(_e)));
var _f=objj_msgSend(_b,"autoresizingMask");
autoresizingMask=_f&~(CPViewMaxYMargin|CPViewMinYMargin);
if(!(_f&(CPViewMaxYMargin|CPViewMinYMargin|CPViewHeightSizable))){
autoresizingMask|=CPViewMinYMargin;
}else{
if(_f&CPViewMaxYMargin){
autoresizingMask|=CPViewMinYMargin;
}
if(_f&CPViewMinYMargin){
autoresizingMask|=CPViewMaxYMargin;
}
}
objj_msgSend(_b,"setAutoresizingMask:",autoresizingMask);
}
var _10=objj_msgSend(CPData,"data"),_11=objj_msgSend(objj_msgSend(CPKeyedArchiver,"alloc"),"initForWritingWithMutableData:",_10);
objj_msgSend(_11,"encodeObject:forKey:",_8,"CPCibObjectDataKey");
objj_msgSend(_11,"finishEncoding");
return _10;
}
})]);
p;11;Converter.jt;3742;@STATIC;1.0;I;21;Foundation/CPObject.jI;19;Foundation/CPData.ji;15;Converter+Mac.jt;3653;
objj_executeFile("Foundation/CPObject.j",false);
objj_executeFile("Foundation/CPData.j",false);
var _1=require("file"),_2=require("os").popen;
NibFormatUndetermined=0,NibFormatMac=1,NibFormatIPhone=2;
ConverterConversionException="ConverterConversionException";
var _3=objj_allocateClassPair(CPObject,"Converter"),_4=_3.isa;
class_addIvars(_3,[new objj_ivar("format"),new objj_ivar("inputPath"),new objj_ivar("outputPath"),new objj_ivar("resourcesPath")]);
objj_registerClassPair(_3);
class_addMethods(_3,[new objj_method(sel_getUid("format"),function(_5,_6){
with(_5){
return format;
}
}),new objj_method(sel_getUid("setFormat:"),function(_7,_8,_9){
with(_7){
format=_9;
}
}),new objj_method(sel_getUid("inputPath"),function(_a,_b){
with(_a){
return inputPath;
}
}),new objj_method(sel_getUid("setInputPath:"),function(_c,_d,_e){
with(_c){
inputPath=_e;
}
}),new objj_method(sel_getUid("outputPath"),function(_f,_10){
with(_f){
return outputPath;
}
}),new objj_method(sel_getUid("setOutputPath:"),function(_11,_12,_13){
with(_11){
outputPath=_13;
}
}),new objj_method(sel_getUid("resourcesPath"),function(_14,_15){
with(_14){
return resourcesPath;
}
}),new objj_method(sel_getUid("setResourcesPath:"),function(_16,_17,_18){
with(_16){
resourcesPath=_18;
}
}),new objj_method(sel_getUid("init"),function(_19,_1a){
with(_19){
_19=objj_msgSendSuper({receiver:_19,super_class:objj_getClass("Converter").super_class},"init");
if(_19){
objj_msgSend(_19,"setFormat:",NibFormatUndetermined);
}
return _19;
}
}),new objj_method(sel_getUid("convert"),function(_1b,_1c){
with(_1b){
try{
if(objj_msgSend(resourcesPath,"length")&&!_1.isReadable(resourcesPath)){
objj_msgSend(CPException,"raise:reason:",ConverterConversionException,"Could not read Resources at path \""+resourcesPath+"\"");
}
var _1d=_1.read(inputPath,{charset:"UTF-8"}),_1e=format;
if(_1e===NibFormatUndetermined){
_1e=NibFormatMac;
if(_1.extension(inputPath)!==".nib"&&_1d.indexOf("<archive type=\"com.apple.InterfaceBuilder3.CocoaTouch.XIB\"")!==-1){
_1e=NibFormatIPhone;
}
if(_1e===NibFormatMac){
CPLog("Auto-detected Cocoa Nib or Xib File");
}else{
CPLog("Auto-detected CocoaTouch Xib File");
}
}
var _1f=objj_msgSend(_1b,"CPCompliantNibDataAtFilePath:",inputPath);
if(_1e===NibFormatMac){
var _20=objj_msgSend(_1b,"convertedDataFromMacData:resourcesPath:",_1f,resourcesPath);
}else{
objj_msgSend(CPException,"raise:reason:",ConverterConversionException,"nib2cib does not understand this nib format.");
}
if(!objj_msgSend(outputPath,"length")){
outputPath=inputPath.substr(0,inputPath.length-_1.extension(inputPath).length)+".cib";
}
_1.write(outputPath,objj_msgSend(_20,"encodedString"),{charset:"UTF-8"});
}
catch(anException){
CPLog.fatal(anException);
}
}
}),new objj_method(sel_getUid("CPCompliantNibDataAtFilePath:"),function(_21,_22,_23){
with(_21){
var _24=_1.join("/tmp",_1.basename(_23)+".tmp.nib");
if(_2("/usr/bin/ibtool "+_23+" --compile "+_24).wait()===1){
throw "Could not compile file at "+_23;
}
var _25=_1.join("/tmp",_1.basename(_23)+".tmp.plist");
if(_2("/usr/bin/plutil "+" -convert xml1 "+_24+" -o "+_25).wait()===1){
throw "Could not convert to xml plist for file at "+_23;
}
if(!_1.isReadable(_25)){
objj_msgSend(CPException,"raise:reason:",ConverterConversionException,"Unable to convert nib file.");
}
var _26=_1.read(_25,{charset:"UTF-8"});
if(system.engine==="rhino"){
_26=String(java.lang.String(_26).replaceAll("\\<key\\>\\s*CF\\$UID\\s*\\</key\\>","<key>CP\\$UID</key>"));
}else{
_26=_26.replace(/\<key\>\s*CF\$UID\s*\<\/key\>/g,"<key>CP$UID</key>");
}
return objj_msgSend(CPData,"dataWithEncodedString:",_26);
}
})]);
objj_executeFile("Converter+Mac.j",true);
p;6;main.jt;1650;@STATIC;1.0;I;23;Foundation/Foundation.jI;14;AppKit/CPCib.ji;14;NSFoundation.ji;10;NSAppKit.ji;24;Nib2CibKeyedUnarchiver.ji;11;Converter.jt;1505;
objj_executeFile("Foundation/Foundation.j",false);
objj_executeFile("AppKit/CPCib.j",false);
objj_executeFile("NSFoundation.j",true);
objj_executeFile("NSAppKit.j",true);
objj_executeFile("Nib2CibKeyedUnarchiver.j",true);
objj_executeFile("Converter.j",true);
CPLogRegister(CPLogPrint,"fatal");
var _1=require("file"),OS=require("os");
printUsage=function(){
print("usage: nib2cib INPUT_FILE [OUTPUT_FILE] [-F /path/to/required/framework] [-R path/to/resources]");
OS.exit(1);
};
loadFrameworks=function(_2,_3){
if(!_2||_2.length===0){
return _3();
}
_2.forEach(function(_4){
print("Loading "+_4);
var _5=objj_msgSend(objj_msgSend(CPBundle,"alloc"),"initWithPath:",_4);
objj_msgSend(_5,"loadWithDelegate:",nil);
require("browser/timeout").serviceTimeouts();
});
_3();
};
main=function(_6){
_6.shift();
var _7=_6.length;
if(_7<1){
return printUsage();
}
var _8=0,_9=[],_a=objj_msgSend(objj_msgSend(Converter,"alloc"),"init");
for(;_8<_7;++_8){
switch(_6[_8]){
case "-help":
case "--help":
printUsage();
break;
case "--mac":
objj_msgSend(_a,"setFormat:",NibFormatMac);
break;
case "-F":
_9.push(_6[++_8]);
break;
case "-R":
objj_msgSend(_a,"setResourcesPath:",_6[++_8]);
break;
case "-v":
CPLogRegister(CPLogPrint,"warn");
break;
case "-vv":
case "--verbose":
CPLogRegister(CPLogPrint,"trace");
break;
default:
if(objj_msgSend(_a,"inputPath")){
objj_msgSend(_a,"setOutputPath:",_6[_8]);
}else{
objj_msgSend(_a,"setInputPath:",_6[_8]);
}
}
}
loadFrameworks(_9,function(){
objj_msgSend(_a,"convert");
});
};
p;24;Nib2CibKeyedUnarchiver.jt;1290;@STATIC;1.0;I;30;Foundation/CPKeyedUnarchiver.jt;1236;
objj_executeFile("Foundation/CPKeyedUnarchiver.j",false);
var _1=require("file");
var _2=objj_allocateClassPair(CPKeyedUnarchiver,"Nib2CibKeyedUnarchiver"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("resourcesPath")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("resourcesPath"),function(_4,_5){
with(_4){
return resourcesPath;
}
}),new objj_method(sel_getUid("initForReadingWithData:resourcesPath:"),function(_6,_7,_8,_9){
with(_6){
_6=objj_msgSendSuper({receiver:_6,super_class:objj_getClass("Nib2CibKeyedUnarchiver").super_class},"initForReadingWithData:",_8);
if(_6){
resourcesPath=_9;
}
return _6;
}
}),new objj_method(sel_getUid("allObjects"),function(_a,_b){
with(_a){
return _objects;
}
}),new objj_method(sel_getUid("resourcePathForName:"),function(_c,_d,_e){
with(_c){
if(!resourcesPath){
return NULL;
}
var _f=[_1.listPaths(resourcesPath)];
while(_f.length>0){
var _10=_f.shift(),_11=0,_12=_10.length;
for(;_11<_12;++_11){
var _13=_10[_11];
if(_1.basename(_13)===_e){
return _13;
}
if(_1.isDirectory(_13)){
_f.push(_1.listPaths(_13));
}
}
}
return NULL;
}
})]);
_1.listPaths=function(_14){
var _15=_1.list(_14),_16=_15.length;
while(_16--){
_15[_16]=_1.join(_14,_15[_16]);
}
return _15;
};
p;10;NSAppKit.jt;3041;@STATIC;1.0;i;15;_NSCornerView.ji;10;NSButton.ji;8;NSCell.ji;16;NSClassSwapper.ji;12;NSClipView.ji;9;NSColor.ji;13;NSColorWell.ji;18;NSCollectionView.ji;22;NSCollectionViewItem.ji;11;NSControl.ji;16;NSCustomObject.ji;18;NSCustomResource.ji;14;NSCustomView.ji;9;NSEvent.ji;8;NSFont.ji;16;NSIBObjectData.ji;13;NSImageView.ji;10;NSMatrix.ji;8;NSMenu.ji;12;NSMenuItem.ji;16;NSNibConnector.ji;15;NSPopUpButton.ji;13;NSResponder.ji;14;NSScrollView.ji;12;NSScroller.ji;15;NSSearchField.ji;7;NSSet.ji;19;NSSecureTextField.ji;20;NSSegmentedControl.ji;10;NSSlider.ji;13;NSSplitView.ji;15;NSTableColumn.ji;19;NSTableHeaderView.ji;13;NSTableView.ji;11;NSTabView.ji;15;NSTabViewItem.ji;13;NSTextField.ji;11;NSToolbar.ji;28;NSToolbarFlexibleSpaceItem.ji;15;NSToolbarItem.ji;25;NSToolbarShowColorsItem.ji;24;NSToolbarSeparatorItem.ji;20;NSToolbarSpaceItem.ji;8;NSView.ji;18;NSViewController.ji;18;NSWindowTemplate.ji;9;WebView.jt;2121;
objj_executeFile("_NSCornerView.j",true);
objj_executeFile("NSButton.j",true);
objj_executeFile("NSCell.j",true);
objj_executeFile("NSClassSwapper.j",true);
objj_executeFile("NSClipView.j",true);
objj_executeFile("NSColor.j",true);
objj_executeFile("NSColorWell.j",true);
objj_executeFile("NSCollectionView.j",true);
objj_executeFile("NSCollectionViewItem.j",true);
objj_executeFile("NSControl.j",true);
objj_executeFile("NSCustomObject.j",true);
objj_executeFile("NSCustomResource.j",true);
objj_executeFile("NSCustomView.j",true);
objj_executeFile("NSEvent.j",true);
objj_executeFile("NSFont.j",true);
objj_executeFile("NSIBObjectData.j",true);
objj_executeFile("NSImageView.j",true);
objj_executeFile("NSMatrix.j",true);
objj_executeFile("NSMenu.j",true);
objj_executeFile("NSMenuItem.j",true);
objj_executeFile("NSNibConnector.j",true);
objj_executeFile("NSPopUpButton.j",true);
objj_executeFile("NSResponder.j",true);
objj_executeFile("NSScrollView.j",true);
objj_executeFile("NSScroller.j",true);
objj_executeFile("NSSearchField.j",true);
objj_executeFile("NSSet.j",true);
objj_executeFile("NSSecureTextField.j",true);
objj_executeFile("NSSegmentedControl.j",true);
objj_executeFile("NSSlider.j",true);
objj_executeFile("NSSplitView.j",true);
objj_executeFile("NSTableColumn.j",true);
objj_executeFile("NSTableHeaderView.j",true);
objj_executeFile("NSTableView.j",true);
objj_executeFile("NSTabView.j",true);
objj_executeFile("NSTabViewItem.j",true);
objj_executeFile("NSTextField.j",true);
objj_executeFile("NSToolbar.j",true);
objj_executeFile("NSToolbarFlexibleSpaceItem.j",true);
objj_executeFile("NSToolbarItem.j",true);
objj_executeFile("NSToolbarShowColorsItem.j",true);
objj_executeFile("NSToolbarSeparatorItem.j",true);
objj_executeFile("NSToolbarSpaceItem.j",true);
objj_executeFile("NSView.j",true);
objj_executeFile("NSViewController.j",true);
objj_executeFile("NSWindowTemplate.j",true);
objj_executeFile("WebView.j",true);
CP_NSMapClassName=function(_1){
if(_1.indexOf("NS")===0){
var _2="CP"+_1.substr(2);
if(CPClassFromString(_2)){
CPLog.warn("Mapping "+_1+" to "+_2);
return _2;
}
}
return _1;
};
p;9;NSArray.jt;442;@STATIC;1.0;I;21;Foundation/CPObject.jt;398;
objj_executeFile("Foundation/CPObject.j",false);
var _1=objj_allocateClassPair(CPObject,"NSArray"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_3,_4,_5){
with(_3){
return objj_msgSend(_5,"decodeObjectForKey:","NS.objects");
}
})]);
var _1=objj_allocateClassPair(NSArray,"NSMutableArray"),_2=_1.isa;
objj_registerClassPair(_1);
p;10;NSButton.jt;6392;@STATIC;1.0;I;17;AppKit/CPButton.jI;19;AppKit/CPCheckBox.jI;16;AppKit/CPRadio.ji;8;NSCell.ji;11;NSControl.jt;6278;
objj_executeFile("AppKit/CPButton.j",false);
objj_executeFile("AppKit/CPCheckBox.j",false);
objj_executeFile("AppKit/CPRadio.j",false);
objj_executeFile("NSCell.j",true);
objj_executeFile("NSControl.j",true);
var _1={};
_1[CPRoundedBezelStyle]=18;
_1[CPTexturedRoundedBezelStyle]=20;
_1[CPHUDBezelStyle]=20;
var _2=objj_getClass("CPButton");
if(!_2){
throw new SyntaxError("*** Could not find definition for class \"CPButton\"");
}
var _3=_2.isa;
class_addMethods(_2,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_4,_5,_6){
with(_4){
_4=objj_msgSendSuper({receiver:_4,super_class:objj_getClass("CPButton").super_class},"NS_initWithCoder:",_6);
if(_4){
var _7=objj_msgSend(_6,"decodeObjectForKey:","NSCell");
NIB_CONNECTION_EQUIVALENCY_TABLE[objj_msgSend(_7,"UID")]=_4;
if(!objj_msgSend(_4,"NS_isCheckBox")&&!objj_msgSend(_4,"NS_isRadio")){
_controlSize=CPRegularControlSize;
_title=objj_msgSend(_7,"title");
objj_msgSend(_4,"setBordered:",objj_msgSend(_7,"isBordered"));
_bezelStyle=objj_msgSend(_7,"bezelStyle");
switch(_bezelStyle){
case CPRoundedBezelStyle:
case CPTexturedRoundedBezelStyle:
case CPHUDBezelStyle:
break;
case CPRoundRectBezelStyle:
_bezelStyle=CPRoundedBezelStyle;
break;
case CPSmallSquareBezelStyle:
case CPThickSquareBezelStyle:
case CPThickerSquareBezelStyle:
case CPRegularSquareBezelStyle:
case CPTexturedSquareBezelStyle:
case CPShadowlessSquareBezelStyle:
_bezelStyle=CPTexturedRoundedBezelStyle;
break;
case CPRecessedBezelStyle:
_bezelStyle=CPHUDBezelStyle;
break;
case CPRoundedDisclosureBezelStyle:
case CPHelpButtonBezelStyle:
case CPCircularBezelStyle:
case CPDisclosureBezelStyle:
CPLog.warn("Unsupported bezel style: "+_bezelStyle);
_bezelStyle=CPHUDBezelStyle;
break;
default:
CPLog.error("Unknown bezel style: "+_bezelStyle);
_bezelStyle=CPHUDBezelStyle;
}
if(objj_msgSend(_7,"isBordered")){
CPLog.warn("Adjusting CPButton height from "+_frame.size.height+" / "+_bounds.size.height+" to "+24);
_frame.size.height=24;
_bounds.size.height=24;
}
}else{
if(!objj_msgSend(_4,"isKindOfClass:",CPCheckBox)&&!objj_msgSend(_4,"isKindOfClass:",CPRadio)){
if(objj_msgSend(_4,"NS_isCheckBox")){
return objj_msgSend(objj_msgSend(CPCheckBox,"alloc"),"NS_initWithCoder:",_6);
}else{
return objj_msgSend(objj_msgSend(CPRadio,"alloc"),"NS_initWithCoder:",_6);
}
}
objj_msgSend(_4,"setBordered:",YES);
_4._title=objj_msgSend(_7,"title");
}
}
return _4;
}
}),new objj_method(sel_getUid("NS_isCheckBox"),function(_8,_9){
with(_8){
return NO;
}
}),new objj_method(sel_getUid("NS_isRadio"),function(_a,_b){
with(_a){
return NO;
}
})]);
var _2=objj_getClass("CPRadio");
if(!_2){
throw new SyntaxError("*** Could not find definition for class \"CPRadio\"");
}
var _3=_2.isa;
class_addMethods(_2,[new objj_method(sel_getUid("NS_isRadio"),function(_c,_d){
with(_c){
return YES;
}
}),new objj_method(sel_getUid("NS_initWithCoder:"),function(_e,_f,_10){
with(_e){
if(_e=objj_msgSendSuper({receiver:_e,super_class:objj_getClass("CPRadio").super_class},"NS_initWithCoder:",_10)){
_radioGroup=objj_msgSend(CPRadioGroup,"new");
}
return _e;
}
})]);
var _2=objj_getClass("CPCheckBox");
if(!_2){
throw new SyntaxError("*** Could not find definition for class \"CPCheckBox\"");
}
var _3=_2.isa;
class_addMethods(_2,[new objj_method(sel_getUid("NS_isCheckBox"),function(_11,_12){
with(_11){
return YES;
}
})]);
var _2=objj_allocateClassPair(CPButton,"NSButton"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_isCheckBox"),new objj_ivar("_isRadio")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("NS_isCheckBox"),function(_13,_14){
with(_13){
return _isCheckBox;
}
}),new objj_method(sel_getUid("NS_isRadio"),function(_15,_16){
with(_15){
return _isRadio;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_17,_18,_19){
with(_17){
var _1a=objj_msgSend(_19,"decodeObjectForKey:","NSCell"),_1b=objj_msgSend(_1a,"alternateImage");
if(objj_msgSend(_1b,"isKindOfClass:",objj_msgSend(NSButtonImageSource,"class"))){
if(objj_msgSend(_1b,"imageName")==="NSSwitch"){
_isCheckBox=YES;
}else{
if(objj_msgSend(_1b,"imageName")==="NSRadioButton"){
_isRadio=YES;
_17._radioGroup=objj_msgSend(CPRadioGroup,"new");
}
}
}
return objj_msgSend(_17,"NS_initWithCoder:",_19);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_1c,_1d){
with(_1c){
if(objj_msgSend(_1c,"NS_isCheckBox")){
return objj_msgSend(CPCheckBox,"class");
}
if(objj_msgSend(_1c,"NS_isRadio")){
return objj_msgSend(CPRadio,"class");
}
return objj_msgSend(CPButton,"class");
}
})]);
var _2=objj_allocateClassPair(NSActionCell,"NSButtonCell"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_isBordered"),new objj_ivar("_bezelStyle"),new objj_ivar("_title"),new objj_ivar("_alternateImage")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("isBordered"),function(_1e,_1f){
with(_1e){
return _isBordered;
}
}),new objj_method(sel_getUid("bezelStyle"),function(_20,_21){
with(_20){
return _bezelStyle;
}
}),new objj_method(sel_getUid("title"),function(_22,_23){
with(_22){
return _title;
}
}),new objj_method(sel_getUid("alternateImage"),function(_24,_25){
with(_24){
return _alternateImage;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_26,_27,_28){
with(_26){
_26=objj_msgSendSuper({receiver:_26,super_class:objj_getClass("NSButtonCell").super_class},"initWithCoder:",_28);
if(_26){
var _29=objj_msgSend(_28,"decodeIntForKey:","NSButtonFlags"),_2a=objj_msgSend(_28,"decodeIntForKey:","NSButtonFlags2");
_isBordered=(_29&8388608)?YES:NO;
_bezelStyle=(_2a&7)|((_2a&32)>>2);
_title=objj_msgSend(_28,"decodeObjectForKey:","NSContents");
_objectValue=objj_msgSend(_26,"state");
_alternateImage=objj_msgSend(_28,"decodeObjectForKey:","NSAlternateImage");
}
return _26;
}
})]);
var _2=objj_allocateClassPair(CPObject,"NSButtonImageSource"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_imageName")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("imageName"),function(_2b,_2c){
with(_2b){
return _imageName;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_2d,_2e,_2f){
with(_2d){
_2d=objj_msgSendSuper({receiver:_2d,super_class:objj_getClass("NSButtonImageSource").super_class},"init");
if(_2d){
_imageName=objj_msgSend(_2f,"decodeObjectForKey:","NSImageName");
}
return _2d;
}
})]);
p;8;NSCell.jt;3905;@STATIC;1.0;I;21;Foundation/CPObject.ji;8;NSFont.jt;3848;
objj_executeFile("Foundation/CPObject.j",false);
objj_executeFile("NSFont.j",true);
var _1=objj_allocateClassPair(CPObject,"NSCell"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_state"),new objj_ivar("_isHighlighted"),new objj_ivar("_isEnabled"),new objj_ivar("_isEditable"),new objj_ivar("_isBordered"),new objj_ivar("_isBezeled"),new objj_ivar("_isSelectable"),new objj_ivar("_isScrollable"),new objj_ivar("_isContinuous"),new objj_ivar("_wraps"),new objj_ivar("_alignment"),new objj_ivar("_controlSize"),new objj_ivar("_objectValue"),new objj_ivar("_font"),new objj_ivar("_lineBreakMode")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("state"),function(_3,_4){
with(_3){
return _state;
}
}),new objj_method(sel_getUid("isHighlighted"),function(_5,_6){
with(_5){
return _isHighlighted;
}
}),new objj_method(sel_getUid("isEnabled"),function(_7,_8){
with(_7){
return _isEnabled;
}
}),new objj_method(sel_getUid("isEditable"),function(_9,_a){
with(_9){
return _isEditable;
}
}),new objj_method(sel_getUid("isBordered"),function(_b,_c){
with(_b){
return _isBordered;
}
}),new objj_method(sel_getUid("isBezeled"),function(_d,_e){
with(_d){
return _isBezeled;
}
}),new objj_method(sel_getUid("isSelectable"),function(_f,_10){
with(_f){
return _isSelectable;
}
}),new objj_method(sel_getUid("isScrollable"),function(_11,_12){
with(_11){
return _isScrollable;
}
}),new objj_method(sel_getUid("isContinuous"),function(_13,_14){
with(_13){
return _isContinuous;
}
}),new objj_method(sel_getUid("wraps"),function(_15,_16){
with(_15){
return _wraps;
}
}),new objj_method(sel_getUid("alignment"),function(_17,_18){
with(_17){
return _alignment;
}
}),new objj_method(sel_getUid("controlSize"),function(_19,_1a){
with(_19){
return _controlSize;
}
}),new objj_method(sel_getUid("objectValue"),function(_1b,_1c){
with(_1b){
return _objectValue;
}
}),new objj_method(sel_getUid("font"),function(_1d,_1e){
with(_1d){
return _font;
}
}),new objj_method(sel_getUid("lineBreakMode"),function(_1f,_20){
with(_1f){
return _lineBreakMode;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_21,_22,_23){
with(_21){
_21=objj_msgSendSuper({receiver:_21,super_class:objj_getClass("NSCell").super_class},"init");
if(_21){
var _24=objj_msgSend(_23,"decodeIntForKey:","NSCellFlags"),_25=objj_msgSend(_23,"decodeIntForKey:","NSCellFlags2");
_state=(_24&2147483648)?CPOnState:CPOffState;
_isHighlighted=(_24&1073741824)?YES:NO;
_isEnabled=(_24&536870912)?NO:YES;
_isEditable=(_24&268435456)?YES:NO;
_isBordered=(_24&8388608)?YES:NO;
_isBezeled=(_24&4194304)?YES:NO;
_isSelectable=(_24&2097152)?YES:NO;
_isScrollable=(_24&1048576)?YES:NO;
_isContinuous=(_24&524544)?YES:NO;
_wraps=(_24&1048576)?NO:YES;
_alignment=(_25&469762048)>>26;
_controlSize=(_25&917504)>>17;
switch((_25&3840)>>8){
case 0:
_lineBreakMode=CPLineBreakByWordWrapping;
break;
case 2:
_lineBreakMode=CPLineBreakByCharWrapping;
break;
case 6:
_lineBreakMode=CPLineBreakByTruncatingHead;
break;
case 8:
_lineBreakMode=CPLineBreakByTruncatingTail;
break;
case 10:
_lineBreakMode=CPLineBreakByTruncatingMiddle;
break;
case 4:
default:
_lineBreakMode=CPLineBreakByClipping;
break;
}
_objectValue=objj_msgSend(_23,"decodeObjectForKey:","NSContents");
_font=objj_msgSend(_23,"decodeObjectForKey:","NSSupport");
}
return _21;
}
}),new objj_method(sel_getUid("replacementObjectForCoder:"),function(_26,_27,_28){
with(_26){
return nil;
}
}),new objj_method(sel_getUid("stringValue"),function(_29,_2a){
with(_29){
if(objj_msgSend(_objectValue,"isKindOfClass:",objj_msgSend(CPString,"class"))){
return _objectValue;
}
if(objj_msgSend(_objectValue,"respondsToSelector:",sel_getUid("attributedStringValue"))){
return objj_msgSend(_objectValue,"attributedStringValue");
}
return "";
}
})]);
var _1=objj_allocateClassPair(NSCell,"NSActionCell"),_2=_1.isa;
objj_registerClassPair(_1);
p;16;NSClassSwapper.jt;1528;@STATIC;1.0;t;1509;
var _1={},_2={};
var _3="_CPCibClassSwapperClassNameKey",_4="_CPCibClassSwapperOriginalClassNameKey";
var _5=objj_allocateClassPair(_CPCibClassSwapper,"NSClassSwapper"),_6=_5.isa;
objj_registerClassPair(_5);
class_addMethods(_6,[new objj_method(sel_getUid("swapperClassForClassName:originalClassName:"),function(_7,_8,_9,_a){
with(_7){
var _b="$NSClassSwapper_"+_9+"_"+_a;
swapperClass=objj_lookUpClass(_b);
if(!swapperClass){
var _c=objj_lookUpClass(_a);
swapperClass=objj_allocateClassPair(_c,_b);
objj_registerClassPair(swapperClass);
class_addMethod(swapperClass,sel_getUid("initWithCoder:"),function(_d,_e,_f){
_d=objj_msgSendSuper({super_class:_c,receiver:_d},_e,_f);
if(_d){
var UID=objj_msgSend(_d,"UID");
_1[UID]=_9;
_2[UID]=_a;
}
return _d;
},"");
class_addMethod(swapperClass,sel_getUid("classForKeyedArchiver"),function(_10,_11){
return objj_msgSend(_CPCibClassSwapper,"class");
},"");
class_addMethod(swapperClass,sel_getUid("encodeWithCoder:"),function(_12,_13,_14){
objj_msgSendSuper({super_class:_c,receiver:_12},_13,_14);
objj_msgSend(_14,"encodeObject:forKey:",_9,_3);
objj_msgSend(_14,"encodeObject:forKey:",CP_NSMapClassName(_a),_4);
},"");
}
return swapperClass;
}
}),new objj_method(sel_getUid("allocWithCoder:"),function(_15,_16,_17){
with(_15){
var _18=objj_msgSend(_17,"decodeObjectForKey:","NSClassName"),_19=objj_msgSend(_17,"decodeObjectForKey:","NSOriginalClassName");
return objj_msgSend(objj_msgSend(_15,"swapperClassForClassName:originalClassName:",_18,_19),"alloc");
}
})]);
p;12;NSClipView.jt;1144;@STATIC;1.0;I;19;AppKit/CPClipView.jt;1101;
objj_executeFile("AppKit/CPClipView.j",false);
var _1=objj_getClass("CPClipView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPClipView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPClipView").super_class},"NS_initWithCoder:",_5)){
_documentView=objj_msgSend(_5,"decodeObjectForKey:","NSDocView");
if(objj_msgSend(_5,"containsValueForKey:","NSBGColor")){
objj_msgSend(_3,"setBackgroundColor:",objj_msgSend(_5,"decodeObjectForKey:","NSBGColor"));
}
}
return _3;
}
}),new objj_method(sel_getUid("NS_isFlipped"),function(_6,_7){
with(_6){
return YES;
}
})]);
var _1=objj_allocateClassPair(CPClipView,"NSClipView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_8,_9,_a){
with(_8){
return objj_msgSend(_8,"NS_initWithCoder:",_a);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_b,_c){
with(_b){
return objj_msgSend(CPClipView,"class");
}
})]);
p;18;NSCollectionView.jt;1535;@STATIC;1.0;I;25;AppKit/CPCollectionView.jt;1486;
objj_executeFile("AppKit/CPCollectionView.j",false);
var _1=objj_getClass("CPCollectionView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPCollectionView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_items=[];
_content=[];
_cachedItems=[];
_itemSize=CGSizeMakeZero();
_minItemSize=CGSizeMakeZero();
_maxItemSize=CGSizeMakeZero();
_verticalMargin=5;
_tileWidth=-1;
_selectionIndexes=objj_msgSend(CPIndexSet,"indexSet");
_allowsEmptySelection=YES;
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPCollectionView").super_class},"NS_initWithCoder:",_5)){
_backgroundColors=objj_msgSend(_5,"decodeObjectForKey:","NSBackgroundColors");
_maxNumberOfRows=objj_msgSend(_5,"decodeIntForKey:","NSMaxNumberOfGridRows");
_maxNumberOfColumns=objj_msgSend(_5,"decodeIntForKey:","NSMaxNumberOfGridColumns");
_isSelectable=objj_msgSend(_5,"decodeBoolForKey:","NSSelectable");
_allowsMultipleSelection=objj_msgSend(_5,"decodeBoolForKey:","NSAllowsMultipleSelection");
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPCollectionView,"NSCollectionView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPCollectionView,"class");
}
})]);
p;22;NSCollectionViewItem.jt;907;@STATIC;1.0;I;29;AppKit/CPCollectionViewItem.jt;855;
objj_executeFile("AppKit/CPCollectionViewItem.j",false);
var _1=objj_getClass("CPCollectionViewItem");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPCollectionViewItem\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
return objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPCollectionViewItem").super_class},"NS_initWithCoder:",_5);
}
})]);
var _1=objj_allocateClassPair(CPCollectionViewItem,"NSCollectionViewItem"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPCollectionViewItem,"class");
}
})]);
p;9;NSColor.jt;2076;@STATIC;1.0;I;16;AppKit/CPColor.jt;2036;
objj_executeFile("AppKit/CPColor.j",false);
var _1=-1,_2=0,_3=1,_4=2,_5=3,_6=4,_7=5,_8=6;
var _9=objj_getClass("CPColor");
if(!_9){
throw new SyntaxError("*** Could not find definition for class \"CPColor\"");
}
var _a=_9.isa;
class_addMethods(_9,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_b,_c,_d){
with(_b){
var _e=objj_msgSend(_d,"decodeIntForKey:","NSColorSpace"),_f;
switch(_e){
case 1:
case 2:
var rgb=objj_msgSend(_d,"decodeBytesForKey:","NSRGB"),_10=bytes_to_string(rgb),_11=objj_msgSend(_10,"componentsSeparatedByString:"," "),_12=[0,0,0,1];
for(var i=0;i<_11.length&&i<4;i++){
_12[i]=objj_msgSend(_11[i],"floatValue");
}
CPLog.warn("rgb="+rgb+" string="+_10+" values="+_12);
_f=objj_msgSend(CPColor,"colorWithCalibratedRed:green:blue:alpha:",_12[0],_12[1],_12[2],_12[3]);
break;
case 3:
case 4:
var _13=objj_msgSend(_d,"decodeBytesForKey:","NSWhite"),_10=bytes_to_string(_13),_11=objj_msgSend(_10,"componentsSeparatedByString:"," "),_12=[0,1];
for(var i=0;i<_11.length&&i<2;i++){
_12[i]=objj_msgSend(_11[i],"floatValue");
}
_f=objj_msgSend(CPColor,"colorWithCalibratedWhite:alpha:",_12[0],_12[1]);
break;
case 6:
var _14=objj_msgSend(_d,"decodeObjectForKey:","NSCatalogName"),_15=objj_msgSend(_d,"decodeObjectForKey:","NSColorName"),_16=objj_msgSend(_d,"decodeObjectForKey:","NSColor");
if(_14==="System"){
var _f=null;
if(_15==="controlColor"){
_f=nil;
}else{
if(_15==="controlBackgroundColor"){
_f=objj_msgSend(CPColor,"whiteColor");
}else{
if(!_f){
_f=_16;
}
}
}
}else{
_f=null;
if(!_f){
_f=_16;
}
}
break;
default:
CPLog("-[%@ %s] unknown color space %d",isa,_c,_e);
_f=objj_msgSend(CPColor,"blackColor");
break;
}
return _f;
}
})]);
var _9=objj_allocateClassPair(CPColor,"NSColor"),_a=_9.isa;
objj_registerClassPair(_9);
class_addMethods(_9,[new objj_method(sel_getUid("initWithCoder:"),function(_17,_18,_19){
with(_17){
return objj_msgSend(_17,"NS_initWithCoder:",_19);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_1a,_1b){
with(_1a){
return objj_msgSend(CPColor,"class");
}
})]);
p;13;NSColorWell.jt;1116;@STATIC;1.0;I;20;AppKit/CPColorWell.ji;8;NSCell.ji;11;NSControl.jt;1044;
objj_executeFile("AppKit/CPColorWell.j",false);
objj_executeFile("NSCell.j",true);
objj_executeFile("NSControl.j",true);
var _1=objj_getClass("CPColorWell");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPColorWell\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPColorWell").super_class},"NS_initWithCoder:",_5);
if(_3){
objj_msgSend(_3,"setBordered:",objj_msgSend(_5,"decodeBoolForKey:","NSIsBordered"));
objj_msgSend(_3,"setColor:",objj_msgSend(_5,"decodeBoolForKey:","NSColor"));
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPColorWell,"NSColorWell"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPColorWell,"class");
}
})]);
p;11;NSControl.jt;1605;@STATIC;1.0;I;18;AppKit/CPControl.ji;8;NSCell.ji;8;NSView.jt;1539;
objj_executeFile("AppKit/CPControl.j",false);
objj_executeFile("NSCell.j",true);
objj_executeFile("NSView.j",true);
var _1=objj_getClass("CPControl");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPControl\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPControl").super_class},"NS_initWithCoder:",_5);
if(_3){
objj_msgSend(_3,"sendActionOn:",CPLeftMouseUpMask);
var _6=objj_msgSend(_5,"decodeObjectForKey:","NSCell");
objj_msgSend(_3,"setObjectValue:",objj_msgSend(_6,"objectValue"));
objj_msgSend(_3,"setFont:",objj_msgSend(_6,"font"));
objj_msgSend(_3,"setAlignment:",objj_msgSend(_6,"alignment"));
objj_msgSend(_3,"setEnabled:",objj_msgSend(_5,"decodeObjectForKey:","NSEnabled"));
objj_msgSend(_3,"setContinuous:",objj_msgSend(_6,"isContinuous"));
objj_msgSend(_3,"setTarget:",objj_msgSend(_5,"decodeObjectForKey:","NSTarget"));
objj_msgSend(_3,"setAction:",objj_msgSend(_5,"decodeObjectForKey:","NSAction"));
objj_msgSend(_3,"setLineBreakMode:",objj_msgSend(_6,"lineBreakMode"));
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPControl,"NSControl"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_7,_8,_9){
with(_7){
return objj_msgSend(_7,"NS_initWithCoder:",_9);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(CPControl,"class");
}
})]);
p;16;NSCustomObject.jt;972;@STATIC;1.0;I;27;AppKit/_CPCibCustomObject.jt;922;
objj_executeFile("AppKit/_CPCibCustomObject.j",false);
var _1=objj_getClass("_CPCibCustomObject");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"_CPCibCustomObject\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("_CPCibCustomObject").super_class},"init");
if(_3){
_className=CP_NSMapClassName(objj_msgSend(_5,"decodeObjectForKey:","NSClassName"));
}
return _3;
}
})]);
var _1=objj_allocateClassPair(_CPCibCustomObject,"NSCustomObject"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(_CPCibCustomObject,"class");
}
})]);
p;18;NSCustomResource.jt;2334;@STATIC;1.0;I;29;AppKit/_CPCibCustomResource.jt;2281;
objj_executeFile("AppKit/_CPCibCustomResource.j",false);
var _1=objj_getClass("_CPCibCustomResource");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"_CPCibCustomResource\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("_CPCibCustomResource").super_class},"init");
if(_3){
_className=CP_NSMapClassName(objj_msgSend(_5,"decodeObjectForKey:","NSClassName"));
_resourceName=objj_msgSend(_5,"decodeObjectForKey:","NSResourceName");
var _6=CGSizeMakeZero();
if(!objj_msgSend(objj_msgSend(_5,"resourcesPath"),"length")){
CPLog.warn("***WARNING: Resources found in nib, but no resources path specified with -R option.");
}else{
var _7=objj_msgSend(_5,"resourcePathForName:",_resourceName);
if(!_7){
CPLog.warn("***WARNING: Resource named "+_resourceName+" not found in supplied resources path.");
}else{
_6=imageSize(_7);
}
}
_properties=objj_msgSend(CPDictionary,"dictionaryWithObject:forKey:",_6,"size");
}
return _3;
}
})]);
imageSize=function(_8){
return (system.engine==="rhino")?javaImageSize(_8):jscImageSize(_8);
};
javaImageSize=function(_9){
var _a=javax.imageio.ImageIO.createImageInputStream(new Packages.java.io.File(_9).getCanonicalFile()),_b=javax.imageio.ImageIO.getImageReaders(_a),_c=null;
if(_b.hasNext()){
_c=_b.next();
}else{
_a.close();
}
_c.setInput(_a,true,true);
var _d=CGSizeMake(_c.getWidth(0),_c.getHeight(0));
_c.dispose();
_a.close();
return _d;
};
jscImageSize=function(_e){
var _f={".png":"image/png",".jpg":"image/jpeg",".jpeg":"image/jpeg",".gif":"image/gif",".tif":"image/tiff",".tiff":"image/tiff"},_10=require("file");
var _11=new Image();
_11.src="data:"+_f[_10.extension(_e)]+";base64,"+require("base64").encode(_10.read(_e,{mode:"b"}));
return CGSizeMake(_11.width,_11.height);
};
var _1=objj_allocateClassPair(_CPCibCustomResource,"NSCustomResource"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_12,_13,_14){
with(_12){
return objj_msgSend(_12,"NS_initWithCoder:",_14);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_15,_16){
with(_15){
return objj_msgSend(_CPCibCustomResource,"class");
}
})]);
p;14;NSCustomView.jt;1031;@STATIC;1.0;I;25;AppKit/_CPCibCustomView.ji;8;NSView.jt;971;
objj_executeFile("AppKit/_CPCibCustomView.j",false);
objj_executeFile("NSView.j",true);
var _1="_CPCibCustomViewClassNameKey";
var _2=objj_allocateClassPair(CPView,"NSCustomView"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_className")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("initWithCoder:"),function(_4,_5,_6){
with(_4){
_4=objj_msgSendSuper({receiver:_4,super_class:objj_getClass("NSCustomView").super_class},"NS_initWithCoder:",_6);
if(_4){
_className=objj_msgSend(_6,"decodeObjectForKey:","NSClassName");
}
return _4;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_7,_8,_9){
with(_7){
objj_msgSendSuper({receiver:_7,super_class:objj_getClass("NSCustomView").super_class},"encodeWithCoder:",_9);
objj_msgSend(_9,"encodeObject:forKey:",CP_NSMapClassName(_className),_1);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(_CPCibCustomView,"class");
}
})]);
p;9;NSEvent.jt;718;@STATIC;1.0;t;700;
NSAlphaShiftKeyMask=1<<16;
NSShiftKeyMask=1<<17;
NSControlKeyMask=1<<18;
NSAlternateKeyMask=1<<19;
NSCommandKeyMask=1<<20;
NSNumericPadKeyMask=1<<21;
NSHelpKeyMask=1<<22;
NSFunctionKeyMask=1<<23;
NSDeviceIndependentModifierFlagsMask=4294901760;
CP_NSMapKeyMask=function(_1){
var _2=0;
if(_1&NSAlphaShiftKeyMask){
_2|=CPAlphaShiftKeyMask;
}
if(_1&NSShiftKeyMask){
_2|=CPShiftKeyMask;
}
if(_1&NSControlKeyMask){
_2|=CPControlKeyMask;
}
if(_1&NSAlternateKeyMask){
_2|=CPAlternateKeyMask;
}
if(_1&NSCommandKeyMask){
_2|=CPCommandKeyMask;
}
if(_1&NSNumericPadKeyMask){
_2|=CPNumericPadKeyMask;
}
if(_1&NSHelpKeyMask){
_2|=CPHelpKeyMask;
}
if(_1&NSFunctionKeyMask){
_2|=CPFunctionKeyMask;
}
return _2;
};
p;8;NSFont.jt;978;@STATIC;1.0;I;15;AppKit/CPFont.jt;940;
objj_executeFile("AppKit/CPFont.j",false);
var _1=objj_getClass("CPFont");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPFont\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
var _6=NO,_7=objj_msgSend(_5,"decodeObjectForKey:","NSName");
if(_7.indexOf("-Bold")===_7.length-"-Bold".length){
_6=YES;
}
if(_7==="LucidaGrande"||_7==="LucidaGrande-Bold"){
_7="Arial";
}
return objj_msgSend(_3,"_initWithName:size:bold:",_7,objj_msgSend(_5,"decodeDoubleForKey:","NSSize"),_6);
}
})]);
var _1=objj_allocateClassPair(CPFont,"NSFont"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_8,_9,_a){
with(_8){
return objj_msgSend(_8,"NS_initWithCoder:",_a);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_b,_c){
with(_b){
return objj_msgSend(CPFont,"class");
}
})]);
p;14;NSFoundation.jt;253;@STATIC;1.0;i;9;NSArray.ji;21;NSMutableDictionary.ji;17;NSMutableString.ji;7;NSSet.jt;163;
objj_executeFile("NSArray.j",true);
objj_executeFile("NSMutableDictionary.j",true);
objj_executeFile("NSMutableString.j",true);
objj_executeFile("NSSet.j",true);
p;16;NSIBObjectData.jt;2537;@STATIC;1.0;I;25;AppKit/_CPCibObjectData.ji;8;NSCell.jt;2476;
objj_executeFile("AppKit/_CPCibObjectData.j",false);
objj_executeFile("NSCell.j",true);
var _1=objj_getClass("_CPCibObjectData");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"_CPCibObjectData\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSend(_3,"init");
if(_3){
_namesKeys=objj_msgSend(_5,"decodeObjectForKey:","NSNamesKeys");
_namesValues=objj_msgSend(_5,"decodeObjectForKey:","NSNamesValues");
_classesKeys=objj_msgSend(_5,"decodeObjectForKey:","NSClassesKeys");
_classesValues=objj_msgSend(_5,"decodeObjectForKey:","NSClassesValues");
_connections=objj_msgSend(_5,"decodeObjectForKey:","NSConnections");
_framework=objj_msgSend(_5,"decodeObjectForKey:","NSFramework");
_objectsKeys=objj_msgSend(_5,"decodeObjectForKey:","NSObjectsKeys");
_objectsValues=objj_msgSend(_5,"decodeObjectForKey:","NSObjectsValues");
objj_msgSend(_3,"removeCellsFromObjectGraph");
_fileOwner=objj_msgSend(_5,"decodeObjectForKey:","NSRoot");
_visibleWindows=objj_msgSend(_5,"decodeObjectForKey:","NSVisibleWindows");
}
return _3;
}
}),new objj_method(sel_getUid("removeCellsFromObjectGraph"),function(_6,_7){
with(_6){
var _8=_objectsKeys.length,_9={},_a={};
while(_8--){
var _b=_objectsKeys[_8];
if(!_b){
continue;
}
var _c=_objectsValues[_8];
if(objj_msgSend(_b,"isKindOfClass:",objj_msgSend(NSCell,"class"))){
_9[objj_msgSend(_b,"UID")]=_c;
continue;
}
if(!objj_msgSend(_c,"isKindOfClass:",objj_msgSend(NSCell,"class"))){
continue;
}
var _d=objj_msgSend(_c,"UID"),_e=_a[_d];
if(!_e){
_e=[];
_a[_d]=_e;
}
_e.push(_b);
_objectsKeys.splice(_8,1);
_objectsValues.splice(_8,1);
}
for(var _f in _a){
if(_a.hasOwnProperty(_f)){
var _e=_a[_f],_c=_9[_f];
_e.forEach(function(_10){
CPLog.warn("Promoted "+_10+" to child of "+_c);
_objectsKeys.push(_10);
_objectsValues.push(_c);
});
}
}
var _8=_objectsKeys.length;
while(_8--){
var _11=_objectsKeys[_8];
if(objj_msgSend(_11,"respondsToSelector:",sel_getUid("swapCellsForParents:"))){
objj_msgSend(_11,"swapCellsForParents:",_9);
}
}
}
})]);
var _1=objj_allocateClassPair(_CPCibObjectData,"NSIBObjectData"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_12,_13,_14){
with(_12){
return objj_msgSend(_12,"NS_initWithCoder:",_14);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_15,_16){
with(_15){
return objj_msgSend(_CPCibObjectData,"class");
}
})]);
p;13;NSImageView.jt;3149;@STATIC;1.0;I;20;AppKit/CPImageView.jt;3105;
objj_executeFile("AppKit/CPImageView.j",false);
var _1=objj_getClass("CPImageView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPImageView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPImageView").super_class},"NS_initWithCoder:",_5);
if(_3){
var _6=objj_msgSend(_5,"decodeObjectForKey:","NSCell");
_imageScaling=objj_msgSend(_6,"imageScaling");
_isEditable=objj_msgSend(_6,"isEditable");
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPImageView,"NSImageView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_7,_8,_9){
with(_7){
return objj_msgSendSuper({receiver:_7,super_class:objj_getClass("NSImageView").super_class},"NS_initWithCoder:",_9);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(CPImageView,"class");
}
})]);
NSImageAlignCenter=0;
NSImageAlignTop=1;
NSImageAlignTopLeft=2;
NSImageAlignTopRight=3;
NSImageAlignLeft=4;
NSImageAlignBottom=5;
NSImageAlignBottomLeft=6;
NSImageAlignBottomRight=7;
NSImageAlignRight=8;
NSImageScaleProportionallyDown=0;
NSImageScaleAxesIndependently=1;
NSImageScaleNone=2;
NSImageScaleProportionallyUpOrDown=3;
NSImageFrameNone=0;
NSImageFramePhoto=1;
NSImageFrameGrayBezel=2;
NSImageFrameGroove=3;
NSImageFrameButton=4;
var _c={};
_c[NSImageScaleProportionallyDown]=CPScaleProportionally;
_c[NSImageScaleAxesIndependently]=CPScaleToFit;
_c[NSImageScaleNone]=CPScaleNone;
_c[NSImageScaleProportionallyUpOrDown]=CPScaleProportionally;
var _1=objj_allocateClassPair(NSCell,"NSImageCell"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_animates"),new objj_ivar("_imageAlignment"),new objj_ivar("_imageScaling"),new objj_ivar("_frameStyle")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("_animates"),function(_d,_e){
with(_d){
return _animates;
}
}),new objj_method(sel_getUid("_setAnimates:"),function(_f,_10,_11){
with(_f){
_animates=_11;
}
}),new objj_method(sel_getUid("_imageAlignment"),function(_12,_13){
with(_12){
return _imageAlignment;
}
}),new objj_method(sel_getUid("_setImageAlignment:"),function(_14,_15,_16){
with(_14){
_imageAlignment=_16;
}
}),new objj_method(sel_getUid("imageScaling"),function(_17,_18){
with(_17){
return _imageScaling;
}
}),new objj_method(sel_getUid("_frameStyle"),function(_19,_1a){
with(_19){
return _frameStyle;
}
}),new objj_method(sel_getUid("_setFrameStyle:"),function(_1b,_1c,_1d){
with(_1b){
_frameStyle=_1d;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_1e,_1f,_20){
with(_1e){
_1e=objj_msgSendSuper({receiver:_1e,super_class:objj_getClass("NSImageCell").super_class},"initWithCoder:",_20);
if(_1e){
_animates=objj_msgSend(_20,"decodeBoolForKey:","NSAnimates");
_imageAlignment=objj_msgSend(_20,"decodeIntForKey:","NSAlign");
_imageScaling=_c[objj_msgSend(_20,"decodeIntForKey:","NSScale")];
_frameStyle=objj_msgSend(_20,"decodeIntForKey:","NSStyle");
}
return _1e;
}
})]);
p;10;NSMatrix.jt;1835;@STATIC;1.0;I;21;Foundation/CPObject.jI;15;AppKit/CPView.ji;8;NSView.jt;1758;
objj_executeFile("Foundation/CPObject.j",false);
objj_executeFile("AppKit/CPView.j",false);
objj_executeFile("NSView.j",true);
var _1=objj_allocateClassPair(CPObject,"NSMatrix"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_3,_4,_5){
with(_3){
var _6=objj_msgSend(objj_msgSend(CPView,"alloc"),"NS_initWithCoder:",_5);
objj_msgSend(_6,"setBackgroundColor:",objj_msgSend(_5,"decodeObjectForKey:","NSBackgroundColor"));
var _7=objj_msgSend(_5,"decodeIntForKey:","NSNumRows"),_8=objj_msgSend(_5,"decodeIntForKey:","NSNumCols"),_9=objj_msgSend(_5,"decodeSizeForKey:","NSCellSize"),_a=objj_msgSend(_5,"decodeSizeForKey:","NSIntercellSpacing"),_b=objj_msgSend(_5,"decodeObjectForKey:","NSCellBackgroundColor"),_c=objj_msgSend(_5,"decodeIntForKey:","NSMatrixFlags"),_d=objj_msgSend(_5,"decodeObjectForKey:","NSCells"),_e=objj_msgSend(_5,"decodeObjectForKey:","NSSelectedCell");
if((_c&1073741824)){
var _f=objj_msgSend(CPRadioGroup,"new");
frame=CGRectMake(0,0,_9.width,_9.height);
rowIndex=0;
for(;rowIndex<_7;++rowIndex){
var _10=0;
frame.origin.x=0;
for(;_10<_8;++_10){
var _11=_d[rowIndex*_8+_10],_12=objj_msgSend(objj_msgSend(CPRadio,"alloc"),"initWithFrame:radioGroup:",frame,_f);
objj_msgSend(_12,"setAutoresizingMask:",CPViewWidthSizable|CPViewHeightSizable);
objj_msgSend(_12,"setTitle:",objj_msgSend(_11,"title"));
objj_msgSend(_12,"setBackgroundColor:",_b);
objj_msgSend(_12,"setObjectValue:",objj_msgSend(_11,"objectValue"));
objj_msgSend(_6,"addSubview:",_12);
NIB_CONNECTION_EQUIVALENCY_TABLE[objj_msgSend(_11,"UID")]=_12;
frame.origin.x=CGRectGetMaxX(frame)+_a.width;
}
frame.origin.y=CGRectGetMaxY(frame)+_a.height;
}
NIB_CONNECTION_EQUIVALENCY_TABLE[_3]=_6;
}
return _6;
}
})]);
p;8;NSMenu.jt;1493;@STATIC;1.0;I;15;AppKit/CPMenu.ji;12;NSMenuItem.jt;1437;
objj_executeFile("AppKit/CPMenu.j",false);
objj_executeFile("NSMenuItem.j",true);
NS_CPMenuNameMap={_NSMainMenu:"_CPMainMenu",_NSAppleMenu:"_CPApplicationMenu",_NSServicesMenu:"_CPServicesMenu",_NSWindowsMenu:"_CPWindowsMenu",_NSFontMenu:"_CPFontMenu",_NSRecentDocumentsMenu:"_CPRecentDocumentsMenu",_NSOpenDocumentsMenu:"_CPOpenDocumentsMenu"};
var _1=objj_getClass("CPMenu");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPMenu\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPMenu").super_class},"init");
if(_3){
_title=objj_msgSend(_5,"decodeObjectForKey:","NSTitle");
_items=objj_msgSend(_5,"decodeObjectForKey:","NSMenuItems");
_name=objj_msgSend(_5,"decodeObjectForKey:","NSName");
var _6=NS_CPMenuNameMap[_name];
if(_6){
_name=_6;
}
_showsStateColumn=!objj_msgSend(_5,"containsValueForKey:","NSMenuExcludeMarkColumn")||!objj_msgSend(_5,"decodeBoolForKey:","NSMenuExcludeMarkColumn");
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPMenu,"NSMenu"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_7,_8,_9){
with(_7){
return objj_msgSend(_7,"NS_initWithCoder:",_9);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(CPMenu,"class");
}
})]);
p;12;NSMenuItem.jt;2048;@STATIC;1.0;I;19;AppKit/CPMenuItem.ji;9;NSEvent.ji;8;NSMenu.jt;1980;
objj_executeFile("AppKit/CPMenuItem.j",false);
objj_executeFile("NSEvent.j",true);
objj_executeFile("NSMenu.j",true);
var _1=objj_getClass("CPMenuItem");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPMenuItem\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPMenuItem").super_class},"init");
if(_3){
_isSeparator=objj_msgSend(_5,"decodeObjectForKey:","NSIsSeparator")||NO;
_title=objj_msgSend(_5,"decodeObjectForKey:","NSTitle");
_target=objj_msgSend(_5,"decodeObjectForKey:","NSTarget");
_action=objj_msgSend(_5,"decodeObjectForKey:","NSAction");
_isEnabled=!objj_msgSend(_5,"decodeBoolForKey:","NSIsDisabled");
_isHidden=objj_msgSend(_5,"decodeBoolForKey:","NSIsHidden");
_state=objj_msgSend(_5,"decodeIntForKey:","NSState");
_submenu=objj_msgSend(_5,"decodeObjectForKey:","NSSubmenu");
_menu=objj_msgSend(_5,"decodeObjectForKey:","NSMenu");
_keyEquivalent=objj_msgSend(_5,"decodeObjectForKey:","NSKeyEquiv");
_keyEquivalentModifierMask=CP_NSMapKeyMask(objj_msgSend(_5,"decodeObjectForKey:","NSKeyEquivModMask"));
_indentationLevel=objj_msgSend(_5,"decodeIntForKey:","NSIndent");
}
return _3;
}
}),new objj_method(sel_getUid("swapCellsForParents:"),function(_6,_7,_8){
with(_6){
var _9=objj_msgSend(_6,"target");
if(!_9){
return;
}
var _a=_8[objj_msgSend(objj_msgSend(_6,"target"),"UID")];
if(_a){
objj_msgSend(_6,"setTarget:",_a);
}
}
})]);
var _1=objj_allocateClassPair(CPMenuItem,"NSMenuItem"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_b,_c,_d){
with(_b){
return objj_msgSend(_b,"NS_initWithCoder:",_d);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_e,_f){
with(_e){
return objj_msgSend(CPMenuItem,"class");
}
})]);
var _1=objj_allocateClassPair(NSButtonCell,"NSMenuItemCell"),_2=_1.isa;
objj_registerClassPair(_1);
p;21;NSMutableDictionary.jt;393;@STATIC;1.0;t;375;
var _1=objj_allocateClassPair(CPObject,"NSMutableDictionary"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_3,_4,_5){
with(_3){
return objj_msgSend(CPDictionary,"dictionaryWithObjects:forKeys:",objj_msgSend(_5,"decodeObjectForKey:","NS.objects"),objj_msgSend(_5,"decodeObjectForKey:","NS.keys"));
}
})]);
p;17;NSMutableString.jt;279;@STATIC;1.0;t;261;
var _1=objj_allocateClassPair(CPObject,"NSMutableString"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_3,_4,_5){
with(_3){
return objj_msgSend(_5,"decodeObjectForKey:","NS.string");
}
})]);
p;16;NSNibConnector.jt;2659;@STATIC;1.0;I;23;AppKit/CPCibConnector.jI;30;AppKit/CPCibControlConnector.jI;29;AppKit/CPCibOutletConnector.jt;2543;
objj_executeFile("AppKit/CPCibConnector.j",false);
objj_executeFile("AppKit/CPCibControlConnector.j",false);
objj_executeFile("AppKit/CPCibOutletConnector.j",false);
NIB_CONNECTION_EQUIVALENCY_TABLE={};
var _1=objj_getClass("CPCibConnector");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPCibConnector\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPCibConnector").super_class},"init");
if(_3){
_source=objj_msgSend(_5,"decodeObjectForKey:","NSSource");
_destination=objj_msgSend(_5,"decodeObjectForKey:","NSDestination");
_label=objj_msgSend(_5,"decodeObjectForKey:","NSLabel");
var _6=objj_msgSend(_source,"UID"),_7=objj_msgSend(_destination,"UID");
if(_6 in NIB_CONNECTION_EQUIVALENCY_TABLE){
CPLog.trace("Swapped object: "+_source+" for object: "+NIB_CONNECTION_EQUIVALENCY_TABLE[_6]);
_source=NIB_CONNECTION_EQUIVALENCY_TABLE[_6];
}
if(_7 in NIB_CONNECTION_EQUIVALENCY_TABLE){
CPLog.trace("Swapped object: "+_destination+" for object: "+NIB_CONNECTION_EQUIVALENCY_TABLE[_7]);
_destination=NIB_CONNECTION_EQUIVALENCY_TABLE[_7];
}
CPLog.debug("Connection: "+objj_msgSend(_source,"description")+" "+objj_msgSend(_destination,"description")+" "+_label);
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPCibConnector,"NSNibConnector"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_8,_9,_a){
with(_8){
return objj_msgSend(_8,"NS_initWithCoder:",_a);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_b,_c){
with(_b){
return objj_msgSend(CPCibConnector,"class");
}
})]);
var _1=objj_allocateClassPair(CPCibControlConnector,"NSNibControlConnector"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_d,_e,_f){
with(_d){
return objj_msgSend(_d,"NS_initWithCoder:",_f);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_10,_11){
with(_10){
return objj_msgSend(CPCibControlConnector,"class");
}
})]);
var _1=objj_allocateClassPair(CPCibOutletConnector,"NSNibOutletConnector"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_12,_13,_14){
with(_12){
return objj_msgSend(_12,"NS_initWithCoder:",_14);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_15,_16){
with(_15){
return objj_msgSend(CPCibOutletConnector,"class");
}
})]);
p;15;NSPopUpButton.jt;2280;@STATIC;1.0;I;22;AppKit/CPPopUpButton.ji;8;NSMenu.jt;2222;
objj_executeFile("AppKit/CPPopUpButton.j",false);
objj_executeFile("NSMenu.j",true);
var _1=objj_getClass("CPPopUpButton");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPPopUpButton\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPPopUpButton").super_class},"NS_initWithCoder:",_5)){
var _6=objj_msgSend(_5,"decodeObjectForKey:","NSCell");
_menu=objj_msgSend(_6,"menu");
_selectedIndex=objj_msgSend(_6,"selectedIndex")||0;
objj_msgSend(_3,"setPullsDown:",objj_msgSend(_6,"pullsDown"));
_preferredEdge=objj_msgSend(_6,"preferredEdge");
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPPopUpButton,"NSPopUpButton"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_7,_8,_9){
with(_7){
return objj_msgSend(_7,"NS_initWithCoder:",_9);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(CPPopUpButton,"class");
}
})]);
var _1=objj_allocateClassPair(NSMenuItemCell,"NSPopUpButtonCell"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("pullsDown"),new objj_ivar("selectedIndex"),new objj_ivar("preferredEdge"),new objj_ivar("menu")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("pullsDown"),function(_c,_d){
with(_c){
return pullsDown;
}
}),new objj_method(sel_getUid("selectedIndex"),function(_e,_f){
with(_e){
return selectedIndex;
}
}),new objj_method(sel_getUid("preferredEdge"),function(_10,_11){
with(_10){
return preferredEdge;
}
}),new objj_method(sel_getUid("menu"),function(_12,_13){
with(_12){
return menu;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_14,_15,_16){
with(_14){
_14=objj_msgSendSuper({receiver:_14,super_class:objj_getClass("NSPopUpButtonCell").super_class},"initWithCoder:",_16);
if(_14){
pullsDown=objj_msgSend(_16,"decodeBoolForKey:","NSPullDown");
selectedIndex=objj_msgSend(_16,"decodeIntForKey:","NSSelectedIndex");
preferredEdge=objj_msgSend(_16,"decodeIntForKey:","NSPreferredEdge");
menu=objj_msgSend(_16,"decodeObjectForKey:","NSMenu");
}
return _14;
}
})]);
p;13;NSResponder.jt;931;@STATIC;1.0;I;20;AppKit/CPResponder.jt;888;
objj_executeFile("AppKit/CPResponder.j",false);
var _1=objj_getClass("CPResponder");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPResponder\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPResponder").super_class},"init");
if(_3){
objj_msgSend(_3,"setNextResponder:",objj_msgSend(_5,"decodeObjectForKey:","NSNextResponder"));
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPResponder,"NSResponder"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPResponder,"class");
}
})]);
p;12;NSScroller.jt;1679;@STATIC;1.0;I;19;AppKit/CPScroller.jt;1636;
objj_executeFile("AppKit/CPScroller.j",false);
var _1=objj_getClass("CPScroller");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPScroller\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPScroller").super_class},"NS_initWithCoder:",_5)){
_controlSize=CPRegularControlSize;
_knobProportion=1;
if(objj_msgSend(_5,"containsValueForKey:","NSPercent")){
_knobProportion=objj_msgSend(_5,"decodeFloatForKey:","NSPercent");
}
_value=0;
if(objj_msgSend(_5,"containsValueForKey:","NSCurValue")){
_value=objj_msgSend(_5,"decodeFloatForKey:","NSCurValue");
}
objj_msgSend(_3,"_calculateIsVertical");
var _6=objj_msgSend(_3,"isVertical");
if(CPStringFromSelector(objj_msgSend(_3,"action"))==="_doScroller:"){
if(_6){
objj_msgSend(_3,"setAction:",sel_getUid("_verticalScrollerDidScroll:"));
}else{
objj_msgSend(_3,"setAction:",sel_getUid("_horizontalScrollerDidScroll:"));
}
}
_partRects=[];
if(_6){
objj_msgSend(_3,"setFrameSize:",CGSizeMake(15,CGRectGetHeight(objj_msgSend(_3,"frame"))));
}else{
objj_msgSend(_3,"setFrameSize:",CGSizeMake(CGRectGetWidth(objj_msgSend(_3,"frame")),15));
}
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPScroller,"NSScroller"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_7,_8,_9){
with(_7){
return objj_msgSend(_7,"NS_initWithCoder:",_9);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(CPScroller,"class");
}
})]);
p;14;NSScrollView.jt;1478;@STATIC;1.0;I;21;AppKit/CPScrollView.jt;1433;
objj_executeFile("AppKit/CPScrollView.j",false);
var _1=objj_getClass("CPScrollView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPScrollView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPScrollView").super_class},"NS_initWithCoder:",_5)){
var _6=objj_msgSend(_5,"decodeIntForKey:","NSsFlags");
_verticalScroller=objj_msgSend(_5,"decodeObjectForKey:","NSVScroller");
_horizontalScroller=objj_msgSend(_5,"decodeObjectForKey:","NSHScroller");
_contentView=objj_msgSend(_5,"decodeObjectForKey:","NSContentView");
_headerClipView=objj_msgSend(_5,"decodeObjectForKey:","NSHeaderClipView");
_cornerView=objj_msgSend(_5,"decodeObjectForKey:","NSCornerView");
_hasVerticalScroller=!!(_6&(1<<4));
_hasHorizontalScroller=!!(_6&(1<<5));
_autohidesScrollers=!!(_6&(1<<9));
_verticalLineScroll=10;
_verticalPageScroll=10;
_horizontalLineScroll=10;
_horizontalPageScroll=10;
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPScrollView,"NSScrollView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_7,_8,_9){
with(_7){
return objj_msgSend(_7,"NS_initWithCoder:",_9);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(CPScrollView,"class");
}
})]);
p;15;NSSearchField.jt;1032;@STATIC;1.0;I;22;AppKit/CPSearchField.ji;13;NSTextField.jt;969;
objj_executeFile("AppKit/CPSearchField.j",false);
objj_executeFile("NSTextField.j",true);
var _1=objj_getClass("CPSearchField");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPSearchField\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPSearchField").super_class},"NS_initWithCoder:",_5);
if(_3){
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPSearchField,"NSSearchField"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPSearchField,"class");
}
})]);
var _1=objj_allocateClassPair(NSTextFieldCell,"NSSearchFieldCell"),_2=_1.isa;
objj_registerClassPair(_1);
p;19;NSSecureTextField.jt;664;@STATIC;1.0;I;26;AppKit/CPSecureTextField.ji;13;NSTextField.jt;597;
objj_executeFile("AppKit/CPSecureTextField.j",false);
objj_executeFile("NSTextField.j",true);
var _1=objj_allocateClassPair(CPSecureTextField,"NSSecureTextField"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_3,_4,_5){
with(_3){
return objj_msgSend(_3,"NS_initWithCoder:",_5);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_6,_7){
with(_6){
return objj_msgSend(CPSecureTextField,"class");
}
})]);
var _1=objj_allocateClassPair(NSTextFieldCell,"NSSecureTextFieldCell"),_2=_1.isa;
objj_registerClassPair(_1);
p;20;NSSegmentedControl.jt;4082;@STATIC;1.0;I;27;AppKit/CPSegmentedControl.jt;4031;
objj_executeFile("AppKit/CPSegmentedControl.j",false);
var _1=objj_getClass("CPSegmentedControl");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPSegmentedControl\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_segments=[];
_themeStates=[];
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPSegmentedControl").super_class},"NS_initWithCoder:",_5)){
var _6=objj_msgSend(_3,"frame"),_7=_6.size.width;
_6.size.width=0;
_6.origin.x=MAX(_6.origin.x-4,0);
objj_msgSend(_3,"setFrame:",_6);
var _8=objj_msgSend(_5,"decodeObjectForKey:","NSCell");
_segments=objj_msgSend(_8,"segments");
_selectedSegment=objj_msgSend(_8,"selectedSegment");
_segmentStyle=objj_msgSend(_8,"segmentStyle");
_trackingMode=objj_msgSend(_8,"trackingMode");
objj_msgSend(_3,"setValue:forThemeAttribute:",CPCenterTextAlignment,"alignment");
for(var i=0;i<_segments.length;i++){
_themeStates[i]=_segments[i].selected?CPThemeStateSelected:CPThemeStateNormal;
objj_msgSend(_3,"tileWithChangedSegment:",i);
}
_6.size.width=_7;
objj_msgSend(_3,"setFrame:",_6);
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPSegmentedControl,"NSSegmentedControl"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_9,_a,_b){
with(_9){
return objj_msgSend(_9,"NS_initWithCoder:",_b);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_c,_d){
with(_c){
return objj_msgSend(CPSegmentedControl,"class");
}
})]);
var _1=objj_allocateClassPair(NSActionCell,"NSSegmentedCell"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_segments"),new objj_ivar("_selectedSegment"),new objj_ivar("_segmentStyle"),new objj_ivar("_trackingMode")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("segments"),function(_e,_f){
with(_e){
return _segments;
}
}),new objj_method(sel_getUid("selectedSegment"),function(_10,_11){
with(_10){
return _selectedSegment;
}
}),new objj_method(sel_getUid("segmentStyle"),function(_12,_13){
with(_12){
return _segmentStyle;
}
}),new objj_method(sel_getUid("trackingMode"),function(_14,_15){
with(_14){
return _trackingMode;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_16,_17,_18){
with(_16){
if(_16=objj_msgSendSuper({receiver:_16,super_class:objj_getClass("NSSegmentedCell").super_class},"initWithCoder:",_18)){
_segments=objj_msgSend(_18,"decodeObjectForKey:","NSSegmentImages");
_selectedSegment=objj_msgSend(_18,"decodeIntForKey:","NSSelectedSegment")||-1;
_segmentStyle=objj_msgSend(_18,"decodeIntForKey:","NSSegmentStyle");
_trackingMode=objj_msgSend(_18,"decodeIntForKey:","NSTrackingMode")||CPSegmentSwitchTrackingSelectOne;
}
return _16;
}
})]);
var _1=objj_getClass("_CPSegmentItem");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"_CPSegmentItem\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_19,_1a,_1b){
with(_19){
if(_19=objj_msgSendSuper({receiver:_19,super_class:objj_getClass("_CPSegmentItem").super_class},"init")){
image=objj_msgSend(_1b,"decodeObjectForKey:","NSSegmentItemImage");
label=objj_msgSend(_1b,"decodeObjectForKey:","NSSegmentItemLabel");
menu=objj_msgSend(_1b,"decodeObjectForKey:","NSSegmentItemMenu");
selected=objj_msgSend(_1b,"decodeBoolForKey:","NSSegmentItemSelected");
enabled=!objj_msgSend(_1b,"decodeBoolForKey:","NSSegmentItemDisabled");
tag=objj_msgSend(_1b,"decodeIntForKey:","NSSegmentItemTag");
width=objj_msgSend(_1b,"decodeIntForKey:","NSSegmentItemWidth");
frame=CGRectMakeZero();
}
return _19;
}
})]);
var _1=objj_allocateClassPair(_CPSegmentItem,"NSSegmentItem"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_1c,_1d,_1e){
with(_1c){
return objj_msgSend(_1c,"NS_initWithCoder:",_1e);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_1f,_20){
with(_1f){
return objj_msgSend(_CPSegmentItem,"class");
}
})]);
p;7;NSSet.jt;564;@STATIC;1.0;I;21;Foundation/CPObject.jI;18;Foundation/CPSet.jt;497;
objj_executeFile("Foundation/CPObject.j",false);
objj_executeFile("Foundation/CPSet.j",false);
var _1=objj_allocateClassPair(CPObject,"NSSet"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_3,_4,_5){
with(_3){
return objj_msgSend(objj_msgSend(CPSet,"alloc"),"initWithArray:",objj_msgSend(_5,"decodeObjectForKey:","NS.objects"));
}
})]);
var _1=objj_allocateClassPair(NSSet,"NSMutableSet"),_2=_1.isa;
objj_registerClassPair(_1);
p;10;NSSlider.jt;2689;@STATIC;1.0;I;17;AppKit/CPSlider.ji;10;NSSlider.jt;2633;
objj_executeFile("AppKit/CPSlider.j",false);
objj_executeFile("NSSlider.j",true);
var _1=objj_getClass("CPSlider");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPSlider\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
var _6=objj_msgSend(_5,"decodeObjectForKey:","NSCell");
_minValue=objj_msgSend(_6,"minValue");
_maxValue=objj_msgSend(_6,"maxValue");
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPSlider").super_class},"NS_initWithCoder:",_5);
if(_3){
_altIncrementValue=objj_msgSend(_6,"altIncrementValue");
objj_msgSend(_3,"setSliderType:",objj_msgSend(_6,"sliderType"));
if(objj_msgSend(_3,"sliderType")===CPCircularSlider){
var _7=objj_msgSend(_3,"frame");
objj_msgSend(_3,"setFrameSize:",CGSizeMake(_7.size.width+4,_7.size.height+2));
}
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPSlider,"NSSlider"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_8,_9,_a){
with(_8){
return objj_msgSend(_8,"NS_initWithCoder:",_a);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_b,_c){
with(_b){
return objj_msgSend(CPSlider,"class");
}
})]);
var _1=objj_allocateClassPair(NSCell,"NSSliderCell"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_minValue"),new objj_ivar("_maxValue"),new objj_ivar("_altIncrementValue"),new objj_ivar("_vertical"),new objj_ivar("_sliderType")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("minValue"),function(_d,_e){
with(_d){
return _minValue;
}
}),new objj_method(sel_getUid("maxValue"),function(_f,_10){
with(_f){
return _maxValue;
}
}),new objj_method(sel_getUid("altIncrementValue"),function(_11,_12){
with(_11){
return _altIncrementValue;
}
}),new objj_method(sel_getUid("isVertical"),function(_13,_14){
with(_13){
return _vertical;
}
}),new objj_method(sel_getUid("sliderType"),function(_15,_16){
with(_15){
return _sliderType;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_17,_18,_19){
with(_17){
_17=objj_msgSendSuper({receiver:_17,super_class:objj_getClass("NSSliderCell").super_class},"initWithCoder:",_19);
if(_17){
_objectValue=objj_msgSend(_19,"decodeDoubleForKey:","NSValue");
_minValue=objj_msgSend(_19,"decodeDoubleForKey:","NSMinValue");
_maxValue=objj_msgSend(_19,"decodeDoubleForKey:","NSMaxValue");
_altIncrementValue=objj_msgSend(_19,"decodeDoubleForKey:","NSAltIncValue");
_isVertical=objj_msgSend(_19,"decodeBoolForKey:","NSVertical");
_sliderType=objj_msgSend(_19,"decodeIntForKey:","NSSliderType")||0;
}
return _17;
}
})]);
p;13;NSSplitView.jt;993;@STATIC;1.0;I;20;AppKit/CPSplitView.jt;950;
objj_executeFile("AppKit/CPSplitView.j",false);
var _1=objj_getClass("CPSplitView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPSplitView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPSplitView").super_class},"NS_initWithCoder:",_5)){
_isVertical=objj_msgSend(_5,"decodeBoolForKey:","NSIsVertical");
_isPaneSplitter=objj_msgSend(_5,"decodeIntForKey:","NSDividerStyle")==2?YES:NO;
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPSplitView,"NSSplitView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPSplitView,"class");
}
})]);
p;15;NSTableColumn.jt;1858;@STATIC;1.0;I;22;AppKit/CPTableColumn.jI;26;AppKit/CPTableHeaderView.jt;1781;
objj_executeFile("AppKit/CPTableColumn.j",false);
objj_executeFile("AppKit/CPTableHeaderView.j",false);
var _1=objj_getClass("CPTableColumn");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPTableColumn\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSend(_3,"init");
if(_3){
_identifier=objj_msgSend(_5,"decodeObjectForKey:","NSIdentifier");
_dataView=objj_msgSend(objj_msgSend(CPTextField,"alloc"),"initWithFrame:",CPRectMakeZero());
objj_msgSend(_dataView,"setValue:forThemeAttribute:inState:",objj_msgSend(CPColor,"whiteColor"),"text-color",CPThemeStateHighlighted);
var _6=objj_msgSend(_5,"decodeObjectForKey:","NSHeaderCell"),_7=objj_msgSend(objj_msgSend(_CPTableColumnHeaderView,"alloc"),"initWithFrame:",CPRectMakeZero());
objj_msgSend(_headerView,"setStringValue:",objj_msgSend(_6,"objectValue"));
objj_msgSend(_headerView,"setFont:",objj_msgSend(_6,"font"));
objj_msgSend(_3,"setHeaderView:",_headerView);
_width=objj_msgSend(_5,"decodeFloatForKey:","NSWidth");
_minWidth=objj_msgSend(_5,"decodeFloatForKey:","NSMinWidth");
_maxWidth=objj_msgSend(_5,"decodeFloatForKey:","NSMaxWidth");
_resizingMask=objj_msgSend(_5,"decodeBoolForKey:","NSIsResizable");
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPTableColumn,"NSTableColumn"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_8,_9,_a){
with(_8){
return objj_msgSend(_8,"NS_initWithCoder:",_a);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_b,_c){
with(_b){
return objj_msgSend(CPTableColumn,"class");
}
})]);
var _1=objj_allocateClassPair(NSActionCell,"NSTableHeaderCell"),_2=_1.isa;
objj_registerClassPair(_1);
p;19;NSTableHeaderView.jt;1108;@STATIC;1.0;I;26;AppKit/CPTableHeaderView.jt;1058;
objj_executeFile("AppKit/CPTableHeaderView.j",false);
var _1=objj_getClass("CPTableHeaderView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPTableHeaderView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPTableHeaderView").super_class},"NS_initWithCoder:",_5)){
_tableView=objj_msgSend(_5,"decodeObjectForKey:","NSTableView");
objj_msgSend(_3,"setBackgroundColor:",objj_msgSend(CPColor,"colorWithPatternImage:",CPAppKitImage("tableview-headerview.png",CGSizeMake(1,22))));
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPTableHeaderView,"NSTableHeaderView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPTableHeaderView,"class");
}
})]);
p;13;NSTableView.jt;1775;@STATIC;1.0;I;20;AppKit/CPTableView.jt;1731;
objj_executeFile("AppKit/CPTableView.j",false);
var _1=objj_getClass("CPTableView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPTableView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPTableView").super_class},"NS_initWithCoder:",_5);
if(_3){
var _6=objj_msgSend(_5,"decodeIntForKey:","NSTvFlags");
_headerView=objj_msgSend(_5,"decodeObjectForKey:","NSHeaderView");
_cornerView=objj_msgSend(_5,"decodeObjectForKey:","NSCornerView");
_tableColumns=objj_msgSend(_5,"decodeObjectForKey:","NSTableColumns");
objj_msgSend(_tableColumns,"makeObjectsPerformSelector:withObject:",sel_getUid("setTableView:"),_3);
_rowHeight=objj_msgSend(_5,"decodeFloatForKey:","NSRowHeight");
if(_rowHeight==17){
_rowHeight=23;
}
_intercellSpacing=CGSizeMake(0,0);
_gridColor=objj_msgSend(_5,"decodeObjectForKey:","NSGridColor");
_gridStyleMask=objj_msgSend(_5,"decodeIntForKey:","NSGridStyleMask");
_usesAlternatingRowBackgroundColors=(_6&8388608)?YES:NO;
_allowsMultipleSelection=(_6&134217728)?YES:NO;
_allowsEmptySelection=(_6&268435456)?YES:NO;
_allowsColumnSelection=(_6&67108864)?YES:NO;
_allowsColumnResizing=(_6&1073741824)?YES:NO;
_allowsColumnReordering=(_6&2147483648)?YES:NO;
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPTableView,"NSTableView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_7,_8,_9){
with(_7){
return objj_msgSend(_7,"NS_initWithCoder:",_9);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(CPTableView,"class");
}
})]);
p;11;NSTabView.jt;1129;@STATIC;1.0;I;18;AppKit/CPTabView.ji;15;NSTabViewItem.jt;1067;
objj_executeFile("AppKit/CPTabView.j",false);
objj_executeFile("NSTabViewItem.j",true);
var _1=objj_getClass("CPTabView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPTabView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPTabView").super_class},"NS_initWithCoder:",_5)){
var _6=objj_msgSend(_5,"decodeObjectForKey:","NSTvFlags");
_tabViewType=_6&7;
_tabViewItems=objj_msgSend(_5,"decodeObjectForKey:","NSTabViewItems");
_selectedTabViewItem=objj_msgSend(_5,"decodeObjectForKey:","NSSelectedTabViewItem");
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPTabView,"NSTabView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_7,_8,_9){
with(_7){
return objj_msgSend(_7,"NS_initWithCoder:",_9);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(CPTabView,"class");
}
})]);
p;15;NSTabViewItem.jt;1027;@STATIC;1.0;I;22;AppKit/CPTabViewItem.jt;982;
objj_executeFile("AppKit/CPTabViewItem.j",false);
var _1=objj_getClass("CPTabViewItem");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPTabViewItem\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPTabViewItem").super_class},"init")){
_identifier=objj_msgSend(_5,"decodeObjectForKey:","NSIdentifier");
_label=objj_msgSend(_5,"decodeObjectForKey:","NSLabel");
_view=objj_msgSend(_5,"decodeObjectForKey:","NSView");
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPTabViewItem,"NSTabViewItem"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPTabViewItem,"class");
}
})]);
p;13;NSTextField.jt;3574;@STATIC;1.0;I;20;AppKit/CPTextField.ji;11;NSControl.ji;8;NSCell.jt;3502;
objj_executeFile("AppKit/CPTextField.j",false);
objj_executeFile("NSControl.j",true);
objj_executeFile("NSCell.j",true);
var _1=objj_getClass("CPTextField");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPTextField\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPTextField").super_class},"NS_initWithCoder:",_5);
if(_3){
var _6=objj_msgSend(_5,"decodeObjectForKey:","NSCell");
objj_msgSend(_3,"sendActionOn:",CPKeyUpMask|CPKeyDownMask);
objj_msgSend(_3,"setEditable:",objj_msgSend(_6,"isEditable"));
objj_msgSend(_3,"setSelectable:",objj_msgSend(_6,"isSelectable"));
objj_msgSend(_3,"setBordered:",objj_msgSend(_6,"isBordered"));
objj_msgSend(_3,"setBezeled:",objj_msgSend(_6,"isBezeled"));
objj_msgSend(_3,"setBezelStyle:",objj_msgSend(_6,"bezelStyle"));
objj_msgSend(_3,"setDrawsBackground:",objj_msgSend(_6,"drawsBackground"));
objj_msgSend(_3,"setTextFieldBackgroundColor:",objj_msgSend(_6,"backgroundColor"));
objj_msgSend(_3,"setPlaceholderString:",objj_msgSend(_6,"placeholderString"));
objj_msgSend(_3,"setTextColor:",objj_msgSend(_6,"textColor"));
var _7=objj_msgSend(_3,"frame");
objj_msgSend(_3,"setFrameOrigin:",CGPointMake(_7.origin.x-4,_7.origin.y-4));
objj_msgSend(_3,"setFrameSize:",CGSizeMake(_7.size.width+8,_7.size.height+8));
CPLog.debug(objj_msgSend(_3,"stringValue")+" => isBordered="+objj_msgSend(_3,"isBordered")+", isBezeled="+objj_msgSend(_3,"isBezeled")+", bezelStyle="+objj_msgSend(_3,"bezelStyle")+"("+objj_msgSend(_6,"stringValue")+", "+objj_msgSend(_6,"placeholderString")+")");
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPTextField,"NSTextField"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_8,_9,_a){
with(_8){
return objj_msgSend(_8,"NS_initWithCoder:",_a);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_b,_c){
with(_b){
return objj_msgSend(CPTextField,"class");
}
})]);
var _1=objj_allocateClassPair(NSCell,"NSTextFieldCell"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_bezelStyle"),new objj_ivar("_drawsBackground"),new objj_ivar("_backgroundColor"),new objj_ivar("_textColor"),new objj_ivar("_placeholderString")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("bezelStyle"),function(_d,_e){
with(_d){
return _bezelStyle;
}
}),new objj_method(sel_getUid("drawsBackground"),function(_f,_10){
with(_f){
return _drawsBackground;
}
}),new objj_method(sel_getUid("backgroundColor"),function(_11,_12){
with(_11){
return _backgroundColor;
}
}),new objj_method(sel_getUid("textColor"),function(_13,_14){
with(_13){
return _textColor;
}
}),new objj_method(sel_getUid("placeholderString"),function(_15,_16){
with(_15){
return _placeholderString;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_17,_18,_19){
with(_17){
_17=objj_msgSendSuper({receiver:_17,super_class:objj_getClass("NSTextFieldCell").super_class},"initWithCoder:",_19);
if(_17){
_bezelStyle=objj_msgSend(_19,"decodeObjectForKey:","NSTextBezelStyle")||CPTextFieldSquareBezel;
_drawsBackground=objj_msgSend(_19,"decodeBoolForKey:","NSDrawsBackground");
_backgroundColor=objj_msgSend(_19,"decodeObjectForKey:","NSBackgroundColor");
_textColor=objj_msgSend(_19,"decodeObjectForKey:","NSTextColor");
_placeholderString=objj_msgSend(_19,"decodeObjectForKey:","NSPlaceholderString");
}
return _17;
}
})]);
p;11;NSToolbar.jt;1546;@STATIC;1.0;I;18;AppKit/CPToolbar.jt;1504;
objj_executeFile("AppKit/CPToolbar.j",false);
var _1=objj_getClass("CPToolbar");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPToolbar\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3){
_identifier=objj_msgSend(_5,"decodeObjectForKey:","NSToolbarIdentifier");
_displayMode=objj_msgSend(_5,"decodeIntForKey:","NSToolbarDisplayMode");
_showsBaselineSeparator=objj_msgSend(_5,"decodeBoolForKey:","NSToolbarShowsBaselineSeparator");
_allowsUserCustomization=objj_msgSend(_5,"decodeBoolForKey:","NSToolbarAllowsUserCustomization");
_isVisible=objj_msgSend(_5,"decodeBoolForKey:","NSToolbarPrefersToBeShown");
_identifiedItems=objj_msgSend(_5,"decodeObjectForKey:","NSToolbarIBIdentifiedItems");
_defaultItems=objj_msgSend(_5,"decodeObjectForKey:","NSToolbarIBDefaultItems");
_allowedItems=objj_msgSend(_5,"decodeObjectForKey:","NSToolbarIBAllowedItems");
_selectableItems=objj_msgSend(_5,"decodeObjectForKey:","NSToolbarIBSelectableItems");
_delegate=objj_msgSend(_5,"decodeObjectForKey:","NSToolbarDelegate");
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPToolbar,"NSToolbar"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPToolbar,"class");
}
})]);
p;28;NSToolbarFlexibleSpaceItem.jt;417;@STATIC;1.0;I;36;AppKit/_CPToolbarFlexibleSpaceItem.jt;358;
objj_executeFile("AppKit/_CPToolbarFlexibleSpaceItem.j",false);
var _1=objj_allocateClassPair(_CPToolbarFlexibleSpaceItem,"NSToolbarFlexibleSpaceItem"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("classForKeyedArchiver"),function(_3,_4){
with(_3){
return objj_msgSend(_CPToolbarFlexibleSpaceItem,"class");
}
})]);
p;15;NSToolbarItem.jt;2669;@STATIC;1.0;I;22;AppKit/CPToolbarItem.jt;2623;
objj_executeFile("AppKit/CPToolbarItem.j",false);
NS_CPToolbarItemIdentifierMap={"NSToolbarSeparatorItem":CPToolbarSeparatorItemIdentifier,"NSToolbarSpaceItem":CPToolbarSpaceItemIdentifier,"NSToolbarFlexibleSpaceItem":CPToolbarFlexibleSpaceItemIdentifier,"NSToolbarShowColorsItem":CPToolbarShowColorsItemIdentifier,"NSToolbarShowFontsItem":CPToolbarShowFontsItemIdentifier,"NSToolbarCustomizeToolbarItem":CPToolbarCustomizeToolbarItemIdentifier,"NSToolbarPrintItem":CPToolbarPrintItemIdentifier};
var _1=objj_getClass("CPToolbarItem");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPToolbarItem\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPToolbarItem").super_class},"init");
if(_3){
var _6=objj_msgSend(_5,"decodeObjectForKey:","NSToolbarItemIdentifier");
_itemIdentifier=NS_CPToolbarItemIdentifierMap[_6]||_6;
_minSize=objj_msgSend(_5,"decodeSizeForKey:","NSToolbarItemMinSize")||CGSizeMakeZero();
_maxSize=objj_msgSend(_5,"decodeSizeForKey:","NSToolbarItemMaxSize")||CGSizeMakeZero();
objj_msgSend(_3,"setLabel:",objj_msgSend(_5,"decodeObjectForKey:","NSToolbarItemLabel"));
objj_msgSend(_3,"setPaletteLabel:",objj_msgSend(_5,"decodeObjectForKey:","NSToolbarItemPaletteLabel"));
objj_msgSend(_3,"setToolTip:",objj_msgSend(_5,"decodeObjectForKey:","NSToolbarItemToolTip"));
objj_msgSend(_3,"setTag:",objj_msgSend(_5,"decodeObjectForKey:","NSToolbarItemTag"));
objj_msgSend(_3,"setTarget:",objj_msgSend(_5,"decodeObjectForKey:","NSToolbarItemTarget"));
objj_msgSend(_3,"setAction:",CPSelectorFromString(objj_msgSend(_5,"decodeObjectForKey:","NSToolbarItemAction")));
objj_msgSend(_3,"setEnabled:",objj_msgSend(_5,"decodeBoolForKey:","NSToolbarItemEnabled"));
objj_msgSend(_3,"setImage:",objj_msgSend(_5,"decodeBoolForKey:","NSToolbarItemImage"));
objj_msgSend(_3,"setView:",objj_msgSend(_5,"decodeObjectForKey:","NSToolbarItemView"));
objj_msgSend(_3,"setVisibilityPriority:",objj_msgSend(_5,"decodeIntForKey:","NSToolbarItemVisibilityPriority"));
objj_msgSend(_3,"setAutovalidates:",objj_msgSend(_5,"decodeBoolForKey:","NSToolbarItemAutovalidates"));
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPToolbarItem,"NSToolbarItem"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_7,_8,_9){
with(_7){
return objj_msgSend(_7,"NS_initWithCoder:",_9);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_a,_b){
with(_a){
return objj_msgSend(CPToolbarItem,"class");
}
})]);
p;24;NSToolbarSeparatorItem.jt;397;@STATIC;1.0;I;32;AppKit/_CPToolbarSeparatorItem.jt;342;
objj_executeFile("AppKit/_CPToolbarSeparatorItem.j",false);
var _1=objj_allocateClassPair(_CPToolbarSeparatorItem,"NSToolbarSeparatorItem"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("classForKeyedArchiver"),function(_3,_4){
with(_3){
return objj_msgSend(_CPToolbarSeparatorItem,"class");
}
})]);
p;25;NSToolbarShowColorsItem.jt;402;@STATIC;1.0;I;33;AppKit/_CPToolbarShowColorsItem.jt;346;
objj_executeFile("AppKit/_CPToolbarShowColorsItem.j",false);
var _1=objj_allocateClassPair(_CPToolbarShowColorsItem,"NSToolbarShowColorsItem"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("classForKeyedArchiver"),function(_3,_4){
with(_3){
return objj_msgSend(_CPToolbarShowColorsItem,"class");
}
})]);
p;20;NSToolbarSpaceItem.jt;377;@STATIC;1.0;I;28;AppKit/_CPToolbarSpaceItem.jt;326;
objj_executeFile("AppKit/_CPToolbarSpaceItem.j",false);
var _1=objj_allocateClassPair(_CPToolbarSpaceItem,"NSToolbarSpaceItem"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("classForKeyedArchiver"),function(_3,_4){
with(_3){
return objj_msgSend(_CPToolbarSpaceItem,"class");
}
})]);
p;8;NSView.jt;1820;@STATIC;1.0;I;15;AppKit/CPView.jt;1781;
objj_executeFile("AppKit/CPView.j",false);
var _1=objj_getClass("CPView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_frame=CGRectMakeZero();
if(objj_msgSend(_5,"containsValueForKey:","NSFrame")){
_frame=objj_msgSend(_5,"decodeRectForKey:","NSFrame");
}else{
if(objj_msgSend(_5,"containsValueForKey:","NSFrameSize")){
_frame.size=objj_msgSend(_5,"decodeSizeForKey:","NSFrameSize");
}
}
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPView").super_class},"NS_initWithCoder:",_5);
if(_3){
_tag=-1;
if(objj_msgSend(_5,"containsValueForKey:","NSTag")){
_tag=objj_msgSend(_5,"decodeIntForKey:","NSTag");
}
_bounds=CGRectMake(0,0,CGRectGetWidth(_frame),CGRectGetHeight(_frame));
_window=objj_msgSend(_5,"decodeObjectForKey:","NSWindow");
_superview=objj_msgSend(_5,"decodeObjectForKey:","NSSuperview");
_subviews=objj_msgSend(_5,"decodeObjectForKey:","NSSubviews");
if(!_subviews){
_subviews=[];
}
var _6=objj_msgSend(_5,"decodeIntForKey:","NSvFlags");
_autoresizingMask=_6&63;
_autoresizesSubviews=_6&(1<<8);
_hitTests=YES;
_isHidden=NO;
_opacity=1;
_themeAttributes={};
_themeState=CPThemeStateNormal;
objj_msgSend(_3,"_loadThemeAttributes");
}
return _3;
}
}),new objj_method(sel_getUid("NS_isFlipped"),function(_7,_8){
with(_7){
return NO;
}
})]);
var _1=objj_allocateClassPair(CPView,"NSView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_9,_a,_b){
with(_9){
return objj_msgSend(_9,"NS_initWithCoder:",_b);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_c,_d){
with(_c){
return objj_msgSend(CPView,"class");
}
})]);
p;18;NSViewController.jt;1127;@STATIC;1.0;I;25;AppKit/CPViewController.jt;1078;
objj_executeFile("AppKit/CPViewController.j",false);
var _1=objj_getClass("CPViewController");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPViewController\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPViewController").super_class},"NS_initWithCoder:",_5);
if(_3){
_title=objj_msgSend(_5,"decodeObjectForKey:","NSTitle");
_cibName=objj_msgSend(_5,"decodeObjectForKey:","NSNibName");
_cibBundle=objj_msgSend(CPBundle,"bundleWithPath:",objj_msgSend(_5,"decodeObjectForKey:","NSNibBundleIdentifier"));
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPViewController,"NSViewController"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPViewController,"class");
}
})]);
p;18;NSWindowTemplate.jt;2381;@STATIC;1.0;I;29;AppKit/_CPCibWindowTemplate.jt;2328;
objj_executeFile("AppKit/_CPCibWindowTemplate.j",false);
var _1=0,_2=1,_3=2,_4=4,_5=8,_6=16,_7=256,_8=8192;
var _9=objj_getClass("_CPCibWindowTemplate");
if(!_9){
throw new SyntaxError("*** Could not find definition for class \"_CPCibWindowTemplate\"");
}
var _a=_9.isa;
class_addMethods(_9,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_b,_c,_d){
with(_b){
_b=objj_msgSendSuper({receiver:_b,super_class:objj_getClass("_CPCibWindowTemplate").super_class},"init");
if(_b){
if(objj_msgSend(_d,"containsValueForKey:","NSMinSize")){
_minSize=objj_msgSend(_d,"decodeSizeForKey:","NSMinSize");
}
if(objj_msgSend(_d,"containsValueForKey:","NSMaxSize")){
_maxSize=objj_msgSend(_d,"decodeSizeForKey:","NSMaxSize");
}
_screenRect=objj_msgSend(_d,"decodeRectForKey:","NSScreenRect");
_viewClass=objj_msgSend(_d,"decodeObjectForKey:","NSViewClass");
_wtFlags=objj_msgSend(_d,"decodeIntForKey:","NSWTFlags");
_windowBacking=objj_msgSend(_d,"decodeIntForKey:","NSWindowBacking");
_windowClass=CP_NSMapClassName(objj_msgSend(_d,"decodeObjectForKey:","NSWindowClass"));
_windowRect=objj_msgSend(_d,"decodeRectForKey:","NSWindowRect");
_windowStyleMask=objj_msgSend(_d,"decodeIntForKey:","NSWindowStyleMask");
_windowTitle=objj_msgSend(_d,"decodeObjectForKey:","NSWindowTitle");
_windowView=objj_msgSend(_d,"decodeObjectForKey:","NSWindowView");
_windowRect.origin.y=_screenRect.size.height-_windowRect.origin.y-_windowRect.size.height;
if(_windowStyleMask===_1){
_windowStyleMask=CPBorderlessWindowMask;
}else{
_windowStyleMask=(_windowStyleMask&_2?CPTitledWindowMask:0)|(_windowStyleMask&_3?CPClosableWindowMask:0)|(_windowStyleMask&_4?CPMiniaturizableWindowMask:0)|(_windowStyleMask&_5?CPResizableWindowMask:0)|(_windowStyleMask&_7?_7:0)|(_windowStyleMask&_8?CPHUDBackgroundWindowMask:0);
}
_windowIsFullBridge=objj_msgSend(_d,"decodeObjectForKey:","NSFrameAutosaveName")==="CPBorderlessBridgeWindowMask";
}
return _b;
}
})]);
var _9=objj_allocateClassPair(_CPCibWindowTemplate,"NSWindowTemplate"),_a=_9.isa;
objj_registerClassPair(_9);
class_addMethods(_9,[new objj_method(sel_getUid("initWithCoder:"),function(_e,_f,_10){
with(_e){
return objj_msgSend(_e,"NS_initWithCoder:",_10);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_11,_12){
with(_11){
return objj_msgSend(_CPCibWindowTemplate,"class");
}
})]);
p;9;WebView.jt;830;@STATIC;1.0;I;18;AppKit/CPWebView.jt;789;
objj_executeFile("AppKit/CPWebView.j",false);
var _1=objj_getClass("CPWebView");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPWebView\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("NS_initWithCoder:"),function(_3,_4,_5){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPWebView").super_class},"NS_initWithCoder:",_5)){
}
return _3;
}
})]);
var _1=objj_allocateClassPair(CPWebView,"WebView"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"NS_initWithCoder:",_8);
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_9,_a){
with(_9){
return objj_msgSend(CPWebView,"class");
}
})]);
e;