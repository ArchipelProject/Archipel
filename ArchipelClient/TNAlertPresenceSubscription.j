/*
 * TNAlertPresenceSubscription.j
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
    Subclass of CPAlert that manages the subscription request.
*/
@implementation TNAlertPresenceSubscription: CPAlert
{
    id              _stanza @accessors(property=stanza);
    TNStropheRoster _roster @accessors(property=roster);
}

/*! This method have to be use for the initialization.
    @param aStanza the subscription request TNStropheStanza
    @param aRoster a TNStropheRoster

    @return an
*/
- (id)initWithStanza:(id)aStanza roster:(TNStropheRoster)aRoster
{
    if (self = [super init])
    {
        var contactName = [aStanza getFrom];
        var msg         = contactName + " is asking you subscription. Do you want to add it ?";

        _stanza = aStanza;
        _roster = aRoster;

        [self setDelegate:self];
        [self setTitle:@"Presence Subscription"];
        [self setMessageText:msg];
        [self addButtonWithTitle:@"Authorize"];
        [self addButtonWithTitle:@"No"];
    }

    return self;
}

/*! Delegate of itself. It will, according to the user answer, add or not the
    requester to the roster.
*/
- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode
{
    if (returnCode == 0)
    {
        [_roster answerAuthorizationRequest:_stanza answer:YES];
        CPLog.info(@"Authorization request accepted from " + [_stanza valueForAttribute:@"from"]);
    }
    else
    {
        [_roster answerAuthorizationRequest:_stanza answer:NO];
        CPLog.info(@"Authorization request rejected from " + [_stanza valueForAttribute:@"from"]);
    }
}

@end