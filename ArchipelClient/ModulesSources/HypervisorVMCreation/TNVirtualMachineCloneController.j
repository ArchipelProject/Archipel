/*
 * TNVirtualMachineCloneController.j
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

@import <GrowlCappuccino/GrowlCappuccino.j>
@import <StropheCappuccino/TNStropheStanza.j>


@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


var TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control",
    TNArchipelTypeHypervisorControlClone        = @"clone";


/*! @ingroup hypervisorvmcreation
    This object allow to clone an existing virtual machine
*/
@implementation TNVirtualMachineCloneController : CPObject
{
    @outlet CPButton        buttonClone;
    @outlet CPPopover       mainPopover;
    @outlet CPTextField     fieldCloneVirtualMachineName;

    id                      _delegate   @accessors(property=delegate);
}


#pragma mark -
#pragma mark Action

/*! open the window
    @param aSender the sender
*/
- (IBAction)openWindow:(id)aSender
{
    [fieldCloneVirtualMachineName setStringValue:@""];

    [mainPopover close];
    [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [mainPopover makeFirstResponder:fieldCloneVirtualMachineName];
    [mainPopover setDefaultButton:buttonClone];
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
- (IBAction)cloneVirtualMachine:(id)aSender
{
    [mainPopover close];
    [self cloneVirtualMachine];
}


#pragma mark -
#pragma mark XMPP Controls

/*! clone a virtual machine.
*/
- (void)cloneVirtualMachine
{
    var tableVirtualMachines    = [_delegate tableVirtualMachines],
        vm                      = [[tableVirtualMachines dataSource] objectAtIndex:[tableVirtualMachines selectedRow]],
        stanza                  = [TNStropheStanza iqWithType:@"set"];

    [tableVirtualMachines deselectAll];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];

    if ([fieldCloneVirtualMachineName stringValue] && [fieldCloneVirtualMachineName stringValue] != @"")
    {
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeHypervisorControlClone,
            "jid": [[vm JID] bare],
            "name": [fieldCloneVirtualMachineName stringValue]}];
    }
    else
    {
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeHypervisorControlClone,
            "jid": [[vm JID] bare]}];
    }

    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didCloneVirtualMachine:) ofObject:self];
}

/*! compute the answer of the hypervisor about its cloning a VM
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didCloneVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info(@"sucessfully cloning a virtual machine");

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] name]
                                                         message:CPBundleLocalizedString(@"Virtual machine has been cloned", @"Virtual machine has been cloned")];
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
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineCloneController], comment);
}
