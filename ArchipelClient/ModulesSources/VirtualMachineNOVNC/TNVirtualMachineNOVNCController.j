/*
 * TNViewHypervisorControl.j
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
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPPopover.j>

@import <LPKit/LPMultiLineTextField.j>
@import <VNCCappuccino/VNCCappuccino.j>

@import "../../Views/TNSwitch.j"
@import "../../Model/TNModule.j"
@import "TNExternalVNCWindow.j"
@import "TNZoomAnimation.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


var TNArchipelPushNotificationVNC                   = @"archipel:push:virtualmachine:vnc",
    TNArchipelTypeVirtualMachineVNC                 = @"archipel:virtualmachine:vnc",
    TNArchipelTypeVirtualMachineVNCDisplay          = @"display",
    TNArchipelVNCInformationRecoveredNotification   = @"TNArchipelVNCInformationRecoveredNotification",
    TNArchipelVNCShowExternalWindowNotification     = @"TNArchipelVNCShowExternalWindowNotification",
    TNArchipelDefinitionUpdatedNotification         = @"TNArchipelDefinitionUpdatedNotification";

TNArchipelVNCScreenTypeVNC = @"vnc";
TNArchipelVNCScreenTypeSPICE = @"spice";

/*! @ingroup virtualmachinenovnc
    module that allow to access virtual machine console using VNC
*/
@implementation TNVirtualMachineNOVNCController : TNModule
{
    @outlet CPButton                buttonAddCertificateException;
    @outlet CPButton                buttonExternalWindow;
    @outlet CPButton                buttonGetPasteBoard;
    @outlet CPButton                buttonPasswordSend;
    @outlet CPButton                buttonPasteBoardSend;
    @outlet CPButton                buttonSendCtrlAtlDel;
    @outlet CPButton                buttonSendPasteBoard;
    @outlet CPButton                buttonZoomFitToWindow;
    @outlet CPButton                buttonZoomReset;
    @outlet CPCheckBox              checkboxPasswordRemember;
    @outlet CPImageView             imageViewSecureConnection;
    @outlet CPPopover               popoverPasteBoard;
    @outlet CPSlider                sliderScaling;
    @outlet CPTextField             fieldPassword;
    @outlet CPTextField             fieldPreferencesCheckRate;
    @outlet CPTextField             fieldPreferencesFBURefreshRate;
    @outlet CPTextField             labelErrorInformation;
    @outlet CPView                  viewConnectionErrorHelp;
    @outlet CPView                  viewControls;
    @outlet CPView                  viewVNCContainer;
    @outlet CPWindow                windowPassword;
    @outlet LPMultiLineTextField    fieldPasteBoard;
    @outlet TNSwitch                switchPreferencesPreferSSL;

    BOOL                            _useSSL;
    BOOL                            _onlySSL;
    BOOL                            _supportsSSL;
    CPString                        _remoteScreenType;
    CPString                        _url;
    CPString                        _VMHost;
    CPString                        _remoteScreenDirectPort;
    CPString                        _remoteScreenProxyPort;
    TNVNCView                       _vncView;
    TNSpiceView                     _spiceView
}


#pragma mark -
#pragma mark Initialization

/*! initialize some value at CIB awakening
*/
- (void)awakeFromCib
{
    [windowPassword setDefaultButton:buttonPasswordSend];

    var bundle  = [CPBundle bundleForClass:[self class]],
        defaults    = [CPUserDefaults standardUserDefaults];

    [imageViewSecureConnection setHidden:YES];
    [imageViewSecureConnection setImage:CPImageInBundle(@"secure.png", CGSizeMake(16.0, 16.0), bundle)];

    // register defaults defaults
    [defaults registerDefaults:@{
        @"NOVNCPreferSSL":[bundle objectForInfoDictionaryKey:@"NOVNCPreferSSL"],
        @"NOVNCFBURate"  :[bundle objectForInfoDictionaryKey:@"NOVNCFBURate"],
        @"NOVNCheckRate" :[bundle objectForInfoDictionaryKey:@"NOVNCheckRate"]
    }];

    var imageZoomFit = CPImageInBundle(@"IconsButtons/fullscreen.png", CGSizeMake(16, 16), [CPBundle mainBundle]),
        imageZoomReset = CPImageInBundle(@"IconsButtons/reset.png", CGSizeMake(16, 16), [CPBundle mainBundle]),
        imageDirectAccess = CPImageInBundle(@"IconsButtons/screen.png", CGSizeMake(16, 16), [CPBundle mainBundle]),
        imageCtrlAltDel = CPImageInBundle(@"skull.png", CGSizeMake(16, 16), bundle),
        imageSendPasteBoard = CPImageInBundle(@"sendPasteBoard.png", CGSizeMake(16, 16), bundle),
        imageGetPasteBoard = CPImageInBundle(@"getPasteBoard.png", CGSizeMake(16, 16), bundle);

    [viewControls setBackgroundColor:[CPColor whiteColor]];
    viewControls._DOMElement.style.borderTop = "1px solid #f2f2f2";
    [buttonZoomFitToWindow setImage:imageZoomFit];
    [buttonZoomReset setImage:imageZoomReset];
    [buttonExternalWindow setImage:imageDirectAccess];
    [buttonSendCtrlAtlDel setImage:imageCtrlAltDel];
    [buttonSendPasteBoard setImage:imageSendPasteBoard];
    [buttonGetPasteBoard setImage:imageGetPasteBoard];

    var inset = CGInsetMake(2, 2, 2, 5);

    [buttonZoomFitToWindow setValue:inset forThemeAttribute:@"content-inset"];
    [buttonZoomReset setValue:inset forThemeAttribute:@"content-inset"];
    [buttonExternalWindow setValue:inset forThemeAttribute:@"content-inset"];
    [buttonSendCtrlAtlDel setValue:inset forThemeAttribute:@"content-inset"];
    [buttonSendPasteBoard setValue:inset forThemeAttribute:@"content-inset"];
    [buttonGetPasteBoard setValue:inset forThemeAttribute:@"content-inset"];

    [fieldPassword setSecure:YES];

    // VNC View
    _vncView = [[TNVNCView alloc] initWithFrame:CGRectMakeZero()];
    [_vncView setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxXMargin | CPViewMaxYMargin];

    // SPICE View
    _spiceView = [[TNSpiceView alloc] initWithFrame:CGRectMakeZero()];
    [_spiceView setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxXMargin | CPViewMaxYMargin];

    [sliderScaling setContinuous:YES];
    [sliderScaling setMinValue:0.2];
    [sliderScaling setMaxValue:2];

    [buttonAddCertificateException setThemeState:CPThemeStateDefault];

    // [viewVNCContainer setClipsToBounds:NO];

    [self _showConnectionHelp:NO];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willLoad
{
    if (![super willLoad])
        return NO;

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_showExternalScreen:)
                                                 name:TNArchipelVNCShowExternalWindowNotification
                                               object:nil];

   [[CPNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(_didDefinitionUpdated:)
                                                name:TNArchipelDefinitionUpdatedNotification
                                              object:nil];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationVNC];

    [self getVirtualMachineVNCDisplay];

    return YES;
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    _VMHost                 = nil;
    _remoteScreenProxyPort  = nil;
    _remoteScreenDirectPort = nil;
    _supportsSSL            = nil;
    _onlySSL                = nil;

    [fieldPassword setStringValue:@""];

    [super willUnload];
}

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [_vncView setHidden:YES];
    [_spiceView setHidden:YES];
    [self _showConnectionHelp:NO];

    [self handleDisplayVNCScreen];
    [[self view] setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [[self view] setFrame:[[[self view] superview] bounds]];

    return YES;
}

/*! called when module become unvisible
*/
- (void)willHide
{
    [imageViewSecureConnection setHidden:YES];
    [_vncView setHidden:YES];
    [_spiceView setHidden:YES];
    [self _showConnectionHelp:NO];

    [windowPassword close];

    if ([self isConnected])
    {
        [[self currentScreenView] disconnect:nil];
        [[self currentScreenView] unfocus];
    }

    [super willHide];
}

/*! call when user saves preferences
*/
- (void)savePreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults setInteger:[fieldPreferencesFBURefreshRate intValue] forKey:@"NOVNCFBURate"];
    [defaults setInteger:[fieldPreferencesCheckRate intValue] forKey:@"NOVNCheckRate"];
    [defaults setBool:[switchPreferencesPreferSSL isOn] forKey:@"NOVNCPreferSSL"];
}

/*! call when user gets preferences
*/
- (void)loadPreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [fieldPreferencesFBURefreshRate setIntValue:[defaults integerForKey:@"NOVNCFBURate"]];
    [fieldPreferencesCheckRate setIntValue:[defaults integerForKey:@"NOVNCheckRate"]];
    [switchPreferencesPreferSSL setOn:[defaults boolForKey:@"NOVNCPreferSSL"] animated:YES sendAction:NO];
}

#pragma mark -
#pragma mark Notification handlers

/*! called when TNArchipelPushNotificationVNC is recieved
    @param somePushInfo CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    switch (change)
    {
        case @"websocketvncstart":
            [self getVirtualMachineVNCDisplay];
            break;

        case @"websocketvncstop":
            [self handleDisplayVNCScreen];
            break;
    }

    return YES;
}

/*! called when TNArchipelVNCShowExternalWindowNotification is received
    @param aNotification the notification
*/
- (void)_showExternalScreen:(CPNotification)aNotification
{
    [self openVNCInNewWindow];
}

/*! called when TNArchipelDefinitionUpdatedNotification is received
    it will request VNC information again.
    @param aNotification the notification
*/
- (void)_didDefinitionUpdated:(CPNotification)aNotification
{
    [self getVirtualMachineVNCDisplay];
}


#pragma mark -
#pragma mark Utilities

- (void)_switchViewAccordingToCurrentType
{
    switch (_remoteScreenType)
    {
        case TNArchipelVNCScreenTypeVNC:
            [_spiceView removeFromSuperview];
            [viewVNCContainer addSubview:_vncView];
            break;

        case TNArchipelVNCScreenTypeSPICE:
            [_vncView removeFromSuperview];
            [viewVNCContainer addSubview:_spiceView];
            break;
    }

    [self _centerScreenView];
}

- (TNRemoteScreenView)currentScreenView
{
    switch (_remoteScreenType)
    {
        case TNArchipelVNCScreenTypeVNC : return _vncView;
        case TNArchipelVNCScreenTypeSPICE : return _spiceView;
    }
}

- (void)_centerScreenView
{
    var frame = [viewVNCContainer bounds],
        centerX = frame.size.width / 2.0,
        centerY = frame.size.height / 2.0;

    [[self currentScreenView] setCenter:CGPointMake(centerX, centerY)];
}

/*! check if VNC is currenttly connected
    @return Boolean.
*/
- (BOOL)isConnected
{
    return ([_vncView state] != TNRemoteScreenViewStateDisconnected || [_vncView state] == TNRemoteScreenViewStateDisconnecting)
}

/*! Check if virtual machine is running. if not displays the masking view
*/
- (void)handleDisplayVNCScreen
{
    var conditionVMStatusOK = ([_entity XMPPShow] == TNStropheContactStatusOnline || [_entity XMPPShow] == TNStropheContactStatusAway);

    if (!conditionVMStatusOK || _remoteScreenProxyPort == -1|| !_remoteScreenProxyPort)
    {
        _VMHost                 = nil;
        _remoteScreenProxyPort  = nil;
        _remoteScreenDirectPort = nil;
        _supportsSSL            = nil;
        _onlySSL                = nil;

        if ([self isConnected])
        {
            [[self currentScreenView] unfocus];
            [[self currentScreenView] disconnect:nil];
        }

        [self _showConnectionHelp:NO];
        [[self currentScreenView] setHidden:YES];
        [self showMaskView:YES];

        return;
    }

    if (![self isVisible])
        return;

    var defaults = [CPUserDefaults standardUserDefaults],
        passwordKey = "TNArchipelNOVNCPasswordRememberFor" + [_entity JID],
        preferSSL = [defaults boolForKey:@"NOVNCPreferSSL"];

    if (_onlySSL || (preferSSL && _supportsSSL))
        _useSSL = YES;

    [sliderScaling setDoubleValue:1];

    if ([defaults stringForKey:passwordKey])
    {
        [fieldPassword setStringValue:[defaults stringForKey:passwordKey]];
        [checkboxPasswordRemember setState:CPOnState];
    }
    else
    {
        [fieldPassword setStringValue:@""];
        [checkboxPasswordRemember setState:CPOffState];
    }

    [self showMaskView:NO];

    [self _switchViewAccordingToCurrentType];

    var currentScreenView;
    switch (_remoteScreenType)
    {
        case TNArchipelVNCScreenTypeVNC:
            currentScreenView = [self _loadVNC];
            break;

        case TNArchipelVNCScreenTypeSPICE:
            currentScreenView = [self _loadSpice];
            break;

        default:
            [TNAlert showAlertWithMessage:@"Unknown screen type received"
                              informative:@"Screen type " + _remoteScreenType + " is not valid"
                                    style:CPCriticalAlertStyle];
            return;
    }

    try
    {
        [currentScreenView load];
        [currentScreenView connect:nil];
    }
    catch(e)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Websocket error for VNC", @"Websocket error for VNC")
                          informative:CPBundleLocalizedString(@"It seems your websocket configuration is not properly configured. If you are using Firefox, go to about:config and set 'network.websocket.override-security-block' and 'network.websocket.enabled' to 'True'.", @"It seems your websocket configuration is not properly configured. If you are using Firefox, go to about:config and set 'network.websocket.override-security-block' and 'network.websocket.enabled' to 'True'.")
                                style:CPCriticalAlertStyle];
        CPLog.error("Websocket problem. unable to start noVNC subsystem: " + e);
    }
}

- (void)_loadVNC
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [_vncView setCheckRate:[defaults integerForKey:@"NOVNCheckRate"]];
    [_vncView setFrameBufferRequestRate:[defaults integerForKey:@"NOVNCFBURate"]];
    [_vncView setHost:_VMHost];
    [_vncView setPort:_remoteScreenProxyPort];
    [_vncView setPassword:[fieldPassword stringValue]];
    [_vncView setZoom:1];
    [_vncView setTrueColor:YES];
    [_vncView setEncrypted:_useSSL];
    [_vncView setDelegate:self];

    CPLog.info("VNC: connecting to %@:%@  using SSL: %@", _VMHost, _remoteScreenProxyPort, _useSSL);

    return _vncView;
}

- (void)_loadSpice
{
    if (_spiceView)
        [_spiceView removeFromSuperview];

    // @TODO: this is a hack. If I keep the same _spiceView, then fantom canvas stay behind the main one.
    _spiceView = [[TNSpiceView alloc] initWithFrame:CGRectMakeZero()];
    [_spiceView setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [viewVNCContainer addSubview:_spiceView];

    [_spiceView setHost:_VMHost];
    [_spiceView setPort:_remoteScreenProxyPort];
    [_spiceView setPassword:[fieldPassword stringValue]];
    [_spiceView setZoom:1];
    [_spiceView setEncrypted:_useSSL];
    [_spiceView setDelegate:self];
    [self showMaskView:NO];

    CPLog.info("SPICE: connecting to %@:%@  using SSL: %@", _VMHost, _remoteScreenProxyPort, _useSSL);

    return _spiceView;
}

/*! create a zoom animation between two zoom factor
    @param aStartZoom float containing the initial zoom factor
    @param aEndZoom float containing the final zoom factor
*/
- (void)animateChangeScaleFrom:(float)aStartZoom to:(float)aEndZoom
{
    var defaults = [CPUserDefaults standardUserDefaults];

    if ([defaults boolForKey:@"TNArchipelUseAnimations"])
    {
        var anim = [[TNZoomAnimation alloc] initWithDuration:0.2 animationCurve:CPAnimationEaseOut];

        [anim setDelegate:self];
        [anim setStartZoomValue:aStartZoom];
        [anim setEndZoomValue:aEndZoom];
        [anim startAnimation];
    }
    else
    {
        [sliderScaling setDoubleValue:aEndZoom];
        [self changeScale:sliderScaling];
    }
}

/*! Open the VNCView in a new physical window
*/
- (void)openVNCInNewWindow
{
    if (_remoteScreenType !== TNArchipelVNCScreenTypeVNC)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"SPICE is not supported as external window", @"SPICE is not supported as external window")
                          informative:CPBundleLocalizedString(@"For now, you cannot use SPICE screen in external window", @"For now, you cannot use SPICE screen in external window")
                                style:CPWarningAlertStyle];
        return;
    }

    var winFrame = CGRectMake(100, 100, 800, 600),
        pfWinFrame = CGRectMake(100, 100, 800, 600),
        defaults = [CPUserDefaults standardUserDefaults],
        VNCWindow,
        platformVNCWindow;

    if ([CPPlatform isBrowser])
    {
        VNCWindow           = [[TNExternalVNCWindow alloc] initWithContentRect:winFrame styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask | CPBorderlessBridgeWindowMask];
        platformVNCWindow   = [[CPPlatformWindow alloc] initWithContentRect:pfWinFrame];

        [VNCWindow setPlatformWindow:platformVNCWindow];
        [platformVNCWindow orderFront:nil];
    }
    else
    {
        winFrame.origin.x = 20;
        winFrame.origin.y = 50;
        winFrame.size.height += 25;

        VNCWindow = [[TNExternalVNCWindow alloc] initWithContentRect:winFrame
                                                           styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask];
    }

    [VNCWindow loadVNCViewWithHost:_VMHost
                              port:_remoteScreenProxyPort
                              type:_remoteScreenType
                          password:[fieldPassword stringValue]
                           encrypt:_useSSL
                         trueColor:YES
                         checkRate:[defaults integerForKey:@"NOVNCheckRate"]
                           FBURate:[defaults integerForKey:@"NOVNCFBURate"]
                            entity:_entity];
}

/*! Shows the connection failure information
    @param shouldShow YES to show, NO to hide
*/
- (void)_showConnectionHelp:(BOOL)shouldShow
{
    if (!shouldShow)
    {
        [viewConnectionErrorHelp removeFromSuperview];
        return;
    }

    [labelErrorInformation setStringValue:[CPString stringWithFormat:@"Tried to connect to %@:%@ (SSL: %@)", _VMHost, _remoteScreenProxyPort, _useSSL]];

    [buttonAddCertificateException setTitle:CPBundleLocalizedString(@"Add Exception", @"Add Exception")];

    [viewConnectionErrorHelp setFrame:[viewVNCContainer bounds]];
    [viewVNCContainer addSubview:viewConnectionErrorHelp];
}


#pragma mark -
#pragma mark Actions

/*! Open the the external VNC window
    @param sender the sender of the action
*/
- (IBAction)openExternalWindow:(id)aSender
{
    [self openVNCInNewWindow];
}

/*! Open the pasteboard window
    @param sender the sender of the action
*/
- (IBAction)openPasteBoardWindow:(id)aSender
{
    [popoverPasteBoard close];
    [popoverPasteBoard showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [popoverPasteBoard setDefaultButton:buttonPasteBoardSend];
    [popoverPasteBoard makeFirstResponder:fieldPasteBoard];
}

/*! close the pasteboard window
    @param sender the sender of the action
*/
- (IBAction)closePasteBoardWindow:(id)aSender
{
    [popoverPasteBoard close];
}

/*! set the zoom factor
    @param sender the sender of the action
*/
- (IBAction)changeScale:(id)aSender
{
    [[self currentScreenView] setZoom:[aSender floatValue]];
    [self _centerScreenView];
}

/*! Make the VNCView fitting the maximum amount of space
    @param sender the sender of the action
*/
- (IBAction)fitToScreen:(id)aSender
{
    var visibleRect     = [viewVNCContainer frame],
        currentVNCSize  = [[self currentScreenView] displaySize],
        currentVNCZoom  = [[self currentScreenView] zoom],
        diffPerc        = ((visibleRect.size.height - currentVNCSize.height) / currentVNCSize.height),
        newZoom         = (diffPerc < 0) ? 1 - (Math.abs(diffPerc)) : 1 + (Math.abs(diffPerc));

    [self animateChangeScaleFrom:currentVNCZoom to:newZoom];
}

/*! Reset the zoom to 100%
    @param sender the sender of the action
*/
- (IBAction)resetZoom:(id)aSender
{
    var visibleRect = [[self currentScreenView] visibleRect],
        currentVNCSize = [[self currentScreenView] displaySize],
        currentVNCZoom = [[self currentScreenView] zoom];

    [self animateChangeScaleFrom:currentVNCZoom to:1];
}

/*! Send CTRL ALT DEL key combination to the VNCView
    @param sender the sender of the action
*/
- (IBAction)sendCtrlAltDel:(id)aSender
{
    CPLog.info("sending ctrl+alt+del to VNCView");
    [[self currentScreenView] sendCtrlAltDel:aSender];
}

/*! Send the content of the pasteboard to the VNCView
    @param sender the sender of the action
*/
- (IBAction)sendPasteBoard:(id)aSender
{
    CPLog.info("sending the content of Pasteboard to VNCView: " + [fieldPasteBoard stringValue]);

    [[self currentScreenView] sendTextToPasteboard:[fieldPasteBoard stringValue]];

    [fieldPasteBoard setStringValue:@""];

    [popoverPasteBoard close];
}

/*! remeber the password
    @param sender the sender of the action
*/
- (IBAction)rememberPassword:(id)aSender
{
    var defaults = [CPUserDefaults standardUserDefaults],
        key = "TNArchipelNOVNCPasswordRememberFor" + [_entity JID];

    if ([checkboxPasswordRemember state] == CPOnState)
        [defaults setObject:[fieldPassword stringValue] forKey:key];
    else
        [defaults setObject:@"" forKey:key];
}

/*! change the password
    @param sender the sender of the action
*/
- (IBAction)changePassword:(id)aSender
{
    [self rememberPassword:nil];
    [windowPassword close];
    if (([[self currentScreenView] state] == TNRemoteScreenViewStateDisconnected) || ([[self currentScreenView] state] == TNRemoteScreenViewStateDisconnecting))
    {
        [[self currentScreenView] setPassword:[fieldPassword stringValue]];
        [[self currentScreenView] connect:nil];
    }
    else
    {
        [[self currentScreenView] sendPassword:[fieldPassword stringValue]];
    }
}

/*! Opens a new browser window and try to access the certificate
    @param sender the sender of the action
*/
- (IBAction)addCertificateException:(id)aSender
{
    if ([buttonAddCertificateException title] == CPBundleLocalizedString(@"Add Exception", @"Add Exception"))
    {
        var host = [[self currentScreenView] host],
            port = [[self currentScreenView] port];

        window.open("https://" + host + ":" + port);
        [buttonAddCertificateException setTitle:CPBundleLocalizedString(@"Retry", @"Retry")];
    }
    else
    {
        [self getVirtualMachineVNCDisplay];
        [buttonAddCertificateException setTitle:CPBundleLocalizedString(@"Add Exception", @"Add Exception")];
    }
}


#pragma mark -
#pragma mark XMPP Controls

/*! send stanza to get the current virtual machine VNC display
*/
- (void)getVirtualMachineVNCDisplay
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineVNC}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineVNCDisplay}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveVNCDisplay:) ofObject:self];
}

/*! message sent when VNC display info is received
    @param aStanza the response stanza
*/
- (void)_didReceiveVNCDisplay:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var displayNode = [aStanza firstChildWithName:@"display"];

        _VMHost                 = [displayNode valueForAttribute:@"host"];
        _remoteScreenProxyPort  = [displayNode valueForAttribute:@"proxy"];
        _remoteScreenDirectPort = [displayNode valueForAttribute:@"port"];
        _remoteScreenType       = [displayNode valueForAttribute:@"type"];
        _supportsSSL            = ([displayNode valueForAttribute:@"supportssl"] == "True") ? YES : NO;
        _onlySSL                = ([displayNode valueForAttribute:@"onlyssl"] == "True") ? YES : NO;
        _useSSL                 = NO;

        [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelVNCInformationRecoveredNotification object:displayNode];
        [self handleDisplayVNCScreen];
    }
    else if ([aStanza type] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


#pragma mark -
#pragma mark Delegates

/*! TNZoomAnimation delegate
*/
- (float)animation:(CPAnimation)animation valueForProgress:(float)progress
{
    [sliderScaling setDoubleValue:[animation currentZoom]];

    [[self currentScreenView] setZoom:([animation currentZoom])];
}

/*! TNZoomAnimation delegate
*/
- (void)animationDidEnd:(CPAnimation)animation
{
    [self changeScale:sliderScaling];
}

- (void)remoteScreenView:(TNRemoteScreenView)aScreenView updateState:(CPString)aState message:(CPString)aMessage
{
    switch (aState)
    {
        case TNRemoteScreenViewStateError:
            [aScreenView setHidden:YES];

            if ([windowPassword isVisible] || ![self isConnected]) // we are asking for the password
                break;

            if ([aScreenView oldState] == TNVNCStateSecurityResult)
            {
                [imageViewSecureConnection setHidden:YES];
                [self _showConnectionHelp:NO];
                [windowPassword center];
                [windowPassword makeKeyAndOrderFront:nil];
            }
            else
            {
                [imageViewSecureConnection setHidden:YES];
                CPLog.error(@"disconnected from the VNC screen at " + _VMHost + @":" + _remoteScreenProxyPort);

                if ([aScreenView oldState] !== TNRemoteScreenViewStateConnected)
                    [self _showConnectionHelp:YES];
            }
            break;

        case TNRemoteScreenViewNeedsPassword:
            [windowPassword center];
            [windowPassword makeKeyAndOrderFront:nil];
            [self _showConnectionHelp:NO];
            break;

        case TNRemoteScreenViewStateConnected:
            [aScreenView setHidden:NO];
            [self _centerScreenView];
            [self _showConnectionHelp:NO];
            setTimeout(function(){ [self fitToScreen:nil] }, 500);
            [imageViewSecureConnection setHidden:!_useSSL];
            break;
    }
}

/*! TNRemoteScreenView delegate
*/
- (void)remoteScreenView:(TNRemoteScreenView)aScreenView didDesktopSizeChange:(CGSize)aNewSize
{
    [self fitToScreen:nil];
}

/*! TNRemoteScreenView delegate
*/
- (void)remoteScreenView:(TNRemoteScreenView)aScreenView didReceivePasteBoardText:(CPString)aText
{
    alert(aText);
}

/*! TNRemoteScreenView delegate
*/
- (void)remoteScreenView:(TNRemoteScreenView)aScreenView didGetFocus:(BOOL)hasFocus
{
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineNOVNCController], comment);
}

