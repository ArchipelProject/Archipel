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
    CPString        jid     @accessors;
    TNStropheRoster roster  @accessors;
}

/*! init the class with the JID to remove and the roster to remove contact from
    @param aJid CPString containing the jid the remove
    @param aRoster TNStropheRoster instance to remove from
    @return an initialized TNAlertRemoveContact
*/
- (id)initWithJid:(CPString)aJid roster:(TNStropheRoster)aRoster
{
    if (self = [super init])
    {
        if (aJid == nil)
            return nil;

        [self setJid:aJid];
        [self setRoster:aRoster];
        [self setDelegate:self];

        var msg = @"Are you sure you want to remove " + aJid + " ?";
        [self setTitle:@"Remove entity"];
        [self setMessageText:msg];
        //[self setWindowStyle:CPHUDBackgroundWindowMask];
        [self setAlertStyle:CPInformationalAlertStyle];
        [self addButtonWithTitle:@"Yes"];
        [self addButtonWithTitle:@"No"];
    }

    return self;
}

/*! Delegate of itself. Will perform, according to the user answer,
    the removing of the jid from the roster.

    @param theAlert itself
    @param returnCode the return code of the CPAlert
*/
- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode
{
    if (returnCode == 0)
    {
        [[self roster] removeContact:[self jid]];
        CPLog.info(@"contact " + [self jid] + "removed");
        
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Contact" message:@"Contact " + [self jid] + @" has been removed" icon:nil];
    }
}

@end