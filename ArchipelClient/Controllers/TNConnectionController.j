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

@import <StropheCappuccino/TNStropheIMClient.j>
@import <StropheCappuccino/TNStropheStanza.j>
@import <StropheCappuccino/TNStropheVCard.j>

@import "../Utils/EKShakeAnimation.j"
@import "../Views/TNModalWindow.j"
@import "../Views/TNSwitch.j"

@class CPLocalizedString
@class TNDatasourceRoster

function _get_query_parameter_with_name(name)
{
    name = name.replace(/[\[]/, "\\\[").replace(/[\]]/, "\\\]");

    var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);

    return results == null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}

TNConnectionControllerCurrentUserVCardRetreived = @"TNConnectionControllerCurrentUserVCardRetreived";
TNConnectionControllerConnectionStarted         = @"TNConnectionControllerConnectionStarted";

var TNConnectionControllerForceResource,
    TNConnectionControllerForceJIDDomain,
    TNArchipelForcedServiceURL,
    TNArchipelForcedJIDDomain,
    TNArchipelServiceTemplate;

/*! @ingroup archipelcore
    subclass of CPWindow that allows to manage connection to XMPP Server
*/
@implementation TNConnectionController : CPObject
{
    @outlet CPButton            buttonConnect;
    @outlet CPImageView         imageViewSpinning;
    @outlet CPSecureTextField   fieldPassword;
    @outlet CPTextField         fieldService;
    @outlet CPTextField         fieldJID;
    @outlet CPTextField         labelService;
    @outlet CPTextField         labelMessage;
    @outlet TNSwitch            switchCredentialRemember;

    @outlet TNModalWindow       mainWindow              @accessors(readonly);

    TNStropheVCard              _userVCard              @accessors(property=userVCard);
}

#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    var bundle = [CPBundle mainBundle];

    TNArchipelServiceTemplate            = [bundle objectForInfoDictionaryKey:@"TNArchipelServiceTemplate"];
    TNConnectionControllerForceResource  = !![bundle objectForInfoDictionaryKey:@"TNArchipelForceService"];
    TNArchipelForcedServiceURL           = [bundle objectForInfoDictionaryKey:@"TNArchipelForcedServiceURL"];
    TNConnectionControllerForceJIDDomain = !![bundle objectForInfoDictionaryKey:@"TNArchipelForceJIDDomain"];
    TNArchipelForcedJIDDomain            = [bundle objectForInfoDictionaryKey:@"TNArchipelForcedJIDDomain"];
}

/*! initialize the window when CIB is loaded
*/
- (void)awakeFromCib
{
    var user     = _get_query_parameter_with_name("user"),
        pass     = _get_query_parameter_with_name("pass"),
        service  = _get_query_parameter_with_name("service");

    if (user)
    {
        [fieldJID setStringValue:user]
        if (!service)
            [fieldService setStringValue:TNArchipelServiceTemplate.replace("@DOMAIN@",user.split("@")[1])]
        else
            [fieldService setStringValue:service]
    }

    if (pass)
        [fieldPassword setStringValue:pass]

    [mainWindow setShowsResizeIndicator:NO];
    [mainWindow setDefaultButton:buttonConnect];

    [switchCredentialRemember setTarget:self];
    [switchCredentialRemember setAction:@selector(rememberCredentials:)];

    [[mainWindow contentView] applyShadow];

    [buttonConnect setBezelStyle:CPRoundedBezelStyle];

    [fieldPassword setSecure:YES];
    [fieldPassword setNeedsLayout];

    if (!TNConnectionControllerForceResource)
        [[CPNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_didJIDChange:)
                                                     name:CPControlTextDidChangeNotification
                                                   object:fieldJID];
}


#pragma mark -
#pragma mark Notification handlers

- (void)_didReceiveUserVCard:(CPNotification)aNotification
{
    _userVCard = [[TNStropheVCard alloc] initWithXMLNode:[[aNotification userInfo] firstChildWithName:@"vCard"]];
    [[CPNotificationCenter defaultCenter] postNotificationName:TNConnectionControllerCurrentUserVCardRetreived object:self];
}

- (void)_didJIDChange:(CPNotification)aNotification
{
    var current_domain = [fieldJID stringValue].split("@")[1];

    if (current_domain)
        [fieldService setStringValue:TNArchipelServiceTemplate.replace("@DOMAIN@",current_domain)]
        [self _saveCredentials];
}


#pragma mark -
#pragma mark Utils

/*! Initialize credentials informations according to the Application Defaults
*/
- (void)initCredentials
{
    [self _prepareCredentialRemember];
    [self _prepareJID];
    [self _prepareService];
    [self _preparePassword];

    if ([[fieldPassword stringValue] length])
        [self connect:nil];
}

- (void)_prepareCredentialRemember
{
    var lastCredsRemember = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNArchipelRememberCredentials"];

    [switchCredentialRemember setOn:lastCredsRemember animated:NO sendAction:NO];
}

- (void)_prepareJID
{
    var lastJID = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNArchipelXMPPJID"];

    try { [fieldJID setStringValue:[[TNStropheJID stropheJIDWithString:lastJID] bare]]; } catch (e) {};
}

- (void)_preparePassword
{
    var lastPassword = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNArchipelXMPPPassword"];

    if ([fieldPassword stringValue] == @"")
        [fieldPassword setStringValue:lastPassword];
}

- (void)_prepareService
{
    // This is forced. Nothing can change, so we just set it.
    if (TNConnectionControllerForceResource)
    {
        [fieldService setStringValue:TNArchipelForcedServiceURL];
        [fieldService setHidden:YES];
        [labelService setHidden:YES];

        var windowFrame = [[mainWindow contentView] frameSize];
        windowFrame.height -= 26;
        [mainWindow setFrameSize:windowFrame];
        [mainWindow center];
        return;
    }

    var lastService = [[CPUserDefaults standardUserDefaults] objectForKey:@"TNArchipelXMPPService"];

    if ([fieldService stringValue] == @"")
        [fieldService setStringValue:lastService];
}

- (void)_saveCredentials
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if (![switchCredentialRemember isOn])
    {
        [defaults removeObjectForKey:@"TNArchipelXMPPService"];
        [defaults removeObjectForKey:@"TNArchipelXMPPJID"];
        [defaults removeObjectForKey:@"TNArchipelXMPPPassword"];
        [defaults setBool:NO forKey:@"TNArchipelRememberCredentials"];
        return;
    }

    [defaults setObject:[fieldJID stringValue] forKey:@"TNArchipelXMPPJID"];
    [defaults setObject:[fieldPassword stringValue] forKey:@"TNArchipelXMPPPassword"];
    [defaults setObject:[fieldService stringValue] forKey:@"TNArchipelXMPPService"];
    [defaults setBool:YES forKey:@"TNArchipelRememberCredentials"];
}


#pragma mark -
#pragma mark Actions

/*! show the window
    @param sender the sender
*/
- (IBAction)showWindow:(id)sender
{
    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:nil];
}

/*! hide the window
    @param sender the sender
*/
- (IBAction)hideWindow:(id)sender
{
    [mainWindow close];
}

/*! connection action
    @param sender the sender
*/
- (IBAction)connect:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults],
        currentConnectionStatus = [[[TNStropheIMClient defaultClient] connection] currentStatus],
        connectionJID;

    if (currentConnectionStatus && currentConnectionStatus != Strophe.Status.DISCONNECTED && currentConnectionStatus != Strophe.Status.DISCONNECTING)
    {
        [[TNStropheIMClient defaultClient] disconnect];
        return;
    }

    if (![[fieldJID stringValue] length])
        return;

    if (!TNConnectionControllerForceJIDDomain)
    {
        try
        {
            connectionJID = [TNStropheJID stropheJIDWithString:[[fieldJID stringValue] lowercaseString]];
        }
        catch (e)
        {
            [labelMessage setStringValue:CPLocalizedString(@"Full JID required", @"Full JID required")];
            return;
        }
    }
    else
    {
        try
        {
            connectionJID = [[TNStropheJID alloc] init];
            [connectionJID setNode:[[fieldJID stringValue] lowercaseString]];
            [connectionJID setDomain:TNArchipelForcedJIDDomain];
        }
        catch (e)
        {
            [labelMessage setStringValue:CPLocalizedString(@"Node only JID required", @"Node only JID required")];
            return;
        }
    }

    [self _saveCredentials];

    [connectionJID setResource:[defaults objectForKey:@"TNArchipelXMPPResource"]];

    var stropheClient = [TNStropheIMClient IMClientWithService:[[fieldService stringValue] lowercaseString] JID:connectionJID password:[fieldPassword stringValue] rosterClass:TNDatasourceRoster];

    [stropheClient setDelegate:self];
    [stropheClient setDefaultClient];

    [[CPNotificationCenter defaultCenter] postNotificationName:TNConnectionControllerConnectionStarted object:self];
    [stropheClient connect];
}

- (IBAction)rememberCredentials:(id)sender
{
    [self _saveCredentials];
}

/*! delegate of TNStropheIMClient
    @param aStropheClient a TNStropheIMClient
    @param anError a string describing the error
*/
- (void)client:(TNStropheIMClient)aStropheClient errorCondition:(CPString)anError
{
    switch (anError)
    {
        case "host-unknown":
            [labelMessage setStringValue:CPLocalizedString(@"host-unreachable", @"host-unreachable")];
            break;
        default:
            [labelMessage setStringValue:anError || @"Error is unknown because empty"];
    }
    [buttonConnect setEnabled:YES];
    [buttonConnect setTitle:CPLocalizedString(@"connect", @"connect")];
    [imageViewSpinning setHidden:YES];
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheConnecting:(TNStropheIMClient)aStropheClient
{
    [labelMessage setStringValue:CPLocalizedString(@"connecting", @"connecting")];
    [buttonConnect setTitle:CPLocalizedString(@"cancel", @"cancel")];
    [buttonConnect setNeedsLayout];
    [imageViewSpinning setHidden:NO];
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheConnected:(TNStropheIMClient)aStropheClient
{
    [labelMessage setStringValue:CPLocalizedString(@"connected", @"connected")];
    [imageViewSpinning setHidden:YES];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveUserVCard:) name:TNStropheClientVCardReceivedNotification object:aStropheClient];
    [aStropheClient getVCard];

    CPLog.info(@"Strophe is now connected using JID " + [aStropheClient JID]);
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheConnectFail:(TNStropheIMClient)aStropheClient
{
    [imageViewSpinning setHidden:YES];
    [buttonConnect setEnabled:YES];
    [buttonConnect setTitle:CPLocalizedString(@"connect", @"connect")];
    [labelMessage setStringValue:CPLocalizedString(@"connection-failed", @"connection-failed")];

    CPLog.info(@"XMPP connection failed");
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheAuthenticating:(TNStropheIMClient)aStropheClient
{
    [labelMessage setStringValue:CPLocalizedString(@"authenticating", @"authenticating")];
    CPLog.info(@"XMPP authenticating...");
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheAuthFail:(TNStropheIMClient)aStropheClient
{
    [imageViewSpinning setHidden:YES];
    [buttonConnect setEnabled:YES];
    [buttonConnect setTitle:CPLocalizedString(@"connect", @"connect")];
    [labelMessage setStringValue:CPLocalizedString(@"authentification-failed", @"authentification-failed")];

    [[EKShakeAnimation alloc] initWithView:mainWindow._windowView];
    CPLog.info(@"XMPP auth failed");
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheError:(TNStropheIMClient)aStropheClient
{
    [imageViewSpinning setHidden:YES];
    [buttonConnect setEnabled:YES];
    [buttonConnect setTitle:CPLocalizedString(@"connect", @"connect")];
    [labelMessage setStringValue:CPLocalizedString(@"unknown-error", @"unknown-error")];

    CPLog.info(@"XMPP unknown error");
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheDisconnecting:(TNStropheIMClient)aStropheClient
{
    var currentConnectionStatus = [[aStropheClient connection] currentStatus];
    if (currentConnectionStatus && currentConnectionStatus != Strophe.Status.CONNECTED)
    {
        [self onStropheDisconnected:aStropheClient];
    }
    else
    {
        [imageViewSpinning setHidden:NO];
        [labelMessage setStringValue:CPLocalizedString(@"disconnecting", @"disconnecting")];
        CPLog.info(@"XMPP is disconnecting");
    }
}

/*! delegate of TNStropheIMClient
    @param aStropheClient TNStropheIMClient
*/
- (void)onStropheDisconnected:(TNStropheIMClient)aStropheClient
{
    [imageViewSpinning setHidden:YES];
    [buttonConnect setEnabled:YES];
    [buttonConnect setTitle:CPLocalizedString(@"connect", @"connect")];
    [labelMessage setStringValue:CPLocalizedString(@"disconnected", @"disconnected")];

    CPLog.info(@"XMPP connection is now disconnected");
}

@end
