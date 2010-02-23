@STATIC;1.0;I;23;Foundation/Foundation.jI;15;AppKit/AppKit.ji;16;../../TNModule.jt;13907;objj_executeFile("Foundation/Foundation.j", false);
objj_executeFile("AppKit/AppKit.j", false);
objj_executeFile("../../TNModule.j", true);;
trinityTypeHypervisorControl = "trinity:hypervisor:control";
trinityTypeHypervisorControlAlloc = "alloc";
trinityTypeHypervisorControlFree = "free";
trinityTypeHypervisorControlRosterVM = "rostervm";
trinityTypeHypervisorControlHealth = "healthinfo";
{var the_class = objj_allocateClassPair(TNModule, "TNMainViewController"),
meta_class = the_class.isa;class_addIvars(the_class, [new objj_ivar("jid"), new objj_ivar("mainTitle"), new objj_ivar("buttonCreateVM"), new objj_ivar("popupDeleteMachine"), new objj_ivar("buttonDeleteVM"), new objj_ivar("healthCPUUsage"), new objj_ivar("healthDiskUsage"), new objj_ivar("healthMemUsage"), new objj_ivar("healthLoad"), new objj_ivar("healthUptime"), new objj_ivar("healthInfo"), new objj_ivar("_timer")]);
objj_registerClassPair(the_class);
class_addMethods(the_class, [new objj_method(sel_getUid("jid"), function $TNMainViewController__jid(self, _cmd)
{ with(self)
{
return jid;
}
},["id"]),
new objj_method(sel_getUid("setJid:"), function $TNMainViewController__setJid_(self, _cmd, newValue)
{ with(self)
{
jid = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("mainTitle"), function $TNMainViewController__mainTitle(self, _cmd)
{ with(self)
{
return mainTitle;
}
},["id"]),
new objj_method(sel_getUid("setMainTitle:"), function $TNMainViewController__setMainTitle_(self, _cmd, newValue)
{ with(self)
{
mainTitle = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("buttonCreateVM"), function $TNMainViewController__buttonCreateVM(self, _cmd)
{ with(self)
{
return buttonCreateVM;
}
},["id"]),
new objj_method(sel_getUid("setButtonCreateVM:"), function $TNMainViewController__setButtonCreateVM_(self, _cmd, newValue)
{ with(self)
{
buttonCreateVM = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("popupDeleteMachine"), function $TNMainViewController__popupDeleteMachine(self, _cmd)
{ with(self)
{
return popupDeleteMachine;
}
},["id"]),
new objj_method(sel_getUid("setPopupDeleteMachine:"), function $TNMainViewController__setPopupDeleteMachine_(self, _cmd, newValue)
{ with(self)
{
popupDeleteMachine = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("buttonDeleteVM"), function $TNMainViewController__buttonDeleteVM(self, _cmd)
{ with(self)
{
return buttonDeleteVM;
}
},["id"]),
new objj_method(sel_getUid("setButtonDeleteVM:"), function $TNMainViewController__setButtonDeleteVM_(self, _cmd, newValue)
{ with(self)
{
buttonDeleteVM = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("healthCPUUsage"), function $TNMainViewController__healthCPUUsage(self, _cmd)
{ with(self)
{
return healthCPUUsage;
}
},["id"]),
new objj_method(sel_getUid("setHealthCPUUsage:"), function $TNMainViewController__setHealthCPUUsage_(self, _cmd, newValue)
{ with(self)
{
healthCPUUsage = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("healthDiskUsage"), function $TNMainViewController__healthDiskUsage(self, _cmd)
{ with(self)
{
return healthDiskUsage;
}
},["id"]),
new objj_method(sel_getUid("setHealthDiskUsage:"), function $TNMainViewController__setHealthDiskUsage_(self, _cmd, newValue)
{ with(self)
{
healthDiskUsage = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("healthMemUsage"), function $TNMainViewController__healthMemUsage(self, _cmd)
{ with(self)
{
return healthMemUsage;
}
},["id"]),
new objj_method(sel_getUid("setHealthMemUsage:"), function $TNMainViewController__setHealthMemUsage_(self, _cmd, newValue)
{ with(self)
{
healthMemUsage = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("healthLoad"), function $TNMainViewController__healthLoad(self, _cmd)
{ with(self)
{
return healthLoad;
}
},["id"]),
new objj_method(sel_getUid("setHealthLoad:"), function $TNMainViewController__setHealthLoad_(self, _cmd, newValue)
{ with(self)
{
healthLoad = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("healthUptime"), function $TNMainViewController__healthUptime(self, _cmd)
{ with(self)
{
return healthUptime;
}
},["id"]),
new objj_method(sel_getUid("setHealthUptime:"), function $TNMainViewController__setHealthUptime_(self, _cmd, newValue)
{ with(self)
{
healthUptime = newValue;
}
},["void","id"]),
new objj_method(sel_getUid("healthInfo"), function $TNMainViewController__healthInfo(self, _cmd)
{ with(self)
{
return healthInfo;
}
},["id"]),
new objj_method(sel_getUid("setHealthInfo:"), function $TNMainViewController__setHealthInfo_(self, _cmd, newValue)
{ with(self)
{
healthInfo = newValue;
}
},["void","id"]), new objj_method(sel_getUid("initializeWithContact:andRoster:"), function $TNMainViewController__initializeWithContact_andRoster_(self, _cmd, aContact, aRoster)
{ with(self)
{
    objj_msgSendSuper({ receiver:self, super_class:objj_getClass("TNMainViewController").super_class }, "initializeWithContact:andRoster:", aContact, aRoster)
    var center = objj_msgSend(CPNotificationCenter, "defaultCenter");
    objj_msgSend(center, "addObserver:selector:name:object:", self, sel_getUid("didNickNameUpdated:"), TNStropheContactNicknameUpdatedNotification, nil);
    if (_timer)
        objj_msgSend(_timer, "invalidate");
    objj_msgSend(objj_msgSend(self, "popupDeleteMachine"), "removeAllItems");
    objj_msgSend(objj_msgSend(self, "mainTitle"), "setStringValue:", objj_msgSend(objj_msgSend(self, "contact"), "nickname"));
    objj_msgSend(objj_msgSend(self, "jid"), "setStringValue:", objj_msgSend(objj_msgSend(self, "contact"), "jid"));
    objj_msgSend(self, "getHypervisorRoster");
    objj_msgSend(self, "getHypervisorHealth:", nil);
    _timer = objj_msgSend(CPTimer, "scheduledTimerWithTimeInterval:target:selector:userInfo:repeats:", 5, self, sel_getUid("getHypervisorHealth:"), nil, YES)
}
},["void","TNStropheContact","TNStropheRoster"]), new objj_method(sel_getUid("didNickNameUpdated:"), function $TNMainViewController__didNickNameUpdated_(self, _cmd, aNotification)
{ with(self)
{
    if (objj_msgSend(aNotification, "object") == objj_msgSend(self, "contact"))
    {
       objj_msgSend(objj_msgSend(self, "mainTitle"), "setStringValue:", objj_msgSend(objj_msgSend(self, "contact"), "nickname"))
    }
}
},["void","CPNotification"]), new objj_method(sel_getUid("getHypervisorRoster"), function $TNMainViewController__getHypervisorRoster(self, _cmd)
{ with(self)
{
    var uid = objj_msgSend(objj_msgSend(objj_msgSend(self, "contact"), "connection"), "getUniqueId");
    var rosterStanza = objj_msgSend(TNStropheStanza, "iqWithAttributes:", {"type" : trinityTypeHypervisorControlRosterVM, "to": objj_msgSend(objj_msgSend(self, "contact"), "fullJID"), "id": uid});
    var params;
    objj_msgSend(rosterStanza, "addChildName:withAttributes:", "query", {"xmlns" : trinityTypeHypervisorControl});
    params= objj_msgSend(CPDictionary, "dictionaryWithObjectsAndKeys:", uid, "id");
    objj_msgSend(objj_msgSend(objj_msgSend(self, "contact"), "connection"), "registerSelector:ofObject:withDict:", sel_getUid("didReceiveHypervisorRoster:"), self, params);
    objj_msgSend(objj_msgSend(objj_msgSend(self, "contact"), "connection"), "send:", objj_msgSend(rosterStanza, "stanza"));
}
},["void"]), new objj_method(sel_getUid("didReceiveHypervisorRoster:"), function $TNMainViewController__didReceiveHypervisorRoster_(self, _cmd, aStanza)
{ with(self)
{
    var queryItems = aStanza.getElementsByTagName("item");
    var i;
    objj_msgSend(objj_msgSend(self, "popupDeleteMachine"), "removeAllItems");
    for (i = 0; i < queryItems.length; i++)
    {
        var jid = $(queryItems[i]).text();
        var entry = objj_msgSend(objj_msgSend(self, "roster"), "getContactFromJID:", jid);
        if (entry)
        {
            if ($(objj_msgSend(entry, "vCard").firstChild).text() == "virtualmachine")
            {
                var name = objj_msgSend(entry, "nickname") + " (" + jid +")";
                var item = objj_msgSend(objj_msgSend(TNMenuItem, "alloc"), "initWithTitle:action:keyEquivalent:", name, nil, "")
                objj_msgSend(item, "setImage:", objj_msgSend(entry, "statusIcon"));
                objj_msgSend(item, "setStringValue:", jid);
                objj_msgSend(objj_msgSend(self, "popupDeleteMachine"), "addItem:", item);
            }
        }
    }
}
},["void","id"]), new objj_method(sel_getUid("getHypervisorHealth:"), function $TNMainViewController__getHypervisorHealth_(self, _cmd, aTimer)
{ with(self)
{
    if (!objj_msgSend(self, "superview"))
    {
        objj_msgSend(_timer, "invalidate");
        return;
    }
    var uid = objj_msgSend(objj_msgSend(objj_msgSend(self, "contact"), "connection"), "getUniqueId");
    var rosterStanza = objj_msgSend(TNStropheStanza, "iqWithAttributes:", {"type" : trinityTypeHypervisorControlHealth, "to": objj_msgSend(objj_msgSend(self, "contact"), "fullJID"), "id": uid});
    var params;
    objj_msgSend(rosterStanza, "addChildName:withAttributes:", "query", {"xmlns" : trinityTypeHypervisorControl});
    params= objj_msgSend(CPDictionary, "dictionaryWithObjectsAndKeys:", uid, "id");
    objj_msgSend(objj_msgSend(objj_msgSend(self, "contact"), "connection"), "registerSelector:ofObject:withDict:", sel_getUid("didReceiveHypervisorHealth:"), self, params);
    objj_msgSend(objj_msgSend(objj_msgSend(self, "contact"), "connection"), "send:", objj_msgSend(rosterStanza, "stanza"));
}
},["void","CPTimer"]), new objj_method(sel_getUid("didReceiveHypervisorHealth:"), function $TNMainViewController__didReceiveHypervisorHealth_(self, _cmd, aStanza)
{ with(self)
{
    if (aStanza.getAttribute("type") == "success")
    {
        var memNode = aStanza.getElementsByTagName("memory")[0];
        objj_msgSend(objj_msgSend(self, "healthMemUsage"), "setStringValue:", memNode.getAttribute("free") + "Mo / " + memNode.getAttribute("swapped") + "Mo");
        var diskNode = aStanza.getElementsByTagName("disk")[0];
        objj_msgSend(objj_msgSend(self, "healthDiskUsage"), "setStringValue:", diskNode.getAttribute("used-percentage"));
        var loadNode = aStanza.getElementsByTagName("load")[0];
        objj_msgSend(objj_msgSend(self, "healthLoad"), "setStringValue:", loadNode.getAttribute("five"));
        var uptimeNode = aStanza.getElementsByTagName("uptime")[0];
        objj_msgSend(objj_msgSend(self, "healthUptime"), "setStringValue:", uptimeNode.getAttribute("up"));
        var cpuNode = aStanza.getElementsByTagName("cpu")[0];
        var cpuFree = 100 - parseInt(cpuNode.getAttribute("id"));
        objj_msgSend(objj_msgSend(self, "healthCPUUsage"), "setStringValue:", cpuFree + "%");
        var infoNode = aStanza.getElementsByTagName("uname")[0];
        objj_msgSend(objj_msgSend(self, "healthInfo"), "setStringValue:", infoNode.getAttribute("os") + " " + infoNode.getAttribute("kname"));
    }
}
},["void","id"]), new objj_method(sel_getUid("addVirtualMachine:"), function $TNMainViewController__addVirtualMachine_(self, _cmd, sender)
{ with(self)
{
    var creationStanza = objj_msgSend(TNStropheStanza, "iqWithAttributes:", {"type" : trinityTypeHypervisorControlAlloc, "to": objj_msgSend(objj_msgSend(self, "contact"), "fullJID")});
    var uuid = objj_msgSend(CPString, "UUID");
    objj_msgSend(creationStanza, "addChildName:withAttributes:", "query", {"xmlns" : trinityTypeHypervisorControl});
    objj_msgSend(creationStanza, "addChildName:withAttributes:", "jid", {});
    objj_msgSend(creationStanza, "addTextNode:", uuid);
    objj_msgSend(objj_msgSend(objj_msgSend(self, "contact"), "connection"), "send:", objj_msgSend(creationStanza, "tree"));
}
},["IBAction","id"]), new objj_method(sel_getUid("deleteVirtualMachine:"), function $TNMainViewController__deleteVirtualMachine_(self, _cmd, sender)
{ with(self)
{
    var alert = objj_msgSend(objj_msgSend(CPAlert, "alloc"), "init");
    objj_msgSend(alert, "setDelegate:", self);
    objj_msgSend(alert, "setTitle:", "Destroying a Virtual Machine");
    objj_msgSend(alert, "setMessageText:", "Are you sure you want to completely remove this virtual machine ?");
    objj_msgSend(alert, "setWindowStyle:", CPHUDBackgroundWindowMask);
    objj_msgSend(alert, "addButtonWithTitle:", "Yes");
    objj_msgSend(alert, "addButtonWithTitle:", "No");
    objj_msgSend(alert, "runModal");
}
},["IBAction","id"]), new objj_method(sel_getUid("alertDidEnd:returnCode:"), function $TNMainViewController__alertDidEnd_returnCode_(self, _cmd, theAlert, returnCode)
{ with(self)
{
    if (returnCode == 0)
    {
        var item = objj_msgSend(objj_msgSend(self, "popupDeleteMachine"), "selectedItem");
        var index = objj_msgSend(objj_msgSend(self, "popupDeleteMachine"), "indexOfSelectedItem");
        var freeStanza = objj_msgSend(TNStropheStanza, "iqWithAttributes:", {"type" : trinityTypeHypervisorControlFree, "to": objj_msgSend(objj_msgSend(self, "contact"), "fullJID")});
        objj_msgSend(freeStanza, "addChildName:withAttributes:", "query", {"xmlns" : trinityTypeHypervisorControl});
        objj_msgSend(freeStanza, "addTextNode:", objj_msgSend(item, "stringValue"));
        objj_msgSend(objj_msgSend(objj_msgSend(self, "contact"), "connection"), "send:", objj_msgSend(freeStanza, "tree"));
        objj_msgSend(objj_msgSend(self, "roster"), "removeContact:", objj_msgSend(item, "stringValue"));
        objj_msgSend(objj_msgSend(self, "popupDeleteMachine"), "removeItemAtIndex:", index);
    }
}
},["void","CPAlert","int"])]);
}
{var the_class = objj_allocateClassPair(CPMenuItem, "TNMenuItem"),
meta_class = the_class.isa;class_addIvars(the_class, [new objj_ivar("stringValue")]);
objj_registerClassPair(the_class);
class_addMethods(the_class, [new objj_method(sel_getUid("stringValue"), function $TNMenuItem__stringValue(self, _cmd)
{ with(self)
{
return stringValue;
}
},["id"]),
new objj_method(sel_getUid("setStringValue:"), function $TNMenuItem__setStringValue_(self, _cmd, newValue)
{ with(self)
{
stringValue = newValue;
}
},["void","id"])]);
}

