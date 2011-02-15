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

@import "../Model/TNDatasourceRoster.j"


TNConnectionControllerCurrentUserVCardRetreived = @"TNConnectionControllerCurrentUserVCardRetreived";

/*! @ingroup archipelcore
    subclass of CPWindow that allows to manage connection to XMPP Server
*/
@implementation TNConnectionController : CPObject
{
    @outlet CPButton        connectButton;
    @outlet CPImageView     spinning;
    @outlet CPTextField     boshService;
    @outlet CPTextField     JID;
    @outlet CPTextField     labelBoshService;
    @outlet CPTextField     labelJID;
    @outlet CPTextField     labelPassword;
    @outlet CPTextField     labelRemember;
    @outlet CPTextField     labelTitle;
    @outlet CPTextField     message;
    @outlet CPTextField     password;
    @outlet TNModalWindow   mainWindow          @accessors(readonly);
    @outlet TNSwitch        credentialRemember;

    TNStropheStanza         _userVCard          @accessors(property=userVCard);
    BOOL                    _isConnecting;
}

#pragma mark -
#pragma mark Initialization

/*! initialize the window when CIB is loaded
*/
- (void)awakeFromCib
{
    [mainWindow setShowsResizeIndicator:NO];
    [mainWindow setDefaultButton:connectButton];

    [password setSecure:YES];
    [credentialRemember setTarget:self];
    [credentialRemember setAction:@selector(rememberCredentials:)];

    [labelTitle setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"logon"]];
    [labelTitle setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelTitle setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];

    [labelJID setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelJID setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelJID setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"jid"]];

    [labelPassword setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelPassword setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelPassword setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"password"]];

    [labelBoshService setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelBoshService setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelBoshService setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"bosh-service"]];

    [labelRemember setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [labelRemember setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelRemember setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"remember"]];

    [message setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [message setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];

    [labelTitle setTextColor:[CPColor colorWithHexString:@"000000"]];

    [connectButton setBezelStyle:CPRoundedBezelStyle];
    [connectButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"connect"]];
    _isConnecting = NO;
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


#pragma mark -
#pragma mark Notification handlers

- (void)_didReceiveUserVCard:(CPNotification)aNotification
{
    _userVCard = [[aNotification userInfo] firstChildWithName:@"vCard"];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNConnectionControllerCurrentUserVCardRetreived object:self];
}

#pragma mark -
#pragma mark Actions

/*! connection action
    @param sender the sender
*/
- (IBAction)connect:(id)sender
{
    if (_isConnecting)
    {
        _isConnecting = NO;
        [[TNStropheIMClient defaultClient] disconnect];
        return;
    }

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

    var connectionJID = [TNStropheJID stropheJIDWithString:[[JID stringValue] lowercaseString]];

    if (![connectionJID domain])
    {
        [message setStringValue:@"Full JID required"];
        return;
    }

    [connectionJID setResource:[defaults objectForKey:@"TNArchipelBOSHResource"]];

    var stropheClient = [TNStropheIMClient IMClientWithService:[[boshService stringValue] lowercaseString] JID:connectionJID password:[password stringValue] rosterClass:TNDatasourceRoster];

    [stropheClient setDelegate:self];
    [stropheClient setDefaultClient];

    _isConnecting = YES;
    [stropheClient connect];
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


/*! delegate of TNStropheIMClient
    @param aStropheClient a TNStropheIMClient
    @param anError a string describing the error
*/
- (void)client:(TNStropheIMClient)aStropheClient errorCondition:(CPString)anError
{
    _isConnecting = NO;

    switch (anError)
    {
        case "host-unknown":
            [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"host-unreachable"]];
            break;
        default:
            [message setStringValue:anError];
    }
    [connectButton setEnabled:YES];
    [connectButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"connect"]];
    [spinning setHidden:YES];
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheConnecting:(TNStropheIMClient)aStropheClient
{
    _isConnecting = YES;

    [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"connecting"]];
    [connectButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"cancel"]];
    [spinning setHidden:NO];
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheConnected:(TNStropheIMClient)aStropheClient
{
    _isConnecting = NO;

    [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"connected"]];
    [spinning setHidden:YES];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveUserVCard:) name:TNStropheClientVCardReceived object:aStropheClient];
    [aStropheClient getVCard];

    CPLog.info(@"Strophe is now connected using JID " + [aStropheClient JID]);
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheConnectFail:(TNStropheIMClient)aStropheClient
{
    _isConnecting = NO;

    [spinning setHidden:YES];
    [connectButton setEnabled:YES];
    [connectButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"connect"]];
    [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"connection-failed"]];

    CPLog.info(@"XMPP connection failed");
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheAuthenticating:(TNStropheIMClient)aStropheClient
{
    [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"authenticating"]];

    CPLog.info(@"XMPP authenticating...");
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheAuthFail:(TNStropheIMClient)aStropheClient
{
    _isConnecting = NO;

    [spinning setHidden:YES];
    [connectButton setEnabled:YES];
    [connectButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"connect"]];
    [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"authentification-failed"]];

    CPLog.info(@"XMPP auth failed");
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheError:(TNStropheIMClient)aStropheClient
{
    _isConnecting = NO;

    [spinning setHidden:YES];
    [connectButton setEnabled:YES];
    [connectButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"connect"]];
    [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"unknown-error"]];

    CPLog.info(@"XMPP unknown error");
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheDisconnecting:(TNStropheIMClient)aStropheClient
{
    [spinning setHidden:NO];
    [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"disconnecting"]];

    CPLog.info(@"XMPP is disconnecting");
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheDisconnected:(TNStropheIMClient)aStropheClient
{
    [[CPUserDefaults standardUserDefaults] setBool:NO forKey:@"TNArchipelBOSHRememberCredentials"];
    [spinning setHidden:YES];
    [connectButton setEnabled:YES];
    [connectButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"connect"]];
    [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"disconnected"]];

    CPLog.info(@"XMPP connection is now disconnected");
}

@end
