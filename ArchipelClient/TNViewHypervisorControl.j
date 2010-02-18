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

@import "StropheCappuccino/TNStropheConnection.j";
@import "StropheCappuccino/TNStropheStanza.j"
@import "StropheCappuccino/TNStropheRoster.j";


trinityTypeHypervisorControl        = @"trinity:hypervisor:control";
trinityTypeHypervisorControlAlloc   = @"alloc";
trinityTypeHypervisorControlFree    = @"free";

@implementation TNViewHypervisorControl: CPView 
{
    @outlet CPTextField     jid;
    @outlet CPTextField     mainTitle;
    
    @outlet CPTextField     fieldNewUUID;
    @outlet CPButton        buttonCreateVM;
    
    @outlet CPPopUpButton   popupDeleteMachine;
    @outlet CPButton        buttonDeleteVM;
    
    
    TNStropheRoster         roster  @accessors;
    TNStropheRosterEntry    _hypervisor;
    
}


- (void)setHypervisor:(TNStropheRosterEntry)aHypervisor
{
    _hypervisor = aHypervisor;
    
    [[self mainTitle] setStringValue:[_hypervisor nickname]];
    [[self jid] setStringValue:[_hypervisor jid]];
    [[self fieldNewUUID] setStringValue:[CPString UUID]];
}

//actions
- (IBAction) addVirtualMachine:(id)sender
{
    var creationStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControlAlloc, "to": [_hypervisor fullJID]}];
    [creationStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeHypervisorControl}];
    [creationStanza addTextNode:[fieldNewUUID stringValue]];
    [[_hypervisor connection] send:[creationStanza tree]];

    console.log("iq sent at " + [[self roster] connection]);
}

- (IBAction) deleteVirtualMachine:(id)sender
{
    console.log("delete vm with uuid " + [popupDeleteMachine stringValue]);
}

@end


