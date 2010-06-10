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



/*! @ingroup archipelcore
    subclass of CPWindow that allows to manage connection to XMPP Server
*/
@implementation TNWindowConnection: TNWhiteWindow
{
    @outlet CPImageView spinning;
    @outlet CPTextField JID;
    @outlet CPTextField message;
    @outlet CPTextField password;
    @outlet CPTextField boshService;
    @outlet CPCheckBox  credentialRemember;

    TNStropheConnection _stropheConnection  @accessors(property=stropheConnection);
}

/*! initialize the window when CIB is loaded
*/
- (void) awakeFromCib
{
    [password setSecure:YES];
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
       [boshService setStringValue:lastBoshService];
    
   if (lastRememberCred)
   {
       [JID setStringValue:lastJID];
       [password setStringValue:lastPassword];
       [credentialRemember setState:CPOnState];
   }
   else
       [credentialRemember setState:CPOffState];

   if (lastRememberCred)
       [self connect:nil];
}

/*! connection action
    @param sender the sender
*/
- (IBAction)connect:(id)sender
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    var bundle      = [CPBundle bundleForClass:[self class]];
    
    if ([credentialRemember state] == CPOnState)
    {
        [defaults setObject:[JID stringValue] forKey:@"loginJID"];
        [defaults setObject:[password stringValue] forKey:@"loginPassword"];
        [defaults setObject:[boshService stringValue] forKey:@"loginService"];
        [defaults setBool:YES forKey:@"loginRememberCredentials"];

        CPLog.info("logging information saved");
    }
    else
    {
        [defaults setBool:NO forKey:@"loginRememberCredentials"];
    }
    
    _stropheConnection = [TNStropheConnection connectionWithService:[boshService stringValue] JID:[JID stringValue] password:[password stringValue]];
    [_stropheConnection setDebugMode:[bundle objectForInfoDictionaryKey:@"TNStropheCappuccinoDebugMode"]];
    [_stropheConnection setDelegate:self];
    [_stropheConnection connect];
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
- (void)onStropheConnecting:(TNStropheConnection)aStrophe
{
    [message setStringValue:@"Connecting"];
    [spinning setHidden:NO];
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheConnected:(TNStropheConnection)aStrophe
{
    [message setStringValue:@"Connected."];
    [spinning setHidden:YES];
    
    CPLog.info(@"Strophe is now connected using JID " + [JID stringValue]);
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheConnectFail:(TNStropheConnection)aStrophe
{
    [spinning setHidden:YES];
    [message setStringValue:@"Connection failed."];

    CPLog.info("XMPP connection failed");
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheAuthenticating:(TNStropheConnection)aStrophe
{
    [message setStringValue:@"Authenticating..."];

    CPLog.info("XMPP authenticating...");
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheAuthFail:(TNStropheConnection)aStrophe
{
    [spinning setHidden:YES];
    [message setStringValue:@"Authentication failed."];

    CPLog.info("XMPP auth failed");
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheError:(TNStropheConnection)aStrophe
{
    [spinning setHidden:YES];
    [message setStringValue:@"Unknown error."];

    CPLog.info("XMPP unknown error");
}

-(void) onStropheDisconnecting:(TNStropheConnection)aStrophe
{
    //[spinning setHidden:YES];
    [message setStringValue:@"Disconnecting."];

   CPLog.info("XMPP is disconnecting");
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheDisconnected:(id)sStrophe
{
    var defaults = [TNUserDefaults standardUserDefaults];
    [self initCredentials];
    
    [message setStringValue:@"Disconnected."];
    
    CPLog.info("XMPP connection is now disconnected");
}
@end