/*  
 * TNViewHypervisorControl.j
 *    
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
 
@import "../../TNModule.j";

trinityTypeHypervisorControl            = @"trinity:hypervisor:control";
trinityTypeHypervisorControlAlloc       = @"alloc";
trinityTypeHypervisorControlFree        = @"free";
trinityTypeHypervisorControlRosterVM    = @"rostervm";
trinityTypeHypervisorControlHealth      = @"healthinfo";


@implementation TNMainViewController : TNModule 
{
    @outlet CPTextField     fieldJID            @accessors;
    @outlet CPTextField     fieldName           @accessors;
    @outlet CPButton        buttonCreateVM      @accessors;
    @outlet CPPopUpButton   popupDeleteMachine  @accessors;
    @outlet CPButton        buttonDeleteVM      @accessors;
    @outlet CPTextField     healthCPUUsage      @accessors;
    @outlet CPTextField     healthDiskUsage     @accessors;
    @outlet CPTextField     healthMemUsage      @accessors;
    @outlet CPTextField     healthLoad          @accessors;
    @outlet CPTextField     healthUptime        @accessors;
    @outlet CPTextField     healthInfo          @accessors;
           
    CPTimer _timer;
    
}

- (void)willLoad
{
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:nil];
}

- (void)willUnload
{
    var center = [CPNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)willShow
{
    
    if (_timer)
        [_timer invalidate];
    
    [[self popupDeleteMachine] removeAllItems];
    [[self fieldName] setStringValue:[[self contact] nickname]];
    
    [[self fieldJID] setStringValue:[[self contact] jid]];
    
    [self getHypervisorRoster];
    [self getHypervisorHealth:nil];
    
    _timer = [CPTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(getHypervisorHealth:) userInfo:nil repeats:YES]
}

- (void)willHide
{
    console.log("hiding");
    if (_timer)
        [_timer invalidate];
}



- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == [self contact])
    {
       [[self fieldName] setStringValue:[[self contact] nickname]] 
    }
}

- (void)getHypervisorRoster
{
    var uid = [[[self contact] connection] getUniqueId];
    var rosterStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControlRosterVM, "to": [[self contact] fullJID], "id": uid}];
    var params;
        
    [rosterStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeHypervisorControl}];
    
    params= [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorRoster:) ofObject:self withDict:params];
    [[[self contact] connection] send:[rosterStanza stanza]];
}

- (void)didReceiveHypervisorRoster:(id)aStanza 
{
    var queryItems = aStanza.getElementsByTagName("item");
    
    [[self popupDeleteMachine] removeAllItems];
    for (var i = 0; i < queryItems.length; i++)
    {
        var jid = $(queryItems[i]).text();
        
        var entry = [[self roster] getContactFromJID:jid];
        if (entry) 
        {
            if ($([entry vCard].firstChild).text() == "virtualmachine")
            {
                var name = [entry nickname] + " (" + jid +")";
                var item = [[TNMenuItem alloc] initWithTitle:name action:nil keyEquivalent:nil]
                [item setImage:[entry statusIcon]];
                [item setStringValue:jid];
                [[self popupDeleteMachine] addItem:item];
            }
        }
    }
}

- (void)getHypervisorHealth:(CPTimer)aTimer
{
    if (![self superview])
    {
        [_timer invalidate];
        return;
    }
    var uid = [[[self contact] connection] getUniqueId];
    var rosterStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControlHealth, "to": [[self contact] fullJID], "id": uid}];
    var params;
    
    [rosterStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeHypervisorControl}];
    
    params= [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorHealth:) ofObject:self withDict:params];
    
    [[[self contact] connection] send:[rosterStanza stanza]];
}

- (void)didReceiveHypervisorHealth:(id)aStanza 
{
    console.log("hypervisor health stat received");
    if (aStanza.getAttribute("type") == @"success")
    {       
        var memNode = aStanza.getElementsByTagName("memory")[0];
        [[self healthMemUsage] setStringValue:memNode.getAttribute("free") + "Mo / " + memNode.getAttribute("swapped") + "Mo"];

        var diskNode = aStanza.getElementsByTagName("disk")[0];
        [[self healthDiskUsage] setStringValue:diskNode.getAttribute("used-percentage")];

        var loadNode = aStanza.getElementsByTagName("load")[0];
        [[self healthLoad] setStringValue:loadNode.getAttribute("five")];

        var uptimeNode = aStanza.getElementsByTagName("uptime")[0];
        [[self healthUptime] setStringValue:uptimeNode.getAttribute("up")];

        var cpuNode = aStanza.getElementsByTagName("cpu")[0];
        var cpuFree = 100 - parseInt(cpuNode.getAttribute("id"));
        [[self healthCPUUsage] setStringValue:cpuFree + @"%"];

        var infoNode = aStanza.getElementsByTagName("uname")[0];
        [[self healthInfo] setStringValue:infoNode.getAttribute("os") + " " + infoNode.getAttribute("kname")];
    }
}


//actions
- (IBAction) addVirtualMachine:(id)sender
{
    var creationStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControlAlloc, "to": [[self contact] fullJID]}];
    var uuid = [CPString UUID];

    [creationStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeHypervisorControl}];
    [creationStanza addChildName:@"jid" withAttributes:{}];
    [creationStanza addTextNode:uuid];
    [[[self contact] connection] send:[creationStanza tree]];
}

- (IBAction) deleteVirtualMachine:(id)sender
{
    var alert = [[CPAlert alloc] init];
    
    [alert setDelegate:self];
    [alert setTitle:@"Destroying a Virtual Machine"];
    [alert setMessageText:@"Are you sure you want to completely remove this virtual machine ?"];
    [alert setWindowStyle:CPHUDBackgroundWindowMask];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert runModal];
}

- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode 
{
    if (returnCode == 0)
    {
        var item  = [[self popupDeleteMachine] selectedItem];
        var index = [[self popupDeleteMachine] indexOfSelectedItem];

        var freeStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControlFree, "to": [[self contact] fullJID]}];

        [freeStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeHypervisorControl}];
        [freeStanza addTextNode:[item stringValue]];
        [[[self contact] connection] send:[freeStanza tree]];
        [[self roster] removeContact:[item stringValue]];

        [[self popupDeleteMachine] removeItemAtIndex:index];
    }
}
@end


@implementation TNMenuItem: CPMenuItem
{
    CPString stringValue @accessors;
}
@end

@implementation CPString (CPStringWithUUIDSeparated)
{
}
+ (CPString)UUID
{
    var g = @"";
    
    for(var i = 0; i < 32; i++)
    {
        if ((i == 8) || (i == 12) || (i == 16) || (i == 20))
            g += '-';
        g += FLOOR(RAND() * 0xF).toString(0xF);
    }
    
    return g;
}
@end


