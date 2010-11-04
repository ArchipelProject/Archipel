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
@import <AppKit/AppKit.j>



TNArchipelTypeVirtualMachineControl             = @"archipel:vm:control";

TNArchipelTypeVirtualMachineControlCreate       = @"create";
TNArchipelTypeVirtualMachineControlShutdown     = @"shutdown";
TNArchipelTypeVirtualMachineControlDestroy      = @"destroy";
TNArchipelTypeVirtualMachineControlReboot       = @"reboot";
TNArchipelTypeVirtualMachineControlSuspend      = @"suspend";
TNArchipelTypeVirtualMachineControlResume       = @"resume";

TNArchipelActionTypeCreate                      = @"Start";
TNArchipelActionTypePause                       = @"Pause";
TNArchipelActionTypeShutdown                    = @"Shutdown";
TNArchipelActionTypeDestroy                     = @"Destroy";
TNArchipelActionTypeResume                      = @"Resume";
TNArchipelActionTypeReboot                      = @"Reboot";

/*! @defgroup  groupmanagement Module Group Management
    @desc This module allows to send controls to a list a virtual machine present in a Roster group
*/

/*! @ingroup groupmanagement
    The main module controller
*/
@implementation TNGroupManagementController : TNModule
{
    @outlet CPButtonBar             buttonBarControl;
    @outlet CPScrollView            VMScrollView;
    @outlet CPSearchField           filterField;
    @outlet CPTextField             fieldJID                @accessors;
    @outlet CPTextField             fieldName               @accessors;
    @outlet CPView                  viewTableContainer;

    CPTableView                     _tableVirtualMachines;
    TNTableViewDataSource           _datasourceGroupVM;
}


#pragma mark -
#pragma mark Initialization

/*! triggered at cib waking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    _datasourceGroupVM      = [[TNTableViewDataSource alloc] init];
    _tableVirtualMachines   = [[CPTableView alloc] initWithFrame:[VMScrollView bounds]];

    [VMScrollView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [VMScrollView setAutohidesScrollers:YES];
    [VMScrollView setDocumentView:_tableVirtualMachines];

    [_tableVirtualMachines setUsesAlternatingRowBackgroundColors:YES];
    [_tableVirtualMachines setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableVirtualMachines setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableVirtualMachines setAllowsColumnReordering:YES];
    [_tableVirtualMachines setAllowsColumnResizing:YES];
    [_tableVirtualMachines setAllowsEmptySelection:YES];
    [_tableVirtualMachines setAllowsMultipleSelection:YES];
    [_tableVirtualMachines setTarget:self];
    [_tableVirtualMachines setDoubleAction:@selector(virtualMachineDoubleClick:)];


    var vmColumNickname     = [[CPTableColumn alloc] initWithIdentifier:@"nickname"],
        vmColumJID          = [[CPTableColumn alloc] initWithIdentifier:@"JID"],
        vmColumStatusIcon   = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"],
        imgView             = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [vmColumNickname setWidth:250];
    [[vmColumNickname headerView] setStringValue:@"Name"];

    [vmColumJID setWidth:450];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];

    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setResizingMask:CPTableColumnAutoresizingMask ];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];

    [_tableVirtualMachines addTableColumn:vmColumStatusIcon];
    [_tableVirtualMachines addTableColumn:vmColumNickname];
    [_tableVirtualMachines addTableColumn:vmColumJID];

    [_datasourceGroupVM setTable:_tableVirtualMachines];
    [_datasourceGroupVM setSearchableKeyPaths:[@"nickname", @"JID"]];
    [_tableVirtualMachines setDataSource:_datasourceGroupVM];

    var createButton    = [CPButtonBar plusButton],
        shutdownButton  = [CPButtonBar plusButton],
        destroyButton   = [CPButtonBar plusButton],
        suspendButton   = [CPButtonBar plusButton],
        resumeButton    = [CPButtonBar plusButton],
        rebootButton    = [CPButtonBar plusButton];

    [createButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-play.png"] size:CPSizeMake(16, 16)]];
    [createButton setTarget:self];
    [createButton setAction:@selector(create:)];

    [shutdownButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-stop.png"] size:CPSizeMake(16, 16)]];
    [shutdownButton setTarget:self];
    [shutdownButton setAction:@selector(shutdown:)];

    [destroyButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-unplug.png"] size:CPSizeMake(16, 16)]];
    [destroyButton setTarget:self];
    [destroyButton setAction:@selector(destroy:)];

    [suspendButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-pause.png"] size:CPSizeMake(16, 16)]];
    [suspendButton setTarget:self];
    [suspendButton setAction:@selector(suspend:)];

    [resumeButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-resume.png"] size:CPSizeMake(16, 16)]];
    [resumeButton setTarget:self];
    [resumeButton setAction:@selector(resume:)];

    [rebootButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-restart.png"] size:CPSizeMake(16, 16)]];
    [rebootButton setTarget:self];
    [rebootButton setAction:@selector(reboot:)];

    [buttonBarControl setButtons:[createButton, suspendButton, resumeButton, shutdownButton, destroyButton, rebootButton]];

    [filterField setTarget:_datasourceGroupVM];
    [filterField setAction:@selector(filterObjects:)];
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
    [[_menu addItemWithTitle:@"Start selected virtual machines" action:@selector(create:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Shutdown selected virtual machines" action:@selector(shutdown:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Pause selected virtual machines" action:@selector(suspend:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Resume selected virtual machines" action:@selector(resume:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Reboot selected virtual machines" action:@selector(reboot:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Destroy selected virtual machines" action:@selector(destroy:) keyEquivalent:@""] setTarget:self];
}


#pragma mark -
#pragma mark Notification hanlders

/*! reload the content of the table when something happens (status changes etc..)
*/
- (void)reload:(CPNotification)aNotification
{
    [fieldName setStringValue:[_entity name]];

    [_datasourceGroupVM removeAllObjects];

    for (var i = 0; i < [[_entity contacts] count]; i++)
    {
        var contact = [[_entity contacts] objectAtIndex:i],
            vCard   = [contact vCard];

        if (vCard && ([[vCard firstChildWithName:@"TYPE"] text] == TNArchipelEntityTypeVirtualMachine))
            [_datasourceGroupVM addObject:contact];
    }

    [_tableVirtualMachines reloadData];
}


#pragma mark -
#pragma mark Actions

/*! Action that is sent when user double click on a machine
    it will show the content of this virtual machine
    @param sender the sender of the action
*/
- (IBAction)virtualMachineDoubleClick:(id)aSender
{
    var selectedIndexes = [_tableVirtualMachines selectedRowIndexes],
        contact         = [_datasourceGroupVM objectAtIndex:[selectedIndexes firstIndex]],
        row             = [[_roster mainOutlineView] rowForItem:contact],
        indexes         = [CPIndexSet indexSetWithIndex:row];

    [[_roster mainOutlineView] selectRowIndexes:indexes byExtendingSelection:NO];
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

    var indexes = [_tableVirtualMachines selectedRowIndexes],
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine "+sender+" state modified"];

        [_tableVirtualMachines reloadData];
    }

    return NO;
}

@end
