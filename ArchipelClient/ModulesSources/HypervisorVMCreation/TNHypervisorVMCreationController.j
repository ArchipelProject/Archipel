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

var TNHypervisorVMCreationControllerLibvirtIcon = nil;

var TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control",
    TNArchipelTypeHypervisorControlRosterVM     = @"rostervm",
    TNArchipelPushNotificationHypervisor        = @"archipel:push:hypervisor",
    TNArchipelPushNotificationHypervisorPark    = @"archipel:push:vmparking";

var TNModuleControlForSubscribe                 = @"Subscribe",
    TNModuleControlForUnSubscribe               = @"UnSubscribe",
    TNModuleControlForNewVM                     = @"NewVM",
    TNModuleControlForClone                     = @"Clone",
    TNModuleControlForEditVcard                 = @"EditVcard",
    TNModuleControlForManage                    = @"Manage",
    TNModuleControlForUnmanage                  = @"Unmanage",
    TNModuleControlForEditXML                   = @"EditXML",
    TNModuleControlForRemove                    = @"Remove",
    TNModuleControlForJump                      = @"Jump",
    TNModuleControlForPark                      = @"Park",
    TNModuleControlForUnpark                    = @"Unpark",
    TNModuleControlForRemoveparked              = @"Removeparked";



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
    [_virtualMachinesDatasource setSearchableKeyPaths:[@"name", @"JID.bare"]];

    [fieldFilterVM setTarget:_virtualMachinesDatasource];
    [fieldFilterVM setAction:@selector(filterObjects:)];
    [tableVirtualMachines setDataSource:_virtualMachinesDatasource];

    // create the control items

    [self addControlsWithIdentifier:TNModuleControlForNewVM
                              title:CPBundleLocalizedString(@"Add a new Virtual Machine", @"Add a new Virtual Machine")
                             target:self
                             action:@selector(openNewVirtualMachineWindow:)
                              image:CPImageInBundle(@"IconsButtons/plus.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForRemove
                              title:CPBundleLocalizedString(@"Remove this Virtual Machine", @"Remove this Virtual Machine")
                             target:self
                             action:@selector(deleteVirtualMachine:)
                              image:CPImageInBundle(@"IconsButtons/minus.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForSubscribe
                              title:CPBundleLocalizedString(@"Add a subsription", @"Add a subsription")
                             target:self
                             action:@selector(openAddSubscriptionWindow:)
                              image:CPImageInBundle(@"IconsButtons/subscription-add.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForUnSubscribe
                              title:CPBundleLocalizedString(@"Remove a subsription", @"Remove a subsription")
                             target:self
                             action:@selector(openRemoveSubscriptionWindow:)
                              image:CPImageInBundle(@"IconsButtons/subscription-remove.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForClone
                              title:CPBundleLocalizedString(@"Clone this Virtual Machine", @"Clone this Virtual Machine")
                             target:self
                             action:@selector(openCloneVirtualMachineWindow:)
                              image:CPImageInBundle(@"IconsButtons/branch.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForUnmanage
                              title:CPBundleLocalizedString(@"Unmanage this Virtual Machine", @"Unmanage this Virtual Machine")
                             target:self
                             action:@selector(unmanageVirtualMachine:)
                              image:CPImageInBundle(@"IconsButtons/unmanage.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForPark
                              title:CPBundleLocalizedString(@"Park this Virtual Machine", @"Park this Virtual Machine")
                             target:self
                             action:@selector(parkVirtualMachines:)
                              image:CPImageInBundle(@"park.png",nil, [CPBundle bundleForClass:[self class]])];

    [self addControlsWithIdentifier:TNModuleControlForJump
                              title:CPBundleLocalizedString(@"Jump to this Virtual Machine", @"Jump to this Virtual Machine")
                             target:self
                             action:@selector(addSelectedVMToRoster:)
                              image:CPImageInBundle(@"jump.png",nil, [CPBundle bundleForClass:[self class]])];

    [self addControlsWithIdentifier:TNModuleControlForEditVcard
                              title:CPBundleLocalizedString(@"Edit Virtual Machine informations", @"Edit Virtual Machine informations")
                             target:self
                             action:@selector(openEditVirtualMachineWindow:)
                              image:CPImageInBundle(@"IconsButtons/edit.png",nil, [CPBundle mainBundle])];

    [[self buttonWithIdentifier:TNModuleControlForRemove] setEnabled:NO];
    [[self buttonWithIdentifier:TNModuleControlForSubscribe] setEnabled:NO];
    [[self buttonWithIdentifier:TNModuleControlForUnSubscribe] setEnabled:NO];

    [buttonBarControl setButtons:[
        [self buttonWithIdentifier:TNModuleControlForNewVM],
        [self buttonWithIdentifier:TNModuleControlForRemove],
        [self buttonWithIdentifier:TNModuleControlForClone],
        [self buttonWithIdentifier:TNModuleControlForEditVcard],
        [self buttonWithIdentifier:TNModuleControlForSubscribe],
        [self buttonWithIdentifier:TNModuleControlForUnSubscribe],
        [self buttonWithIdentifier:TNModuleControlForUnmanage],
        [self buttonWithIdentifier:TNModuleControlForPark],
        [self buttonWithIdentifier:TNModuleControlForJump]]];

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

    [self addControlsWithIdentifier:TNModuleControlForManage
                              title:CPBundleLocalizedString(@"Manage this Virtual Machine", @"Manage this Virtual Machine")
                             target:self
                             action:@selector(manageVirtualMachine:)
                              image:CPImageInBundle(@"IconsButtons/manage.png",nil, [CPBundle mainBundle])];

    [buttonBarNotManagedVMControl setButtons:[[self buttonWithIdentifier:TNModuleControlForManage]]];

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

    [self addControlsWithIdentifier:TNModuleControlForUnpark
                              title:CPBundleLocalizedString(@"Unpark this Virtual Machine", @"Unpark this Virtual Machine")
                             target:self
                             action:@selector(unparkVirtualMachines:)
                              image:CPImageInBundle(@"unpark.png",nil, [CPBundle bundleForClass:[self class]])];

    [self addControlsWithIdentifier:TNModuleControlForEditXML
                              title:CPBundleLocalizedString(@"Edit this Virtual Machine XML definition", @"Edit this Virtual Machine XML definition")
                             target:self
                             action:@selector(openParkedXMLEditor:)
                              image:CPImageInBundle(@"IconsButtons/editxml.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForRemoveparked
                              title:CPBundleLocalizedString(@"Delete this parked Virtual Machine", @"Delete this parked Virtual Machine")
                             target:self
                             action:@selector(deleteParkedVirtualMachines:)
                              image:CPImageInBundle(@"IconsButtons/minus.png",nil, [CPBundle mainBundle])];

    [buttonBarParkedVMControl setButtons:[
        [self buttonWithIdentifier:TNModuleControlForUnpark],
        [self buttonWithIdentifier:TNModuleControlForEditXML],
        [self buttonWithIdentifier:TNModuleControlForRemoveparked]]];

    [VMAllocationController setDelegate:self];
    [VMSubscriptionController setDelegate:self];
    [VMCloneController setDelegate:self];
    [VMManagerController setDelegate:self];
    [VMParkingController setDelegate:self];

    TNHypervisorVMCreationControllerLibvirtIcon = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"libvirt-icon.png"]];
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

    [self setControl:[self buttonWithIdentifier:TNModuleControlForManage] enabledAccordingToPermission:@"manage" specialCondition:tableNotManagedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForUnmanage] enabledAccordingToPermission:@"unmanage" specialCondition:tableManagedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForPark] enabledAccordingToPermission:@"vmparking_park" specialCondition:tableManagedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForUnpark] enabledAccordingToPermission:@"vmparking_unpark" specialCondition:tableParkedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForEditXML] enabledAccordingToPermission:@"vmparking_updatexml" specialCondition:tableParkedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForRemoveparked] enabledAccordingToPermission:@"vmparking_delete" specialCondition:tableParkedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForNewVM] enabledAccordingToPermission:@"alloc"];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForEditVcard] enabledAccordingToPermission:@"alloc" specialCondition:tableManagedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForRemove] enabledAccordingToPermission:@"free" specialCondition:tableManagedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForClone] enabledAccordingToPermission:@"clone" specialCondition:tableManagedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForSubscribe] enabledAccordingToPermission:@"subscription_add" specialCondition:tableManagedCondition];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForUnSubscribe] enabledAccordingToPermission:@"subscription_remove" specialCondition:tableManagedCondition];

    [[self buttonWithIdentifier:TNModuleControlForJump] setEnabled:[tableVirtualMachines numberOfSelectedRows] == 1];

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
            [[self buttonWithIdentifier:TNModuleControlForRemove] setEnabled:NO];
            [[self buttonWithIdentifier:TNModuleControlForEditVcard] setEnabled:NO];
            [[self buttonWithIdentifier:TNModuleControlForClone] setEnabled:NO];
            [[self buttonWithIdentifier:TNModuleControlForUnmanage] setEnabled:NO];
            [[self buttonWithIdentifier:TNModuleControlForPark] setEnabled:NO];
            [[self buttonWithIdentifier:TNModuleControlForSubscribe] setEnabled:NO];
            [[self buttonWithIdentifier:TNModuleControlForUnSubscribe] setEnabled:NO];
            [[self buttonWithIdentifier:TNModuleControlForJump] setEnabled:[tableVirtualMachines numberOfSelectedRows] == 1];

            var condition = ([tableVirtualMachines numberOfSelectedRows] > 0);
            [self setControl:[self buttonWithIdentifier:TNModuleControlForEditVcard] enabledAccordingToPermission:@"alloc" specialCondition:condition];
            [self setControl:[self buttonWithIdentifier:TNModuleControlForRemove] enabledAccordingToPermission:@"free" specialCondition:condition];
            [self setControl:[self buttonWithIdentifier:TNModuleControlForClone] enabledAccordingToPermission:@"clone" specialCondition:condition];
            [self setControl:[self buttonWithIdentifier:TNModuleControlForSubscribe] enabledAccordingToPermission:@"subscription_add" specialCondition:condition];
            [self setControl:[self buttonWithIdentifier:TNModuleControlForUnSubscribe] enabledAccordingToPermission:@"subscription_remove" specialCondition:condition];
            [self setControl:[self buttonWithIdentifier:TNModuleControlForUnmanage] enabledAccordingToPermission:@"unmanage" specialCondition:condition];
            [self setControl:[self buttonWithIdentifier:TNModuleControlForPark] enabledAccordingToPermission:@"vmparking_park" specialCondition:condition];

        case tableVirtualMachinesNotManaged:
            [[self buttonWithIdentifier:TNModuleControlForManage] setEnabled:NO];
            var condition = ([tableVirtualMachinesNotManaged numberOfSelectedRows] > 0);
            [self setControl:[self buttonWithIdentifier:TNModuleControlForManage] enabledAccordingToPermission:@"manage" specialCondition:condition];

        case tableVirtualMachinesParked:
            [[self buttonWithIdentifier:TNModuleControlForUnpark] setEnabled:NO];
            [[self buttonWithIdentifier:TNModuleControlForEditXML] setEnabled:NO];
            [[self buttonWithIdentifier:TNModuleControlForRemoveparked] setEnabled:NO];
            var condition = ([tableVirtualMachinesParked numberOfSelectedRows] > 0);
            [self setControl:[self buttonWithIdentifier:TNModuleControlForUnpark] enabledAccordingToPermission:@"vmparking_unpark" specialCondition:condition];
            [self setControl:[self buttonWithIdentifier:TNModuleControlForEditXML] enabledAccordingToPermission:@"vmparking_updatexml" specialCondition:condition];
            [self setControl:[self buttonWithIdentifier:TNModuleControlForRemoveparked] enabledAccordingToPermission:@"vmparking_delete" specialCondition:condition];
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

/*! add vm to roster if not present or go to virtual machine
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
                                    informative:CPBundleLocalizedString(@"Would you like to add ", @"Would you like to add ") + [vm name] + CPBundleLocalizedString(@" to your roster", @" to your roster")
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

/*! manage the selected virtual machine
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
    [VMParkingController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableVirtualMachinesParked : aSender];
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

    var titleMessage = CPLocalizedString("Unmanage virtual machine", "Unmanage virtual machine"),
        informativeMessage = CPLocalizedString(@"Are you sure you want Archipel to unmanage this virtual machine?", @"Are you sure you want Archipel to unmanage this virtual machine?");

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

    [VMCloneController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableVirtualMachines : aSender];
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
        [VMAllocationController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableVirtualMachines : aSender];
    }
}

/*! open the edit virtual machine window
    @param sender the sender of the action
*/
- (IBAction)openEditVirtualMachineWindow:(id)aSender
{
    if (![[_virtualMachinesDatasource objectAtIndex:[tableVirtualMachines selectedRow]] vCard])
    {
        [self addSelectedVMToRoster:aSender];
        return;
    }

    [self requestVisible];

    if ([self isVisible])
    {
        var vm = [_virtualMachinesDatasource objectAtIndex:[tableVirtualMachines selectedRow]];
        [VMAllocationController setVirtualMachine:vm];
        [VMAllocationController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableVirtualMachines : aSender];
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

    [VMSubscriptionController openAddSubsctiptionWindow:([aSender isKindOfClass:CPMenuItem]) ? tableVirtualMachines : aSender];
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

    [VMSubscriptionController openRemoveSubscriptionWindow:([aSender isKindOfClass:CPMenuItem]) ? tableVirtualMachines : aSender];
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
        var queryItems  = [aStanza childrenWithName:@"item"];

        [_virtualMachinesDatasource removeAllObjects];
        [_virtualMachinesNotManagedDatasource removeAllObjects];
        for (var i = 0; i < [queryItems count]; i++)
        {
            var JID = [TNStropheJID stropheJIDWithString:[[queryItems objectAtIndex:i] text]];

            if ([[queryItems objectAtIndex:i] valueForAttribute:@"managed"] == "True")
            {
                var entry = [[[TNStropheIMClient defaultClient] roster] contactWithBareJID:JID];
                if (entry)
                {
                    if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[entry vCard]] != TNArchipelEntityTypeVirtualMachine)
                        [entry getVCard];

                    [_virtualMachinesDatasource addObject:entry];

                    [[CPNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(populateVirtualMachinesTable:)
                                                                 name:TNStropheContactVCardReceivedNotification
                                                               object:entry];

                    [[CPNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(_didChangeVMStatus:)
                                                                 name:TNStropheContactPresenceUpdatedNotification
                                                               object:entry];
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

                [contact setNickname:name];
                [contact setAvatar:TNHypervisorVMCreationControllerLibvirtIcon];

                [_virtualMachinesNotManagedDatasource addObject:contact];
            }
        }

        [tableVirtualMachines reloadData];
        [tableVirtualMachinesNotManaged reloadData];
        [tableVirtualMachines setSortDescriptors:[[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]]
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

/*! Delegate of CPTableView - This will be called when context menu is triggered with right click
*/
- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow;
{

    if ([aTableView numberOfSelectedRows] > 1)
        return;

    [_contextualMenu removeAllItems];

    if (([aTableView numberOfSelectedRows] == 0) && (aTableView == tableVirtualMachines))
    {
        [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForNewVM]];

        return _contextualMenu;
    }

    switch (aTableView)
    {
        case tableVirtualMachines:
            var itemRow = [tableVirtualMachines rowAtPoint:aRow];
            if ([tableVirtualMachines selectedRow] != aRow)
                [tableVirtualMachines selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];

            if ([[_virtualMachinesDatasource objectAtIndex:[tableVirtualMachines selectedRow]] vCard])
                {
                    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForJump]];
                    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForClone]];
                    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForEditVcard]];
                    [_contextualMenu addItem:[CPMenuItem separatorItem]];
                    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForSubscribe]];
                    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForUnSubscribe]];
                    [_contextualMenu addItem:[CPMenuItem separatorItem]];
                    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForUnmanage]];
                    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForRemove]];
                }
            else
                {
                    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForJump]];
                }
            break;

        case tableVirtualMachinesNotManaged:
            var itemRow = [tableVirtualMachinesNotManaged rowAtPoint:aRow];
            if ([tableVirtualMachinesNotManaged selectedRow] != aRow)
                [tableVirtualMachinesNotManaged selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];

            [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForManage]];
            break;

        case tableVirtualMachinesParked:
            var itemRow = [tableVirtualMachinesParked rowAtPoint:aRow];
            if ([tableVirtualMachinesParked selectedRow] != aRow)
                [tableVirtualMachinesParked selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];
            [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForUnpark]];
            [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForEditXML]];
            [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForRemoveparked]];
            break;

        default:
            return;
    }

    return _contextualMenu;
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNHypervisorVMCreationController], comment);
}
