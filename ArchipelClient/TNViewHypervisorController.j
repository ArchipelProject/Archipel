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

@import "StropheCappuccino/TNStrophe.j";
@import "TNViewEntityController.j";

trinityTypeHypervisorControl            = @"trinity:hypervisor:control";
trinityTypeHypervisorControlAlloc       = @"alloc";
trinityTypeHypervisorControlFree        = @"free";
trinityTypeHypervisorControlRosterVM    = @"rostervm";


@implementation TNMenuItem: CPMenuItem
{
    CPString stringValue @accessors;
}
@end


@implementation TNViewHypervisorController: TNViewEntityController 
{
    @outlet CPTextField     jid                 @accessors;
    @outlet CPTextField     mainTitle           @accessors;
    @outlet CPButton        buttonCreateVM      @accessors;
    @outlet CPPopUpButton   popupDeleteMachine  @accessors;
    @outlet CPButton        buttonDeleteVM      @accessors;
}

- (void)initialize
{   
    [[self popupDeleteMachine] removeAllItems];
    [[self mainTitle] setStringValue:[[self contact] nickname]];
    [[self jid] setStringValue:[[self contact] jid]];
    
    [self getHypervisorRoster];
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
    var i;
    
    [[self popupDeleteMachine] removeAllItems];
    
    @each (var anItem in queryItems)
    {
        var jid = $(anItem).text();
        var entry = [[self roster] getContactFromJID:jid];
        if (entry) 
        {
            if ($([entry vCard].firstChild).text() == "virtualmachine")
            {
                var name = [entry nickname] + " (" + jid +")";
                var item = [[TNMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""]
                [item setImage:[entry statusIcon]];
                [item setStringValue:jid];
                [[self popupDeleteMachine] addItem:item];
            }
        }
    }
    // for (i = 0; i < queryItems.length; i++)
    // {
    //     var jid = $(queryItems[i]).text();
    // 
    //     var entry = [[self roster] getContactFromJID:jid];
    //     if (entry) 
    //     {
    //         if ($([entry vCard].firstChild).text() == "virtualmachine")
    //         {
    //             var name = [entry nickname] + " (" + jid +")";
    //             var item = [[TNMenuItem alloc] initWithTitle:name action:nil keyEquivalent:@""]
    //             [item setImage:[entry statusIcon]];
    //             [item setStringValue:jid];
    //             [[self popupDeleteMachine] addItem:item];
    //         }
    //     }
    // }
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


