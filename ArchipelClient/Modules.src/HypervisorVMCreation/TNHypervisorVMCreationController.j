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

TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control";
TNArchipelTypeHypervisorControlAlloc        = @"alloc";
TNArchipelTypeHypervisorControlFree         = @"free";
TNArchipelTypeHypervisorControlRosterVM     = @"rostervm";
TNArchipelTypeHypervisorControlClone        = @"clone";

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
    @outlet CPTextField     fieldNewVMRequestedName;
    @outlet CPView          viewTableContainer;
    @outlet CPWindow        windowNewVirtualMachine;

    CPButton                _cloneButton;
    CPButton                _minusButton;
    CPButton                _plusButton;
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

    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(deleteVirtualMachine:)];

    [_minusButton setEnabled:NO];

    _cloneButton = [CPButtonBar minusButton];
    [_cloneButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-branch.png"] size:CPSizeMake(16, 16)]];
    [_cloneButton setTarget:self];
    [_cloneButton setAction:@selector(cloneVirtualMachine:)];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _cloneButton]];

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
    [center addObserver:self selector:@selector(_reload:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [_tableVirtualMachines setDelegate:nil];
    [_tableVirtualMachines setDelegate:self]; // hum....

    [self getHypervisorRoster];
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
- (void)willShow
{
    [super willShow];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
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

    [self getHypervisorRoster];

    return YES;
}

/*! reload the content of the table when contact add or presence changes
    @param aNotification the notification
*/
- (void)_reload:(CPNotification)aNotification
{
    if ([_entity XMPPShow] != TNStropheContactStatusOffline)
        [self getHypervisorRoster];
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

    if ([[aNotification object] numberOfSelectedRows] > 0)
    {
        [_minusButton setEnabled:YES];
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

    if ([_roster containsJID:[vm JID]])
    {
        var row             = [[_roster mainOutlineView] rowForItem:vm],
            indexes         = [CPIndexSet indexSetWithIndex:row];

        [[_roster mainOutlineView] selectRowIndexes:indexes byExtendingSelection:NO];
    }
    else
    {
        var alert = [TNAlert alertWithTitle:@"Adding contact"
                                    message:@"Would you like to add " + [vm nickname] + @" to your roster"
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


#pragma mark -
#pragma mark XMPP Controls

/*! add given given virtual machine to roster
    @param someUserInfo info from TNAlert
*/
- (void)performAddToRoster:(id)someUserInfo
{
    var vm      = someUserInfo;

    [_roster addContact:[vm JID] withName:[vm nickname] inGroupWithName:@"General"];
    [_roster askAuthorizationTo:[vm JID]];
    [_roster authorizeJID:[vm JID]];
}

/*! get the hypervisor roster content
*/
- (void)getHypervisorRoster
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlRosterVM}];

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
            var JID     = [[queryItems objectAtIndex:i] text],
                entry   = [_roster contactWithJID:JID];

            if (entry)
            {
               if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
               {
                   [_virtualMachinesDatasource addObject:entry];
                   [center addObserver:self selector:@selector(_didChangeVMStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];
               }
            }
            else
            {
                var contact = [TNStropheContact contactWithConnection:nil JID:JID groupName:@"nogroup"];
                [[contact resources] addObject:JID.split('/')[1]];
                [_virtualMachinesDatasource addObject:contact];
            }
        }

        [_tableVirtualMachines reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
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
         [CPAlert alertWithTitle:@"Error" message:@"You must select a virtual machine"];
         return;
    }

    var msg     = @"Destroying some Virtual Machines",
        title   = @"Are you sure you want to completely remove theses virtual machines ?";

    if ([[_tableVirtualMachines selectedRowIndexes] count] < 2)
    {
        msg     = @"Are you sure you want to completely remove this virtual machine ?";
        title   = @"Destroying a Virtual Machine";
    }

    var alert = [TNAlert alertWithTitle:title
                                message:msg
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

        [_roster removeContact:vm];

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
    [_roster removeContactWithJID:[someUserInfo JID]];
}

/*! clone a virtual machine. but ask user if he is sure before
*/
- (void)cloneVirtualMachine
{
    if (([_tableVirtualMachines numberOfRows] == 0)
        || ([_tableVirtualMachines numberOfSelectedRows] <= 0)
        || ([_tableVirtualMachines numberOfSelectedRows] > 1))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select one (and only one) virtual machine"];
         return;
    }

    var alert = [TNAlert alertWithTitle:@"Cloning a Virtual Machine"
                                message:@"Are you sure you want to clone this virtual machine ?"
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
        "jid": [vm JID]}];

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

@end
