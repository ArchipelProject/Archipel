/*
 * TNVirtualMachineParkingController.j
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
@import <AppKit/CPView.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPTextField.j>

@import <LPKit/LPMultiLineTextField.j>


var TNArchipelTypeHypervisorParking             = @"archipel:hypervisor:vmparking",
    TNArchipelTypeHypervisorParkingList         = @"list",
    TNArchipelTypeHypervisorParkingPark         = @"park",
    TNArchipelTypeHypervisorParkingUnpark       = @"unpark",
    TNArchipelTypeHypervisorParkingDelete       = @"delete",
    TNArchipelTypeHypervisorParkingUpdateXML    = @"updatexml";

@implementation TNVirtualMachineParkedObject : CPObject
{
    CPString name       @accessors;
    CPString UUID       @accessors;
    CPString parkingID  @accessors;
    CPString date       @accessors;
    CPString parker     @accessors;
    TNXMLNode domain    @accessors;
}
@end


/*! @ingroup hypervisorvmcreation
    This object allow to clone an existing virtual machine
*/
@implementation TNVirtualMachineParkingController : CPObject
{
    @outlet CPButton                buttonDefine;
    @outlet CPPopover               mainPopover;
    @outlet LPMultiLineTextField    fieldXMLString;

    TNVirtualMachineParkedObject    _currentItem @accessors(property=currentItem);
    id                              _delegate   @accessors(property=delegate);
}

#pragma mark -
#pragma mark Initialization

/*! Called at cib awakening
*/
- (void)awakeFromCib
{
    [fieldXMLString setTextColor:[CPColor blackColor]];
    [fieldXMLString setFont:[CPFont fontWithName:@"Andale Mono, Courier New" size:12]];
    [fieldXMLString setBordered:YES];
    [fieldXMLString setBezeled:YES];
    [fieldXMLString setEnabled:YES];
}


#pragma mark -
#pragma mark Action

/*! open the window
    @param aSender the sender
*/
- (IBAction)openWindow:(id)aSender
{
    [fieldXMLString setStringValue:@""];

    [mainPopover close];

    if (!_currentItem)
        return;

    if ([aSender isKindOfClass:CPTableView])
    {
        var rect = [aSender rectOfRow:[aSender selectedRow]];
        rect.origin.y += rect.size.height;
        rect.origin.x += rect.size.width / 2;
        var point = [[aSender superview] convertPoint:rect.origin toView:nil];
        [mainPopover showRelativeToRect:CPRectMake(point.x, point.y, 10, 10) ofView:nil preferredEdge:CPMaxYEdge];
    }
    else
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [mainPopover makeFirstResponder:fieldXMLString];
    [mainPopover setDefaultButton:buttonDefine];

    // if I put this before, the field is empty...
    var XMLString = [[_currentItem domain] description];
    XMLString = XMLString.replace("\n  \n", "\n");
    XMLString = XMLString.replace(" xmlns='http://www.gajim.org/xmlns/undeclared'", "");
    XMLString = XMLString.replace(" xmlns='archipel:hypervisor:vmparking'", "");
    [fieldXMLString setStringValue:XMLString];

    [fieldXMLString setEditable:YES];
}

/*! close the window
    @param aSender the sender
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close];
}

/*! clone a virtual machine
    @param sender the sender of the action
*/
- (IBAction)updateXML:(id)aSender
{
    var desc;
    try
    {
        desc = (new DOMParser()).parseFromString(unescape(""+[fieldXMLString stringValue]+""), "text/xml").getElementsByTagName("domain")[0];
        if (!desc || typeof(desc) == "undefined")
            [CPException raise:CPInternalInconsistencyException reason:@"Not valid XML"];
    }
    catch (e)
    {
        [TNAlert showAlertWithMessage:CPLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"Unable to parse the given XML", @"Unable to parse the given XML")
                          style:CPCriticalAlertStyle];
        [mainPopover close];
        return;
    }

    [self updateCurrentItemXML:[TNXMLNode nodeWithXMLNode:desc]];
    [mainPopover close];
}


#pragma mark -
#pragma mark XMPP Controls

/*! Get list of parked virtual machines
*/
- (void)listParkedVirtualMachines
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorParkingList}];

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didReceiveList:) ofObject:self];
}

/*! compute the answer of the hypervisor about its parking VMs list
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didReceiveList:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var table = [_delegate tableVirtualMachinesParked],
            datasource = [table dataSource],
            virtualmachines = [aStanza childrenWithName:@"virtualmachine"];

        [datasource removeAllObjects];
        for (var i = 0; i < [virtualmachines count]; i++)
        {
            var vm = [virtualmachines objectAtIndex:i],
                data = [TNVirtualMachineParkedObject new];

            [data setName:[[vm firstChildWithName:@"name"] text]];
            [data setUUID:[[vm firstChildWithName:@"uuid"] text]];
            [data setDate:[vm valueForAttribute:@"date"]];
            [data setParker:[vm valueForAttribute:@"parker"]];
            [data setParkingID:[vm valueForAttribute:@"itemid"]];
            [data setDomain:[vm firstChildWithName:@"domain"]];

            [datasource addObject:data];
        }
        [table reloadData];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! park some virtual machines
    @param someVirtualMachines CPArray of virtual machine to park
*/
- (void)parkVirtualMachines:(CPArray)someVirtualMachines
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorParkingPark}];

    for (var i = 0; i < [someVirtualMachines count]; i++)
    {
        var vm = [someVirtualMachines objectAtIndex:i];
        [stanza addChildWithName:@"item" andAttributes:{"uuid": [[vm JID] node]}];
        [stanza up];
    }

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didParkVirtualMachine:) ofObject:self];
}

/*! compute the answer of the hypervisor about its parking VMs
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didParkVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! unpark some virtual machines
    @param someVirtualMachines CPArray of virtual machine to unpark
*/
- (void)unparkVirtualMachines:(CPArray)someVirtualMachines
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorParkingUnpark}];

    for (var i = 0; i < [someVirtualMachines count]; i++)
    {
        var vm = [someVirtualMachines objectAtIndex:i];
        [stanza addChildWithName:@"item" andAttributes:{"ticket": [vm parkingID]}];
        [stanza up];
    }

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didUnparkVirtualMachine:) ofObject:self];
}

/*! compute the answer of the hypervisor about uparking virtual machines
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didUnparkVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! Update the current parked vm item XML definition
    @param aNewDefinition TNXMLNode representing the new definition
*/
- (void)updateCurrentItemXML:(TNXMLNode)aNewDefinition
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorParkingUpdateXML,
        "ticket": [_currentItem parkingID]}];

    [stanza addNode:aNewDefinition];
    _currentItem = nil;

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didUpdateCurrentItemXML:) ofObject:self];
}

/*! compute the answer of the hypervisor about updating xml description
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didUpdateCurrentItemXML:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! Delete some parked VMs
    @param someVirtualMachines CPArray containing parked virtual machines to delete
*/
- (void)deleteParkedVirtualMachines:(CPArray)someVirtualMachines
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorParking}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorParkingDelete}];

    for (var i = 0; i < [someVirtualMachines count]; i++)
    {
        var vm = [someVirtualMachines objectAtIndex:i];
        [stanza addChildWithName:@"item" andAttributes:{"ticket": [vm parkingID]}];
        [stanza up];
    }

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didDeleteParkedVirtualMachines:) ofObject:self];

}

/*! compute the answer of the hypervisor about deleting parked virtual machines
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didDeleteParkedVirtualMachines:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineParkingController], comment);
}