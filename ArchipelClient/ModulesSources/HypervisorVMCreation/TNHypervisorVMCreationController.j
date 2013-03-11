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
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTabViewItem.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>

@import "../../Model/TNModule.j"
@import "TNVirtualMachineAllocationController.j"
@import "TNVirtualMachineCloneController.j"
@import "TNVirtualMachineDataView.j"
@import "TNVirtualMachineManageController.j"
@import "TNVirtualMachineParkedDataView.j"
@import "TNVirtualMachineParkingController.j"
@import "TNVirtualMachineSubscriptionController.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNArchipelEntityTypeVirtualMachine
@global TNArchipelRosterOutlineViewSelectItemNotification


var TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control",
    TNArchipelTypeHypervisorControlRosterVM     = @"rostervm",
    TNArchipelPushNotificationHypervisor        = @"archipel:push:hypervisor",
    TNArchipelPushNotificationHypervisorPark    = @"archipel:push:vmparking";

/*! @defgroup  hypervisorvmcreation Module Hypervisor VM Creation
    @desc This module allow to create and delete virtual machines
*/

/*! @ingroup hypervisorvmcreation
    Main controller of the module
*/
@implementation TNHypervisorVMCreationController : TNModule
{
    @outlet CPButtonBar                             buttonBarControl;
    @outlet CPButtonBar                             buttonBarNotManagedVMControl;
    @outlet CPButtonBar                             buttonBarParkedVMControl;
    @outlet CPPopUpButton                           popupDeleteMachine;
    @outlet CPSearchField                           fieldFilterVM;
    @outlet CPSearchField                           fieldFilterVMNotManaged;
    @outlet CPSearchField                           fieldFilterVMParked;
    @outlet CPTableView                             tableVirtualMachines            @accessors(readonly);
    @outlet CPTableView                             tableVirtualMachinesNotManaged;
    @outlet CPTableView                             tableVirtualMachinesParked      @accessors(readonly);
    @outlet CPTabView                               tabViewVMs;
    @outlet CPView                                  viewItemManagedVMs;
    @outlet CPView                                  viewItemNotManagedVMs;
    @outlet CPView                                  viewItemParkedVMs;
    @outlet CPView                                  viewTableContainer;
    @outlet CPView                                  viewTableContainerNotManaged;
    @outlet CPView                                  viewTableContainerParked;
    @outlet TNVirtualMachineAllocationController    VMAllocationController;
    @outlet TNVirtualMachineCloneController         VMCloneController;
    @outlet TNVirtualMachineDataView                dataViewVMPrototype;
    @outlet TNVirtualMachineManageController        VMManagerController;
    @outlet TNVirtualMachineParkedDataView          dataViewParkedVMPrototype;
    @outlet TNVirtualMachineParkingController       VMParkingController;
    @outlet TNVirtualMachineSubscriptionController  VMSubscriptionController;

    CPButton                                        _addSubscriptionButton;
    CPButton                                        _cloneButton;
    CPButton                                        _editParkedXMLButton;
    CPButton                                        _manageButton;
    CPButton                                        _minusButton;
    CPButton                                        _parkButton;
    CPButton                                        _parkDeleteButton;
    CPButton                                        _plusButton;
    CPButton                                        _removeSubscriptionButton;
    CPButton                                        _jumpButton;
    CPButton                                        _unmanageButton;
    CPButton                                        _unparkButton;
    TNTableViewDataSource                           _virtualMachinesDatasource;
    TNTableViewDataSource                           _virtualMachinesNotManagedDatasource;
    TNTableViewDataSource                           _virtualMachinesParkedDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];
    [viewTableContainerNotManaged setBorderedWithHexColor:@"#C0C7D2"];
    [viewTableContainerParked setBorderedWithHexColor:@"#C0C7D2"];

    // tab view
    var tabViewItemManagedVM = [[CPTabViewItem alloc] initWithIdentifier:@"tabViewItemManagedVM"],
        tabViewItemNotManagedVM = [[CPTabViewItem alloc] initWithIdentifier:@"tabViewItemNotManagedVM"],
        tabViewItemParkedVM = [[CPTabViewItem alloc] initWithIdentifier:@"tabViewItemParkedVM"];

    [tabViewItemManagedVM setLabel:CPLocalizedString(@"Archipel VMs", @"Archipel VMs")];
    [tabViewItemManagedVM setView:viewItemManagedVMs];

    [tabViewItemNotManagedVM setLabel:CPLocalizedString(@"Others VMs", @"Others VMs")];
    [tabViewItemNotManagedVM setView:viewItemNotManagedVMs];

    [tabViewItemParkedVM setLabel:CPLocalizedString(@"Parked VMs", @"Parked VMs")];
    [tabViewItemParkedVM setView:viewItemParkedVMs];

    [tabViewVMs addTabViewItem:tabViewItemManagedVM];
    [tabViewVMs addTabViewItem:tabViewItemNotManagedVM];
    [tabViewVMs addTabViewItem:tabViewItemParkedVM];
    [tabViewVMs setDelegate:self];

    // VM table view
    _virtualMachinesDatasource   = [[TNTableViewDataSource alloc] init];
    [tableVirtualMachines setDelegate:self];
    [tableVirtualMachines setTarget:self];
    [tableVirtualMachines setDoubleAction:@selector(openEditVirtualMachineWindow:)];
    [[tableVirtualMachines tableColumnWithIdentifier:@"self"] setDataView:[dataViewVMPrototype duplicate]];
    [tableVirtualMachines setBackgroundColor:TNArchipelDefaultColorsTableView];

    [_virtualMachinesDatasource setTable:tableVirtualMachines];
    [_virtualMachinesDatasource setSearchableKeyPaths:[@"nickname", @"JID.bare"]];

    [fieldFilterVM setTarget:_virtualMachinesDatasource];
    [fieldFilterVM setAction:@selector(filterObjects:)];
    [tableVirtualMachines setDataSource:_virtualMachinesDatasource];

    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(openNewVirtualMachineWindow:)];
    [_plusButton setToolTip:CPBundleLocalizedString(@"Add a new VM", @"Add a new VM")]

    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(deleteVirtualMachine:)];
    [_minusButton setToolTip:CPBundleLocalizedString(@"Remove completely selected vms", @"Remove completely selected vms")];

    _addSubscriptionButton = [CPButtonBar plusButton];
    [_addSubscriptionButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/subscription-add.png"] size:CGSizeMake(16, 16)]];
    [_addSubscriptionButton setTarget:self];
    [_addSubscriptionButton setAction:@selector(openAddSubscriptionWindow:)];
    [_addSubscriptionButton setToolTip:CPBundleLocalizedString(@"VM will ask subscription to given user", @"VM will ask subscription to given user")];

    _removeSubscriptionButton = [CPButtonBar plusButton];
    [_removeSubscriptionButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/subscription-remove.png"] size:CGSizeMake(16, 16)]];
    [_removeSubscriptionButton setTarget:self];
    [_removeSubscriptionButton setAction:@selector(openRemoveSubscriptionWindow:)];
    [_removeSubscriptionButton setToolTip:CPBundleLocalizedString(@"VM will remove subscription from given user", @"VM will remove subscription from given user")];

    _cloneButton = [CPButtonBar minusButton];
    [_cloneButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/branch.png"] size:CGSizeMake(16, 16)]];
    [_cloneButton setTarget:self];
    [_cloneButton setAction:@selector(openCloneVirtualMachineWindow:)];
    [_cloneButton setToolTip:CPBundleLocalizedString(@"Clone selected VM", @"Clone selected VM")];

    [_minusButton setEnabled:NO];
    [_addSubscriptionButton setEnabled:NO];
    [_removeSubscriptionButton setEnabled:NO];

    _unmanageButton = [CPButtonBar minusButton];
    [_unmanageButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/unmanage.png"] size:CGSizeMake(16, 16)]];
    [_unmanageButton setTarget:self];
    [_unmanageButton setAction:@selector(unmanageVirtualMachine:)];
    [_unmanageButton setEnabled:NO];
    [_unmanageButton setToolTip:CPBundleLocalizedString(@"Do not use Archipel to manage selected vms. Vms will still be there", @"Do not use Archipel to manage selected vms. Vms will still be there")];

    _parkButton = [CPButtonBar plusButton];
    [_parkButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"park.png"] size:CGSizeMake(16, 16)]];
    [_parkButton setTarget:self];
    [_parkButton setAction:@selector(parkVirtualMachines:)];
    [_parkButton setEnabled:NO];
    [_parkButton setToolTip:CPBundleLocalizedString(@"Park selected VMs", @"Park selected VMs")];

    _jumpButton = [CPButtonBar plusButton];
    [_jumpButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"jump.png"] size:CGSizeMake(16, 16)]];
    [_jumpButton setTarget:self];
    [_jumpButton setAction:@selector(addSelectedVMToRoster:)];
    [_jumpButton setEnabled:NO];
    [_jumpButton setToolTip:CPBundleLocalizedString(@"If vm is in roster, jump to it, otherwhise, ask subscription", @"If vm is in roster, jump to it, otherwhise, ask subscription")];


    [buttonBarControl setButtons:[_plusButton, _minusButton, _cloneButton, _addSubscriptionButton, _removeSubscriptionButton, _unmanageButton, _parkButton, _jumpButton]];

    // Not managed VM Table View
    _virtualMachinesNotManagedDatasource = [[TNTableViewDataSource alloc] init];
    [tableVirtualMachinesNotManaged setDelegate:self];
    [tableVirtualMachinesNotManaged setTarget:self];
    [tableVirtualMachinesNotManaged setDoubleAction:@selector(didNotManagedTableDoubleClick:)];
    [[tableVirtualMachinesNotManaged tableColumnWithIdentifier:@"self"] setDataView:[dataViewVMPrototype duplicate]];
    [tableVirtualMachinesNotManaged setBackgroundColor:TNArchipelDefaultColorsTableView];

    [_virtualMachinesNotManagedDatasource setTable:tableVirtualMachinesNotManaged];
    [_virtualMachinesNotManagedDatasource setSearchableKeyPaths:[@"JID.bare"]];

    [fieldFilterVMNotManaged setTarget:_virtualMachinesNotManagedDatasource];
    [fieldFilterVMNotManaged setAction:@selector(filterObjects:)];
    [tableVirtualMachinesNotManaged setDataSource:_virtualMachinesNotManagedDatasource];

    _manageButton = [CPButtonBar plusButton];
    [_manageButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/manage.png"] size:CGSizeMake(16, 16)]];
    [_manageButton setTarget:self];
    [_manageButton setAction:@selector(manageVirtualMachine:)];
    [_manageButton setEnabled:NO];
    [_manageButton setToolTip:CPBundleLocalizedString(@"Make Archipel manage selected VMs", @"Make Archipel manage selected VMs")]

    [buttonBarNotManagedVMControl setButtons:[_manageButton]];


    // Parked VM Table View
    _virtualMachinesParkedDatasource = [[TNTableViewDataSource alloc] init];
    [tableVirtualMachinesParked setDelegate:self];
    [tableVirtualMachinesParked setTarget:self];
    [tableVirtualMachinesParked setDoubleAction:@selector(openParkedXMLEditor:)];
    [[tableVirtualMachinesParked tableColumnWithIdentifier:@"self"] setDataView:[dataViewParkedVMPrototype duplicate]];
    [tableVirtualMachinesParked setBackgroundColor:TNArchipelDefaultColorsTableView];

    [_virtualMachinesParkedDatasource setTable:tableVirtualMachinesParked];
    [_virtualMachinesParkedDatasource setSearchableKeyPaths:[@"name", @"UUID", @"parker"]];

    [fieldFilterVMParked setTarget:_virtualMachinesParkedDatasource];
    [fieldFilterVMParked setAction:@selector(filterObjects:)];
    [tableVirtualMachinesParked setDataSource:_virtualMachinesParkedDatasource];


    _unparkButton = [CPButtonBar plusButton];
    [_unparkButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"unpark.png"] size:CGSizeMake(16, 16)]];
    [_unparkButton setTarget:self];
    [_unparkButton setAction:@selector(unparkVirtualMachines:)];
    [_unparkButton setEnabled:NO];
    [_unparkButton setToolTip:CPBundleLocalizedString(@"Unpark selected VMs into this hypervisor", @"Unpark selected VMs into this hypervisor")];

    _editParkedXMLButton = [CPButtonBar plusButton];
    [_editParkedXMLButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/editxml.png"] size:CGSizeMake(16, 16)]];
    [_editParkedXMLButton setTarget:self];
    [_editParkedXMLButton setAction:@selector(openParkedXMLEditor:)];
    [_editParkedXMLButton setEnabled:NO];
    [_editParkedXMLButton setToolTip:CPBundleLocalizedString(@"Edit parked VM's XML definition", @"Edit parked VM's XML definition")];

    _parkDeleteButton = [CPButtonBar minusButton];
    [_parkDeleteButton setTarget:self];
    [_parkDeleteButton setAction:@selector(deleteParkedVirtualMachines:)];
    [_parkDeleteButton setEnabled:NO];
    [_parkDeleteButton setToolTip:CPBundleLocalizedString(@"Delete selected parked VMs. All data will be lost", @"Delete selected parked VMs. All data will be lost")]

    [buttonBarParkedVMControl setButtons:[_unparkButton, _editParkedXMLButton, _parkDeleteButton]];

    [VMAllocationController setDelegate:self];
    [VMSubscriptionController setDelegate:self];
    [VMCloneController setDelegate:self];
    [VMManagerController setDelegate:self];
    [VMParkingController setDelegate:self];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [self registerSelector:@selector(_didReceiveParkPush:) forPushNotificationType:TNArchipelPushNotificationHypervisorPark];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_reload:)
                                                 name:TNStropheContactPresenceUpdatedNotification
                                               object:nil];

    [tableVirtualMachines setDelegate:nil];
    [tableVirtualMachines setDelegate:self];
    [tableVirtualMachinesNotManaged setDelegate:nil];
    [tableVirtualMachinesNotManaged setDelegate:self];
    [tableVirtualMachinesParked setDelegate:nil];
    [tableVirtualMachinesParked setDelegate:self];

    // simulate a tab change
    [self tabView:tabViewVMs didSelectTabViewItem:[tabViewVMs selectedTabViewItem]];

    return YES;
}

/*! called when the module hides
*/
- (void)willHide
{
    [VMCloneController closeWindow:nil];
    [VMSubscriptionController closeAddSubscriptionWindow:nil];
    [VMSubscriptionController closeRemoveSubscriptionWindow:nil];
    [VMAllocationController closeWindow:nil];

    [super willHide];
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Create new virtual machine", @"Create new virtual machine") action:@selector(openNewVirtualMachineWindow:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Delete virtual machine", @"Delete virtual machine") action:@selector(deleteVirtualMachine:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Clone this virtual machine", @"Clone this virtual machine") action:@selector(openCloneVirtualMachineWindow:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Add a user subscription", @"Add a user subscription") action:@selector(openAddSubscriptionWindow:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Remove a user subscription", @"Remove a user subscription") action:@selector(openRemoveSubscriptionWindow:) keyEquivalent:@""] setTarget:self];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    [self populateVirtualMachinesTable];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    var tableManagedCondition = ([tableVirtualMachines numberOfSelectedRows] > 0),
        tableNotManagedCondition = ([tableVirtualMachinesNotManaged numberOfSelectedRows] > 0),
        tableParkedCondition = ([tableVirtualMachinesParked numberOfSelectedRows] > 0);

    [self setControl:_manageButton enabledAccordingToPermission:@"manage" specialCondition:tableNotManagedCondition];
    [self setControl:_unmanageButton enabledAccordingToPermission:@"unmanage" specialCondition:tableManagedCondition];
    [self setControl:_parkButton enabledAccordingToPermission:@"vmparking_park" specialCondition:tableManagedCondition];
    [self setControl:_unparkButton enabledAccordingToPermission:@"vmparking_unpark" specialCondition:tableParkedCondition];
    [self setControl:_editParkedXMLButton enabledAccordingToPermission:@"vmparking_updatexml" specialCondition:tableParkedCondition];
    [self setControl:_parkDeleteButton enabledAccordingToPermission:@"vmparking_delete" specialCondition:tableParkedCondition];
    [self setControl:_plusButton enabledAccordingToPermission:@"alloc"];
    [self setControl:_minusButton enabledAccordingToPermission:@"free" specialCondition:tableManagedCondition];
    [self setControl:_cloneButton enabledAccordingToPermission:@"clone" specialCondition:tableManagedCondition];
    [self setControl:_addSubscriptionButton enabledAccordingToPermission:@"subscription_add" specialCondition:tableManagedCondition];
    [self setControl:_removeSubscriptionButton enabledAccordingToPermission:@"subscription_remove" specialCondition:tableManagedCondition];

    [_jumpButton setEnabled:[tableVirtualMachines numberOfSelectedRows] == 1];

    if (![self currentEntityHasPermission:@"alloc"])
        [VMAllocationController closeWindow:nil];

    if (![self currentEntityHasPermission:@"subscription_add"])
        [VMSubscriptionController closeAddSubscriptionWindow:nil];

    if (![self currentEntityHasPermission:@"subscription_remove"])
        [VMSubscriptionController closeRemoveSubscriptionWindow:nil];

    [self tableViewSelectionDidChange:[CPNotification notificationWithName:@"" object:tableVirtualMachinesParked]];
    [self tableViewSelectionDidChange:[CPNotification notificationWithName:@"" object:tableVirtualMachines]];
    [self tableViewSelectionDidChange:[CPNotification notificationWithName:@"" object:tableVirtualMachinesNotManaged]];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_virtualMachinesDatasource removeAllObjects];
    [_virtualMachinesNotManagedDatasource removeAllObjects];
    [_virtualMachinesParkedDatasource removeAllObjects];

    [tableVirtualMachines reloadData];
    [tableVirtualMachinesNotManaged reloadData];
    [tableVirtualMachinesParked reloadData];
}

#pragma mark -
#pragma mark Notification handlers

/*! called when an Archipel push is recieved
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceiveParkPush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"],
        stanza  = [somePushInfo objectForKey:@"rawStanza"];

    var growl = [TNGrowlCenter defaultCenter];
    switch (change)
    {
        case "cannot-park":
            [growl pushNotificationWithTitle:@"Parking error" message:@"Unable to park" icon:TNGrowlIconError];
            CPLog.error(stanza)
            break;

        case "cannot-unpark":
            [growl pushNotificationWithTitle:@"Parking error" message:@"Unable to unpark" icon:TNGrowlIconError];
            CPLog.error(stanza)
            break;

        case "cannot-delete":
            [growl pushNotificationWithTitle:@"Parking error" message:@"Unable to delete" icon:TNGrowlIconError];
            CPLog.error(stanza)
            break;

        case "cannot-update":
            [growl pushNotificationWithTitle:@"Parking error" message:@"Unable to update" icon:TNGrowlIconError];
            CPLog.error(stanza)
            break;

        case "parked":
            [growl pushNotificationWithTitle:@"Parking success" message:@"Parked successfully"];
            break;

        case "unparked":
            [growl pushNotificationWithTitle:@"Parking success" message:@"Unparked successfully"];
            break;

        case "deleted":
            [growl pushNotificationWithTitle:@"Parking success" message:@"Deleted successfully"];
            break;

        case "updated":
            [growl pushNotificationWithTitle:@"Parking success" message:@"Updated successfully"];
            break;

        default:
            if ([[tabViewVMs selectedTabViewItem] identifier] != @"tabViewItemParkedVM")
                [self populateVirtualMachinesTable];
    }

    if ([[tabViewVMs selectedTabViewItem] identifier] == @"tabViewItemParkedVM")
        [VMParkingController listParkedVirtualMachines];

    return YES;
}

/*! reload the content of the table when contact add or presence changes
    @param aNotification the notification
*/
- (void)_reload:(CPNotification)aNotification
{
    if ([_entity XMPPShow] != TNStropheContactStatusOffline)
        if ([[tabViewVMs selectedTabViewItem] identifier] != @"tabViewItemParkedVM")
            [self populateVirtualMachinesTable];
}

/*! reload the content of the table when a roster push is received
    @param aNotification the notification
*/
- (void)populateVirtualMachinesTable:(CPNotification)aNotification
{
    if ([[tabViewVMs selectedTabViewItem] identifier] != @"tabViewItemParkedVM")
        [self populateVirtualMachinesTable];
}

/*! reoload the table when a VM change it's status
    @param aNotification the notification
*/
- (void)_didChangeVMStatus:(CPNotification)aNotif
{
    [tableVirtualMachines reloadData];
    [tableVirtualMachinesNotManaged reloadData];
}

/*! update the GUI according to the selected entity in table
    @param aNotification the notification
*/
- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    switch ([aNotification object])
    {
        case tableVirtualMachines:
            [_minusButton setEnabled:NO];
            [_cloneButton setEnabled:NO];
            [_unmanageButton setEnabled:NO];
            [_parkButton setEnabled:NO];
            [_addSubscriptionButton setEnabled:NO];
            [_removeSubscriptionButton setEnabled:NO];
            [_jumpButton setEnabled:[tableVirtualMachines numberOfSelectedRows] == 1];

            var condition = ([tableVirtualMachines numberOfSelectedRows] > 0);
            [self setControl:_minusButton enabledAccordingToPermission:@"free" specialCondition:condition];
            [self setControl:_cloneButton enabledAccordingToPermission:@"clone" specialCondition:condition];
            [self setControl:_addSubscriptionButton enabledAccordingToPermission:@"subscription_add" specialCondition:condition];
            [self setControl:_removeSubscriptionButton enabledAccordingToPermission:@"subscription_remove" specialCondition:condition];
            [self setControl:_unmanageButton enabledAccordingToPermission:@"unmanage" specialCondition:condition];
            [self setControl:_parkButton enabledAccordingToPermission:@"vmparking_park" specialCondition:condition];

        case tableVirtualMachinesNotManaged:
            [_manageButton setEnabled:NO];
            var condition = ([tableVirtualMachinesNotManaged numberOfSelectedRows] > 0);
            [self setControl:_manageButton enabledAccordingToPermission:@"manage" specialCondition:condition];

        case tableVirtualMachinesParked:
            [_unparkButton setEnabled:NO];
            [_editParkedXMLButton setEnabled:NO];
            [_parkDeleteButton setEnabled:NO];
            var condition = ([tableVirtualMachinesParked numberOfSelectedRows] > 0);
            [self setControl:_unparkButton enabledAccordingToPermission:@"vmparking_unpark" specialCondition:condition];
            [self setControl:_editParkedXMLButton enabledAccordingToPermission:@"vmparking_updatexml" specialCondition:condition];
            [self setControl:_parkDeleteButton enabledAccordingToPermission:@"vmparking_delete" specialCondition:condition];
    }
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
    {
        [self getHypervisorRoster];
    }
    else
    {
        [_virtualMachinesDatasource removeAllObjects];
        [_virtualMachinesNotManagedDatasource removeAllObjects];
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
        [tableVirtualMachines reloadData];
        [tableVirtualMachinesNotManaged reloadData];
    }
}


#pragma mark -
#pragma mark Actions

/*! add double clicked vm to roster if not present or go to virtual machine
    @param sender the sender of the action
*/
- (IBAction)addSelectedVMToRoster:(id)aSender
{
    if ([tableVirtualMachines numberOfSelectedRows] <= 0)
        return;

    var vm = [_virtualMachinesDatasource objectAtIndex:[tableVirtualMachines selectedRow]];

    if (![[[TNStropheIMClient defaultClient] roster] containsJID:[vm JID]])
    {
        var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Adding contact", @"Adding contact")
                                    informative:CPBundleLocalizedString(@"Would you like to add ", @"Would you like to add ") + [vm nickname] + CPBundleLocalizedString(@" to your roster", @" to your roster")
                                     target:self
                                     actions:[[CPBundleLocalizedString(@"Add contact", @"Add contact"), @selector(performAddToRoster:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
        [alert setUserInfo:vm];
        [alert runModal];
    }
    else
    {
        [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelRosterOutlineViewSelectItemNotification object:self userInfo:vm];
    }
}

/*! add double clicked vm to roster if not present or go to virtual machine
    @param sender the sender of the action
*/
- (IBAction)didNotManagedTableDoubleClick:(id)aSender
{
    [self manageVirtualMachine:aSender];
}

/*! Ask the hypervisor to park selected virtual machines
    @param aSender the sender of the action
*/
- (IBAction)parkVirtualMachines:(id)aSender
{
    if ([tableVirtualMachines numberOfSelectedRows] <= 0)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"You must select at least a virtual machine", @"You must select at least a virtual machine")];
        return;
    }

    var titleMessage = CPLocalizedString("Park virtual machine", "Park virtual machine"),
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to park this virtual machine?", @"Are you sure you want Archipel to park this virtual machine?");

    if ([tableVirtualMachines numberOfSelectedRows] > 1)
    {
        titleMessage = CPLocalizedString("Park virtual machines", "Park virtual machines");
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to park these virtual machines?", @"Are you sure you want Archipel to park these virtual machines?");
    }

    var vms = [_virtualMachinesDatasource objectsAtIndexes:[tableVirtualMachines selectedRowIndexes]],
        alert = [TNAlert alertWithMessage:titleMessage
                                informative:informativeMessage
                                 target:VMParkingController
                                 actions:[[CPLocalizedString(@"Park", @"Park"), @selector(parkVirtualMachines:)],
                                          [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
    [alert setUserInfo:vms];
    [alert runModal];
}

/*! Asthe hypervisor to unparke selected virtual machines
    @param aSender the sender of the action
*/
- (IBAction)unparkVirtualMachines:(id)aSender
{
    if ([tableVirtualMachinesParked numberOfSelectedRows] <= 0)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"You must select at least a virtual machine", @"You must select at least a virtual machine")];
        return;
    }

    var titleMessage = CPLocalizedString("Unpark virtual machine", "Unpark virtual machine"),
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to unpark this virtual machine?", @"Are you sure you want Archipel to unpark this virtual machine?");

    if ([tableVirtualMachinesParked numberOfSelectedRows] > 1)
    {
        titleMessage = CPLocalizedString("Unpark virtual machines", "Unpark virtual machines");
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to unpark these virtual machines?", @"Are you sure you want Archipel to unpark these virtual machines?");
    }

    var vms = [_virtualMachinesParkedDatasource objectsAtIndexes:[tableVirtualMachinesParked selectedRowIndexes]],
        alert = [TNAlert alertWithMessage:titleMessage
                                informative:informativeMessage
                                 target:VMParkingController
                                 actions:[[CPLocalizedString(@"Unpark", @"Unpark"), @selector(unparkVirtualMachines:)],
                                          [CPLocalizedString(@"Unpark and start", @"Unpark and start"), @selector(unparkAndStartVirtualMachines:)],
                                          [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
    [alert setUserInfo:vms];
    [alert runModal];
}

/*! Open the XML editor
    @param aSender the sender of the action
*/
- (IBAction)openParkedXMLEditor:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableVirtualMachinesParked numberOfSelectedRows] != 1)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"You must select a virtual machine", @"You must select a virtual machine")];
        return;
    }

    [VMParkingController setCurrentItem:[_virtualMachinesParkedDatasource objectAtIndex:[tableVirtualMachinesParked selectedRow]]];
    [VMParkingController openWindow:aSender];
}

- (IBAction)deleteParkedVirtualMachines:(id)aSender
{
    if ([tableVirtualMachinesParked numberOfSelectedRows] <= 0)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"You must select at least a virtual machine", @"You must select at least a virtual machine")];
        return;
    }

    var titleMessage = CPLocalizedString("Delete parked virtual machine", "Delete parked virtual machine"),
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to delete this parked virtual machine? This will remove everything related to it, including drives", @"Are you sure you want Archipel to delete this parked virtual machine? This will remove everything related to it, including drives");

    if ([tableVirtualMachinesParked numberOfSelectedRows] > 1)
    {
        titleMessage = CPLocalizedString("Delete parked virtual machines", "Delete parked virtual machines");
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to delete these parked virtual machines? This will remove everything related to them, including drives", @"Are you sure you want Archipel to delete these parked virtual machines? This will remove everything related to them, including drives");
    }

    var vms = [_virtualMachinesParkedDatasource objectsAtIndexes:[tableVirtualMachinesParked selectedRowIndexes]],
        alert = [TNAlert alertWithMessage:titleMessage
                                informative:informativeMessage
                                 target:VMParkingController
                                 actions:[[CPLocalizedString(@"Delete", @"Delete"), @selector(deleteParkedVirtualMachines:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
    [alert setUserInfo:vms];
    [alert runModal];
}

/*! ask the hypervisor to manage selected virtual machines
    @param sender the sender of the action
*/
- (IBAction)manageVirtualMachine:(id)aSender
{
    if ([tableVirtualMachinesNotManaged numberOfSelectedRows] <= 0)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"You must select at least a virtual machine", @"You must select at least a virtual machine")];
        return;
    }

    var titleMessage = CPLocalizedString("Manage virtual machine", "Manage virtual machine"),
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to manage this virtual machine?", @"Are you sure you want Archipel to manage this virtual machine?");

    if ([tableVirtualMachinesNotManaged numberOfSelectedRows] > 1)
    {
        titleMessage = CPLocalizedString("Manage virtual machines", "Manage virtual machines");
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to manage these virtual machines?", @"Are you sure you want Archipel to manage these virtual machines?");
    }

    var vms = [_virtualMachinesNotManagedDatasource objectsAtIndexes:[tableVirtualMachinesNotManaged selectedRowIndexes]],
        alert = [TNAlert alertWithMessage:titleMessage
                                informative:informativeMessage
                                 target:VMManagerController
                                 actions:[[CPLocalizedString(@"Manage", @"Manage"), @selector(performManage:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
    [alert setUserInfo:vms];
    [alert runModal];
}

/*! unmanage selected virtual machines
    @param sender the sender of the action
*/
- (IBAction)unmanageVirtualMachine:(id)aSender
{
    if ([tableVirtualMachines numberOfSelectedRows] <= 0)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPLocalizedString(@"You must select at least a virtual machine", @"You must select at least a virtual machine")];
        return;
    }

    var titleMessage = CPLocalizedString("Manage virtual machine", "Manage virtual machine"),
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to manage this virtual machine?", @"Are you sure you want Archipel to manage this virtual machine?");

    if ([tableVirtualMachines numberOfSelectedRows] > 1)
    {
        titleMessage = CPLocalizedString("Unmanage virtual machines", "Umnanage virtual machines");
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to unmanage these virtual machines?", @"Are you sure you want Archipel to unmanage these virtual machines?");
    }

    var vms = [_virtualMachinesDatasource objectsAtIndexes:[tableVirtualMachines selectedRowIndexes]],
        alert = [TNAlert alertWithMessage:titleMessage
                                informative:informativeMessage
                                 target:VMManagerController
                                 actions:[[CPLocalizedString(@"Unmanage", @"Unmanage"), @selector(performUnmanage:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];
    [alert setUserInfo:vms];
    [alert runModal];
}

/*! delete selected virtual machines
    @param sender the sender of the action
*/
- (IBAction)deleteVirtualMachine:(id)aSender
{
    [VMAllocationController deleteVirtualMachine];
}

/*! Opens the clone virtual machine window
    @param sender the sender of the action
*/
- (IBAction)openCloneVirtualMachineWindow:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableVirtualMachines numberOfSelectedRows] != 1)
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select one (and only one) virtual machine", @"You must select one (and only one) virtual machine")];
         return;
    }

    [VMCloneController openWindow:_cloneButton];
}

/*! open the add virtual machine window
    @param sender the sender of the action
*/
- (IBAction)openNewVirtualMachineWindow:(id)aSender
{
    [self requestVisible];

    if ([self isVisible])
    {
        [VMAllocationController setVirtualMachine:nil];
        [VMAllocationController openWindow:_plusButton];
    }
}

/*! open the edit virtual machine window
    @param sender the sender of the action
*/
- (IBAction)openEditVirtualMachineWindow:(id)aSender
{
    [self requestVisible];

    if ([self isVisible])
    {
        var vm = [_virtualMachinesDatasource objectAtIndex:[tableVirtualMachines selectedRow]];
        [VMAllocationController setVirtualMachine:vm];
        [VMAllocationController openWindow:aSender];
    }
}


/*! open the add subscription window
    @param sender the sender of the action
*/
- (IBAction)openAddSubscriptionWindow:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableVirtualMachines numberOfSelectedRows] != 1)
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select one (and only one) virtual machine", @"You must select one (and only one) virtual machine")];
         return;
    }

    [VMSubscriptionController openAddSubsctiptionWindow:_addSubscriptionButton];
}

/*! open the add subscription window
    @param sender the sender of the action
*/
- (IBAction)openRemoveSubscriptionWindow:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([tableVirtualMachines numberOfSelectedRows] != 1)
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                           informative:CPBundleLocalizedString(@"You must select one (and only one) virtual machine", @"You must select one (and only one) virtual machine")];
         return;
    }

    [VMSubscriptionController openRemoveSubscriptionWindow:_removeSubscriptionButton];
}


#pragma mark -
#pragma mark XMPP Controls

/*! add given given virtual machine to roster
    @param someUserInfo info from TNAlert
*/
- (void)performAddToRoster:(id)someUserInfo
{
    var vm = someUserInfo;

    [[[TNStropheIMClient defaultClient] roster] addContact:[vm JID] withName:[[vm JID] bare] inGroupWithPath:nil];
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
    [self sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorRoster:)];
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
        [_virtualMachinesNotManagedDatasource removeAllObjects];
        for (var i = 0; i < [queryItems count]; i++)
        {
            var JID = [TNStropheJID stropheJIDWithString:[[queryItems objectAtIndex:i] text]];

            // @TODO: do not check for nil value later
            // but for the moment, keep compatibility with older version of Agent
            if (![[queryItems objectAtIndex:i] valueForAttribute:@"managed"] || [[queryItems objectAtIndex:i] valueForAttribute:@"managed"] == "True")
            {
                var entry = [[[TNStropheIMClient defaultClient] roster] contactWithBareJID:JID];
                if (entry)
                {
                   if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[entry vCard]] == TNArchipelEntityTypeVirtualMachine)
                   {
                       // Remove any vcard obeserver here
                       [[CPNotificationCenter defaultCenter] removeObserver:self
                                                                    name:TNStropheContactVCardReceivedNotification
                                                                  object:entry];

                       [_virtualMachinesDatasource addObject:entry];
                       [center addObserver:self selector:@selector(_didChangeVMStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];
                   }
                   else
                   {
                       // Maybe it's a VM and it's still configuring its VCARD
                       [[CPNotificationCenter defaultCenter] addObserver:self
                                                                selector:@selector(populateVirtualMachinesTable:)
                                                                    name:TNStropheContactVCardReceivedNotification
                                                                  object:entry];
                   }
                }
                else
                {
                    var contact = [TNStropheContact contactWithConnection:nil JID:JID group:nil],
                        name = [[queryItems objectAtIndex:i] valueForAttribute:@"name"];

                    [contact setNickname:name];
                    [_virtualMachinesDatasource addObject:contact];
                }
            }
            else
            {
                var contact = [TNStropheContact contactWithConnection:nil JID:JID group:nil],
                    name = [[queryItems objectAtIndex:i] valueForAttribute:@"name"];

                [contact setNickname: name + @" is not managed by Archipel. Double click on it to manage."];

                [_virtualMachinesNotManagedDatasource addObject:contact];
            }
        }

        [tableVirtualMachines reloadData];
        [tableVirtualMachinesNotManaged reloadData];
        [tableVirtualMachines setSortDescriptors:[[CPSortDescriptor sortDescriptorWithKey:@"nickname" ascending:YES]]]
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
        [self setModuleStatus:TNArchipelModuleStatusError];
    }
    return NO;
}

/*! remove a virtual machine from the roster
*/
- (void)performRemoveFromRoster:(id)someUserInfo
{
    [[[TNStropheIMClient defaultClient] roster] removeContact:someUserInfo];
}


#pragma mark -
#pragma mark Delegates

- (void)tabView:(CPTabView)aTabView didSelectTabViewItem:(CPTabViewItem)anItem
{
    switch ([anItem identifier])
    {
        case @"tabViewItemManagedVM":
        case @"tabViewItemNotManagedVM":
            [self populateVirtualMachinesTable];
            break;

        case @"tabViewItemParkedVM":
            [VMParkingController listParkedVirtualMachines];
            break;
    }
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNHypervisorVMCreationController], comment);
}
