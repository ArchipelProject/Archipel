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


var TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control",
    TNArchipelTypeHypervisorControlAlloc        = @"alloc",
    TNArchipelTypeHypervisorControlFree         = @"free",
    TNArchipelTypeHypervisorControlSetOrgInfo   = "setorginfo";


/*! Send this notification from anywhere to register a field completion delegate
*/
TNVirtualMachineVMCreationAddFieldDelegateNotification = @"TNVirtualMachineVMCreationAddFieldDelegateNotification";


/*! @ingroup hypervisorvmcreation
    This object allow to create new virtual machine
*/
@implementation TNVirtualMachineAllocationController : CPObject
{
    @outlet CPButton        buttonAlloc;
    @outlet CPPopover       mainPopover;
    @outlet CPComboBox      fieldNewVMRequestedCategories;
    @outlet CPComboBox      fieldNewVMRequestedLocality;
    @outlet CPComboBox      fieldNewVMRequestedName;
    @outlet CPComboBox      fieldNewVMRequestedOrganization;
    @outlet CPComboBox      fieldNewVMRequestedOrganizationUnit;
    @outlet CPComboBox      fieldNewVMRequestedOwner;

    TNStropheContact        _virtualMachine     @accessors(property=virtualMachine);
    id                      _delegate           @accessors(property=delegate);

    CPArray                 _fieldsNeedCompletion;
    CPArray                 _fieldsDelegates;
}


#pragma mark -
#pragma mark Action

- (void)awakeFromCib
{
    _fieldsDelegates = [CPArray array];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_didReceiveNewFieldDelegateRequest:)
                                                 name:TNVirtualMachineVMCreationAddFieldDelegateNotification
                                               object:nil];

    [fieldNewVMRequestedCategories setDelegate:self];
    [fieldNewVMRequestedLocality setDelegate:self];
    [fieldNewVMRequestedOrganization setDelegate:self];
    [fieldNewVMRequestedOrganizationUnit setDelegate:self];
    [fieldNewVMRequestedOwner setDelegate:self];
}


#pragma mark -
#pragma mark Notification Handlers

/*! add a notification as a fields delegate
    @param aNotification the notification
*/
- (void)_didReceiveNewFieldDelegateRequest:(CPNotification)aNotification
{
    var requester = [aNotification object];

    if (![_fieldsDelegates containsObject:requester]
        && [requester respondsToSelector:@selector(completionForField:value:)])
        [_fieldsDelegates addObject:requester];
}

- (void)controlTextDidFocus:(CPNotification)aNotification
{
    if (![_fieldsNeedCompletion containsObject:[[aNotification object] tag]])
        [self _requestCompletion:[aNotification object]];
}


#pragma mark -
#pragma mark Utilities

- (void)_requestCompletion:(CPComboxBox)aSender
{
    var completions = [CPArray array];

    for (var i = 0; i < [_fieldsDelegates count]; i++)
    {
        var currentDelegate = [_fieldsDelegates objectAtIndex:i],
            additionalCompletions = [currentDelegate completionForField:aSender value:[aSender objectValue]];
    }

    [_fieldsNeedCompletion addObject:[aSender tag]];
}


#pragma mark -
#pragma mark Actions

/*! open the window
    @param aSender the sender
*/
- (IBAction)openWindow:(id)aSender
{
    _fieldsNeedCompletion = [CPArray array];

    var vCard = [_virtualMachine vCard];

    [fieldNewVMRequestedName setStringValue:[[vCard firstChildWithName:@"FN"] text] || @""];
    [fieldNewVMRequestedOrganization setStringValue:[[vCard firstChildWithName:@"ORGNAME"] text] ||@""];
    [fieldNewVMRequestedOrganizationUnit setStringValue:[[vCard firstChildWithName:@"ORGUNIT"] text] || @""];
    [fieldNewVMRequestedLocality setStringValue:[[vCard firstChildWithName:@"LOCALITY"] text] || @""];
    [fieldNewVMRequestedOwner setStringValue:[[vCard firstChildWithName:@"USERID"] text] || @""];
    [fieldNewVMRequestedCategories setStringValue:[[vCard firstChildWithName:@"CATEGORIES"] text] || @""];


    if ([aSender isKindOfClass:CPTableView])
    {
        var rect = [aSender rectOfRow:[aSender selectedRow]];
        rect.origin.y += rect.size.height / 2;
        rect.origin.x += rect.size.width / 2;
        [mainPopover showRelativeToRect:CGRectMake(rect.origin.x, rect.origin.y, 10, 10) ofView:aSender preferredEdge:nil];
    }
    else
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil]

    [mainPopover makeFirstResponder:fieldNewVMRequestedName];
    [mainPopover setDefaultButton:buttonAlloc];

    if (_virtualMachine)
    {
        [buttonAlloc setTitle:@"Update"];
        [buttonAlloc setAction:@selector(update:)];
        [fieldNewVMRequestedName setEnabled:NO];
    }
    else
    {
        [buttonAlloc setTitle:@"Create"];
        [buttonAlloc setAction:@selector(alloc:)];
        [fieldNewVMRequestedName setEnabled:YES];
    }
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

/*! alloc a new virtual machine
    @param aSender the sender
*/
- (IBAction)update:(id)aSender
{
    [mainPopover close];
    [self update];
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
        "name": [fieldNewVMRequestedName stringValue],
        "orgname": [fieldNewVMRequestedOrganization stringValue],
        "orgunit": [fieldNewVMRequestedOrganizationUnit stringValue],
        "locality": [fieldNewVMRequestedLocality stringValue],
        "userid": [fieldNewVMRequestedOwner stringValue],
        "categories": [fieldNewVMRequestedCategories stringValue]}];

    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didAllocVirtualMachine:) ofObject:self];
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

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                         message:CPBundleLocalizedString(@"Virtual machine ", @"Virtual machine ") + vmJID + CPBundleLocalizedString(@" has been created", @" has been created")];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

- (void)update
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlSetOrgInfo,
        "target": [[_virtualMachine JID] node]}];

    [stanza addChildWithName:"ORGNAME"];
    [stanza addTextNode:[fieldNewVMRequestedOrganization stringValue]];
    [stanza up];

    [stanza addChildWithName:"ORGUNIT"];
    [stanza addTextNode:[fieldNewVMRequestedOrganizationUnit stringValue]];
    [stanza up];

    [stanza addChildWithName:"LOCALITY"];
    [stanza addTextNode:[fieldNewVMRequestedLocality stringValue]];
    [stanza up];

    [stanza addChildWithName:"USERID"];
    [stanza addTextNode:[fieldNewVMRequestedOwner stringValue]];
    [stanza up];

    [stanza addChildWithName:"CATEGORIES"];
    [stanza addTextNode:[fieldNewVMRequestedCategories stringValue]];
    [stanza up];

    [_delegate sendStanza:stanza andRegisterSelector:@selector(_didUpdateVirtualMachine:) ofObject:self];
}

/*! compute the answer of the hypervisor about its allocing a VM
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didUpdateVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var vmJID   = [[[aStanza firstChildWithName:@"query"] firstChildWithName:@"virtualmachine"] valueForAttribute:@"jid"];
        CPLog.info(@"sucessfully create a virtual machine");

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                         message:CPBundleLocalizedString(@"Virtual machine ", @"Virtual machine ") + vmJID + CPBundleLocalizedString(@" has been updated", @" has been updated")];

        [_delegate getHypervisorRoster];
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
        title   = CPBundleLocalizedString(@"Are you sure you want to completely remove these virtual machines ?", @"Are you sure you want to completely remove these virtual machines ?");

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

        [_delegate sendStanza:stanza andRegisterSelector:@selector(_didDeleteVirtualMachine:) ofObject:self];
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

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
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
