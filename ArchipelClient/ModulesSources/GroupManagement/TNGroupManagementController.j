/*
 * TNSampleTabModule.j
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

@import <AppKit/CPButtonBar.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <StropheCappuccino/TNStropheContact.j>
@import <StropheCappuccino/TNStropheIMClient.j>
@import <StropheCappuccino/TNStropheStanza.j>
@import <TNKit/TNTableViewDataSource.j>

@import "../../Model/TNModule.j"
@import "TNGroupedMigrationController.j";

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNArchipelEntityTypeVirtualMachine


var TNArchipelTypeVirtualMachineControl             = @"archipel:vm:control",
    TNArchipelTypeVirtualMachineControlCreate       = @"create",
    TNArchipelTypeVirtualMachineControlShutdown     = @"shutdown",
    TNArchipelTypeVirtualMachineControlDestroy      = @"destroy",
    TNArchipelTypeVirtualMachineControlReboot       = @"reboot",
    TNArchipelTypeVirtualMachineControlSuspend      = @"suspend",
    TNArchipelTypeVirtualMachineControlResume       = @"resume",
    TNArchipelTypeVirtualMachineControlMigrate      = @"migrate",
    TNArchipelActionTypeCreate                      = @"Start",
    TNArchipelActionTypePause                       = @"Pause",
    TNArchipelActionTypeShutdown                    = @"Shutdown",
    TNArchipelActionTypeDestroy                     = @"Destroy",
    TNArchipelActionTypeResume                      = @"Resume",
    TNArchipelActionTypeReboot                      = @"Reboot";

var TNModuleControlForStart                         = @"Start",
    TNModuleControlForPause                         = @"Pause",
    TNModuleControlForResume                        = @"Resume",
    TNModuleControlForShutdown                      = @"Stop",
    TNModuleControlForDestroy                       = @"Destroy",
    TNModuleControlForReboot                        = @"Reboot",
    TNModuleControlForMigrate                       = @"Migrate";

/*! @defgroup  groupmanagement Module Group Management
    @desc This module allows to send controls to a list a virtual machine present in a Roster group
*/

/*! @ingroup groupmanagement
    The main module controller
*/
@implementation TNGroupManagementController : TNModule
{
    @outlet CPButtonBar                     buttonBarControl;
    @outlet CPSearchField                   filterField;
    @outlet CPTableView                     tableVirtualMachines;
    @outlet CPView                          viewTableContainer;
    @outlet TNGroupedMigrationController    groupedMigrationController;

    TNTableViewDataSource                   _datasourceGroupVM;
}


#pragma mark -
#pragma mark Initialization

/*! triggered at cib waking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    _datasourceGroupVM      = [[TNTableViewDataSource alloc] init];

    [tableVirtualMachines setTarget:self];
    [_datasourceGroupVM setTable:tableVirtualMachines];
    [_datasourceGroupVM setSearchableKeyPaths:[@"name", @"JID.bare"]];
    [tableVirtualMachines setDataSource:_datasourceGroupVM];
    [tableVirtualMachines setDelegate:self];

    [self addControlsWithIdentifier:TNModuleControlForStart
                              title:CPBundleLocalizedString(@"Start", @"Start")
                             target:self
                             action:@selector(create:)
                              image:CPImageInBundle(@"IconsButtons/play.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForPause
                              title:CPBundleLocalizedString(@"Pause", @"Pause")
                             target:self
                             action:@selector(suspend:)
                              image:CPImageInBundle(@"IconsButtons/pause.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForResume
                              title:CPBundleLocalizedString(@"Resume", @"Resume")
                             target:self
                             action:@selector(resume:)
                              image:CPImageInBundle(@"IconsButtons/resume.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForShutdown
                              title:CPBundleLocalizedString(@"Shutdown", @"Shutdown")
                             target:self
                             action:@selector(shutdown:)
                              image:CPImageInBundle(@"IconsButtons/stop.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForDestroy
                              title:CPBundleLocalizedString(@"Force Off", @"Force Off")
                             target:self
                             action:@selector(destroy:)
                              image:CPImageInBundle(@"IconsButtons/destroy.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForReboot
                              title:CPBundleLocalizedString(@"Reboot", @"Reboot")
                             target:self
                             action:@selector(reboot:)
                              image:CPImageInBundle(@"IconsButtons/reboot.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForMigrate
                              title:CPBundleLocalizedString(@"Migrate", @"Migrate")
                             target:self
                             action:@selector(migrate:)
                              image:CPImageInBundle(@"IconsButtons/migrate.png",nil, [CPBundle mainBundle])];

    [buttonBarControl setButtons:[
        [self buttonWithIdentifier:TNModuleControlForStart],
        [self buttonWithIdentifier:TNModuleControlForPause],
        [self buttonWithIdentifier:TNModuleControlForResume],
        [self buttonWithIdentifier:TNModuleControlForShutdown],
        [self buttonWithIdentifier:TNModuleControlForDestroy],
        [self buttonWithIdentifier:TNModuleControlForReboot],
        [self buttonWithIdentifier:TNModuleControlForMigrate]]];

    [filterField setTarget:_datasourceGroupVM];
    [filterField setAction:@selector(filterObjects:)];

    [groupedMigrationController setDelegate:self];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(reload:) name:TNStropheContactGroupUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(reload:) name:TNStropheContactPresenceUpdatedNotification object:nil];

    return YES;
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [super willUnload];
}

/*! called when module become visible
*/
- (void)willShow
{
    [super willShow];

    [self reload:nil];
}

/*! called when module become unvisible
*/
- (void)willHide
{
    [groupedMigrationController closeWindow:nil];
    [super willHide];
}

#pragma mark -
#pragma mark Notification hanlders

/*! reload the content of the table when something happens (status changes etc..)
*/
- (void)reload:(CPNotification)aNotification
{
    [_datasourceGroupVM removeAllObjects];

    var contacts = [[[TNStropheIMClient defaultClient] roster] getAllContactsTreeFromGroup:_entity];

    for (var i = 0; i < [contacts count]; i++)
    {
        var contact = [contacts objectAtIndex:i],
            vCard   = [contact vCard];

        if (vCard && ([[[TNStropheIMClient defaultClient] roster] analyseVCard:vCard] == TNArchipelEntityTypeVirtualMachine))
            [_datasourceGroupVM addObject:contact];
    }

    [tableVirtualMachines reloadData];
}


#pragma mark -
#pragma mark Actions


/*! Action that is sent when user click the create button
    it will show the content of this virtual machine
    @param sender the sender of the action
*/
- (IBAction)create:(id)aSender
{
    [self applyAction:TNArchipelActionTypeCreate];
}

/*! Action that is sent when user click the shutdown button
    it will show the content of this virtual machine
    @param sender the sender of the action
*/
- (IBAction)shutdown:(id)aSender
{
    [self applyAction:TNArchipelActionTypeShutdown];
}

/*! Action that is sent when user click the destroy button
    it will show the content of this virtual machine
    @param sender the sender of the action
*/
- (IBAction)destroy:(id)aSender
{
    [self applyAction:TNArchipelActionTypeDestroy];
}

/*! Action that is sent when user click the suspend button
    it will show the content of this virtual machine
    @param sender the sender of the action
*/
- (IBAction)suspend:(id)aSender
{
    [self applyAction:TNArchipelActionTypePause];
}

/*! Action that is sent when user click the resume button
    it will show the content of this virtual machine
    @param sender the sender of the action
*/
- (IBAction)resume:(id)aSender
{
    [self applyAction:TNArchipelActionTypeResume];
}

/*! Action that is sent when user click the reboot button
    it will show the content of this virtual machine
    @param sender the sender of the action
*/
- (IBAction)reboot:(id)aSender
{
    [self applyAction:TNArchipelActionTypeReboot];
}

/*! Action that will open the grouped migration controller
    @param sender the sender of the action
*/
- (IBAction)migrate:(id)aSender
{
    [groupedMigrationController openWindow:([aSender isKindOfClass:CPMenuItem]) ? tableVirtualMachines : aSender];
}


#pragma mark -
#pragma mark XMPP Management

/*! prepare and send the action stanza
    @param aCommand the command to send to entities
*/
- (void)applyAction:(CPString)aCommand
{
    var controlType;

    switch (aCommand)
    {
        case TNArchipelActionTypeCreate:
            controlType = TNArchipelTypeVirtualMachineControlCreate;
            break;

        case TNArchipelActionTypeShutdown:
            controlType = TNArchipelTypeVirtualMachineControlShutdown;
            break;

        case TNArchipelActionTypeDestroy:
            controlType = TNArchipelTypeVirtualMachineControlDestroy;
            break;

        case TNArchipelActionTypePause:
            controlType = TNArchipelTypeVirtualMachineControlSuspend;
            break;

        case TNArchipelActionTypeResume:
            controlType = TNArchipelTypeVirtualMachineControlResume;
            break;

        case TNArchipelActionTypeReboot:
            controlType = TNArchipelTypeVirtualMachineControlReboot;
            break;
    }

    var indexes = [tableVirtualMachines selectedRowIndexes],
        objects = [_datasourceGroupVM objectsAtIndexes:indexes];

    for (var i = 0; i < [objects count]; i++)
    {
        var vm              = [objects objectAtIndex:i],
            controlStanza   = [TNStropheStanza iqWithType:@"set"];

        [controlStanza addChildWithName:@"query" andAttributes:{@"xmlns": TNArchipelTypeVirtualMachineControl}];
        [controlStanza addChildWithName:@"archipel" andAttributes:{
            @"xmlns": TNArchipelTypeVirtualMachineControl,
            @"action": controlType}];

        [vm sendStanza:controlStanza andRegisterSelector:@selector(_didSendAction:) ofObject:self];
    }
}

/*! Notify about the result of the action
    @param aStanza TNStropheStanza containing the result of the request
*/
- (BOOL)_didSendAction:(TNStropheStanza)aStanza
{
    var sender = [aStanza fromUser];

    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Virtual machine ", @"Virtual machine ") + sender + CPBundleLocalizedString(" state modified", " state modified")];

        [tableVirtualMachines reloadData];
    }

    return NO;
}


/*! perform migration
*/
- (void)performGroupedMigration:(TNStropheContact)aDestination
{
    var indexes = [tableVirtualMachines selectedRowIndexes],
        objects = [_datasourceGroupVM objectsAtIndexes:indexes];

    for (var i = 0; i < [objects count]; i++)
    {
        var vm      = [objects objectAtIndex:i],
            stanza  = [TNStropheStanza iqWithType:@"set"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeVirtualMachineControlMigrate,
            "hypervisorjid": [aDestination JID]}];

        [vm sendStanza:stanza andRegisterSelector:@selector(_didMigrate:) ofObject:self];
    }
}

/*! Notify about the result of the migration
    @param aStanza TNStropheStanza containing the result of the request
*/
- (BOOL)_didMigrate:(TNStropheStanza)aStanza
{
    var sender = [aStanza fromUser];

    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Virtual machine ", @"Virtual machine ") + sender + CPBundleLocalizedString(" is migrating", " is migrating")];
    else
         [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                          message:CPBundleLocalizedString(@"Cannot migrate virtual machine ", @"Cannot migrate virtual machine ") + sender + CPBundleLocalizedString(" to the selected hypervisor", " to the selected hypervisor")];

    [tableVirtualMachines reloadData];
    return NO;
}

##pragma mark -
#pragma mark delegate

/*! Delegate of CPTableView - This will be called when context menu is triggered with right click
*/
- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{

    [_contextualMenu removeAllItems];

    var itemRow = [aTableView rowAtPoint:aRow];
    if ([aTableView selectedRow] != aRow)
        [aTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];

    if (([aTableView numberOfSelectedRows] == 0) && (aTableView == tableVirtualMachines))
        return;

    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForStart]];
    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForResume]];
    [_contextualMenu addItem:[CPMenuItem separatorItem]];
    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForPause]];
    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForShutdown]];
    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForDestroy]];
    [_contextualMenu addItem:[CPMenuItem separatorItem]];
    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForReboot]];
    [_contextualMenu addItem:[CPMenuItem separatorItem]];
    [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForMigrate]];


    return _contextualMenu;
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNGroupManagementController], comment);
}
