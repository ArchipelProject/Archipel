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
@import <StropheCappuccino/TNStropheGlobals.j>
@import <StropheCappuccino/TNStropheIMClient.j>
@import <StropheCappuccino/TNStropheStanza.j>
@import <TNKit/TNTableViewDataSource.j>

@import "TNGroupedMigrationController.j";

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
    [tableVirtualMachines setDoubleAction:@selector(virtualMachineDoubleClick:)];
    [_datasourceGroupVM setTable:tableVirtualMachines];
    [_datasourceGroupVM setSearchableKeyPaths:[@"nickname", @"JID"]];
    [tableVirtualMachines setDataSource:_datasourceGroupVM];

    var createButton    = [CPButtonBar plusButton],
        shutdownButton  = [CPButtonBar plusButton],
        destroyButton   = [CPButtonBar plusButton],
        suspendButton   = [CPButtonBar plusButton],
        resumeButton    = [CPButtonBar plusButton],
        rebootButton    = [CPButtonBar plusButton],
        migrateButton   = [CPButtonBar plusButton];

    [createButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/play.png"] size:CPSizeMake(16, 16)]];
    [createButton setTarget:self];
    [createButton setAction:@selector(create:)];
    [createButton setToolTip:CPBundleLocalizedString(@"Start all selected virtual machines", @"Start all selected virtual machines")];

    [shutdownButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/stop.png"] size:CPSizeMake(16, 16)]];
    [shutdownButton setTarget:self];
    [shutdownButton setAction:@selector(shutdown:)];
    [shutdownButton setToolTip:CPBundleLocalizedString(@"Shutdown all selected virtual machines", @"Shutdown all selected virtual machines")];

    [destroyButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/unplug.png"] size:CPSizeMake(16, 16)]];
    [destroyButton setTarget:self];
    [destroyButton setAction:@selector(destroy:)];
    [destroyButton setToolTip:CPBundleLocalizedString(@"Destroy all selected virtual machines", @"Destroy all selected virtual machines")];

    [suspendButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/pause.png"] size:CPSizeMake(16, 16)]];
    [suspendButton setTarget:self];
    [suspendButton setAction:@selector(suspend:)];
    [suspendButton setToolTip:CPBundleLocalizedString(@"Pause all selected virtual machines", @"Pause all selected virtual machines")];

    [resumeButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/resume.png"] size:CPSizeMake(16, 16)]];
    [resumeButton setTarget:self];
    [resumeButton setAction:@selector(resume:)];
    [resumeButton setToolTip:CPBundleLocalizedString(@"Resume all selected virtual machines", @"Resume all selected virtual machines")];

    [rebootButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/restart.png"] size:CPSizeMake(16, 16)]];
    [rebootButton setTarget:self];
    [rebootButton setAction:@selector(reboot:)];
    [rebootButton setToolTip:CPBundleLocalizedString(@"Reboot all selected virtual machines (not supported by all hypervisors)", @"Reboot all selected virtual machines (not supported by all hypervisors)")];

    [migrateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/migrate.png"] size:CPSizeMake(16, 16)]];
    [migrateButton setTarget:self];
    [migrateButton setAction:@selector(migrate:)];
    [migrateButton setToolTip:CPBundleLocalizedString(@"Migrate all selected virtual machines", @"Migrate all selected virtual machines")];


    [buttonBarControl setButtons:[createButton, suspendButton, resumeButton, shutdownButton, destroyButton, rebootButton, migrateButton]];

    [filterField setTarget:_datasourceGroupVM];
    [filterField setAction:@selector(filterObjects:)];

    [groupedMigrationController setDelegate:self];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(reload:) name:TNStropheContactGroupUpdatedNotification object:nil];
    [center addObserver:self selector:@selector(reload:) name:TNStropheContactPresenceUpdatedNotification object:nil];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
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
    [super willHide];
}

/*! called by module loader when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Start selected virtual machines", @"Start selected virtual machines") action:@selector(create:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Shutdown selected virtual machines", @"Shutdown selected virtual machines") action:@selector(shutdown:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Pause selected virtual machines", @"Pause selected virtual machines") action:@selector(suspend:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Resume selected virtual machines", @"Resume selected virtual machines") action:@selector(resume:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Reboot selected virtual machines", @"Reboot selected virtual machines") action:@selector(reboot:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Destroy selected virtual machines", @"Destroy selected virtual machines") action:@selector(destroy:) keyEquivalent:@""] setTarget:self];
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

/*! Action that is sent when user double click on a machine
    it will show the content of this virtual machine
    @param sender the sender of the action
*/
- (IBAction)virtualMachineDoubleClick:(id)aSender
{
    var selectedIndexes = [tableVirtualMachines selectedRowIndexes],
        contact         = [_datasourceGroupVM objectAtIndex:[selectedIndexes firstIndex]],
        row             = [[[[TNStropheIMClient defaultClient] roster] mainOutlineView] rowForItem:contact],
        indexes         = [CPIndexSet indexSetWithIndex:row];

    [[[[TNStropheIMClient defaultClient] roster] mainOutlineView] selectRowIndexes:indexes byExtendingSelection:NO];
}

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
    [groupedMigrationController showMainWindow:aSender];
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
}

/*! Notify about the result of the action
    @param aStanza TNStropheStanza containing the result of the request
*/
- (BOOL)_didSendAction:(TNStropheStanza)aStanza
{
    var sender = [aStanza fromUser];

    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Virtual Machine", @"Virtual Machine")
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Virtual Machine", @"Virtual Machine")
                                                         message:CPBundleLocalizedString(@"Virtual machine ", @"Virtual machine ") + sender + CPBundleLocalizedString(" is migrating", " is migrating")];
    else
         [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Virtual Machine", @"Virtual Machine")
                                                          message:CPBundleLocalizedString(@"Cannot migrate virtual machine ", @"Cannot migrate virtual machine ") + sender + CPBundleLocalizedString(" to the selected hypervisor", " to the selected hypervisor")];

    [tableVirtualMachines reloadData];
    return NO;
}


@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNGroupManagementController], comment);
}
