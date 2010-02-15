@STATIC;1.0;u;27;Resources/dark-checkers.png61;mhtml:IE7.environment/BlendKit.sj!Resources/dark-checkers.pngu;28;Resources/light-checkers.png62;mhtml:IE7.environment/BlendKit.sj!Resources/light-checkers.pngu;23;Resources/selection.png57;mhtml:IE7.environment/BlendKit.sj!Resources/selection.pngp;22;BKShowcaseController.jI;16;AppKit/CPTheme.jI;15;AppKit/CPView.jc;15346;
var _1=176;
var _2="BKLearnMoreToolbarItemIdentifier",_3="BKStateToolbarItemIdentifier",_4="BKBackgroundColorToolbarItemIdentifier";
var _5=objj_allocateClassPair(CPObject,"BKShowcaseController"),_6=_5.isa;
class_addIvars(_5,[new objj_ivar("_themeDescriptorClasses"),new objj_ivar("_themesCollectionView"),new objj_ivar("_themedObjectsCollectionView")]);
objj_registerClassPair(_5);
objj_addClassForBundle(_5,objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));
class_addMethods(_5,[new objj_method(sel_getUid("applicationDidFinishLaunching:"),function(_7,_8,_9){
with(_7){
_themeDescriptorClasses=objj_msgSend(BKThemeDescriptor,"allThemeDescriptorClasses");
var _a=objj_msgSend(objj_msgSend(CPWindow,"alloc"),"initWithContentRect:styleMask:",CGRectMakeZero(),CPBorderlessBridgeWindowMask),_b=objj_msgSend(objj_msgSend(CPToolbar,"alloc"),"initWithIdentifier:","Toolbar");
objj_msgSend(_b,"setDelegate:",_7);
objj_msgSend(_a,"setToolbar:",_b);
var _c=objj_msgSend(_a,"contentView"),_d=objj_msgSend(_c,"bounds"),_e=objj_msgSend(objj_msgSend(CPSplitView,"alloc"),"initWithFrame:",_d);
objj_msgSend(_e,"setIsPaneSplitter:",YES);
objj_msgSend(_e,"setAutoresizingMask:",CPViewWidthSizable|CPViewHeightSizable);
objj_msgSend(_c,"addSubview:",_e);
var _f=objj_msgSend(CPTextField,"labelWithTitle:","THEMES");
objj_msgSend(_f,"setFont:",objj_msgSend(CPFont,"boldSystemFontOfSize:",11));
objj_msgSend(_f,"setTextColor:",objj_msgSend(CPColor,"colorWithCalibratedRed:green:blue:alpha:",93/255,93/255,93/255,1));
objj_msgSend(_f,"setTextShadowColor:",objj_msgSend(CPColor,"colorWithCalibratedRed:green:blue:alpha:",225/255,255/255,255/255,0.7));
objj_msgSend(_f,"setTextShadowOffset:",CGSizeMake(0,1));
objj_msgSend(_f,"sizeToFit");
objj_msgSend(_f,"setFrameOrigin:",CGPointMake(5,4));
var _10=objj_msgSend(objj_msgSend(CPCollectionViewItem,"alloc"),"init");
objj_msgSend(_10,"setView:",objj_msgSend(objj_msgSend(BKThemeDescriptorCell,"alloc"),"init"));
_themesCollectionView=objj_msgSend(objj_msgSend(CPCollectionView,"alloc"),"initWithFrame:",CGRectMake(0,0,_1,CGRectGetHeight(_d)));
objj_msgSend(_themesCollectionView,"setDelegate:",_7);
objj_msgSend(_themesCollectionView,"setItemPrototype:",_10);
objj_msgSend(_themesCollectionView,"setMinItemSize:",CGSizeMake(20,36));
objj_msgSend(_themesCollectionView,"setMaxItemSize:",CGSizeMake(10000000,36));
objj_msgSend(_themesCollectionView,"setMaxNumberOfColumns:",1);
objj_msgSend(_themesCollectionView,"setContent:",_themeDescriptorClasses);
objj_msgSend(_themesCollectionView,"setAutoresizingMask:",CPViewWidthSizable);
objj_msgSend(_themesCollectionView,"setVerticalMargin:",0);
objj_msgSend(_themesCollectionView,"setSelectable:",YES);
objj_msgSend(_themesCollectionView,"setFrameOrigin:",CGPointMake(0,20));
objj_msgSend(_themesCollectionView,"setAutoresizingMask:",CPViewWidthSizable);
var _11=objj_msgSend(objj_msgSend(CPScrollView,"alloc"),"initWithFrame:",CGRectMake(0,0,_1,CGRectGetHeight(_d))),_c=objj_msgSend(_11,"contentView");
objj_msgSend(_11,"setAutohidesScrollers:",YES);
objj_msgSend(_11,"setDocumentView:",_themesCollectionView);
objj_msgSend(_c,"setBackgroundColor:",objj_msgSend(CPColor,"colorWithRed:green:blue:alpha:",212/255,221/255,230/255,1));
objj_msgSend(_c,"addSubview:",_f);
objj_msgSend(_e,"addSubview:",_11);
_themedObjectsCollectionView=objj_msgSend(objj_msgSend(CPCollectionView,"alloc"),"initWithFrame:",CGRectMake(0,0,CGRectGetWidth(_d)-_1-1,10));
var _12=objj_msgSend(objj_msgSend(CPCollectionViewItem,"alloc"),"init");
objj_msgSend(_12,"setView:",objj_msgSend(objj_msgSend(BKShowcaseCell,"alloc"),"init"));
objj_msgSend(_themedObjectsCollectionView,"setItemPrototype:",_12);
objj_msgSend(_themedObjectsCollectionView,"setVerticalMargin:",20);
objj_msgSend(_themedObjectsCollectionView,"setAutoresizingMask:",CPViewWidthSizable);
var _11=objj_msgSend(objj_msgSend(CPScrollView,"alloc"),"initWithFrame:",CGRectMake(_1+1,0,CGRectGetWidth(_d)-_1-1,CGRectGetHeight(_d)));
objj_msgSend(_11,"setHasHorizontalScroller:",NO);
objj_msgSend(_11,"setAutohidesScrollers:",YES);
objj_msgSend(_11,"setAutoresizingMask:",CPViewWidthSizable|CPViewHeightSizable);
objj_msgSend(_11,"setDocumentView:",_themedObjectsCollectionView);
objj_msgSend(_e,"addSubview:",_11);
objj_msgSend(_themesCollectionView,"setSelectionIndexes:",objj_msgSend(CPIndexSet,"indexSetWithIndex:",0));
objj_msgSend(_a,"setFullBridge:",YES);
objj_msgSend(_a,"makeKeyAndOrderFront:",_7);
}
}),new objj_method(sel_getUid("collectionViewDidChangeSelection:"),function(_13,_14,_15){
with(_13){
var _16=_themeDescriptorClasses[objj_msgSend(objj_msgSend(_15,"selectionIndexes"),"firstIndex")],_17=objj_msgSend(_16,"itemSize");
_17.width=MAX(100,_17.width+20);
_17.height=MAX(100,_17.height+30);
objj_msgSend(_themedObjectsCollectionView,"setMinItemSize:",_17);
objj_msgSend(_themedObjectsCollectionView,"setMaxItemSize:",_17);
objj_msgSend(_themedObjectsCollectionView,"setContent:",objj_msgSend(_16,"themedObjectTemplates"));
objj_msgSend(BKShowcaseCell,"setBackgroundColor:",objj_msgSend(_16,"showcaseBackgroundColor"));
}
}),new objj_method(sel_getUid("hasLearnMoreURL"),function(_18,_19){
with(_18){
return objj_msgSend(objj_msgSend(CPBundle,"mainBundle"),"objectForInfoDictionaryKey:","BKLearnMoreURL");
}
}),new objj_method(sel_getUid("toolbarAllowedItemIdentifiers:"),function(_1a,_1b,_1c){
with(_1a){
return [_2,CPToolbarSpaceItemIdentifier,CPToolbarFlexibleSpaceItemIdentifier,_4,_3];
}
}),new objj_method(sel_getUid("toolbarDefaultItemIdentifiers:"),function(_1d,_1e,_1f){
with(_1d){
var _20=[CPToolbarFlexibleSpaceItemIdentifier,_4,_3];
if(objj_msgSend(_1d,"hasLearnMoreURL")){
_20=[_2].concat(_20);
}
return _20;
}
}),new objj_method(sel_getUid("toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:"),function(_21,_22,_23,_24,_25){
with(_21){
var _26=objj_msgSend(objj_msgSend(CPToolbarItem,"alloc"),"initWithItemIdentifier:",_24);
objj_msgSend(_26,"setTarget:",_21);
if(_24===_3){
var _27=objj_msgSend(CPPopUpButton,"buttonWithTitle:","Enabled");
objj_msgSend(_27,"addItemWithTitle:","Disabled");
objj_msgSend(_26,"setView:",_27);
objj_msgSend(_26,"setTarget:",nil);
objj_msgSend(_26,"setAction:",sel_getUid("changeState:"));
objj_msgSend(_26,"setLabel:","State");
var _28=CGRectGetWidth(objj_msgSend(_27,"frame"));
objj_msgSend(_26,"setMinSize:",CGSizeMake(_28+20,24));
objj_msgSend(_26,"setMaxSize:",CGSizeMake(_28+20,24));
}else{
if(_24===_4){
var _27=objj_msgSend(CPPopUpButton,"buttonWithTitle:","Window Background");
objj_msgSend(_27,"addItemWithTitle:","Light Checkers");
objj_msgSend(_27,"addItemWithTitle:","Dark Checkers");
objj_msgSend(_27,"addItemWithTitle:","White");
objj_msgSend(_27,"addItemWithTitle:","Black");
objj_msgSend(_27,"addItemWithTitle:","More Choices...");
var _29=objj_msgSend(_27,"itemArray");
objj_msgSend(_29[0],"setRepresentedObject:",objj_msgSend(BKThemeDescriptor,"windowBackgroundColor"));
objj_msgSend(_29[1],"setRepresentedObject:",objj_msgSend(BKThemeDescriptor,"lightCheckersColor"));
objj_msgSend(_29[2],"setRepresentedObject:",objj_msgSend(BKThemeDescriptor,"darkCheckersColor"));
objj_msgSend(_29[3],"setRepresentedObject:",objj_msgSend(CPColor,"whiteColor"));
objj_msgSend(_29[4],"setRepresentedObject:",objj_msgSend(CPColor,"blackColor"));
objj_msgSend(_26,"setView:",_27);
objj_msgSend(_26,"setTarget:",nil);
objj_msgSend(_26,"setAction:",sel_getUid("changeColor:"));
objj_msgSend(_26,"setLabel:","Background Color");
var _28=CGRectGetWidth(objj_msgSend(_27,"frame"));
objj_msgSend(_26,"setMinSize:",CGSizeMake(_28,24));
objj_msgSend(_26,"setMaxSize:",CGSizeMake(_28,24));
}else{
if(_24===_2){
var _2a=objj_msgSend(objj_msgSend(CPBundle,"mainBundle"),"objectForInfoDictionaryKey:","BKLearnMoreButtonTitle");
if(!_2a){
_2a=objj_msgSend(objj_msgSend(CPBundle,"mainBundle"),"objectForInfoDictionaryKey:","CPBundleName")||"Home Page";
}
var _2b=objj_msgSend(CPButton,"buttonWithTitle:",_2a);
objj_msgSend(_2b,"setDefaultButton:",YES);
objj_msgSend(_26,"setView:",_2b);
objj_msgSend(_26,"setLabel:","Learn More");
objj_msgSend(_26,"setTarget:",nil);
objj_msgSend(_26,"setAction:",sel_getUid("learnMore:"));
var _28=CGRectGetWidth(objj_msgSend(_2b,"frame"));
objj_msgSend(_26,"setMinSize:",CGSizeMake(_28,24));
objj_msgSend(_26,"setMaxSize:",CGSizeMake(_28,24));
}
}
}
return _26;
}
}),new objj_method(sel_getUid("learnMore:"),function(_2c,_2d,_2e){
with(_2c){
window.location.href=objj_msgSend(objj_msgSend(CPBundle,"mainBundle"),"objectForInfoDictionaryKey:","BKLearnMoreURL");
}
}),new objj_method(sel_getUid("selectedThemeDescriptor"),function(_2f,_30){
with(_2f){
return _themeDescriptorClasses[objj_msgSend(objj_msgSend(_themesCollectionView,"selectionIndexes"),"firstIndex")];
}
}),new objj_method(sel_getUid("changeState:"),function(_31,_32,_33){
with(_31){
var _34=objj_msgSend(objj_msgSend(_31,"selectedThemeDescriptor"),"themedObjectTemplates"),_35=objj_msgSend(_34,"count");
while(_35--){
var _36=objj_msgSend(_34[_35],"valueForKey:","themedObject");
if(objj_msgSend(_36,"respondsToSelector:",sel_getUid("setEnabled:"))){
objj_msgSend(_36,"setEnabled:",objj_msgSend(_33,"title")==="Enabled"?YES:NO);
}
}
}
}),new objj_method(sel_getUid("changeColor:"),function(_37,_38,_39){
with(_37){
var _3a=nil;
if(objj_msgSend(_39,"isKindOfClass:",objj_msgSend(CPColorPanel,"class"))){
_3a=objj_msgSend(_39,"color");
}else{
if(objj_msgSend(_39,"titleOfSelectedItem")==="More Choices..."){
objj_msgSend(_39,"addItemWithTitle:","Other");
objj_msgSend(_39,"selectItemWithTitle:","Other");
objj_msgSend(CPApp,"orderFrontColorPanel:",_37);
}else{
_3a=objj_msgSend(objj_msgSend(_39,"selectedItem"),"representedObject");
objj_msgSend(_39,"removeItemWithTitle:","Other");
}
}
if(_3a){
objj_msgSend(objj_msgSend(_37,"selectedThemeDescriptor"),"setShowcaseBackgroundColor:",_3a);
objj_msgSend(BKShowcaseCell,"setBackgroundColor:",_3a);
}
}
})]);
var _3b=nil;
var _5=objj_allocateClassPair(CPView,"BKThemeDescriptorCell"),_6=_5.isa;
class_addIvars(_5,[new objj_ivar("_label")]);
objj_registerClassPair(_5);
objj_addClassForBundle(_5,objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));
class_addMethods(_5,[new objj_method(sel_getUid("setRepresentedObject:"),function(_3c,_3d,_3e){
with(_3c){
if(!_label){
_label=objj_msgSend(CPTextField,"labelWithTitle:","hello");
objj_msgSend(_label,"setFont:",objj_msgSend(CPFont,"systemFontOfSize:",11));
objj_msgSend(_label,"setFrame:",CGRectMake(10,0,CGRectGetWidth(objj_msgSend(_3c,"bounds"))-20,CGRectGetHeight(objj_msgSend(_3c,"bounds"))));
objj_msgSend(_label,"setVerticalAlignment:",CPCenterVerticalTextAlignment);
objj_msgSend(_label,"setAutoresizingMask:",CPViewWidthSizable|CPViewHeightSizable);
objj_msgSend(_3c,"addSubview:",_label);
}
objj_msgSend(_label,"setStringValue:",objj_msgSend(_3e,"themeName")+" ("+objj_msgSend(objj_msgSend(_3e,"themedObjectTemplates"),"count")+")");
}
}),new objj_method(sel_getUid("setSelected:"),function(_3f,_40,_41){
with(_3f){
objj_msgSend(_3f,"setBackgroundColor:",_41?objj_msgSend(objj_msgSend(_3f,"class"),"selectionColor"):nil);
objj_msgSend(_label,"setTextShadowOffset:",_41?CGSizeMake(0,1):CGSizeMakeZero());
objj_msgSend(_label,"setTextShadowColor:",_41?objj_msgSend(CPColor,"blackColor"):nil);
objj_msgSend(_label,"setFont:",_41?objj_msgSend(CPFont,"boldSystemFontOfSize:",11):objj_msgSend(CPFont,"systemFontOfSize:",11));
objj_msgSend(_label,"setTextColor:",_41?objj_msgSend(CPColor,"whiteColor"):objj_msgSend(CPColor,"blackColor"));
}
})]);
class_addMethods(_6,[new objj_method(sel_getUid("selectionColor"),function(_42,_43){
with(_42){
if(!_3b){
_3b=objj_msgSend(CPColor,"colorWithPatternImage:",objj_msgSend(objj_msgSend(CPImage,"alloc"),"initWithContentsOfFile:size:",objj_msgSend(objj_msgSend(CPBundle,"bundleForClass:",objj_msgSend(BKThemeDescriptorCell,"class")),"pathForResource:","selection.png"),CGSizeMake(1,36)));
}
return _3b;
}
})]);
var _44=nil;
var _45="BKShowcaseCellBackgroundColorDidChangeNotification";
var _5=objj_allocateClassPair(CPView,"BKShowcaseCell"),_6=_5.isa;
class_addIvars(_5,[new objj_ivar("_backgroundView"),new objj_ivar("_view"),new objj_ivar("_label")]);
objj_registerClassPair(_5);
objj_addClassForBundle(_5,objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));
class_addMethods(_5,[new objj_method(sel_getUid("init"),function(_46,_47){
with(_46){
_46=objj_msgSendSuper({receiver:_46,super_class:objj_getClass("CPView")},"init");
if(_46){
objj_msgSend(objj_msgSend(CPNotificationCenter,"defaultCenter"),"addObserver:selector:name:object:",_46,sel_getUid("showcaseBackgroundDidChange:"),_45,nil);
}
return _46;
}
}),new objj_method(sel_getUid("initWithCoder:"),function(_48,_49,_4a){
with(_48){
_48=objj_msgSendSuper({receiver:_48,super_class:objj_getClass("CPView")},"initWithCoder:",_4a);
if(_48){
objj_msgSend(objj_msgSend(CPNotificationCenter,"defaultCenter"),"addObserver:selector:name:object:",_48,sel_getUid("showcaseBackgroundDidChange:"),_45,nil);
}
return _48;
}
}),new objj_method(sel_getUid("showcaseBackgroundDidChange:"),function(_4b,_4c,_4d){
with(_4b){
objj_msgSend(_backgroundView,"setBackgroundColor:",objj_msgSend(BKShowcaseCell,"backgroundColor"));
}
}),new objj_method(sel_getUid("setSelected:"),function(_4e,_4f,_50){
with(_4e){
}
}),new objj_method(sel_getUid("setRepresentedObject:"),function(_51,_52,_53){
with(_51){
if(!_label){
_label=objj_msgSend(objj_msgSend(CPTextField,"alloc"),"initWithFrame:",CGRectMakeZero());
objj_msgSend(_label,"setAlignment:",CPCenterTextAlignment);
objj_msgSend(_label,"setAutoresizingMask:",CPViewMinYMargin|CPViewWidthSizable);
objj_msgSend(_label,"setFont:",objj_msgSend(CPFont,"boldSystemFontOfSize:",11));
objj_msgSend(_51,"addSubview:",_label);
}
objj_msgSend(_label,"setStringValue:",objj_msgSend(_53,"valueForKey:","label"));
objj_msgSend(_label,"sizeToFit");
objj_msgSend(_label,"setFrame:",CGRectMake(0,CGRectGetHeight(objj_msgSend(_51,"bounds"))-CGRectGetHeight(objj_msgSend(_label,"frame")),CGRectGetWidth(objj_msgSend(_51,"bounds")),CGRectGetHeight(objj_msgSend(_label,"frame"))));
if(!_backgroundView){
_backgroundView=objj_msgSend(objj_msgSend(CPView,"alloc"),"init");
objj_msgSend(_51,"addSubview:",_backgroundView);
}
objj_msgSend(_backgroundView,"setFrame:",CGRectMake(0,0,CGRectGetWidth(objj_msgSend(_51,"bounds")),CGRectGetMinY(objj_msgSend(_label,"frame"))));
objj_msgSend(_backgroundView,"setAutoresizingMask:",CPViewWidthSizable|CPViewHeightSizable);
if(_view){
objj_msgSend(_view,"removeFromSuperview");
}
_view=objj_msgSend(_53,"valueForKey:","themedObject");
objj_msgSend(_view,"setTheme:",nil);
objj_msgSend(_view,"setAutoresizingMask:",CPViewMinXMargin|CPViewMaxXMargin|CPViewMinYMargin|CPViewMaxYMargin);
objj_msgSend(_view,"setFrameOrigin:",CGPointMake((CGRectGetWidth(objj_msgSend(_backgroundView,"bounds"))-CGRectGetWidth(objj_msgSend(_view,"frame")))/2,(CGRectGetHeight(objj_msgSend(_backgroundView,"bounds"))-CGRectGetHeight(objj_msgSend(_view,"frame")))/2));
objj_msgSend(_backgroundView,"addSubview:",_view);
objj_msgSend(_backgroundView,"setBackgroundColor:",objj_msgSend(BKShowcaseCell,"backgroundColor"));
}
})]);
class_addMethods(_6,[new objj_method(sel_getUid("setBackgroundColor:"),function(_54,_55,_56){
with(_54){
if(_44===_56){
return;
}
_44=_56;
objj_msgSend(objj_msgSend(CPNotificationCenter,"defaultCenter"),"postNotificationName:object:",_45,nil);
}
}),new objj_method(sel_getUid("backgroundColor"),function(_57,_58){
with(_57){
return _44;
}
})]);
p;19;BKThemeDescriptor.jI;21;Foundation/CPObject.jc;4265;
var _1={},_2={},_3={},_4=nil,_5=nil,_6=nil;
var _7=objj_allocateClassPair(CPObject,"BKThemeDescriptor"),_8=_7.isa;
objj_registerClassPair(_7);
objj_addClassForBundle(_7,objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));
class_addMethods(_8,[new objj_method(sel_getUid("allThemeDescriptorClasses"),function(_9,_a){
with(_9){
var _b=[];
for(candidate in window){
var _c=objj_getClass(candidate),_d=class_getName(_c);
if(_d==="BKThemeDescriptor"){
continue;
}
var _e=_d.indexOf("ThemeDescriptor");
if((_e>=0)&&(_e===_d.length-"ThemeDescriptor".length)){
_b.push(_c);
}
}
objj_msgSend(_b,"sortUsingSelector:",sel_getUid("compare:"));
return _b;
}
}),new objj_method(sel_getUid("lightCheckersColor"),function(_f,_10){
with(_f){
if(!_4){
_4=objj_msgSend(CPColor,"colorWithPatternImage:",objj_msgSend(objj_msgSend(CPImage,"alloc"),"initWithContentsOfFile:size:",objj_msgSend(objj_msgSend(CPBundle,"bundleForClass:",objj_msgSend(BKThemeDescriptor,"class")),"pathForResource:","light-checkers.png"),CGSizeMake(12,12)));
}
return _4;
}
}),new objj_method(sel_getUid("darkCheckersColor"),function(_11,_12){
with(_11){
if(!_5){
_5=objj_msgSend(CPColor,"colorWithPatternImage:",objj_msgSend(objj_msgSend(CPImage,"alloc"),"initWithContentsOfFile:size:",objj_msgSend(objj_msgSend(CPBundle,"bundleForClass:",objj_msgSend(BKThemeDescriptor,"class")),"pathForResource:","dark-checkers.png"),CGSizeMake(12,12)));
}
return _5;
}
}),new objj_method(sel_getUid("windowBackgroundColor"),function(_13,_14){
with(_13){
return objj_msgSend(_CPStandardWindowView,"bodyBackgroundColor");
}
}),new objj_method(sel_getUid("defaultShowcaseBackgroundColor"),function(_15,_16){
with(_15){
return objj_msgSend(_CPStandardWindowView,"bodyBackgroundColor");
}
}),new objj_method(sel_getUid("showcaseBackgroundColor"),function(_17,_18){
with(_17){
var _19=objj_msgSend(_17,"className");
if(!_3[_19]){
_3[_19]=objj_msgSend(_17,"defaultShowcaseBackgroundColor");
}
return _3[_19];
}
}),new objj_method(sel_getUid("setShowcaseBackgroundColor:"),function(_1a,_1b,_1c){
with(_1a){
_3[objj_msgSend(_1a,"className")]=_1c;
}
}),new objj_method(sel_getUid("itemSize"),function(_1d,_1e){
with(_1d){
var _1f=objj_msgSend(_1d,"className");
if(!_1[_1f]){
objj_msgSend(_1d,"calculateThemedObjectTemplates");
}
return CGSizeMakeCopy(_1[_1f]);
}
}),new objj_method(sel_getUid("themedObjectTemplates"),function(_20,_21){
with(_20){
var _22=objj_msgSend(_20,"className");
if(!_2[_22]){
objj_msgSend(_20,"calculateThemedObjectTemplates");
}
return _2[_22];
}
}),new objj_method(sel_getUid("calculateThemedObjectTemplates"),function(_23,_24){
with(_23){
var _25=[],_26=CGSizeMake(0,0),_27=class_copyMethodList(objj_msgSend(_23,"class").isa),_28=0,_29=objj_msgSend(_27,"count");
for(;_28<_29;++_28){
var _2a=_27[_28],_2b=method_getName(_2a);
if(_2b.indexOf("themed")!==0){
continue;
}
var _2c=method_getImplementation(_2a),_2d=_2c(_23,_2b);
if(!_2d){
continue;
}
var _2e=objj_msgSend(objj_msgSend(BKThemedObjectTemplate,"alloc"),"init");
objj_msgSend(_2e,"setValue:forKey:",_2d,"themedObject");
objj_msgSend(_2e,"setValue:forKey:",BKLabelFromIdentifier(_2b),"label");
objj_msgSend(_25,"addObject:",_2e);
if(objj_msgSend(_2d,"isKindOfClass:",objj_msgSend(CPView,"class"))){
var _2f=objj_msgSend(_2d,"frame").size,_30=objj_msgSend(objj_msgSend(_2e,"valueForKey:","label"),"sizeWithFont:",objj_msgSend(CPFont,"boldSystemFontOfSize:",12)).width+20;
if(_2f.width>_26.width){
_26.width=_2f.width;
}
if(_30>_26.width){
_26.width=_30;
}
if(_2f.height>_26.height){
_26.height=_2f.height;
}
}
}
var _31=objj_msgSend(_23,"className");
_1[_31]=_26;
_2[_31]=_25;
}
}),new objj_method(sel_getUid("compare:"),function(_32,_33,_34){
with(_32){
return objj_msgSend(objj_msgSend(_32,"themeName"),"compare:",objj_msgSend(_34,"themeName"));
}
})]);
BKLabelFromIdentifier=function(_35){
var _36=_35.substr("themed".length);
index=0,count=_36.length,label="",lastCapital=null,isLeadingCapital=YES;
for(;index<count;++index){
var _37=_36.charAt(index),_38=/^[A-Z]/.test(_37);
if(_38){
if(!isLeadingCapital){
if(lastCapital===null){
label+=" "+_37.toLowerCase();
}else{
label+=_37;
}
}
lastCapital=_37;
}else{
if(isLeadingCapital&&lastCapital!==null){
label+=lastCapital;
}
label+=_37;
lastCapital=null;
isLeadingCapital=NO;
}
}
return label;
};
p;24;BKThemedObjectTemplate.jI;15;AppKit/CPView.jc;882;
var _1=objj_allocateClassPair(CPView,"BKThemedObjectTemplate"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_label"),new objj_ivar("_themedObject")]);
objj_registerClassPair(_1);
objj_addClassForBundle(_1,objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPView")},"init");
if(_3){
_label=objj_msgSend(_5,"decodeObjectForKey:","BKThemedObjectTemplateLabel");
_themedObject=objj_msgSend(_5,"decodeObjectForKey:","BKThemedObjectTemplateThemedObject");
}
return _3;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_6,_7,_8){
with(_6){
objj_msgSend(_8,"encodeObject:forKey:",_label,"BKThemedObjectTemplateLabel");
objj_msgSend(_8,"encodeObject:forKey:",_themedObject,"BKThemedObjectTemplateThemedObject");
}
})]);
p;17;BKThemeTemplate.jI;21;Foundation/CPObject.jc;841;
var _1=objj_allocateClassPair(CPObject,"BKThemeTemplate"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_name"),new objj_ivar("_description")]);
objj_registerClassPair(_1);
objj_addClassForBundle(_1,objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPObject")},"init");
if(_3){
_name=objj_msgSend(_5,"decodeObjectForKey:","BKThemeTemplateName");
_description=objj_msgSend(_5,"decodeObjectForKey:","BKThemeTemplateDescription");
}
return _3;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_6,_7,_8){
with(_6){
objj_msgSend(_8,"encodeObject:forKey:",_name,"BKThemeTemplateName");
objj_msgSend(_8,"encodeObject:forKey:",_description,"BKThemeTemplateDescription");
}
})]);
p;10;BlendKit.ji;22;BKShowcaseController.ji;19;BKThemeDescriptor.ji;17;BKThemeTemplate.ji;24;BKThemedObjectTemplate.je;/*
Content-Type: multipart/related; boundary="_ANY_STRING_WILL_DO_AS_A_SEPARATOR"

--_ANY_STRING_WILL_DO_AS_A_SEPARATOR
Content-Location:Resources/dark-checkers.png
Content-Transfer-Encoding:base64

iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAIAAADZF8uwAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAACVJREFUeNpi1NPTY0AFly5dQhNhYiACDEZFjJhCmP4dsr4DCDAAhJEDocvkWaYAAAAASUVORK5CYII=
--_ANY_STRING_WILL_DO_AS_A_SEPARATOR
Content-Location:Resources/light-checkers.png
Content-Transfer-Encoding:base64

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
--_ANY_STRING_WILL_DO_AS_A_SEPARATOR
Content-Location:Resources/selection.png
Content-Transfer-Encoding:base64

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
*/