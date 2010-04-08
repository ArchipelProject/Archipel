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
}

/*! initialize the window when CIB is loaded
*/
- (void) awakeFromCib
{
    [[self password] setSecure:YES];
    [self setShowsResizeIndicator:NO];
    
    [self initCredentials];
}

/*! Initialize credentials informations according to the Application Defaults
*/
- (void)initCredentials
{
    var defaults            = [TNUserDefaults standardUserDefaults];

   var lastBoshService     = [defaults stringForKey:@"loginService"];
   var lastJID             = [defaults stringForKey:@"loginJID"];
   var lastPassword        = [defaults stringForKey:@"loginPassword"];
   var lastRememberCred    = [defaults boolForKey:@"loginRememberCredentials"];

   if (lastBoshService)
       [[self boshService] setStringValue:lastBoshService];
    
   if (lastRememberCred)
   {
       [[self jid] setStringValue:lastJID];
       [[self password] setStringValue:lastPassword];
       [[self credentialRemember] setState:CPOnState];
   }
   else
       [[self credentialRemember] setState:CPOffState];

   if (lastRememberCred)
       [self connect:nil];
}

/*! connection action
    @param sender the sender
*/
- (IBAction)connect:(id)sender
{
    var defaults = [TNUserDefaults standardUserDefaults];
    [defaults stringForKey:@"loginService"];
    
    if ([[self credentialRemember] state] == CPOnState)
    {
        CPLog.info("Saving logging information");
        [defaults setObject:[jid stringValue] forKey:@"loginJID"];
        [defaults setObject:[password stringValue] forKey:@"loginPassword"];
        [defaults setObject:[boshService stringValue] forKey:@"loginService"];
        [defaults setBool:YES forKey:@"loginRememberCredentials"];
    }
    else
    {
        [defaults setBool:NO forKey:@"loginRememberCredentials"];
    }

    [self setJSStrophe:[TNStropheConnection connectionWithService:[boshService stringValue] jid:[jid stringValue] password:[password stringValue]]];
    [[self JSStrophe] setDelegate:self];
    [[self JSStrophe] connect];
}

- (IBAction)rememberCredentials:(id)sender
{
    var defaults = [TNUserDefaults standardUserDefaults];
    
    if ([sender state] == CPOnState)
        [defaults setBool:YES forKey:@"loginRememberCredentials"];
    else
        [defaults setBool:NO forKey:@"loginRememberCredentials"];
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
    
    CPLog.info("XMPP connection sucessfull");
    
    // [[TNViewLog sharedLogger] log:@"Strophe is now connected using JID " + [[self jid] stringValue]];
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

    CPLog.info("XMPP connection failed");
    
    // [[TNViewLog sharedLogger] log:@"Strophe connection failed"];
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheDisconnected:(id)sStrophe
{
    var center = [CPNotificationCenter defaultCenter];
    var defaults = [TNUserDefaults standardUserDefaults];
    
    [center postNotificationName:TNStropheDisconnectionNotification object:self userInfo:[self JSStrophe]];
    
    [self initCredentials];
    
    CPLog.info("XMPP connection is now disconnected");
}
@end