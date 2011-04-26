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

@import <AppKit/CPButton.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTextField.j>

@import <StropheCappuccino/TNStropheStanza.j>
@import <TNKit/TNLocalizationCenter.j>

@import "../Model/TNDatasourceRoster.j"
@import "../Views/TNModalWindow.j"
@import "../Views/TNSwitch.j"



TNConnectionControllerCurrentUserVCardRetreived = @"TNConnectionControllerCurrentUserVCardRetreived";
TNConnectionControllerConnectionStarted         = @"TNConnectionControllerConnectionStarted";

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
    @outlet TNModalWindow   mainWindow              @accessors(readonly);
    @outlet TNSwitch        credentialRemember;

    BOOL                    _credentialRecovered    @accessors(getter=areCredentialRecovered);
    TNStropheStanza         _userVCard              @accessors(property=userVCard);

    BOOL                    _isConnecting;
    CPDictionary            _credentialsHistory;
}

#pragma mark -
#pragma mark Initialization

/*! initialize the window when CIB is loaded
*/
- (void)awakeFromCib
{
    _credentialRecovered = NO;
    _isConnecting = NO;

    [mainWindow setShowsResizeIndicator:NO];
    [mainWindow setDefaultButton:connectButton];

    [password setSecure:YES];
    [password setNeedsLayout]; // for some reasons, with XCode 4, setSecure doesn't work every time. this force it to relayout

    [credentialRemember setTarget:self];
    [credentialRemember setAction:@selector(rememberCredentials:)];

    [labelTitle setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"logon"]];
    [labelTitle setTextShadowOffset:CPSizeMake(0.0, 1.0)];
    [labelTitle setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];

    [labelJID setTextShadowOffset:CPSizeMake(0.0, 1.0)];
    [labelJID setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelJID setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"jid"]];

    [labelPassword setTextShadowOffset:CPSizeMake(0.0, 1.0)];
    [labelPassword setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelPassword setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"password"]];

    [labelBoshService setTextShadowOffset:CPSizeMake(0.0, 1.0)];
    [labelBoshService setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelBoshService setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"bosh-service"]];

    [labelRemember setTextShadowOffset:CPSizeMake(0.0, 1.0)];
    [labelRemember setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [labelRemember setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"remember"]];

    [message setTextShadowOffset:CPSizeMake(0.0, 1.0)];
    [message setValue:[CPColor whiteColor] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];

    [labelTitle setTextColor:[CPColor colorWithHexString:@"000000"]];

    [JID setToolTip:@"The JID to use to connect. It is always formatted like user@domain.com"];
    [password setToolTip:@"The password associated to your XMPP account"];
    [boshService setToolTip:@"The service BOSH (XMPP over HTTP) to use"];
    [credentialRemember setToolTip:@"Turn this ON to remember your credential and connect automatically. Note that "
        + @"all passwords are stored in clear in your browser local storage. It is extremly easy to find. So easy that you have to "
        + @"at your own risk. So we turn this in our disasventage, making your life easier. If you want to remove your credentials "
        + @"from the history, just be sure to have entered your JID and switch down the button.                \n"];

    [connectButton setBezelStyle:CPRoundedBezelStyle];
    [connectButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"connect"]];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didJIDChange:) name:CPControlTextDidChangeNotification object:JID];
}


#pragma mark -
#pragma mark Notification handlers

- (void)_didReceiveUserVCard:(CPNotification)aNotification
{
    _userVCard = [[aNotification userInfo] firstChildWithName:@"vCard"];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNConnectionControllerCurrentUserVCardRetreived object:self];
}

- (void)_didJIDChange:(CPNotification)aNotification
{
    if ([_credentialsHistory containsKey:[JID stringValue]])
    {
        [password setStringValue:[[_credentialsHistory objectForKey:[JID stringValue]] objectForKey:@"password"]];
        [boshService setStringValue:[[_credentialsHistory objectForKey:[JID stringValue]] objectForKey:@"service"]];
        [credentialRemember setOn:YES animated:YES sendAction:NO];
    }
    else
    {
        [password setStringValue:nil];
        [boshService setStringValue:nil];
        [credentialRemember setOn:NO animated:YES sendAction:NO];
    }
}


#pragma mark -
#pragma mark Utils

/*! Initialize credentials informations according to the Application Defaults
*/
- (void)initCredentials
{

    var defaults            = [CPUserDefaults standardUserDefaults],
        lastBoshService     = [defaults objectForKey:@"TNArchipelBOSHService"],
        lastJID             = [defaults objectForKey:@"TNArchipelBOSHJID"],
        lastPassword        = [defaults objectForKey:@"TNArchipelBOSHPassword"],
        lastRememberCred    = [defaults objectForKey:@"TNArchipelBOSHRememberCredentials"];

    _credentialsHistory = [defaults objectForKey:@"TNArchipelBOSHCredentialHistory"] || [CPDictionary dictionary];

    if (lastBoshService)
        [boshService setStringValue:lastBoshService];

    if (lastJID && lastJID != @"")
        [JID setStringValue:[[TNStropheJID stropheJIDWithString:lastJID] bare]];

    [self _didJIDChange:nil];

    if ([credentialRemember isOn])
    {
        _credentialRecovered = YES;
        [password setStringValue:lastPassword];
        [self connect:nil];
    }
}

/*! add History token
*/
- (void)saveCredentialsInHistory
{
    if ([_credentialsHistory containsKey:[JID stringValue]])
        return;

    var historyToken = [CPDictionary dictionaryWithObjectsAndKeys:[password stringValue], @"password",
                                                                  [boshService stringValue], @"service"];

    [_credentialsHistory setObject:historyToken forKey:[JID stringValue]];
    [[CPUserDefaults standardUserDefaults] setObject:_credentialsHistory forKey:@"TNArchipelBOSHCredentialHistory" inDomain:CPGlobalDomain];
}

/*! add History token
*/
- (void)clearCredentialFromHistory
{
    [_credentialsHistory removeObjectForKey:[JID stringValue]];
    [[CPUserDefaults standardUserDefaults] setObject:_credentialsHistory forKey:@"TNArchipelBOSHCredentialHistory" inDomain:CPGlobalDomain];
}

/*! will handle the clear after user logout
*/
- (void)userLogout
{
    [JID setStringValue:nil];
    [password setStringValue:nil];
    [credentialRemember setOn:YES animated:YES sendAction:YES];
}


#pragma mark -
#pragma mark Actions

/*! show the window
    @param sender the sender
*/
- (IBAction)showWindow:(id)sender
{
    [mainWindow center];
    [mainWindow makeKeyWindow];
    [mainWindow orderFontWithAnimation:nil];
}

/*! hide the window
    @param sender the sender
*/
- (IBAction)hideWindow:(id)sender
{
    [mainWindow orderOutWithAnimation:nil];
    [mainWindow close];
}

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

    var defaults = [CPUserDefaults standardUserDefaults];

    if ([credentialRemember isOn])
    {
        [self saveCredentialsInHistory];

        [defaults setObject:[JID stringValue] forKey:@"TNArchipelBOSHJID" inDomain:CPGlobalDomain];
        [defaults setObject:[password stringValue] forKey:@"TNArchipelBOSHPassword" inDomain:CPGlobalDomain];
        [defaults setObject:[boshService stringValue] forKey:@"TNArchipelBOSHService" inDomain:CPGlobalDomain];
        [defaults setBool:YES forKey:@"TNArchipelBOSHRememberCredentials" inDomain:CPGlobalDomain];
        _credentialRecovered = YES;
        CPLog.info("logging information saved");
    }
    else
    {
        _credentialRecovered = NO;
        [defaults setBool:NO forKey:@"TNArchipelLoginRememberCredentials" inDomain:CPGlobalDomain];
    }

    var connectionJID   = [TNStropheJID stropheJIDWithString:[[JID stringValue] lowercaseString]];


    if (![connectionJID domain])
    {
        [message setStringValue:@"Full JID required"];
        return;
    }

    [connectionJID setResource:[defaults objectForKey:@"TNArchipelBOSHResource"]];

    var stropheClient = [TNStropheIMClient IMClientWithService:[[boshService stringValue] lowercaseString] JID:connectionJID password:[password stringValue] rosterClass:TNDatasourceRoster];

    [stropheClient setDelegate:self];
    [stropheClient setDefaultClient];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNConnectionControllerConnectionStarted object:self];
    _isConnecting = YES;
    [stropheClient connect];
}

- (IBAction)rememberCredentials:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if ([credentialRemember isOn])
    {
        [self saveCredentialsInHistory];

        [defaults setBool:YES forKey:@"TNArchipelBOSHRememberCredentials" inDomain:CPGlobalDomain];
    }
    else
    {
        [self clearCredentialFromHistory];

        [defaults setBool:NO forKey:@"TNArchipelBOSHRememberCredentials" inDomain:CPGlobalDomain];
        [defaults removeObjectForKey:@"TNArchipelBOSHJID" inDomain:CPGlobalDomain];
        [defaults removeObjectForKey:@"TNArchipelBOSHPassword" inDomain:CPGlobalDomain];
    }


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
    [connectButton setNeedsLayout];
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
    [[CPUserDefaults standardUserDefaults] setBool:NO forKey:@"TNArchipelBOSHRememberCredentials" inDomain:CPGlobalDomain];
    [spinning setHidden:YES];
    [connectButton setEnabled:YES];
    [connectButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"connect"]];
    [message setStringValue:[[TNLocalizationCenter defaultCenter] localize:@"disconnected"]];

    CPLog.info(@"XMPP connection is now disconnected");
}

@end
