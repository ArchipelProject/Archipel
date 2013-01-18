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

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


var TNArchipelTypeSubscription                  = @"archipel:subscription",
    TNArchipelTypeSubscriptionAdd               = @"add",
    TNArchipelTypeSubscriptionRemove            = @"remove";


/*! @ingroup hypervisorvmcreation
    This object allow to control VM subscription requests
*/
@implementation TNVirtualMachineSubscriptionController : CPObject
{
    @outlet CPButton        buttonAddSubscription;
    @outlet CPButton        buttonRemoveSubscription;
    @outlet CPPopover       popoverAddSubscription;
    @outlet CPPopover       popoverRemoveSubscription;
    @outlet CPTextField     fieldNewSubscriptionTarget;
    @outlet CPTextField     fieldRemoveSubscriptionTarget;

    id                      _delegate   @accessors(property=delegate);
}


#pragma mark -
#pragma mark Action

/*! open the add subscription window
    @param aSender the sender
*/
- (IBAction)openAddSubsctiptionWindow:(id)aSender
{
    [fieldNewSubscriptionTarget setStringValue:@""];

    [popoverAddSubscription close];
    [popoverAddSubscription showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [popoverAddSubscription setDefaultButton:buttonAddSubscription];
    [popoverAddSubscription makeFirstResponder:fieldNewSubscriptionTarget];
}

/*! open the remove subscription window
    @param aSender the sender
*/
- (IBAction)openRemoveSubscriptionWindow:(id)aSender
{
    [fieldRemoveSubscriptionTarget setStringValue:@""];

    [popoverRemoveSubscription close];
    [popoverRemoveSubscription showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [popoverRemoveSubscription makeFirstResponder:fieldRemoveSubscriptionTarget];
    [popoverRemoveSubscription setDefaultButton:buttonRemoveSubscription];
}

/*! close the add subscription window
    @param aSender the sender
*/
- (IBAction)closeAddSubscriptionWindow:(id)aSender
{
    [popoverAddSubscription close];
}

/*! close the remove subscription window
    @param aSender the sender
*/
- (IBAction)closeRemoveSubscriptionWindow:(id)aSender
{
    [popoverRemoveSubscription close];
}

/*! add a new subscription
    @param aSender the sender
*/
- (IBAction)addSubscription:(id)aSender
{
    [self addSubscription];
}

/*! remove a subscription
    @param aSender the sender
*/
- (IBAction)removeSubscription:(id)aSender
{
    [self removeSubscription];
}


#pragma mark -
#pragma mark XMPP Controls

/*! add a new subscription to selected virtual machine
*/
- (void)addSubscription
{
    var tableVirtualMachines = [_delegate tableVirtualMachines];

    if (([tableVirtualMachines numberOfRows] == 0) || ([tableVirtualMachines numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select a virtual machine", @"You must select a virtual machine")];
         return;
    }

    var vm      = [[tableVirtualMachines dataSource] objectAtIndex:[tableVirtualMachines selectedRow]],
        stanza  = [TNStropheStanza iqWithType:@"set"];

    [popoverAddSubscription close];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeSubscription}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeSubscriptionAdd,
        "jid": [fieldNewSubscriptionTarget stringValue]}];

    [vm sendStanza:stanza andRegisterSelector:@selector(_didAddSubscription:) ofObject:self];
}

/*! compute the answer of the hypervisor about adding subscription
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didAddSubscription:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                         message:CPBundleLocalizedString(@"Added new subscription to virtual machine", @"Added new subscription to virtual machine")];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! ask vm to remove a subscription. but ask user if he is sure before
*/
- (id)removeSubscription
{
    var tableVirtualMachines = [_delegate tableVirtualMachines];

    if (([tableVirtualMachines numberOfRows] == 0) || ([tableVirtualMachines numberOfSelectedRows] != 1))
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select a virtual machine", @"You must select a virtual machine")];
         return;
    }

    var vm  = [[tableVirtualMachines dataSource] objectAtIndex:[tableVirtualMachines selectedRow]],
        alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Removing subscription", @"Removing subscription")
                              informative:CPBundleLocalizedString(@"Are you sure you want to remove the subscription for this user ?", @"Are you sure you want to remove the subscription for this user ?")
                                   target:self
                                  actions:[[CPBundleLocalizedString(@"Remove", @"Remove"), @selector(performRemoveSubscription:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];

    [alert setUserInfo:vm];

    [alert runModal];
}

/*! ask vm to remove a subscription
*/
- (void)performRemoveSubscription:(TNStropheContact)aVirtualMachine
{
    var tableVirtualMachines = [_delegate tableVirtualMachines];

    if (([tableVirtualMachines numberOfRows] == 0) || ([tableVirtualMachines numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select a virtual machine", @"You must select a virtual machine")];
         return;
    }

    var stanza = [TNStropheStanza iqWithType:@"set"];

    [popoverRemoveSubscription close];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeSubscription}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeSubscriptionRemove,
        "jid": [fieldRemoveSubscriptionTarget stringValue]}];

    [aVirtualMachine sendStanza:stanza andRegisterSelector:@selector(_didRemoveSubscription:) ofObject:self];
}

/*! compute the answer of the hypervisor about removing subscription
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didRemoveSubscription:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                         message:CPBundleLocalizedString(@"Subscription have been removed", @"Subscription have been removed")];
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
