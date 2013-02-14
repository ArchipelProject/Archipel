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
    BOOL                            _vncOnlySSL;
    BOOL                            _vncSupportSSL;
    CPString                        _url;
    CPString                        _VMHost;
    CPString                        _vncDirectPort;
    CPString                        _vncProxyPort;
    TNVNCView                       _vncView;
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
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"NOVNCPreferSSL"], @"NOVNCPreferSSL",
            [bundle objectForInfoDictionaryKey:@"NOVNCFBURate"], @"NOVNCFBURate",
            [bundle objectForInfoDictionaryKey:@"NOVNCheckRate"], @"NOVNCheckRate"
    ]];

    var imageBg = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"bg-controls.png"]],
        imageZoomFit = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/fullscreen.png"] size:CGSizeMake(16, 16)],
        imageZoomReset = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/reset.png"] size:CGSizeMake(16, 16)],
        imageDirectAccess = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/screen.png"] size:CGSizeMake(16, 16)],
        imageCtrlAltDel = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"skull.png"] size:CGSizeMake(16, 16)],
        imageSendPasteBoard = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"sendPasteBoard.png"] size:CGSizeMake(16, 16)],
        imageGetPasteBoard = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"getPasteBoard.png"] size:CGSizeMake(16, 16)];

    [viewControls setBackgroundColor:[CPColor colorWithPatternImage:imageBg]];
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

    _vncView = [[TNVNCView alloc] initWithFrame:CGRectMakeZero()];
    [_vncView setAutoresizingMask:CPViewMinXMargin | CPViewMinYMargin | CPViewMaxXMargin | CPViewMaxYMargin];
    [self _centerVNCView];
    [viewVNCContainer addSubview:_vncView];

    [sliderScaling setContinuous:YES];
    [sliderScaling setMinValue:1];
    [sliderScaling setMaxValue:200];

    [buttonAddCertificateException setThemeState:CPThemeStateDefault];
    [viewConnectionErrorHelp applyShadow];

    [self _showConnectionHelp:NO];

    [[self view] applyShadow];
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
    _VMHost         = nil;
    _vncProxyPort   = nil;
    _vncDirectPort  = nil;
    _vncSupportSSL  = nil;
    _vncOnlySSL     = nil;

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
    [self _showConnectionHelp:NO];

    [windowPassword close];

    if ([self isConnected])
    {
        [_vncView disconnect:nil];
        [_vncView unfocus];
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

/*! call when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Fit screen to window", @"Fit screen to window") action:@selector(fitToScreen:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Reset zoom", @"Reset zoom") action:@selector(resetZoom:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Open external VNC program", @"Open external VNC program") action:@selector(openExternalWindow:) keyEquivalent:@""] setTarget:self];
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

- (void)_centerVNCView
{
    var frame = [viewVNCContainer bounds],
        centerX = frame.size.width / 2.0,
        centerY = frame.size.height / 2.0;

    [_vncView setCenter:CGPointMake(centerX, centerY)];
}

/*! check if VNC is currenttly connected
    @return Boolean.
*/
- (BOOL)isConnected
{
    return ([_vncView state] != TNVNCCappuccinoStateDisconnected || [_vncView state] == TNVNCCappuccinoStateDisconnect)
}

/*! Check if virtual machine is running. if not displays the masking view
*/
- (void)handleDisplayVNCScreen
{
    if (([_entity XMPPShow] != TNStropheContactStatusOnline
            && [_entity XMPPShow] != TNStropheContactStatusAway)
        || _vncProxyPort == -1
        || !_vncProxyPort)
    {
        _VMHost         = nil;
        _vncProxyPort   = nil;
        _vncDirectPort  = nil;
        _vncSupportSSL  = nil;
        _vncOnlySSL     = nil;

        if ([self isConnected])
        {
            [_vncView unfocus];
            [_vncView disconnect:nil];
        }

        [_vncView setHidden:YES];
        [self showMaskView:YES];

        return;
    }

    if (![self isVisible])
        return;

    var defaults = [CPUserDefaults standardUserDefaults],
        passwordKey = "TNArchipelNOVNCPasswordRememberFor" + [_entity JID],
        preferSSL = [defaults boolForKey:@"NOVNCPreferSSL"];

    if ((_vncOnlySSL) || (preferSSL && _vncSupportSSL))
        _useSSL = YES;

    [sliderScaling setDoubleValue:100];

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

    [_vncView setCheckRate:[defaults integerForKey:@"NOVNCheckRate"]];
    [_vncView setFrameBufferRequestRate:[defaults integerForKey:@"NOVNCFBURate"]];
    [_vncView setHost:_VMHost];
    [_vncView setPort:_vncProxyPort];
    [_vncView setPassword:[fieldPassword stringValue]];
    [_vncView setZoom:1];
    [_vncView setTrueColor:YES];
    [_vncView setEncrypted:_useSSL];
    [_vncView setDelegate:self];
    [self showMaskView:NO];

    CPLog.info("VNC: connecting to %@:%@  using SSL: %@ (checkRate: %@, FBURate: %@)",
        _VMHost, _vncProxyPort, _useSSL, [defaults integerForKey:@"NOVNCheckRate"], [defaults integerForKey:@"NOVNCFBURate"]);

    try
    {
        [_vncView load];
        [_vncView connect:nil];
    }
    catch(e)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Websocket error for VNC", @"Websocket error for VNC")
                          informative:CPBundleLocalizedString(@"It seems your websocket configuration is not properly configured. If you are using Firefox, go to about:config and set 'network.websocket.override-security-block' and 'network.websocket.enabled' to 'True'.", @"It seems your websocket configuration is not properly configured. If you are using Firefox, go to about:config and set 'network.websocket.override-security-block' and 'network.websocket.enabled' to 'True'.")
                                style:CPCriticalAlertStyle];
        CPLog.error("Websocket problem. unable to start noVNC subsystem: " + e);
    }
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
                              port:_vncProxyPort
                          password:[fieldPassword stringValue]
                           encrypt:_useSSL
                         trueColor:YES
                         checkRate:[defaults integerForKey:@"NOVNCheckRate"]
                           FBURate:[defaults integerForKey:@"NOVNCFBURate"]
                            entity:_entity];

    [VNCWindow makeKeyAndOrderFront:nil];
}

- (void)_showConnectionHelp:(BOOL)shouldShow
{
    if (!shouldShow)
    {
        [viewConnectionErrorHelp removeFromSuperview];
        return;
    }

    [labelErrorInformation setStringValue:[CPString stringWithFormat:@"Tried to connect to %@:%@ (SSL: %@)", _VMHost, _vncProxyPort, _useSSL]];

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
    [_vncView setZoom:([aSender intValue] / 100)];
    [self _centerVNCView];
}

/*! Make the VNCView fitting the maximum amount of space
    @param sender the sender of the action
*/
- (IBAction)fitToScreen:(id)aSender
{
    var visibleRect     = [viewVNCContainer frame],
        currentVNCSize  = [_vncView displaySize],
        currentVNCZoom  = [_vncView zoom] * 100,
        diffPerc        = ((visibleRect.size.height - (currentVNCSize.height + 6)) / (currentVNCSize.height + 6)),
        newZoom         = (diffPerc < 0) ? 100 - (Math.abs(diffPerc) * 100) : 100 + (Math.abs(diffPerc) * 100);

    [self animateChangeScaleFrom:currentVNCZoom to:newZoom];
}

/*! Reset the zoom to 100%
    @param sender the sender of the action
*/
- (IBAction)resetZoom:(id)aSender
{
    var visibleRect = [_vncView visibleRect],
        currentVNCSize = [_vncView displaySize],
        currentVNCZoom = [_vncView zoom] * 100;

    [self animateChangeScaleFrom:currentVNCZoom to:100];
}

/*! Send CTRL ALT DEL key combination to the VNCView
    @param sender the sender of the action
*/
- (IBAction)sendCtrlAltDel:(id)aSender
{
    CPLog.info("sending ctrl+alt+del to VNCView");
    [_vncView sendCtrlAltDel:aSender];

    // [_vncView sendTextToPasteboard:@"HELLO MOTO"];
}

/*! Send the content of the pasteboard to the VNCView
    @param sender the sender of the action
*/
- (IBAction)sendPasteBoard:(id)aSender
{
    CPLog.info("sending the content of Pasteboard to VNCView: " + [fieldPasteBoard stringValue]);

    [_vncView sendTextToPasteboard:[fieldPasteBoard stringValue]];

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
    if (([_vncView state] == TNVNCCappuccinoStateDisconnected) || ([_vncView state] == TNVNCCappuccinoStateDisconnect))
    {
        [_vncView setPassword:[fieldPassword stringValue]];
        [_vncView connect:nil];
    }
    else
    {
        [_vncView sendPassword:[fieldPassword stringValue]];
    }
}

/*! Opens a new browser window and try to access the certificate
    @param sender the sender of the action
*/
- (IBAction)addCertificateException:(id)aSender
{
    if ([buttonAddCertificateException title] == CPBundleLocalizedString(@"Add Exception", @"Add Exception"))
    {
        var host = [_vncView host],
            port = [_vncView port];

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

        _VMHost         = [displayNode valueForAttribute:@"host"];
        _vncProxyPort   = [displayNode valueForAttribute:@"proxy"];
        _vncDirectPort  = [displayNode valueForAttribute:@"port"];
        _vncSupportSSL  = ([displayNode valueForAttribute:@"supportssl"] == "True") ? YES : NO;
        _vncOnlySSL     = ([displayNode valueForAttribute:@"onlyssl"] == "True") ? YES : NO;
        _useSSL         = NO;

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

    [_vncView setZoom:([animation currentZoom] / 100)];
}

/*! TNZoomAnimation delegate
*/
- (void)animationDidEnd:(CPAnimation)animation
{
    [self changeScale:sliderScaling];
}

- (void)vncView:(TNVNCView)aVNCView updateState:(CPString)aState message:(CPString)aMessage
{
    switch (aState)
    {
        case TNVNCCappuccinoStateFailed:
            [_vncView setHidden:YES];

            if ([_vncView oldState] == TNVNCCappuccinoStateSecurityResult)
            {
                [imageViewSecureConnection setHidden:YES];
                [self _showConnectionHelp:NO];
                [windowPassword center];
                [windowPassword makeKeyAndOrderFront:nil];
            }
            else
            {
                [imageViewSecureConnection setHidden:YES];
                CPLog.error(@"disconnected from the VNC screen at " + _VMHost + @":" + _vncProxyPort);

                if ([_vncView oldState] !== TNVNCCappuccinoStateNormal)
                    [self _showConnectionHelp:YES];
            }
            break;

        case TNVNCCappuccinoStatePassword:
            [windowPassword center];
            [windowPassword makeKeyAndOrderFront:nil];
            break;

        case TNVNCCappuccinoStateNormal:
            [_vncView setHidden:NO];
            [self _centerVNCView];
            [self _showConnectionHelp:NO];
            setTimeout(function(){ [self fitToScreen:nil] }, 500);
            [imageViewSecureConnection setHidden:!_useSSL];
            break;
    }
}

- (void)vncView:(TNVNCView)aVNCView didReceivePasteBoardText:(CPString)aText
{
    alert(aText);
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNVirtualMachineNOVNCController], comment);
}

