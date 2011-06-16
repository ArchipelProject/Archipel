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
@import <TNKit/TNUIKitScrollView.j>
@import <VNCCappuccino/TNVNCView.j>

@import "TNExternalVNCWindow.j";
@import "TNZoomAnimation.j";



var TNArchipelPushNotificationVNC                   = @"archipel:push:virtualmachine:vnc",
    TNArchipelTypeVirtualMachineVNC                 = @"archipel:virtualmachine:vnc",
    TNArchipelTypeVirtualMachineVNCDisplay          = @"display",
    TNArchipelVNCScaleFactor                        = @"TNArchipelVNCScaleFactor_",
    TNArchipelVNCInformationRecoveredNotification   = @"TNArchipelVNCInformationRecoveredNotification",
    TNArchipelVNCShowExternalWindowNotification     = @"TNArchipelVNCShowExternalWindowNotification",
    TNArchipelDefinitionUpdatedNotification         = @"TNArchipelDefinitionUpdatedNotification";


/*! @ingroup virtualmachinenovnc
    module that allow to access virtual machine console using VNC
*/
@implementation TNVirtualMachineNOVNCController : TNModule
{
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
    @outlet CPSlider                sliderScaling;
    @outlet CPTextField             fieldPassword;
    @outlet CPTextField             fieldPreferencesCheckRate;
    @outlet CPTextField             fieldPreferencesFBURefreshRate;
    @outlet CPView                  viewControls;
    @outlet CPWindow                windowPassword;
    @outlet CPWindow                windowPasteBoard;
    @outlet LPMultiLineTextField    fieldPasteBoard;
    @outlet TNSwitch                switchPreferencesPreferSSL;
    @outlet TNUIKitScrollView       mainScrollView;

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
    [windowPasteBoard setDefaultButton:buttonPasteBoardSend];

    [imageViewSecureConnection setHidden:YES];

    var bundle  = [CPBundle bundleForClass:[self class]],
        defaults    = [CPUserDefaults standardUserDefaults];

    // register defaults defaults
    [defaults registerDefaults:[CPDictionary dictionaryWithObjectsAndKeys:
            [bundle objectForInfoDictionaryKey:@"NOVNCPreferSSL"], @"NOVNCPreferSSL",
            [bundle objectForInfoDictionaryKey:@"NOVNCFBURate"], @"NOVNCFBURate",
            [bundle objectForInfoDictionaryKey:@"NOVNCheckRate"], @"NOVNCheckRate"
    ]];

    var imageBg = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"bg-controls.png"]],
        imageZoomFit = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/fullscreen.png"] size:CPSizeMake(16, 16)],
        imageZoomReset = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/reset.png"] size:CPSizeMake(16, 16)],
        imageDirectAccess = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/screen.png"] size:CPSizeMake(16, 16)],
        imageCtrlAltDel = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"skull.png"] size:CPSizeMake(16, 16)],
        imageSendPasteBoard = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"sendPasteBoard.png"] size:CPSizeMake(16, 16)],
        imageGetPasteBoard = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"getPasteBoard.png"] size:CPSizeMake(16, 16)];

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

    _vncView = [[TNVNCView alloc] initWithFrame:[mainScrollView bounds]];
    [_vncView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];

    [mainScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setDocumentView:_vncView];
    [mainScrollView setAutohidesScrollers:YES];
    [sliderScaling setContinuous:YES];
    [sliderScaling setMinValue:1];
    [sliderScaling setMaxValue:200];

    [buttonGetPasteBoard setToolTip:CPBundleLocalizedString(@"Get the distant pasteboard (not implemented)", @"Get the distant pasteboard (not implemented)")];
    [buttonSendPasteBoard setToolTip:CPBundleLocalizedString(@"Send local pasteboard to the distant one (not implemented)", @"Send local pasteboard to the distant one (not implemented)")];
    [buttonSendCtrlAtlDel setToolTip:CPBundleLocalizedString(@"Send the CTRL+ALT+DEL key combinaison", @"Send the CTRL+ALT+DEL key combinaison")];
    [buttonExternalWindow setToolTip:CPBundleLocalizedString(@"Open the virtual screen in a new window", @"Open the virtual screen in a new window")];
    [buttonZoomFitToWindow setToolTip:CPBundleLocalizedString(@"Make the screen fit the current window", @"Make the screen fit the current window")];
    [buttonZoomReset setToolTip:CPBundleLocalizedString(@"Reset the zoom", @"Reset the zoom")];
    [sliderScaling setToolTip:CPBundleLocalizedString(@"Adjust zoom", @"Adjust zoom")];

    [fieldPreferencesCheckRate setToolTip:CPBundleLocalizedString(@"Set the VNC check rate value", @"Set the VNC check rate value")];
    [fieldPreferencesFBURefreshRate setToolTip:CPBundleLocalizedString(@"Set the VNC FBU refresg rate value", @"Set the VNC FBU refresg rate value")];
    [switchPreferencesPreferSSL setToolTip:CPBundleLocalizedString(@"Prefer SSL connection if possible", @"Prefer SSL connection if possible")];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

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
    if ([windowPassword isVisible])
        [windowPassword close];

    if ([self isConnected])
    {
        [_vncView disconnect:nil];
        [_vncView resetSize];
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
    if (([_entity XMPPShow] != TNStropheContactStatusOnline  && [_entity XMPPShow] != TNStropheContactStatusAway)
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
    {
        return;
    }

    var defaults    = [CPUserDefaults standardUserDefaults],
        scaleKey    = TNArchipelVNCScaleFactor + [[self entity] JID],
        passwordKey = "TNArchipelNOVNCPasswordRememberFor" + [_entity JID],
        lastScale   = [defaults floatForKey:scaleKey],
        preferSSL   = [defaults boolForKey:@"NOVNCPreferSSL"];

    if ((_vncOnlySSL) || (preferSSL && _vncSupportSSL))
        _useSSL = YES;

    if ((navigator.appVersion.indexOf("Chrome") == -1) && _useSSL)
    {
        var growl = [TNGrowlCenter defaultCenter];
        if (_vncOnlySSL)
        {
            CPLog.warn(@"Your browser doesn't support TLSv1 for WebSocket and Archipel server doesn't support plain connection. Use Google Chrome.");
            return;
        }
        else
        {
            CPLog.warn(@"Your browser doesn't support Websocket TLSv1. We use plain connection.");
            _useSSL = NO;
        }
    }

    if (lastScale)
        [sliderScaling setDoubleValue:lastScale];
    else
        [sliderScaling setDoubleValue:100];

    if ([defaults stringForKey:passwordKey])
    {
        [fieldPassword setStringValue:[defaults stringForKey:key]];
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
    [_vncView setZoom:(lastScale) ? (lastScale / 100) : 1];
    [_vncView setTrueColor:YES];
    [_vncView setEncrypted:_useSSL];
    [_vncView setDelegate:self];
    [_vncView setHidden:NO];
    [self showMaskView:NO];

    CPLog.info("VNC: connecting to " + _VMHost + ":" + _vncProxyPort + " using SSL:"
                + _useSSL + "(checkRate: " + [defaults integerForKey:@"NOVNCheckRate"]
                + ", FBURate: " + [defaults integerForKey:@"NOVNCFBURate"]);

    [_vncView load];
    [_vncView connect:nil];
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
    var winFrame    = CGRectMake(100, 100, 800, 600),
        pfWinFrame  = CGRectMake(100, 100, 800, 600),
        defaults    = [CPUserDefaults standardUserDefaults],
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

        VNCWindow = [[TNExternalVNCWindow alloc] initWithContentRect:winFrame styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask];
    }

    [VNCWindow loadVNCViewWithHost:_VMHost port:_vncProxyPort password:[fieldPassword stringValue] encrypt:_useSSL trueColor:YES checkRate:[defaults integerForKey:@"NOVNCheckRate"] FBURate:[defaults integerForKey:@"NOVNCFBURate"] entity:_entity];
    [VNCWindow makeKeyAndOrderFront:nil];
}



#pragma mark -
#pragma mark Actions

/*! Open the direct VNC URI using vnc://
    @param sender the sender of the action
*/
- (IBAction)openExternalWindow:(id)aSender
{
    [self openVNCInNewWindow];
}

/*! set the zoom factor
    @param sender the sender of the action
*/
- (IBAction)changeScale:(id)aSender
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        zoom        = [aSender intValue],
        key         = TNArchipelVNCScaleFactor + [[self entity] JID];

    [defaults setFloat:zoom forKey:key];

    [_vncView setZoom:(zoom / 100)];
}

/*! Make the VNCView fitting the maximum amount of space
    @param sender the sender of the action
*/
- (IBAction)fitToScreen:(id)aSender
{
    var visibleRect     = [_vncView visibleRect],
        currentVNCSize  = [_vncView displaySize],
        currentVNCZoom  = [_vncView zoom] * 100,
        diffPerc        = ((visibleRect.size.height - currentVNCSize.height) / currentVNCSize.height),
        newZoom         = (diffPerc < 0) ? 100 - (Math.abs(diffPerc) * 100) : 100 + (Math.abs(diffPerc) * 100);

    [self animateChangeScaleFrom:currentVNCZoom to:newZoom];
}

/*! Reset the zoom to 100%
    @param sender the sender of the action
*/
- (IBAction)resetZoom:(id)aSender
{
    var visibleRect     = [_vncView visibleRect],
        currentVNCSize  = [_vncView displaySize],
        currentVNCZoom  = [_vncView zoom] * 100;

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

    [windowPasteBoard close];
}

/*! remeber the password
    @param sender the sender of the action
*/
- (IBAction)rememberPassword:(id)aSender
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        key         = "TNArchipelNOVNCPasswordRememberFor" + [_entity JID];

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
    if (([_vncView state] == TNVNCCappuccinoStateDisconnected)
        || ([_vncView state] == TNVNCCappuccinoStateDisconnect))
    {
        [_vncView setPassword:[fieldPassword stringValue]];
        [_vncView connect:nil];
    }
    else
    {
        [_vncView sendPassword:[fieldPassword stringValue]];
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
            if ([_vncView oldState] == TNVNCCappuccinoStateSecurityResult)
            {
                [imageViewSecureConnection setHidden:YES];
                [windowPassword center];
                [windowPassword makeKeyAndOrderFront:nil];
            }
            else
            {
                [imageViewSecureConnection setHidden:YES];
                CPLog.error(@"disconnected from the VNC screen at " + _VMHost + @":" + _vncProxyPort);
            }
            [_vncView resetSize];
            break;

        case TNVNCCappuccinoStatePassword:
            [windowPassword center];
            [windowPassword makeKeyAndOrderFront:nil];
            break;

        case TNVNCCappuccinoStateNormal:
            if (_useSSL)
                [imageViewSecureConnection setHidden:NO];
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

