/*
 * TNVMCastRegistrationController.j
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


var TNArchipelTypeHypervisorVMCasting                   = @"archipel:hypervisor:vmcasting",
    TNArchipelTypeHypervisorVMCastingRegister           = @"register",
    TNArchipelTypeHypervisorVMCastingUnregister         = @"unregister";


/*! @ingroup hypervisorvmcasts
    This object allow to manage VMCast registrations
*/
@implementation TNVMCastRegistrationController : CPObject
{
    @outlet CPButton        buttonNewVMCast;
    @outlet CPPopover       mainPopover;
    @outlet CPTextField     fieldNewURL;

    id                      _delegate   @accessors(property=delegate);
}


#pragma mark -
#pragma mark Action

/*! open the window
    @param aSender the sender
*/
- (IBAction)openWindow:(id)aSender
{
    [fieldNewURL setStringValue:@""];
    [mainPopover close];
    [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [mainPopover setDefaultButton:buttonNewVMCast];
    [mainPopover makeFirstResponder:fieldNewURL];
}

/*! close the window
    @param aSender the sender
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close]
}

/*! add new VMCast
    @param sender the sender of the action
*/
- (IBAction)addNewVMCast:(id)aSender
{
    [mainPopover close];
    [self addNewVMCast];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask hypervisor to add VMCasts
*/
- (void)addNewVMCast
{
    var stanza      = [TNStropheStanza iqWithType:@"set"],
        url         = [fieldNewURL stringValue];

    [fieldNewURL setStringValue:@""];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingRegister,
        "url": url}];

    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didAddNewVMCast:) ofObject:self];
}

/*! compute the hypervisor answer about adding a VMCast
    @param aStanza TNStropheStanza that contains the hypervisor answer
*/
- (BOOL)_didAddNewVMCast:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname] message:CPBundleLocalizedString(@"VMcast has been registred", @"VMcast has been registred")];
    else
        [_delegate handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! ask hypervisor to add remove an VMCast. but before ask user if he is sure.
*/
- (void)removeVMCast
{
    var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Delete VMCast", @"Delete VMCast")
                                informative:CPBundleLocalizedString(@"Are you sure you want to unregister fro this VMCast? All its appliances will be deleted.", @"Are you sure you want to unregister fro this VMCast? All its appliances will be deleted.")
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Unregister", @"Unregister"), @selector(performRemoveVMCast:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];

    [alert runModal];
}

/*! ask hypervisor to add remove an VMCast
*/
- (void)performRemoveVMCast:(id)someUserInfo
{
    var mainOutlineView = [_delegate mainOutlineView],
        currentVMCast   = [mainOutlineView itemAtRow:[mainOutlineView selectedRow]],
        uuid            = [currentVMCast UUID],
        stanza          = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingUnregister,
        "uuid": uuid}];

    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didRemoveVMCast:) ofObject:self];
}

/*! compute the hypervisor answer about removing an vmcast
    @param aStanza TNStropheStanza that contains the hypervisor answer
*/
- (BOOL)_didRemoveVMCast:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                         message:CPBundleLocalizedString(@"VMcast has been unregistred", @"VMcast has been unregistred")];
    else
        [_delegate handleIqErrorFromStanza:aStanza];

    return NO;
}


@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNNewVirtualMachineController], comment);
}