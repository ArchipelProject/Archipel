@STATIC;1.0;I;23;Foundation/Foundation.jI;15;AppKit/AppKit.ji;16;../../TNModule.jt;680;objj_executeFile("Foundation/Foundation.j", false);
objj_executeFile("AppKit/AppKit.j", false);
objj_executeFile("../../TNModule.j", true);;
{var the_class = objj_allocateClassPair(TNModule, "TNSampleModule"),
meta_class = the_class.isa;objj_registerClassPair(the_class);
class_addMethods(the_class, [new objj_method(sel_getUid("initializeWithContact:andRoster:"), function $TNSampleModule__initializeWithContact_andRoster_(self, _cmd, aContact, aRoster)
{ with(self)
{
    objj_msgSendSuper({ receiver:self, super_class:objj_getClass("TNSampleModule").super_class }, "initializeWithContact:andRoster:", aContact, aRoster)
}
},["void","TNStropheContact","TNStropheRoster"])]);
}

