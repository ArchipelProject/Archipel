/*
 * TNVirtualMachineManageController.j
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
    TNArchipelTypeHypervisorControlManage       = @"manage",
    TNArchipelTypeHypervisorControlUnmanage     = @"unmanage";


/*! @ingroup hypervisorvmcreation
    This object allow to create new virtual machine
*/
@implementation TNVirtualMachineManageController : CPObject
{
    id   _delegate   @accessors(property=delegate);
}

#pragma mark -
#pragma mark Action

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

/*! ask hypervisor to manage virtual machines
    @param someVirtualMachines CPArray of virtual machines
*/
- (void)performManage:(CPArray)someVirtualMachines
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlManage}];

    for (var i = 0; i < [someVirtualMachines count]; i++)
    {
        var vm = [someVirtualMachines objectAtIndex:i];
        [stanza addChildWithName:@"item" andAttributes:{"jid": [vm JID]}];
        [stanza up];
    }

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didPerformManage:) ofObject:self];
}

- (BOOL)_didPerformManage:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [_delegate setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
        [_delegate setModuleStatus:TNArchipelModuleStatusError];
    }

    return NO;
}

/*! ask hypervisor to unmanage virtual machines
    @param someVirtualMachines CPArray of virtual machines
*/
- (void)performUnmanage:(CPArray)someVirtualMachines
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlUnmanage}];

    for (var i = 0; i < [someVirtualMachines count]; i++)
    {
        var vm = [someVirtualMachines objectAtIndex:i];
        [stanza addChildWithName:@"item" andAttributes:{"jid": [vm JID]}];
        [stanza up];
    }

    [_delegate setModuleStatus:TNArchipelModuleStatusWaiting];
    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didPerformUnmanage:) ofObject:self];
}

- (BOOL)_didPerformUnmanage:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [_delegate setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
        [_delegate setModuleStatus:TNArchipelModuleStatusError];
    }

    return NO;
}


@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineManageController], comment);
}