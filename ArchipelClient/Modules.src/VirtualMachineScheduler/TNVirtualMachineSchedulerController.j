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
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <TNKit/TNAlert.j>
@import <TNKit/TNTableViewDataSource.j>
@import <TNKit/TNTextFieldStepper.j>



/*! @defgroup virtualmachinescheduler Module VirtualMachineShceduler
    @desc Scheduler control for virtual machines
*/

var TNArchipelPushNotificationScheduler     = @"archipel:push:scheduler",
    TNArchipelTypeEntitySchedule            = @"archipel:entity:scheduler",
    TNArchipelTypeEntityScheduleSchedule    = @"schedule",
    TNArchipelTypeEntityScheduleUnschedule  = @"unschedule",
    TNArchipelTypeEntityScheduleJobs        = @"jobs",
    TNArchipelTypeEntityScheduleActions     = @"actions";

/*! @ingroup virtualmachinescheduler
    Main controller of the module
*/
@implementation TNVirtualMachineScheduler : TNModule
{
    @outlet CPButtonBar             buttonBarJobs;
    @outlet CPCheckBox              checkBoxEveryDay;
    @outlet CPCheckBox              checkBoxEveryHour;
    @outlet CPCheckBox              checkBoxEveryMinute;
    @outlet CPCheckBox              checkBoxEveryMonth;
    @outlet CPCheckBox              checkBoxEverySecond;
    @outlet CPCheckBox              checkBoxEveryYear;
    @outlet CPPopUpButton           buttonNewJobAction;
    @outlet CPScrollView            scrollViewTableJobs;
    @outlet CPSearchField           filterFieldJobs;
    @outlet CPTabView               tabViewJobSchedule;
    @outlet CPTextField             fieldJID;
    @outlet CPTextField             fieldName;
    @outlet CPTextField             fieldNewJobComment;
    @outlet CPView                  viewNewJobOneShot;
    @outlet CPView                  viewNewJobRecurent;
    @outlet CPView                  viewTableContainer;
    @outlet CPWindow                windowNewJob;
    @outlet TNCalendarView          calendarViewNewJob;
    @outlet TNTextFieldStepper      stepperHour;
    @outlet TNTextFieldStepper      stepperMinute;
    @outlet TNTextFieldStepper      stepperNewRecurrentJobDay;
    @outlet TNTextFieldStepper      stepperNewRecurrentJobHour;
    @outlet TNTextFieldStepper      stepperNewRecurrentJobMinute;
    @outlet TNTextFieldStepper      stepperNewRecurrentJobMonth;
    @outlet TNTextFieldStepper      stepperNewRecurrentJobSecond;
    @outlet TNTextFieldStepper      stepperNewRecurrentJobYear;
    @outlet TNTextFieldStepper      stepperSecond;

    CPButton                        _buttonSchedule;
    CPButton                        _buttonUnschedule;
    CPDate                          _scheduledDate;
    CPTableView                     _tableJobs;
    TNTableViewDataSource           _datasourceJobs;
}


#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];

    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    _datasourceJobs     = [[TNTableViewDataSource alloc] init];
    _tableJobs          = [[CPTableView alloc] initWithFrame:[scrollViewTableJobs bounds]];

    [scrollViewTableJobs setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewTableJobs setAutohidesScrollers:YES];
    [scrollViewTableJobs setDocumentView:_tableJobs];

    [_tableJobs setUsesAlternatingRowBackgroundColors:YES];
    [_tableJobs setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableJobs setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableJobs setAllowsColumnReordering:YES];
    [_tableJobs setAllowsColumnResizing:YES];
    [_tableJobs setAllowsEmptySelection:YES];
    [_tableJobs setAllowsMultipleSelection:YES];

    var columnAction    = [[CPTableColumn alloc] initWithIdentifier:@"action"],
        columnDate      = [[CPTableColumn alloc] initWithIdentifier:@"date"],
        columnComment   = [[CPTableColumn alloc] initWithIdentifier:@"comment"];

    [columnAction setWidth:120];
    [[columnAction headerView] setStringValue:@"Action"];

    [columnDate setWidth:150];
    [[columnDate headerView] setStringValue:@"Date"];

    [[columnComment headerView] setStringValue:@"Comment"];

    [_tableJobs addTableColumn:columnAction];
    [_tableJobs addTableColumn:columnDate];
    [_tableJobs addTableColumn:columnComment];

    [_datasourceJobs setTable:_tableJobs];
    [_datasourceJobs setSearchableKeyPaths:[@"comment", @"action", @"date"]];
    [_tableJobs setDataSource:_datasourceJobs];

    _buttonSchedule    = [CPButtonBar plusButton];
    _buttonUnschedule  = [CPButtonBar plusButton];

    [_buttonSchedule setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/plus.png"] size:CPSizeMake(16, 16)]];
    [_buttonSchedule setTarget:self];
    [_buttonSchedule setAction:@selector(openNewJobWindow:)];
    [_buttonSchedule setToolTip:@"Add a new scheduled action"];

    [_buttonUnschedule setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/minus.png"] size:CPSizeMake(16, 16)]];
    [_buttonUnschedule setTarget:self];
    [_buttonUnschedule setAction:@selector(unschedule:)];
    [_buttonUnschedule setToolTip:@"Remove selected scheduled action"];

    [buttonBarJobs setButtons:[_buttonSchedule, _buttonUnschedule]];

    [filterFieldJobs setTarget:_datasourceJobs];
    [filterFieldJobs setAction:@selector(filterObjects:)];

    [stepperHour setMaxValue:23];

    [calendarViewNewJob setBorderedWithHexColor:@"#C0C7D2"];
    [calendarViewNewJob setDelegate:self];

    //tabview
    var itemOneShot = [[CPTabViewItem alloc] initWithIdentifier:@"itemOneShot"];
    [itemOneShot setLabel:@"Unique"];
    [itemOneShot setView:viewNewJobOneShot];
    [tabViewJobSchedule addTabViewItem:itemOneShot];

    var itemRecurrent = [[CPTabViewItem alloc] initWithIdentifier:@"itemRecurrent"];
    [itemRecurrent setLabel:@"Recurent"];
    [itemRecurrent setView:viewNewJobRecurent];
    [tabViewJobSchedule addTabViewItem:itemRecurrent];

    var date = [CPDate date];
    [stepperNewRecurrentJobYear setMaxValue:[[date format:@"Y"] intValue] + 100];
    [stepperNewRecurrentJobYear setMinValue:[date format:@"Y"]];
    [stepperNewRecurrentJobMonth setMaxValue:12];
    [stepperNewRecurrentJobMonth setMinValue:1];
    [stepperNewRecurrentJobDay setMaxValue:31];
    [stepperNewRecurrentJobDay setMinValue:1];
    [stepperNewRecurrentJobHour setMaxValue:23];
    [stepperNewRecurrentJobHour setMinValue:0];


}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationScheduler];

    [self getJobs];
    [self getActions];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];

    return YES;
}

/*! called when module becomes unvisible
*/
- (void)willHide
{
    [super willHide];
    [windowNewJob close];
}


/*! called by module loader when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:@"Schedule new action" action:@selector(openNewJobWindowq:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Unschedule selected action" action:@selector(unschedule:) keyEquivalent:@""] setTarget:self];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [self setControl:_buttonSchedule enabledAccordingToPermission:@"scheduler_schedule"];
    [self setControl:_buttonUnschedule enabledAccordingToPermission:@"scheduler_unschedule"];

    if (![self currentEntityHasPermission:@"scheduler_schedule"])
        [windowNewJob close];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when entity' nickname changed
    @param aNotification the notification
*/
- (void)_didUpdateNickName:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

/*! called when an Archipel push is received
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    CPLog.info(@"PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);

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
    var date = [CPDate date];

    [fieldNewJobComment setStringValue:@""];
    [stepperHour setDoubleValue:[date format:@"H"]]
    [stepperMinute setDoubleValue:[date format:@"i"]]
    [stepperSecond setDoubleValue:0.0];
    [calendarViewNewJob makeSelectionWithDate:date end:date];

    [stepperNewRecurrentJobYear setDoubleValue:[date format:@"Y"]];
    [stepperNewRecurrentJobMonth setDoubleValue:[date format:@"m"]];
    [stepperNewRecurrentJobDay setDoubleValue:[date format:@"d"]];
    [stepperNewRecurrentJobHour setDoubleValue:[date format:@"H"]];
    [stepperNewRecurrentJobMinute setDoubleValue:[date format:@"i"]];
    [stepperNewRecurrentJobSecond setDoubleValue:0.0];

    [windowNewJob center];
    [windowNewJob makeKeyAndOrderFront:nil];

    [buttonNewJobAction selectItemAtIndex:0];
}

/*! schedule a new job
*/
- (IBAction)schedule:(id)sender
{
    [windowNewJob close];
    [self schedule];
}

/*! unschedule the selected jobs
*/
- (IBAction)unschedule:(id)sender
{
    [self unschedule];
}

/*! handle every checkbox event
*/
- (IBAction)checkboxClicked:(id)aSender
{
    switch ([aSender tag])
    {
        case "1":
            [stepperNewRecurrentJobYear setEnabled:![aSender state]];
            break;
        case "2":
            [stepperNewRecurrentJobMonth setEnabled:![aSender state]];
            break;
        case "3":
            [stepperNewRecurrentJobDay setEnabled:![aSender state]];
            break;
        case "4":
            [stepperNewRecurrentJobHour setEnabled:![aSender state]];
            break;
        case "5":
            [stepperNewRecurrentJobMinute setEnabled:![aSender state]];
            break;
        case "6":
            [stepperNewRecurrentJobSecond setEnabled:![aSender state]];
            break;
    }
}

#pragma mark -
#pragma mark XMPP Controls

/*! ask for supported actions
*/
- (void)getActions
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeEntitySchedule}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeEntityScheduleActions}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveActions:) ofObject:self];
}

/*! compute the answer containing the actions
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveActions:(TNStropheStanza)aStanza
{
    [buttonNewJobAction removeAllItems];

    if ([aStanza type] == @"result")
    {
        var actions = [aStanza childrenWithName:@"action"];

        for (var i = 0; i < [actions count]; i++)
            [buttonNewJobAction addItemWithTitle:[[actions objectAtIndex:i] text]];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

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
        [_tableJobs reloadData];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


/*! schedule a new job
*/
- (void)schedule
{
    if (!_scheduledDate)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Scheduler" message:@"You must select a date" icon:TNGrowlIconError];
        return;
    }

    var stanza = [TNStropheStanza iqWithType:@"get"];

    var year,
        month,
        day,
        hour,
        minute,
        second;

    if ([[tabViewJobSchedule selectedTabViewItem] identifier] == @"itemOneShot")
    {
        year    = [_scheduledDate format:@"Y"];
        month   = [_scheduledDate format:@"m"];
        day     = [_scheduledDate format:@"d"];
        hour    = [stepperHour doubleValue];
        minute  = [stepperMinute doubleValue];
        second  = [stepperSecond doubleValue];
    }
    else if ([[tabViewJobSchedule selectedTabViewItem] identifier] == @"itemRecurrent")
    {
        year    = (![checkBoxEveryYear state]) ? [stepperNewRecurrentJobYear doubleValue] : "*";
        month   = (![checkBoxEveryMonth state]) ? [stepperNewRecurrentJobMonth doubleValue] : "*";
        day     = (![checkBoxEveryDay state]) ? [stepperNewRecurrentJobDay doubleValue] : "*";
        hour    = (![checkBoxEveryHour state]) ? [stepperNewRecurrentJobHour doubleValue] : "*";
        minute  = (![checkBoxEveryMinute state]) ? [stepperNewRecurrentJobMinute doubleValue] : "*";
        second  = (![checkBoxEverySecond state]) ? [stepperNewRecurrentJobSecond doubleValue] : "*";
    }

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeEntitySchedule}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeEntityScheduleSchedule,
        "comment": [fieldNewJobComment stringValue],
        "job": [buttonNewJobAction title],
        "year": year,
        "month": month,
        "day": day,
        "hour": hour,
        "minute": minute,
        "second": second}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didScheduleJob:) ofObject:self];
}

/*! compute the scheduling results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didScheduleJob:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Scheduler" message:@"Action has been scheduled"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


/*! schedule a new job, but before ask user confirmation
*/
- (void)unschedule
{
    if (([_tableJobs numberOfRows] == 0) || ([_tableJobs numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a job"];
         return;
    }

    var title = @"Unschedule Jobs",
        msg   = @"Are you sure you want to unschedule these jobs ?";

    if ([[_tableJobs selectedRowIndexes] count] < 2)
    {
        title = @"Unschedule job";
        msg   = @"Are you sure you want to unschedule this job ?";
    }

    var alert = [TNAlert alertWithMessage:title
                                informative:msg
                                 target:self
                                 actions:[["Unschedule", @selector(performUnschedule:)], ["Cancel", nil]]];

    [alert setUserInfo:[_tableJobs selectedRowIndexes]];

    [alert runModal];
}

/*! schedule a new job
*/
- (void)performUnschedule:(id)userInfo
{
    var indexes = userInfo,
        objects = [_datasourceJobs objectsAtIndexes:indexes];

    [_tableJobs deselectAll];

    for (var i = 0; i < [objects count]; i++)
    {
        var job             = [objects objectAtIndex:i],
            stanza          = [TNStropheStanza iqWithType:@"set"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeEntitySchedule}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeEntityScheduleUnschedule,
            "uid": [job objectForKey:@"uid"]}];

        [_entity sendStanza:stanza andRegisterSelector:@selector(_didUnscheduleJobs:) ofObject:self];
    }
}

/*! compute the scheduling results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didUnscheduleJobs:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}


#pragma mark -
#pragma mark Delegates

- (void)calendarView:(LPCalendarView)aCalendarView didMakeSelection:(CPDate)aStartDate end:(CPDate)anEndDate
{
    _scheduledDate = aStartDate;
}


@end



