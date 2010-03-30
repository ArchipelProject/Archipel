/*
 * TNWindowConnection.j
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
@import <StropheCappuccino/StropheCappuccino.j>

@import "TNViewLog.j"

/*! @global
    @group TNStropheConnection
    Notification that indicates successfull connection
*/
TNStropheConnectionSuccessNotification  = @"TNStropheConnectionSuccessNotification";

/*! @global
    @group TNStropheConnection
    Notification that indicates disconnection
*/
TNStropheDisconnectionNotification      = @"TNStropheDisconnectionNotification";

/*! @global
    @group TNStropheConnection
    Notification that indicates unsuccessfull connection
*/
TNStropheConnectionFailNotification     = @"TNStropheConnectionFailNotification";

/*! @ingroup archipelcore
    subclass of CPWindow that allows to manage connection to XMPP Server
*/
@implementation TNWindowConnection: CPWindow
{
    @outlet CPImageView spinning            @accessors;
    @outlet CPTextField jid                 @accessors;
    @outlet CPTextField message             @accessors;
    @outlet CPTextField password            @accessors;
    @outlet CPTextField boshService         @accessors;
    @outlet CPCheckBox  credentialRemember  @accessors;

    TNStropheConnection JSStrophe           @accessors;
    CPCookie            cookieLogin         @accessors;
    CPCookie            cookiePassword      @accessors;
}

/*! initialize the window when CIB is loaded
*/
- (void) awakeFromCib
{
    [[self password] setSecure:YES];

    var lastBoshService  = JSON.parse(localStorage.getItem("lastboshservice"));
    var lastJID          = JSON.parse(localStorage.getItem("lastjid"));
    var lastPassword     = JSON.parse(localStorage.getItem("lastpassword"));

    if (lastBoshService)
        [[self boshService] setStringValue:lastBoshService];

    [[self jid] setStringValue:lastJID];
    [[self password] setStringValue:lastPassword];

    if (lastJID && lastPassword)
        [self connect:nil];
    else
        [[self credentialRemember] setState:CPOffState];

    [self setShowsResizeIndicator:NO];
}

/*! connection action
    @param sender the sender
*/
- (IBAction)connect:(id)sender
{
    localStorage.setItem("lastboshservice", JSON.stringify([[self boshService] stringValue]));
    if ([[self credentialRemember] state] == CPOnState)
    {
        localStorage.setItem("lastjid", JSON.stringify([jid stringValue]));
        localStorage.setItem("lastpassword", JSON.stringify([password stringValue]));
    }

    [self setJSStrophe:[TNStropheConnection connectionWithService:[boshService stringValue] jid:[jid stringValue] password:[password stringValue]]];
    [[self JSStrophe] setDelegate:self];
    [[self JSStrophe] connect];
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheConnecting:(id)aStrophe
{
    [[self spinning] setHidden:NO];
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheConnected:(id)aStrophe
{
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheConnectionSuccessNotification object:self userInfo:[self JSStrophe]];
    [[self spinning] setHidden:YES];

    [[TNViewLog sharedLogger] log:@"Strophe is now connected using JID " + [[self jid] stringValue]];
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheConnectFail:(id)aStrophe
{
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheConnectionFailNotification object:self userInfo:[self JSStrophe]];
    [[self spinning] setHidden:YES];
    [[self message] setStringValue:@"strophe connection failed"];

    [[TNViewLog sharedLogger] log:@"Strophe connection failed"];
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheDisconnected:(id)sStrophe
{
    var center = [CPNotificationCenter defaultCenter];
    [center postNotificationName:TNStropheDisconnectionNotification object:self userInfo:[self JSStrophe]];

    [[self jid] setStringValue:""];
    [[self password] setStringValue:""];

    localStorage.setItem("lastjid", JSON.stringify(""));
    localStorage.setItem("lastpassword", JSON.stringify(""));

    [[TNViewLog sharedLogger] log:@"Strophe is disconnected"];
}
@end