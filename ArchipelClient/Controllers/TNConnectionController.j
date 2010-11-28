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
@implementation TNConnectionController : CPObject
{
    @outlet CPButton        connectButton;
    @outlet TNSwitch        credentialRemember;
    @outlet CPImageView     spinning;
    @outlet CPTextField     boshService;
    @outlet CPTextField     JID;
    @outlet CPTextField     message;
    @outlet CPTextField     password;
    @outlet CPTextField     labelPassword;
    @outlet CPTextField     labelBoshService;
    @outlet CPTextField     labelJID;
    @outlet CPTextField     labelRemeber;
    @outlet CPTextField     labelTitle;
    @outlet TNModalWindow   mainWindow @accessors(readonly);



    TNStropheConnection _stropheConnection  @accessors(property=stropheConnection);
}

/*! initialize the window when CIB is loaded
*/
- (void)awakeFromCib
{
    [mainWindow setShowsResizeIndicator:NO];
    [mainWindow setDefaultButton:connectButton];

    [password setSecure:YES];
    [credentialRemember setTarget:self];
    [credentialRemember setAction:@selector(rememberCredentials:)];


    [labelTitle setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelTitle setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelJID setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelJID setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelPassword setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelPassword setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelBoshService setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelBoshService setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelRemeber setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelRemeber setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [message setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [message setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];

    [labelTitle setTextColor:[CPColor colorWithHexString:@"000000"]];

    [connectButton setBezelStyle:CPRoundedBezelStyle];
}

/*! Initialize credentials informations according to the Application Defaults
*/
- (void)initCredentials
{
    var defaults            = [CPUserDefaults standardUserDefaults],
        lastBoshService     = [defaults stringForKey:@"TNArchipelBOSHService"],
        lastJID             = [defaults stringForKey:@"TNArchipelBOSHJID"],
        lastPassword        = [defaults stringForKey:@"TNArchipelBOSHPassword"],
        lastRememberCred    = [defaults boolForKey:@"TNArchipelBOSHRememberCredentials"];

    if (lastBoshService)
        [boshService setStringValue:lastBoshService];

    if (lastRememberCred)
    {
        if (lastJID && lastJID != @"")
            [JID setStringValue:[[TNStropheJID stropheJIDWithString:lastJID] bare]];
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
    var defaults    = [CPUserDefaults standardUserDefaults];

    if ([credentialRemember state] == CPOnState)
    {
        [defaults setObject:[JID stringValue] forKey:@"TNArchipelBOSHJID"];
        [defaults setObject:[password stringValue] forKey:@"TNArchipelBOSHPassword"];
        [defaults setObject:[boshService stringValue] forKey:@"TNArchipelBOSHService"];
        [defaults setBool:YES forKey:@"TNArchipelBOSHRememberCredentials"];

        CPLog.info("logging information saved");
    }
    else
    {
        [defaults setBool:NO forKey:@"TNArchipelLoginRememberCredentials"];
    }

    _stropheConnection = [TNStropheConnection connectionWithService:[boshService stringValue] JID:[TNStropheJID stropheJIDWithString:[JID stringValue]] password:[password stringValue]];

    [[_stropheConnection JID] setResource:[defaults objectForKey:@"TNArchipelBOSHResource"]];
    [_stropheConnection setDelegate:self];
    [_stropheConnection connect];
}

- (IBAction)rememberCredentials:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if ([sender state] == CPOnState)
        [defaults setBool:YES forKey:@"TNArchipelBOSHRememberCredentials"];
    else
        [defaults setBool:NO forKey:@"TNArchipelBOSHRememberCredentials"];

    CPLog.debug("credential remember set");
}


/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)connection:(TNStropheConnection)aStrophe errorCondition:(CPString)anError
{
    switch (anError)
    {
        case "host-unknown":
            [message setStringValue:@"Host unreachable"];
            break;
        default:
            [message setStringValue:anError];
    }
    [connectButton setEnabled:YES];
    [spinning setHidden:YES];
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheConnecting:(TNStropheConnection)aStrophe
{
    [message setStringValue:@"Connecting..."];
    [connectButton setEnabled:NO];
    [spinning setHidden:NO];
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheConnected:(TNStropheConnection)aStrophe
{
    [message setStringValue:@"Connected"];
    [spinning setHidden:YES];

    CPLog.info(@"Strophe is now connected using JID " + [JID stringValue]);
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheConnectFail:(TNStropheConnection)aStrophe
{
    [spinning setHidden:YES];
    [connectButton setEnabled:YES];
    [message setStringValue:@"Connection failed"];

    CPLog.info(@"XMPP connection failed");
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheAuthenticating:(TNStropheConnection)aStrophe
{
    [message setStringValue:@"Authenticating..."];
    CPLog.info(@"XMPP authenticating...");
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheAuthFail:(TNStropheConnection)aStrophe
{
    [spinning setHidden:YES];
    [connectButton setEnabled:YES];
    [message setStringValue:@"Authentication failed"];

    CPLog.info(@"XMPP auth failed");
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheError:(TNStropheConnection)aStrophe
{
    [spinning setHidden:YES];
    [connectButton setEnabled:YES];
    [message setStringValue:@"Unknown error"];

    CPLog.info(@"XMPP unknown error");
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheDisconnecting:(TNStropheConnection)aStrophe
{
    [spinning setHidden:NO];
    [connectButton setEnabled:NO];
    [message setStringValue:@"Disconnecting..."];

   CPLog.info(@"XMPP is disconnecting");
}

/*! delegate of TNStropheConnection
    @param aStrophe TNStropheConnection
*/
- (void)onStropheDisconnected:(id)sStrophe
{
    defaults = [CPUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:@"TNArchipelBOSHRememberCredentials"]
    [spinning setHidden:YES];
    [connectButton setEnabled:YES];
    [message setStringValue:@"Disconnected"];

    CPLog.info(@"XMPP connection is now disconnected");
}
@end