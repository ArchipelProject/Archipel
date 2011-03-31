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

@import <AppKit/CPButton.j>
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>


var TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control",
    TNArchipelTypeHypervisorControlAlloc        = @"alloc",
    TNArchipelTypeHypervisorControlFree         = @"free",
    TNArchipelTypeHypervisorControlRosterVM     = @"rostervm",
    TNArchipelTypeHypervisorControlClone        = @"clone",
    TNArchipelTypeSubscription                  = @"archipel:subscription",
    TNArchipelTypeSubscriptionAdd               = @"add",
    TNArchipelTypeSubscriptionRemove            = @"remove",
    TNArchipelPushNotificationHypervisor        = @"archipel:push:hypervisor";

/*! @defgroup  hypervisorvmcreation Module Hypervisor VM Creation
    @desc This module allow to create and delete virtual machines
*/

/*! @ingroup hypervisorvmcreation
    Main controller of the module
*/
@implementation TNHypervisorVMCreationController : TNModule
{
    @outlet CPButton        buttonAlloc;
    @outlet CPButtonBar     buttonBarControl;
    @outlet CPPopUpButton   popupDeleteMachine;
    @outlet CPScrollView    scrollViewListVM;
    @outlet CPSearchField   fieldFilterVM;
    @outlet CPTextField     fieldJID;
    @outlet CPTextField     fieldName;
    @outlet CPTextField     fieldNewSubscriptionTarget;
    @outlet CPTextField     fieldNewVMRequestedName;
    @outlet CPTextField     fieldRemoveSubscriptionTarget;
    @outlet CPView          viewTableContainer;
    @outlet CPWindow        windowNewSubscription;
    @outlet CPWindow        windowNewVirtualMachine;
    @outlet CPWindow        windowRemoveSubscription;

    CPButton                _cloneButton;
    CPButton                _minusButton;
    CPButton                _plusButton;
    CPButton                _addSubscriptionButton;
    CPButton                _removeSubscriptionButton;
    CPTableView             _tableVirtualMachines;
    TNTableViewDataSource   _virtualMachinesDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    // VM table view
    _virtualMachinesDatasource   = [[TNTableViewDataSource alloc] init];
    _tableVirtualMachines        = [[CPTableView alloc] initWithFrame:[scrollViewListVM bounds]];

    [scrollViewListVM setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewListVM setAutohidesScrollers:YES];
    [scrollViewListVM setDocumentView:_tableVirtualMachines];

    [_tableVirtualMachines setUsesAlternatingRowBackgroundColors:YES];
    [_tableVirtualMachines setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableVirtualMachines setAllowsColumnResizing:YES];
    [_tableVirtualMachines setAllowsEmptySelection:YES];
    [_tableVirtualMachines setAllowsMultipleSelection:YES];
    [_tableVirtualMachines setDelegate:self];
    [_tableVirtualMachines setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableVirtualMachines setTarget:self];
    [_tableVirtualMachines setDoubleAction:@selector(didDoubleClick:)]

    var vmColumNickname     = [[CPTableColumn alloc] initWithIdentifier:@"nickname"],
        vmColumJID          = [[CPTableColumn alloc] initWithIdentifier:@"JID"],
        vmColumStatusIcon   = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"],
        imgView             = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [vmColumNickname setWidth:250];
    [[vmColumNickname headerView] setStringValue:@"Name"];
    [vmColumNickname setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"nickname" ascending:YES]];

    [vmColumJID setWidth:320];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];
    [vmColumJID setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"JID" ascending:YES]];

    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setResizingMask:CPTableColumnAutoresizingMask ];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];

    [_tableVirtualMachines addTableColumn:vmColumStatusIcon];
    [_tableVirtualMachines addTableColumn:vmColumNickname];
    [_tableVirtualMachines addTableColumn:vmColumJID];

    [_virtualMachinesDatasource setTable:_tableVirtualMachines];
    [_virtualMachinesDatasource setSearchableKeyPaths:[@"nickname", @"JID"]];

    [fieldFilterVM setTarget:_virtualMachinesDatasource];
    [fieldFilterVM setAction:@selector(filterObjects:)];

    [_tableVirtualMachines setDataSource:_virtualMachinesDatasource];

    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:@"Create new virtual machine" action:@selector(addVirtualMachine:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Delete" action:@selector(deleteVirtualMachine:) keyEquivalent:@""];
    [_tableVirtualMachines setMenu:menu];

    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(addVirtualMachine:)];
    [_plusButton setToolTip:@"Ask hypervisor to create a new virtual machine"];

    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(deleteVirtualMachine:)];
    [_minusButton setToolTip:@"Ask hypervisor to completely destroy all selected virtual machine"];

    _addSubscriptionButton = [CPButtonBar plusButton];
    [_addSubscriptionButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/subscription-add.png"] size:CPSizeMake(16, 16)]];
    [_addSubscriptionButton setTarget:self];
    [_addSubscriptionButton setAction:@selector(openAddSubscriptionWindow:)];
    [_addSubscriptionButton setToolTip:@"Ask the virtual machine to add in its contact a user"];

    _removeSubscriptionButton = [CPButtonBar plusButton];
    [_removeSubscriptionButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/subscription-remove.png"] size:CPSizeMake(16, 16)]];
    [_removeSubscriptionButton setTarget:self];
    [_removeSubscriptionButton setAction:@selector(openRemoveSubscriptionWindow:)];
    [_removeSubscriptionButton setToolTip:@"Ask the virtual machine to remove a user from its contact"];

    _cloneButton = [CPButtonBar minusButton];
    [_cloneButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/branch.png"] size:CPSizeMake(16, 16)]];
    [_cloneButton setTarget:self];
    [_cloneButton setAction:@selector(cloneVirtualMachine:)];
    [_cloneButton setToolTip:@"Create a clone virtual machine from the selected one"];

    [_minusButton setEnabled:NO];
    [_addSubscriptionButton setEnabled:NO];
    [_removeSubscriptionButton setEnabled:NO];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _cloneButton, _addSubscriptionButton, _removeSubscriptionButton]];

}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationHypervisor];

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(_reload:) name:TNStropheRosterAddedContactNotification object:nil];
    [center addObserver:self selector:@selector(_reload:) name:TNStropheContactPresenceUpdatedNotification object:nil];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [_tableVirtualMachines setDelegate:nil];
    [_tableVirtualMachines setDelegate:self]; // hum....

    [self populateVirtualMachinesTable];
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [_virtualMachinesDatasource removeAllObjects];
    [_tableVirtualMachines reloadData];

    [super willUnload];
}

/*! called when module become visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];

    return YES;
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:@"Create new virtual machine" action:@selector(addVirtualMachine:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Delete virtual machine" action:@selector(deleteVirtualMachine:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Clone this virtual machine" action:@selector(cloneVirtualMachine:) keyEquivalent:@""] setTarget:self];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [self setControl:_plusButton enabledAccordingToPermission:@"alloc"];
    [self setControl:_minusButton enabledAccordingToPermission:@"free"];
    [self setControl:_cloneButton enabledAccordingToPermission:@"clone"];
    [self setControl:_addSubscriptionButton enabledAccordingToPermission:@"subscription_add"];
    [self setControl:_removeSubscriptionButton enabledAccordingToPermission:@"subscription_remove"];

    if (![self currentEntityHasPermission:@"alloc"])
        [windowNewVirtualMachine close];

    if (![self currentEntityHasPermission:@"subscription_add"])
        [windowNewSubscription close];

    if (![self currentEntityHasPermission:@"subscription_remove"])
        [windowRemoveSubscription close];

    [self tableViewSelectionDidChange:nil];

    [self populateVirtualMachinesTable];
}

#pragma mark -
#pragma mark Notification handlers

/*! called when entity's nickname changed
    @param aNotification the notification
*/
- (void)_didUpdateNickName:(CPNotification)aNotification
{
    [fieldName setStringValue:[_entity nickname]]
}

/*! called when an Archipel push is recieved
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    CPLog.info("PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);

    [self populateVirtualMachinesTable];

    return YES;
}

/*! reload the content of the table when contact add or presence changes
    @param aNotification the notification
*/
- (void)_reload:(CPNotification)aNotification
{
    if ([_entity XMPPShow] != TNStropheContactStatusOffline)
        [self populateVirtualMachinesTable];
}

/*! reoload the table when a VM change it's status
    @param aNotification the notification
*/
- (void)_didChangeVMStatus:(CPNotification)aNotif
{
    [_tableVirtualMachines reloadData];
}

/*! update the GUI according to the selected entity in table
    @param aNotification the notification
*/
- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    [_minusButton setEnabled:NO];
    [_cloneButton setEnabled:NO];
    [_addSubscriptionButton setEnabled:NO];
    [_removeSubscriptionButton setEnabled:NO];

    var condition = ([_tableVirtualMachines numberOfSelectedRows] > 0);

    [self setControl:_minusButton enabledAccordingToPermission:@"free" specialCondition:condition];
    [self setControl:_cloneButton enabledAccordingToPermission:@"clone" specialCondition:condition];
    [self setControl:_addSubscriptionButton enabledAccordingToPermission:@"subscription_add" specialCondition:condition];
    [self setControl:_removeSubscriptionButton enabledAccordingToPermission:@"subscription_remove" specialCondition:condition];
}


#pragma mark -
#pragma mark Utilities

/*! will populate the table of virtual machine according to permissions
    if entity has rostervm permissions, the it will ask for the hyperisor's roster,
    otherwise it will populate according to the user roster
*/
- (void)populateVirtualMachinesTable
{
    if ([self currentEntityHasPermission:@"rostervm"])
        [self getHypervisorRoster];
    else
    {
        [_virtualMachinesDatasource removeAllObjects];
        for (var i = 0; i < [[[[TNStropheIMClient defaultClient] roster] contacts] count]; i++)
        {
            var contact = [[[[TNStropheIMClient defaultClient] roster] contacts] objectAtIndex:i];

            if (([[[TNStropheIMClient defaultClient] roster] analyseVCard:[contact vCard]] == TNArchipelEntityTypeVirtualMachine)
                && [[contact resources] count]
                && ([[contact resources] objectAtIndex:0] == [[_entity JID] node]))
            {
                [_virtualMachinesDatasource addObject:contact];
                [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didChangeVMStatus:) name:TNStropheContactPresenceUpdatedNotification object:contact];
            }
        }
        [_tableVirtualMachines reloadData];
    }
}


#pragma mark -
#pragma mark Actions

/*! add double clicked vm to roster if not present or go to virtual machine
    @param sender the sender of the action
*/
- (IBAction)didDoubleClick:(id)aSender
{
    var index   = [[_tableVirtualMachines selectedRowIndexes] firstIndex],
        vm      = [_virtualMachinesDatasource objectAtIndex:index];

    if (![[[TNStropheIMClient defaultClient] roster] containsJID:[vm JID]])
    {
        var alert = [TNAlert alertWithMessage:@"Adding contact"
                                    informative:@"Would you like to add " + [vm nickname] + @" to your roster"
                                     target:self
                                     actions:[["Add contact", @selector(performAddToRoster:)], ["Cancel", nil]]];
        [alert setUserInfo:vm];
        [alert runModal];
    }
}

/*! open the new virtual machine window
    @param sender the sender of the action
*/
- (IBAction)addVirtualMachine:(id)aSender
{
    [fieldNewVMRequestedName setStringValue:@""];
    [windowNewVirtualMachine center];
    [windowNewVirtualMachine makeKeyAndOrderFront:nil];
}

/*! alloc a new virtual machine
    @param sender the sender of the action
*/
- (IBAction)alloc:(id)aSender
{
    [self alloc];
}

/*! delete selected virtual machines
    @param sender the sender of the action
*/
- (IBAction)deleteVirtualMachine:(id)aSender
{
    [self deleteVirtualMachine];
}

/*! clone selected virtual machine
    @param sender the sender of the action
*/
- (IBAction)cloneVirtualMachine:(id)aSender
{
    [self cloneVirtualMachine]
}

/*! open the add subscription window
    @param sender the sender of the action
*/
- (IBAction)openAddSubscriptionWindow:(id)aSender
{
    [fieldNewSubscriptionTarget setStringValue:@""];
    [windowNewSubscription center];
    [windowNewSubscription makeKeyAndOrderFront:aSender];
}

/*! add subscription to selected virtual machine
    @param sender the sender of the action
*/
- (IBAction)addSubscription:(id)aSender
{
    [self addSubscription];
}

/*! open the add subscription window
    @param sender the sender of the action
*/
- (IBAction)openRemoveSubscriptionWindow:(id)aSender
{
    [fieldRemoveSubscriptionTarget setStringValue:@""];
    [windowRemoveSubscription center];
    [windowRemoveSubscription makeKeyAndOrderFront:aSender];
}

/*! remove subscription from selected virtual machine
    @param sender the sender of the action
*/
- (IBAction)removeSubscription:(id)aSender
{
    [self removeSubscription];
}

#pragma mark -
#pragma mark XMPP Controls

/*! add given given virtual machine to roster
    @param someUserInfo info from TNAlert
*/
- (void)performAddToRoster:(id)someUserInfo
{
    var vm = someUserInfo;

    [[[TNStropheIMClient defaultClient] roster] addContact:[vm JID] withName:[vm nickname] inGroupWithPath:nil];
    [[[TNStropheIMClient defaultClient] roster] askAuthorizationTo:[vm JID]];
    [[[TNStropheIMClient defaultClient] roster] authorizeJID:[vm JID]];
}

/*! get the hypervisor roster content
*/
- (void)getHypervisorRoster
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlRosterVM}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorRoster:) ofObject:self];
}

/*! compute the answer of the hypervisor about its roster
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didReceiveHypervisorRoster:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var queryItems  = [aStanza childrenWithName:@"item"],
            center      = [CPNotificationCenter defaultCenter];

        [_virtualMachinesDatasource removeAllObjects];

        for (var i = 0; i < [queryItems count]; i++)
        {
            var JID     = [TNStropheJID stropheJIDWithString:[[queryItems objectAtIndex:i] text]],
                entry   = [[[TNStropheIMClient defaultClient] roster] contactWithBareJID:JID];

            if (entry)
            {
               if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[entry vCard]] == TNArchipelEntityTypeVirtualMachine)
               {
                   [_virtualMachinesDatasource addObject:entry];
                   [center addObserver:self selector:@selector(_didChangeVMStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];
               }
            }
            else
            {
                var contact = [TNStropheContact contactWithConnection:nil JID:JID group:nil];
                [contact setNickname:[JID node]];
                [_virtualMachinesDatasource addObject:contact];
            }
        }

        [_tableVirtualMachines reloadData];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
        [self setModuleStatus:TNArchipelModuleStatusError];
    }

    return NO;
}

/*! alloc a new virtual machine
*/
- (void)alloc
{
    var stanza  = [TNStropheStanza iqWithType:@"set"];

    [windowNewVirtualMachine orderOut:nil];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlAlloc,
        "name": [fieldNewVMRequestedName stringValue]}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didAllocVirtualMachine:)];

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

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine " + vmJID + @" has been created"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! delete a virtual machine. but ask user if he is sure before
*/
- (void)deleteVirtualMachine
{
    if (([_tableVirtualMachines numberOfRows] == 0) || ([_tableVirtualMachines numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:@"Error" informative:@"You must select a virtual machine"];
         return;
    }

    var msg     = @"Destroying some Virtual Machines",
        title   = @"Are you sure you want to completely remove theses virtual machines ?";

    if ([[_tableVirtualMachines selectedRowIndexes] count] < 2)
    {
        msg     = @"Are you sure you want to completely remove this virtual machine ?";
        title   = @"Destroying a Virtual Machine";
    }

    var alert = [TNAlert alertWithMessage:title
                                informative:msg
                                 target:self
                                 actions:[["Delete", @selector(performDeleteVirtualMachine:)], ["Cancel", nil]]];

    [alert setUserInfo:[_tableVirtualMachines selectedRowIndexes]];

    [alert runModal];
}

/*! delete a virtual machine
*/
- (void)performDeleteVirtualMachine:(id)someUserInfo
{
    var indexes = someUserInfo,
        objects = [_virtualMachinesDatasource objectsAtIndexes:indexes];

    [_tableVirtualMachines deselectAll];

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

        [_entity sendStanza:stanza andRegisterSelector:@selector(_didDeleteVirtualMachine:) ofObject:self];
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

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine has been removed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! remove a virtual machine from the roster
*/
- (void)performRemoveFromRoster:(id)someUserInfo
{
    [[[TNStropheIMClient defaultClient] roster] removeContact:someUserInfo];
}

/*! clone a virtual machine. but ask user if he is sure before
*/
- (void)cloneVirtualMachine
{
    if (([_tableVirtualMachines numberOfRows] == 0)
        || ([_tableVirtualMachines numberOfSelectedRows] <= 0)
        || ([_tableVirtualMachines numberOfSelectedRows] > 1))
    {
         [TNAlert showAlertWithMessage:@"Error" informative:@"You must select one (and only one) virtual machine"];
         return;
    }

    var alert = [TNAlert alertWithMessage:@"Cloning a Virtual Machine"
                                informative:@"Are you sure you want to clone this virtual machine ?"
                                 target:self
                                 actions:[["Clone", @selector(performCloneVirtualMachine:)], ["Cancel", nil]]];
    [alert runModal];

}

/*! delete a virtual machine
*/
- (void)performCloneVirtualMachine:(id)someUserInfo
{
    var index   = [[_tableVirtualMachines selectedRowIndexes] firstIndex],
        vm      = [_virtualMachinesDatasource objectAtIndex:index],
        stanza  = [TNStropheStanza iqWithType:@"set"];

    [_tableVirtualMachines deselectAll];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlClone,
        "jid": [[vm JID] bare]}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didCloneVirtualMachine:) ofObject:self];
}

/*! compute the answer of the hypervisor about its cloning a VM
    @param aStanza TNStropheStanza containing hypervisor answer
*/
- (BOOL)_didCloneVirtualMachine:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        CPLog.info(@"sucessfully cloning a virtual machine");

        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine has been cloned"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! add a new subscription to selected virtual machine
*/
- (void)addSubscription
{
    if (([_tableVirtualMachines numberOfRows] == 0) || ([_tableVirtualMachines numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:@"Error" informative:@"You must select a virtual machine"];
         return;
    }

    var selectedIndex   = [[_tableVirtualMachines selectedRowIndexes] firstIndex],
        vm              = [_virtualMachinesDatasource objectAtIndex:selectedIndex],
        stanza          = [TNStropheStanza iqWithType:@"set"];

    [windowNewSubscription close];

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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Subscription request" message:@"Added new subscription to virtual machine"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


/*! ask vm to remove a subscription. but ask user if he is sure before
*/
- (void)removeSubscription
{
    if (([_tableVirtualMachines numberOfRows] == 0) || ([_tableVirtualMachines numberOfSelectedRows] != 1))
    {
         [TNAlert showAlertWithMessage:@"Error" informative:@"You must select a virtual machine"];
         return;
    }

    var selectedIndex   = [[_tableVirtualMachines selectedRowIndexes] firstIndex],
        vm              = [_virtualMachinesDatasource objectAtIndex:selectedIndex];

    var alert = [TNAlert alertWithMessage:@"Removing subscription"
                                informative:@"Are you sure you want to remove the subscription for this user ?"
                                 target:self
                                 actions:[["Remove", @selector(performRemoveSubscription:)], ["Cancel", nil]]];

    [alert setUserInfo:vm];

    [alert runModal];
}

/*! ask vm to remove a subscription
*/
- (void)performRemoveSubscription:(TNStropheContact)aVirtualMachine
{
    if (([_tableVirtualMachines numberOfRows] == 0) || ([_tableVirtualMachines numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:@"Error" informative:@"You must select a virtual machine"];
         return;
    }

    var stanza = [TNStropheStanza iqWithType:@"set"];

    [windowRemoveSubscription close];

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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Subscription request" message:@"Subscription have been removed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


@end
