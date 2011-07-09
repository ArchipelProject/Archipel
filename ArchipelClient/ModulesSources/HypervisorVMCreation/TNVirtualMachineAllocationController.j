/*
 * TNVirtualMachineSubscriptionController.j
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


var TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control",
    TNArchipelTypeHypervisorControlAlloc        = @"alloc",
    TNArchipelTypeHypervisorControlFree         = @"free";


/*! @ingroup hypervisorvmcreation
    This object allow to create new virtual machine
*/
@implementation TNVirtualMachineAllocationController : CPObject
{
    @outlet CPButton        buttonAlloc;
    @outlet CPPopover       mainPopover;
    @outlet CPTextField     fieldNewVMRequestedName;

    id                      _delegate   @accessors(property=delegate);
}


#pragma mark -
#pragma mark Action

/*! open the window
    @param aSender the sender
*/
- (IBAction)openWindow:(id)aSender
{
    [fieldNewVMRequestedName setStringValue:@""];

    [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [mainPopover makeFirstResponder:fieldNewVMRequestedName];
    [mainPopover setDefaultButton:buttonAlloc];
}

/*! close the window
    @param aSender the sender
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close]
}

/*! alloc a new virtual machine
    @param aSender the sender
*/
- (IBAction)alloc:(id)aSender
{
    [mainPopover close];
    [self alloc];
}


#pragma mark -
#pragma mark XMPP Controls

/*! alloc a new virtual machine
    @param aSender the sender
*/
- (void)alloc
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlAlloc,
        "name": [fieldNewVMRequestedName stringValue]}];

    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didAllocVirtualMachine:) ofObject:self];
}

/*! compute the answer of the hypervisor about its allocing a VM
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didAllocVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var vmJID   = [[[aStanza firstChildWithName:@"query"] firstChildWithName:@"virtualmachine"] valueForAttribute:@"jid"];
        CPLog.info(@"sucessfully create a virtual machine");

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Virtual Machine", @"Virtual Machine")
                                                         message:CPBundleLocalizedString(@"Virtual machine ", @"Virtual machine ") + vmJID + CPBundleLocalizedString(@" has been created", @" has been created")];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! delete a virtual machine. but ask user if he is sure before
*/
- (void)deleteVirtualMachine
{
    var tableVirtualMachines = [_delegate tableVirtualMachines];

    if (([tableVirtualMachines numberOfRows] == 0) || ([tableVirtualMachines numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select a virtual machine", @"You must select a virtual machine")];
         return;
    }

    var msg     = CPBundleLocalizedString(@"Destroying some Virtual Machines", @"Destroying some Virtual Machines"),
        title   = CPBundleLocalizedString(@"Are you sure you want to completely remove theses virtual machines ?", @"Are you sure you want to completely remove theses virtual machines ?");

    if ([[tableVirtualMachines selectedRowIndexes] count] < 2)
    {
        msg     = CPBundleLocalizedString(@"Are you sure you want to completely remove this virtual machine ?", @"Are you sure you want to completely remove this virtual machine ?");
        title   = CPBundleLocalizedString(@"Destroying a Virtual Machine", @"Destroying a Virtual Machine");
    }

    var alert = [TNAlert alertWithMessage:title
                                informative:msg
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Delete", @"Delete"), @selector(performDeleteVirtualMachine:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];

    [alert setUserInfo:[tableVirtualMachines selectedRowIndexes]];

    [alert runModal];
}

/*! delete a virtual machine
*/
- (void)performDeleteVirtualMachine:(id)someUserInfo
{
    var tableVirtualMachines = [_delegate tableVirtualMachines],
        indexes = someUserInfo,
        objects = [[tableVirtualMachines dataSource] objectsAtIndexes:indexes];

    [tableVirtualMachines deselectAll];

    for (var i = 0; i < [objects count]; i++)
    {
        var vm              = [objects objectAtIndex:i],
            stanza          = [TNStropheStanza iqWithType:@"set"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "xmlns": TNArchipelTypeHypervisorControl,
            "action": TNArchipelTypeHypervisorControlFree,
            "jid": [vm JID]}];

        if ([[[TNStropheIMClient defaultClient] roster] containsJID:[vm JID]])
            [[[TNStropheIMClient defaultClient] roster] removeContact:vm];

        [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didDeleteVirtualMachine:) ofObject:self];
    }
}

/*! compute the answer of the hypervisor about its deleting a VM
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didDeleteVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info(@"sucessfully deallocating a virtual machine");

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Virtual Machine", @"Virtual Machine")
                                                         message:CPBundleLocalizedString(@"Virtual machine has been removed", @"Virtual machine has been removed")];
    }
    else
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
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineSubscriptionController], comment);
}