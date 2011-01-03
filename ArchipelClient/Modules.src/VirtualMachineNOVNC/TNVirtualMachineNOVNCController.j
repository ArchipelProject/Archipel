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
@import <AppKit/AppKit.j>

@import "TNExternalVNCWindow.j";
@import "TNZoomAnimation.j";


/*! @defgroup  virtualmachinevnc Module VirtualMachineVNC
    @desc This module allows to access to virtual machine displays
    using VNC.
*/


/*! @ingroup virtualmachinevnc
    @group TNArchipelTypeVirtualMachineControl
    namespave of vm control
*/
TNArchipelTypeVirtualMachineControl             = @"archipel:vm:control";

/*! @ingroup virtualmachinenovnc
    @group TNArchipelTypeVirtualMachineControl
    get vnc display
*/
TNArchipelTypeVirtualMachineControlVNCDisplay   = @"vncdisplay";



/*! @ingroup virtualmachinenovnc
    @group TNArchipelTypeVirtualMachineControl
    identifier prefix of zoom scaling
*/
TNArchipelVNCScaleFactor                        = @"TNArchipelVNCScaleFactor_";


/*! @ingroup virtualmachinenovnc
    module that allow to access virtual machine console using VNC
*/
@implementation TNVirtualMachineNOVNCController : TNModule
{
    @outlet CPScrollView    mainScrollView;
    @outlet CPTextField     fieldJID;
    @outlet CPTextField     fieldName;
    @outlet CPView          maskingView;
    @outlet CPSlider        sliderScaling;
    @outlet CPButton        buttonZoomFitToWindow;
    @outlet CPButton        buttonZoomReset;
    @outlet CPButton        buttonSendCtrlAtlDel;
    @outlet CPButton        buttonSendPasteBoard;
    @outlet CPButton        buttonGetPasteBoard;
    @outlet CPTextField     fieldZoomValue;
    @outlet CPTextField     fieldPassword;
    @outlet CPButton        buttonDirectURL;
    @outlet CPView          viewControls;
    @outlet CPWindow        windowPassword;
    @outlet CPWindow        windowPasteBoard;
    @outlet LPMultiLineTextField        fieldPasteBoard;
    @outlet CPImageView     imageViewSecureConnection;
    @outlet CPCheckBox      checkboxPasswordRemember;
    @outlet CPTextField     fieldPreferencesFBURefreshRate;
    @outlet CPTextField     fieldPreferencesCheckRate;
    @outlet TNSwitch        switchPreferencesPreferSSL;

    CPString                _url;
    CPString                _VMHost;
    BOOL                    _vncOnlySSL;
    BOOL                    _vncSupportSSL;
    BOOL                    _useSSL;
    BOOL                    _preferSSL;
    CPString                _vncProxyPort;
    CPString                _vncDirectPort;
    TNVNCView               _vncView;
    int                     _NOVNCheckRate;
    int                     _NOVNCFBURate;
}


#pragma mark -
#pragma mark Initialization

/*! initialize some value at CIB awakening
*/
- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
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
    [buttonDirectURL setImage:imageDirectAccess];
    [buttonSendCtrlAtlDel setImage:imageCtrlAltDel];
    [buttonSendPasteBoard setImage:imageSendPasteBoard];
    [buttonGetPasteBoard setImage:imageGetPasteBoard];

    var inset = CGInsetMake(2, 2, 2, 5);

    [buttonZoomFitToWindow setValue:inset forThemeAttribute:@"content-inset"];
    [buttonZoomReset setValue:inset forThemeAttribute:@"content-inset"];
    [buttonDirectURL setValue:inset forThemeAttribute:@"content-inset"];
    [buttonSendCtrlAtlDel setValue:inset forThemeAttribute:@"content-inset"];
    [buttonSendPasteBoard setValue:inset forThemeAttribute:@"content-inset"];
    [buttonGetPasteBoard setValue:inset forThemeAttribute:@"content-inset"];

    [fieldPassword setSecure:YES];

    _vncView = [[TNVNCView alloc] initWithFrame:[mainScrollView bounds]];
    [_vncView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_vncView setBackgroundImage:[bundle pathForResource:@"vncbg.png"]];

    [mainScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setDocumentView:_vncView];
    [mainScrollView setAutohidesScrollers:YES];
    [sliderScaling setContinuous:YES];
    [sliderScaling setMinValue:1];
    [sliderScaling setMaxValue:200];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    [center addObserver:self selector:@selector(_didUpdatePresence:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [fieldPassword setStringValue:@""];
    [super willUnload];
}

/*! called when module becomes visible
*/
- (void)willShow
{
    if (![super willShow])
        return NO;

    [maskingView setFrame:[[self view] bounds]];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    [self checkIfRunning];

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

    if (([_vncView state] != TNVNCCappuccinoStateDisconnected)
        || ([_vncView state] == TNVNCCappuccinoStateDisconnect))
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

    [defaults setObject:[fieldPreferencesFBURefreshRate stringValue] forKey:@"NOVNCFBURate"];
    [defaults setObject:[fieldPreferencesCheckRate stringValue] forKey:@"NOVNCheckRate"];
    [defaults setBool:[switchPreferencesPreferSSL isOn] forKey:@"NOVNCPreferSSL"];
}

/*! call when user gets preferences
*/
- (void)loadPreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [fieldPreferencesFBURefreshRate setStringValue:[defaults objectForKey:@"NOVNCFBURate"]];
    [fieldPreferencesCheckRate setStringValue:[defaults objectForKey:@"NOVNCheckRate"]];
    [switchPreferencesPreferSSL setOn:[defaults boolForKey:@"NOVNCPreferSSL"] animated:YES sendAction:NO];
}

/*! call when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:@"Fit screen to window" action:@selector(fitToScreen:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Reset zoom" action:@selector(resetZoom:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Open external VNC program" action:@selector(openDirectURI:) keyEquivalent:@""] setTarget:self];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when contact nickname has been updated
    @param aNotification the notification
*/
- (void)_didUpdateNickName:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

/*! called when contact presence has changed
    @param aNotification the notification
*/
- (void)_didUpdatePresence:(CPNotification)aNotification
{
    [self checkIfRunning];
}


#pragma mark -
#pragma mark Utilities

/*! Check if virtual machine is running. if not displays the masking view
*/
- (void)checkIfRunning
{
    if ([_entity XMPPShow] == TNStropheContactStatusOnline)
    {
        [maskingView removeFromSuperview];
        if ((_isVisible) && (([_vncView state] == TNVNCCappuccinoStateDisconnected) || ([_vncView state] == TNVNCCappuccinoStateDisconnect)))
            [self getVirtualMachineVNCDisplay];
    }
    else
    {
        if (([_vncView state] != TNVNCCappuccinoStateDisconnected)
            && ([_vncView state] != TNVNCCappuccinoStateDisconnect))
        {
            [_vncView disconnect:nil];
            [_vncView resetSize];
            [_vncView unfocus];
        }

        [maskingView setFrame:[[self view] bounds]];
        [[self view] addSubview:maskingView];
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


#pragma mark -
#pragma mark Actions

/*! Open the direct VNC URI using vnc://
    @param sender the sender of the action
*/
- (IBAction)openDirectURI:(id)aSender
{
    // window.open(@"vnc://" + _VMHost + @":" + _vncDirectPort);
    [self openVNCInNewWindow:aSender];
}

/*! set the zoom factor
    @param sender the sender of the action
*/
- (IBAction)changeScale:(id)aSender
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        zoom        = [aSender intValue],
        key         = TNArchipelVNCScaleFactor + [[self entity] JID];

    [defaults setObject:zoom forKey:key];

    [_vncView setZoom:(zoom / 100)];
    [fieldZoomValue setStringValue:parseInt(zoom)];
}

/*! Make the VNCView fitting the maximum amount of space
    @param sender the sender of the action
*/
- (IBAction)fitToScreen:(id)aSender
{
    var visibleRect     = [_vncView visibleRect],
        currentVNCSize  = [_vncView canvasSize],
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
        currentVNCSize  = [_vncView canvasSize],
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

/*! Open the VNCView in a new physical window
    @param sender the sender of the action
*/
- (IBAction)openVNCInNewWindow:(id)aSender
{
    var widthOffset         = 6,
        heightOffset        = 6;

    // if on chrome take care of the address bar and it's fuckness about counting it into the size of the window...
    if (navigator.appVersion.indexOf("Chrome") != -1)
    {
        widthOffset     =   6;
        heightOffset    =   56;
    }

    var vncSize             = [_vncView canvasSize],
        winFrame            = CGRectMake(100, 100, vncSize.width + widthOffset, vncSize.height + heightOffset),
        pfWinFrame          = CGRectMake(100, 100, vncSize.width + widthOffset, vncSize.height + heightOffset),
        VNCWindow,
        platformVNCWindow;

    if ([CPPlatform isBrowser])
    {
        VNCWindow           = [[TNExternalVNCWindow alloc] initWithContentRect:winFrame styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask | CPBorderlessBridgeWindowMask];
        platformVNCWindow   = [[CPPlatformWindow alloc] initWithContentRect:pfWinFrame];
        [VNCWindow setPlatformWindow:platformVNCWindow];

        [VNCWindow setMaxSize:CPSizeMake(vncSize.width + 6, vncSize.height + 6)];
        [VNCWindow setMinSize:CPSizeMake(vncSize.width + 6, vncSize.height + 6)];
    }
    else
    {
        winFrame.origin.x = 20;
        winFrame.origin.y = 50;
        winFrame.size.height += 25;

        VNCWindow = [[TNExternalVNCWindow alloc] initWithContentRect:winFrame styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask];

        [VNCWindow setMaxSize:CPSizeMake(vncSize.width + 6, vncSize.height + 6 + 25)];
        [VNCWindow setMinSize:CPSizeMake(vncSize.width + 6, vncSize.height + 6 + 25)];
    }

    [VNCWindow makeKeyAndOrderFront:nil];
    [VNCWindow setTitle:@"Screen for " + [_entity nickname] + " (" + [_entity JID] + ")"];

    [VNCWindow loadVNCViewWithHost:_VMHost port:_vncProxyPort password:[fieldPassword stringValue] encrypt:_useSSL trueColor:YES checkRate:_NOVNCheckRate FBURate:_NOVNCFBURate];
    [VNCWindow makeKeyWindow];
}


#pragma mark -
#pragma mark XMPP Controls

/*! send stanza to get the current virtual machine VNC display
*/
- (void)getVirtualMachineVNCDisplay
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineControlVNCDisplay}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveVNCDisplay:) ofObject:self];
}

/*! message sent when VNC display info is received
    @param aStanza the response stanza
*/
- (void)_didReceiveVNCDisplay:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var defaults    = [CPUserDefaults standardUserDefaults],
            displayNode = [aStanza firstChildWithName:@"vncdisplay"],
            key         = TNArchipelVNCScaleFactor + [[self entity] JID],
            lastScale   = [defaults objectForKey:key],
            defaults    = [CPUserDefaults standardUserDefaults],
            key         = "TNArchipelNOVNCPasswordRememberFor" + [_entity JID];

        _VMHost         = [displayNode valueForAttribute:@"host"];
        _vncProxyPort   = [displayNode valueForAttribute:@"proxy"];
        _vncDirectPort  = [displayNode valueForAttribute:@"port"];
        _vncSupportSSL  = ([displayNode valueForAttribute:@"supportssl"] == "True") ? YES : NO;
        _vncOnlySSL     = ([displayNode valueForAttribute:@"onlyssl"] == "True") ? YES : NO;

        _useSSL         = NO;
        _preferSSL      = ([defaults boolForKey:@"NOVNCPreferSSL"] == 1) ? YES: NO;
        _NOVNCFBURate   = [defaults integerForKey:@"NOVNCFBURate"];
        _NOVNCheckRate  = [defaults integerForKey:@"NOVNCheckRate"];

        if ((_vncOnlySSL) || (_preferSSL && _vncSupportSSL))
            _useSSL = YES;

        if ((navigator.appVersion.indexOf("Chrome") == -1) && _useSSL)
        {
            var growl = [TNGrowlCenter defaultCenter];
            if (_vncOnlySSL)
            {
                [growl pushNotificationWithTitle:@"VNC" message:@"Your browser doesn't support TLSv1 for WebSocket and Archipel server doesn't support plain connection. Use Google Chrome." icon:TNGrowlIconError];
                return;
            }
            else
            {
                [growl pushNotificationWithTitle:@"VNC" message:@"Your browser doesn't support Websocket TLSv1. We use plain connection." icon:TNGrowlIconWarning];
                _useSSL = NO;
            }
        }

        if (lastScale)
        {
            [sliderScaling setDoubleValue:lastScale];
            [fieldZoomValue setStringValue:lastScale];
        }
        else
        {
            [sliderScaling setDoubleValue:100];
            [fieldZoomValue setStringValue:@"100"];
        }

        if ([defaults stringForKey:key])
        {
            [fieldPassword setStringValue:[defaults stringForKey:key]];
            [checkboxPasswordRemember setState:CPOnState];
        }
        else
        {
            [fieldPassword setStringValue:@""];
            [checkboxPasswordRemember setState:CPOffState];
        }

        [_vncView setCheckRate:_NOVNCheckRate];
        [_vncView setFrameBufferRequestRate:_NOVNCFBURate];
        [_vncView setHost:_VMHost];
        [_vncView setPort:_vncProxyPort];
        [_vncView setPassword:[fieldPassword stringValue]];
        [_vncView setZoom:(lastScale) ? (lastScale / 100) : 1];
        [_vncView setTrueColor:YES];
        [_vncView setEncrypted:_useSSL];
        [_vncView setDelegate:self];

        [_vncView load];
        [_vncView connect:nil];
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
    [fieldZoomValue setStringValue:parseInt([animation currentZoom])];
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



