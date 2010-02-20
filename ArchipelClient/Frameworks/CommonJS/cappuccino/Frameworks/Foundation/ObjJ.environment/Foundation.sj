@STATIC;1.0;p;13;CPArray+KVO.jt;12439;@STATIC;1.0;i;9;CPArray.ji;8;CPNull.jt;12394;
objj_executeFile("CPArray.j",true);
objj_executeFile("CPNull.j",true);
var _1=objj_getClass("CPObject");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPObject\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("mutableArrayValueForKey:"),function(_3,_4,_5){
with(_3){
return objj_msgSend(objj_msgSend(_CPKVCArray,"alloc"),"initWithKey:forProxyObject:",_5,_3);
}
}),new objj_method(sel_getUid("mutableArrayValueForKeyPath:"),function(_6,_7,_8){
with(_6){
var _9=_8.indexOf(".");
if(_9<0){
return objj_msgSend(_6,"mutableArrayValueForKey:",_8);
}
var _a=_8.substring(0,_9),_b=_8.substring(_9+1);
return objj_msgSend(objj_msgSend(_6,"valueForKeyPath:",_a),"valueForKeyPath:",_b);
}
})]);
var _1=objj_allocateClassPair(CPArray,"_CPKVCArray"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_proxyObject"),new objj_ivar("_key"),new objj_ivar("_insertSEL"),new objj_ivar("_insert"),new objj_ivar("_removeSEL"),new objj_ivar("_remove"),new objj_ivar("_replaceSEL"),new objj_ivar("_replace"),new objj_ivar("_insertManySEL"),new objj_ivar("_insertMany"),new objj_ivar("_removeManySEL"),new objj_ivar("_removeMany"),new objj_ivar("_replaceManySEL"),new objj_ivar("_replaceMany"),new objj_ivar("_objectAtIndexSEL"),new objj_ivar("_objectAtIndex"),new objj_ivar("_countSEL"),new objj_ivar("_count"),new objj_ivar("_accessSEL"),new objj_ivar("_access"),new objj_ivar("_setSEL"),new objj_ivar("_set")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithKey:forProxyObject:"),function(_c,_d,_e,_f){
with(_c){
_c=objj_msgSendSuper({receiver:_c,super_class:objj_getClass("_CPKVCArray").super_class},"init");
_key=_e;
_proxyObject=_f;
var _10=_key.charAt(0).toUpperCase()+_key.substring(1);
_insertSEL=sel_getName("insertObject:in"+_10+"AtIndex:");
if(objj_msgSend(_proxyObject,"respondsToSelector:",_insertSEL)){
_insert=objj_msgSend(_proxyObject,"methodForSelector:",_insertSEL);
}
_removeSEL=sel_getName("removeObjectFrom"+_10+"AtIndex:");
if(objj_msgSend(_proxyObject,"respondsToSelector:",_removeSEL)){
_remove=objj_msgSend(_proxyObject,"methodForSelector:",_removeSEL);
}
_replaceSEL=sel_getName("replaceObjectFrom"+_10+"AtIndex:withObject:");
if(objj_msgSend(_proxyObject,"respondsToSelector:",_replaceSEL)){
_replace=objj_msgSend(_proxyObject,"methodForSelector:",_replaceSEL);
}
_insertManySEL=sel_getName("insertObjects:in"+_10+"AtIndexes:");
if(objj_msgSend(_proxyObject,"respondsToSelector:",_insertManySEL)){
_insert=objj_msgSend(_proxyObject,"methodForSelector:",_insertManySEL);
}
_removeManySEL=sel_getName("removeObjectsFrom"+_10+"AtIndexes:");
if(objj_msgSend(_proxyObject,"respondsToSelector:",_removeManySEL)){
_remove=objj_msgSend(_proxyObject,"methodForSelector:",_removeManySEL);
}
_replaceManySEL=sel_getName("replaceObjectsFrom"+_10+"AtIndexes:withObjects:");
if(objj_msgSend(_proxyObject,"respondsToSelector:",_replaceManySEL)){
_replace=objj_msgSend(_proxyObject,"methodForSelector:",_replaceManySEL);
}
_objectAtIndexSEL=sel_getName("objectIn"+_10+"AtIndex:");
if(objj_msgSend(_proxyObject,"respondsToSelector:",_objectAtIndexSEL)){
_objectAtIndex=objj_msgSend(_proxyObject,"methodForSelector:",_objectAtIndexSEL);
}
_countSEL=sel_getName("countOf"+_10);
if(objj_msgSend(_proxyObject,"respondsToSelector:",_countSEL)){
_count=objj_msgSend(_proxyObject,"methodForSelector:",_countSEL);
}
_accessSEL=sel_getName(_key);
if(objj_msgSend(_proxyObject,"respondsToSelector:",_accessSEL)){
_access=objj_msgSend(_proxyObject,"methodForSelector:",_accessSEL);
}
_setSEL=sel_getName("set"+_10+":");
if(objj_msgSend(_proxyObject,"respondsToSelector:",_setSEL)){
_set=objj_msgSend(_proxyObject,"methodForSelector:",_setSEL);
}
return _c;
}
}),new objj_method(sel_getUid("copy"),function(_11,_12){
with(_11){
var _13=[],_14=objj_msgSend(_11,"count");
for(var i=0;i<_14;i++){
objj_msgSend(_13,"addObject:",objj_msgSend(_11,"objectAtIndex:",i));
}
return _13;
}
}),new objj_method(sel_getUid("_representedObject"),function(_15,_16){
with(_15){
if(_access){
return _access(_proxyObject,_accessSEL);
}
return objj_msgSend(_proxyObject,"valueForKey:",_key);
}
}),new objj_method(sel_getUid("_setRepresentedObject:"),function(_17,_18,_19){
with(_17){
if(_set){
return _set(_proxyObject,_setSEL,_19);
}
objj_msgSend(_proxyObject,"setValue:forKey:",_19,_key);
}
}),new objj_method(sel_getUid("count"),function(_1a,_1b){
with(_1a){
if(_count){
return _count(_proxyObject,_countSEL);
}
return objj_msgSend(objj_msgSend(_1a,"_representedObject"),"count");
}
}),new objj_method(sel_getUid("indexOfObject:inRange:"),function(_1c,_1d,_1e,_1f){
with(_1c){
var _20=_1f.location,_21=_1f.length,_22=!!_1e.isa;
for(;_20<_21;++_20){
var _23=objj_msgSend(_1c,"objectAtIndex:",_20);
if(_1e===_23||_22&&!!_23.isa&&objj_msgSend(_1e,"isEqual:",_23)){
return _20;
}
}
return CPNotFound;
}
}),new objj_method(sel_getUid("indexOfObject:"),function(_24,_25,_26){
with(_24){
return objj_msgSend(_24,"indexOfObject:range:",_26,CPMakeRange(0,objj_msgSend(_24,"count")));
}
}),new objj_method(sel_getUid("indexOfObjectIdenticalTo:inRange:"),function(_27,_28,_29,_2a){
with(_27){
var _2b=_2a.location,_2c=_2a.length;
for(;_2b<_2c;++_2b){
if(_29===objj_msgSend(_27,"objectAtIndex:",_2b)){
return _2b;
}
}
return CPNotFound;
}
}),new objj_method(sel_getUid("indexOfObjectIdenticalTo:"),function(_2d,_2e,_2f){
with(_2d){
return objj_msgSend(_2d,"indexOfObjectIdenticalTo:inRange:",_2f,CPMakeRange(0,objj_msgSend(_2d,"count")));
}
}),new objj_method(sel_getUid("objectAtIndex:"),function(_30,_31,_32){
with(_30){
if(_objectAtIndex){
return _objectAtIndex(_proxyObject,_objectAtIndexSEL,_32);
}
return objj_msgSend(objj_msgSend(_30,"_representedObject"),"objectAtIndex:",_32);
}
}),new objj_method(sel_getUid("addObject:"),function(_33,_34,_35){
with(_33){
if(_insert){
return _insert(_proxyObject,_insertSEL,_35,objj_msgSend(_33,"count"));
}
var _36=objj_msgSend(objj_msgSend(_33,"_representedObject"),"copy");
objj_msgSend(_36,"addObject:",_35);
objj_msgSend(_33,"_setRepresentedObject:",_36);
}
}),new objj_method(sel_getUid("addObjectsFromArray:"),function(_37,_38,_39){
with(_37){
var _3a=0,_3b=objj_msgSend(_39,"count");
for(;_3a<_3b;++_3a){
objj_msgSend(_37,"addObject:",objj_msgSend(_39,"objectAtIndex:",_3a));
}
}
}),new objj_method(sel_getUid("insertObject:atIndex:"),function(_3c,_3d,_3e,_3f){
with(_3c){
if(_insert){
return _insert(_proxyObject,_insertSEL,_3e,_3f);
}
var _40=objj_msgSend(objj_msgSend(_3c,"_representedObject"),"copy");
objj_msgSend(_40,"insertObject:atIndex:",_3e,_3f);
objj_msgSend(_3c,"_setRepresentedObject:",_40);
}
}),new objj_method(sel_getUid("removeLastObject"),function(_41,_42){
with(_41){
if(_remove){
return _remove(_proxyObject,_removeSEL,objj_msgSend(_41,"count")-1);
}
var _43=objj_msgSend(objj_msgSend(_41,"_representedObject"),"copy");
objj_msgSend(_43,"removeLastObject");
objj_msgSend(_41,"_setRepresentedObject:",_43);
}
}),new objj_method(sel_getUid("removeObjectAtIndex:"),function(_44,_45,_46){
with(_44){
if(_remove){
return _remove(_proxyObject,_removeSEL,_46);
}
var _47=objj_msgSend(objj_msgSend(_44,"_representedObject"),"copy");
objj_msgSend(_47,"removeObjectAtIndex:",_46);
objj_msgSend(_44,"_setRepresentedObject:",_47);
}
}),new objj_method(sel_getUid("replaceObjectAtIndex:withObject:"),function(_48,_49,_4a,_4b){
with(_48){
if(_replace){
return _replace(_proxyObject,_replaceSEL,_4a,_4b);
}
var _4c=objj_msgSend(objj_msgSend(_48,"_representedObject"),"copy");
objj_msgSend(_4c,"replaceObjectAtIndex:withObject:",_4a,_4b);
objj_msgSend(_48,"_setRepresentedObject:",_4c);
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("alloc"),function(_4d,_4e){
with(_4d){
var _4f=[];
_4f.isa=_4d;
var _50=class_copyIvarList(_4d),_51=_50.length;
while(_51--){
_4f[ivar_getName(_50[_51])]=nil;
}
return _4f;
}
})]);
var _1=objj_getClass("CPArray");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPArray\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("valueForKey:"),function(_52,_53,_54){
with(_52){
if(_54.indexOf("@")===0){
if(_54.indexOf(".")!==-1){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"called valueForKey: on an array with a complex key ("+_54+"). use valueForKeyPath:");
}
if(_54=="@count"){
return length;
}
return nil;
}else{
var _55=[],_56=objj_msgSend(_52,"objectEnumerator"),_57;
while((_57=objj_msgSend(_56,"nextObject"))!==nil){
var _58=objj_msgSend(_57,"valueForKey:",_54);
if(_58===nil||_58===undefined){
_58=objj_msgSend(CPNull,"null");
}
_55.push(_58);
}
return _55;
}
}
}),new objj_method(sel_getUid("valueForKeyPath:"),function(_59,_5a,_5b){
with(_59){
if(_5b.indexOf("@")===0){
var _5c=_5b.indexOf("."),_5d,_5e;
if(_5c!==-1){
_5d=_5b.substring(1,_5c);
_5e=_5b.substring(_5c+1);
}else{
_5d=_5b.substring(1);
}
if(_5f[_5d]){
return _5f[_5d](_59,_5a,_5e);
}
return nil;
}else{
var _60=[],_61=objj_msgSend(_59,"objectEnumerator"),_62;
while((_62=objj_msgSend(_61,"nextObject"))!==nil){
var _63=objj_msgSend(_62,"valueForKeyPath:",_5b);
if(_63===nil||_63===undefined){
_63=objj_msgSend(CPNull,"null");
}
_60.push(_63);
}
return _60;
}
}
}),new objj_method(sel_getUid("setValue:forKey:"),function(_64,_65,_66,_67){
with(_64){
var _68=objj_msgSend(_64,"objectEnumerator"),_69;
while(_69=objj_msgSend(_68,"nextObject")){
objj_msgSend(_69,"setValue:forKey:",_66,_67);
}
}
}),new objj_method(sel_getUid("setValue:forKeyPath:"),function(_6a,_6b,_6c,_6d){
with(_6a){
var _6e=objj_msgSend(_6a,"objectEnumerator"),_6f;
while(_6f=objj_msgSend(_6e,"nextObject")){
objj_msgSend(_6f,"setValue:forKeyPath:",_6c,_6d);
}
}
})]);
var _5f=[];
var _70,_71,_72,_73,_74;
_5f["avg"]=_70=function(_75,_76,_77){
var _78=objj_msgSend(_75,"valueForKeyPath:",_77),_79=objj_msgSend(_78,"count"),_7a=_79;
average=0;
if(!_79){
return 0;
}
while(_7a--){
average+=objj_msgSend(_78[_7a],"doubleValue");
}
return average/_79;
};
_5f["max"]=_71=function(_7b,_7c,_7d){
var _7e=objj_msgSend(_7b,"valueForKeyPath:",_7d),_7f=objj_msgSend(_7e,"count")-1,max=objj_msgSend(_7e,"lastObject");
while(_7f--){
var _80=_7e[_7f];
if(objj_msgSend(max,"compare:",_80)<0){
max=_80;
}
}
return max;
};
_5f["min"]=_72=function(_81,_82,_83){
var _84=objj_msgSend(_81,"valueForKeyPath:",_83),_85=objj_msgSend(_84,"count")-1,min=objj_msgSend(_84,"lastObject");
while(_85--){
var _86=_84[_85];
if(objj_msgSend(min,"compare:",_86)>0){
min=_86;
}
}
return min;
};
_5f["count"]=_73=function(_87,_88,_89){
return objj_msgSend(_87,"count");
};
_5f["sum"]=_74=function(_8a,_8b,_8c){
var _8d=objj_msgSend(_8a,"valueForKeyPath:",_8c),_8e=objj_msgSend(_8d,"count"),sum=0;
while(_8e--){
sum+=objj_msgSend(_8d[_8e],"doubleValue");
}
return sum;
};
var _1=objj_getClass("CPArray");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPArray\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("addObserver:toObjectsAtIndexes:forKeyPath:options:context:"),function(_8f,_90,_91,_92,_93,_94,_95){
with(_8f){
var _96=objj_msgSend(_92,"firstIndex");
while(_96>=0){
objj_msgSend(_8f[_96],"addObserver:forKeyPath:options:context:",_91,_93,_94,_95);
_96=objj_msgSend(_92,"indexGreaterThanIndex:",_96);
}
}
}),new objj_method(sel_getUid("removeObserver:fromObjectsAtIndexes:forKeyPath:"),function(_97,_98,_99,_9a,_9b){
with(_97){
var _9c=objj_msgSend(_9a,"firstIndex");
while(_9c>=0){
objj_msgSend(_97[_9c],"removeObserver:forKeyPath:",_99,_9b);
_9c=objj_msgSend(_9a,"indexGreaterThanIndex:",_9c);
}
}
}),new objj_method(sel_getUid("addObserver:forKeyPath:options:context:"),function(_9d,_9e,_9f,_a0,_a1,_a2){
with(_9d){
if(objj_msgSend(isa,"instanceMethodForSelector:",_9e)===objj_msgSend(CPArray,"instanceMethodForSelector:",_9e)){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"Unsupported method on CPArray");
}else{
objj_msgSendSuper({receiver:_9d,super_class:objj_getClass("CPArray").super_class},"addObserver:forKeyPath:options:context:",_9f,_a0,_a1,_a2);
}
}
}),new objj_method(sel_getUid("removeObserver:forKeyPath:"),function(_a3,_a4,_a5,_a6){
with(_a3){
if(objj_msgSend(isa,"instanceMethodForSelector:",_a4)===objj_msgSend(CPArray,"instanceMethodForSelector:",_a4)){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"Unsupported method on CPArray");
}else{
objj_msgSendSuper({receiver:_a3,super_class:objj_getClass("CPArray").super_class},"removeObserver:forKeyPath:",_a5,_a6);
}
}
})]);
p;9;CPArray.jt;19059;@STATIC;1.0;i;10;CPObject.ji;9;CPRange.ji;14;CPEnumerator.ji;18;CPSortDescriptor.ji;13;CPException.jt;18951;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPRange.j",true);
objj_executeFile("CPEnumerator.j",true);
objj_executeFile("CPSortDescriptor.j",true);
objj_executeFile("CPException.j",true);
var _1=objj_allocateClassPair(CPEnumerator,"_CPArrayEnumerator"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_array"),new objj_ivar("_index")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithArray:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("_CPArrayEnumerator").super_class},"init");
if(_3){
_array=_5;
_index=-1;
}
return _3;
}
}),new objj_method(sel_getUid("nextObject"),function(_6,_7){
with(_6){
if(++_index>=objj_msgSend(_array,"count")){
return nil;
}
return objj_msgSend(_array,"objectAtIndex:",_index);
}
}),new objj_method(sel_getUid("countByEnumeratingWithState:objects:count:"),function(_8,_9,_a,_b,_c){
with(_8){
return objj_msgSend(_array,"countByEnumeratingWithState:objects:count:",_a,_b,_c);
}
})]);
var _1=objj_allocateClassPair(CPEnumerator,"_CPReverseArrayEnumerator"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_array"),new objj_ivar("_index")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithArray:"),function(_d,_e,_f){
with(_d){
_d=objj_msgSendSuper({receiver:_d,super_class:objj_getClass("_CPReverseArrayEnumerator").super_class},"init");
if(_d){
_array=_f;
_index=objj_msgSend(_array,"count");
}
return _d;
}
}),new objj_method(sel_getUid("nextObject"),function(_10,_11){
with(_10){
if(--_index<0){
return nil;
}
return objj_msgSend(_array,"objectAtIndex:",_index);
}
})]);
var _1=objj_allocateClassPair(CPObject,"CPArray"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("init"),function(_12,_13){
with(_12){
return _12;
}
}),new objj_method(sel_getUid("initWithArray:"),function(_14,_15,_16){
with(_14){
_14=objj_msgSendSuper({receiver:_14,super_class:objj_getClass("CPArray").super_class},"init");
if(_14){
objj_msgSend(_14,"setArray:",_16);
}
return _14;
}
}),new objj_method(sel_getUid("initWithArray:copyItems:"),function(_17,_18,_19,_1a){
with(_17){
if(!_1a){
return objj_msgSend(_17,"initWithArray:",_19);
}
_17=objj_msgSendSuper({receiver:_17,super_class:objj_getClass("CPArray").super_class},"init");
if(_17){
var _1b=0,_1c=objj_msgSend(_19,"count");
for(;_1b<_1c;++i){
if(_19[i].isa){
_17[i]=objj_msgSend(_19,"copy");
}else{
_17[i]=_19;
}
}
}
return _17;
}
}),new objj_method(sel_getUid("initWithObjects:"),function(_1d,_1e,_1f){
with(_1d){
var i=2,_20;
for(;i<arguments.length&&(_20=arguments[i])!=nil;++i){
push(_20);
}
return _1d;
}
}),new objj_method(sel_getUid("initWithObjects:count:"),function(_21,_22,_23,_24){
with(_21){
_21=objj_msgSendSuper({receiver:_21,super_class:objj_getClass("CPArray").super_class},"init");
if(_21){
var _25=0;
for(;_25<_24;++_25){
push(_23[_25]);
}
}
return _21;
}
}),new objj_method(sel_getUid("containsObject:"),function(_26,_27,_28){
with(_26){
return objj_msgSend(_26,"indexOfObject:",_28)!=CPNotFound;
}
}),new objj_method(sel_getUid("count"),function(_29,_2a){
with(_29){
return length;
}
}),new objj_method(sel_getUid("indexOfObject:"),function(_2b,_2c,_2d){
with(_2b){
if(_2d===nil){
return CPNotFound;
}
var i=0,_2e=length;
if(_2d.isa){
for(;i<_2e;++i){
if(objj_msgSend(_2b[i],"isEqual:",_2d)){
return i;
}
}
}else{
if(_2b.indexOf){
return indexOf(_2d);
}else{
for(;i<_2e;++i){
if(_2b[i]==_2d){
return i;
}
}
}
}
return CPNotFound;
}
}),new objj_method(sel_getUid("indexOfObject:inRange:"),function(_2f,_30,_31,_32){
with(_2f){
if(_31===nil){
return CPNotFound;
}
var i=_32.location,_33=MIN(CPMaxRange(_32),length);
if(_31.isa){
for(;i<_33;++i){
if(objj_msgSend(_2f[i],"isEqual:",_31)){
return i;
}
}
}else{
for(;i<_33;++i){
if(_2f[i]==_31){
return i;
}
}
}
return CPNotFound;
}
}),new objj_method(sel_getUid("indexOfObjectIdenticalTo:"),function(_34,_35,_36){
with(_34){
if(_36===nil){
return CPNotFound;
}
if(_34.indexOf){
return indexOf(_36);
}else{
var _37=0,_38=length;
for(;_37<_38;++_37){
if(_34[_37]===_36){
return _37;
}
}
}
return CPNotFound;
}
}),new objj_method(sel_getUid("indexOfObjectIdenticalTo:inRange:"),function(_39,_3a,_3b,_3c){
with(_39){
if(_3b===nil){
return CPNotFound;
}
if(_39.indexOf){
var _3d=indexOf(_3b,_3c.location);
if(CPLocationInRange(_3d,_3c)){
return _3d;
}
}else{
var _3d=_3c.location,_3e=MIN(CPMaxRange(_3c),length);
for(;_3d<_3e;++_3d){
if(_39[_3d]==_3b){
return _3d;
}
}
}
return CPNotFound;
}
}),new objj_method(sel_getUid("indexOfObject:sortedBySelector:"),function(_3f,_40,_41,_42){
with(_3f){
return objj_msgSend(_3f,"indexOfObject:sortedByFunction:",_41,function(lhs,rhs){
objj_msgSend(lhs,_42,rhs);
});
}
}),new objj_method(sel_getUid("indexOfObject:sortedByFunction:"),function(_43,_44,_45,_46){
with(_43){
return objj_msgSend(_43,"indexOfObject:sortedByFunction:context:",_45,_46,nil);
}
}),new objj_method(sel_getUid("indexOfObject:sortedByFunction:context:"),function(_47,_48,_49,_4a,_4b){
with(_47){
if(!_4a||_49===undefined){
return CPNotFound;
}
var mid,c,_4c=0,_4d=length-1;
while(_4c<=_4d){
mid=FLOOR((_4c+_4d)/2);
c=_4a(_49,_47[mid],_4b);
if(c>0){
_4c=mid+1;
}else{
if(c<0){
_4d=mid-1;
}else{
while(mid<length-1&&_4a(_49,_47[mid+1],_4b)==CPOrderedSame){
mid++;
}
return mid;
}
}
}
return CPNotFound;
}
}),new objj_method(sel_getUid("indexOfObject:sortedByDescriptors:"),function(_4e,_4f,_50,_51){
with(_4e){
return objj_msgSend(_4e,"indexOfObject:sortedByFunction:",_50,function(lhs,rhs){
var i=0,_52=objj_msgSend(_51,"count"),_53=CPOrderedSame;
while(i<_52){
if((_53=objj_msgSend(_51[i++],"compareObject:withObject:",lhs,rhs))!=CPOrderedSame){
return _53;
}
}
return _53;
});
}
}),new objj_method(sel_getUid("lastObject"),function(_54,_55){
with(_54){
var _56=objj_msgSend(_54,"count");
if(!_56){
return nil;
}
return _54[_56-1];
}
}),new objj_method(sel_getUid("objectAtIndex:"),function(_57,_58,_59){
with(_57){
if(_59>=length||_59<0){
objj_msgSend(CPException,"raise:reason:",CPRangeException,"index ("+_59+") beyond bounds ("+length+")");
}
return _57[_59];
}
}),new objj_method(sel_getUid("objectsAtIndexes:"),function(_5a,_5b,_5c){
with(_5a){
var _5d=CPNotFound,_5e=[];
while((_5d=objj_msgSend(_5c,"indexGreaterThanIndex:",_5d))!==CPNotFound){
objj_msgSend(_5e,"addObject:",objj_msgSend(_5a,"objectAtIndex:",_5d));
}
return _5e;
}
}),new objj_method(sel_getUid("objectEnumerator"),function(_5f,_60){
with(_5f){
return objj_msgSend(objj_msgSend(_CPArrayEnumerator,"alloc"),"initWithArray:",_5f);
}
}),new objj_method(sel_getUid("reverseObjectEnumerator"),function(_61,_62){
with(_61){
return objj_msgSend(objj_msgSend(_CPReverseArrayEnumerator,"alloc"),"initWithArray:",_61);
}
}),new objj_method(sel_getUid("makeObjectsPerformSelector:"),function(_63,_64,_65){
with(_63){
if(!_65){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"makeObjectsPerformSelector: 'aSelector' can't be nil");
}
var _66=0,_67=length;
for(;_66<_67;++_66){
objj_msgSend(_63[_66],_65);
}
}
}),new objj_method(sel_getUid("makeObjectsPerformSelector:withObject:"),function(_68,_69,_6a,_6b){
with(_68){
if(!_6a){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"makeObjectsPerformSelector:withObject 'aSelector' can't be nil");
}
var _6c=0,_6d=length;
for(;_6c<_6d;++_6c){
objj_msgSend(_68[_6c],_6a,_6b);
}
}
}),new objj_method(sel_getUid("makeObjectsPerformSelector:withObjects:"),function(_6e,_6f,_70,_71){
with(_6e){
if(!_70){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"makeObjectsPerformSelector:withObjects: 'aSelector' can't be nil");
}
var _72=0,_73=length,_74=[nil,_70].concat(_71||[]);
for(;_72<_73;++_72){
_74[0]=_6e[_72];
objj_msgSend.apply(this,_74);
}
}
}),new objj_method(sel_getUid("firstObjectCommonWithArray:"),function(_75,_76,_77){
with(_75){
if(!objj_msgSend(_77,"count")||!objj_msgSend(_75,"count")){
return nil;
}
var i=0,_78=objj_msgSend(_75,"count");
for(;i<_78;++i){
if(objj_msgSend(_77,"containsObject:",_75[i])){
return _75[i];
}
}
return nil;
}
}),new objj_method(sel_getUid("isEqualToArray:"),function(_79,_7a,_7b){
with(_79){
if(_79===_7b){
return YES;
}
if(length!=_7b.length){
return NO;
}
var _7c=0,_7d=objj_msgSend(_79,"count");
for(;_7c<_7d;++_7c){
var lhs=_79[_7c],rhs=_7b[_7c];
if(lhs!==rhs&&(lhs&&!lhs.isa||rhs&&!rhs.isa||!objj_msgSend(lhs,"isEqual:",rhs))){
return NO;
}
}
return YES;
}
}),new objj_method(sel_getUid("isEqual:"),function(_7e,_7f,_80){
with(_7e){
if(_7e===_80){
return YES;
}
if(!objj_msgSend(_80,"isKindOfClass:",objj_msgSend(CPArray,"class"))){
return NO;
}
return objj_msgSend(_7e,"isEqualToArray:",_80);
}
}),new objj_method(sel_getUid("arrayByAddingObject:"),function(_81,_82,_83){
with(_81){
if(_83===nil||_83===undefined){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"arrayByAddingObject: object can't be nil");
}
var _84=objj_msgSend(_81,"copy");
_84.push(_83);
return _84;
}
}),new objj_method(sel_getUid("arrayByAddingObjectsFromArray:"),function(_85,_86,_87){
with(_85){
return slice(0).concat(_87);
}
}),new objj_method(sel_getUid("subarrayWithRange:"),function(_88,_89,_8a){
with(_88){
if(_8a.location<0||CPMaxRange(_8a)>length){
objj_msgSend(CPException,"raise:reason:",CPRangeException,"subarrayWithRange: aRange out of bounds");
}
return slice(_8a.location,CPMaxRange(_8a));
}
}),new objj_method(sel_getUid("sortedArrayUsingDescriptors:"),function(_8b,_8c,_8d){
with(_8b){
var _8e=objj_msgSend(_8b,"copy");
objj_msgSend(_8e,"sortUsingDescriptors:",_8d);
return _8e;
}
}),new objj_method(sel_getUid("sortedArrayUsingFunction:"),function(_8f,_90,_91){
with(_8f){
return objj_msgSend(_8f,"sortedArrayUsingFunction:context:",_91,nil);
}
}),new objj_method(sel_getUid("sortedArrayUsingFunction:context:"),function(_92,_93,_94,_95){
with(_92){
var _96=objj_msgSend(_92,"copy");
objj_msgSend(_96,"sortUsingFunction:context:",_94,_95);
return _96;
}
}),new objj_method(sel_getUid("sortedArrayUsingSelector:"),function(_97,_98,_99){
with(_97){
var _9a=objj_msgSend(_97,"copy");
objj_msgSend(_9a,"sortUsingSelector:",_99);
return _9a;
}
}),new objj_method(sel_getUid("componentsJoinedByString:"),function(_9b,_9c,_9d){
with(_9b){
return join(_9d);
}
}),new objj_method(sel_getUid("description"),function(_9e,_9f){
with(_9e){
var _a0=0,_a1=objj_msgSend(_9e,"count"),_a2="(";
for(;_a0<_a1;++_a0){
if(_a0===0){
_a2+="\n";
}
var _a3=objj_msgSend(_9e,"objectAtIndex:",_a0),_a4=_a3&&_a3.isa?objj_msgSend(_a3,"description"):String(_a3);
_a2+="\t"+_a4.split("\n").join("\n\t");
if(_a0!==_a1-1){
_a2+=", ";
}
_a2+="\n";
}
return _a2+")";
}
}),new objj_method(sel_getUid("pathsMatchingExtensions:"),function(_a5,_a6,_a7){
with(_a5){
var _a8=0,_a9=objj_msgSend(_a5,"count"),_aa=[];
for(;_a8<_a9;++_a8){
if(_a5[_a8].isa&&objj_msgSend(_a5[_a8],"isKindOfClass:",objj_msgSend(CPString,"class"))&&objj_msgSend(_a7,"containsObject:",objj_msgSend(_a5[_a8],"pathExtension"))){
_aa.push(_a5[_a8]);
}
}
return _aa;
}
}),new objj_method(sel_getUid("setValue:forKey:"),function(_ab,_ac,_ad,_ae){
with(_ab){
var i=0,_af=objj_msgSend(_ab,"count");
for(;i<_af;++i){
objj_msgSend(_ab[i],"setValue:forKey:",_ad,_ae);
}
}
}),new objj_method(sel_getUid("valueForKey:"),function(_b0,_b1,_b2){
with(_b0){
var i=0,_b3=objj_msgSend(_b0,"count"),_b4=[];
for(;i<_b3;++i){
_b4.push(objj_msgSend(_b0[i],"valueForKey:",_b2));
}
return _b4;
}
}),new objj_method(sel_getUid("copy"),function(_b5,_b6){
with(_b5){
return slice(0);
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("alloc"),function(_b7,_b8){
with(_b7){
return [];
}
}),new objj_method(sel_getUid("array"),function(_b9,_ba){
with(_b9){
return objj_msgSend(objj_msgSend(_b9,"alloc"),"init");
}
}),new objj_method(sel_getUid("arrayWithArray:"),function(_bb,_bc,_bd){
with(_bb){
return objj_msgSend(objj_msgSend(_bb,"alloc"),"initWithArray:",_bd);
}
}),new objj_method(sel_getUid("arrayWithObject:"),function(_be,_bf,_c0){
with(_be){
return objj_msgSend(objj_msgSend(_be,"alloc"),"initWithObjects:",_c0);
}
}),new objj_method(sel_getUid("arrayWithObjects:"),function(_c1,_c2,_c3){
with(_c1){
var i=2,_c4=objj_msgSend(objj_msgSend(_c1,"alloc"),"init"),_c5;
for(;i<arguments.length&&(_c5=arguments[i])!=nil;++i){
_c4.push(_c5);
}
return _c4;
}
}),new objj_method(sel_getUid("arrayWithObjects:count:"),function(_c6,_c7,_c8,_c9){
with(_c6){
return objj_msgSend(objj_msgSend(_c6,"alloc"),"initWithObjects:count:",_c8,_c9);
}
})]);
var _1=objj_getClass("CPArray");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPArray\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("initWithCapacity:"),function(_ca,_cb,_cc){
with(_ca){
return _ca;
}
}),new objj_method(sel_getUid("addObject:"),function(_cd,_ce,_cf){
with(_cd){
push(_cf);
}
}),new objj_method(sel_getUid("addObjectsFromArray:"),function(_d0,_d1,_d2){
with(_d0){
splice.apply(_d0,[length,0].concat(_d2));
}
}),new objj_method(sel_getUid("insertObject:atIndex:"),function(_d3,_d4,_d5,_d6){
with(_d3){
splice(_d6,0,_d5);
}
}),new objj_method(sel_getUid("insertObjects:atIndexes:"),function(_d7,_d8,_d9,_da){
with(_d7){
var _db=objj_msgSend(_da,"count"),_dc=objj_msgSend(_d9,"count");
if(_db!==_dc){
objj_msgSend(CPException,"raise:reason:",CPRangeException,"the counts of the passed-in array ("+_dc+") and index set ("+_db+") must be identical.");
}
var _dd=objj_msgSend(_da,"lastIndex");
if(_dd>=objj_msgSend(_d7,"count")+_db){
objj_msgSend(CPException,"raise:reason:",CPRangeException,"the last index ("+_dd+") must be less than the sum of the original count ("+objj_msgSend(_d7,"count")+") and the insertion count ("+_db+").");
}
var _de=0,_df=objj_msgSend(_da,"firstIndex");
for(;_de<_dc;++_de,_df=objj_msgSend(_da,"indexGreaterThanIndex:",_df)){
objj_msgSend(_d7,"insertObject:atIndex:",_d9[_de],_df);
}
}
}),new objj_method(sel_getUid("replaceObjectAtIndex:withObject:"),function(_e0,_e1,_e2,_e3){
with(_e0){
_e0[_e2]=_e3;
}
}),new objj_method(sel_getUid("replaceObjectsAtIndexes:withObjects:"),function(_e4,_e5,_e6,_e7){
with(_e4){
var i=0,_e8=objj_msgSend(_e6,"firstIndex");
while(_e8!=CPNotFound){
objj_msgSend(_e4,"replaceObjectAtIndex:withObject:",_e8,_e7[i++]);
_e8=objj_msgSend(_e6,"indexGreaterThanIndex:",_e8);
}
}
}),new objj_method(sel_getUid("replaceObjectsInRange:withObjectsFromArray:range:"),function(_e9,_ea,_eb,_ec,_ed){
with(_e9){
if(!_ed.location&&_ed.length==objj_msgSend(_ec,"count")){
objj_msgSend(_e9,"replaceObjectsInRange:withObjectsFromArray:",_eb,_ec);
}else{
splice.apply(_e9,[_eb.location,_eb.length].concat(objj_msgSend(_ec,"subarrayWithRange:",_ed)));
}
}
}),new objj_method(sel_getUid("replaceObjectsInRange:withObjectsFromArray:"),function(_ee,_ef,_f0,_f1){
with(_ee){
splice.apply(_ee,[_f0.location,_f0.length].concat(_f1));
}
}),new objj_method(sel_getUid("setArray:"),function(_f2,_f3,_f4){
with(_f2){
if(_f2==_f4){
return;
}
splice.apply(_f2,[0,length].concat(_f4));
}
}),new objj_method(sel_getUid("removeAllObjects"),function(_f5,_f6){
with(_f5){
splice(0,length);
}
}),new objj_method(sel_getUid("removeLastObject"),function(_f7,_f8){
with(_f7){
pop();
}
}),new objj_method(sel_getUid("removeObject:"),function(_f9,_fa,_fb){
with(_f9){
objj_msgSend(_f9,"removeObject:inRange:",_fb,CPMakeRange(0,length));
}
}),new objj_method(sel_getUid("removeObject:inRange:"),function(_fc,_fd,_fe,_ff){
with(_fc){
var _100;
while((_100=objj_msgSend(_fc,"indexOfObject:inRange:",_fe,_ff))!=CPNotFound){
objj_msgSend(_fc,"removeObjectAtIndex:",_100);
_ff=CPIntersectionRange(CPMakeRange(_100,length-_100),_ff);
}
}
}),new objj_method(sel_getUid("removeObjectAtIndex:"),function(self,_101,_102){
with(self){
splice(_102,1);
}
}),new objj_method(sel_getUid("removeObjectsAtIndexes:"),function(self,_103,_104){
with(self){
var _105=objj_msgSend(_104,"lastIndex");
while(_105!=CPNotFound){
objj_msgSend(self,"removeObjectAtIndex:",_105);
_105=objj_msgSend(_104,"indexLessThanIndex:",_105);
}
}
}),new objj_method(sel_getUid("removeObjectIdenticalTo:"),function(self,_106,_107){
with(self){
objj_msgSend(self,"removeObjectIdenticalTo:inRange:",_107,CPMakeRange(0,objj_msgSend(self,"count")));
}
}),new objj_method(sel_getUid("removeObjectIdenticalTo:inRange:"),function(self,_108,_109,_10a){
with(self){
var _10b,_10c=objj_msgSend(self,"count");
while((_10b=objj_msgSend(self,"indexOfObjectIdenticalTo:inRange:",_109,_10a))!==CPNotFound){
objj_msgSend(self,"removeObjectAtIndex:",_10b);
_10a=CPIntersectionRange(CPMakeRange(_10b,(--_10c)-_10b),_10a);
}
}
}),new objj_method(sel_getUid("removeObjectsInArray:"),function(self,_10d,_10e){
with(self){
var _10f=0,_110=objj_msgSend(_10e,"count");
for(;_10f<_110;++_10f){
objj_msgSend(self,"removeObject:",_10e[_10f]);
}
}
}),new objj_method(sel_getUid("removeObjectsInRange:"),function(self,_111,_112){
with(self){
splice(_112.location,_112.length);
}
}),new objj_method(sel_getUid("exchangeObjectAtIndex:withObjectAtIndex:"),function(self,_113,_114,_115){
with(self){
var _116=self[_114];
self[_114]=self[_115];
self[_115]=_116;
}
}),new objj_method(sel_getUid("sortUsingDescriptors:"),function(self,_117,_118){
with(self){
sort(function(lhs,rhs){
var i=0,_119=objj_msgSend(_118,"count"),_11a=CPOrderedSame;
while(i<_119){
if((_11a=objj_msgSend(_118[i++],"compareObject:withObject:",lhs,rhs))!=CPOrderedSame){
return _11a;
}
}
return _11a;
});
}
}),new objj_method(sel_getUid("sortUsingFunction:context:"),function(self,_11b,_11c,_11d){
with(self){
sort(function(lhs,rhs){
return _11c(lhs,rhs,_11d);
});
}
}),new objj_method(sel_getUid("sortUsingSelector:"),function(self,_11e,_11f){
with(self){
sort(function(lhs,rhs){
return objj_msgSend(lhs,_11f,rhs);
});
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("arrayWithCapacity:"),function(self,_120,_121){
with(self){
return objj_msgSend(objj_msgSend(self,"alloc"),"initWithCapacity:",_121);
}
})]);
var _1=objj_getClass("CPArray");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPArray\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("countByEnumeratingWithState:objects:count:"),function(self,_122,_123,_124,_125){
with(self){
var _126=objj_msgSend(self,"count"),_127=_123.state;
if(_127>=_126){
return 0;
}
var _128=0,last=MIN(_127+_125,_126);
_125=last-_127;
for(;_127<last;++_127,++_128){
_124[_128]=objj_msgSend(self,"objectAtIndex:",_127);
}
_123.state=last;
return _125;
}
})]);
var _1=objj_getClass("CPArray");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPArray\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(self,_129,_12a){
with(self){
return objj_msgSend(_12a,"decodeObjectForKey:","CP.objects");
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(self,_12b,_12c){
with(self){
objj_msgSend(_12c,"_encodeArrayOfObjects:forKey:",self,"CP.objects");
}
})]);
var _1=objj_allocateClassPair(CPArray,"CPMutableArray"),_2=_1.isa;
objj_registerClassPair(_1);
Array.prototype.isa=CPArray;
objj_msgSend(CPArray,"initialize");
p;20;CPAttributedString.jt;12873;@STATIC;1.0;i;10;CPObject.ji;10;CPString.ji;14;CPDictionary.ji;9;CPRange.jt;12791;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPString.j",true);
objj_executeFile("CPDictionary.j",true);
objj_executeFile("CPRange.j",true);
var _1=objj_allocateClassPair(CPObject,"CPAttributedString"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_string"),new objj_ivar("_rangeEntries")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithString:"),function(_3,_4,_5){
with(_3){
return objj_msgSend(_3,"initWithString:attributes:",_5,nil);
}
}),new objj_method(sel_getUid("initWithAttributedString:"),function(_6,_7,_8){
with(_6){
var _9=objj_msgSend(_6,"initWithString:attributes:","",nil);
objj_msgSend(_9,"setAttributedString:",_8);
return _9;
}
}),new objj_method(sel_getUid("initWithString:attributes:"),function(_a,_b,_c,_d){
with(_a){
_a=objj_msgSendSuper({receiver:_a,super_class:objj_getClass("CPAttributedString").super_class},"init");
if(!_d){
_d=objj_msgSend(CPDictionary,"dictionary");
}
_string=""+_c;
_rangeEntries=[_e(CPMakeRange(0,_string.length),_d)];
return _a;
}
}),new objj_method(sel_getUid("string"),function(_f,_10){
with(_f){
return _string;
}
}),new objj_method(sel_getUid("mutableString"),function(_11,_12){
with(_11){
return objj_msgSend(_11,"string");
}
}),new objj_method(sel_getUid("length"),function(_13,_14){
with(_13){
return _string.length;
}
}),new objj_method(sel_getUid("_indexOfEntryWithIndex:"),function(_15,_16,_17){
with(_15){
if(_17<0||_17>_string.length||_17===undefined){
return CPNotFound;
}
var _18=function(_19,_1a){
if(CPLocationInRange(_19,_1a.range)){
return CPOrderedSame;
}else{
if(CPMaxRange(_1a.range)<=_19){
return CPOrderedDescending;
}else{
return CPOrderedAscending;
}
}
};
return objj_msgSend(_rangeEntries,"indexOfObject:sortedByFunction:",_17,_18);
}
}),new objj_method(sel_getUid("attributesAtIndex:effectiveRange:"),function(_1b,_1c,_1d,_1e){
with(_1b){
var _1f=objj_msgSend(_1b,"_indexOfEntryWithIndex:",_1d);
if(_1f==CPNotFound){
return nil;
}
var _20=_rangeEntries[_1f];
if(_1e){
_1e.location=_20.range.location;
_1e.length=_20.range.length;
}
return _20.attributes;
}
}),new objj_method(sel_getUid("attributesAtIndex:longestEffectiveRange:inRange:"),function(_21,_22,_23,_24,_25){
with(_21){
var _26=objj_msgSend(_21,"_indexOfEntryWithIndex:",_23);
if(_26==CPNotFound){
return nil;
}
if(!_24){
return _rangeEntries[_26].attributes;
}
if(CPRangeInRange(_rangeEntries[_26].range,_25)){
_24.location=_25.location;
_24.length=_25.length;
return _rangeEntries[_26].attributes;
}
var _27=_26-1,_28=_rangeEntries[_26],_29=_28.attributes;
while(_27>=0){
var _2a=_rangeEntries[_27];
if(CPMaxRange(_2a.range)>_25.location&&objj_msgSend(_2a.attributes,"isEqualToDictionary:",_29)){
_28=_2a;
_27--;
}else{
break;
}
}
_24.location=MAX(_28.range.location,_25.location);
_28=_rangeEntries[_26];
_27=_26+1;
while(_27<_rangeEntries.length){
var _2a=_rangeEntries[_27];
if(_2a.range.location<CPMaxRange(_25)&&objj_msgSend(_2a.attributes,"isEqualToDictionary:",_29)){
_28=_2a;
_27++;
}else{
break;
}
}
_24.length=MIN(CPMaxRange(_28.range),CPMaxRange(_25))-_24.location;
return _29;
}
}),new objj_method(sel_getUid("attribute:atIndex:effectiveRange:"),function(_2b,_2c,_2d,_2e,_2f){
with(_2b){
if(!_2d){
if(_2f){
_2f.location=0;
_2f.length=_string.length;
}
return nil;
}
return objj_msgSend(objj_msgSend(_2b,"attributesAtIndex:effectiveRange:",_2e,_2f),"valueForKey:",_2d);
}
}),new objj_method(sel_getUid("attribute:atIndex:longestEffectiveRange:inRange:"),function(_30,_31,_32,_33,_34,_35){
with(_30){
var _36=objj_msgSend(_30,"_indexOfEntryWithIndex:",_33);
if(_36==CPNotFound||!_32){
return nil;
}
if(!_34){
return objj_msgSend(_rangeEntries[_36].attributes,"objectForKey:",_32);
}
if(CPRangeInRange(_rangeEntries[_36].range,_35)){
_34.location=_35.location;
_34.length=_35.length;
return objj_msgSend(_rangeEntries[_36].attributes,"objectForKey:",_32);
}
var _37=_36-1,_38=_rangeEntries[_36],_39=objj_msgSend(_38.attributes,"objectForKey:",_32);
while(_37>=0){
var _3a=_rangeEntries[_37];
if(CPMaxRange(_3a.range)>_35.location&&_3b(_39,objj_msgSend(_3a.attributes,"objectForKey:",_32))){
_38=_3a;
_37--;
}else{
break;
}
}
_34.location=MAX(_38.range.location,_35.location);
_38=_rangeEntries[_36];
_37=_36+1;
while(_37<_rangeEntries.length){
var _3a=_rangeEntries[_37];
if(_3a.range.location<CPMaxRange(_35)&&_3b(_39,objj_msgSend(_3a.attributes,"objectForKey:",_32))){
_38=_3a;
_37++;
}else{
break;
}
}
_34.length=MIN(CPMaxRange(_38.range),CPMaxRange(_35))-_34.location;
return _39;
}
}),new objj_method(sel_getUid("isEqualToAttributedString:"),function(_3c,_3d,_3e){
with(_3c){
if(!_3e){
return NO;
}
if(_string!=objj_msgSend(_3e,"string")){
return NO;
}
var _3f=CPMakeRange(),_40=CPMakeRange(),_41=objj_msgSend(_3c,"attributesAtIndex:effectiveRange:",0,_3f),_42=objj_msgSend(_3e,"attributesAtIndex:effectiveRange:",0,_40),_43=_string.length;
while(CPMaxRange(CPUnionRange(_3f,_40))<_43){
if(CPIntersectionRange(_3f,_40).length>0&&!objj_msgSend(_41,"isEqualToDictionary:",_42)){
return NO;
}
if(CPMaxRange(_3f)<CPMaxRange(_40)){
_41=objj_msgSend(_3c,"attributesAtIndex:effectiveRange:",CPMaxRange(_3f),_3f);
}else{
_42=objj_msgSend(_3e,"attributesAtIndex:effectiveRange:",CPMaxRange(_40),_40);
}
}
return YES;
}
}),new objj_method(sel_getUid("isEqual:"),function(_44,_45,_46){
with(_44){
if(_46==_44){
return YES;
}
if(objj_msgSend(_46,"isKindOfClass:",objj_msgSend(_44,"class"))){
return objj_msgSend(_44,"isEqualToAttributedString:",_46);
}
return NO;
}
}),new objj_method(sel_getUid("attributedSubstringFromRange:"),function(_47,_48,_49){
with(_47){
if(!_49||CPMaxRange(_49)>_string.length||_49.location<0){
objj_msgSend(CPException,"raise:reason:",CPRangeException,"tried to get attributedSubstring for an invalid range: "+(_49?CPStringFromRange(_49):"nil"));
}
var _4a=objj_msgSend(objj_msgSend(CPAttributedString,"alloc"),"initWithString:",_string.substring(_49.location,CPMaxRange(_49))),_4b=objj_msgSend(_47,"_indexOfEntryWithIndex:",_49.location),_4c=_rangeEntries[_4b],_4d=CPMaxRange(_49);
_4a._rangeEntries=[];
while(_4c&&CPMaxRange(_4c.range)<_4d){
var _4e=_4f(_4c);
_4e.range.location-=_49.location;
if(_4e.range.location<0){
_4e.range.length+=_4e.range.location;
_4e.range.location=0;
}
_4a._rangeEntries.push(_4e);
_4c=_rangeEntries[++_4b];
}
if(_4c){
var _50=_4f(_4c);
_50.range.length=CPMaxRange(_49)-_50.range.location;
_50.range.location-=_49.location;
if(_50.range.location<0){
_50.range.length+=_50.range.location;
_50.range.location=0;
}
_4a._rangeEntries.push(_50);
}
return _4a;
}
}),new objj_method(sel_getUid("replaceCharactersInRange:withString:"),function(_51,_52,_53,_54){
with(_51){
objj_msgSend(_51,"beginEditing");
if(!_54){
_54="";
}
var _55=objj_msgSend(_51,"_indexOfEntryWithIndex:",_53.location),_56=_rangeEntries[_55],_57=objj_msgSend(_51,"_indexOfEntryWithIndex:",MAX(CPMaxRange(_53)-1,0)),_58=_rangeEntries[_57],_59=_54.length-_53.length;
_string=_string.substring(0,_53.location)+_54+_string.substring(CPMaxRange(_53));
if(_55==_57){
_56.range.length+=_59;
}else{
_58.range.length=CPMaxRange(_58.range)-CPMaxRange(_53);
_58.range.location=CPMaxRange(_53);
_56.range.length=CPMaxRange(_53)-_56.range.location;
_rangeEntries.splice(_55,_57-_55);
}
_57=_55+1;
while(_57<_rangeEntries.length){
_rangeEntries[_57++].range.location+=_59;
}
objj_msgSend(_51,"endEditing");
}
}),new objj_method(sel_getUid("deleteCharactersInRange:"),function(_5a,_5b,_5c){
with(_5a){
objj_msgSend(_5a,"replaceCharactersInRange:withString:",_5c,nil);
}
}),new objj_method(sel_getUid("setAttributes:range:"),function(_5d,_5e,_5f,_60){
with(_5d){
objj_msgSend(_5d,"beginEditing");
var _61=objj_msgSend(_5d,"_indexOfRangeEntryForIndex:splitOnMaxIndex:",_60.location,YES),_62=objj_msgSend(_5d,"_indexOfRangeEntryForIndex:splitOnMaxIndex:",CPMaxRange(_60),YES),_63=_61;
if(_62==CPNotFound){
_62=_rangeEntries.length;
}
while(_63<_62){
_rangeEntries[_63++].attributes=objj_msgSend(_5f,"copy");
}
objj_msgSend(_5d,"_coalesceRangeEntriesFromIndex:toIndex:",_61,_62);
objj_msgSend(_5d,"endEditing");
}
}),new objj_method(sel_getUid("addAttributes:range:"),function(_64,_65,_66,_67){
with(_64){
objj_msgSend(_64,"beginEditing");
var _68=objj_msgSend(_64,"_indexOfRangeEntryForIndex:splitOnMaxIndex:",_67.location,YES),_69=objj_msgSend(_64,"_indexOfRangeEntryForIndex:splitOnMaxIndex:",CPMaxRange(_67),YES),_6a=_68;
if(_69==CPNotFound){
_69=_rangeEntries.length;
}
while(_6a<_69){
var _6b=objj_msgSend(_66,"allKeys"),_6c=objj_msgSend(_6b,"count");
while(_6c--){
objj_msgSend(_rangeEntries[_6a].attributes,"setObject:forKey:",objj_msgSend(_66,"objectForKey:",_6b[_6c]),_6b[_6c]);
}
_6a++;
}
objj_msgSend(_64,"_coalesceRangeEntriesFromIndex:toIndex:",_68,_69);
objj_msgSend(_64,"endEditing");
}
}),new objj_method(sel_getUid("addAttribute:value:range:"),function(_6d,_6e,_6f,_70,_71){
with(_6d){
objj_msgSend(_6d,"addAttributes:range:",objj_msgSend(CPDictionary,"dictionaryWithObject:forKey:",_70,_6f),_71);
}
}),new objj_method(sel_getUid("removeAttribute:range:"),function(_72,_73,_74,_75){
with(_72){
objj_msgSend(_72,"beginEditing");
var _76=objj_msgSend(_72,"_indexOfRangeEntryForIndex:splitOnMaxIndex:",_75.location,YES),_77=objj_msgSend(_72,"_indexOfRangeEntryForIndex:splitOnMaxIndex:",CPMaxRange(_75),YES),_78=_76;
if(_77==CPNotFound){
_77=_rangeEntries.length;
}
while(_78<_77){
objj_msgSend(_rangeEntries[_78++].attributes,"removeObjectForKey:",_74);
}
objj_msgSend(_72,"_coalesceRangeEntriesFromIndex:toIndex:",_76,_77);
objj_msgSend(_72,"endEditing");
}
}),new objj_method(sel_getUid("appendAttributedString:"),function(_79,_7a,_7b){
with(_79){
objj_msgSend(_79,"insertAttributedString:atIndex:",_7b,_string.length);
}
}),new objj_method(sel_getUid("insertAttributedString:atIndex:"),function(_7c,_7d,_7e,_7f){
with(_7c){
objj_msgSend(_7c,"beginEditing");
if(_7f<0||_7f>objj_msgSend(_7c,"length")){
objj_msgSend(CPException,"raise:reason:",CPRangeException,"tried to insert attributed string at an invalid index: "+_7f);
}
var _80=objj_msgSend(_7c,"_indexOfRangeEntryForIndex:splitOnMaxIndex:",_7f,YES),_81=_7e._rangeEntries,_82=objj_msgSend(_7e,"length");
if(_80==CPNotFound){
_80=_rangeEntries.length;
}
_string=_string.substring(0,_7f)+_7e._string+_string.substring(_7f);
var _83=_80;
while(_83<_rangeEntries.length){
_rangeEntries[_83++].range.location+=_82;
}
var _84=_81.length,_85=0;
while(_85<_84){
var _86=_4f(_81[_85++]);
_86.range.location+=_7f;
_rangeEntries.splice(_80-1+_85,0,_86);
}
objj_msgSend(_7c,"endEditing");
}
}),new objj_method(sel_getUid("replaceCharactersInRange:withAttributedString:"),function(_87,_88,_89,_8a){
with(_87){
objj_msgSend(_87,"beginEditing");
objj_msgSend(_87,"deleteCharactersInRange:",_89);
objj_msgSend(_87,"insertAttributedString:atIndex:",_8a,_89.location);
objj_msgSend(_87,"endEditing");
}
}),new objj_method(sel_getUid("setAttributedString:"),function(_8b,_8c,_8d){
with(_8b){
objj_msgSend(_8b,"beginEditing");
_string=_8d._string;
_rangeEntries=[];
for(var i=0,_8e=_8d._rangeEntries.length;i<_8e;i++){
_rangeEntries.push(_4f(_8d._rangeEntries[i]));
}
objj_msgSend(_8b,"endEditing");
}
}),new objj_method(sel_getUid("_indexOfRangeEntryForIndex:splitOnMaxIndex:"),function(_8f,_90,_91,_92){
with(_8f){
var _93=objj_msgSend(_8f,"_indexOfEntryWithIndex:",_91);
if(_93<0){
return _93;
}
var _94=_rangeEntries[_93];
if(_94.range.location==_91||(CPMaxRange(_94.range)-1==_91&&!_92)){
return _93;
}
var _95=splitRangeEntryAtIndex(_94,_91);
_rangeEntries.splice(_93,1,_95[0],_95[1]);
_93++;
return _93;
}
}),new objj_method(sel_getUid("_coalesceRangeEntriesFromIndex:toIndex:"),function(_96,_97,_98,end){
with(_96){
var _99=_98;
if(end>=_rangeEntries.length){
end=_rangeEntries.length-1;
}
while(_99<end){
var a=_rangeEntries[_99],b=_rangeEntries[_99+1];
if(objj_msgSend(a.attributes,"isEqualToDictionary:",b.attributes)){
a.range.length=CPMaxRange(b.range)-a.range.location;
_rangeEntries.splice(_99+1,1);
end--;
}else{
_99++;
}
}
}
}),new objj_method(sel_getUid("beginEditing"),function(_9a,_9b){
with(_9a){
}
}),new objj_method(sel_getUid("endEditing"),function(_9c,_9d){
with(_9c){
}
})]);
var _1=objj_allocateClassPair(CPAttributedString,"CPMutableAttributedString"),_2=_1.isa;
objj_registerClassPair(_1);
var _3b=_3b=function(a,b){
if(a==b){
return YES;
}
if(objj_msgSend(a,"respondsToSelector:",sel_getUid("isEqual:"))&&objj_msgSend(a,"isEqual:",b)){
return YES;
}
return NO;
};
var _e=_e=function(_9e,_9f){
return {range:_9e,attributes:objj_msgSend(_9f,"copy")};
};
var _4f=_4f=function(_a0){
return _e(CPCopyRange(_a0.range),objj_msgSend(_a0.attributes,"copy"));
};
var _a1=splitRangeEntryAtIndex=function(_a2,_a3){
var _a4=_4f(_a2),_a5=CPMaxRange(_a2.range);
_a2.range.length=_a3-_a2.range.location;
_a4.range.location=_a3;
_a4.range.length=_a5-_a3;
_a4.attributes=objj_msgSend(_a4.attributes,"copy");
return [_a2,_a4];
};
p;10;CPBundle.jt;3122;@STATIC;1.0;i;10;CPObject.ji;14;CPDictionary.ji;14;CPURLRequest.jt;3050;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPDictionary.j",true);
objj_executeFile("CPURLRequest.j",true);
var _1={};
var _2=objj_allocateClassPair(CPObject,"CPBundle"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_bundle"),new objj_ivar("_delegate")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("initWithPath:"),function(_4,_5,_6){
with(_4){
var _7=_1[_6];
if(_7){
return _7;
}
_4=objj_msgSendSuper({receiver:_4,super_class:objj_getClass("CPBundle").super_class},"init");
if(_4){
_bundle=new CFBundle(_6);
_1[_6]=_4;
}
return _4;
}
}),new objj_method(sel_getUid("classNamed:"),function(_8,_9,_a){
with(_8){
}
}),new objj_method(sel_getUid("bundlePath"),function(_b,_c){
with(_b){
return _bundle.path();
}
}),new objj_method(sel_getUid("resourcePath"),function(_d,_e){
with(_d){
var _f=objj_msgSend(_d,"bundlePath");
if(_f.length){
_f+="/";
}
return _f+"Resources";
}
}),new objj_method(sel_getUid("principalClass"),function(_10,_11){
with(_10){
var _12=objj_msgSend(_10,"objectForInfoDictionaryKey:","CPPrincipalClass");
return _12?CPClassFromString(_12):Nil;
}
}),new objj_method(sel_getUid("pathForResource:"),function(_13,_14,_15){
with(_13){
return _bundle.pathForResource(_15);
}
}),new objj_method(sel_getUid("infoDictionary"),function(_16,_17){
with(_16){
return _bundle.infoDictionary();
}
}),new objj_method(sel_getUid("objectForInfoDictionaryKey:"),function(_18,_19,_1a){
with(_18){
return _bundle.valueForInfoDictionary(_1a);
}
}),new objj_method(sel_getUid("loadWithDelegate:"),function(_1b,_1c,_1d){
with(_1b){
_delegate=_1d;
_bundle.addEventListener("load",function(){
objj_msgSend(_delegate,"bundleDidFinishLoading:",_1b);
});
_bundle.addEventListener("error",function(){
CPLog.error("Could not find bundle: "+_1b);
});
_bundle.load(YES);
}
}),new objj_method(sel_getUid("staticResourceURLs"),function(_1e,_1f){
with(_1e){
var _20=[],_21=_bundle.staticResources(),_22=0,_23=objj_msgSend(_21,"count");
for(;_22<_23;++_22){
objj_msgSend(_20,"addObject:",objj_msgSend(CPURL,"URLWithString:",_21[_22].path()));
}
return _20;
}
}),new objj_method(sel_getUid("environments"),function(_24,_25){
with(_24){
return _bundle.environments();
}
}),new objj_method(sel_getUid("mostEligibleEnvironment"),function(_26,_27){
with(_26){
return _bundle.mostEligibleEnvironment();
}
}),new objj_method(sel_getUid("description"),function(_28,_29){
with(_28){
return objj_msgSendSuper({receiver:_28,super_class:objj_getClass("CPBundle").super_class},"description")+"("+objj_msgSend(_28,"bundlePath")+")";
}
})]);
class_addMethods(_3,[new objj_method(sel_getUid("bundleWithPath:"),function(_2a,_2b,_2c){
with(_2a){
return objj_msgSend(objj_msgSend(_2a,"alloc"),"initWithPath:",_2c);
}
}),new objj_method(sel_getUid("bundleForClass:"),function(_2d,_2e,_2f){
with(_2d){
return objj_msgSend(_2d,"bundleWithPath:",CFBundle.bundleForClass(_2f).path());
}
}),new objj_method(sel_getUid("mainBundle"),function(_30,_31){
with(_30){
return objj_msgSend(CPBundle,"bundleWithPath:",CFBundle.mainBundle().path());
}
})]);
p;9;CPCoder.jt;1900;@STATIC;1.0;i;10;CPObject.ji;13;CPException.jt;1848;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPException.j",true);
var _1=objj_allocateClassPair(CPObject,"CPCoder"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("allowsKeyedCoding"),function(_3,_4){
with(_3){
return NO;
}
}),new objj_method(sel_getUid("encodeValueOfObjCType:at:"),function(_5,_6,_7,_8){
with(_5){
CPInvalidAbstractInvocation();
}
}),new objj_method(sel_getUid("encodeDataObject:"),function(_9,_a,_b){
with(_9){
CPInvalidAbstractInvocation();
}
}),new objj_method(sel_getUid("encodeObject:"),function(_c,_d,_e){
with(_c){
}
}),new objj_method(sel_getUid("encodePoint:"),function(_f,_10,_11){
with(_f){
objj_msgSend(_f,"encodeNumber:",_11.x);
objj_msgSend(_f,"encodeNumber:",_11.y);
}
}),new objj_method(sel_getUid("encodeRect:"),function(_12,_13,_14){
with(_12){
objj_msgSend(_12,"encodePoint:",_14.origin);
objj_msgSend(_12,"encodeSize:",_14.size);
}
}),new objj_method(sel_getUid("encodeSize:"),function(_15,_16,_17){
with(_15){
objj_msgSend(_15,"encodeNumber:",_17.width);
objj_msgSend(_15,"encodeNumber:",_17.height);
}
}),new objj_method(sel_getUid("encodePropertyList:"),function(_18,_19,_1a){
with(_18){
}
}),new objj_method(sel_getUid("encodeRootObject:"),function(_1b,_1c,_1d){
with(_1b){
objj_msgSend(_1b,"encodeObject:",_1d);
}
}),new objj_method(sel_getUid("encodeBycopyObject:"),function(_1e,_1f,_20){
with(_1e){
objj_msgSend(_1e,"encodeObject:",object);
}
}),new objj_method(sel_getUid("encodeConditionalObject:"),function(_21,_22,_23){
with(_21){
objj_msgSend(_21,"encodeObject:",object);
}
})]);
var _1=objj_getClass("CPObject");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPObject\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("awakeAfterUsingCoder:"),function(_24,_25,_26){
with(_24){
return _24;
}
})]);
p;14;CPCountedSet.jt;1288;@STATIC;1.0;i;7;CPSet.jt;1258;
objj_executeFile("CPSet.j",true);
var _1=objj_allocateClassPair(CPMutableSet,"CPCountedSet"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_counts")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("addObject:"),function(_3,_4,_5){
with(_3){
if(!_counts){
_counts={};
}
objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPCountedSet").super_class},"addObject:",_5);
var _6=objj_msgSend(_5,"UID");
if(_counts[_6]===undefined){
_counts[_6]=1;
}else{
++_counts[_6];
}
}
}),new objj_method(sel_getUid("removeObject:"),function(_7,_8,_9){
with(_7){
if(!_counts){
return;
}
var _a=objj_msgSend(_9,"UID");
if(_counts[_a]===undefined){
return;
}else{
--_counts[_a];
if(_counts[_a]===0){
delete _counts[_a];
objj_msgSendSuper({receiver:_7,super_class:objj_getClass("CPCountedSet").super_class},"removeObject:",_9);
}
}
}
}),new objj_method(sel_getUid("removeAllObjects"),function(_b,_c){
with(_b){
objj_msgSendSuper({receiver:_b,super_class:objj_getClass("CPCountedSet").super_class},"removeAllObjects");
_counts={};
}
}),new objj_method(sel_getUid("countForObject:"),function(_d,_e,_f){
with(_d){
if(!_counts){
_counts={};
}
var UID=objj_msgSend(_f,"UID");
if(_counts[UID]===undefined){
return 0;
}
return _counts[UID];
}
})]);
p;8;CPData.jt;3159;@STATIC;1.0;i;10;CPObject.ji;10;CPString.jt;3110;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPString.j",true);
var _1=objj_allocateClassPair(CPObject,"CPData"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithEncodedString:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPData").super_class},"init");
if(_3){
objj_msgSend(_3,"setEncodedString:",_5);
}
return _3;
}
}),new objj_method(sel_getUid("initWithString:"),function(_6,_7,_8){
with(_6){
return objj_msgSend(_6,"initWithSerializedPlistObject:",aPlistObject);
}
}),new objj_method(sel_getUid("initWithSerializedPlistObject:"),function(_9,_a,_b){
with(_9){
_9=objj_msgSendSuper({receiver:_9,super_class:objj_getClass("CPData").super_class},"init");
if(_9){
objj_msgSend(_9,"setSerializedPlistObject:",_b);
}
return _9;
}
}),new objj_method(sel_getUid("initWithSerializedPlistObject:format:"),function(_c,_d,_e,_f){
with(_c){
_c=objj_msgSendSuper({receiver:_c,super_class:objj_getClass("CPData").super_class},"init");
if(_c){
objj_msgSend(_c,"setSerializedPlistObject:format:",_e,_f);
}
return _c;
}
}),new objj_method(sel_getUid("setString:"),function(_10,_11,_12){
with(_10){
return objj_msgSend(_10,"setSerializedPlistObject:",_12);
}
}),new objj_method(sel_getUid("string"),function(_13,_14){
with(_13){
return objj_msgSend(_13,"serializedPlistObject");
}
}),new objj_method(sel_getUid("length"),function(_15,_16){
with(_15){
return objj_msgSend(objj_msgSend(_15,"encodedString"),"length");
}
}),new objj_method(sel_getUid("description"),function(_17,_18){
with(_17){
return _17.toString();
}
}),new objj_method(sel_getUid("encodedString"),function(_19,_1a){
with(_19){
return _19.encodedString();
}
}),new objj_method(sel_getUid("setEncodedString:"),function(_1b,_1c,_1d){
with(_1b){
_1b.setEncodedString(_1d);
}
}),new objj_method(sel_getUid("serializedPlistObject"),function(_1e,_1f){
with(_1e){
return _1e.serializedPropertyList();
}
}),new objj_method(sel_getUid("setSerializedPlistObject:"),function(_20,_21,_22){
with(_20){
_20.setSerializedPropertyList(_22);
}
}),new objj_method(sel_getUid("setSerializedPlistObject:format:"),function(_23,_24,_25,_26){
with(_23){
_23.setSerializedPropertyList(_25,_26);
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("alloc"),function(_27,_28){
with(_27){
return new CFMutableData();
}
}),new objj_method(sel_getUid("data"),function(_29,_2a){
with(_29){
return objj_msgSend(objj_msgSend(_29,"alloc"),"init");
}
}),new objj_method(sel_getUid("dataWithEncodedString:"),function(_2b,_2c,_2d){
with(_2b){
return objj_msgSend(objj_msgSend(_2b,"alloc"),"initWithEncodedString:",_2d);
}
}),new objj_method(sel_getUid("dataWithSerializedPlistObject:"),function(_2e,_2f,_30){
with(_2e){
return objj_msgSend(objj_msgSend(_2e,"alloc"),"initWithSerializedPlistObject:",_30);
}
}),new objj_method(sel_getUid("dataWithSerializedPlistObject:format:"),function(_31,_32,_33,_34){
with(_31){
return objj_msgSend(objj_msgSend(_31,"alloc"),"initWithSerializedPlistObject:format:",_33,_34);
}
})]);
CFData.prototype.isa=CPData;
CFMutableData.prototype.isa=CPData;
p;8;CPDate.jt;4921;@STATIC;1.0;i;10;CPObject.ji;10;CPString.jt;4872;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPString.j",true);
var _1=new Date(Date.UTC(2001,1,1,0,0,0,0));
var _2=objj_allocateClassPair(CPObject,"CPDate"),_3=_2.isa;
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("initWithTimeIntervalSinceNow:"),function(_4,_5,_6){
with(_4){
_4=new Date((new Date()).getTime()+_6*1000);
return _4;
}
}),new objj_method(sel_getUid("initWithTimeIntervalSince1970:"),function(_7,_8,_9){
with(_7){
_7=new Date(_9*1000);
return _7;
}
}),new objj_method(sel_getUid("initWithTimeIntervalSinceReferenceDate:"),function(_a,_b,_c){
with(_a){
_a=objj_msgSend(_a,"initWithTimeInterval:sinceDate:",_c,_1);
return _a;
}
}),new objj_method(sel_getUid("initWithTimeInterval:sinceDate:"),function(_d,_e,_f,_10){
with(_d){
_d=new Date(_10.getTime()+_f*1000);
return _d;
}
}),new objj_method(sel_getUid("initWithString:"),function(_11,_12,_13){
with(_11){
var _14=/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) ([-+])(\d{2})(\d{2})/,d=_13.match(new RegExp(_14));
if(!d||d.length!=10){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"initWithString: the string must be of YYYY-MM-DD HH:MM:SS ±HHMM format");
}
var _15=new Date(d[1],d[2]-1,d[3]),_16=(Number(d[8])*60+Number(d[9]))*(d[7]==="-"?-1:1);
_15.setHours(d[4]);
_15.setMinutes(d[5]);
_15.setSeconds(d[6]);
_11=new Date(_15.getTime()+(_16-_15.getTimezoneOffset())*60*1000);
return _11;
}
}),new objj_method(sel_getUid("timeIntervalSinceDate:"),function(_17,_18,_19){
with(_17){
return (_17.getTime()-_19.getTime())/1000;
}
}),new objj_method(sel_getUid("timeIntervalSinceNow"),function(_1a,_1b){
with(_1a){
return objj_msgSend(_1a,"timeIntervalSinceDate:",objj_msgSend(CPDate,"date"));
}
}),new objj_method(sel_getUid("timeIntervalSince1970"),function(_1c,_1d){
with(_1c){
return _1c.getTime()/1000;
}
}),new objj_method(sel_getUid("timeIntervalSinceReferenceDate"),function(_1e,_1f){
with(_1e){
return (_1e.getTime()-_1.getTime())/1000;
}
}),new objj_method(sel_getUid("isEqual:"),function(_20,_21,_22){
with(_20){
return objj_msgSend(_20,"isEqualToDate:",_22);
}
}),new objj_method(sel_getUid("isEqualToDate:"),function(_23,_24,_25){
with(_23){
return _23===_25||(_25!==nil&&_25.isa&&objj_msgSend(_25,"isKindOfClass:",CPDate)&&!(_23<_25||_23>_25));
}
}),new objj_method(sel_getUid("compare:"),function(_26,_27,_28){
with(_26){
return (_26>_28)?CPOrderedDescending:((_26<_28)?CPOrderedAscending:CPOrderedSame);
}
}),new objj_method(sel_getUid("earlierDate:"),function(_29,_2a,_2b){
with(_29){
return (_29<_2b)?_29:_2b;
}
}),new objj_method(sel_getUid("laterDate:"),function(_2c,_2d,_2e){
with(_2c){
return (_2c>_2e)?_2c:_2e;
}
}),new objj_method(sel_getUid("description"),function(_2f,_30){
with(_2f){
var _31=Math.floor(_2f.getTimezoneOffset()/60),_32=_2f.getTimezoneOffset()-_31*60;
return objj_msgSend(CPString,"stringWithFormat:","%04d-%02d-%02d %02d:%02d:%02d +%02d%02d",_2f.getFullYear(),_2f.getMonth()+1,_2f.getDate(),_2f.getHours(),_2f.getMinutes(),_2f.getSeconds(),_31,_32);
}
}),new objj_method(sel_getUid("copy"),function(_33,_34){
with(_33){
return new Date(_33.getTime());
}
})]);
class_addMethods(_3,[new objj_method(sel_getUid("alloc"),function(_35,_36){
with(_35){
return new Date;
}
}),new objj_method(sel_getUid("date"),function(_37,_38){
with(_37){
return objj_msgSend(objj_msgSend(_37,"alloc"),"init");
}
}),new objj_method(sel_getUid("dateWithTimeIntervalSinceNow:"),function(_39,_3a,_3b){
with(_39){
return objj_msgSend(objj_msgSend(CPDate,"alloc"),"initWithTimeIntervalSinceNow:",_3b);
}
}),new objj_method(sel_getUid("dateWithTimeIntervalSince1970:"),function(_3c,_3d,_3e){
with(_3c){
return objj_msgSend(objj_msgSend(CPDate,"alloc"),"initWithTimeIntervalSince1970:",_3e);
}
}),new objj_method(sel_getUid("dateWithTimeIntervalSinceReferenceDate:"),function(_3f,_40,_41){
with(_3f){
return objj_msgSend(objj_msgSend(CPDate,"alloc"),"initWithTimeIntervalSinceReferenceDate:",_41);
}
}),new objj_method(sel_getUid("distantPast"),function(_42,_43){
with(_42){
return new Date(-10000,1,1,0,0,0,0);
}
}),new objj_method(sel_getUid("distantFuture"),function(_44,_45){
with(_44){
return new Date(10000,1,1,0,0,0,0);
}
}),new objj_method(sel_getUid("timeIntervalSinceReferenceDate"),function(_46,_47){
with(_46){
return objj_msgSend(objj_msgSend(CPDate,"date"),"timeIntervalSinceReferenceDate");
}
})]);
var _48="CPDateTimeKey";
var _2=objj_getClass("CPDate");
if(!_2){
throw new SyntaxError("*** Could not find definition for class \"CPDate\"");
}
var _3=_2.isa;
class_addMethods(_2,[new objj_method(sel_getUid("initWithCoder:"),function(_49,_4a,_4b){
with(_49){
if(_49){
_49.setTime(objj_msgSend(_4b,"decodeIntForKey:",_48));
}
return _49;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_4c,_4d,_4e){
with(_4c){
objj_msgSend(_4e,"encodeInt:forKey:",_4c.getTime(),_48);
}
})]);
Date.prototype.isa=CPDate;
p;14;CPDictionary.jt;7819;@STATIC;1.0;i;9;CPArray.ji;10;CPObject.ji;14;CPEnumerator.ji;13;CPException.jt;7735;
objj_executeFile("CPArray.j",true);
objj_executeFile("CPObject.j",true);
objj_executeFile("CPEnumerator.j",true);
objj_executeFile("CPException.j",true);
var _1=objj_allocateClassPair(CPEnumerator,"_CPDictionaryValueEnumerator"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_keyEnumerator"),new objj_ivar("_dictionary")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithDictionary:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("_CPDictionaryValueEnumerator").super_class},"init");
if(_3){
_keyEnumerator=objj_msgSend(_5,"keyEnumerator");
_dictionary=_5;
}
return _3;
}
}),new objj_method(sel_getUid("nextObject"),function(_6,_7){
with(_6){
var _8=objj_msgSend(_keyEnumerator,"nextObject");
if(!_8){
return nil;
}
return objj_msgSend(_dictionary,"objectForKey:",_8);
}
})]);
var _1=objj_allocateClassPair(CPObject,"CPDictionary"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithDictionary:"),function(_9,_a,_b){
with(_9){
var _c="",_d=objj_msgSend(objj_msgSend(CPDictionary,"alloc"),"init");
for(_c in _b._buckets){
objj_msgSend(_d,"setObject:forKey:",objj_msgSend(_b,"objectForKey:",_c),_c);
}
return _d;
}
}),new objj_method(sel_getUid("initWithObjects:forKeys:"),function(_e,_f,_10,_11){
with(_e){
_e=objj_msgSendSuper({receiver:_e,super_class:objj_getClass("CPDictionary").super_class},"init");
if(objj_msgSend(_10,"count")!=objj_msgSend(_11,"count")){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"Counts are different.("+objj_msgSend(_10,"count")+"!="+objj_msgSend(_11,"count")+")");
}
if(_e){
var i=objj_msgSend(_11,"count");
while(i--){
objj_msgSend(_e,"setObject:forKey:",_10[i],_11[i]);
}
}
return _e;
}
}),new objj_method(sel_getUid("initWithObjectsAndKeys:"),function(_12,_13,_14){
with(_12){
var _15=arguments.length;
if(_15%2!==0){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"Key-value count is mismatched. ("+_15+" arguments passed)");
}
_12=objj_msgSendSuper({receiver:_12,super_class:objj_getClass("CPDictionary").super_class},"init");
if(_12){
var _16=2;
for(;_16<_15;_16+=2){
var _17=arguments[_16];
if(_17===nil){
break;
}
objj_msgSend(_12,"setObject:forKey:",_17,arguments[_16+1]);
}
}
return _12;
}
}),new objj_method(sel_getUid("copy"),function(_18,_19){
with(_18){
return objj_msgSend(CPDictionary,"dictionaryWithDictionary:",_18);
}
}),new objj_method(sel_getUid("count"),function(_1a,_1b){
with(_1a){
return _count;
}
}),new objj_method(sel_getUid("allKeys"),function(_1c,_1d){
with(_1c){
return _keys;
}
}),new objj_method(sel_getUid("allValues"),function(_1e,_1f){
with(_1e){
var _20=_keys.length,_21=[];
while(_20--){
_21.push(_1e.valueForKey(_keys[_20]));
}
return _21;
}
}),new objj_method(sel_getUid("keyEnumerator"),function(_22,_23){
with(_22){
return objj_msgSend(_keys,"objectEnumerator");
}
}),new objj_method(sel_getUid("objectEnumerator"),function(_24,_25){
with(_24){
return objj_msgSend(objj_msgSend(_CPDictionaryValueEnumerator,"alloc"),"initWithDictionary:",_24);
}
}),new objj_method(sel_getUid("isEqualToDictionary:"),function(_26,_27,_28){
with(_26){
var _29=objj_msgSend(_26,"count");
if(_29!==objj_msgSend(_28,"count")){
return NO;
}
var _2a=_29;
while(_2a--){
var _2b=_keys[_2a],_2c=_buckets[_2b],_2d=_28._buckets[_2b];
if(_2c===_2d){
continue;
}
if(_2c&&_2c.isa&&_2d&&_2d.isa&&objj_msgSend(_2c,"respondsToSelector:",sel_getUid("isEqual:"))&&objj_msgSend(_2c,"isEqual:",_2d)){
continue;
}
return NO;
}
return YES;
}
}),new objj_method(sel_getUid("objectForKey:"),function(_2e,_2f,_30){
with(_2e){
var _31=_buckets[_30];
return (_31===undefined)?nil:_31;
}
}),new objj_method(sel_getUid("removeAllObjects"),function(_32,_33){
with(_32){
_32.removeAllValues();
}
}),new objj_method(sel_getUid("removeObjectForKey:"),function(_34,_35,_36){
with(_34){
_34.removeValueForKey(_36);
}
}),new objj_method(sel_getUid("removeObjectsForKeys:"),function(_37,_38,_39){
with(_37){
var _3a=_39.length;
while(_3a--){
_37.removeValueForKey(_39[_3a]);
}
}
}),new objj_method(sel_getUid("setObject:forKey:"),function(_3b,_3c,_3d,_3e){
with(_3b){
_3b.setValueForKey(_3e,_3d);
}
}),new objj_method(sel_getUid("addEntriesFromDictionary:"),function(_3f,_40,_41){
with(_3f){
if(!_41){
return;
}
var _42=objj_msgSend(_41,"allKeys"),_43=objj_msgSend(_42,"count");
while(_43--){
var key=_42[_43];
objj_msgSend(_3f,"setObject:forKey:",objj_msgSend(_41,"objectForKey:",key),key);
}
}
}),new objj_method(sel_getUid("description"),function(_44,_45){
with(_44){
return _44.toString();
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("alloc"),function(_46,_47){
with(_46){
return new CFMutableDictionary();
}
}),new objj_method(sel_getUid("dictionary"),function(_48,_49){
with(_48){
return objj_msgSend(objj_msgSend(_48,"alloc"),"init");
}
}),new objj_method(sel_getUid("dictionaryWithDictionary:"),function(_4a,_4b,_4c){
with(_4a){
return objj_msgSend(objj_msgSend(_4a,"alloc"),"initWithDictionary:",_4c);
}
}),new objj_method(sel_getUid("dictionaryWithObject:forKey:"),function(_4d,_4e,_4f,_50){
with(_4d){
return objj_msgSend(objj_msgSend(_4d,"alloc"),"initWithObjects:forKeys:",[_4f],[_50]);
}
}),new objj_method(sel_getUid("dictionaryWithObjects:forKeys:"),function(_51,_52,_53,_54){
with(_51){
return objj_msgSend(objj_msgSend(_51,"alloc"),"initWithObjects:forKeys:",_53,_54);
}
}),new objj_method(sel_getUid("dictionaryWithJSObject:"),function(_55,_56,_57){
with(_55){
return objj_msgSend(_55,"dictionaryWithJSObject:recursively:",_57,NO);
}
}),new objj_method(sel_getUid("dictionaryWithJSObject:recursively:"),function(_58,_59,_5a,_5b){
with(_58){
var _5c=objj_msgSend(objj_msgSend(_58,"alloc"),"init");
for(var key in _5a){
if(!_5a.hasOwnProperty(key)){
continue;
}
var _5d=_5a[key];
if(_5b){
if(_5d.constructor===Object){
_5d=objj_msgSend(CPDictionary,"dictionaryWithJSObject:recursively:",_5d,YES);
}else{
if(objj_msgSend(_5d,"isKindOfClass:",CPArray)){
var _5e=[];
for(var i=0,_5f=_5d.length;i<_5f;i++){
var _60=_5d[i];
if(_60.constructor===Object){
_5e.push(objj_msgSend(CPDictionary,"dictionaryWithJSObject:recursively:",_60,YES));
}else{
_5e.push(_60);
}
}
_5d=_5e;
}
}
}
objj_msgSend(_5c,"setObject:forKey:",_5d,key);
}
return _5c;
}
}),new objj_method(sel_getUid("dictionaryWithObjectsAndKeys:"),function(_61,_62,_63){
with(_61){
arguments[0]=objj_msgSend(_61,"alloc");
arguments[1]=sel_getUid("initWithObjectsAndKeys:");
return objj_msgSend.apply(this,arguments);
}
})]);
var _1=objj_getClass("CPDictionary");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPDictionary\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_64,_65,_66){
with(_64){
return objj_msgSend(_66,"_decodeDictionaryOfObjectsForKey:","CP.objects");
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_67,_68,_69){
with(_67){
objj_msgSend(_69,"_encodeDictionaryOfObjects:forKey:",_67,"CP.objects");
}
})]);
var _1=objj_getClass("CPDictionary");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPDictionary\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("countByEnumeratingWithState:objects:count:"),function(_6a,_6b,_6c,_6d,_6e){
with(_6a){
var _6f=objj_msgSend(_6a,"count");
if(_6c.state>=_6f){
return 0;
}
var _70=objj_msgSend(_6a,"allKeys"),_71=_6f,_6d=new Array(_6f);
while(_71--){
_6d[_71]=objj_msgSend(_6a,"objectForKey:",_70[_71]);
}
_6c.items0=_6d;
_6c.items1=_70;
_6c.state=_6f;
return _6f;
}
})]);
var _1=objj_allocateClassPair(CPDictionary,"CPMutableDictionary"),_2=_1.isa;
objj_registerClassPair(_1);
CFDictionary.prototype.isa=CPDictionary;
CFMutableDictionary.prototype.isa=CPMutableDictionary;
p;14;CPEnumerator.jt;578;@STATIC;1.0;i;10;CPObject.jt;545;
objj_executeFile("CPObject.j",true);
var _1=objj_allocateClassPair(CPObject,"CPEnumerator"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("nextObject"),function(_3,_4){
with(_3){
return nil;
}
}),new objj_method(sel_getUid("allObjects"),function(_5,_6){
with(_5){
return [];
}
}),new objj_method(sel_getUid("countByEnumeratingWithState:objects:count:"),function(_7,_8,_9,_a,_b){
with(_7){
return objj_msgSend(objj_msgSend(_7,"allObjects"),"countByEnumeratingWithState:objects:count:",_9,_a,_b);
}
})]);
p;13;CPException.jt;3508;@STATIC;1.0;i;9;CPCoder.ji;10;CPObject.ji;10;CPString.jt;3446;
objj_executeFile("CPCoder.j",true);
objj_executeFile("CPObject.j",true);
objj_executeFile("CPString.j",true);
CPInvalidArgumentException="CPInvalidArgumentException";
CPUnsupportedMethodException="CPUnsupportedMethodException";
CPRangeException="CPRangeException";
CPInternalInconsistencyException="CPInternalInconsistencyException";
var _1=objj_allocateClassPair(CPObject,"CPException"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_userInfo")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithName:reason:userInfo:"),function(_3,_4,_5,_6,_7){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPException").super_class},"init");
if(_3){
name=_5;
message=_6;
_userInfo=_7;
}
return _3;
}
}),new objj_method(sel_getUid("name"),function(_8,_9){
with(_8){
return name;
}
}),new objj_method(sel_getUid("reason"),function(_a,_b){
with(_a){
return message;
}
}),new objj_method(sel_getUid("userInfo"),function(_c,_d){
with(_c){
return _userInfo;
}
}),new objj_method(sel_getUid("description"),function(_e,_f){
with(_e){
return message;
}
}),new objj_method(sel_getUid("raise"),function(_10,_11){
with(_10){
throw _10;
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("alloc"),function(_12,_13){
with(_12){
return new Error();
}
}),new objj_method(sel_getUid("raise:reason:"),function(_14,_15,_16,_17){
with(_14){
objj_msgSend(objj_msgSend(_14,"exceptionWithName:reason:userInfo:",_16,_17,nil),"raise");
}
}),new objj_method(sel_getUid("exceptionWithName:reason:userInfo:"),function(_18,_19,_1a,_1b,_1c){
with(_18){
return objj_msgSend(objj_msgSend(_18,"alloc"),"initWithName:reason:userInfo:",_1a,_1b,_1c);
}
})]);
var _1=objj_getClass("CPException");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPException\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("copy"),function(_1d,_1e){
with(_1d){
return objj_msgSend(objj_msgSend(_1d,"class"),"exceptionWithName:reason:userInfo:",name,message,_userInfo);
}
})]);
var _1f="CPExceptionNameKey",_20="CPExceptionReasonKey",_21="CPExceptionUserInfoKey";
var _1=objj_getClass("CPException");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPException\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_22,_23,_24){
with(_22){
_22=objj_msgSendSuper({receiver:_22,super_class:objj_getClass("CPException").super_class},"init");
if(_22){
name=objj_msgSend(_24,"decodeObjectForKey:",_1f);
message=objj_msgSend(_24,"decodeObjectForKey:",_20);
_userInfo=objj_msgSend(_24,"decodeObjectForKey:",_21);
}
return _22;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_25,_26,_27){
with(_25){
objj_msgSend(_27,"encodeObject:forKey:",name,_1f);
objj_msgSend(_27,"encodeObject:forKey:",message,_20);
objj_msgSend(_27,"encodeObject:forKey:",_userInfo,_21);
}
})]);
Error.prototype.isa=CPException;
Error.prototype._userInfo=NULL;
objj_msgSend(CPException,"initialize");
_CPRaiseInvalidAbstractInvocation=function(_28,_29){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"*** -"+sel_getName(_29)+" cannot be sent to an abstract object of class "+objj_msgSend(_28,"className")+": Create a concrete instance!");
};
_CPReportLenientDeprecation=function(_2a,_2b,_2c){
CPLog.warn("["+CPStringFromClass(_2a)+" "+CPStringFromSelector(_2b)+"] is deprecated, using "+CPStringFromSelector(_2c)+" instead.");
};
p;21;CPFunctionOperation.jt;1270;@STATIC;1.0;I;21;Foundation/CPObject.ji;13;CPOperation.jt;1207;
objj_executeFile("Foundation/CPObject.j",false);
objj_executeFile("CPOperation.j",true);
var _1=objj_allocateClassPair(CPOperation,"CPFunctionOperation"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_functions")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("main"),function(_3,_4){
with(_3){
if(_functions&&objj_msgSend(_functions,"count")>0){
var i=0;
for(i=0;i<objj_msgSend(_functions,"count");i++){
var _5=objj_msgSend(_functions,"objectAtIndex:",i);
_5();
}
}
}
}),new objj_method(sel_getUid("init"),function(_6,_7){
with(_6){
if(_6=objj_msgSendSuper({receiver:_6,super_class:objj_getClass("CPFunctionOperation").super_class},"init")){
_functions=[];
}
return _6;
}
}),new objj_method(sel_getUid("addExecutionFunction:"),function(_8,_9,_a){
with(_8){
objj_msgSend(_functions,"addObject:",_a);
}
}),new objj_method(sel_getUid("executionFunctions"),function(_b,_c){
with(_b){
return _functions;
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("functionOperationWithFunction:"),function(_d,_e,_f){
with(_d){
functionOp=objj_msgSend(objj_msgSend(CPFunctionOperation,"alloc"),"init");
objj_msgSend(functionOp,"addExecutionFunction:",_f);
return functionOp;
}
})]);
p;12;CPIndexSet.jt;12214;@STATIC;1.0;i;9;CPRange.ji;10;CPObject.jt;12166;
objj_executeFile("CPRange.j",true);
objj_executeFile("CPObject.j",true);
var _1=objj_allocateClassPair(CPObject,"CPIndexSet"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_count"),new objj_ivar("_ranges")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("init"),function(_3,_4){
with(_3){
return objj_msgSend(_3,"initWithIndexesInRange:",{location:(0),length:0});
}
}),new objj_method(sel_getUid("initWithIndex:"),function(_5,_6,_7){
with(_5){
return objj_msgSend(_5,"initWithIndexesInRange:",{location:(_7),length:1});
}
}),new objj_method(sel_getUid("initWithIndexesInRange:"),function(_8,_9,_a){
with(_8){
_8=objj_msgSendSuper({receiver:_8,super_class:objj_getClass("CPIndexSet").super_class},"init");
if(_8){
_count=MAX(0,_a.length);
if(_count>0){
_ranges=[_a];
}else{
_ranges=[];
}
}
return _8;
}
}),new objj_method(sel_getUid("initWithIndexSet:"),function(_b,_c,_d){
with(_b){
_b=objj_msgSendSuper({receiver:_b,super_class:objj_getClass("CPIndexSet").super_class},"init");
if(_b){
_count=objj_msgSend(_d,"count");
_ranges=[];
var _e=_d._ranges,_f=_e.length;
while(_f--){
_ranges[_f]={location:(_e[_f]).location,length:(_e[_f]).length};
}
}
return _b;
}
}),new objj_method(sel_getUid("isEqualToIndexSet:"),function(_10,_11,_12){
with(_10){
if(!_12){
return NO;
}
if(_10===_12){
return YES;
}
var _13=_ranges.length,_14=_12._ranges;
if(_13!==_14.length||_count!==_12._count){
return NO;
}
while(_13--){
if(!CPEqualRanges(_ranges[_13],_14[_13])){
return NO;
}
}
return YES;
}
}),new objj_method(sel_getUid("containsIndex:"),function(_15,_16,_17){
with(_15){
return _18(_ranges,_17)!==CPNotFound;
}
}),new objj_method(sel_getUid("containsIndexesInRange:"),function(_19,_1a,_1b){
with(_19){
if(_1b.length<=0){
return NO;
}
if(_count<_1b.length){
return NO;
}
var _1c=_18(_ranges,_1b.location);
if(_1c===CPNotFound){
return NO;
}
var _1d=_ranges[_1c];
return CPIntersectionRange(_1d,_1b).length===_1b.length;
}
}),new objj_method(sel_getUid("containsIndexes:"),function(_1e,_1f,_20){
with(_1e){
var _21=_20._count;
if(_21<=0){
return YES;
}
if(_count<_21){
return NO;
}
var _22=_20._ranges,_23=_22.length;
while(_23--){
if(!objj_msgSend(_1e,"containsIndexesInRange:",_22[_23])){
return NO;
}
}
return YES;
}
}),new objj_method(sel_getUid("intersectsIndexesInRange:"),function(_24,_25,_26){
with(_24){
if(_count<=0){
return NO;
}
var _27=_28(_ranges,_26.location);
if(FLOOR(_27)===_27){
return YES;
}
var _29=_28(_ranges,((_26).location+(_26).length)-1);
if(FLOOR(_29)===_29){
return YES;
}
return _27!==_29;
}
}),new objj_method(sel_getUid("count"),function(_2a,_2b){
with(_2a){
return _count;
}
}),new objj_method(sel_getUid("firstIndex"),function(_2c,_2d){
with(_2c){
if(_count>0){
return _ranges[0].location;
}
return CPNotFound;
}
}),new objj_method(sel_getUid("lastIndex"),function(_2e,_2f){
with(_2e){
if(_count>0){
return ((_ranges[_ranges.length-1]).location+(_ranges[_ranges.length-1]).length)-1;
}
return CPNotFound;
}
}),new objj_method(sel_getUid("indexGreaterThanIndex:"),function(_30,_31,_32){
with(_30){
++_32;
var _33=_28(_ranges,_32);
if(_33===CPNotFound){
return CPNotFound;
}
_33=CEIL(_33);
if(_33>=_ranges.length){
return CPNotFound;
}
var _34=_ranges[_33];
if(CPLocationInRange(_32,_34)){
return _32;
}
return _34.location;
}
}),new objj_method(sel_getUid("indexLessThanIndex:"),function(_35,_36,_37){
with(_35){
--_37;
var _38=_28(_ranges,_37);
if(_38===CPNotFound){
return CPNotFound;
}
_38=FLOOR(_38);
if(_38<0){
return CPNotFound;
}
var _39=_ranges[_38];
if(CPLocationInRange(_37,_39)){
return _37;
}
return ((_39).location+(_39).length)-1;
}
}),new objj_method(sel_getUid("indexGreaterThanOrEqualToIndex:"),function(_3a,_3b,_3c){
with(_3a){
return objj_msgSend(_3a,"indexGreaterThanIndex:",_3c-1);
}
}),new objj_method(sel_getUid("indexLessThanOrEqualToIndex:"),function(_3d,_3e,_3f){
with(_3d){
return objj_msgSend(_3d,"indexLessThanIndex:",_3f+1);
}
}),new objj_method(sel_getUid("getIndexes:maxCount:inIndexRange:"),function(_40,_41,_42,_43,_44){
with(_40){
if(!_count||_43===0||_44&&!_44.length){
if(_44){
_44.length=0;
}
return 0;
}
var _45=0;
if(_44){
var _46=_44.location,_47=((_44).location+(_44).length)-1,_48=CEIL(_28(_ranges,_46)),_49=FLOOR(_28(_ranges,_47));
}else{
var _46=objj_msgSend(_40,"firstIndex"),_47=objj_msgSend(_40,"lastIndex"),_48=0,_49=_ranges.length-1;
}
while(_48<=_49){
var _4a=_ranges[_48],_4b=MAX(_46,_4a.location),_4c=MIN(_47+1,((_4a).location+(_4a).length));
for(;_4b<_4c;++_4b){
_42[_45++]=_4b;
if(_45===_43){
if(_44){
_44.location=_4b+1;
_44.length=_47+1-_4b-1;
}
return _43;
}
}
++_48;
}
if(_44){
_44.location=CPNotFound;
_44.length=0;
}
return _45;
}
}),new objj_method(sel_getUid("description"),function(_4d,_4e){
with(_4d){
var _4f=objj_msgSendSuper({receiver:_4d,super_class:objj_getClass("CPIndexSet").super_class},"description");
if(_count){
var _50=0,_51=_ranges.length;
_4f+="[number of indexes: "+_count+" (in "+_51;
if(_51===1){
_4f+=" range), indexes: (";
}else{
_4f+=" ranges), indexes: (";
}
for(;_50<_51;++_50){
var _52=_ranges[_50];
_4f+=_52.location;
if(_52.length>1){
_4f+="-"+(CPMaxRange(_52)-1);
}
if(_50+1<_51){
_4f+=" ";
}
}
_4f+=")]";
}else{
_4f+="(no indexes)";
}
return _4f;
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("indexSet"),function(_53,_54){
with(_53){
return objj_msgSend(objj_msgSend(_53,"alloc"),"init");
}
}),new objj_method(sel_getUid("indexSetWithIndex:"),function(_55,_56,_57){
with(_55){
return objj_msgSend(objj_msgSend(_55,"alloc"),"initWithIndex:",_57);
}
}),new objj_method(sel_getUid("indexSetWithIndexesInRange:"),function(_58,_59,_5a){
with(_58){
return objj_msgSend(objj_msgSend(_58,"alloc"),"initWithIndexesInRange:",_5a);
}
})]);
var _1=objj_getClass("CPIndexSet");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPIndexSet\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("addIndex:"),function(_5b,_5c,_5d){
with(_5b){
objj_msgSend(_5b,"addIndexesInRange:",{location:(_5d),length:1});
}
}),new objj_method(sel_getUid("addIndexes:"),function(_5e,_5f,_60){
with(_5e){
var _61=_60._ranges,_62=_61.length;
while(_62--){
objj_msgSend(_5e,"addIndexesInRange:",_61[_62]);
}
}
}),new objj_method(sel_getUid("addIndexesInRange:"),function(_63,_64,_65){
with(_63){
if(_65.length<=0){
return;
}
if(_count<=0){
_count=_65.length;
_ranges=[_65];
return;
}
var _66=_ranges.length,_67=_28(_ranges,_65.location-1),_68=CEIL(_67);
if(_68===_67&&_68<_66){
_65=CPUnionRange(_65,_ranges[_68]);
}
var _69=_28(_ranges,CPMaxRange(_65)),_6a=FLOOR(_69);
if(_6a===_69&&_6a>=0){
_65=CPUnionRange(_65,_ranges[_6a]);
}
var _6b=_6a-_68+1;
if(_6b===_ranges.length){
_ranges=[_65];
_count=_65.length;
}else{
if(_6b===1){
if(_68<_ranges.length){
_count-=_ranges[_68].length;
}
_count+=_65.length;
_ranges[_68]=_65;
}else{
if(_6b>0){
var _6c=_68,_6d=_68+_6b-1;
for(;_6c<=_6d;++_6c){
_count-=_ranges[_6c].length;
}
objj_msgSend(_ranges,"removeObjectsInRange:",{location:(_68),length:_6b});
}
objj_msgSend(_ranges,"insertObject:atIndex:",_65,_68);
_count+=_65.length;
}
}
}
}),new objj_method(sel_getUid("removeIndex:"),function(_6e,_6f,_70){
with(_6e){
objj_msgSend(_6e,"removeIndexesInRange:",{location:(_70),length:1});
}
}),new objj_method(sel_getUid("removeIndexes:"),function(_71,_72,_73){
with(_71){
var _74=_73._ranges,_75=_74.length;
while(_75--){
objj_msgSend(_71,"removeIndexesInRange:",_74[_75]);
}
}
}),new objj_method(sel_getUid("removeAllIndexes"),function(_76,_77){
with(_76){
_ranges=[];
_count=0;
}
}),new objj_method(sel_getUid("removeIndexesInRange:"),function(_78,_79,_7a){
with(_78){
if(_7a.length<=0){
return;
}
if(_count<=0){
return;
}
var _7b=_ranges.length,_7c=_28(_ranges,_7a.location),_7d=CEIL(_7c);
if(_7c===_7d&&_7d<_7b){
var _7e=_ranges[_7d];
if(_7a.location!==_7e.location){
var _7f=CPMaxRange(_7a),_80=CPMaxRange(_7e);
_7e.length=_7a.location-_7e.location;
if(_7f<_80){
_count-=_7a.length;
objj_msgSend(_ranges,"insertObject:atIndex:",{location:(_7f),length:_80-_7f},_7d+1);
return;
}else{
_count-=_80-_7a.location;
_7d+=1;
}
}
}
var _81=_28(_ranges,CPMaxRange(_7a)-1),_82=FLOOR(_81);
if(_81===_82&&_82>=0){
var _7f=CPMaxRange(_7a),_7e=_ranges[_82],_80=CPMaxRange(_7e);
if(_7f!==_80){
_count-=_7f-_7e.location;
_82-=1;
_7e.location=_7f;
_7e.length=_80-_7f;
}
}
var _83=_82-_7d+1;
if(_83>0){
var _84=_7d,_85=_7d+_83-1;
for(;_84<=_85;++_84){
_count-=_ranges[_84].length;
}
objj_msgSend(_ranges,"removeObjectsInRange:",{location:(_7d),length:_83});
}
}
}),new objj_method(sel_getUid("shiftIndexesStartingAtIndex:by:"),function(_86,_87,_88,_89){
with(_86){
if(!_count||_89==0){
return;
}
var i=_ranges.length-1,_8a=CPMakeRange(CPNotFound,0);
for(;i>=0;--i){
var _8b=_ranges[i],_8c=CPMaxRange(_8b);
if(_88>_8c){
break;
}
if(_88>_8b.location&&_88<_8c){
_8a=CPMakeRange(_88+_89,_8c-_88);
_8b.length=_88-_8b.location;
if(_89>0){
objj_msgSend(_ranges,"insertObject:atIndex:",_8a,i+1);
}else{
if(_8a.location<0){
_8a.length=CPMaxRange(_8a);
_8a.location=0;
}
}
break;
}
if((_8b.location+=_89)<0){
_8b.length=CPMaxRange(_8b);
_8b.location=0;
}
}
if(_89<0){
var j=i+1,_8d=_ranges.length,_8e=[];
for(;j<_8d;++j){
objj_msgSend(_8e,"addObject:",_ranges[j]);
}
if((j=i+1)<_8d){
objj_msgSend(_ranges,"removeObjectsInRange:",CPMakeRange(j,_8d-j));
for(j=0,_8d=_8e.length;j<_8d;++j){
objj_msgSend(_86,"addIndexesInRange:",_8e[j]);
}
}
if(_8a.location!=CPNotFound){
objj_msgSend(_86,"addIndexesInRange:",_8a);
}
}
}
})]);
var _8f="CPIndexSetCountKey",_90="CPIndexSetRangeStringsKey";
var _1=objj_getClass("CPIndexSet");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPIndexSet\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_91,_92,_93){
with(_91){
_91=objj_msgSendSuper({receiver:_91,super_class:objj_getClass("CPIndexSet").super_class},"init");
if(_91){
_count=objj_msgSend(_93,"decodeIntForKey:",_8f);
_ranges=[];
var _94=objj_msgSend(_93,"decodeObjectForKey:",_90),_95=0,_96=_94.length;
for(;_95<_96;++_95){
_ranges.push(CPRangeFromString(_94[_95]));
}
}
return _91;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_97,_98,_99){
with(_97){
objj_msgSend(_99,"encodeInt:forKey:",_count,_8f);
var _9a=0,_9b=_ranges.length,_9c=[];
for(;_9a<_9b;++_9a){
_9c[_9a]=CPStringFromRange(_ranges[_9a]);
}
objj_msgSend(_99,"encodeObject:forKey:",_9c,_90);
}
})]);
var _1=objj_getClass("CPIndexSet");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPIndexSet\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("copy"),function(_9d,_9e){
with(_9d){
return objj_msgSend(objj_msgSend(objj_msgSend(_9d,"class"),"alloc"),"initWithIndexSet:",_9d);
}
}),new objj_method(sel_getUid("mutableCopy"),function(_9f,_a0){
with(_9f){
return objj_msgSend(objj_msgSend(objj_msgSend(_9f,"class"),"alloc"),"initWithIndexSet:",_9f);
}
})]);
var _1=objj_getClass("CPIndexSet");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPIndexSet\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("countByEnumeratingWithState:objects:count:"),function(_a1,_a2,_a3,_a4,_a5){
with(_a1){
var _a6=_a3.state;
if(_a3.state>=_ranges.length){
return 0;
}
var _a7=_ranges[_a6],_a8=0,_a9=_a7.location,end=_a9+_a7.length,_aa=new Array(_a7.length);
while(_a9<end){
_aa[_a8++]=_a9++;
}
_a3.items=_aa;
++_a3.state;
return _a7.length;
}
})]);
var _1=objj_allocateClassPair(CPIndexSet,"CPMutableIndexSet"),_2=_1.isa;
objj_registerClassPair(_1);
var _18=function(_ab,_ac){
var low=0,_ad=_ab.length-1;
while(low<=_ad){
var _ae=FLOOR(low+(_ad-low)/2),_af=_ab[_ae];
if(_ac<_af.location){
_ad=_ae-1;
}else{
if(_ac>=CPMaxRange(_af)){
low=_ae+1;
}else{
return _ae;
}
}
}
return CPNotFound;
};
var _28=function(_b0,_b1){
var _b2=_b0.length;
if(_b2<=0){
return CPNotFound;
}
var low=0,_b3=_b2*2;
while(low<=_b3){
var _b4=FLOOR(low+(_b3-low)/2),_b5=_b4/2,_b6=FLOOR(_b5);
if(_b5===_b6){
if(_b6-1>=0&&_b1<CPMaxRange(_b0[_b6-1])){
_b3=_b4-1;
}else{
if(_b6<_b2&&_b1>=_b0[_b6].location){
low=_b4+1;
}else{
return _b6-0.5;
}
}
}else{
var _b7=_b0[_b6];
if(_b1<_b7.location){
_b3=_b4-1;
}else{
if(_b1>=CPMaxRange(_b7)){
low=_b4+1;
}else{
return _b6;
}
}
}
}
return CPNotFound;
};
p;14;CPInvocation.jt;2661;@STATIC;1.0;i;10;CPObject.ji;13;CPException.jt;2609;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPException.j",true);
var _1=objj_allocateClassPair(CPObject,"CPInvocation"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_returnValue"),new objj_ivar("_arguments"),new objj_ivar("_methodSignature")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithMethodSignature:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPInvocation").super_class},"init");
if(_3){
_arguments=[];
_methodSignature=_5;
}
return _3;
}
}),new objj_method(sel_getUid("setSelector:"),function(_6,_7,_8){
with(_6){
_arguments[1]=_8;
}
}),new objj_method(sel_getUid("selector"),function(_9,_a){
with(_9){
return _arguments[1];
}
}),new objj_method(sel_getUid("setTarget:"),function(_b,_c,_d){
with(_b){
_arguments[0]=_d;
}
}),new objj_method(sel_getUid("target"),function(_e,_f){
with(_e){
return _arguments[0];
}
}),new objj_method(sel_getUid("setArgument:atIndex:"),function(_10,_11,_12,_13){
with(_10){
_arguments[_13]=_12;
}
}),new objj_method(sel_getUid("argumentAtIndex:"),function(_14,_15,_16){
with(_14){
return _arguments[_16];
}
}),new objj_method(sel_getUid("setReturnValue:"),function(_17,_18,_19){
with(_17){
_returnValue=_19;
}
}),new objj_method(sel_getUid("returnValue"),function(_1a,_1b){
with(_1a){
return _returnValue;
}
}),new objj_method(sel_getUid("invoke"),function(_1c,_1d){
with(_1c){
_returnValue=objj_msgSend.apply(objj_msgSend,_arguments);
}
}),new objj_method(sel_getUid("invokeWithTarget:"),function(_1e,_1f,_20){
with(_1e){
_arguments[0]=_20;
_returnValue=objj_msgSend.apply(objj_msgSend,_arguments);
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("invocationWithMethodSignature:"),function(_21,_22,_23){
with(_21){
return objj_msgSend(objj_msgSend(_21,"alloc"),"initWithMethodSignature:",_23);
}
})]);
var _24="CPInvocationArguments",_25="CPInvocationReturnValue";
var _1=objj_getClass("CPInvocation");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPInvocation\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_26,_27,_28){
with(_26){
_26=objj_msgSendSuper({receiver:_26,super_class:objj_getClass("CPInvocation").super_class},"init");
if(_26){
_returnValue=objj_msgSend(_28,"decodeObjectForKey:",_25);
_arguments=objj_msgSend(_28,"decodeObjectForKey:",_24);
}
return _26;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_29,_2a,_2b){
with(_29){
objj_msgSend(_2b,"encodeObject:forKey:",_returnValue,_25);
objj_msgSend(_2b,"encodeObject:forKey:",_arguments,_24);
}
})]);
p;23;CPInvocationOperation.jt;1529;@STATIC;1.0;I;21;Foundation/CPObject.jI;25;Foundation/CPInvocation.ji;13;CPOperation.jt;1436;
objj_executeFile("Foundation/CPObject.j",false);
objj_executeFile("Foundation/CPInvocation.j",false);
objj_executeFile("CPOperation.j",true);
var _1=objj_allocateClassPair(CPOperation,"CPInvocationOperation"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_invocation")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("main"),function(_3,_4){
with(_3){
if(_invocation){
objj_msgSend(_invocation,"invoke");
}
}
}),new objj_method(sel_getUid("init"),function(_5,_6){
with(_5){
if(_5=objj_msgSendSuper({receiver:_5,super_class:objj_getClass("CPInvocationOperation").super_class},"init")){
_invocation=nil;
}
return _5;
}
}),new objj_method(sel_getUid("initWithInvocation:"),function(_7,_8,_9){
with(_7){
if(_7=objj_msgSend(_7,"init")){
_invocation=_9;
}
return _7;
}
}),new objj_method(sel_getUid("initWithTarget:selector:object:"),function(_a,_b,_c,_d,_e){
with(_a){
var _f=objj_msgSend(objj_msgSend(CPInvocation,"alloc"),"initWithMethodSignature:",nil);
objj_msgSend(_f,"setTarget:",_c);
objj_msgSend(_f,"setSelector:",_d);
objj_msgSend(_f,"setArgument:atIndex:",_e,2);
return objj_msgSend(_a,"initWithInvocation:",_f);
}
}),new objj_method(sel_getUid("invocation"),function(_10,_11){
with(_10){
return _invocation;
}
}),new objj_method(sel_getUid("result"),function(_12,_13){
with(_12){
if(objj_msgSend(_12,"isFinished")&&_invocation){
return objj_msgSend(_invocation,"returnValue");
}
return nil;
}
})]);
p;19;CPJSONPConnection.jt;3385;@STATIC;1.0;I;21;Foundation/CPObject.jt;3340;
objj_executeFile("Foundation/CPObject.j",false);
CPJSONPConnectionCallbacks={};
CPJSONPCallbackReplacementString="${JSONP_CALLBACK}";
var _1=objj_allocateClassPair(CPObject,"CPJSONPConnection"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_request"),new objj_ivar("_delegate"),new objj_ivar("_callbackParameter"),new objj_ivar("_scriptTag")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithRequest:callback:delegate:"),function(_3,_4,_5,_6,_7){
with(_3){
return objj_msgSend(_3,"initWithRequest:callback:delegate:startImmediately:",_5,_6,_7,NO);
}
}),new objj_method(sel_getUid("initWithRequest:callback:delegate:startImmediately:"),function(_8,_9,_a,_b,_c,_d){
with(_8){
_8=objj_msgSendSuper({receiver:_8,super_class:objj_getClass("CPJSONPConnection").super_class},"init");
_request=_a;
_delegate=_c;
_callbackParameter=_b;
if(!_callbackParameter&&objj_msgSend(objj_msgSend(_request,"URL"),"absoluteString").indexOf(CPJSONPCallbackReplacementString)<0){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"JSONP source specified without callback parameter or CPJSONPCallbackReplacementString in URL.");
}
if(_d){
objj_msgSend(_8,"start");
}
return _8;
}
}),new objj_method(sel_getUid("start"),function(_e,_f){
with(_e){
try{
CPJSONPConnectionCallbacks["callback"+objj_msgSend(_e,"UID")]=function(_10){
objj_msgSend(_delegate,"connection:didReceiveData:",_e,_10);
objj_msgSend(_e,"removeScriptTag");
objj_msgSend(objj_msgSend(CPRunLoop,"currentRunLoop"),"limitDateForMode:",CPDefaultRunLoopMode);
};
var _11=document.getElementsByTagName("head").item(0),_12=objj_msgSend(objj_msgSend(_request,"URL"),"absoluteString");
if(_callbackParameter){
_12+=(_12.indexOf("?")<0)?"?":"&";
_12+=_callbackParameter+"=CPJSONPConnectionCallbacks.callback"+objj_msgSend(_e,"UID");
}else{
if(_12.indexOf(CPJSONPCallbackReplacementString)>=0){
_12=objj_msgSend(_12,"stringByReplacingOccurrencesOfString:withString:",CPJSONPCallbackReplacementString,"CPJSONPConnectionCallbacks.callback"+objj_msgSend(_e,"UID"));
}else{
return;
}
}
_scriptTag=document.createElement("script");
_scriptTag.setAttribute("type","text/javascript");
_scriptTag.setAttribute("charset","utf-8");
_scriptTag.setAttribute("src",_12);
_11.appendChild(_scriptTag);
}
catch(exception){
objj_msgSend(_delegate,"connection:didFailWithError:",_e,exception);
objj_msgSend(_e,"removeScriptTag");
}
}
}),new objj_method(sel_getUid("removeScriptTag"),function(_13,_14){
with(_13){
var _15=document.getElementsByTagName("head").item(0);
if(_scriptTag&&_scriptTag.parentNode==_15){
_15.removeChild(_scriptTag);
}
CPJSONPConnectionCallbacks["callback"+objj_msgSend(_13,"UID")]=nil;
delete CPJSONPConnectionCallbacks["callback"+objj_msgSend(_13,"UID")];
}
}),new objj_method(sel_getUid("cancel"),function(_16,_17){
with(_16){
objj_msgSend(_16,"removeScriptTag");
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("sendRequest:callback:delegate:"),function(_18,_19,_1a,_1b,_1c){
with(_18){
return objj_msgSend(_18,"connectionWithRequest:callback:delegate:",_1a,_1b,_1c);
}
}),new objj_method(sel_getUid("connectionWithRequest:callback:delegate:"),function(_1d,_1e,_1f,_20,_21){
with(_1d){
return objj_msgSend(objj_msgSend(objj_msgSend(_1d,"class"),"alloc"),"initWithRequest:callback:delegate:startImmediately:",_1f,_20,_21,YES);
}
})]);
p;17;CPKeyedArchiver.jt;10369;@STATIC;1.0;i;8;CPData.ji;9;CPCoder.ji;9;CPArray.ji;10;CPString.ji;10;CPNumber.ji;14;CPDictionary.ji;9;CPValue.jt;10249;
objj_executeFile("CPData.j",true);
objj_executeFile("CPCoder.j",true);
objj_executeFile("CPArray.j",true);
objj_executeFile("CPString.j",true);
objj_executeFile("CPNumber.j",true);
objj_executeFile("CPDictionary.j",true);
objj_executeFile("CPValue.j",true);
var _1=nil;
var _2=1,_3=2,_4=4,_5=8,_6=16;
var _7="$null",_8=nil,_9="CP$UID",_a="$top",_b="$objects",_c="$archiver",_d="$version",_e="$classname",_f="$classes",_10="$class";
var _11=Nil,_12=Nil;
var _13=objj_allocateClassPair(CPValue,"_CPKeyedArchiverValue"),_14=_13.isa;
objj_registerClassPair(_13);
var _13=objj_allocateClassPair(CPCoder,"CPKeyedArchiver"),_14=_13.isa;
class_addIvars(_13,[new objj_ivar("_delegate"),new objj_ivar("_delegateSelectors"),new objj_ivar("_data"),new objj_ivar("_objects"),new objj_ivar("_UIDs"),new objj_ivar("_conditionalUIDs"),new objj_ivar("_replacementObjects"),new objj_ivar("_replacementClassNames"),new objj_ivar("_plistObject"),new objj_ivar("_plistObjects"),new objj_ivar("_outputFormat")]);
objj_registerClassPair(_13);
class_addMethods(_13,[new objj_method(sel_getUid("initForWritingWithMutableData:"),function(_15,_16,_17){
with(_15){
_15=objj_msgSendSuper({receiver:_15,super_class:objj_getClass("CPKeyedArchiver").super_class},"init");
if(_15){
_data=_17;
_objects=[];
_UIDs=objj_msgSend(CPDictionary,"dictionary");
_conditionalUIDs=objj_msgSend(CPDictionary,"dictionary");
_replacementObjects=objj_msgSend(CPDictionary,"dictionary");
_data=_17;
_plistObject=objj_msgSend(CPDictionary,"dictionary");
_plistObjects=objj_msgSend(CPArray,"arrayWithObject:",_7);
}
return _15;
}
}),new objj_method(sel_getUid("finishEncoding"),function(_18,_19){
with(_18){
if(_delegate&&_delegateSelectors&_6){
objj_msgSend(_delegate,"archiverWillFinish:",_18);
}
var i=0,_1a=_plistObject,_1b=[];
for(;i<_objects.length;++i){
var _1c=_objects[i],_1d=objj_msgSend(_1c,"classForKeyedArchiver");
_plistObject=_plistObjects[objj_msgSend(_UIDs,"objectForKey:",objj_msgSend(_1c,"UID"))];
objj_msgSend(_1c,"encodeWithCoder:",_18);
if(_delegate&&_delegateSelectors&_2){
objj_msgSend(_delegate,"archiver:didEncodeObject:",_18,_1c);
}
}
_plistObject=objj_msgSend(CPDictionary,"dictionary");
objj_msgSend(_plistObject,"setObject:forKey:",_1a,_a);
objj_msgSend(_plistObject,"setObject:forKey:",_plistObjects,_b);
objj_msgSend(_plistObject,"setObject:forKey:",objj_msgSend(_18,"className"),_c);
objj_msgSend(_plistObject,"setObject:forKey:","100000",_d);
objj_msgSend(_data,"setSerializedPlistObject:",_plistObject);
if(_delegate&&_delegateSelectors&_5){
objj_msgSend(_delegate,"archiverDidFinish:",_18);
}
}
}),new objj_method(sel_getUid("outputFormat"),function(_1e,_1f){
with(_1e){
return _outputFormat;
}
}),new objj_method(sel_getUid("setOutputFormat:"),function(_20,_21,_22){
with(_20){
_outputFormat=_22;
}
}),new objj_method(sel_getUid("encodeBool:forKey:"),function(_23,_24,_25,_26){
with(_23){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_23,_25,NO),_26);
}
}),new objj_method(sel_getUid("encodeDouble:forKey:"),function(_28,_29,_2a,_2b){
with(_28){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_28,_2a,NO),_2b);
}
}),new objj_method(sel_getUid("encodeFloat:forKey:"),function(_2c,_2d,_2e,_2f){
with(_2c){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_2c,_2e,NO),_2f);
}
}),new objj_method(sel_getUid("encodeInt:forKey:"),function(_30,_31,_32,_33){
with(_30){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_30,_32,NO),_33);
}
}),new objj_method(sel_getUid("setDelegate:"),function(_34,_35,_36){
with(_34){
_delegate=_36;
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("archiver:didEncodeObject:"))){
_delegateSelectors|=_2;
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("archiver:willEncodeObject:"))){
_delegateSelectors|=_3;
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("archiver:willReplaceObject:withObject:"))){
_delegateSelectors|=_4;
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("archiver:didFinishEncoding:"))){
_delegateSelectors|=_CPKeyedArchiverDidFinishEncodingSelector;
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("archiver:willFinishEncoding:"))){
_delegateSelectors|=_CPKeyedArchiverWillFinishEncodingSelector;
}
}
}),new objj_method(sel_getUid("delegate"),function(_37,_38){
with(_37){
return _delegate;
}
}),new objj_method(sel_getUid("encodePoint:forKey:"),function(_39,_3a,_3b,_3c){
with(_39){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_39,CPStringFromPoint(_3b),NO),_3c);
}
}),new objj_method(sel_getUid("encodeRect:forKey:"),function(_3d,_3e,_3f,_40){
with(_3d){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_3d,CPStringFromRect(_3f),NO),_40);
}
}),new objj_method(sel_getUid("encodeSize:forKey:"),function(_41,_42,_43,_44){
with(_41){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_41,CPStringFromSize(_43),NO),_44);
}
}),new objj_method(sel_getUid("encodeConditionalObject:forKey:"),function(_45,_46,_47,_48){
with(_45){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_45,_47,YES),_48);
}
}),new objj_method(sel_getUid("encodeNumber:forKey:"),function(_49,_4a,_4b,_4c){
with(_49){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_49,_4b,NO),_4c);
}
}),new objj_method(sel_getUid("encodeObject:forKey:"),function(_4d,_4e,_4f,_50){
with(_4d){
objj_msgSend(_plistObject,"setObject:forKey:",_27(_4d,_4f,NO),_50);
}
}),new objj_method(sel_getUid("_encodeArrayOfObjects:forKey:"),function(_51,_52,_53,_54){
with(_51){
var i=0,_55=_53.length,_56=objj_msgSend(CPArray,"arrayWithCapacity:",_55);
for(;i<_55;++i){
objj_msgSend(_56,"addObject:",_27(_51,_53[i],NO));
}
objj_msgSend(_plistObject,"setObject:forKey:",_56,_54);
}
}),new objj_method(sel_getUid("_encodeDictionaryOfObjects:forKey:"),function(_57,_58,_59,_5a){
with(_57){
var key,_5b=objj_msgSend(_59,"keyEnumerator"),_5c=objj_msgSend(CPDictionary,"dictionary");
while(key=objj_msgSend(_5b,"nextObject")){
objj_msgSend(_5c,"setObject:forKey:",_27(_57,objj_msgSend(_59,"objectForKey:",key),NO),key);
}
objj_msgSend(_plistObject,"setObject:forKey:",_5c,_5a);
}
}),new objj_method(sel_getUid("setClassName:forClass:"),function(_5d,_5e,_5f,_60){
with(_5d){
if(!_replacementClassNames){
_replacementClassNames=objj_msgSend(CPDictionary,"dictionary");
}
objj_msgSend(_replacementClassNames,"setObject:forKey:",_5f,CPStringFromClass(_60));
}
}),new objj_method(sel_getUid("classNameForClass:"),function(_61,_62,_63){
with(_61){
if(!_replacementClassNames){
return _63.name;
}
var _64=objj_msgSend(_replacementClassNames,"objectForKey:",CPStringFromClass(aClassName));
return _64?_64:_63.name;
}
})]);
class_addMethods(_14,[new objj_method(sel_getUid("initialize"),function(_65,_66){
with(_65){
if(_65!=objj_msgSend(CPKeyedArchiver,"class")){
return;
}
_11=objj_msgSend(CPString,"class");
_12=objj_msgSend(CPNumber,"class");
_8=objj_msgSend(CPDictionary,"dictionaryWithObject:forKey:",0,_9);
}
}),new objj_method(sel_getUid("allowsKeyedCoding"),function(_67,_68){
with(_67){
return YES;
}
}),new objj_method(sel_getUid("archivedDataWithRootObject:"),function(_69,_6a,_6b){
with(_69){
var _6c=objj_msgSend(CPData,"dataWithSerializedPlistObject:",nil),_6d=objj_msgSend(objj_msgSend(_69,"alloc"),"initForWritingWithMutableData:",_6c);
objj_msgSend(_6d,"encodeObject:forKey:",_6b,"root");
objj_msgSend(_6d,"finishEncoding");
return _6c;
}
}),new objj_method(sel_getUid("setClassName:forClass:"),function(_6e,_6f,_70,_71){
with(_6e){
if(!_1){
_1=objj_msgSend(CPDictionary,"dictionary");
}
objj_msgSend(_1,"setObject:forKey:",_70,CPStringFromClass(_71));
}
}),new objj_method(sel_getUid("classNameForClass:"),function(_72,_73,_74){
with(_72){
if(!_1){
return _74.name;
}
var _75=objj_msgSend(_1,"objectForKey:",CPStringFromClass(aClassName));
return _75?_75:_74.name;
}
})]);
var _27=function(_76,_77,_78){
if(_77!==nil&&!_77.isa){
_77=objj_msgSend(_CPKeyedArchiverValue,"valueWithJSObject:",_77);
}
var _79=objj_msgSend(_77,"UID"),_7a=objj_msgSend(_76._replacementObjects,"objectForKey:",_79);
if(_7a===nil){
_7a=objj_msgSend(_77,"replacementObjectForKeyedArchiver:",_76);
if(_76._delegate){
if(_7a!==_77&&_76._delegateSelectors&_4){
objj_msgSend(_76._delegate,"archiver:willReplaceObject:withObject:",_76,_77,_7a);
}
if(_76._delegateSelectors&_3){
_77=objj_msgSend(_76._delegate,"archiver:willEncodeObject:",_76,_7a);
if(_77!==_7a&&_76._delegateSelectors&_4){
objj_msgSend(_76._delegate,"archiver:willReplaceObject:withObject:",_76,_7a,_77);
}
_7a=_77;
}
}
objj_msgSend(_76._replacementObjects,"setObject:forKey:",_7a,_79);
}
if(_7a===nil){
return _8;
}
var UID=objj_msgSend(_76._UIDs,"objectForKey:",_79=objj_msgSend(_7a,"UID"));
if(UID===nil){
if(_78){
if((UID=objj_msgSend(_76._conditionalUIDs,"objectForKey:",_79))===nil){
objj_msgSend(_76._conditionalUIDs,"setObject:forKey:",UID=objj_msgSend(_76._plistObjects,"count"),_79);
objj_msgSend(_76._plistObjects,"addObject:",_7);
}
}else{
var _7b=objj_msgSend(_7a,"classForKeyedArchiver"),_7c=nil;
if((_7b===_11)||(_7b===_12)){
_7c=_7a;
}else{
_7c=objj_msgSend(CPDictionary,"dictionary");
objj_msgSend(_76._objects,"addObject:",_7a);
var _7d=objj_msgSend(_76,"classNameForClass:",_7b);
if(!_7d){
_7d=objj_msgSend(objj_msgSend(_76,"class"),"classNameForClass:",_7b);
}
if(!_7d){
_7d=_7b.name;
}else{
_7b=CPClassFromString(_7d);
}
var _7e=objj_msgSend(_76._UIDs,"objectForKey:",_7d);
if(!_7e){
var _7f=objj_msgSend(CPDictionary,"dictionary"),_80=[];
objj_msgSend(_7f,"setObject:forKey:",_7d,_e);
do{
objj_msgSend(_80,"addObject:",CPStringFromClass(_7b));
}while(_7b=objj_msgSend(_7b,"superclass"));
objj_msgSend(_7f,"setObject:forKey:",_80,_f);
_7e=objj_msgSend(_76._plistObjects,"count");
objj_msgSend(_76._plistObjects,"addObject:",_7f);
objj_msgSend(_76._UIDs,"setObject:forKey:",_7e,_7d);
}
objj_msgSend(_7c,"setObject:forKey:",objj_msgSend(CPDictionary,"dictionaryWithObject:forKey:",_7e,_9),_10);
}
UID=objj_msgSend(_76._conditionalUIDs,"objectForKey:",_79);
if(UID!==nil){
objj_msgSend(_76._UIDs,"setObject:forKey:",UID,_79);
objj_msgSend(_76._plistObjects,"replaceObjectAtIndex:withObject:",UID,_7c);
}else{
objj_msgSend(_76._UIDs,"setObject:forKey:",UID=objj_msgSend(_76._plistObjects,"count"),_79);
objj_msgSend(_76._plistObjects,"addObject:",_7c);
}
}
}
return objj_msgSend(CPDictionary,"dictionaryWithObject:forKey:",UID,_9);
};
p;19;CPKeyedUnarchiver.jt;8777;@STATIC;1.0;i;9;CPCoder.ji;8;CPNull.jt;8733;
objj_executeFile("CPCoder.j",true);
objj_executeFile("CPNull.j",true);
CPInvalidUnarchiveOperationException="CPInvalidUnarchiveOperationException";
var _1=1<<0,_2=1<<1,_3=1<<2,_4=1<<3,_5=1<<4,_6=1<<5;
var _7="$null";
_CPKeyedArchiverUIDKey="CP$UID",_CPKeyedArchiverTopKey="$top",_CPKeyedArchiverObjectsKey="$objects",_CPKeyedArchiverArchiverKey="$archiver",_CPKeyedArchiverVersionKey="$version",_CPKeyedArchiverClassNameKey="$classname",_CPKeyedArchiverClassesKey="$classes",_CPKeyedArchiverClassKey="$class";
var _8=Nil,_9=Nil,_a=Nil,_b=Nil,_c=Nil,_d=Nil;
var _e=objj_allocateClassPair(CPCoder,"CPKeyedUnarchiver"),_f=_e.isa;
class_addIvars(_e,[new objj_ivar("_delegate"),new objj_ivar("_delegateSelectors"),new objj_ivar("_data"),new objj_ivar("_replacementClasses"),new objj_ivar("_objects"),new objj_ivar("_archive"),new objj_ivar("_plistObject"),new objj_ivar("_plistObjects")]);
objj_registerClassPair(_e);
class_addMethods(_e,[new objj_method(sel_getUid("initForReadingWithData:"),function(_10,_11,_12){
with(_10){
_10=objj_msgSendSuper({receiver:_10,super_class:objj_getClass("CPKeyedUnarchiver").super_class},"init");
if(_10){
_archive=objj_msgSend(_12,"serializedPlistObject");
_objects=objj_msgSend(CPArray,"arrayWithObject:",objj_msgSend(CPNull,"null"));
_plistObject=objj_msgSend(_archive,"objectForKey:",_CPKeyedArchiverTopKey);
_plistObjects=objj_msgSend(_archive,"objectForKey:",_CPKeyedArchiverObjectsKey);
_replacementClasses=objj_msgSend(CPDictionary,"dictionary");
}
return _10;
}
}),new objj_method(sel_getUid("containsValueForKey:"),function(_13,_14,_15){
with(_13){
return objj_msgSend(_plistObject,"objectForKey:",_15)!=nil;
}
}),new objj_method(sel_getUid("_decodeDictionaryOfObjectsForKey:"),function(_16,_17,_18){
with(_16){
var _19=objj_msgSend(_plistObject,"objectForKey:",_18);
if(objj_msgSend(_19,"isKindOfClass:",_a)){
var key,_1a=objj_msgSend(_19,"keyEnumerator"),_1b=objj_msgSend(CPDictionary,"dictionary");
while(key=objj_msgSend(_1a,"nextObject")){
objj_msgSend(_1b,"setObject:forKey:",_1c(_16,objj_msgSend(objj_msgSend(_19,"objectForKey:",key),"objectForKey:",_CPKeyedArchiverUIDKey)),key);
}
return _1b;
}
return nil;
}
}),new objj_method(sel_getUid("decodeBoolForKey:"),function(_1d,_1e,_1f){
with(_1d){
return objj_msgSend(_1d,"decodeObjectForKey:",_1f);
}
}),new objj_method(sel_getUid("decodeFloatForKey:"),function(_20,_21,_22){
with(_20){
return objj_msgSend(_20,"decodeObjectForKey:",_22);
}
}),new objj_method(sel_getUid("decodeDoubleForKey:"),function(_23,_24,_25){
with(_23){
return objj_msgSend(_23,"decodeObjectForKey:",_25);
}
}),new objj_method(sel_getUid("decodeIntForKey:"),function(_26,_27,_28){
with(_26){
return objj_msgSend(_26,"decodeObjectForKey:",_28);
}
}),new objj_method(sel_getUid("decodePointForKey:"),function(_29,_2a,_2b){
with(_29){
var _2c=objj_msgSend(_29,"decodeObjectForKey:",_2b);
if(_2c){
return CPPointFromString(_2c);
}else{
return CPPointMake(0,0);
}
}
}),new objj_method(sel_getUid("decodeRectForKey:"),function(_2d,_2e,_2f){
with(_2d){
var _30=objj_msgSend(_2d,"decodeObjectForKey:",_2f);
if(_30){
return CPRectFromString(_30);
}else{
return CPRectMakeZero();
}
}
}),new objj_method(sel_getUid("decodeSizeForKey:"),function(_31,_32,_33){
with(_31){
var _34=objj_msgSend(_31,"decodeObjectForKey:",_33);
if(_34){
return CPSizeFromString(_34);
}else{
return CPSizeMake(0,0);
}
}
}),new objj_method(sel_getUid("decodeObjectForKey:"),function(_35,_36,_37){
with(_35){
var _38=objj_msgSend(_plistObject,"objectForKey:",_37);
if(objj_msgSend(_38,"isKindOfClass:",_a)){
return _1c(_35,objj_msgSend(_38,"objectForKey:",_CPKeyedArchiverUIDKey));
}else{
if(objj_msgSend(_38,"isKindOfClass:",_b)||objj_msgSend(_38,"isKindOfClass:",_c)||objj_msgSend(_38,"isKindOfClass:",_9)){
return _38;
}else{
if(objj_msgSend(_38,"isKindOfClass:",_8)){
var _39=0,_3a=_38.length,_3b=[];
for(;_39<_3a;++_39){
_3b[_39]=_1c(_35,objj_msgSend(_38[_39],"objectForKey:",_CPKeyedArchiverUIDKey));
}
return _3b;
}
}
}
return nil;
}
}),new objj_method(sel_getUid("decodeBytesForKey:"),function(_3c,_3d,_3e){
with(_3c){
var _3f=objj_msgSend(_3c,"decodeObjectForKey:",_3e);
if(objj_msgSend(_3f,"isKindOfClass:",objj_msgSend(CPData,"class"))){
return _3f.bytes;
}
return nil;
}
}),new objj_method(sel_getUid("finishDecoding"),function(_40,_41){
with(_40){
if(_delegateSelectors&_4){
objj_msgSend(_delegate,"unarchiverWillFinish:",_40);
}
if(_delegateSelectors&_5){
objj_msgSend(_delegate,"unarchiverDidFinish:",_40);
}
}
}),new objj_method(sel_getUid("delegate"),function(_42,_43){
with(_42){
return _delegate;
}
}),new objj_method(sel_getUid("setDelegate:"),function(_44,_45,_46){
with(_44){
_delegate=_46;
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("unarchiver:cannotDecodeObjectOfClassName:originalClasses:"))){
_delegateSelectors|=_1;
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("unarchiver:didDecodeObject:"))){
_delegateSelectors|=_2;
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("unarchiver:willReplaceObject:withObject:"))){
_delegateSelectors|=_3;
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("unarchiverWillFinish:"))){
_delegateSelectors|=_CPKeyedUnarchiverWilFinishSelector;
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("unarchiverDidFinish:"))){
_delegateSelectors|=_5;
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("unarchiver:cannotDecodeObjectOfClassName:originalClasses:"))){
_delegateSelectors|=_6;
}
}
}),new objj_method(sel_getUid("setClass:forClassName:"),function(_47,_48,_49,_4a){
with(_47){
objj_msgSend(_replacementClasses,"setObject:forKey:",_49,_4a);
}
}),new objj_method(sel_getUid("classForClassName:"),function(_4b,_4c,_4d){
with(_4b){
return objj_msgSend(_replacementClasses,"objectForKey:",_4d);
}
}),new objj_method(sel_getUid("allowsKeyedCoding"),function(_4e,_4f){
with(_4e){
return YES;
}
})]);
class_addMethods(_f,[new objj_method(sel_getUid("initialize"),function(_50,_51){
with(_50){
if(_50!==objj_msgSend(CPKeyedUnarchiver,"class")){
return;
}
_8=objj_msgSend(CPArray,"class");
_9=objj_msgSend(CPString,"class");
_a=objj_msgSend(CPDictionary,"class");
_b=objj_msgSend(CPNumber,"class");
_c=objj_msgSend(CPData,"class");
_d=objj_msgSend(_CPKeyedArchiverValue,"class");
}
}),new objj_method(sel_getUid("unarchiveObjectWithData:"),function(_52,_53,_54){
with(_52){
var _55=objj_msgSend(objj_msgSend(_52,"alloc"),"initForReadingWithData:",_54),_56=objj_msgSend(_55,"decodeObjectForKey:","root");
objj_msgSend(_55,"finishDecoding");
return _56;
}
}),new objj_method(sel_getUid("unarchiveObjectWithFile:"),function(_57,_58,_59){
with(_57){
}
}),new objj_method(sel_getUid("unarchiveObjectWithFile:asynchronously:"),function(_5a,_5b,_5c,_5d){
with(_5a){
}
})]);
var _1c=function(_5e,_5f){
var _60=_5e._objects[_5f];
if(_60){
if(_60==_5e._objects[0]){
return nil;
}else{
return _60;
}
}
var _60,_61=_5e._plistObjects[_5f];
if(objj_msgSend(_61,"isKindOfClass:",_a)){
var _62=_5e._plistObjects[objj_msgSend(objj_msgSend(_61,"objectForKey:",_CPKeyedArchiverClassKey),"objectForKey:",_CPKeyedArchiverUIDKey)],_63=objj_msgSend(_62,"objectForKey:",_CPKeyedArchiverClassNameKey),_64=objj_msgSend(_62,"objectForKey:",_CPKeyedArchiverClassesKey),_65=objj_msgSend(_5e,"classForClassName:",_63);
if(!_65){
_65=CPClassFromString(_63);
}
if(!_65&&(_5e._delegateSelectors&_6)){
_65=objj_msgSend(_delegate,"unarchiver:cannotDecodeObjectOfClassName:originalClasses:",_5e,_63,_64);
}
if(!_65){
objj_msgSend(CPException,"raise:reason:",CPInvalidUnarchiveOperationException,"-[CPKeyedUnarchiver decodeObjectForKey:]: cannot decode object of class ("+_63+")");
}
var _66=_5e._plistObject;
_5e._plistObject=_61;
_60=objj_msgSend(_65,"allocWithCoder:",_5e);
_5e._objects[_5f]=_60;
var _67=objj_msgSend(_60,"initWithCoder:",_5e);
_5e._plistObject=_66;
if(_67!=_60){
if(_5e._delegateSelectors&_3){
objj_msgSend(_5e._delegate,"unarchiver:willReplaceObject:withObject:",_5e,_60,_67);
}
_60=_67;
_5e._objects[_5f]=_67;
}
_67=objj_msgSend(_60,"awakeAfterUsingCoder:",_5e);
if(_67!=_60){
if(_5e._delegateSelectors&_3){
objj_msgSend(_5e._delegate,"unarchiver:willReplaceObject:withObject:",_5e,_60,_67);
}
_60=_67;
_5e._objects[_5f]=_67;
}
if(_5e._delegate){
if(_5e._delegateSelectors&_2){
_67=objj_msgSend(_5e._delegate,"unarchiver:didDecodeObject:",_5e,_60);
}
if(_67!=_60){
if(_5e._delegateSelectors&_3){
objj_msgSend(_5e._delegate,"unarchiver:willReplaceObject:withObject:",_5e,_60,_67);
}
_60=_67;
_5e._objects[_5f]=_67;
}
}
}else{
_5e._objects[_5f]=_60=_61;
if(objj_msgSend(_60,"class")==_9){
if(_60==_7){
_5e._objects[_5f]=_5e._objects[0];
return nil;
}else{
_5e._objects[_5f]=_60=_61;
}
}
}
if(objj_msgSend(_60,"isMemberOfClass:",_d)){
_60=objj_msgSend(_60,"JSObject");
}
return _60;
};
p;18;CPKeyValueCoding.jt;6257;@STATIC;1.0;i;9;CPArray.ji;14;CPDictionary.ji;8;CPNull.ji;10;CPObject.ji;13;CPArray+KVO.jt;6161;
objj_executeFile("CPArray.j",true);
objj_executeFile("CPDictionary.j",true);
objj_executeFile("CPNull.j",true);
objj_executeFile("CPObject.j",true);
var _1=nil,_2=nil;
CPUndefinedKeyException="CPUndefinedKeyException";
CPTargetObjectUserInfoKey="CPTargetObjectUserInfoKey";
CPUnknownUserInfoKey="CPUnknownUserInfoKey";
var _3=objj_getClass("CPObject");
if(!_3){
throw new SyntaxError("*** Could not find definition for class \"CPObject\"");
}
var _4=_3.isa;
class_addMethods(_3,[new objj_method(sel_getUid("_ivarForKey:"),function(_5,_6,_7){
with(_5){
var _8="_"+_7;
if(typeof _5[_8]!="undefined"){
return _8;
}
var _9="is"+_7.charAt(0).toUpperCase()+_7.substr(1);
_8="_"+_9;
if(typeof _5[_8]!="undefined"){
return _8;
}
_8=_7;
if(typeof _5[_8]!="undefined"){
return _8;
}
_8=_9;
if(typeof _5[_8]!="undefined"){
return _8;
}
return nil;
}
}),new objj_method(sel_getUid("valueForKey:"),function(_a,_b,_c){
with(_a){
var _d=objj_msgSend(_a,"class"),_e=objj_msgSend(_d,"_accessorForKey:",_c);
if(_e){
return objj_msgSend(_a,_e);
}
if(objj_msgSend(_d,"accessInstanceVariablesDirectly")){
var _f=objj_msgSend(_a,"_ivarForKey:",_c);
if(_f){
return _a[_f];
}
}
return objj_msgSend(_a,"valueForUndefinedKey:",_c);
}
}),new objj_method(sel_getUid("valueForKeyPath:"),function(_10,_11,_12){
with(_10){
var _13=_12.indexOf(".");
if(_13===-1){
return objj_msgSend(_10,"valueForKey:",_12);
}
var _14=_12.substring(0,_13),_15=_12.substring(_13+1),_16=objj_msgSend(_10,"valueForKey:",_14);
return objj_msgSend(_16,"valueForKeyPath:",_15);
}
}),new objj_method(sel_getUid("dictionaryWithValuesForKeys:"),function(_17,_18,_19){
with(_17){
var _1a=0,_1b=_19.length,_1c=objj_msgSend(CPDictionary,"dictionary");
for(;_1a<_1b;++_1a){
var key=_19[_1a],_1d=objj_msgSend(_17,"valueForKey:",key);
if(_1d===nil){
objj_msgSend(_1c,"setObject:forKey:",objj_msgSend(CPNull,"null"),key);
}else{
objj_msgSend(_1c,"setObject:forKey:",_1d,key);
}
}
return _1c;
}
}),new objj_method(sel_getUid("valueForUndefinedKey:"),function(_1e,_1f,_20){
with(_1e){
objj_msgSend(objj_msgSend(CPException,"exceptionWithName:reason:userInfo:",CPUndefinedKeyException,objj_msgSend(_1e,"description")+" is not key value coding-compliant for the key "+_20,objj_msgSend(CPDictionary,"dictionaryWithObjects:forKeys:",[_1e,_20],[CPTargetObjectUserInfoKey,CPUnknownUserInfoKey])),"raise");
}
}),new objj_method(sel_getUid("setValue:forKeyPath:"),function(_21,_22,_23,_24){
with(_21){
if(!_24){
_24="self";
}
var i=0,_25=_24.split("."),_26=_25.length-1,_27=_21;
for(;i<_26;++i){
_27=objj_msgSend(_27,"valueForKey:",_25[i]);
}
objj_msgSend(_27,"setValue:forKey:",_23,_25[i]);
}
}),new objj_method(sel_getUid("setValue:forKey:"),function(_28,_29,_2a,_2b){
with(_28){
var _2c=objj_msgSend(_28,"class"),_2d=objj_msgSend(_2c,"_modifierForKey:",_2b);
if(_2d){
return objj_msgSend(_28,_2d,_2a);
}
if(objj_msgSend(_2c,"accessInstanceVariablesDirectly")){
var _2e=objj_msgSend(_28,"_ivarForKey:",_2b);
if(_2e){
objj_msgSend(_28,"willChangeValueForKey:",_2b);
_28[_2e]=_2a;
objj_msgSend(_28,"didChangeValueForKey:",_2b);
return;
}
}
objj_msgSend(_28,"setValue:forUndefinedKey:",_2a,_2b);
}
}),new objj_method(sel_getUid("setValue:forUndefinedKey:"),function(_2f,_30,_31,_32){
with(_2f){
objj_msgSend(objj_msgSend(CPException,"exceptionWithName:reason:userInfo:",CPUndefinedKeyException,objj_msgSend(_2f,"description")+" is not key value coding-compliant for the key "+_32,objj_msgSend(CPDictionary,"dictionaryWithObjects:forKeys:",[_2f,_32],[CPTargetObjectUserInfoKey,CPUnknownUserInfoKey])),"raise");
}
})]);
class_addMethods(_4,[new objj_method(sel_getUid("accessInstanceVariablesDirectly"),function(_33,_34){
with(_33){
return YES;
}
}),new objj_method(sel_getUid("_accessorForKey:"),function(_35,_36,_37){
with(_35){
if(!_1){
_1=objj_msgSend(CPDictionary,"dictionary");
}
var UID=objj_msgSend(isa,"UID"),_38=nil,_39=objj_msgSend(_1,"objectForKey:",UID);
if(_39){
_38=objj_msgSend(_39,"objectForKey:",_37);
if(_38){
return _38===objj_msgSend(CPNull,"null")?nil:_38;
}
}else{
_39=objj_msgSend(CPDictionary,"dictionary");
objj_msgSend(_1,"setObject:forKey:",_39,UID);
}
var _3a=_37.charAt(0).toUpperCase()+_37.substr(1);
if(objj_msgSend(_35,"instancesRespondToSelector:",_38=CPSelectorFromString("get"+_3a))||objj_msgSend(_35,"instancesRespondToSelector:",_38=CPSelectorFromString(_37))||objj_msgSend(_35,"instancesRespondToSelector:",_38=CPSelectorFromString("is"+_3a))||objj_msgSend(_35,"instancesRespondToSelector:",_38=CPSelectorFromString("_get"+_3a))||objj_msgSend(_35,"instancesRespondToSelector:",_38=CPSelectorFromString("_"+_37))||objj_msgSend(_35,"instancesRespondToSelector:",_38=CPSelectorFromString("_is"+_3a))){
objj_msgSend(_39,"setObject:forKey:",_38,_37);
return _38;
}
objj_msgSend(_39,"setObject:forKey:",objj_msgSend(CPNull,"null"),_37);
return nil;
}
}),new objj_method(sel_getUid("_modifierForKey:"),function(_3b,_3c,_3d){
with(_3b){
if(!_2){
_2=objj_msgSend(CPDictionary,"dictionary");
}
var UID=objj_msgSend(isa,"UID"),_3e=nil,_3f=objj_msgSend(_2,"objectForKey:",UID);
if(_3f){
_3e=objj_msgSend(_3f,"objectForKey:",_3d);
if(_3e){
return _3e===objj_msgSend(CPNull,"null")?nil:_3e;
}
}else{
_3f=objj_msgSend(CPDictionary,"dictionary");
objj_msgSend(_2,"setObject:forKey:",_3f,UID);
}
if(_3e){
return _3e===objj_msgSend(CPNull,"null")?nil:_3e;
}
var _40=_3d.charAt(0).toUpperCase()+_3d.substr(1)+":";
if(objj_msgSend(_3b,"instancesRespondToSelector:",_3e=CPSelectorFromString("set"+_40))||objj_msgSend(_3b,"instancesRespondToSelector:",_3e=CPSelectorFromString("_set"+_40))){
objj_msgSend(_3f,"setObject:forKey:",_3e,_3d);
return _3e;
}
objj_msgSend(_3f,"setObject:forKey:",objj_msgSend(CPNull,"null"),_3d);
return nil;
}
})]);
var _3=objj_getClass("CPDictionary");
if(!_3){
throw new SyntaxError("*** Could not find definition for class \"CPDictionary\"");
}
var _4=_3.isa;
class_addMethods(_3,[new objj_method(sel_getUid("valueForKey:"),function(_41,_42,_43){
with(_41){
return objj_msgSend(_41,"objectForKey:",_43);
}
}),new objj_method(sel_getUid("setValue:forKey:"),function(_44,_45,_46,_47){
with(_44){
objj_msgSend(_44,"setObject:forKey:",_46,_47);
}
})]);
objj_executeFile("CPArray+KVO.j",true);
p;21;CPKeyValueObserving.jt;16736;@STATIC;1.0;i;9;CPArray.ji;14;CPDictionary.ji;13;CPException.ji;8;CPNull.ji;10;CPObject.ji;7;CPSet.ji;13;CPArray+KVO.jt;16610;
objj_executeFile("CPArray.j",true);
objj_executeFile("CPDictionary.j",true);
objj_executeFile("CPException.j",true);
objj_executeFile("CPNull.j",true);
objj_executeFile("CPObject.j",true);
objj_executeFile("CPSet.j",true);
var _1=objj_getClass("CPObject");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPObject\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("willChangeValueForKey:"),function(_3,_4,_5){
with(_3){
}
}),new objj_method(sel_getUid("didChangeValueForKey:"),function(_6,_7,_8){
with(_6){
}
}),new objj_method(sel_getUid("willChange:valuesAtIndexes:forKey:"),function(_9,_a,_b,_c,_d){
with(_9){
}
}),new objj_method(sel_getUid("didChange:valuesAtIndexes:forKey:"),function(_e,_f,_10,_11,key){
with(_e){
}
}),new objj_method(sel_getUid("addObserver:forKeyPath:options:context:"),function(_12,_13,_14,_15,_16,_17){
with(_12){
if(!_14||!_15){
return;
}
objj_msgSend(objj_msgSend(_CPKVOProxy,"proxyForObject:",_12),"_addObserver:forKeyPath:options:context:",_14,_15,_16,_17);
}
}),new objj_method(sel_getUid("removeObserver:forKeyPath:"),function(_18,_19,_1a,_1b){
with(_18){
if(!_1a||!_1b){
return;
}
objj_msgSend(_18[_1c],"_removeObserver:forKeyPath:",_1a,_1b);
}
}),new objj_method(sel_getUid("applyChange:toKeyPath:"),function(_1d,_1e,_1f,_20){
with(_1d){
var _21=objj_msgSend(_1f,"objectForKey:",CPKeyValueChangeKindKey);
if(_21===CPKeyValueChangeSetting){
var _22=objj_msgSend(_1f,"objectForKey:",CPKeyValueChangeNewKey);
objj_msgSend(_1d,"setValue:forKeyPath:",_22===objj_msgSend(CPNull,"null")?nil:_22,_20);
}else{
if(_21===CPKeyValueChangeInsertion){
objj_msgSend(objj_msgSend(_1d,"mutableArrayValueForKeyPath:",_20),"insertObjects:atIndexes:",objj_msgSend(_1f,"objectForKey:",CPKeyValueChangeNewKey),objj_msgSend(_1f,"objectForKey:",CPKeyValueChangeIndexesKey));
}else{
if(_21===CPKeyValueChangeRemoval){
objj_msgSend(objj_msgSend(_1d,"mutableArrayValueForKeyPath:",_20),"removeObjectsAtIndexes:",objj_msgSend(_1f,"objectForKey:",CPKeyValueChangeIndexesKey));
}else{
if(_21===CPKeyValueChangeReplacement){
objj_msgSend(objj_msgSend(_1d,"mutableArrayValueForKeyPath:",_20),"replaceObjectAtIndexes:withObjects:",objj_msgSend(_1f,"objectForKey:",CPKeyValueChangeIndexesKey),objj_msgSend(_1f,"objectForKey:",CPKeyValueChangeNewKey));
}
}
}
}
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("automaticallyNotifiesObserversForKey:"),function(_23,_24,_25){
with(_23){
return YES;
}
}),new objj_method(sel_getUid("keyPathsForValuesAffectingValueForKey:"),function(_26,_27,_28){
with(_26){
var _29=_28.charAt(0).toUpperCase()+_28.substring(1);
selector="keyPathsForValuesAffecting"+_29;
if(objj_msgSend(objj_msgSend(_26,"class"),"respondsToSelector:",selector)){
return objj_msgSend(objj_msgSend(_26,"class"),selector);
}
return objj_msgSend(CPSet,"set");
}
})]);
var _1=objj_getClass("CPDictionary");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPDictionary\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("inverseChangeDictionary"),function(_2a,_2b){
with(_2a){
var _2c=objj_msgSend(_2a,"mutableCopy"),_2d=objj_msgSend(_2a,"objectForKey:",CPKeyValueChangeKindKey);
if(_2d===CPKeyValueChangeSetting||_2d===CPKeyValueChangeReplacement){
objj_msgSend(_2c,"setObject:forKey:",objj_msgSend(_2a,"objectForKey:",CPKeyValueChangeOldKey),CPKeyValueChangeNewKey);
objj_msgSend(_2c,"setObject:forKey:",objj_msgSend(_2a,"objectForKey:",CPKeyValueChangeNewKey),CPKeyValueChangeOldKey);
}else{
if(_2d===CPKeyValueChangeInsertion){
objj_msgSend(_2c,"setObject:forKey:",CPKeyValueChangeRemoval,CPKeyValueChangeKindKey);
objj_msgSend(_2c,"setObject:forKey:",objj_msgSend(_2a,"objectForKey:",CPKeyValueChangeNewKey),CPKeyValueChangeOldKey);
objj_msgSend(_2c,"removeObjectForKey:",CPKeyValueChangeNewKey);
}else{
if(_2d===CPKeyValueChangeRemoval){
objj_msgSend(_2c,"setObject:forKey:",CPKeyValueChangeInsertion,CPKeyValueChangeKindKey);
objj_msgSend(_2c,"setObject:forKey:",objj_msgSend(_2a,"objectForKey:",CPKeyValueChangeOldKey),CPKeyValueChangeNewKey);
objj_msgSend(_2c,"removeObjectForKey:",CPKeyValueChangeOldKey);
}
}
}
return _2c;
}
})]);
CPKeyValueObservingOptionNew=1<<0;
CPKeyValueObservingOptionOld=1<<1;
CPKeyValueObservingOptionInitial=1<<2;
CPKeyValueObservingOptionPrior=1<<3;
CPKeyValueChangeKindKey="CPKeyValueChangeKindKey";
CPKeyValueChangeNewKey="CPKeyValueChangeNewKey";
CPKeyValueChangeOldKey="CPKeyValueChangeOldKey";
CPKeyValueChangeIndexesKey="CPKeyValueChangeIndexesKey";
CPKeyValueChangeNotificationIsPriorKey="CPKeyValueChangeNotificationIsPriorKey";
CPKeyValueChangeSetting=1;
CPKeyValueChangeInsertion=2;
CPKeyValueChangeRemoval=3;
CPKeyValueChangeReplacement=4;
var _2e=CPKeyValueObservingOptionNew|CPKeyValueObservingOptionOld,_2f="$KVODEPENDENT",_1c="$KVOPROXY";
var _1=objj_allocateClassPair(CPObject,"_CPKVOProxy"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_targetObject"),new objj_ivar("_nativeClass"),new objj_ivar("_changesForKey"),new objj_ivar("_observersForKey"),new objj_ivar("_observersForKeyLength"),new objj_ivar("_replacedKeys")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithTarget:"),function(_30,_31,_32){
with(_30){
_30=objj_msgSendSuper({receiver:_30,super_class:objj_getClass("_CPKVOProxy").super_class},"init");
_targetObject=_32;
_nativeClass=objj_msgSend(_32,"class");
_replacedKeys=objj_msgSend(CPSet,"set");
_observersForKey={};
_changesForKey={};
_observersForKeyLength=0;
return _30;
}
}),new objj_method(sel_getUid("_replaceClass"),function(_33,_34){
with(_33){
var _35=_nativeClass,_36="$KVO_"+class_getName(_nativeClass),_37=objj_lookUpClass(_36);
if(_37){
_targetObject.isa=_37;
return;
}
var _38=objj_allocateClassPair(_35,_36);
objj_registerClassPair(_38);
var _39=_CPKVOModelSubclass.method_list,_3a=_39.length;
for(var i=0;i<_3a;i++){
var _3b=_39[i];
class_addMethod(_38,method_getName(_3b),method_getImplementation(_3b),"");
}
_targetObject.isa=_38;
}
}),new objj_method(sel_getUid("_replaceSetterForKey:"),function(_3c,_3d,_3e){
with(_3c){
if(objj_msgSend(_replacedKeys,"containsObject:",_3e)||!objj_msgSend(_nativeClass,"automaticallyNotifiesObserversForKey:",_3e)){
return;
}
var _3f=_nativeClass,_40=_3e.charAt(0).toUpperCase()+_3e.substring(1),_41=false,_42=["set"+_40+":",_43,"_set"+_40+":",_43,"insertObject:in"+_40+"AtIndex:",_44,"replaceObjectIn"+_40+"AtIndex:withObject:",_45,"removeObjectFrom"+_40+"AtIndex:",_46];
for(var i=0,_47=_42.length;i<_47;i+=2){
var _48=sel_getName(_42[i]),_49=_42[i+1];
if(objj_msgSend(_nativeClass,"instancesRespondToSelector:",_48)){
var _4a=class_getInstanceMethod(_nativeClass,_48);
class_addMethod(_targetObject.isa,_48,_49(_3e,_4a),"");
}
}
var _4b=objj_msgSend(objj_msgSend(_nativeClass,"keyPathsForValuesAffectingValueForKey:",_3e),"allObjects"),_4c=_4b?_4b.length:0;
if(!_4c){
return;
}
var _4d=_nativeClass[_2f];
if(!_4d){
_4d={};
_nativeClass[_2f]=_4d;
}
while(_4c--){
var _4e=_4b[_4c],_4f=_4d[_4e];
if(!_4f){
_4f=objj_msgSend(CPSet,"new");
_4d[_4e]=_4f;
}
objj_msgSend(_4f,"addObject:",_3e);
objj_msgSend(_3c,"_replaceSetterForKey:",_4e);
}
}
}),new objj_method(sel_getUid("_addObserver:forKeyPath:options:context:"),function(_50,_51,_52,_53,_54,_55){
with(_50){
if(!_52){
return;
}
var _56=nil;
if(_53.indexOf(".")!=CPNotFound){
_56=objj_msgSend(objj_msgSend(_CPKVOForwardingObserver,"alloc"),"initWithKeyPath:object:observer:options:context:",_53,_targetObject,_52,_54,_55);
}else{
objj_msgSend(_50,"_replaceSetterForKey:",_53);
}
var _57=_observersForKey[_53];
if(!_57){
_57=objj_msgSend(CPDictionary,"dictionary");
_observersForKey[_53]=_57;
_observersForKeyLength++;
}
objj_msgSend(_57,"setObject:forKey:",_58(_52,_54,_55,_56),objj_msgSend(_52,"UID"));
if(_54&CPKeyValueObservingOptionInitial){
var _59=objj_msgSend(_targetObject,"valueForKeyPath:",_53);
if(_59===nil||_59===undefined){
_59=objj_msgSend(CPNull,"null");
}
var _5a=objj_msgSend(CPDictionary,"dictionaryWithObject:forKey:",_59,CPKeyValueChangeNewKey);
objj_msgSend(_52,"observeValueForKeyPath:ofObject:change:context:",_53,_50,_5a,_55);
}
}
}),new objj_method(sel_getUid("_removeObserver:forKeyPath:"),function(_5b,_5c,_5d,_5e){
with(_5b){
var _5f=_observersForKey[_5e];
if(_5e.indexOf(".")!=CPNotFound){
var _60=objj_msgSend(_5f,"objectForKey:",objj_msgSend(_5d,"UID")).forwarder;
objj_msgSend(_60,"finalize");
}
objj_msgSend(_5f,"removeObjectForKey:",objj_msgSend(_5d,"UID"));
if(!objj_msgSend(_5f,"count")){
_observersForKeyLength--;
delete _observersForKey[_5e];
}
if(!_observersForKeyLength){
_targetObject.isa=_nativeClass;
delete _targetObject[_1c];
}
}
}),new objj_method(sel_getUid("_sendNotificationsForKey:changeOptions:isBefore:"),function(_61,_62,_63,_64,_65){
with(_61){
var _66=_changesForKey[_63];
if(_65){
_66=_64;
var _67=objj_msgSend(_66,"objectForKey:",CPKeyValueChangeIndexesKey);
if(_67){
var _68=objj_msgSend(_66,"objectForKey:",CPKeyValueChangeKindKey);
if(_68===CPKeyValueChangeReplacement||_68===CPKeyValueChangeRemoval){
var _69=objj_msgSend(objj_msgSend(_targetObject,"mutableArrayValueForKeyPath:",_63),"objectsAtIndexes:",_67);
objj_msgSend(_66,"setValue:forKey:",_69,CPKeyValueChangeOldKey);
}
}else{
var _6a=objj_msgSend(_targetObject,"valueForKey:",_63);
if(_6a===nil||_6a===undefined){
_6a=objj_msgSend(CPNull,"null");
}
objj_msgSend(_66,"setObject:forKey:",_6a,CPKeyValueChangeOldKey);
}
objj_msgSend(_66,"setObject:forKey:",1,CPKeyValueChangeNotificationIsPriorKey);
_changesForKey[_63]=_66;
}else{
objj_msgSend(_66,"removeObjectForKey:",CPKeyValueChangeNotificationIsPriorKey);
var _67=objj_msgSend(_66,"objectForKey:",CPKeyValueChangeIndexesKey);
if(_67){
var _68=objj_msgSend(_66,"objectForKey:",CPKeyValueChangeKindKey);
if(_68==CPKeyValueChangeReplacement||_68==CPKeyValueChangeInsertion){
var _69=objj_msgSend(objj_msgSend(_targetObject,"mutableArrayValueForKeyPath:",_63),"objectsAtIndexes:",_67);
objj_msgSend(_66,"setValue:forKey:",_69,CPKeyValueChangeNewKey);
}
}else{
var _6b=objj_msgSend(_targetObject,"valueForKey:",_63);
if(_6b===nil||_6b===undefined){
_6b=objj_msgSend(CPNull,"null");
}
objj_msgSend(_66,"setObject:forKey:",_6b,CPKeyValueChangeNewKey);
}
}
var _6c=objj_msgSend(_observersForKey[_63],"allValues"),_6d=_6c?_6c.length:0;
while(_6d--){
var _6e=_6c[_6d];
if(_65&&(_6e.options&CPKeyValueObservingOptionPrior)){
objj_msgSend(_6e.observer,"observeValueForKeyPath:ofObject:change:context:",_63,_targetObject,_66,_6e.context);
}else{
if(!_65){
objj_msgSend(_6e.observer,"observeValueForKeyPath:ofObject:change:context:",_63,_targetObject,_66,_6e.context);
}
}
}
var _6f=_nativeClass[_2f];
if(!_6f){
return;
}
var _70=objj_msgSend(_6f[_63],"allObjects");
if(!_70){
return;
}
var _71=0,_6d=objj_msgSend(_70,"count");
for(;_71<_6d;++_71){
var _72=_70[_71];
objj_msgSend(_61,"_sendNotificationsForKey:changeOptions:isBefore:",_72,_65?objj_msgSend(_64,"copy"):_changesForKey[_72],_65);
}
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("proxyForObject:"),function(_73,_74,_75){
with(_73){
var _76=_75[_1c];
if(_76){
return _76;
}
_76=objj_msgSend(objj_msgSend(_73,"alloc"),"initWithTarget:",_75);
objj_msgSend(_76,"_replaceClass");
_75[_1c]=_76;
return _76;
}
})]);
var _1=objj_allocateClassPair(Nil,"_CPKVOModelSubclass"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("willChangeValueForKey:"),function(_77,_78,_79){
with(_77){
if(!_79){
return;
}
var _7a=objj_msgSend(CPDictionary,"dictionaryWithObject:forKey:",CPKeyValueChangeSetting,CPKeyValueChangeKindKey);
objj_msgSend(objj_msgSend(_CPKVOProxy,"proxyForObject:",_77),"_sendNotificationsForKey:changeOptions:isBefore:",_79,_7a,YES);
}
}),new objj_method(sel_getUid("didChangeValueForKey:"),function(_7b,_7c,_7d){
with(_7b){
if(!_7d){
return;
}
objj_msgSend(objj_msgSend(_CPKVOProxy,"proxyForObject:",_7b),"_sendNotificationsForKey:changeOptions:isBefore:",_7d,nil,NO);
}
}),new objj_method(sel_getUid("willChange:valuesAtIndexes:forKey:"),function(_7e,_7f,_80,_81,_82){
with(_7e){
if(!_82){
return;
}
var _83=objj_msgSend(CPDictionary,"dictionaryWithObjects:forKeys:",[_80,_81],[CPKeyValueChangeKindKey,CPKeyValueChangeIndexesKey]);
objj_msgSend(objj_msgSend(_CPKVOProxy,"proxyForObject:",_7e),"_sendNotificationsForKey:changeOptions:isBefore:",_82,_83,YES);
}
}),new objj_method(sel_getUid("didChange:valuesAtIndexes:forKey:"),function(_84,_85,_86,_87,_88){
with(_84){
if(!_88){
return;
}
objj_msgSend(objj_msgSend(_CPKVOProxy,"proxyForObject:",_84),"_sendNotificationsForKey:changeOptions:isBefore:",_88,nil,NO);
}
}),new objj_method(sel_getUid("class"),function(_89,_8a){
with(_89){
return _89[_1c]._nativeClass;
}
}),new objj_method(sel_getUid("superclass"),function(_8b,_8c){
with(_8b){
return objj_msgSend(objj_msgSend(_8b,"class"),"superclass");
}
}),new objj_method(sel_getUid("isKindOfClass:"),function(_8d,_8e,_8f){
with(_8d){
return objj_msgSend(objj_msgSend(_8d,"class"),"isSubclassOfClass:",_8f);
}
}),new objj_method(sel_getUid("isMemberOfClass:"),function(_90,_91,_92){
with(_90){
return objj_msgSend(_90,"class")==_92;
}
}),new objj_method(sel_getUid("className"),function(_93,_94){
with(_93){
return objj_msgSend(_93,"class").name;
}
})]);
var _1=objj_allocateClassPair(CPObject,"_CPKVOForwardingObserver"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_object"),new objj_ivar("_observer"),new objj_ivar("_context"),new objj_ivar("_firstPart"),new objj_ivar("_secondPart"),new objj_ivar("_value")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithKeyPath:object:observer:options:context:"),function(_95,_96,_97,_98,_99,_9a,_9b){
with(_95){
_95=objj_msgSendSuper({receiver:_95,super_class:objj_getClass("_CPKVOForwardingObserver").super_class},"init");
_context=_9b;
_observer=_99;
_object=_98;
var _9c=_97.indexOf(".");
if(_9c==CPNotFound){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"Created _CPKVOForwardingObserver without compound key path: "+_97);
}
_firstPart=_97.substring(0,_9c);
_secondPart=_97.substring(_9c+1);
objj_msgSend(_object,"addObserver:forKeyPath:options:context:",_95,_firstPart,_2e,nil);
_value=objj_msgSend(_object,"valueForKey:",_firstPart);
if(_value){
objj_msgSend(_value,"addObserver:forKeyPath:options:context:",_95,_secondPart,_2e,nil);
}
return _95;
}
}),new objj_method(sel_getUid("observeValueForKeyPath:ofObject:change:context:"),function(_9d,_9e,_9f,_a0,_a1,_a2){
with(_9d){
if(_9f===_firstPart){
objj_msgSend(_observer,"observeValueForKeyPath:ofObject:change:context:",_firstPart,_object,_a1,_context);
if(_value){
objj_msgSend(_value,"removeObserver:forKeyPath:",_9d,_secondPart);
}
_value=objj_msgSend(_object,"valueForKey:",_firstPart);
if(_value){
objj_msgSend(_value,"addObserver:forKeyPath:options:context:",_9d,_secondPart,_2e,nil);
}
}else{
objj_msgSend(_observer,"observeValueForKeyPath:ofObject:change:context:",_firstPart+"."+_9f,_object,_a1,_context);
}
}
}),new objj_method(sel_getUid("finalize"),function(_a3,_a4){
with(_a3){
if(_value){
objj_msgSend(_value,"removeObserver:forKeyPath:",_a3,_secondPart);
}
objj_msgSend(_object,"removeObserver:forKeyPath:",_a3,_firstPart);
_object=nil;
_observer=nil;
_context=nil;
_value=nil;
}
})]);
var _58=_58=function(_a5,_a6,_a7,_a8){
return {observer:_a5,options:_a6,context:_a7,forwarder:_a8};
};
var _43=_43=function(_a9,_aa){
return function(_ab,_ac,_ad){
objj_msgSend(_ab,"willChangeValueForKey:",_a9);
_aa.method_imp(_ab,_ac,_ad);
objj_msgSend(_ab,"didChangeValueForKey:",_a9);
};
};
var _44=_44=function(_ae,_af){
return function(_b0,_b1,_b2,_b3){
objj_msgSend(_b0,"willChange:valuesAtIndexes:forKey:",CPKeyValueChangeInsertion,objj_msgSend(CPIndexSet,"indexSetWithIndex:",_b3),_ae);
_af.method_imp(_b0,_b1,_b2,_b3);
objj_msgSend(_b0,"didChange:valuesAtIndexes:forKey:",CPKeyValueChangeInsertion,objj_msgSend(CPIndexSet,"indexSetWithIndex:",_b3),_ae);
};
};
var _45=_45=function(_b4,_b5){
return function(_b6,_b7,_b8,_b9){
objj_msgSend(_b6,"willChange:valuesAtIndexes:forKey:",CPKeyValueChangeReplacement,objj_msgSend(CPIndexSet,"indexSetWithIndex:",_b8),_b4);
_b5.method_imp(_b6,_b7,_b8,_b9);
objj_msgSend(_b6,"didChange:valuesAtIndexes:forKey:",CPKeyValueChangeReplacement,objj_msgSend(CPIndexSet,"indexSetWithIndex:",_b8),_b4);
};
};
var _46=_46=function(_ba,_bb){
return function(_bc,_bd,_be){
objj_msgSend(_bc,"willChange:valuesAtIndexes:forKey:",CPKeyValueChangeRemoval,objj_msgSend(CPIndexSet,"indexSetWithIndex:",_be),_ba);
_bb.method_imp(_bc,_bd,_be);
objj_msgSend(_bc,"didChange:valuesAtIndexes:forKey:",CPKeyValueChangeRemoval,objj_msgSend(CPIndexSet,"indexSetWithIndex:",_be),_ba);
};
};
objj_executeFile("CPArray+KVO.j",true);
p;7;CPLog.jt;17;@STATIC;1.0;t;1;
p;16;CPNotification.jt;1474;@STATIC;1.0;i;10;CPObject.ji;13;CPException.jt;1422;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPException.j",true);
var _1=objj_allocateClassPair(CPObject,"CPNotification"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_name"),new objj_ivar("_object"),new objj_ivar("_userInfo")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("init"),function(_3,_4){
with(_3){
objj_msgSend(CPException,"raise:reason:",CPUnsupportedMethodException,"CPNotification's init method should not be used");
}
}),new objj_method(sel_getUid("initWithName:object:userInfo:"),function(_5,_6,_7,_8,_9){
with(_5){
_5=objj_msgSendSuper({receiver:_5,super_class:objj_getClass("CPNotification").super_class},"init");
if(_5){
_name=_7;
_object=_8;
_userInfo=_9;
}
return _5;
}
}),new objj_method(sel_getUid("name"),function(_a,_b){
with(_a){
return _name;
}
}),new objj_method(sel_getUid("object"),function(_c,_d){
with(_c){
return _object;
}
}),new objj_method(sel_getUid("userInfo"),function(_e,_f){
with(_e){
return _userInfo;
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("notificationWithName:object:userInfo:"),function(_10,_11,_12,_13,_14){
with(_10){
return objj_msgSend(objj_msgSend(_10,"alloc"),"initWithName:object:userInfo:",_12,_13,_14);
}
}),new objj_method(sel_getUid("notificationWithName:object:"),function(_15,_16,_17,_18){
with(_15){
return objj_msgSend(objj_msgSend(_15,"alloc"),"initWithName:object:userInfo:",_17,_18,nil);
}
})]);
p;22;CPNotificationCenter.jt;6522;@STATIC;1.0;i;9;CPArray.ji;14;CPDictionary.ji;13;CPException.ji;16;CPNotification.ji;8;CPNull.jt;6420;
objj_executeFile("CPArray.j",true);
objj_executeFile("CPDictionary.j",true);
objj_executeFile("CPException.j",true);
objj_executeFile("CPNotification.j",true);
objj_executeFile("CPNull.j",true);
var _1=nil;
var _2=objj_allocateClassPair(CPObject,"CPNotificationCenter"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_namedRegistries"),new objj_ivar("_unnamedRegistry")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("init"),function(_4,_5){
with(_4){
_4=objj_msgSendSuper({receiver:_4,super_class:objj_getClass("CPNotificationCenter").super_class},"init");
if(_4){
_namedRegistries=objj_msgSend(CPDictionary,"dictionary");
_unnamedRegistry=objj_msgSend(objj_msgSend(_CPNotificationRegistry,"alloc"),"init");
}
return _4;
}
}),new objj_method(sel_getUid("addObserver:selector:name:object:"),function(_6,_7,_8,_9,_a,_b){
with(_6){
var _c,_d=objj_msgSend(objj_msgSend(_CPNotificationObserver,"alloc"),"initWithObserver:selector:",_8,_9);
if(_a==nil){
_c=_unnamedRegistry;
}else{
if(!(_c=objj_msgSend(_namedRegistries,"objectForKey:",_a))){
_c=objj_msgSend(objj_msgSend(_CPNotificationRegistry,"alloc"),"init");
objj_msgSend(_namedRegistries,"setObject:forKey:",_c,_a);
}
}
objj_msgSend(_c,"addObserver:object:",_d,_b);
}
}),new objj_method(sel_getUid("removeObserver:"),function(_e,_f,_10){
with(_e){
var _11=nil,_12=objj_msgSend(_namedRegistries,"keyEnumerator");
while(_11=objj_msgSend(_12,"nextObject")){
objj_msgSend(objj_msgSend(_namedRegistries,"objectForKey:",_11),"removeObserver:object:",_10,nil);
}
objj_msgSend(_unnamedRegistry,"removeObserver:object:",_10,nil);
}
}),new objj_method(sel_getUid("removeObserver:name:object:"),function(_13,_14,_15,_16,_17){
with(_13){
if(_16==nil){
var _18=nil,_19=objj_msgSend(_namedRegistries,"keyEnumerator");
while(_18=objj_msgSend(_19,"nextObject")){
objj_msgSend(objj_msgSend(_namedRegistries,"objectForKey:",_18),"removeObserver:object:",_15,_17);
}
objj_msgSend(_unnamedRegistry,"removeObserver:object:",_15,_17);
}else{
objj_msgSend(objj_msgSend(_namedRegistries,"objectForKey:",_16),"removeObserver:object:",_15,_17);
}
}
}),new objj_method(sel_getUid("postNotification:"),function(_1a,_1b,_1c){
with(_1a){
if(!_1c){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"postNotification: does not except 'nil' notifications");
}
_1d(_1a,_1c);
}
}),new objj_method(sel_getUid("postNotificationName:object:userInfo:"),function(_1e,_1f,_20,_21,_22){
with(_1e){
_1d(_1e,objj_msgSend(objj_msgSend(CPNotification,"alloc"),"initWithName:object:userInfo:",_20,_21,_22));
}
}),new objj_method(sel_getUid("postNotificationName:object:"),function(_23,_24,_25,_26){
with(_23){
_1d(_23,objj_msgSend(objj_msgSend(CPNotification,"alloc"),"initWithName:object:userInfo:",_25,_26,nil));
}
})]);
class_addMethods(_3,[new objj_method(sel_getUid("defaultCenter"),function(_27,_28){
with(_27){
if(!_1){
_1=objj_msgSend(objj_msgSend(CPNotificationCenter,"alloc"),"init");
}
return _1;
}
})]);
var _1d=function(_29,_2a){
objj_msgSend(_29._unnamedRegistry,"postNotification:",_2a);
objj_msgSend(objj_msgSend(_29._namedRegistries,"objectForKey:",objj_msgSend(_2a,"name")),"postNotification:",_2a);
};
var _2=objj_allocateClassPair(CPObject,"_CPNotificationRegistry"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_objectObservers"),new objj_ivar("_observerRemovalCount")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("init"),function(_2b,_2c){
with(_2b){
_2b=objj_msgSendSuper({receiver:_2b,super_class:objj_getClass("_CPNotificationRegistry").super_class},"init");
if(_2b){
_observerRemovalCount=0;
_objectObservers=objj_msgSend(CPDictionary,"dictionary");
}
return _2b;
}
}),new objj_method(sel_getUid("addObserver:object:"),function(_2d,_2e,_2f,_30){
with(_2d){
if(!_30){
_30=objj_msgSend(CPNull,"null");
}
var _31=objj_msgSend(_objectObservers,"objectForKey:",objj_msgSend(_30,"UID"));
if(!_31){
_31=[];
objj_msgSend(_objectObservers,"setObject:forKey:",_31,objj_msgSend(_30,"UID"));
}
_31.push(_2f);
}
}),new objj_method(sel_getUid("removeObserver:object:"),function(_32,_33,_34,_35){
with(_32){
var _36=[];
if(_35==nil){
var key=nil,_37=objj_msgSend(_objectObservers,"keyEnumerator");
while(key=objj_msgSend(_37,"nextObject")){
var _38=objj_msgSend(_objectObservers,"objectForKey:",key),_39=_38?_38.length:0;
while(_39--){
if(objj_msgSend(_38[_39],"observer")==_34){
++_observerRemovalCount;
_38.splice(_39,1);
}
}
if(!_38||_38.length==0){
_36.push(key);
}
}
}else{
var key=objj_msgSend(_35,"UID"),_38=objj_msgSend(_objectObservers,"objectForKey:",key);
_39=_38?_38.length:0;
while(_39--){
if(objj_msgSend(_38[_39],"observer")==_34){
++_observerRemovalCount;
_38.splice(_39,1);
}
}
if(!_38||_38.length==0){
_36.push(key);
}
}
var _39=_36.length;
while(_39--){
objj_msgSend(_objectObservers,"removeObjectForKey:",_36[_39]);
}
}
}),new objj_method(sel_getUid("postNotification:"),function(_3a,_3b,_3c){
with(_3a){
var _3d=_observerRemovalCount,_3e=objj_msgSend(_3c,"object"),_3f=nil;
if(_3e!=nil&&(_3f=objj_msgSend(objj_msgSend(_objectObservers,"objectForKey:",objj_msgSend(_3e,"UID")),"copy"))){
var _40=_3f,_41=_3f.length;
while(_41--){
var _42=_3f[_41];
if((_3d===_observerRemovalCount)||objj_msgSend(_40,"indexOfObjectIdenticalTo:",_42)!==CPNotFound){
objj_msgSend(_42,"postNotification:",_3c);
}
}
}
_3f=objj_msgSend(objj_msgSend(_objectObservers,"objectForKey:",objj_msgSend(objj_msgSend(CPNull,"null"),"UID")),"copy");
if(!_3f){
return;
}
var _3d=_observerRemovalCount,_41=_3f.length,_40=_3f;
while(_41--){
var _42=_3f[_41];
if((_3d===_observerRemovalCount)||objj_msgSend(_40,"indexOfObjectIdenticalTo:",_42)!==CPNotFound){
objj_msgSend(_42,"postNotification:",_3c);
}
}
}
}),new objj_method(sel_getUid("count"),function(_43,_44){
with(_43){
return objj_msgSend(_objectObservers,"count");
}
})]);
var _2=objj_allocateClassPair(CPObject,"_CPNotificationObserver"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_observer"),new objj_ivar("_selector")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("initWithObserver:selector:"),function(_45,_46,_47,_48){
with(_45){
if(_45){
_observer=_47;
_selector=_48;
}
return _45;
}
}),new objj_method(sel_getUid("observer"),function(_49,_4a){
with(_49){
return _observer;
}
}),new objj_method(sel_getUid("postNotification:"),function(_4b,_4c,_4d){
with(_4b){
objj_msgSend(_observer,"performSelector:withObject:",_selector,_4d);
}
})]);
p;8;CPNull.jt;621;@STATIC;1.0;i;10;CPObject.jt;588;
objj_executeFile("CPObject.j",true);
var _1=nil;
var _2=objj_allocateClassPair(CPObject,"CPNull"),_3=_2.isa;
objj_registerClassPair(_2);
class_addMethods(_3,[new objj_method(sel_getUid("null"),function(_4,_5){
with(_4){
if(!_1){
_1=objj_msgSend(objj_msgSend(CPNull,"alloc"),"init");
}
return _1;
}
})]);
var _2=objj_getClass("CPNull");
if(!_2){
throw new SyntaxError("*** Could not find definition for class \"CPNull\"");
}
var _3=_2.isa;
class_addMethods(_2,[new objj_method(sel_getUid("countByEnumeratingWithState:objects:count:"),function(_6,_7,_8,_9,_a){
with(_6){
return 0;
}
})]);
p;10;CPNumber.jt;6060;@STATIC;1.0;i;10;CPObject.ji;15;CPObjJRuntime.jt;6006;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPObjJRuntime.j",true);
var _1=new Number(),_2=new CFMutableDictionary();
var _3=objj_allocateClassPair(CPObject,"CPNumber"),_4=_3.isa;
objj_registerClassPair(_3);
class_addMethods(_3,[new objj_method(sel_getUid("initWithBool:"),function(_5,_6,_7){
with(_5){
return _7;
}
}),new objj_method(sel_getUid("initWithChar:"),function(_8,_9,_a){
with(_8){
if(_a.charCodeAt){
return _a.charCodeAt(0);
}
return _a;
}
}),new objj_method(sel_getUid("initWithDouble:"),function(_b,_c,_d){
with(_b){
return _d;
}
}),new objj_method(sel_getUid("initWithFloat:"),function(_e,_f,_10){
with(_e){
return _10;
}
}),new objj_method(sel_getUid("initWithInt:"),function(_11,_12,_13){
with(_11){
return _13;
}
}),new objj_method(sel_getUid("initWithLong:"),function(_14,_15,_16){
with(_14){
return _16;
}
}),new objj_method(sel_getUid("initWithLongLong:"),function(_17,_18,_19){
with(_17){
return _19;
}
}),new objj_method(sel_getUid("initWithShort:"),function(_1a,_1b,_1c){
with(_1a){
return _1c;
}
}),new objj_method(sel_getUid("initWithUnsignedChar:"),function(_1d,_1e,_1f){
with(_1d){
if(_1f.charCodeAt){
return _1f.charCodeAt(0);
}
return _1f;
}
}),new objj_method(sel_getUid("initWithUnsignedInt:"),function(_20,_21,_22){
with(_20){
return _22;
}
}),new objj_method(sel_getUid("initWithUnsignedLong:"),function(_23,_24,_25){
with(_23){
return _25;
}
}),new objj_method(sel_getUid("initWithUnsignedShort:"),function(_26,_27,_28){
with(_26){
return _28;
}
}),new objj_method(sel_getUid("UID"),function(_29,_2a){
with(_29){
var UID=_2.valueForKey(_29);
if(!UID){
UID=objj_generateObjectUID();
_2.setValueForKey(_29,UID);
}
return UID+"";
}
}),new objj_method(sel_getUid("boolValue"),function(_2b,_2c){
with(_2b){
return _2b?true:false;
}
}),new objj_method(sel_getUid("charValue"),function(_2d,_2e){
with(_2d){
return String.fromCharCode(_2d);
}
}),new objj_method(sel_getUid("decimalValue"),function(_2f,_30){
with(_2f){
objj_throw_exception("decimalValue: NOT YET IMPLEMENTED");
}
}),new objj_method(sel_getUid("descriptionWithLocale:"),function(_31,_32,_33){
with(_31){
if(!_33){
return toString();
}
objj_throw_exception("descriptionWithLocale: NOT YET IMPLEMENTED");
}
}),new objj_method(sel_getUid("description"),function(_34,_35){
with(_34){
return objj_msgSend(_34,"descriptionWithLocale:",nil);
}
}),new objj_method(sel_getUid("doubleValue"),function(_36,_37){
with(_36){
if(typeof _36=="boolean"){
return _36?1:0;
}
return _36;
}
}),new objj_method(sel_getUid("floatValue"),function(_38,_39){
with(_38){
if(typeof _38=="boolean"){
return _38?1:0;
}
return _38;
}
}),new objj_method(sel_getUid("intValue"),function(_3a,_3b){
with(_3a){
if(typeof _3a=="boolean"){
return _3a?1:0;
}
return _3a;
}
}),new objj_method(sel_getUid("longLongValue"),function(_3c,_3d){
with(_3c){
if(typeof _3c=="boolean"){
return _3c?1:0;
}
return _3c;
}
}),new objj_method(sel_getUid("longValue"),function(_3e,_3f){
with(_3e){
if(typeof _3e=="boolean"){
return _3e?1:0;
}
return _3e;
}
}),new objj_method(sel_getUid("shortValue"),function(_40,_41){
with(_40){
if(typeof _40=="boolean"){
return _40?1:0;
}
return _40;
}
}),new objj_method(sel_getUid("stringValue"),function(_42,_43){
with(_42){
return toString();
}
}),new objj_method(sel_getUid("unsignedCharValue"),function(_44,_45){
with(_44){
return String.fromCharCode(_44);
}
}),new objj_method(sel_getUid("unsignedIntValue"),function(_46,_47){
with(_46){
if(typeof _46=="boolean"){
return _46?1:0;
}
return _46;
}
}),new objj_method(sel_getUid("unsignedLongValue"),function(_48,_49){
with(_48){
if(typeof _48=="boolean"){
return _48?1:0;
}
return _48;
}
}),new objj_method(sel_getUid("unsignedShortValue"),function(_4a,_4b){
with(_4a){
if(typeof _4a=="boolean"){
return _4a?1:0;
}
return _4a;
}
}),new objj_method(sel_getUid("compare:"),function(_4c,_4d,_4e){
with(_4c){
if(_4c>_4e){
return CPOrderedDescending;
}else{
if(_4c<_4e){
return CPOrderedAscending;
}
}
return CPOrderedSame;
}
}),new objj_method(sel_getUid("isEqualToNumber:"),function(_4f,_50,_51){
with(_4f){
return _4f==_51;
}
})]);
class_addMethods(_4,[new objj_method(sel_getUid("alloc"),function(_52,_53){
with(_52){
return _1;
}
}),new objj_method(sel_getUid("numberWithBool:"),function(_54,_55,_56){
with(_54){
return _56;
}
}),new objj_method(sel_getUid("numberWithChar:"),function(_57,_58,_59){
with(_57){
if(_59.charCodeAt){
return _59.charCodeAt(0);
}
return _59;
}
}),new objj_method(sel_getUid("numberWithDouble:"),function(_5a,_5b,_5c){
with(_5a){
return _5c;
}
}),new objj_method(sel_getUid("numberWithFloat:"),function(_5d,_5e,_5f){
with(_5d){
return _5f;
}
}),new objj_method(sel_getUid("numberWithInt:"),function(_60,_61,_62){
with(_60){
return _62;
}
}),new objj_method(sel_getUid("numberWithLong:"),function(_63,_64,_65){
with(_63){
return _65;
}
}),new objj_method(sel_getUid("numberWithLongLong:"),function(_66,_67,_68){
with(_66){
return _68;
}
}),new objj_method(sel_getUid("numberWithShort:"),function(_69,_6a,_6b){
with(_69){
return _6b;
}
}),new objj_method(sel_getUid("numberWithUnsignedChar:"),function(_6c,_6d,_6e){
with(_6c){
if(_6e.charCodeAt){
return _6e.charCodeAt(0);
}
return _6e;
}
}),new objj_method(sel_getUid("numberWithUnsignedInt:"),function(_6f,_70,_71){
with(_6f){
return _71;
}
}),new objj_method(sel_getUid("numberWithUnsignedLong:"),function(_72,_73,_74){
with(_72){
return _74;
}
}),new objj_method(sel_getUid("numberWithUnsignedShort:"),function(_75,_76,_77){
with(_75){
return _77;
}
})]);
var _3=objj_getClass("CPNumber");
if(!_3){
throw new SyntaxError("*** Could not find definition for class \"CPNumber\"");
}
var _4=_3.isa;
class_addMethods(_3,[new objj_method(sel_getUid("initWithCoder:"),function(_78,_79,_7a){
with(_78){
return objj_msgSend(_7a,"decodeNumber");
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_7b,_7c,_7d){
with(_7b){
objj_msgSend(_7d,"encodeNumber:forKey:",_7b,"self");
}
})]);
Number.prototype.isa=CPNumber;
Boolean.prototype.isa=CPNumber;
objj_msgSend(CPNumber,"initialize");
p;10;CPObject.jt;6646;@STATIC;1.0;t;6627;
var _1=objj_allocateClassPair(Nil,"CPObject"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("isa")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("init"),function(_3,_4){
with(_3){
return _3;
}
}),new objj_method(sel_getUid("copy"),function(_5,_6){
with(_5){
return _5;
}
}),new objj_method(sel_getUid("mutableCopy"),function(_7,_8){
with(_7){
return objj_msgSend(_7,"copy");
}
}),new objj_method(sel_getUid("dealloc"),function(_9,_a){
with(_9){
}
}),new objj_method(sel_getUid("class"),function(_b,_c){
with(_b){
return isa;
}
}),new objj_method(sel_getUid("isKindOfClass:"),function(_d,_e,_f){
with(_d){
return objj_msgSend(isa,"isSubclassOfClass:",_f);
}
}),new objj_method(sel_getUid("isMemberOfClass:"),function(_10,_11,_12){
with(_10){
return _10.isa===_12;
}
}),new objj_method(sel_getUid("isProxy"),function(_13,_14){
with(_13){
return NO;
}
}),new objj_method(sel_getUid("respondsToSelector:"),function(_15,_16,_17){
with(_15){
return !!class_getInstanceMethod(isa,_17);
}
}),new objj_method(sel_getUid("methodForSelector:"),function(_18,_19,_1a){
with(_18){
return class_getMethodImplementation(isa,_1a);
}
}),new objj_method(sel_getUid("methodSignatureForSelector:"),function(_1b,_1c,_1d){
with(_1b){
return nil;
}
}),new objj_method(sel_getUid("description"),function(_1e,_1f){
with(_1e){
return "<"+class_getName(isa)+" 0x"+objj_msgSend(CPString,"stringWithHash:",objj_msgSend(_1e,"UID"))+">";
}
}),new objj_method(sel_getUid("performSelector:"),function(_20,_21,_22){
with(_20){
return objj_msgSend(_20,_22);
}
}),new objj_method(sel_getUid("performSelector:withObject:"),function(_23,_24,_25,_26){
with(_23){
return objj_msgSend(_23,_25,_26);
}
}),new objj_method(sel_getUid("performSelector:withObject:withObject:"),function(_27,_28,_29,_2a,_2b){
with(_27){
return objj_msgSend(_27,_29,_2a,_2b);
}
}),new objj_method(sel_getUid("forwardInvocation:"),function(_2c,_2d,_2e){
with(_2c){
objj_msgSend(_2c,"doesNotRecognizeSelector:",objj_msgSend(_2e,"selector"));
}
}),new objj_method(sel_getUid("forward::"),function(_2f,_30,_31,_32){
with(_2f){
var _33=objj_msgSend(_2f,"methodSignatureForSelector:",_31);
if(_33){
invocation=objj_msgSend(CPInvocation,"invocationWithMethodSignature:",_33);
objj_msgSend(invocation,"setTarget:",_2f);
objj_msgSend(invocation,"setSelector:",_31);
var _34=2,_35=_32.length;
for(;_34<_35;++_34){
objj_msgSend(invocation,"setArgument:atIndex:",_32[_34],_34);
}
objj_msgSend(_2f,"forwardInvocation:",invocation);
return objj_msgSend(invocation,"returnValue");
}
objj_msgSend(_2f,"doesNotRecognizeSelector:",_31);
}
}),new objj_method(sel_getUid("doesNotRecognizeSelector:"),function(_36,_37,_38){
with(_36){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,(class_isMetaClass(isa)?"+":"-")+" ["+objj_msgSend(_36,"className")+" "+_38+"] unrecognized selector sent to "+(class_isMetaClass(isa)?"class":"instance")+" 0x"+objj_msgSend(CPString,"stringWithHash:",objj_msgSend(_36,"UID")));
}
}),new objj_method(sel_getUid("awakeAfterUsingCoder:"),function(_39,_3a,_3b){
with(_39){
return _39;
}
}),new objj_method(sel_getUid("classForKeyedArchiver"),function(_3c,_3d){
with(_3c){
return objj_msgSend(_3c,"classForCoder");
}
}),new objj_method(sel_getUid("classForCoder"),function(_3e,_3f){
with(_3e){
return objj_msgSend(_3e,"class");
}
}),new objj_method(sel_getUid("replacementObjectForArchiver:"),function(_40,_41,_42){
with(_40){
return objj_msgSend(_40,"replacementObjectForCoder:",_42);
}
}),new objj_method(sel_getUid("replacementObjectForKeyedArchiver:"),function(_43,_44,_45){
with(_43){
return objj_msgSend(_43,"replacementObjectForCoder:",_45);
}
}),new objj_method(sel_getUid("replacementObjectForCoder:"),function(_46,_47,_48){
with(_46){
return _46;
}
}),new objj_method(sel_getUid("className"),function(_49,_4a){
with(_49){
return isa.name;
}
}),new objj_method(sel_getUid("autorelease"),function(_4b,_4c){
with(_4b){
return _4b;
}
}),new objj_method(sel_getUid("hash"),function(_4d,_4e){
with(_4d){
return objj_msgSend(_4d,"UID");
}
}),new objj_method(sel_getUid("UID"),function(_4f,_50){
with(_4f){
if(typeof _4f._UID==="undefined"){
_4f._UID=objj_generateObjectUID();
}
return _UID+"";
}
}),new objj_method(sel_getUid("isEqual:"),function(_51,_52,_53){
with(_51){
return _51===_53||objj_msgSend(_51,"UID")===objj_msgSend(_53,"UID");
}
}),new objj_method(sel_getUid("retain"),function(_54,_55){
with(_54){
return _54;
}
}),new objj_method(sel_getUid("release"),function(_56,_57){
with(_56){
}
}),new objj_method(sel_getUid("self"),function(_58,_59){
with(_58){
return _58;
}
}),new objj_method(sel_getUid("superclass"),function(_5a,_5b){
with(_5a){
return isa.super_class;
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("load"),function(_5c,_5d){
with(_5c){
}
}),new objj_method(sel_getUid("initialize"),function(_5e,_5f){
with(_5e){
}
}),new objj_method(sel_getUid("new"),function(_60,_61){
with(_60){
return objj_msgSend(objj_msgSend(_60,"alloc"),"init");
}
}),new objj_method(sel_getUid("alloc"),function(_62,_63){
with(_62){
return class_createInstance(_62);
}
}),new objj_method(sel_getUid("allocWithCoder:"),function(_64,_65,_66){
with(_64){
return objj_msgSend(_64,"alloc");
}
}),new objj_method(sel_getUid("class"),function(_67,_68){
with(_67){
return _67;
}
}),new objj_method(sel_getUid("superclass"),function(_69,_6a){
with(_69){
return super_class;
}
}),new objj_method(sel_getUid("isSubclassOfClass:"),function(_6b,_6c,_6d){
with(_6b){
var _6e=_6b;
for(;_6e;_6e=_6e.super_class){
if(_6e===_6d){
return YES;
}
}
return NO;
}
}),new objj_method(sel_getUid("isKindOfClass:"),function(_6f,_70,_71){
with(_6f){
return objj_msgSend(_6f,"isSubclassOfClass:",_71);
}
}),new objj_method(sel_getUid("isMemberOfClass:"),function(_72,_73,_74){
with(_72){
return _72===_74;
}
}),new objj_method(sel_getUid("instancesRespondToSelector:"),function(_75,_76,_77){
with(_75){
return !!class_getInstanceMethod(_75,_77);
}
}),new objj_method(sel_getUid("instanceMethodForSelector:"),function(_78,_79,_7a){
with(_78){
return class_getMethodImplementation(_78,_7a);
}
}),new objj_method(sel_getUid("description"),function(_7b,_7c){
with(_7b){
return class_getName(isa);
}
}),new objj_method(sel_getUid("setVersion:"),function(_7d,_7e,_7f){
with(_7d){
version=_7f;
return _7d;
}
}),new objj_method(sel_getUid("version"),function(_80,_81){
with(_80){
return version;
}
})]);
objj_class.prototype.toString=objj_object.prototype.toString=function(){
if(this.isa&&class_getInstanceMethod(this.isa,"description")!=NULL){
return objj_msgSend(this,"description");
}else{
return String(this)+" (-description not implemented)";
}
};
p;15;CPObjJRuntime.jt;435;@STATIC;1.0;i;7;CPLog.jt;406;
objj_executeFile("CPLog.j",true);
CPStringFromSelector=function(_1){
return sel_getName(_1);
};
CPSelectorFromString=function(_2){
return sel_registerName(_2);
};
CPClassFromString=function(_3){
return objj_getClass(_3);
};
CPStringFromClass=function(_4){
return class_getName(_4);
};
CPOrderedAscending=-1;
CPOrderedSame=0;
CPOrderedDescending=1;
CPNotFound=-1;
MIN=Math.min;
MAX=Math.max;
ABS=Math.abs;
p;13;CPOperation.jt;4282;@STATIC;1.0;I;21;Foundation/CPObject.jt;4237;
objj_executeFile("Foundation/CPObject.j",false);
CPOperationQueuePriorityVeryLow=-8;
CPOperationQueuePriorityLow=-4;
CPOperationQueuePriorityNormal=0;
CPOperationQueuePriorityHigh=4;
CPOperationQueuePriorityVeryHigh=8;
var _1=objj_allocateClassPair(CPObject,"CPOperation"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("operations"),new objj_ivar("_cancelled"),new objj_ivar("_executing"),new objj_ivar("_finished"),new objj_ivar("_ready"),new objj_ivar("_queuePriority"),new objj_ivar("_completionFunction"),new objj_ivar("_dependencies")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("main"),function(_3,_4){
with(_3){
}
}),new objj_method(sel_getUid("init"),function(_5,_6){
with(_5){
if(_5=objj_msgSendSuper({receiver:_5,super_class:objj_getClass("CPOperation").super_class},"init")){
_cancelled=NO;
_executing=NO;
_finished=NO;
_ready=YES;
_dependencies=objj_msgSend(objj_msgSend(CPArray,"alloc"),"init");
_queuePriority=CPOperationQueuePriorityNormal;
}
return _5;
}
}),new objj_method(sel_getUid("start"),function(_7,_8){
with(_7){
if(!_cancelled){
objj_msgSend(_7,"willChangeValueForKey:","isExecuting");
_executing=YES;
objj_msgSend(_7,"didChangeValueForKey:","isExecuting");
objj_msgSend(_7,"main");
if(_completionFunction){
_completionFunction();
}
objj_msgSend(_7,"willChangeValueForKey:","isExecuting");
_executing=NO;
objj_msgSend(_7,"didChangeValueForKey:","isExecuting");
objj_msgSend(_7,"willChangeValueForKey:","isFinished");
_finished=YES;
objj_msgSend(_7,"didChangeValueForKey:","isFinished");
}
}
}),new objj_method(sel_getUid("isCancelled"),function(_9,_a){
with(_9){
return _cancelled;
}
}),new objj_method(sel_getUid("isExecuting"),function(_b,_c){
with(_b){
return _executing;
}
}),new objj_method(sel_getUid("isFinished"),function(_d,_e){
with(_d){
return _finished;
}
}),new objj_method(sel_getUid("isConcurrent"),function(_f,_10){
with(_f){
return NO;
}
}),new objj_method(sel_getUid("isReady"),function(_11,_12){
with(_11){
return _ready;
}
}),new objj_method(sel_getUid("completionFunction"),function(_13,_14){
with(_13){
return _completionFunction;
}
}),new objj_method(sel_getUid("setCompletionFunction:"),function(_15,_16,_17){
with(_15){
_completionFunction=_17;
}
}),new objj_method(sel_getUid("addDependency:"),function(_18,_19,_1a){
with(_18){
objj_msgSend(_18,"willChangeValueForKey:","dependencies");
objj_msgSend(_1a,"addObserver:forKeyPath:options:context:",_18,"isFinished",(CPKeyValueObservingOptionNew),NULL);
objj_msgSend(_dependencies,"addObject:",_1a);
objj_msgSend(_18,"didChangeValueForKey:","dependencies");
objj_msgSend(_18,"_updateIsReadyState");
}
}),new objj_method(sel_getUid("removeDependency:"),function(_1b,_1c,_1d){
with(_1b){
objj_msgSend(_1b,"willChangeValueForKey:","dependencies");
objj_msgSend(_dependencies,"removeObject:",_1d);
objj_msgSend(_1d,"removeObserver:forKeyPath:",_1b,"isFinished");
objj_msgSend(_1b,"didChangeValueForKey:","dependencies");
objj_msgSend(_1b,"_updateIsReadyState");
}
}),new objj_method(sel_getUid("dependencies"),function(_1e,_1f){
with(_1e){
return _dependencies;
}
}),new objj_method(sel_getUid("waitUntilFinished"),function(_20,_21){
with(_20){
}
}),new objj_method(sel_getUid("cancel"),function(_22,_23){
with(_22){
objj_msgSend(_22,"willChangeValueForKey:","isCancelled");
_cancelled=YES;
objj_msgSend(_22,"didChangeValueForKey:","isCancelled");
}
}),new objj_method(sel_getUid("setQueuePriority:"),function(_24,_25,_26){
with(_24){
_queuePriority=_26;
}
}),new objj_method(sel_getUid("queuePriority"),function(_27,_28){
with(_27){
return _queuePriority;
}
}),new objj_method(sel_getUid("observeValueForKeyPath:ofObject:change:context:"),function(_29,_2a,_2b,_2c,_2d,_2e){
with(_29){
if(_2b=="isFinished"){
objj_msgSend(_29,"_updateIsReadyState");
}
}
}),new objj_method(sel_getUid("_updateIsReadyState"),function(_2f,_30){
with(_2f){
var _31=YES;
if(_dependencies&&objj_msgSend(_dependencies,"count")>0){
var i=0;
for(i=0;i<objj_msgSend(_dependencies,"count");i++){
if(!objj_msgSend(objj_msgSend(_dependencies,"objectAtIndex:",i),"isFinished")){
_31=NO;
}
}
}
if(_31!=_ready){
objj_msgSend(_2f,"willChangeValueForKey:","isReady");
_ready=_31;
objj_msgSend(_2f,"didChangeValueForKey:","isReady");
}
}
})]);
p;18;CPOperationQueue.jt;5187;@STATIC;1.0;I;21;Foundation/CPObject.ji;13;CPOperation.ji;23;CPInvocationOperation.ji;21;CPFunctionOperation.jt;5070;
objj_executeFile("Foundation/CPObject.j",false);
objj_executeFile("CPOperation.j",true);
objj_executeFile("CPInvocationOperation.j",true);
objj_executeFile("CPFunctionOperation.j",true);
var _1=nil;
var _2=objj_allocateClassPair(CPObject,"CPOperationQueue"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_operations"),new objj_ivar("_suspended"),new objj_ivar("_name"),new objj_ivar("_timer")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("name"),function(_4,_5){
with(_4){
return _name;
}
}),new objj_method(sel_getUid("setName:"),function(_6,_7,_8){
with(_6){
_name=_8;
}
}),new objj_method(sel_getUid("init"),function(_9,_a){
with(_9){
if(_9=objj_msgSendSuper({receiver:_9,super_class:objj_getClass("CPOperationQueue").super_class},"init")){
_operations=objj_msgSend(objj_msgSend(CPArray,"alloc"),"init");
_suspended=NO;
_currentlyModifyingOps=NO;
_timer=objj_msgSend(CPTimer,"scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:",0.01,_9,sel_getUid("_runNextOpsInQueue"),nil,YES);
}
return _9;
}
}),new objj_method(sel_getUid("_runNextOpsInQueue"),function(_b,_c){
with(_b){
if(!_suspended&&objj_msgSend(_b,"operationCount")>0){
var i=0;
for(i=0;i<objj_msgSend(_operations,"count");i++){
var op=objj_msgSend(_operations,"objectAtIndex:",i);
if(objj_msgSend(op,"isReady")&&!objj_msgSend(op,"isCancelled")&&!objj_msgSend(op,"isFinished")&&!objj_msgSend(op,"isExecuting")){
objj_msgSend(op,"start");
}
}
}
}
}),new objj_method(sel_getUid("_enableTimer:"),function(_d,_e,_f){
with(_d){
if(!_f){
if(_timer){
objj_msgSend(_timer,"invalidate");
_timer=nil;
}
}else{
if(!_timer){
_timer=objj_msgSend(CPTimer,"scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:",0.01,_d,sel_getUid("_runNextOpsInQueue"),nil,YES);
}
}
}
}),new objj_method(sel_getUid("addOperation:"),function(_10,_11,_12){
with(_10){
objj_msgSend(_10,"willChangeValueForKey:","operations");
objj_msgSend(_10,"willChangeValueForKey:","operationCount");
objj_msgSend(_operations,"addObject:",_12);
objj_msgSend(_10,"_sortOpsByPriority:",_operations);
objj_msgSend(_10,"didChangeValueForKey:","operations");
objj_msgSend(_10,"didChangeValueForKey:","operationCount");
}
}),new objj_method(sel_getUid("addOperations:waitUntilFinished:"),function(_13,_14,ops,_15){
with(_13){
if(ops){
if(_15){
objj_msgSend(_13,"_sortOpsByPriority:",ops);
objj_msgSend(_13,"_runOpsSynchronously:",ops);
}
objj_msgSend(_operations,"addObjectsFromArray:",ops);
objj_msgSend(_13,"_sortOpsByPriority:",_operations);
}
}
}),new objj_method(sel_getUid("addOperationWithFunction:"),function(_16,_17,_18){
with(_16){
objj_msgSend(_16,"addOperation:",objj_msgSend(CPFunctionOperation,"functionOperationWithFunction:",_18));
}
}),new objj_method(sel_getUid("operations"),function(_19,_1a){
with(_19){
return _operations;
}
}),new objj_method(sel_getUid("operationCount"),function(_1b,_1c){
with(_1b){
if(_operations){
return objj_msgSend(_operations,"count");
}
return 0;
}
}),new objj_method(sel_getUid("cancelAllOperations"),function(_1d,_1e){
with(_1d){
if(_operations){
var i=0;
for(i=0;i<objj_msgSend(_operations,"count");i++){
objj_msgSend(objj_msgSend(_operations,"objectAtIndex:",i),"cancel");
}
}
}
}),new objj_method(sel_getUid("waitUntilAllOperationsAreFinished"),function(_1f,_20){
with(_1f){
objj_msgSend(_1f,"_enableTimer:",NO);
objj_msgSend(_1f,"_runOpsSynchronously:",_operations);
if(!_suspended){
objj_msgSend(_1f,"_enableTimer:",YES);
}
}
}),new objj_method(sel_getUid("maxConcurrentOperationCount"),function(_21,_22){
with(_21){
return 1;
}
}),new objj_method(sel_getUid("setSuspended:"),function(_23,_24,_25){
with(_23){
_suspended=_25;
objj_msgSend(_23,"_enableTimer:",!_25);
}
}),new objj_method(sel_getUid("isSuspended"),function(_26,_27){
with(_26){
return _suspended;
}
}),new objj_method(sel_getUid("_sortOpsByPriority:"),function(_28,_29,_2a){
with(_28){
if(_2a){
objj_msgSend(_2a,"sortUsingFunction:context:",function(lhs,rhs){
if(objj_msgSend(lhs,"queuePriority")<objj_msgSend(rhs,"queuePriority")){
return 1;
}else{
if(objj_msgSend(lhs,"queuePriority")>objj_msgSend(rhs,"queuePriority")){
return -1;
}else{
return 0;
}
}
},nil);
}
}
}),new objj_method(sel_getUid("_runOpsSynchronously:"),function(_2b,_2c,ops){
with(_2b){
if(ops){
var _2d=YES;
while(_2d){
var i=0;
_2d=NO;
for(i=0;i<objj_msgSend(ops,"count");i++){
var op=objj_msgSend(ops,"objectAtIndex:",i);
if(objj_msgSend(op,"isReady")&&!objj_msgSend(op,"isCancelled")&&!objj_msgSend(op,"isFinished")&&!objj_msgSend(op,"isExecuting")){
objj_msgSend(op,"start");
}
}
for(i=0;i<objj_msgSend(ops,"count");i++){
var op=objj_msgSend(ops,"objectAtIndex:",i);
if(!objj_msgSend(op,"isFinished")&&!objj_msgSend(op,"isCancelled")){
_2d=YES;
}
}
}
}
}
})]);
class_addMethods(_3,[new objj_method(sel_getUid("mainQueue"),function(_2e,_2f){
with(_2e){
if(!_1){
_1=objj_msgSend(objj_msgSend(CPOperationQueue,"alloc"),"init");
objj_msgSend(_1,"setName:","main");
}
return _1;
}
}),new objj_method(sel_getUid("currentQueue"),function(_30,_31){
with(_30){
return objj_msgSend(CPOperationQueue,"mainQueue");
}
})]);
p;29;CPPropertyListSerialization.jt;1498;@STATIC;1.0;i;10;CPObject.jt;1464;
objj_executeFile("CPObject.j",true);
CPPropertyListUnknownFormat=0;
CPPropertyListOpenStepFormat=kCFPropertyListOpenStepFormat;
CPPropertyListXMLFormat_v1_0=kCFPropertyListXMLFormat_v1_0;
CPPropertyListBinaryFormat_v1_0=kCFPropertyListBinaryFormat_v1_0;
CPPropertyList280NorthFormat_v1_0=kCFPropertyList280NorthFormat_v1_0;
var _1=objj_allocateClassPair(CPObject,"CPPropertyListSerialization"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_2,[new objj_method(sel_getUid("dataFromPropertyList:format:"),function(_3,_4,_5,_6){
with(_3){
return CPPropertyListCreateData(_5,_6);
}
}),new objj_method(sel_getUid("propertyListFromData:format:"),function(_7,_8,_9,_a){
with(_7){
return CPPropertyListCreateFromData(_9,_a);
}
})]);
var _1=objj_getClass("CPPropertyListSerialization");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPPropertyListSerialization\"");
}
var _2=_1.isa;
class_addMethods(_2,[new objj_method(sel_getUid("dataFromPropertyList:format:errorDescription:"),function(_b,_c,_d,_e,_f){
with(_b){
_CPReportLenientDeprecation(_b,_c,sel_getUid("dataFromPropertyList:format:"));
return objj_msgSend(_b,"dataFromPropertyList:format:",_d,_e);
}
}),new objj_method(sel_getUid("propertyListFromData:format:errorDescription:"),function(_10,_11,_12,_13,_14){
with(_10){
_CPReportLenientDeprecation(_10,_11,sel_getUid("propertyListFromData:format:"));
return objj_msgSend(_10,"propertyListFromData:format:",_12,_13);
}
})]);
p;9;CPProxy.jt;3572;@STATIC;1.0;i;13;CPException.ji;14;CPInvocation.ji;10;CPString.jt;3501;
objj_executeFile("CPException.j",true);
objj_executeFile("CPInvocation.j",true);
objj_executeFile("CPString.j",true);
var _1=objj_allocateClassPair(Nil,"CPProxy"),_2=_1.isa;
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("methodSignatureForSelector:"),function(_3,_4,_5){
with(_3){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"-methodSignatureForSelector: called on abstract CPProxy class.");
}
}),new objj_method(sel_getUid("forwardInvocation:"),function(_6,_7,_8){
with(_6){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"-methodSignatureForSelector: called on abstract CPProxy class.");
}
}),new objj_method(sel_getUid("forward::"),function(_9,_a,_b,_c){
with(_9){
objj_msgSend(CPObject,"methodForSelector:",_a)(_9,_a,_b,_c);
}
}),new objj_method(sel_getUid("hash"),function(_d,_e){
with(_d){
return objj_msgSend(_d,"UID");
}
}),new objj_method(sel_getUid("UID"),function(_f,_10){
with(_f){
if(typeof _f._UID==="undefined"){
_f._UID=objj_generateObjectUID();
}
return _UID;
}
}),new objj_method(sel_getUid("isEqual:"),function(_11,_12,_13){
with(_11){
return _11===object;
}
}),new objj_method(sel_getUid("self"),function(_14,_15){
with(_14){
return _14;
}
}),new objj_method(sel_getUid("class"),function(_16,_17){
with(_16){
return isa;
}
}),new objj_method(sel_getUid("superclass"),function(_18,_19){
with(_18){
return class_getSuperclass(isa);
}
}),new objj_method(sel_getUid("performSelector:"),function(_1a,_1b,_1c){
with(_1a){
return objj_msgSend(_1a,_1c);
}
}),new objj_method(sel_getUid("performSelector:withObject:"),function(_1d,_1e,_1f,_20){
with(_1d){
return objj_msgSend(_1d,_1f,_20);
}
}),new objj_method(sel_getUid("performSelector:withObject:withObject:"),function(_21,_22,_23,_24,_25){
with(_21){
return objj_msgSend(_21,_23,_24,_25);
}
}),new objj_method(sel_getUid("isProxy"),function(_26,_27){
with(_26){
return YES;
}
}),new objj_method(sel_getUid("isKindOfClass:"),function(_28,_29,_2a){
with(_28){
var _2b=objj_msgSend(_28,"methodSignatureForSelector:",_29),_2c=objj_msgSend(CPInvocation,"invocationWithMethodSignature:",_2b);
objj_msgSend(_28,"forwardInvocation:",_2c);
return objj_msgSend(_2c,"returnValue");
}
}),new objj_method(sel_getUid("isMemberOfClass:"),function(_2d,_2e,_2f){
with(_2d){
var _30=objj_msgSend(_2d,"methodSignatureForSelector:",_2e),_31=objj_msgSend(CPInvocation,"invocationWithMethodSignature:",_30);
objj_msgSend(_2d,"forwardInvocation:",_31);
return objj_msgSend(_31,"returnValue");
}
}),new objj_method(sel_getUid("respondsToSelector:"),function(_32,_33,_34){
with(_32){
var _35=objj_msgSend(_32,"methodSignatureForSelector:",_33),_36=objj_msgSend(CPInvocation,"invocationWithMethodSignature:",_35);
objj_msgSend(_32,"forwardInvocation:",_36);
return objj_msgSend(_36,"returnValue");
}
}),new objj_method(sel_getUid("description"),function(_37,_38){
with(_37){
return "<"+class_getName(isa)+" 0x"+objj_msgSend(CPString,"stringWithHash:",objj_msgSend(_37,"UID"))+">";
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("load"),function(_39,_3a){
with(_39){
}
}),new objj_method(sel_getUid("initialize"),function(_3b,_3c){
with(_3b){
}
}),new objj_method(sel_getUid("class"),function(_3d,_3e){
with(_3d){
return _3d;
}
}),new objj_method(sel_getUid("alloc"),function(_3f,_40){
with(_3f){
return class_createInstance(_3f);
}
}),new objj_method(sel_getUid("respondsToSelector:"),function(_41,_42,_43){
with(_41){
return !!class_getInstanceMethod(isa,aSelector);
}
})]);
p;9;CPRange.jt;1244;@STATIC;1.0;t;1225;
CPMakeRange=function(_1,_2){
return {location:_1,length:_2};
};
CPCopyRange=function(_3){
return {location:_3.location,length:_3.length};
};
CPMakeRangeCopy=function(_4){
return {location:_4.location,length:_4.length};
};
CPEmptyRange=function(_5){
return _5.length===0;
};
CPMaxRange=function(_6){
return _6.location+_6.length;
};
CPEqualRanges=function(_7,_8){
return ((_7.location===_8.location)&&(_7.length===_8.length));
};
CPLocationInRange=function(_9,_a){
return (_9>=_a.location)&&(_9<CPMaxRange(_a));
};
CPUnionRange=function(_b,_c){
var _d=MIN(_b.location,_c.location);
return CPMakeRange(_d,MAX(CPMaxRange(_b),CPMaxRange(_c))-_d);
};
CPIntersectionRange=function(_e,_f){
if(CPMaxRange(_e)<_f.location||CPMaxRange(_f)<_e.location){
return CPMakeRange(0,0);
}
var _10=MAX(_e.location,_f.location);
return CPMakeRange(_10,MIN(CPMaxRange(_e),CPMaxRange(_f))-_10);
};
CPRangeInRange=function(_11,_12){
return (_11.location<=_12.location&&CPMaxRange(_11)>=CPMaxRange(_12));
};
CPStringFromRange=function(_13){
return "{"+_13.location+", "+_13.length+"}";
};
CPRangeFromString=function(_14){
var _15=_14.indexOf(",");
return {location:parseInt(_14.substr(1,_15-1)),length:parseInt(_14.substring(_15+1,_14.length))};
};
p;11;CPRunLoop.jt;6459;@STATIC;1.0;i;10;CPObject.ji;9;CPArray.ji;10;CPString.jt;6397;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPArray.j",true);
objj_executeFile("CPString.j",true);
CPDefaultRunLoopMode="CPDefaultRunLoopMode";
_CPRunLoopPerformCompare=function(_1,_2){
return objj_msgSend(_2,"order")-objj_msgSend(_1,"order");
};
var _3=[],_4=5;
var _5=objj_allocateClassPair(CPObject,"_CPRunLoopPerform"),_6=_5.isa;
class_addIvars(_5,[new objj_ivar("_target"),new objj_ivar("_selector"),new objj_ivar("_argument"),new objj_ivar("_order"),new objj_ivar("_runLoopModes"),new objj_ivar("_isValid")]);
objj_registerClassPair(_5);
class_addMethods(_5,[new objj_method(sel_getUid("initWithSelector:target:argument:order:modes:"),function(_7,_8,_9,_a,_b,_c,_d){
with(_7){
_7=objj_msgSendSuper({receiver:_7,super_class:objj_getClass("_CPRunLoopPerform").super_class},"init");
if(_7){
_selector=_9;
_target=_a;
_argument=_b;
_order=_c;
_runLoopModes=_d;
_isValid=YES;
}
return _7;
}
}),new objj_method(sel_getUid("selector"),function(_e,_f){
with(_e){
return _selector;
}
}),new objj_method(sel_getUid("target"),function(_10,_11){
with(_10){
return _target;
}
}),new objj_method(sel_getUid("argument"),function(_12,_13){
with(_12){
return _argument;
}
}),new objj_method(sel_getUid("order"),function(_14,_15){
with(_14){
return _order;
}
}),new objj_method(sel_getUid("fireInMode:"),function(_16,_17,_18){
with(_16){
if(!_isValid){
return YES;
}
if(objj_msgSend(_runLoopModes,"containsObject:",_18)){
objj_msgSend(_target,"performSelector:withObject:",_selector,_argument);
return YES;
}
return NO;
}
}),new objj_method(sel_getUid("invalidate"),function(_19,_1a){
with(_19){
_isValid=NO;
}
})]);
class_addMethods(_6,[new objj_method(sel_getUid("_poolPerform:"),function(_1b,_1c,_1d){
with(_1b){
if(!_1d||_3.length>=_4){
return;
}
_3.push(_1d);
}
}),new objj_method(sel_getUid("performWithSelector:target:argument:order:modes:"),function(_1e,_1f,_20,_21,_22,_23,_24){
with(_1e){
if(_3.length){
var _25=_3.pop();
_25._target=_21;
_25._selector=_20;
_25._argument=_22;
_25._order=_23;
_25._runLoopModes=_24;
_25._isValid=YES;
return _25;
}
return objj_msgSend(objj_msgSend(_1e,"alloc"),"initWithSelector:target:argument:order:modes:",_20,_21,_22,_23,_24);
}
})]);
var _26=0;
var _5=objj_allocateClassPair(CPObject,"CPRunLoop"),_6=_5.isa;
class_addIvars(_5,[new objj_ivar("_runLoopLock"),new objj_ivar("_timersForModes"),new objj_ivar("_nativeTimersForModes"),new objj_ivar("_nextTimerFireDatesForModes"),new objj_ivar("_didAddTimer"),new objj_ivar("_effectiveDate"),new objj_ivar("_orderedPerforms")]);
objj_registerClassPair(_5);
class_addMethods(_5,[new objj_method(sel_getUid("init"),function(_27,_28){
with(_27){
_27=objj_msgSendSuper({receiver:_27,super_class:objj_getClass("CPRunLoop").super_class},"init");
if(_27){
_orderedPerforms=[];
_timersForModes={};
_nativeTimersForModes={};
_nextTimerFireDatesForModes={};
}
return _27;
}
}),new objj_method(sel_getUid("performSelector:target:argument:order:modes:"),function(_29,_2a,_2b,_2c,_2d,_2e,_2f){
with(_29){
var _30=objj_msgSend(_CPRunLoopPerform,"performWithSelector:target:argument:order:modes:",_2b,_2c,_2d,_2e,_2f),_31=_orderedPerforms.length;
while(_31--){
if(_2e<objj_msgSend(_orderedPerforms[_31],"order")){
break;
}
}
_orderedPerforms.splice(_31+1,0,_30);
}
}),new objj_method(sel_getUid("cancelPerformSelector:target:argument:"),function(_32,_33,_34,_35,_36){
with(_32){
var _37=_orderedPerforms.length;
while(_37--){
var _38=_orderedPerforms[_37];
if(objj_msgSend(_38,"selector")===_34&&objj_msgSend(_38,"target")==_35&&objj_msgSend(_38,"argument")==_36){
objj_msgSend(_orderedPerforms[_37],"invalidate");
}
}
}
}),new objj_method(sel_getUid("performSelectors"),function(_39,_3a){
with(_39){
objj_msgSend(_39,"limitDateForMode:",CPDefaultRunLoopMode);
}
}),new objj_method(sel_getUid("addTimer:forMode:"),function(_3b,_3c,_3d,_3e){
with(_3b){
if(_timersForModes[_3e]){
_timersForModes[_3e].push(_3d);
}else{
_timersForModes[_3e]=[_3d];
}
_didAddTimer=YES;
if(!_3d._lastNativeRunLoopsForModes){
_3d._lastNativeRunLoopsForModes={};
}
_3d._lastNativeRunLoopsForModes[_3e]=_26;
}
}),new objj_method(sel_getUid("limitDateForMode:"),function(_3f,_40,_41){
with(_3f){
if(_runLoopLock){
return;
}
_runLoopLock=YES;
var now=_effectiveDate?objj_msgSend(_effectiveDate,"laterDate:",objj_msgSend(CPDate,"date")):objj_msgSend(CPDate,"date"),_42=nil,_43=_nextTimerFireDatesForModes[_41];
if(_didAddTimer||_43&&_43<=now){
_didAddTimer=NO;
if(_nativeTimersForModes[_41]!==nil){
window.clearNativeTimeout(_nativeTimersForModes[_41]);
_nativeTimersForModes[_41]=nil;
}
var _44=_timersForModes[_41],_45=_44.length;
_timersForModes[_41]=nil;
while(_45--){
var _46=_44[_45];
if(_46._lastNativeRunLoopsForModes[_41]<_26&&_46._isValid&&_46._fireDate<=now){
objj_msgSend(_46,"fire");
}
if(_46._isValid){
_42=(_42===nil)?_46._fireDate:objj_msgSend(_42,"earlierDate:",_46._fireDate);
}else{
_46._lastNativeRunLoopsForModes[_41]=0;
_44.splice(_45,1);
}
}
var _47=_timersForModes[_41];
if(_47&&_47.length){
_45=_47.length;
while(_45--){
var _46=_47[_45];
if(objj_msgSend(_46,"isValid")){
_42=(_42===nil)?_46._fireDate:objj_msgSend(_42,"earlierDate:",_46._fireDate);
}else{
_47.splice(_45,1);
}
}
_timersForModes[_41]=_47.concat(_44);
}else{
_timersForModes[_41]=_44;
}
_nextTimerFireDatesForModes[_41]=_42;
if(_nextTimerFireDatesForModes[_41]!==nil){
_nativeTimersForModes[_41]=window.setNativeTimeout(function(){
_effectiveDate=_42;
_nativeTimersForModes[_41]=nil;
++_26;
objj_msgSend(_3f,"limitDateForMode:",_41);
_effectiveDate=nil;
},MAX(0,objj_msgSend(_42,"timeIntervalSinceNow")*1000));
}
}
var _48=_orderedPerforms,_45=_48.length;
_orderedPerforms=[];
while(_45--){
var _49=_48[_45];
if(objj_msgSend(_49,"fireInMode:",CPDefaultRunLoopMode)){
objj_msgSend(_CPRunLoopPerform,"_poolPerform:",_49);
_48.splice(_45,1);
}
}
if(_orderedPerforms.length){
_orderedPerforms=_orderedPerforms.concat(_48);
_orderedPerforms.sort(_CPRunLoopPerformCompare);
}else{
_orderedPerforms=_48;
}
_runLoopLock=NO;
return _42;
}
})]);
class_addMethods(_6,[new objj_method(sel_getUid("initialize"),function(_4a,_4b){
with(_4a){
if(_4a!=objj_msgSend(CPRunLoop,"class")){
return;
}
CPMainRunLoop=objj_msgSend(objj_msgSend(CPRunLoop,"alloc"),"init");
}
}),new objj_method(sel_getUid("currentRunLoop"),function(_4c,_4d){
with(_4c){
return CPMainRunLoop;
}
}),new objj_method(sel_getUid("mainRunLoop"),function(_4e,_4f){
with(_4e){
return CPMainRunLoop;
}
})]);
p;7;CPSet.jt;8330;@STATIC;1.0;i;10;CPObject.ji;9;CPArray.ji;10;CPNumber.ji;14;CPEnumerator.jt;8249;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPArray.j",true);
objj_executeFile("CPNumber.j",true);
objj_executeFile("CPEnumerator.j",true);
var _1=objj_allocateClassPair(CPObject,"CPSet"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_contents"),new objj_ivar("_count")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("init"),function(_3,_4){
with(_3){
if(_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPSet").super_class},"init")){
_count=0;
_contents={};
}
return _3;
}
}),new objj_method(sel_getUid("initWithArray:"),function(_5,_6,_7){
with(_5){
if(_5=objj_msgSend(_5,"init")){
var _8=_7.length;
while(_8--){
objj_msgSend(_5,"addObject:",_7[_8]);
}
}
return _5;
}
}),new objj_method(sel_getUid("initWithObjects:count:"),function(_9,_a,_b,_c){
with(_9){
return objj_msgSend(_9,"initWithArray:",_b.splice(0,_c));
}
}),new objj_method(sel_getUid("initWithObjects:"),function(_d,_e,_f){
with(_d){
if(_d=objj_msgSend(_d,"init")){
var _10=arguments.length,i=2;
for(;i<_10&&(argument=arguments[i])!=nil;++i){
objj_msgSend(_d,"addObject:",argument);
}
}
return _d;
}
}),new objj_method(sel_getUid("initWithSet:"),function(_11,_12,_13){
with(_11){
return objj_msgSend(_11,"initWithSet:copyItems:",_13,NO);
}
}),new objj_method(sel_getUid("initWithSet:copyItems:"),function(_14,_15,_16,_17){
with(_14){
_14=objj_msgSend(_14,"init");
if(!_16){
return _14;
}
var _18=_16._contents;
for(var _19 in _18){
if(_18.hasOwnProperty(_19)){
if(_17){
objj_msgSend(_14,"addObject:",objj_msgSend(_18[_19],"copy"));
}else{
objj_msgSend(_14,"addObject:",_18[_19]);
}
}
}
return _14;
}
}),new objj_method(sel_getUid("allObjects"),function(_1a,_1b){
with(_1a){
var _1c=[];
for(var _1d in _contents){
if(_contents.hasOwnProperty(_1d)){
_1c.push(_contents[_1d]);
}
}
return _1c;
}
}),new objj_method(sel_getUid("anyObject"),function(_1e,_1f){
with(_1e){
for(var _20 in _contents){
if(_contents.hasOwnProperty(_20)){
return _contents[_20];
}
}
return nil;
}
}),new objj_method(sel_getUid("containsObject:"),function(_21,_22,_23){
with(_21){
var obj=_contents[objj_msgSend(_23,"UID")];
if(obj!==undefined&&objj_msgSend(obj,"isEqual:",_23)){
return YES;
}
return NO;
}
}),new objj_method(sel_getUid("count"),function(_24,_25){
with(_24){
return _count;
}
}),new objj_method(sel_getUid("intersectsSet:"),function(_26,_27,_28){
with(_26){
if(_26===_28){
return YES;
}
var _29=objj_msgSend(_28,"allObjects"),_2a=objj_msgSend(_29,"count");
while(_2a--){
if(objj_msgSend(_26,"containsObject:",_29[_2a])){
return YES;
}
}
return NO;
}
}),new objj_method(sel_getUid("isEqualToSet:"),function(_2b,_2c,set){
with(_2b){
return _2b===set||(objj_msgSend(_2b,"count")===objj_msgSend(set,"count")&&objj_msgSend(set,"isSubsetOfSet:",_2b));
}
}),new objj_method(sel_getUid("isSubsetOfSet:"),function(_2d,_2e,set){
with(_2d){
var _2f=objj_msgSend(_2d,"allObjects");
for(var i=0;i<_2f.length;i++){
if(!objj_msgSend(set,"containsObject:",_2f[i])){
return NO;
}
}
return YES;
}
}),new objj_method(sel_getUid("makeObjectsPerformSelector:"),function(_30,_31,_32){
with(_30){
objj_msgSend(_30,"makeObjectsPerformSelector:withObject:",_32,nil);
}
}),new objj_method(sel_getUid("makeObjectsPerformSelector:withObject:"),function(_33,_34,_35,_36){
with(_33){
var _37=objj_msgSend(_33,"allObjects");
for(var i=0;i<_37.length;i++){
objj_msgSend(_37[i],"performSelector:withObject:",_35,_36);
}
}
}),new objj_method(sel_getUid("member:"),function(_38,_39,_3a){
with(_38){
if(objj_msgSend(_38,"containsObject:",_3a)){
return _3a;
}
return nil;
}
}),new objj_method(sel_getUid("objectEnumerator"),function(_3b,_3c){
with(_3b){
return objj_msgSend(objj_msgSend(_3b,"allObjects"),"objectEnumerator");
}
}),new objj_method(sel_getUid("initWithCapacity:"),function(_3d,_3e,_3f){
with(_3d){
_3d=objj_msgSend(_3d,"init");
return _3d;
}
}),new objj_method(sel_getUid("setSet:"),function(_40,_41,set){
with(_40){
objj_msgSend(_40,"removeAllObjects");
objj_msgSend(_40,"addObjectsFromArray:",objj_msgSend(set,"allObjects"));
}
}),new objj_method(sel_getUid("addObject:"),function(_42,_43,_44){
with(_42){
if(objj_msgSend(_42,"containsObject:",_44)){
return;
}
_contents[objj_msgSend(_44,"UID")]=_44;
_count++;
}
}),new objj_method(sel_getUid("addObjectsFromArray:"),function(_45,_46,_47){
with(_45){
var _48=objj_msgSend(_47,"count");
while(_48--){
objj_msgSend(_45,"addObject:",_47[_48]);
}
}
}),new objj_method(sel_getUid("removeObject:"),function(_49,_4a,_4b){
with(_49){
if(objj_msgSend(_49,"containsObject:",_4b)){
delete _contents[objj_msgSend(_4b,"UID")];
_count--;
}
}
}),new objj_method(sel_getUid("removeObjectsInArray:"),function(_4c,_4d,_4e){
with(_4c){
var _4f=objj_msgSend(_4e,"count");
while(_4f--){
objj_msgSend(_4c,"removeObject:",_4e[_4f]);
}
}
}),new objj_method(sel_getUid("removeAllObjects"),function(_50,_51){
with(_50){
_contents={};
_count=0;
}
}),new objj_method(sel_getUid("intersectSet:"),function(_52,_53,set){
with(_52){
var _54=objj_msgSend(_52,"allObjects");
for(var i=0,_55=_54.length;i<_55;i++){
if(!objj_msgSend(set,"containsObject:",_54[i])){
objj_msgSend(_52,"removeObject:",_54[i]);
}
}
}
}),new objj_method(sel_getUid("minusSet:"),function(_56,_57,set){
with(_56){
var _58=objj_msgSend(set,"allObjects");
for(var i=0;i<_58.length;i++){
if(objj_msgSend(_56,"containsObject:",_58[i])){
objj_msgSend(_56,"removeObject:",_58[i]);
}
}
}
}),new objj_method(sel_getUid("unionSet:"),function(_59,_5a,set){
with(_59){
var _5b=objj_msgSend(set,"allObjects");
for(var i=0,_5c=_5b.length;i<_5c;i++){
objj_msgSend(_59,"addObject:",_5b[i]);
}
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("set"),function(_5d,_5e){
with(_5d){
return objj_msgSend(objj_msgSend(_5d,"alloc"),"init");
}
}),new objj_method(sel_getUid("setWithArray:"),function(_5f,_60,_61){
with(_5f){
return objj_msgSend(objj_msgSend(_5f,"alloc"),"initWithArray:",_61);
}
}),new objj_method(sel_getUid("setWithObject:"),function(_62,_63,_64){
with(_62){
return objj_msgSend(objj_msgSend(_62,"alloc"),"initWithArray:",[_64]);
}
}),new objj_method(sel_getUid("setWithObjects:count:"),function(_65,_66,_67,_68){
with(_65){
return objj_msgSend(objj_msgSend(_65,"alloc"),"initWithObjects:count:",_67,_68);
}
}),new objj_method(sel_getUid("setWithObjects:"),function(_69,_6a,_6b){
with(_69){
var set=objj_msgSend(objj_msgSend(_69,"alloc"),"init"),_6c=arguments.length,i=2;
for(;i<_6c&&((argument=arguments[i])!==nil);++i){
objj_msgSend(set,"addObject:",argument);
}
return set;
}
}),new objj_method(sel_getUid("setWithSet:"),function(_6d,_6e,set){
with(_6d){
return objj_msgSend(objj_msgSend(_6d,"alloc"),"initWithSet:",set);
}
}),new objj_method(sel_getUid("setWithCapacity:"),function(_6f,_70,_71){
with(_6f){
return objj_msgSend(objj_msgSend(_6f,"alloc"),"initWithCapacity:",_71);
}
})]);
var _1=objj_getClass("CPSet");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPSet\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("copy"),function(_72,_73){
with(_72){
return objj_msgSend(objj_msgSend(CPSet,"alloc"),"initWithSet:",_72);
}
}),new objj_method(sel_getUid("mutableCopy"),function(_74,_75){
with(_74){
return objj_msgSend(_74,"copy");
}
})]);
var _76="CPSetObjectsKey";
var _1=objj_getClass("CPSet");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPSet\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_77,_78,_79){
with(_77){
return objj_msgSend(_77,"initWithArray:",objj_msgSend(_79,"decodeObjectForKey:",_76));
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_7a,_7b,_7c){
with(_7a){
objj_msgSend(_7c,"encodeObject:forKey:",objj_msgSend(_7a,"allObjects"),_76);
}
})]);
var _1=objj_getClass("CPSet");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPSet\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("countByEnumeratingWithState:objects:count:"),function(_7d,_7e,_7f,_80,_81){
with(_7d){
var _82=objj_msgSend(_7d,"count");
if(_7f.state>=_82){
return 0;
}
_82=objj_msgSend(objj_msgSend(_7d,"allObjects"),"countByEnumeratingWithState:objects:count:",_7f,_80,_81);
return _82;
}
})]);
var _1=objj_allocateClassPair(CPSet,"CPMutableSet"),_2=_1.isa;
objj_registerClassPair(_1);
p;18;CPSortDescriptor.jt;2029;@STATIC;1.0;i;10;CPObject.ji;15;CPObjJRuntime.jt;1975;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPObjJRuntime.j",true);
CPOrderedAscending=-1;
CPOrderedSame=0;
CPOrderedDescending=1;
var _1=objj_allocateClassPair(CPObject,"CPSortDescriptor"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_key"),new objj_ivar("_selector"),new objj_ivar("_ascending")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithKey:ascending:"),function(_3,_4,_5,_6){
with(_3){
return objj_msgSend(_3,"initWithKey:ascending:selector:",_5,_6,sel_getUid("compare:"));
}
}),new objj_method(sel_getUid("initWithKey:ascending:selector:"),function(_7,_8,_9,_a,_b){
with(_7){
_7=objj_msgSendSuper({receiver:_7,super_class:objj_getClass("CPSortDescriptor").super_class},"init");
if(_7){
_key=_9;
_ascending=_a;
_selector=_b;
}
return _7;
}
}),new objj_method(sel_getUid("ascending"),function(_c,_d){
with(_c){
return _ascending;
}
}),new objj_method(sel_getUid("key"),function(_e,_f){
with(_e){
return _key;
}
}),new objj_method(sel_getUid("selector"),function(_10,_11){
with(_10){
return _selector;
}
}),new objj_method(sel_getUid("compareObject:withObject:"),function(_12,_13,_14,_15){
with(_12){
return (_ascending?1:-1)*objj_msgSend(objj_msgSend(_14,"valueForKeyPath:",_key),"performSelector:withObject:",_selector,objj_msgSend(_15,"valueForKeyPath:",_key));
}
}),new objj_method(sel_getUid("reversedSortDescriptor"),function(_16,_17){
with(_16){
return objj_msgSend(objj_msgSend(objj_msgSend(_16,"class"),"alloc"),"initWithKey:ascending:selector:",_key,!_ascending,_selector);
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("sortDescriptorWithKey:ascending:"),function(_18,_19,_1a,_1b){
with(_18){
return objj_msgSend(objj_msgSend(_18,"alloc"),"initWithKey:ascending:",_1a,_1b);
}
}),new objj_method(sel_getUid("sortDescriptorWithKey:ascending:selector:"),function(_1c,_1d,_1e,_1f,_20){
with(_1c){
return objj_msgSend(objj_msgSend(_1c,"alloc"),"initWithKey:ascending:selector:",_1e,_1f,_20);
}
})]);
p;10;CPString.jt;10237;@STATIC;1.0;i;10;CPObject.ji;13;CPException.ji;18;CPSortDescriptor.ji;9;CPValue.jt;10148;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPException.j",true);
objj_executeFile("CPSortDescriptor.j",true);
objj_executeFile("CPValue.j",true);
CPCaseInsensitiveSearch=1;
CPLiteralSearch=2;
CPBackwardsSearch=4;
CPAnchoredSearch=8;
CPNumericSearch=64;
var _1=new CFMutableDictionary();
var _2=["/",".","*","+","?","|","$","^","(",")","[","]","{","}","\\"],_3=new RegExp("(\\"+_2.join("|\\")+")","g"),_4=new RegExp("(^\\s+|\\s+$)","g");
var _5=objj_allocateClassPair(CPObject,"CPString"),_6=_5.isa;
objj_registerClassPair(_5);
class_addMethods(_5,[new objj_method(sel_getUid("initWithString:"),function(_7,_8,_9){
with(_7){
return String(_9);
}
}),new objj_method(sel_getUid("initWithFormat:"),function(_a,_b,_c){
with(_a){
if(!_c){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"initWithFormat: the format can't be 'nil'");
}
_a=sprintf.apply(this,Array.prototype.slice.call(arguments,2));
return _a;
}
}),new objj_method(sel_getUid("description"),function(_d,_e){
with(_d){
return _d;
}
}),new objj_method(sel_getUid("length"),function(_f,_10){
with(_f){
return length;
}
}),new objj_method(sel_getUid("characterAtIndex:"),function(_11,_12,_13){
with(_11){
return charAt(_13);
}
}),new objj_method(sel_getUid("stringByAppendingFormat:"),function(_14,_15,_16){
with(_14){
if(!_16){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"initWithFormat: the format can't be 'nil'");
}
return _14+sprintf.apply(this,Array.prototype.slice.call(arguments,2));
}
}),new objj_method(sel_getUid("stringByAppendingString:"),function(_17,_18,_19){
with(_17){
return _17+_19;
}
}),new objj_method(sel_getUid("stringByPaddingToLength:withString:startingAtIndex:"),function(_1a,_1b,_1c,_1d,_1e){
with(_1a){
if(length==_1c){
return _1a;
}
if(_1c<length){
return substr(0,_1c);
}
var _1f=_1a,_20=_1d.substring(_1e),_21=_1c-length;
while((_21-=_20.length)>=0){
_1f+=_20;
}
if(-_21<_20.length){
_1f+=_20.substring(0,-_21);
}
return _1f;
}
}),new objj_method(sel_getUid("componentsSeparatedByString:"),function(_22,_23,_24){
with(_22){
return split(_24);
}
}),new objj_method(sel_getUid("substringFromIndex:"),function(_25,_26,_27){
with(_25){
return substr(_27);
}
}),new objj_method(sel_getUid("substringWithRange:"),function(_28,_29,_2a){
with(_28){
return substr(_2a.location,_2a.length);
}
}),new objj_method(sel_getUid("substringToIndex:"),function(_2b,_2c,_2d){
with(_2b){
return substring(0,_2d);
}
}),new objj_method(sel_getUid("rangeOfString:"),function(_2e,_2f,_30){
with(_2e){
return objj_msgSend(_2e,"rangeOfString:options:",_30,0);
}
}),new objj_method(sel_getUid("rangeOfString:options:"),function(_31,_32,_33,_34){
with(_31){
return objj_msgSend(_31,"rangeOfString:options:range:",_33,_34,nil);
}
}),new objj_method(sel_getUid("rangeOfString:options:range:"),function(_35,_36,_37,_38,_39){
with(_35){
var _3a=(_39==nil)?_35:objj_msgSend(_35,"substringWithRange:",_39),_3b=CPNotFound;
if(_38&CPCaseInsensitiveSearch){
_3a=_3a.toLowerCase();
_37=_37.toLowerCase();
}
if(_38&CPBackwardsSearch){
_3b=_3a.lastIndexOf(_37,_38&CPAnchoredSearch?length-_37.length:0);
}else{
if(_38&CPAnchoredSearch){
_3b=_3a.substr(0,_37.length).indexOf(_37)!=CPNotFound?0:CPNotFound;
}else{
_3b=_3a.indexOf(_37);
}
}
return CPMakeRange(_3b,_3b==CPNotFound?0:_37.length);
}
}),new objj_method(sel_getUid("stringByEscapingRegexControlCharacters"),function(_3c,_3d){
with(_3c){
return _3c.replace(_3,"\\$1");
}
}),new objj_method(sel_getUid("stringByReplacingOccurrencesOfString:withString:"),function(_3e,_3f,_40,_41){
with(_3e){
return _3e.replace(new RegExp(objj_msgSend(_40,"stringByEscapingRegexControlCharacters"),"g"),_41);
}
}),new objj_method(sel_getUid("stringByReplacingOccurrencesOfString:withString:options:range:"),function(_42,_43,_44,_45,_46,_47){
with(_42){
var _48=substring(0,_47.location),_49=substr(_47.location,_47.length),end=substring(_47.location+_47.length,_42.length),_44=objj_msgSend(_44,"stringByEscapingRegexControlCharacters"),_4a;
if(_46&CPCaseInsensitiveSearch){
_4a=new RegExp(_44,"gi");
}else{
_4a=new RegExp(_44,"g");
}
return _48+""+_49.replace(_4a,_45)+""+end;
}
}),new objj_method(sel_getUid("stringByReplacingCharactersInRange:withString:"),function(_4b,_4c,_4d,_4e){
with(_4b){
return ""+substring(0,_4d.location)+_4e+substring(_4d.location+_4d.length,_4b.length);
}
}),new objj_method(sel_getUid("stringByTrimmingWhitespace"),function(_4f,_50){
with(_4f){
return _4f.replace(_4,"");
}
}),new objj_method(sel_getUid("compare:"),function(_51,_52,_53){
with(_51){
return objj_msgSend(_51,"compare:options:",_53,nil);
}
}),new objj_method(sel_getUid("caseInsensitiveCompare:"),function(_54,_55,_56){
with(_54){
return objj_msgSend(_54,"compare:options:",_56,CPCaseInsensitiveSearch);
}
}),new objj_method(sel_getUid("compare:options:"),function(_57,_58,_59,_5a){
with(_57){
var lhs=_57,rhs=_59;
if(_5a&CPCaseInsensitiveSearch){
lhs=lhs.toLowerCase();
rhs=rhs.toLowerCase();
}
if(lhs<rhs){
return CPOrderedAscending;
}else{
if(lhs>rhs){
return CPOrderedDescending;
}
}
return CPOrderedSame;
}
}),new objj_method(sel_getUid("compare:options:range:"),function(_5b,_5c,_5d,_5e,_5f){
with(_5b){
var lhs=objj_msgSend(_5b,"substringWithRange:",_5f),rhs=_5d;
return objj_msgSend(lhs,"compare:options:",rhs,_5e);
}
}),new objj_method(sel_getUid("hasPrefix:"),function(_60,_61,_62){
with(_60){
return _62&&_62!=""&&indexOf(_62)==0;
}
}),new objj_method(sel_getUid("hasSuffix:"),function(_63,_64,_65){
with(_63){
return _65&&_65!=""&&length>=_65.length&&lastIndexOf(_65)==(length-_65.length);
}
}),new objj_method(sel_getUid("isEqualToString:"),function(_66,_67,_68){
with(_66){
return _66==_68;
}
}),new objj_method(sel_getUid("UID"),function(_69,_6a){
with(_69){
var UID=_1.valueForKey(_69);
if(!UID){
UID=objj_generateObjectUID();
_1.setValueForKey(_69,UID);
}
return UID+"";
}
}),new objj_method(sel_getUid("commonPrefixWithString:"),function(_6b,_6c,_6d){
with(_6b){
return objj_msgSend(_6b,"commonPrefixWithString:options:",_6d,0);
}
}),new objj_method(sel_getUid("commonPrefixWithString:options:"),function(_6e,_6f,_70,_71){
with(_6e){
var len=0,lhs=_6e,rhs=_70,min=MIN(objj_msgSend(lhs,"length"),objj_msgSend(rhs,"length"));
if(_71&CPCaseInsensitiveSearch){
lhs=objj_msgSend(lhs,"lowercaseString");
rhs=objj_msgSend(rhs,"lowercaseString");
}
for(;len<min;len++){
if(objj_msgSend(lhs,"characterAtIndex:",len)!==objj_msgSend(rhs,"characterAtIndex:",len)){
break;
}
}
return objj_msgSend(_6e,"substringToIndex:",len);
}
}),new objj_method(sel_getUid("capitalizedString"),function(_72,_73){
with(_72){
var _74=_72.split(/\b/g);
for(var i=0;i<_74.length;i++){
if(i==0||(/\s$/).test(_74[i-1])){
_74[i]=_74[i].substring(0,1).toUpperCase()+_74[i].substring(1).toLowerCase();
}else{
_74[i]=_74[i].toLowerCase();
}
}
return _74.join("");
}
}),new objj_method(sel_getUid("lowercaseString"),function(_75,_76){
with(_75){
return toLowerCase();
}
}),new objj_method(sel_getUid("uppercaseString"),function(_77,_78){
with(_77){
return toUpperCase();
}
}),new objj_method(sel_getUid("doubleValue"),function(_79,_7a){
with(_79){
return parseFloat(_79,10);
}
}),new objj_method(sel_getUid("boolValue"),function(_7b,_7c){
with(_7b){
var _7d=new RegExp("^\\s*[\\+,\\-]*0*");
return RegExp("^[Y,y,t,T,1-9]").test(_7b.replace(_7d,""));
}
}),new objj_method(sel_getUid("floatValue"),function(_7e,_7f){
with(_7e){
return parseFloat(_7e,10);
}
}),new objj_method(sel_getUid("intValue"),function(_80,_81){
with(_80){
return parseInt(_80,10);
}
}),new objj_method(sel_getUid("pathComponents"),function(_82,_83){
with(_82){
var _84=split("/");
if(_84[0]===""){
_84[0]="/";
}
if(_84[_84.length-1]===""){
_84.pop();
}
return _84;
}
}),new objj_method(sel_getUid("pathExtension"),function(_85,_86){
with(_85){
return substr(lastIndexOf(".")+1);
}
}),new objj_method(sel_getUid("lastPathComponent"),function(_87,_88){
with(_87){
var _89=objj_msgSend(_87,"pathComponents");
return _89[_89.length-1];
}
}),new objj_method(sel_getUid("stringByDeletingLastPathComponent"),function(_8a,_8b){
with(_8a){
var _8c=_8a,_8d=length-1;
while(_8c.charAt(_8d)==="/"){
_8d--;
}
_8c=_8c.substr(0,_8c.lastIndexOf("/",_8d));
if(_8c===""&&charAt(0)==="/"){
return "/";
}
return _8c;
}
}),new objj_method(sel_getUid("stringByStandardizingPath"),function(_8e,_8f){
with(_8e){
return objj_standardize_path(_8e);
}
}),new objj_method(sel_getUid("copy"),function(_90,_91){
with(_90){
return new String(_90);
}
})]);
class_addMethods(_6,[new objj_method(sel_getUid("alloc"),function(_92,_93){
with(_92){
return new String;
}
}),new objj_method(sel_getUid("string"),function(_94,_95){
with(_94){
return objj_msgSend(objj_msgSend(_94,"alloc"),"init");
}
}),new objj_method(sel_getUid("stringWithHash:"),function(_96,_97,_98){
with(_96){
var _99=parseInt(_98,10).toString(16);
return "000000".substring(0,MAX(6-_99.length,0))+_99;
}
}),new objj_method(sel_getUid("stringWithString:"),function(_9a,_9b,_9c){
with(_9a){
if(!_9c){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"stringWithString: the string can't be 'nil'");
}
return objj_msgSend(objj_msgSend(_9a,"alloc"),"initWithString:",_9c);
}
}),new objj_method(sel_getUid("stringWithFormat:"),function(_9d,_9e,_9f){
with(_9d){
if(!_9f){
objj_msgSend(CPException,"raise:reason:",CPInvalidArgumentException,"initWithFormat: the format can't be 'nil'");
}
return sprintf.apply(this,Array.prototype.slice.call(arguments,2));
}
})]);
var _5=objj_getClass("CPString");
if(!_5){
throw new SyntaxError("*** Could not find definition for class \"CPString\"");
}
var _6=_5.isa;
class_addMethods(_5,[new objj_method(sel_getUid("objectFromJSON"),function(_a0,_a1){
with(_a0){
return JSON.parse(_a0);
}
})]);
class_addMethods(_6,[new objj_method(sel_getUid("JSONFromObject:"),function(_a2,_a3,_a4){
with(_a2){
return JSON.stringify(_a4);
}
})]);
var _5=objj_getClass("CPString");
if(!_5){
throw new SyntaxError("*** Could not find definition for class \"CPString\"");
}
var _6=_5.isa;
class_addMethods(_6,[new objj_method(sel_getUid("UUID"),function(_a5,_a6){
with(_a5){
var g="";
for(var i=0;i<32;i++){
g+=FLOOR(RAND()*15).toString(15);
}
return g;
}
})]);
String.prototype.isa=CPString;
p;9;CPTimer.jt;5531;@STATIC;1.0;i;10;CPObject.ji;14;CPInvocation.ji;8;CPDate.ji;11;CPRunLoop.jt;5450;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPInvocation.j",true);
objj_executeFile("CPDate.j",true);
objj_executeFile("CPRunLoop.j",true);
var _1=objj_allocateClassPair(CPObject,"CPTimer"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_timeInterval"),new objj_ivar("_invocation"),new objj_ivar("_callback"),new objj_ivar("_repeats"),new objj_ivar("_isValid"),new objj_ivar("_fireDate"),new objj_ivar("_userInfo")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithFireDate:interval:invocation:repeats:"),function(_3,_4,_5,_6,_7,_8){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPTimer").super_class},"init");
if(_3){
_timeInterval=_6;
_invocation=_7;
_repeats=_8;
_isValid=YES;
_fireDate=_5;
}
return _3;
}
}),new objj_method(sel_getUid("initWithFireDate:interval:target:selector:userInfo:repeats:"),function(_9,_a,_b,_c,_d,_e,_f,_10){
with(_9){
var _11=objj_msgSend(CPInvocation,"invocationWithMethodSignature:",1);
objj_msgSend(_11,"setTarget:",_d);
objj_msgSend(_11,"setSelector:",_e);
objj_msgSend(_11,"setArgument:atIndex:",_9,2);
_9=objj_msgSend(_9,"initWithFireDate:interval:invocation:repeats:",_b,_c,_11,_10);
if(_9){
_userInfo=_f;
}
return _9;
}
}),new objj_method(sel_getUid("initWithFireDate:interval:callback:repeats:"),function(_12,_13,_14,_15,_16,_17){
with(_12){
_12=objj_msgSendSuper({receiver:_12,super_class:objj_getClass("CPTimer").super_class},"init");
if(_12){
_timeInterval=_15;
_callback=_16;
_repeats=_17;
_isValid=YES;
_fireDate=_14;
}
return _12;
}
}),new objj_method(sel_getUid("timeInterval"),function(_18,_19){
with(_18){
return _timeInterval;
}
}),new objj_method(sel_getUid("fireDate"),function(_1a,_1b){
with(_1a){
return _fireDate;
}
}),new objj_method(sel_getUid("setFireDate:"),function(_1c,_1d,_1e){
with(_1c){
_fireDate=_1e;
}
}),new objj_method(sel_getUid("fire"),function(_1f,_20){
with(_1f){
if(!_isValid){
return;
}
if(_callback){
_callback();
}else{
objj_msgSend(_invocation,"invoke");
}
if(!_isValid){
return;
}
if(_repeats){
_fireDate=objj_msgSend(CPDate,"dateWithTimeIntervalSinceNow:",_timeInterval);
}else{
objj_msgSend(_1f,"invalidate");
}
}
}),new objj_method(sel_getUid("isValid"),function(_21,_22){
with(_21){
return _isValid;
}
}),new objj_method(sel_getUid("invalidate"),function(_23,_24){
with(_23){
_isValid=NO;
_userInfo=nil;
_invocation=nil;
_callback=nil;
}
}),new objj_method(sel_getUid("userInfo"),function(_25,_26){
with(_25){
return _userInfo;
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("scheduledTimerWithTimeInterval:invocation:repeats:"),function(_27,_28,_29,_2a,_2b){
with(_27){
var _2c=objj_msgSend(objj_msgSend(_27,"alloc"),"initWithFireDate:interval:invocation:repeats:",objj_msgSend(CPDate,"dateWithTimeIntervalSinceNow:",_29),_29,_2a,_2b);
objj_msgSend(objj_msgSend(CPRunLoop,"currentRunLoop"),"addTimer:forMode:",_2c,CPDefaultRunLoopMode);
return _2c;
}
}),new objj_method(sel_getUid("scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:"),function(_2d,_2e,_2f,_30,_31,_32,_33){
with(_2d){
var _34=objj_msgSend(objj_msgSend(_2d,"alloc"),"initWithFireDate:interval:target:selector:userInfo:repeats:",objj_msgSend(CPDate,"dateWithTimeIntervalSinceNow:",_2f),_2f,_30,_31,_32,_33);
objj_msgSend(objj_msgSend(CPRunLoop,"currentRunLoop"),"addTimer:forMode:",_34,CPDefaultRunLoopMode);
return _34;
}
}),new objj_method(sel_getUid("scheduledTimerWithTimeInterval:callback:repeats:"),function(_35,_36,_37,_38,_39){
with(_35){
var _3a=objj_msgSend(objj_msgSend(_35,"alloc"),"initWithFireDate:interval:callback:repeats:",objj_msgSend(CPDate,"dateWithTimeIntervalSinceNow:",_37),_37,_38,_39);
objj_msgSend(objj_msgSend(CPRunLoop,"currentRunLoop"),"addTimer:forMode:",_3a,CPDefaultRunLoopMode);
return _3a;
}
}),new objj_method(sel_getUid("timerWithTimeInterval:invocation:repeats:"),function(_3b,_3c,_3d,_3e,_3f){
with(_3b){
return objj_msgSend(objj_msgSend(_3b,"alloc"),"initWithFireDate:interval:invocation:repeats:",objj_msgSend(CPDate,"dateWithTimeIntervalSinceNow:",_3d),_3d,_3e,_3f);
}
}),new objj_method(sel_getUid("timerWithTimeInterval:target:selector:userInfo:repeats:"),function(_40,_41,_42,_43,_44,_45,_46){
with(_40){
return objj_msgSend(objj_msgSend(_40,"alloc"),"initWithFireDate:interval:target:selector:userInfo:repeats:",objj_msgSend(CPDate,"dateWithTimeIntervalSinceNow:",_42),_42,_43,_44,_45,_46);
}
}),new objj_method(sel_getUid("timerWithTimeInterval:callback:repeats:"),function(_47,_48,_49,_4a,_4b){
with(_47){
return objj_msgSend(objj_msgSend(_47,"alloc"),"initWithFireDate:interval:callback:repeats:",objj_msgSend(CPDate,"dateWithTimeIntervalSinceNow:",_49),_49,_4a,_4b);
}
})]);
var _4c=1000,_4d={};
var _4e=function(_4f,_50,_51,_52){
var _53=_4c++,_54=nil;
if(typeof _4f==="string"){
_54=function(){
new Function(_4f)();
if(!_51){
_4d[_53]=nil;
}
};
}else{
if(!_52){
_52=[];
}
_54=function(){
_4f.apply(window,_52);
if(!_51){
_4d[_53]=nil;
}
};
}
_4d[_53]=objj_msgSend(CPTimer,"scheduledTimerWithTimeInterval:callback:repeats:",_50/1000,_54,_51);
return _53;
};
window.setTimeout=function(_55,_56){
return _4e(_55,_56,NO,Array.prototype.slice.apply(arguments,[2]));
};
window.clearTimeout=function(_57){
var _58=_4d[_57];
if(_58){
objj_msgSend(_58,"invalidate");
}
_4d[_57]=nil;
};
window.setInterval=function(_59,_5a,_5b){
return _4e(_59,_5a,YES,Array.prototype.slice.apply(arguments,[2]));
};
window.clearInterval=function(_5c){
window.clearTimeout(_5c);
};
p;15;CPUndoManager.jt;15918;@STATIC;1.0;i;10;CPObject.ji;14;CPInvocation.ji;9;CPProxy.jt;15851;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPInvocation.j",true);
objj_executeFile("CPProxy.j",true);
var _1=0,_2=1,_3=2;
CPUndoManagerCheckpointNotification="CPUndoManagerCheckpointNotification";
CPUndoManagerDidOpenUndoGroupNotification="CPUndoManagerDidOpenUndoGroupNotification";
CPUndoManagerDidRedoChangeNotification="CPUndoManagerDidRedoChangeNotification";
CPUndoManagerDidUndoChangeNotification="CPUndoManagerDidUndoChangeNotification";
CPUndoManagerWillCloseUndoGroupNotification="CPUndoManagerWillCloseUndoGroupNotification";
CPUndoManagerWillRedoChangeNotification="CPUndoManagerWillRedoChangeNotification";
CPUndoManagerWillUndoChangeNotification="CPUndoManagerWillUndoChangeNotification";
CPUndoCloseGroupingRunLoopOrdering=350000;
var _4=[],_5=5;
var _6=objj_allocateClassPair(CPObject,"_CPUndoGrouping"),_7=_6.isa;
class_addIvars(_6,[new objj_ivar("_parent"),new objj_ivar("_invocations")]);
objj_registerClassPair(_6);
class_addMethods(_6,[new objj_method(sel_getUid("initWithParent:"),function(_8,_9,_a){
with(_8){
_8=objj_msgSendSuper({receiver:_8,super_class:objj_getClass("_CPUndoGrouping").super_class},"init");
if(_8){
_parent=_a;
_invocations=[];
}
return _8;
}
}),new objj_method(sel_getUid("parent"),function(_b,_c){
with(_b){
return _parent;
}
}),new objj_method(sel_getUid("addInvocation:"),function(_d,_e,_f){
with(_d){
_invocations.push(_f);
}
}),new objj_method(sel_getUid("addInvocationsFromArray:"),function(_10,_11,_12){
with(_10){
objj_msgSend(_invocations,"addObjectsFromArray:",_12);
}
}),new objj_method(sel_getUid("removeInvocationsWithTarget:"),function(_13,_14,_15){
with(_13){
var _16=_invocations.length;
while(_16--){
if(objj_msgSend(_invocations[_16],"target")==_15){
_invocations.splice(_16,1);
}
}
}
}),new objj_method(sel_getUid("invocations"),function(_17,_18){
with(_17){
return _invocations;
}
}),new objj_method(sel_getUid("invoke"),function(_19,_1a){
with(_19){
var _1b=_invocations.length;
while(_1b--){
objj_msgSend(_invocations[_1b],"invoke");
}
}
})]);
class_addMethods(_7,[new objj_method(sel_getUid("_poolUndoGrouping:"),function(_1c,_1d,_1e){
with(_1c){
if(!_1e||_4.length>=_5){
return;
}
_4.push(_1e);
}
}),new objj_method(sel_getUid("undoGroupingWithParent:"),function(_1f,_20,_21){
with(_1f){
if(_4.length){
var _22=_4.pop();
_22._parent=_21;
if(_22._invocations.length){
_22._invocations=[];
}
return _22;
}
return objj_msgSend(objj_msgSend(_1f,"alloc"),"initWithParent:",_21);
}
})]);
var _23="_CPUndoGroupingParentKey",_24="_CPUndoGroupingInvocationsKey";
var _6=objj_getClass("_CPUndoGrouping");
if(!_6){
throw new SyntaxError("*** Could not find definition for class \"_CPUndoGrouping\"");
}
var _7=_6.isa;
class_addMethods(_6,[new objj_method(sel_getUid("initWithCoder:"),function(_25,_26,_27){
with(_25){
_25=objj_msgSendSuper({receiver:_25,super_class:objj_getClass("_CPUndoGrouping").super_class},"init");
if(_25){
_parent=objj_msgSend(_27,"decodeObjectForKey:",_23);
_invocations=objj_msgSend(_27,"decodeObjectForKey:",_24);
}
return _25;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_28,_29,_2a){
with(_28){
objj_msgSend(_2a,"encodeObject:forKey:",_parent,_23);
objj_msgSend(_2a,"encodeObject:forKey:",_invocations,_24);
}
})]);
var _6=objj_allocateClassPair(CPObject,"CPUndoManager"),_7=_6.isa;
class_addIvars(_6,[new objj_ivar("_redoStack"),new objj_ivar("_undoStack"),new objj_ivar("_groupsByEvent"),new objj_ivar("_disableCount"),new objj_ivar("_levelsOfUndo"),new objj_ivar("_currentGrouping"),new objj_ivar("_state"),new objj_ivar("_actionName"),new objj_ivar("_preparedTarget"),new objj_ivar("_undoManagerProxy"),new objj_ivar("_runLoopModes"),new objj_ivar("_registeredWithRunLoop")]);
objj_registerClassPair(_6);
class_addMethods(_6,[new objj_method(sel_getUid("init"),function(_2b,_2c){
with(_2b){
_2b=objj_msgSendSuper({receiver:_2b,super_class:objj_getClass("CPUndoManager").super_class},"init");
if(_2b){
_redoStack=[];
_undoStack=[];
_state=_1;
objj_msgSend(_2b,"setRunLoopModes:",[CPDefaultRunLoopMode]);
objj_msgSend(_2b,"setGroupsByEvent:",YES);
_undoManagerProxy=objj_msgSend(_CPUndoManagerProxy,"alloc");
_undoManagerProxy._undoManager=_2b;
}
return _2b;
}
}),new objj_method(sel_getUid("_addUndoInvocation:"),function(_2d,_2e,_2f){
with(_2d){
if(!_currentGrouping){
if(objj_msgSend(_2d,"groupsByEvent")){
objj_msgSend(_2d,"_beginUndoGroupingForEvent");
}else{
objj_msgSend(CPException,"raise:reason:",CPInternalInconsistencyException,"No undo group is currently open");
}
}
objj_msgSend(_currentGrouping,"addInvocation:",_2f);
if(_state===_1){
objj_msgSend(_redoStack,"removeAllObjects");
}
}
}),new objj_method(sel_getUid("registerUndoWithTarget:selector:object:"),function(_30,_31,_32,_33,_34){
with(_30){
if(_disableCount>0){
return;
}
var _35=objj_msgSend(CPInvocation,"invocationWithMethodSignature:",nil);
objj_msgSend(_35,"setTarget:",_32);
objj_msgSend(_35,"setSelector:",_33);
objj_msgSend(_35,"setArgument:atIndex:",_34,2);
objj_msgSend(_30,"_addUndoInvocation:",_35);
}
}),new objj_method(sel_getUid("prepareWithInvocationTarget:"),function(_36,_37,_38){
with(_36){
_preparedTarget=_38;
return _undoManagerProxy;
}
}),new objj_method(sel_getUid("_methodSignatureOfPreparedTargetForSelector:"),function(_39,_3a,_3b){
with(_39){
if(objj_msgSend(_preparedTarget,"respondsToSelector:",_3b)){
return 1;
}
return nil;
}
}),new objj_method(sel_getUid("_forwardInvocationToPreparedTarget:"),function(_3c,_3d,_3e){
with(_3c){
if(_disableCount>0){
return;
}
objj_msgSend(_3e,"setTarget:",_preparedTarget);
objj_msgSend(_3c,"_addUndoInvocation:",_3e);
_preparedTarget=nil;
}
}),new objj_method(sel_getUid("canRedo"),function(_3f,_40){
with(_3f){
objj_msgSend(objj_msgSend(CPNotificationCenter,"defaultCenter"),"postNotificationName:object:",CPUndoManagerCheckpointNotification,_3f);
return objj_msgSend(_redoStack,"count")>0;
}
}),new objj_method(sel_getUid("canUndo"),function(_41,_42){
with(_41){
if(_undoStack.length>0){
return YES;
}
return objj_msgSend(_currentGrouping,"actions").length>0;
}
}),new objj_method(sel_getUid("undo"),function(_43,_44){
with(_43){
if(objj_msgSend(_43,"groupingLevel")===1){
objj_msgSend(_43,"endUndoGrouping");
}
objj_msgSend(_43,"undoNestedGroup");
}
}),new objj_method(sel_getUid("undoNestedGroup"),function(_45,_46){
with(_45){
if(objj_msgSend(_undoStack,"count")<=0){
return;
}
var _47=objj_msgSend(CPNotificationCenter,"defaultCenter");
objj_msgSend(_47,"postNotificationName:object:",CPUndoManagerCheckpointNotification,_45);
objj_msgSend(_47,"postNotificationName:object:",CPUndoManagerWillUndoChangeNotification,_45);
var _48=_undoStack.pop();
_state=_2;
objj_msgSend(_45,"_beginUndoGrouping");
objj_msgSend(_48,"invoke");
objj_msgSend(_45,"endUndoGrouping");
objj_msgSend(_CPUndoGrouping,"_poolUndoGrouping:",_48);
_state=_1;
objj_msgSend(_47,"postNotificationName:object:",CPUndoManagerDidUndoChangeNotification,_45);
}
}),new objj_method(sel_getUid("redo"),function(_49,_4a){
with(_49){
if(objj_msgSend(_redoStack,"count")<=0){
return;
}
var _4b=objj_msgSend(CPNotificationCenter,"defaultCenter");
objj_msgSend(_4b,"postNotificationName:object:",CPUndoManagerCheckpointNotification,_49);
objj_msgSend(_4b,"postNotificationName:object:",CPUndoManagerWillRedoChangeNotification,_49);
var _4c=_currentGrouping,_4d=_redoStack.pop();
_currentGrouping=nil;
_state=_3;
objj_msgSend(_49,"_beginUndoGrouping");
objj_msgSend(_4d,"invoke");
objj_msgSend(_49,"endUndoGrouping");
objj_msgSend(_CPUndoGrouping,"_poolUndoGrouping:",_4d);
_currentGrouping=_4c;
_state=_1;
objj_msgSend(_4b,"postNotificationName:object:",CPUndoManagerDidRedoChangeNotification,_49);
}
}),new objj_method(sel_getUid("beginUndoGrouping"),function(_4e,_4f){
with(_4e){
if(!_currentGrouping&&objj_msgSend(_4e,"groupsByEvent")){
objj_msgSend(_4e,"_beginUndoGroupingForEvent");
}
objj_msgSend(objj_msgSend(CPNotificationCenter,"defaultCenter"),"postNotificationName:object:",CPUndoManagerCheckpointNotification,_4e);
objj_msgSend(_4e,"_beginUndoGrouping");
}
}),new objj_method(sel_getUid("_beginUndoGroupingForEvent"),function(_50,_51){
with(_50){
objj_msgSend(_50,"_beginUndoGrouping");
objj_msgSend(_50,"_registerWithRunLoop");
}
}),new objj_method(sel_getUid("_beginUndoGrouping"),function(_52,_53){
with(_52){
_currentGrouping=objj_msgSend(_CPUndoGrouping,"undoGroupingWithParent:",_currentGrouping);
}
}),new objj_method(sel_getUid("endUndoGrouping"),function(_54,_55){
with(_54){
if(!_currentGrouping){
objj_msgSend(CPException,"raise:reason:",CPInternalInconsistencyException,"endUndoGrouping. No undo group is currently open.");
}
var _56=objj_msgSend(CPNotificationCenter,"defaultCenter");
objj_msgSend(_56,"postNotificationName:object:",CPUndoManagerCheckpointNotification,_54);
var _57=objj_msgSend(_currentGrouping,"parent");
if(!_57&&objj_msgSend(_currentGrouping,"invocations").length>0){
objj_msgSend(_56,"postNotificationName:object:",CPUndoManagerWillCloseUndoGroupNotification,_54);
var _58=_state===_2?_redoStack:_undoStack;
_58.push(_currentGrouping);
if(_levelsOfUndo>0&&_58.length>_levelsOfUndo){
_58.splice(0,1);
}
}else{
objj_msgSend(_57,"addInvocationsFromArray:",objj_msgSend(_currentGrouping,"invocations"));
objj_msgSend(_CPUndoGrouping,"_poolUndoGrouping:",_currentGrouping);
}
_currentGrouping=_57;
}
}),new objj_method(sel_getUid("enableUndoRegistration"),function(_59,_5a){
with(_59){
if(_disableCount<=0){
objj_msgSend(CPException,"raise:reason:",CPInternalInconsistencyException,"enableUndoRegistration. There are no disable messages in effect right now.");
}
_disableCount--;
}
}),new objj_method(sel_getUid("groupsByEvent"),function(_5b,_5c){
with(_5b){
return _groupsByEvent;
}
}),new objj_method(sel_getUid("setGroupsByEvent:"),function(_5d,_5e,_5f){
with(_5d){
_5f=!!_5f;
if(_groupsByEvent===_5f){
return;
}
_groupsByEvent=_5f;
if(!objj_msgSend(_5d,"groupsByEvent")){
objj_msgSend(_5d,"_unregisterWithRunLoop");
}
}
}),new objj_method(sel_getUid("groupingLevel"),function(_60,_61){
with(_60){
var _62=_currentGrouping,_63=_currentGrouping!=nil;
while(_62=objj_msgSend(_62,"parent")){
++_63;
}
return _63;
}
}),new objj_method(sel_getUid("disableUndoRegistration"),function(_64,_65){
with(_64){
++_disableCount;
}
}),new objj_method(sel_getUid("isUndoRegistrationEnabled"),function(_66,_67){
with(_66){
return _disableCount==0;
}
}),new objj_method(sel_getUid("isUndoing"),function(_68,_69){
with(_68){
return _state===_2;
}
}),new objj_method(sel_getUid("isRedoing"),function(_6a,_6b){
with(_6a){
return _state===_3;
}
}),new objj_method(sel_getUid("removeAllActions"),function(_6c,_6d){
with(_6c){
_redoStack=[];
_undoStack=[];
_disableCount=0;
}
}),new objj_method(sel_getUid("removeAllActionsWithTarget:"),function(_6e,_6f,_70){
with(_6e){
objj_msgSend(_currentGrouping,"removeInvocationsWithTarget:",_70);
var _71=_redoStack.length;
while(_71--){
var _72=_redoStack[_71];
objj_msgSend(_72,"removeInvocationsWithTarget:",_70);
if(!objj_msgSend(_72,"invocations").length){
_redoStack.splice(_71,1);
}
}
_71=_undoStack.length;
while(_71--){
var _72=_undoStack[_71];
objj_msgSend(_72,"removeInvocationsWithTarget:",_70);
if(!objj_msgSend(_72,"invocations").length){
_undoStack.splice(_71,1);
}
}
}
}),new objj_method(sel_getUid("setActionName:"),function(_73,_74,_75){
with(_73){
_actionName=_75;
}
}),new objj_method(sel_getUid("redoActionName"),function(_76,_77){
with(_76){
return objj_msgSend(_76,"canRedo")?_actionName:nil;
}
}),new objj_method(sel_getUid("undoActionName"),function(_78,_79){
with(_78){
return objj_msgSend(_78,"canUndo")?_actionName:nil;
}
}),new objj_method(sel_getUid("runLoopModes"),function(_7a,_7b){
with(_7a){
return _runLoopModes;
}
}),new objj_method(sel_getUid("setRunLoopModes:"),function(_7c,_7d,_7e){
with(_7c){
_runLoopModes=objj_msgSend(_7e,"copy");
if(_registeredWithRunLoop){
objj_msgSend(_7c,"_unregisterWithRunLoop");
objj_msgSend(_7c,"_registerWithRunLoop");
}
}
}),new objj_method(sel_getUid("_runLoopEndUndoGrouping"),function(_7f,_80){
with(_7f){
objj_msgSend(_7f,"endUndoGrouping");
_registeredWithRunLoop=NO;
}
}),new objj_method(sel_getUid("_registerWithRunLoop"),function(_81,_82){
with(_81){
if(_registeredWithRunLoop){
return;
}
_registeredWithRunLoop=YES;
objj_msgSend(objj_msgSend(CPRunLoop,"currentRunLoop"),"performSelector:target:argument:order:modes:",sel_getUid("_runLoopEndUndoGrouping"),_81,nil,CPUndoCloseGroupingRunLoopOrdering,_runLoopModes);
}
}),new objj_method(sel_getUid("_unregisterWithRunLoop"),function(_83,_84){
with(_83){
if(!_registeredWithRunLoop){
return;
}
_registeredWithRunLoop=NO;
objj_msgSend(objj_msgSend(CPRunLoop,"currentRunLoop"),"cancelPerformSelector:target:argument:",sel_getUid("_runLoopEndUndoGrouping"),_83,nil);
}
}),new objj_method(sel_getUid("observeChangesForKeyPath:ofObject:"),function(_85,_86,_87,_88){
with(_85){
objj_msgSend(_88,"addObserver:forKeyPath:options:context:",_85,_87,CPKeyValueObservingOptionOld|CPKeyValueObservingOptionNew,NULL);
}
}),new objj_method(sel_getUid("stopObservingChangesForKeyPath:ofObject:"),function(_89,_8a,_8b,_8c){
with(_89){
objj_msgSend(_8c,"removeObserver:forKeyPath:",_89,_8b);
}
}),new objj_method(sel_getUid("observeValueForKeyPath:ofObject:change:context:"),function(_8d,_8e,_8f,_90,_91,_92){
with(_8d){
objj_msgSend(objj_msgSend(_8d,"prepareWithInvocationTarget:",_90),"applyChange:toKeyPath:",objj_msgSend(_91,"inverseChangeDictionary"),_8f);
}
})]);
var _93="CPUndoManagerRedoStackKey",_94="CPUndoManagerUndoStackKey";
CPUndoManagerLevelsOfUndoKey="CPUndoManagerLevelsOfUndoKey";
CPUndoManagerActionNameKey="CPUndoManagerActionNameKey";
CPUndoManagerCurrentGroupingKey="CPUndoManagerCurrentGroupingKey";
CPUndoManagerRunLoopModesKey="CPUndoManagerRunLoopModesKey";
CPUndoManagerGroupsByEventKey="CPUndoManagerGroupsByEventKey";
var _6=objj_getClass("CPUndoManager");
if(!_6){
throw new SyntaxError("*** Could not find definition for class \"CPUndoManager\"");
}
var _7=_6.isa;
class_addMethods(_6,[new objj_method(sel_getUid("initWithCoder:"),function(_95,_96,_97){
with(_95){
_95=objj_msgSendSuper({receiver:_95,super_class:objj_getClass("CPUndoManager").super_class},"init");
if(_95){
_redoStack=objj_msgSend(_97,"decodeObjectForKey:",_93);
_undoStack=objj_msgSend(_97,"decodeObjectForKey:",_94);
_levelsOfUndo=objj_msgSend(_97,"decodeObjectForKey:",CPUndoManagerLevelsOfUndoKey);
_actionName=objj_msgSend(_97,"decodeObjectForKey:",CPUndoManagerActionNameKey);
_currentGrouping=objj_msgSend(_97,"decodeObjectForKey:",CPUndoManagerCurrentGroupingKey);
_state=_1;
objj_msgSend(_95,"setRunLoopModes:",objj_msgSend(_97,"decodeObjectForKey:",CPUndoManagerRunLoopModesKey));
objj_msgSend(_95,"setGroupsByEvent:",objj_msgSend(_97,"decodeBoolForKey:",CPUndoManagerGroupsByEventKey));
}
return _95;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_98,_99,_9a){
with(_98){
objj_msgSend(_9a,"encodeObject:forKey:",_redoStack,_93);
objj_msgSend(_9a,"encodeObject:forKey:",_undoStack,_94);
objj_msgSend(_9a,"encodeInt:forKey:",_levelsOfUndo,CPUndoManagerLevelsOfUndoKey);
objj_msgSend(_9a,"encodeObject:forKey:",_actionName,CPUndoManagerActionNameKey);
objj_msgSend(_9a,"encodeObject:forKey:",_currentGrouping,CPUndoManagerCurrentGroupingKey);
objj_msgSend(_9a,"encodeObject:forKey:",_runLoopModes,CPUndoManagerRunLoopModesKey);
objj_msgSend(_9a,"encodeBool:forKey:",_groupsByEvent,CPUndoManagerGroupsByEventKey);
}
})]);
var _6=objj_allocateClassPair(CPProxy,"_CPUndoManagerProxy"),_7=_6.isa;
class_addIvars(_6,[new objj_ivar("_undoManager")]);
objj_registerClassPair(_6);
class_addMethods(_6,[new objj_method(sel_getUid("methodSignatureForSelector:"),function(_9b,_9c,_9d){
with(_9b){
return objj_msgSend(_undoManager,"_methodSignatureOfPreparedTargetForSelector:",_9d);
}
}),new objj_method(sel_getUid("forwardInvocation:"),function(_9e,_9f,_a0){
with(_9e){
objj_msgSend(_undoManager,"_forwardInvocationToPreparedTarget:",_a0);
}
})]);
p;7;CPURL.jt;11467;@STATIC;1.0;I;21;Foundation/CPObject.jt;11421;
objj_executeFile("Foundation/CPObject.j",false);
CPURLNameKey="CPURLNameKey";
CPURLLocalizedNameKey="CPURLLocalizedNameKey";
CPURLIsRegularFileKey="CPURLIsRegularFileKey";
CPURLIsDirectoryKey="CPURLIsDirectoryKey";
CPURLIsSymbolicLinkKey="CPURLIsSymbolicLinkKey";
CPURLIsVolumeKey="CPURLIsVolumeKey";
CPURLIsPackageKey="CPURLIsPackageKey";
CPURLIsSystemImmutableKey="CPURLIsSystemImmutableKey";
CPURLIsUserImmutableKey="CPURLIsUserImmutableKey";
CPURLIsHiddenKey="CPURLIsHiddenKey";
CPURLHasHiddenExtensionKey="CPURLHasHiddenExtensionKey";
CPURLCreationDateKey="CPURLCreationDateKey";
CPURLContentAccessDateKey="CPURLContentAccessDateKey";
CPURLContentModificationDateKey="CPURLContentModificationDateKey";
CPURLAttributeModificationDateKey="CPURLAttributeModificationDateKey";
CPURLLinkCountKey="CPURLLinkCountKey";
CPURLParentDirectoryURLKey="CPURLParentDirectoryURLKey";
CPURLVolumeURLKey="CPURLTypeIdentifierKey";
CPURLTypeIdentifierKey="CPURLTypeIdentifierKey";
CPURLLocalizedTypeDescriptionKey="CPURLLocalizedTypeDescriptionKey";
CPURLLabelNumberKey="CPURLLabelNumberKey";
CPURLLabelColorKey="CPURLLabelColorKey";
CPURLLocalizedLabelKey="CPURLLocalizedLabelKey";
CPURLEffectiveIconKey="CPURLEffectiveIconKey";
CPURLCustomIconKey="CPURLCustomIconKey";
var _1=objj_allocateClassPair(CPObject,"CPURL"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_base"),new objj_ivar("_relative"),new objj_ivar("_resourceValues")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("baseURL"),function(_3,_4){
with(_3){
return _base;
}
}),new objj_method(sel_getUid("relativeString"),function(_5,_6){
with(_5){
return _relative;
}
}),new objj_method(sel_getUid("initWithScheme:host:path:"),function(_7,_8,_9,_a,_b){
with(_7){
var _c=new _d();
_c.scheme=_9;
_c.authority=_a;
_c.path=_b;
objj_msgSend(_7,"initWithString:",_c.toString());
}
}),new objj_method(sel_getUid("initWithString:"),function(_e,_f,_10){
with(_e){
return objj_msgSend(_e,"initWithString:relativeToURL:",_10,nil);
}
}),new objj_method(sel_getUid("initWithString:relativeToURL:"),function(_11,_12,_13,_14){
with(_11){
if(!_15.test(_13)){
return nil;
}
if(_11){
_base=_14;
_relative=_13;
_resourceValues=objj_msgSend(CPDictionary,"dictionary");
}
return _11;
}
}),new objj_method(sel_getUid("absoluteURL"),function(_16,_17){
with(_16){
var _18=objj_msgSend(_16,"absoluteString");
if(_18!==_relative){
return objj_msgSend(objj_msgSend(CPURL,"alloc"),"initWithString:",_18);
}
return _16;
}
}),new objj_method(sel_getUid("absoluteString"),function(_19,_1a){
with(_19){
return _1b(objj_msgSend(_base,"absoluteString")||"",_relative);
}
}),new objj_method(sel_getUid("relativeString"),function(_1c,_1d){
with(_1c){
return _relative;
}
}),new objj_method(sel_getUid("path"),function(_1e,_1f){
with(_1e){
var str=objj_msgSend(_1e,"absoluteString");
return _15.test(str)?(_20(str).path||nil):nil;
}
}),new objj_method(sel_getUid("relativePath"),function(_21,_22){
with(_21){
return _15.test(_relative)?(_20(_relative).path||nil):nil;
}
}),new objj_method(sel_getUid("scheme"),function(_23,_24){
with(_23){
var str=objj_msgSend(_23,"absoluteString");
return _15.test(str)?(_20(str).protocol||nil):nil;
}
}),new objj_method(sel_getUid("user"),function(_25,_26){
with(_25){
var str=objj_msgSend(_25,"absoluteString");
return _15.test(str)?(_20(str).user||nil):nil;
}
}),new objj_method(sel_getUid("password"),function(_27,_28){
with(_27){
var str=objj_msgSend(_27,"absoluteString");
return _15.test(str)?(_20(str).password||nil):nil;
}
}),new objj_method(sel_getUid("host"),function(_29,_2a){
with(_29){
var str=objj_msgSend(_29,"absoluteString");
return _15.test(str)?(_20(str).domain||nil):nil;
}
}),new objj_method(sel_getUid("port"),function(_2b,_2c){
with(_2b){
var str=objj_msgSend(_2b,"absoluteString");
if(_15.test(str)){
var _2d=_20(str).port;
if(_2d){
return parseInt(_2d,10);
}
}
return nil;
}
}),new objj_method(sel_getUid("parameterString"),function(_2e,_2f){
with(_2e){
var str=objj_msgSend(_2e,"absoluteString");
return _15.test(str)?(_20(str).query||nil):nil;
}
}),new objj_method(sel_getUid("fragment"),function(_30,_31){
with(_30){
var str=objj_msgSend(_30,"absoluteString");
return _15.test(str)?(_20(str).anchor||nil):nil;
}
}),new objj_method(sel_getUid("isEqual:"),function(_32,_33,_34){
with(_32){
return objj_msgSend(_32,"relativeString")===objj_msgSend(_34,"relativeString")&&(objj_msgSend(_32,"baseURL")===objj_msgSend(_34,"baseURL")||objj_msgSend(objj_msgSend(_32,"baseURL"),"isEqual:",objj_msgSend(_34,"baseURL")));
}
}),new objj_method(sel_getUid("lastPathComponent"),function(_35,_36){
with(_35){
var _37=objj_msgSend(_35,"path");
return _37?_37.split("/").pop():nil;
}
}),new objj_method(sel_getUid("pathExtension"),function(_38,_39){
with(_38){
var _3a=objj_msgSend(_38,"path"),ext=_3a.match(/\.(\w+)$/);
return ext?ext[1]:"";
}
}),new objj_method(sel_getUid("standardizedURL"),function(_3b,_3c){
with(_3b){
return objj_msgSend(CPURL,"URLWithString:relativeToURL:",_3d(_20(_relative)),_base);
}
}),new objj_method(sel_getUid("isFileURL"),function(_3e,_3f){
with(_3e){
return objj_msgSend(_3e,"scheme")==="file";
}
}),new objj_method(sel_getUid("description"),function(_40,_41){
with(_40){
return objj_msgSend(_40,"absoluteString");
}
}),new objj_method(sel_getUid("resourceValueForKey:"),function(_42,_43,_44){
with(_42){
return objj_msgSend(_resourceValues,"objectForKey:",_44);
}
}),new objj_method(sel_getUid("setResourceValue:forKey:"),function(_45,_46,_47,_48){
with(_45){
objj_msgSend(_resourceValues,"setObject:forKey:",_47,_48);
}
}),new objj_method(sel_getUid("staticResourceData"),function(_49,_4a){
with(_49){
return CFBundle.dataContentsAtPath(objj_msgSend(_49,"path"));
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("URLWithString:"),function(_4b,_4c,_4d){
with(_4b){
return objj_msgSend(objj_msgSend(_4b,"alloc"),"initWithString:",_4d);
}
}),new objj_method(sel_getUid("URLWithString:relativeToURL:"),function(_4e,_4f,_50,_51){
with(_4e){
return objj_msgSend(objj_msgSend(_4e,"alloc"),"initWithString:relativeToURL:",_50,_51);
}
})]);
var _1=objj_getClass("CPURL");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPURL\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_52,_53,_54){
with(_52){
_base=objj_msgSend(_54,"decodeObjectForKey:","CPURLBaseKey");
_relative=objj_msgSend(_54,"decodeObjectForKey:","CPURLRelativeKey");
return _52;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_55,_56,_57){
with(_55){
objj_msgSend(_57,"encodeObject:forKey:",_base,"CPURLBaseKey");
objj_msgSend(_57,"encodeObject:forKey:",_relative,"CPURLRelativeKey");
}
})]);
var _15=/^(?:([^:\/?\#]+):)?(?:\/\/([^\/?\#]*))?([^?\#]*)(?:\?([^\#]*))?(?:\#(.*))?/;
var _d=function(str){
if(!str){
str="";
}
var _58=str.match(_15);
this.scheme=_58[1]||null;
this.authority=_58[2]||null;
this.path=_58[3]||null;
this.query=_58[4]||null;
this.fragment=_58[5]||null;
};
_d.prototype.toString=function(){
var str="";
if(this.scheme){
str+=this.scheme+":";
}
if(this.authority){
str+="//"+this.authority;
}
if(this.path){
str+=this.path;
}
if(this.query){
str+="?"+this.query;
}
if(this.fragment){
str+="#"+this.fragment;
}
return str;
};
var _20=function(uri){
return new _d(uri);
};
var _59=function(str,_5a){
return decodeURI(str).replace(/\+/g," ");
};
var _5b=function(str,_5c){
return decodeURIComponent(str).replace(/\+/g," ");
};
var _5d=["url","protocol","authorityRoot","authority","userInfo","user","password","domain","domains","port","path","root","directory","directories","file","query","anchor"];
var _5e=["url","protocol","authorityRoot","authority","userInfo","user","password","domain","port","path","root","directory","file","query","anchor"];
var _5f=new RegExp("^"+"(?:"+"([^:/?#]+):"+")?"+"(?:"+"(//)"+"("+"(?:"+"("+"([^:@]*)"+":?"+"([^:@]*)"+")?"+"@"+")?"+"([^:/?#]*)"+"(?::(\\d*))?"+")"+")?"+"("+"(/?)"+"((?:[^?#/]*/)*)"+"([^?#]*)"+")"+"(?:\\?([^#]*))?"+"(?:#(.*))?");
var _60=function(_61){
return function(url){
if(typeof url=="undefined"){
throw new Error("HttpError: URL is undefined");
}
if(typeof url!="string"){
return new Object(url);
}
var _62={};
var _63=_61.exec(url);
for(var i=0;i<_63.length;i++){
_62[_5e[i]]=_63[i]?_63[i]:"";
}
_62.root=(_62.root||_62.authorityRoot)?"/":"";
_62.directories=_62.directory.split("/");
if(_62.directories[_62.directories.length-1]==""){
_62.directories.pop();
}
var _64=[];
for(var i=0;i<_62.directories.length;i++){
var _65=_62.directories[i];
if(_65=="."){
}else{
if(_65==".."){
if(_64.length&&_64[_64.length-1]!=".."){
_64.pop();
}else{
_64.push("..");
}
}else{
_64.push(_65);
}
}
}
_62.directories=_64;
_62.domains=_62.domain.split(".");
return _62;
};
};
var _20=_60(_5f);
var _3d=function(_66){
if(typeof (_66)=="undefined"){
throw new Error("UrlError: URL undefined for urls#format");
}
if(_66 instanceof String||typeof (_66)=="string"){
return _66;
}
var _67=_66.domains?_66.domains.join("."):_66.domain;
var _68=(_66.user||_66.password)?((_66.user||"")+(_66.password?":"+_66.password:"")):_66.userInfo;
var _69=(_68||_67||_66.port)?((_68?_68+"@":"")+(_67||"")+(_66.port?":"+_66.port:"")):_66.authority;
var _6a=_66.directories?_66.directories.join("/"):_66.directory;
var _6b=_6a||_66.file?((_6a?_6a+"/":"")+(_66.file||"")):_66.path;
return ((_66.protocol?_66.protocol+":":"")+(_69?"//"+_69:"")+(_66.root||(_69&&_6b)?"/":"")+(_6b?_6b:"")+(_66.query?"?"+_66.query:"")+(_66.anchor?"#"+_66.anchor:""))||_66.url||"";
};
var _6c=function(_6d,_6e){
if(!_6d){
return _6e;
}
_6d=_20(_6d);
_6e=_20(_6e);
if(_6e.url==""){
return _6d;
}
delete _6d.url;
delete _6d.authority;
delete _6d.domain;
delete _6d.userInfo;
delete _6d.path;
delete _6d.directory;
if(_6e.protocol&&_6e.protocol!=_6d.protocol||_6e.authority&&_6e.authority!=_6d.authority){
_6d=_6e;
}else{
if(_6e.root){
_6d.directories=_6e.directories;
}else{
var _6f=_6e.directories;
for(var i=0;i<_6f.length;i++){
var _70=_6f[i];
if(_70=="."){
}else{
if(_70==".."){
if(_6d.directories.length){
_6d.directories.pop();
}else{
_6d.directories.push("..");
}
}else{
_6d.directories.push(_70);
}
}
}
if(_6e.file=="."){
_6e.file="";
}else{
if(_6e.file==".."){
_6d.directories.pop();
_6e.file="";
}
}
}
}
if(_6e.root){
_6d.root=_6e.root;
}
if(_6e.protcol){
_6d.protocol=_6e.protocol;
}
if(!(!_6e.path&&_6e.anchor)){
_6d.file=_6e.file;
}
_6d.query=_6e.query;
_6d.anchor=_6e.anchor;
return _6d;
};
var _71=function(_72,_73){
_73=_20(_73);
_72=_20(_72);
delete _73.url;
if(_73.protocol==_72.protocol&&_73.authority==_72.authority){
delete _73.protocol;
delete _73.authority;
delete _73.userInfo;
delete _73.user;
delete _73.password;
delete _73.domain;
delete _73.domains;
delete _73.port;
if(!!_73.root==!!_72.root&&!(_73.root&&_73.directories[0]!=_72.directories[0])){
delete _73.path;
delete _73.root;
delete _73.directory;
while(_72.directories.length&&_73.directories.length&&_73.directories[0]==_72.directories[0]){
_73.directories.shift();
_72.directories.shift();
}
while(_72.directories.length){
_72.directories.shift();
_73.directories.unshift("..");
}
if(!_73.root&&!_73.directories.length&&!_73.file&&_72.file){
_73.directories.push(".");
}
if(_72.file==_73.file){
delete _73.file;
}
if(_72.query==_73.query){
delete _73.query;
}
if(_72.anchor==_73.anchor){
delete _73.anchor;
}
}
}
return _73;
};
var _1b=function(_74,_75){
return _3d(_6c(_74,_75));
};
var _76=function(_77,_78){
return _3d(_71(_77,_78));
};
p;17;CPURLConnection.jt;5422;@STATIC;1.0;i;10;CPObject.ji;11;CPRunLoop.ji;14;CPURLRequest.ji;15;CPURLResponse.jt;5333;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPRunLoop.j",true);
objj_executeFile("CPURLRequest.j",true);
objj_executeFile("CPURLResponse.j",true);
var _1=nil;
var _2=objj_allocateClassPair(CPObject,"CPURLConnection"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_request"),new objj_ivar("_delegate"),new objj_ivar("_isCanceled"),new objj_ivar("_isLocalFileConnection"),new objj_ivar("_HTTPRequest")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("initWithRequest:delegate:startImmediately:"),function(_4,_5,_6,_7,_8){
with(_4){
_4=objj_msgSendSuper({receiver:_4,super_class:objj_getClass("CPURLConnection").super_class},"init");
if(_4){
_request=_6;
_delegate=_7;
_isCanceled=NO;
var _9=objj_msgSend(_request,"URL"),_a=objj_msgSend(_9,"scheme");
_isLocalFileConnection=_a==="file"||((_a==="http"||_a==="https:")&&window.location&&(window.location.protocol==="file:"||window.location.protocol==="app:"));
_HTTPRequest=new CFHTTPRequest();
if(_8){
objj_msgSend(_4,"start");
}
}
return _4;
}
}),new objj_method(sel_getUid("initWithRequest:delegate:"),function(_b,_c,_d,_e){
with(_b){
return objj_msgSend(_b,"initWithRequest:delegate:startImmediately:",_d,_e,YES);
}
}),new objj_method(sel_getUid("delegate"),function(_f,_10){
with(_f){
return _delegate;
}
}),new objj_method(sel_getUid("start"),function(_11,_12){
with(_11){
_isCanceled=NO;
try{
_HTTPRequest.open(objj_msgSend(_request,"HTTPMethod"),objj_msgSend(objj_msgSend(_request,"URL"),"absoluteString"),YES);
_HTTPRequest.onreadystatechange=function(){
objj_msgSend(_11,"_readyStateDidChange");
};
var _13=objj_msgSend(_request,"allHTTPHeaderFields"),key=nil,_14=objj_msgSend(_13,"keyEnumerator");
while(key=objj_msgSend(_14,"nextObject")){
_HTTPRequest.setRequestHeader(key,objj_msgSend(_13,"objectForKey:",key));
}
_HTTPRequest.send(objj_msgSend(_request,"HTTPBody"));
}
catch(anException){
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("connection:didFailWithError:"))){
objj_msgSend(_delegate,"connection:didFailWithError:",_11,anException);
}
}
}
}),new objj_method(sel_getUid("cancel"),function(_15,_16){
with(_15){
_isCanceled=YES;
try{
_HTTPRequest.abort();
}
catch(anException){
}
}
}),new objj_method(sel_getUid("isLocalFileConnection"),function(_17,_18){
with(_17){
return _isLocalFileConnection;
}
}),new objj_method(sel_getUid("_readyStateDidChange"),function(_19,_1a){
with(_19){
if(_HTTPRequest.readyState()===CFHTTPRequest.CompleteState){
var _1b=_HTTPRequest.status(),URL=objj_msgSend(_request,"URL");
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("connection:didReceiveResponse:"))){
if(_isLocalFileConnection){
objj_msgSend(_delegate,"connection:didReceiveResponse:",_19,objj_msgSend(objj_msgSend(CPURLResponse,"alloc"),"initWithURL:",URL));
}else{
var _1c=objj_msgSend(objj_msgSend(CPHTTPURLResponse,"alloc"),"initWithURL:",URL);
objj_msgSend(_1c,"_setStatusCode:",_1b);
objj_msgSend(_delegate,"connection:didReceiveResponse:",_19,_1c);
}
}
if(!_isCanceled){
if(_1b===401&&objj_msgSend(_1,"respondsToSelector:",sel_getUid("connectionDidReceiveAuthenticationChallenge:"))){
objj_msgSend(_1,"connectionDidReceiveAuthenticationChallenge:",_19);
}else{
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("connection:didReceiveData:"))){
objj_msgSend(_delegate,"connection:didReceiveData:",_19,_HTTPRequest.responseText());
}
if(objj_msgSend(_delegate,"respondsToSelector:",sel_getUid("connectionDidFinishLoading:"))){
objj_msgSend(_delegate,"connectionDidFinishLoading:",_19);
}
}
}
}
objj_msgSend(objj_msgSend(CPRunLoop,"currentRunLoop"),"limitDateForMode:",CPDefaultRunLoopMode);
}
}),new objj_method(sel_getUid("_HTTPRequest"),function(_1d,_1e){
with(_1d){
return _HTTPRequest;
}
})]);
class_addMethods(_3,[new objj_method(sel_getUid("setClassDelegate:"),function(_1f,_20,_21){
with(_1f){
_1=_21;
}
}),new objj_method(sel_getUid("sendSynchronousRequest:returningResponse:"),function(_22,_23,_24,_25){
with(_22){
try{
var _26=new CFHTTPRequest();
_26.open(objj_msgSend(_24,"HTTPMethod"),objj_msgSend(objj_msgSend(_24,"URL"),"absoluteString"),NO);
var _27=objj_msgSend(_24,"allHTTPHeaderFields"),key=nil,_28=objj_msgSend(_27,"keyEnumerator");
while(key=objj_msgSend(_28,"nextObject")){
_26.setRequestHeader(key,objj_msgSend(_27,"objectForKey:",key));
}
_26.send(objj_msgSend(_24,"HTTPBody"));
return objj_msgSend(CPData,"dataWithEncodedString:",_26.responseText());
}
catch(anException){
}
return nil;
}
}),new objj_method(sel_getUid("connectionWithRequest:delegate:"),function(_29,_2a,_2b,_2c){
with(_29){
return objj_msgSend(objj_msgSend(_29,"alloc"),"initWithRequest:delegate:",_2b,_2c);
}
})]);
var _2=objj_getClass("CPURLConnection");
if(!_2){
throw new SyntaxError("*** Could not find definition for class \"CPURLConnection\"");
}
var _3=_2.isa;
class_addMethods(_2,[new objj_method(sel_getUid("_XMLHTTPRequest"),function(_2d,_2e){
with(_2d){
_CPReportLenientDeprecation(_2d,_2e,sel_getUid("_HTTPRequest"));
return objj_msgSend(_2d,"_HTTPRequest");
}
})]);
class_addMethods(_3,[new objj_method(sel_getUid("sendSynchronousRequest:returningResponse:error:"),function(_2f,_30,_31,_32,_33){
with(_2f){
_CPReportLenientDeprecation(_2f,_30,sel_getUid("sendSynchronousRequest:returningResponse:"));
return objj_msgSend(_2f,"sendSynchronousRequest:returningResponse:",_31,_32);
}
})]);
p;14;CPURLRequest.jt;2188;@STATIC;1.0;i;10;CPObject.jt;2154;
objj_executeFile("CPObject.j",true);
var _1=objj_allocateClassPair(CPObject,"CPURLRequest"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_URL"),new objj_ivar("_HTTPBody"),new objj_ivar("_HTTPMethod"),new objj_ivar("_HTTPHeaderFields")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithURL:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPURLRequest").super_class},"init");
if(_3){
objj_msgSend(_3,"setURL:",_5);
_HTTPBody="";
_HTTPMethod="GET";
_HTTPHeaderFields=objj_msgSend(CPDictionary,"dictionary");
objj_msgSend(_3,"setValue:forHTTPHeaderField:","Thu, 1 Jan 1970 00:00:00 GMT","If-Modified-Since");
objj_msgSend(_3,"setValue:forHTTPHeaderField:","no-cache","Cache-Control");
objj_msgSend(_3,"setValue:forHTTPHeaderField:","XMLHttpRequest","X-Requested-With");
}
return _3;
}
}),new objj_method(sel_getUid("URL"),function(_6,_7){
with(_6){
return _URL;
}
}),new objj_method(sel_getUid("setURL:"),function(_8,_9,_a){
with(_8){
if(objj_msgSend(_a,"isKindOfClass:",objj_msgSend(CPURL,"class"))){
_URL=_a;
}else{
_URL=objj_msgSend(CPURL,"URLWithString:",String(_a));
}
}
}),new objj_method(sel_getUid("setHTTPBody:"),function(_b,_c,_d){
with(_b){
_HTTPBody=_d;
}
}),new objj_method(sel_getUid("HTTPBody"),function(_e,_f){
with(_e){
return _HTTPBody;
}
}),new objj_method(sel_getUid("setHTTPMethod:"),function(_10,_11,_12){
with(_10){
_HTTPMethod=_12;
}
}),new objj_method(sel_getUid("HTTPMethod"),function(_13,_14){
with(_13){
return _HTTPMethod;
}
}),new objj_method(sel_getUid("allHTTPHeaderFields"),function(_15,_16){
with(_15){
return _HTTPHeaderFields;
}
}),new objj_method(sel_getUid("valueForHTTPHeaderField:"),function(_17,_18,_19){
with(_17){
return objj_msgSend(_HTTPHeaderFields,"objectForKey:",_19);
}
}),new objj_method(sel_getUid("setValue:forHTTPHeaderField:"),function(_1a,_1b,_1c,_1d){
with(_1a){
objj_msgSend(_HTTPHeaderFields,"setObject:forKey:",_1c,_1d);
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("requestWithURL:"),function(_1e,_1f,_20){
with(_1e){
return objj_msgSend(objj_msgSend(CPURLRequest,"alloc"),"initWithURL:",_20);
}
})]);
p;15;CPURLResponse.jt;889;@STATIC;1.0;i;10;CPObject.jt;856;
objj_executeFile("CPObject.j",true);
var _1=objj_allocateClassPair(CPObject,"CPURLResponse"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_URL")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithURL:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPURLResponse").super_class},"init");
if(_3){
_URL=_5;
}
return _3;
}
}),new objj_method(sel_getUid("URL"),function(_6,_7){
with(_6){
return _URL;
}
})]);
var _1=objj_allocateClassPair(CPURLResponse,"CPHTTPURLResponse"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_statusCode")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("_setStatusCode:"),function(_8,_9,_a){
with(_8){
_statusCode=_a;
}
}),new objj_method(sel_getUid("statusCode"),function(_b,_c){
with(_b){
return _statusCode;
}
})]);
p;22;CPUserSessionManager.jt;1960;@STATIC;1.0;I;21;Foundation/CPObject.jI;21;Foundation/CPString.jt;1889;
objj_executeFile("Foundation/CPObject.j",false);
objj_executeFile("Foundation/CPString.j",false);
CPUserSessionUndeterminedStatus=0;
CPUserSessionLoggedInStatus=1;
CPUserSessionLoggedOutStatus=2;
CPUserSessionManagerStatusDidChangeNotification="CPUserSessionManagerStatusDidChangeNotification";
CPUserSessionManagerUserIdentifierDidChangeNotification="CPUserSessionManagerUserIdentifierDidChangeNotification";
var _1=nil;
var _2=objj_allocateClassPair(CPObject,"CPUserSessionManager"),_3=_2.isa;
class_addIvars(_2,[new objj_ivar("_status"),new objj_ivar("_userIdentifier")]);
objj_registerClassPair(_2);
class_addMethods(_2,[new objj_method(sel_getUid("init"),function(_4,_5){
with(_4){
_4=objj_msgSendSuper({receiver:_4,super_class:objj_getClass("CPUserSessionManager").super_class},"init");
if(_4){
_status=CPUserSessionUndeterminedStatus;
}
return _4;
}
}),new objj_method(sel_getUid("status"),function(_6,_7){
with(_6){
return _status;
}
}),new objj_method(sel_getUid("setStatus:"),function(_8,_9,_a){
with(_8){
if(_status==_a){
return;
}
_status=_a;
objj_msgSend(objj_msgSend(CPNotificationCenter,"defaultCenter"),"postNotificationName:object:",CPUserSessionManagerStatusDidChangeNotification,_8);
if(_status!=CPUserSessionLoggedInStatus){
objj_msgSend(_8,"setUserIdentifier:",nil);
}
}
}),new objj_method(sel_getUid("userIdentifier"),function(_b,_c){
with(_b){
return _userIdentifier;
}
}),new objj_method(sel_getUid("setUserIdentifier:"),function(_d,_e,_f){
with(_d){
if(_userIdentifier==_f){
return;
}
_userIdentifier=_f;
objj_msgSend(objj_msgSend(CPNotificationCenter,"defaultCenter"),"postNotificationName:object:",CPUserSessionManagerUserIdentifierDidChangeNotification,_d);
}
})]);
class_addMethods(_3,[new objj_method(sel_getUid("defaultManager"),function(_10,_11){
with(_10){
if(!_1){
_1=objj_msgSend(objj_msgSend(CPUserSessionManager,"alloc"),"init");
}
return _1;
}
})]);
p;9;CPValue.jt;1692;@STATIC;1.0;i;10;CPObject.ji;9;CPCoder.jt;1645;
objj_executeFile("CPObject.j",true);
objj_executeFile("CPCoder.j",true);
var _1=objj_allocateClassPair(CPObject,"CPValue"),_2=_1.isa;
class_addIvars(_1,[new objj_ivar("_JSObject")]);
objj_registerClassPair(_1);
class_addMethods(_1,[new objj_method(sel_getUid("initWithJSObject:"),function(_3,_4,_5){
with(_3){
_3=objj_msgSendSuper({receiver:_3,super_class:objj_getClass("CPValue").super_class},"init");
if(_3){
_JSObject=_5;
}
return _3;
}
}),new objj_method(sel_getUid("JSObject"),function(_6,_7){
with(_6){
return _JSObject;
}
})]);
class_addMethods(_2,[new objj_method(sel_getUid("valueWithJSObject:"),function(_8,_9,_a){
with(_8){
return objj_msgSend(objj_msgSend(_8,"alloc"),"initWithJSObject:",_a);
}
})]);
var _b="CPValueValueKey";
var _1=objj_getClass("CPValue");
if(!_1){
throw new SyntaxError("*** Could not find definition for class \"CPValue\"");
}
var _2=_1.isa;
class_addMethods(_1,[new objj_method(sel_getUid("initWithCoder:"),function(_c,_d,_e){
with(_c){
_c=objj_msgSendSuper({receiver:_c,super_class:objj_getClass("CPValue").super_class},"init");
if(_c){
_JSObject=JSON.parse(objj_msgSend(_e,"decodeObjectForKey:",_b));
}
return _c;
}
}),new objj_method(sel_getUid("encodeWithCoder:"),function(_f,_10,_11){
with(_f){
objj_msgSend(_11,"encodeObject:forKey:",JSON.stringify(_JSObject),_b);
}
})]);
CPJSObjectCreateJSON=function(_12){
CPLog.warn("CPJSObjectCreateJSON deprecated, use JSON.stringify() or CPString's objectFromJSON");
return JSON.stringify(_12);
};
CPJSObjectCreateWithJSON=function(_13){
CPLog.warn("CPJSObjectCreateWithJSON deprecated, use JSON.parse() or CPString's JSONFromObject");
return JSON.parse(_13);
};
p;17;CPWebDAVManager.jt;4329;@STATIC;1.0;t;4310;
var _1=function(_2,_3,_4){
var _5=objj_msgSend(_4,"objectForKey:","resourcetype");
if(_5===CPWebDAVManagerCollectionResourceType){
objj_msgSend(_2,"setResourceValue:forKey:",YES,CPURLIsDirectoryKey);
objj_msgSend(_2,"setResourceValue:forKey:",NO,CPURLIsRegularFileKey);
}else{
if(_5===CPWebDAVManagerNonCollectionResourceType){
objj_msgSend(_2,"setResourceValue:forKey:",NO,CPURLIsDirectoryKey);
objj_msgSend(_2,"setResourceValue:forKey:",YES,CPURLIsRegularFileKey);
}
}
var _6=objj_msgSend(_4,"objectForKey:","displayname");
if(_6!==nil){
objj_msgSend(_2,"setResourceValue:forKey:",_6,CPURLNameKey);
objj_msgSend(_2,"setResourceValue:forKey:",_6,CPURLLocalizedNameKey);
}
};
CPWebDAVManagerCollectionResourceType=1;
CPWebDAVManagerNonCollectionResourceType=0;
var _7=objj_allocateClassPair(CPObject,"CPWebDAVManager"),_8=_7.isa;
class_addIvars(_7,[new objj_ivar("_blocksForConnections")]);
objj_registerClassPair(_7);
class_addMethods(_7,[new objj_method(sel_getUid("init"),function(_9,_a){
with(_9){
_9=objj_msgSendSuper({receiver:_9,super_class:objj_getClass("CPWebDAVManager").super_class},"init");
if(_9){
_blocksForConnections=objj_msgSend(CPDictionary,"dictionary");
}
return _9;
}
}),new objj_method(sel_getUid("contentsOfDirectoryAtURL:includingPropertiesForKeys:options:block:"),function(_b,_c,_d,_e,_f,_10){
with(_b){
var _11=[],_12=objj_msgSend(_e,"count");
while(_12--){
_11.push(_13[_e[_12]]);
}
var _14=function(_15,_16){
var _17=[],_18=nil,_19=objj_msgSend(_16,"keyEnumerator");
while(_18=objj_msgSend(_19,"nextObject")){
var URL=objj_msgSend(CPURL,"URLWithString:",_18),_11=objj_msgSend(_16,"objectForKey:",_18);
if(!objj_msgSend(objj_msgSend(URL,"absoluteString"),"isEqual:",objj_msgSend(_15,"absoluteString"))){
_17.push(URL);
_1(URL,_e,_11);
}
}
return _17;
};
if(!_10){
return _14(_d,response);
}
objj_msgSend(_b,"PROPFIND:properties:depth:block:",_d,_11,1,function(_1a,_1b){
_10(_1a,_14(_1a,_1b));
});
}
}),new objj_method(sel_getUid("PROPFIND:properties:depth:block:"),function(_1c,_1d,_1e,_1f,_20,_21){
with(_1c){
var _22=objj_msgSend(CPURLRequest,"requestWithURL:",_1e);
objj_msgSend(_22,"setHTTPMethod:","PROPFIND");
objj_msgSend(_22,"setValue:forHTTPHeaderField:",_20,"Depth");
var _23=["<?xml version=\"1.0\"?><a:propfind xmlns:a=\"DAV:\">"],_24=0,_25=_1f.length;
for(;_24<_25;++_24){
_23.push("<a:prop><a:",_1f[_24],"/></a:prop>");
}
_23.push("</a:propfind>");
objj_msgSend(_22,"setHTTPBody:",_23.join(""));
if(!_21){
return _26(objj_msgSend(objj_msgSend(CPURLConnection,"sendSynchronousRequest:returningResponse:error:",_22,nil,nil),"encodedString"));
}else{
var _27=objj_msgSend(CPURLConnection,"connectionWithRequest:delegate:",_22,_1c);
objj_msgSend(_blocksForConnections,"setObject:forKey:",_21,objj_msgSend(_27,"UID"));
}
}
}),new objj_method(sel_getUid("connection:didReceiveData:"),function(_28,_29,_2a,_2b){
with(_28){
var _2c=objj_msgSend(_blocksForConnections,"objectForKey:",objj_msgSend(_2a,"UID"));
_2c(objj_msgSend(_2a._request,"URL"),_26(_2b));
}
})]);
var _13={};
_13[CPURLNameKey]="displayname";
_13[CPURLLocalizedNameKey]="displayname";
_13[CPURLIsRegularFileKey]="resourcetype";
_13[CPURLIsDirectoryKey]="resourcetype";
var _2d=function(_2e){
if(typeof window["ActiveXObject"]!=="undefined"){
var _2f=new ActiveXObject("Microsoft.XMLDOM");
_2f.async=false;
_2f.loadXML(_2e);
return _2f;
}
return new DOMParser().parseFromString(_2e,"text/xml");
};
var _26=function(_30){
var _31=_2d(_30),_32=_31.getElementsByTagNameNS("*","response"),_33=0,_34=_32.length;
var _35=objj_msgSend(CPDictionary,"dictionary");
for(;_33<_34;++_33){
var _36=_32[_33],_37=_36.getElementsByTagNameNS("*","prop").item(0).childNodes,_38=0,_39=_37.length,_3a=objj_msgSend(CPDictionary,"dictionary");
for(;_38<_39;++_38){
var _3b=_37[_38];
if(_3b.nodeType===8||_3b.nodeType===3){
continue;
}
var _3c=_3b.nodeName,_3d=_3c.lastIndexOf(":");
if(_3d>-1){
_3c=_3c.substr(_3d+1);
}
if(_3c==="resourcetype"){
objj_msgSend(_3a,"setObject:forKey:",_3b.firstChild?CPWebDAVManagerCollectionResourceType:CPWebDAVManagerNonCollectionResourceType,_3c);
}else{
objj_msgSend(_3a,"setObject:forKey:",_3b.firstChild.nodeValue,_3c);
}
}
var _3e=_36.getElementsByTagNameNS("*","href").item(0);
objj_msgSend(_35,"setObject:forKey:",_3a,_3e.firstChild.nodeValue);
}
return _35;
};
var _3f=function(_40,_41){
};
p;12;Foundation.jt;2257;@STATIC;1.0;i;9;CPArray.ji;10;CPBundle.ji;9;CPCoder.ji;8;CPData.ji;8;CPDate.ji;14;CPDictionary.ji;14;CPEnumerator.ji;13;CPException.ji;12;CPIndexSet.ji;14;CPInvocation.ji;19;CPJSONPConnection.ji;17;CPKeyedArchiver.ji;19;CPKeyedUnarchiver.ji;18;CPKeyValueCoding.ji;21;CPKeyValueObserving.ji;7;CPLog.ji;16;CPNotification.ji;22;CPNotificationCenter.ji;8;CPNull.ji;10;CPNumber.ji;10;CPObject.ji;15;CPObjJRuntime.ji;13;CPOperation.ji;18;CPOperationQueue.ji;29;CPPropertyListSerialization.ji;9;CPRange.ji;11;CPRunLoop.ji;7;CPSet.ji;18;CPSortDescriptor.ji;10;CPString.ji;9;CPTimer.ji;15;CPUndoManager.ji;7;CPURL.ji;17;CPURLConnection.ji;14;CPURLRequest.ji;15;CPURLResponse.ji;22;CPUserSessionManager.ji;9;CPValue.jt;1543;
objj_executeFile("CPArray.j",true);
objj_executeFile("CPBundle.j",true);
objj_executeFile("CPCoder.j",true);
objj_executeFile("CPData.j",true);
objj_executeFile("CPDate.j",true);
objj_executeFile("CPDictionary.j",true);
objj_executeFile("CPEnumerator.j",true);
objj_executeFile("CPException.j",true);
objj_executeFile("CPIndexSet.j",true);
objj_executeFile("CPInvocation.j",true);
objj_executeFile("CPJSONPConnection.j",true);
objj_executeFile("CPKeyedArchiver.j",true);
objj_executeFile("CPKeyedUnarchiver.j",true);
objj_executeFile("CPKeyValueCoding.j",true);
objj_executeFile("CPKeyValueObserving.j",true);
objj_executeFile("CPLog.j",true);
objj_executeFile("CPNotification.j",true);
objj_executeFile("CPNotificationCenter.j",true);
objj_executeFile("CPNull.j",true);
objj_executeFile("CPNumber.j",true);
objj_executeFile("CPObject.j",true);
objj_executeFile("CPObjJRuntime.j",true);
objj_executeFile("CPOperation.j",true);
objj_executeFile("CPOperationQueue.j",true);
objj_executeFile("CPPropertyListSerialization.j",true);
objj_executeFile("CPRange.j",true);
objj_executeFile("CPRunLoop.j",true);
objj_executeFile("CPSet.j",true);
objj_executeFile("CPSortDescriptor.j",true);
objj_executeFile("CPString.j",true);
objj_executeFile("CPTimer.j",true);
objj_executeFile("CPUndoManager.j",true);
objj_executeFile("CPURL.j",true);
objj_executeFile("CPURLConnection.j",true);
objj_executeFile("CPURLRequest.j",true);
objj_executeFile("CPURLResponse.j",true);
objj_executeFile("CPUserSessionManager.j",true);
objj_executeFile("CPValue.j",true);
e;