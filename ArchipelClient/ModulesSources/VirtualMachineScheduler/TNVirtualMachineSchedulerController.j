/*
 * TNVirtualMachineScheduler.j
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
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>

@import "../../Model/TNModule.j"
@import "TNSchedulerController.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


/*! @defgroup virtualmachinescheduler Module VirtualMachineShceduler
    @desc Scheduler control for virtual machines
*/

var TNArchipelPushNotificationScheduler     = @"archipel:push:scheduler",
    TNArchipelTypeEntitySchedule            = @"archipel:entity:scheduler",
    TNArchipelTypeEntityScheduleJobs        = @"jobs";

var TNModuleControlForSchedule                    = @"Schedule",
    TNModuleControlForUnSchedule                  = @"UnSchedule";

/*! @ingroup virtualmachinescheduler
    Main controller of the module
*/
@implementation TNVirtualMachineScheduler : TNModule
{
    @outlet CPButtonBar             buttonBarJobs;
    @outlet CPSearchField           filterFieldJobs;
    @outlet CPTableView             tableJobs           @accessors(readonly);
    @outlet CPView                  viewTableContainer;
    @outlet TNSchedulerController   schedulerController;

    CPDate                          _scheduledDate;
    TNTableViewDataSource           _datasourceJobs;
}


#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    _datasourceJobs     = [[TNTableViewDataSource alloc] init];
    [_datasourceJobs setTable:tableJobs];
    [_datasourceJobs setSearchableKeyPaths:[@"comment", @"action", @"date"]];
    [tableJobs setDataSource:_datasourceJobs];
    [tableJobs setAllowsMultipleSelection:YES];
    [tableJobs setDelegate:self];

    [self addControlsWithIdentifier:TNModuleControlForSchedule
                              title:CPBundleLocalizedString(@"Add a scheduled action", @"Add a scheduled action")
                             target:self
                             action:@selector(openNewJobWindow:)
                              image:CPImageInBundle(@"IconsButtons/plus.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForUnSchedule
                              title:CPBundleLocalizedString(@"Remove the selected scheduled action(s)", @"Remove the selected scheduled action(s)")
                             target:schedulerController
                             action:@selector(unschedule:)
                              image:CPImageInBundle(@"IconsButtons/minus.png",nil, [CPBundle mainBundle])];

    [buttonBarJobs setButtons:[
        [self buttonWithIdentifier:TNModuleControlForSchedule],
        [self buttonWithIdentifier:TNModuleControlForUnSchedule]]];

    [filterFieldJobs setTarget:_datasourceJobs];
    [filterFieldJobs setAction:@selector(filterObjects:)];

    [schedulerController setDelegate:self];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationScheduler];

    [self getJobs];
    [schedulerController getActions];

    return YES;
}

/*! called when module becomes unvisible
*/
- (void)willHide
{
    [schedulerController closeWindow:nil];

    [super willHide];
}

/*! called when user permissions changed
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    [self setControl:[self buttonWithIdentifier:TNModuleControlForSchedule] enabledAccordingToPermission:@"scheduler_schedule"];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForUnSchedule] enabledAccordingToPermission:@"scheduler_unschedule"];

    if (![self currentEntityHasPermission:@"scheduler_schedule"])
        [schedulerController closeWindow:nil];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [_datasourceJobs removeAllObjects];
    [tableJobs reloadData];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when an Archipel push is received
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    [self getJobs];
    return YES;
}


#pragma mark -
#pragma mark Actions

/*! Open the new job window
    @param sender the sender of the action
*/
- (IBAction)openNewJobWindow:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    [schedulerController openWindow:[self buttonWithIdentifier:TNModuleControlForSchedule]];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask for existing jobs
*/
- (void)getJobs
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeEntitySchedule}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeEntityScheduleJobs}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveJobs:) ofObject:self];
}

/*! compute the answer containing the jobs
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveJobs:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [_datasourceJobs removeAllObjects];

        var jobs = [aStanza childrenWithName:@"job"];

        for (var i = 0; i < [jobs count]; i++)
        {
            var job             = [jobs objectAtIndex:i],
                action          = [job valueForAttribute:@"action"],
                uid             = [job valueForAttribute:@"uid"],
                comment         = [job valueForAttribute:@"comment"],
                date            = [job valueForAttribute:@"date"],

                newJob    = @{@"action":action, @"uid":uid, @"comment":comment, @"date":date};

            [_datasourceJobs addObject:newJob];
        }
        [tableJobs reloadData];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

#pragma mark -
#pragma mark delegate

/*! Delegate of CPTableView - This will be called when context menu is triggered with right click
*/
- (CPMenu)tableView:(CPTableView)aTableView menuForTableColumn:(CPTableColumn)aColumn row:(int)aRow
{

    if ([aTableView selectedRow] != aRow)
        if (aRow >=0)
            [aTableView selectRowIndexes:[CPIndexSet indexSetWithIndex:aRow] byExtendingSelection:NO];
        else
            [aTableView deselectAll];

    [_contextualMenu removeAllItems];

    if (([aTableView numberOfSelectedRows] == 0) && (aTableView == tableJobs))
    {
        [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForSchedule]];
    }
    else
    {
        [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForUnSchedule]];
    }

    return _contextualMenu;
}

/* Delegate of CPTableView - this will be triggered on delete key events
*/
- (void)tableViewDeleteKeyPressed:(CPTableView)aTableView
{
    if ([aTableView numberOfSelectedRows] == 0)
        return;

        [schedulerController unschedule:aTableView];
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineScheduler], comment);
}

