/*
 * TNWindowAddContact.j
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

/*! @ingroup archipelcore
    subclass of CPWindow that allows to add a TNStropheContact
*/
@implementation TNContactsController: CPObject
{
    @outlet CPPopUpButton   newContactGroup;
    @outlet CPTextField     newContactJID;
    @outlet CPTextField     newContactName;
    @outlet CPWindow        mainWindow @accessors(readonly);

    TNStropheRoster         _roster         @accessors(property=roster);
}

/*! overide of the orderFront
    @param sender the sender
*/
- (IBAction)showWindow:(id)sender
{
    var groups = [_roster groups];

    [newContactJID setStringValue:@""];
    [newContactName setStringValue:@""];
    [newContactGroup removeAllItems];
    //[self makeFirstResponder:newContactJID];

    if (![_roster containsGroup:@"General"])
    {
        [newContactGroup addItemWithTitle:@"General"];
    }

    //@each (var group in groups)
    for (var i = 0; i < [groups count]; i++)
    {
        var group   = [groups objectAtIndex:i];
        [newContactGroup addItemWithTitle:[group name]];
    }

    [newContactGroup selectItemWithTitle:@"General"];

    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:sender];
}

/*! add a contact according to the values of the outlets
    @param sender the sender
*/
- (IBAction)addContact:(id)sender
{
    var group   = [newContactGroup title],
        JID     = [[newContactJID stringValue] lowercaseString],
        name    = [newContactName stringValue],
        growl   = [TNGrowlCenter defaultCenter],
        msg     = @"Presence subsciption has been sent to " + JID + ".";

    if (name == "")
        name = [[JID componentsSeparatedByString:@"@"] objectAtIndex:0];

    [_roster addContact:JID withName:name inGroupWithName:group];
    [_roster askAuthorizationTo:JID];
    [_roster authorizeJID:JID];

    [mainWindow performClose:nil];

    CPLog.info(@"added contact " + JID);

    [growl pushNotificationWithTitle:@"Contact" message:@"Contact " + JID + @" has been added"];
}


/*! will ask for deleting the selected contact
    @param the sender of the action
*/
- (void)deleteContact:(TNStropheContact)aContact
{
    if ([aContact class] != TNStropheContact)
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"User supression" message:@"You must choose a contact" icon:TNGrowlIconError];
        return;
    }

    var alert = [TNAlert alertWithMessage:@"Delete contact"
                                informative:@"Are you sure you want to delete this contact?"
                                 target:self
                                 actions:[["Delete", @selector(performDeleteContact:)], ["Cancel", nil]]];
    [alert setUserInfo:aContact];
    [alert runModal];
}

/*! Action for the deleteContact:'s confirmation TNAlert.
    It will delete the contact
    @param the sender of the action
*/
- (void)performDeleteContact:(id)userInfo
{
    var contact = userInfo;

    [_roster removeContactWithJID:[contact JID]];

    CPLog.info(@"contact " + [contact JID] + "removed");
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Contact" message:@"Contact " + [contact JID] + @" has been removed"];

    var pubsub = [TNPubSubNode pubSubNodeWithNodeName:"/archipel/" + [contact JID] + "/events"
                                               connection:[_roster connection]
                                             pubSubServer:@"pubsub." + [contact domain]];
    [pubsub unsubscribe];
}

@end