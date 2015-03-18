/*
 * TNSchedulerController.j
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
@import <AppKit/CPView.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPPopover.j>

@import <GrowlCappuccino/TNGrowlCenter.j>
@import <StropheCappuccino/TNStropheStanza.j>
@import <TNKit/TNAlert.j>
@import <TNKit/TNTextFieldStepper.j>

@import "../../Views/TNCalendarView.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


var TNArchipelTypeEntitySchedule            = @"archipel:entity:scheduler",
    TNArchipelTypeEntityScheduleSchedule    = @"schedule",
    TNArchipelTypeEntityScheduleUnschedule  = @"unschedule",
    TNArchipelTypeEntityScheduleActions     = @"actions";


/*! @ingroup virtualmachinescheduler
    This object allow to schedule and unschedule jobs
*/
@implementation TNSchedulerController : CPObject
{
    @outlet CPButton                buttonNewJobOK;
    @outlet CPCheckBox              checkBoxEveryDay;
    @outlet CPCheckBox              checkBoxEveryHour;
    @outlet CPCheckBox              checkBoxEveryMinute;
    @outlet CPCheckBox              checkBoxEveryMonth;
    @outlet CPCheckBox              checkBoxEverySecond;
    @outlet CPCheckBox              checkBoxEveryYear;
    @outlet CPPopUpButton           buttonNewJobAction;
    @outlet CPTextField             fieldNewJobComment;
    @outlet CPView                  viewNewJobOneShot;
    @outlet CPView                  viewNewJobRecurent;
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
    @outlet CPTabView               tabViewJobSchedule;
    @outlet CPPopover               mainPopover;

    id                              _delegate   @accessors(property=delegate);
    CPDate                          _scheduledDate;
}

#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    [stepperHour setMaxValue:23];

    [calendarViewNewJob setBorderedWithHexColor:@"#F2F2F2"];
    [calendarViewNewJob setDelegate:self];

    var itemOneShot = [[CPTabViewItem alloc] initWithIdentifier:@"itemOneShot"];
    [itemOneShot setLabel:CPBundleLocalizedString(@"Unique", @"Unique")];
    [itemOneShot setView:viewNewJobOneShot];
    [tabViewJobSchedule addTabViewItem:itemOneShot];

    var itemRecurrent = [[CPTabViewItem alloc] initWithIdentifier:@"itemRecurrent"];
    [itemRecurrent setLabel:CPBundleLocalizedString(@"Recurent", @"Recurent")];
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
#pragma mark Action

/*! open the window
    @param aSender the sender
*/
- (IBAction)openWindow:(id)aSender
{
    var date = [CPDate date];

    [buttonNewJobAction selectItemAtIndex:0];
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

    [mainPopover close];

    if ([aSender isKindOfClass:CPTableView])
    {
        var rect = [aSender rectOfRow:[aSender selectedRow]];
        rect.origin.y += rect.size.height / 2;
        rect.origin.x += rect.size.width / 2;
        [mainPopover showRelativeToRect:CGRectMake(rect.origin.x, rect.origin.y, 10, 10) ofView:aSender preferredEdge:nil];
    }
    else
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil]

    [mainPopover makeFirstResponder:fieldNewJobComment];
    [mainPopover setDefaultButton:buttonNewJobOK];
}

/*! close the window
    @param aSender the sender
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close]
}

/*! alloc a new virtual machine
    @param aSender the sender
*/
- (IBAction)alloc:(id)aSender
{
    [mainPopover close];
    [self alloc];
}

/*! schedule a new job
*/
- (IBAction)schedule:(id)sender
{
    [mainPopover close];
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
        case 1:
            [stepperNewRecurrentJobYear setEnabled:![aSender state]];
            break;
        case 2:
            [stepperNewRecurrentJobMonth setEnabled:![aSender state]];
            break;
        case 3:
            [stepperNewRecurrentJobDay setEnabled:![aSender state]];
            break;
        case 4:
            [stepperNewRecurrentJobHour setEnabled:![aSender state]];
            break;
        case 5:
            [stepperNewRecurrentJobMinute setEnabled:![aSender state]];
            break;
        case 6:
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

    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didReceiveActions:) ofObject:self];
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
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! schedule a new job
*/
- (void)schedule
{
    if (!_scheduledDate)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] name]
                                                         message:CPBundleLocalizedString(@"You must select a date", @"You must select a date")
                                                            icon:TNGrowlIconError];
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

    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didScheduleJob:) ofObject:self];
}

/*! compute the scheduling results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didScheduleJob:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] name]
                                                         message:CPBundleLocalizedString(@"Action has been scheduled", @"Action has been scheduled")];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


/*! unschedule a new job, but before ask user confirmation
*/
- (void)unschedule
{
    var tableJobs = [_delegate tableJobs];

    if (([tableJobs numberOfRows] == 0) || ([tableJobs numberOfSelectedRows] <= 0))
    {
         [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                         informative:CPBundleLocalizedString(@"You must select a job", @"You must select a job")];
         return;
    }

    var title = CPBundleLocalizedString(@"Unschedule Jobs", @"Unschedule Jobs"),
        msg   = CPBundleLocalizedString(@"Are you sure you want to unschedule these jobs ?", @"Are you sure you want to unschedule these jobs ?");

    if ([[tableJobs selectedRowIndexes] count] < 2)
    {
        title = CPBundleLocalizedString(@"Unschedule job", @"Unschedule job");
        msg   = CPBundleLocalizedString(@"Are you sure you want to unschedule this job ?", @"Are you sure you want to unschedule this job ?");
    }

    var alert = [TNAlert alertWithMessage:title
                                informative:msg
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Unschedule", @"Unschedule"), @selector(performUnschedule:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];

    [alert setUserInfo:[tableJobs selectedRowIndexes]];

    [alert runModal];
}

/*! unschedule a new job
*/
- (void)performUnschedule:(id)userInfo
{
    var tableJobs = [_delegate tableJobs],
        indexes = userInfo,
        objects = [[tableJobs dataSource] objectsAtIndexes:indexes];

    [tableJobs deselectAll];

    for (var i = 0; i < [objects count]; i++)
    {
        var job             = [objects objectAtIndex:i],
            stanza          = [TNStropheStanza iqWithType:@"set"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeEntitySchedule}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "action": TNArchipelTypeEntityScheduleUnschedule,
            "uid": [job objectForKey:@"uid"]}];

        [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didUnscheduleJobs:) ofObject:self];
    }
}

/*! compute the scheduling results
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didUnscheduleJobs:(TNStropheStanza)aStanza
{
    if ([aStanza type] != @"result")
        [_delegate handleIqErrorFromStanza:aStanza];

    return NO;
}

#pragma mark -
#pragma mark Delegates

- (void)calendarView:(LPCalendarView)aCalendarView didMakeSelection:(CPDate)aStartDate end:(CPDate)anEndDate
{
    _scheduledDate = aStartDate;
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNSchedulerController], comment);
}
