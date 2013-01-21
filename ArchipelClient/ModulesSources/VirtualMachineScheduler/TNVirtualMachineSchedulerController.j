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

    CPButton                        _buttonSchedule;
    CPButton                        _buttonUnschedule;
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

    _buttonSchedule    = [CPButtonBar plusButton];
    [_buttonSchedule setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/plus.png"] size:CGSizeMake(16, 16)]];
    [_buttonSchedule setTarget:self];
    [_buttonSchedule setAction:@selector(openNewJobWindow:)];

    _buttonUnschedule  = [CPButtonBar plusButton];
    [_buttonUnschedule setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/minus.png"] size:CGSizeMake(16, 16)]];
    [_buttonUnschedule setTarget:schedulerController];
    [_buttonUnschedule setAction:@selector(unschedule:)];

    [buttonBarJobs setButtons:[_buttonSchedule, _buttonUnschedule]];

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


/*! called by module loader when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Schedule new action", @"Schedule new action") action:@selector(openNewJobWindow:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Unschedule selected action", @"Unschedule selected action") action:@selector(unschedule:) keyEquivalent:@""] setTarget:schedulerController];
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
    [self setControl:_buttonSchedule enabledAccordingToPermission:@"scheduler_schedule"];
    [self setControl:_buttonUnschedule enabledAccordingToPermission:@"scheduler_unschedule"];

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

    [schedulerController openWindow:_buttonSchedule];
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

                newJob    = [CPDictionary dictionaryWithObjectsAndKeys:action, @"action", uid, @"uid", comment, @"comment", date, @"date"];

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


@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineScheduler], comment);
}

