/*
 * TNWindowAddGroup.j
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
@import <AppKit/CPTextField.j>
@import <AppKit/CPWindow.j>

@import <GrowlCappuccino/TNGrowlCenter.j>
@import <StropheCappuccino/TNStropheIMClient.j>
@import <TNKit/TNAlert.j>


/*! @ingroup archipelcore
    subclass of CPWindow that allows to add grou in roster
*/
@implementation TNGroupsController: CPObject
{
    @outlet CPButton    buttonAdd;
    @outlet CPButton    buttonCancel;
    @outlet CPTextField newGroupName;
    @outlet CPWindow    mainWindow;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    [newGroupName setToolTip:CPLocalizedString(@"The name of the new group", @"The name of the new group")];

    [mainWindow setDefaultButton:buttonAdd];
}


#pragma mark -
#pragma mark Utilities

/*! will ask for deleting the selected group
    @param the sender of the action
*/
- (void)deleteGroup:(TNStropheGroup)aGroup
{
    var defaults = [CPUserDefaults standardUserDefaults],
        alert;

    if (![aGroup isKindOfClass:TNStropheGroup])
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Group supression", @"Group supression")
                                                         message:CPLocalizedString(@"You must choose a group", @"You must choose a group")
                                                            icon:TNGrowlIconError];
        return;
    }

    if ([[aGroup content] count] != 0)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Group supression", @"Group supression")
                                                         message:CPLocalizedString(@"The group must be empty", @"The group must be empty") icon:TNGrowlIconError];
        return;
    }

    var alert = [TNAlert alertWithMessage:CPLocalizedString(@"Delete group", @"Delete group")
                              informative:CPLocalizedString(@"Are you sure you want to delete this group?", @"Are you sure you want to delete this group?")
                                   target:self
                                  actions:[[CPLocalizedString("Delete", "Delete"), @selector(performDeleteGroup:)], [CPLocalizedString("Cancel", "Cancel"), nil]]];
    [alert setUserInfo:aGroup];
    [alert runModal];
}

/*! Action for the deleteGroup:'s confirmation TNAlert.
    It will delete the group
    @param the sender of the action
*/
- (void)performDeleteGroup:(id)userInfo
{
    var group   = userInfo,
        defaults = [CPUserDefaults standardUserDefaults],
        key     = TNArchipelRememberOpenedGroup + [group name];

    [[[TNStropheIMClient defaultClient] roster] removeGroup:group];
    [defaults removeObjectForKey:key];

    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPLocalizedString(@"Group supression", @"Group supression")
                                                     message:CPLocalizedString(@"The group has been removed", @"The group has been removed")];
}


#pragma mark -
#pragma mark Actions

/*! overide of the orderFront
    @param sender the sender
*/
- (IBAction)showWindow:(id)aSender
{
    [newGroupName setStringValue:@""];

    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];
}

/*! add a group according to the outlets
    @param aSender the sender
*/
- (IBAction)addGroup:(id)aSender
{
    if ([newGroupName stringValue] == "")
    {
        [TNAlert showAlertWithMessage:CPLocalizedString(@"Group addition error", @"Group addition error")
                          informative:CPLocalizedString(@"You have to enter a valid group name.", @"You have to enter a valid group name.")
                                style:CPCriticalAlertStyle];
    }
    else
    {
        var groupName = [newGroupName stringValue];

        [[[TNStropheIMClient defaultClient] roster] addGroupWithPath:groupName];
        [newGroupName setStringValue:@""];
        CPLog.info(@"new group " + groupName + " added.");

        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:CPLocalizedString(@"Group", @"Group")
                                 message:CPLocalizedString(@"Group ", @"Group ") + groupName + CPLocalizedString(@" has been created", @" has been created")];

        [mainWindow performClose:aSender];
    }
}

@end