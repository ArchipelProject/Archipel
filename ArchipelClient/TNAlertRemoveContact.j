/*
 * TNAlertRemoveContact.j
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
    Subclass of CPAlert that manages the removing of contact
*/
@implementation TNAlertRemoveContact: CPAlert
{
    CPString        _JID        @accessors(getter=JID, setter=setJID:);
    TNStropheRoster _roster      @accessors(getter=roster, setter=setRoster:);
}

/*! init the class with the JID to remove and the roster to remove contact from
    @param aJID CPString containing the JID the remove
    @param aRoster TNStropheRoster instance to remove from
    @return an initialized TNAlertRemoveContact
*/
- (id)initWithJID:(CPString)aJID roster:(TNStropheRoster)aRoster
{
    if (self = [super init])
    {
        if (aJID == nil)
            return nil;

        _JID    = aJID;
        _roster = aRoster;
        
        [self setDelegate:self];

        var msg = @"Are you sure you want to remove " + _JID + " ?";
        [self setTitle:@"Remove entity"];
        [self setMessageText:msg];
        [self setAlertStyle:CPInformationalAlertStyle];
        [self addButtonWithTitle:@"Yes"];
        [self addButtonWithTitle:@"No"];
    }

    return self;
}

/*! Delegate of itself. Will perform, according to the user answer,
    the removing of the JID from the roster.

    @param theAlert itself
    @param returnCode the return code of the CPAlert
*/
- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode
{
    if (returnCode == 0)
    {
        var growl = [TNGrowlCenter defaultCenter];
        
        [_roster removeContactWithJID:_JID];
        
        CPLog.info(@"contact " + _JID + "removed");
        [growl pushNotificationWithTitle:@"Contact" message:@"Contact " + _JID + @" has been removed"];
    }
}

@end