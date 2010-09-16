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

/*! @ingroup virtualmachinevnc
    @group TNArchipelTypeVirtualMachineControl
    get vnc display
*/
TNArchipelTypeVirtualMachineControlVNCDisplay   = @"vncdisplay";

TNArchipelVNCScaleFactor                        = @"TNArchipelVNCScaleFactor_";


/*! @ingroup virtualmachinevnc
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

/*! initialize some value at CIB awakening
*/
- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    [imageViewSecureConnection setHidden:YES];
    
    var bundle  = [CPBundle bundleForClass:[self class]];
    
    var imageBg = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"bg-controls.png"]];
    [viewControls setBackgroundColor:[CPColor colorWithPatternImage:imageBg]];
    
    
    var imageZoomFit = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-fullscreen.png"] size:CPSizeMake(16, 16)]
    [buttonZoomFitToWindow setImage:imageZoomFit];
    
    var imageZoomReset = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-reset.png"] size:CPSizeMake(16, 16)]
    [buttonZoomReset setImage:imageZoomReset];
    
    var imageDirectAccess = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-screen.png"] size:CPSizeMake(16, 16)]
    [buttonDirectURL setImage:imageDirectAccess];
    
    var imageCtrlAltDel = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"skull.png"] size:CPSizeMake(16, 16)]
    [buttonSendCtrlAtlDel setImage:imageCtrlAltDel];
    
    var imageSendPasteBoard = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"sendPasteBoard.png"] size:CPSizeMake(16, 16)]
    [buttonSendPasteBoard setImage:imageSendPasteBoard];
    
    var imageGetPasteBoard = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"getPasteBoard.png"] size:CPSizeMake(16, 16)]
    [buttonGetPasteBoard setImage:imageGetPasteBoard];
    
    [fieldPassword setSecure:YES];
    
    _vncView    = [[TNVNCView alloc] initWithFrame:[mainScrollView bounds]];
    [_vncView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_vncView setBackgroundImage:[bundle pathForResource:@"vncbg.png"]];
    
    [mainScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setDocumentView:_vncView];
    [mainScrollView setAutohidesScrollers:YES];
    [sliderScaling setContinuous:YES];
    [sliderScaling setMinValue:1];
    [sliderScaling setMaxValue:200];
}

/*! TNModule implementation
*/
- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];   
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    [center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
}

- (void)willShow
{
    [super willShow];
    
    [maskingView setFrame:[[self view] bounds]];
    
    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    [self checkIfRunning];
    
    [[self view] setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [[self view] setFrame:[[[self view] superview] bounds]];
}

- (void)willHide
{
    [imageViewSecureConnection setHidden:YES];
    if ([windowPassword isVisible])
        [windowPassword close];
    
    if (([_vncView state] != TNVNCCappuccinoStateDisconnected) 
        || ([_vncView state] == TNVNCCappuccinoStateDisconnect))
    {
        [_vncView disconnect:nil];
        [_vncView clear];
        [_vncView unfocus];
    }
    [_vncView invalidate];
       
    [super willHide];
}

- (void)willUnload
{
    [fieldPassword setStringValue:@""];
    [super willUnload];
}

- (void)menuReady
{
    [[_menu addItemWithTitle:@"Fit screen to window" action:@selector(fitToScreen:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Reset zoom" action:@selector(resetZoom:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Open external VNC program" action:@selector(openDirectURI:) keyEquivalent:@""] setTarget:self];
}


- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

- (void)didPresenceUpdated:(CPNotification)aNotification
{
    [self checkIfRunning];
}

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
            [_vncView clear];
            [_vncView unfocus];
        }
        
        [maskingView setFrame:[[self view] bounds]];
        [[self view] addSubview:maskingView];
    }
}


/*! send stanza to get the current virtual machine VNC display
*/
- (void)getVirtualMachineVNCDisplay
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildName:@"archipel" withAttributes:{
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
        var bundle      = [CPBundle bundleForClass:[self class]];
        var displayNode = [aStanza firstChildWithName:@"vncdisplay"];
        var defaults    = [TNUserDefaults standardUserDefaults];
        var key         = TNArchipelVNCScaleFactor + [[self entity] JID];
        var lastScale   = [defaults objectForKey:key];
        var defaults    = [TNUserDefaults standardUserDefaults];
        var key         = "TNArchipelNOVNCPasswordRememberFor" + [_entity JID];
        
        _VMHost         = [displayNode valueForAttribute:@"host"];
        _vncProxyPort   = [displayNode valueForAttribute:@"proxy"];
        _vncDirectPort  = [displayNode valueForAttribute:@"port"];
        _vncSupportSSL  = ([displayNode valueForAttribute:@"supportssl"] == "True") ? YES : NO;
        _vncOnlySSL     = ([displayNode valueForAttribute:@"onlyssl"] == "True") ? YES : NO;
        
        _useSSL         = NO;
        _preferSSL      = ([bundle objectForInfoDictionaryKey:@"NOVNCPreferSSL"] == 1) ? YES: NO;
        _NOVNCFBURate   = [bundle objectForInfoDictionaryKey:@"NOVNCFBURate"];
        _NOVNCheckRate  = [bundle objectForInfoDictionaryKey:@"NOVNCheckRate"];
        
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



/*
    Controls
*/
- (IBAction)openDirectURI:(id)sender
{
    // window.open(@"vnc://" + _VMHost + @":" + _vncDirectPort);
    [self openVNCInNewWindow:sender];
}

- (IBAction)changeScale:(id)sender
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    var zoom        = [sender intValue];
    
    var key = TNArchipelVNCScaleFactor + [[self entity] JID];
    [defaults setObject:zoom forKey:key];
    
    [_vncView setZoom:(zoom / 100)];
    [fieldZoomValue setStringValue:parseInt(zoom)];
}

- (IBAction)fitToScreen:(id)sender
{
    var visibleRect     = [_vncView visibleRect];
    var currentVNCSize  = [_vncView canvasSize];
    var currentVNCZoom  = [_vncView zoom] * 100;
    var diffPerc        = ((visibleRect.size.height - currentVNCSize.height) / currentVNCSize.height);
    
    if (diffPerc < 0)
        var newZoom = 100 - (Math.abs(diffPerc) * 100);
    else
        var newZoom = 100 + (Math.abs(diffPerc) * 100);

    [self animateChangeScaleFrom:currentVNCZoom to:newZoom];
}

- (IBAction)resetZoom:(id)sender
{
    var visibleRect     = [_vncView visibleRect];
    var currentVNCSize  = [_vncView canvasSize];
    var currentVNCZoom  = [_vncView zoom] * 100;

    [self animateChangeScaleFrom:currentVNCZoom to:100];
}

- (IBAction)sendCtrlAltDel:(id)sender
{
    CPLog.info("sending ctrl+alt+del to VNCView");
    [_vncView sendCtrlAltDel:sender];
    
    // [_vncView sendTextToPasteboard:@"HELLO MOTO"];
}

- (IBAction)sendPasteBoard:(id)sender
{
    CPLog.info("sending the content of Pasteboard to VNCView: " + [fieldPasteBoard stringValue]);
    
    [_vncView sendTextToPasteboard:[fieldPasteBoard stringValue]];
    
    [fieldPasteBoard setStringValue:@""];
    
    [windowPasteBoard close];
}



/*
    Zoom animation
*/
- (void)animateChangeScaleFrom:(float)aStartZoom to:(float)aEndZoom
{
    var useAnimations = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelUseAnimations"];
    
    if (useAnimations)
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
        [self changeScale:nil];
    }
}

- (float)animation:(CPAnimation)animation valueForProgress:(float)progress
{
    [sliderScaling setDoubleValue:[animation currentZoom]];
    
    [_vncView setZoom:([animation currentZoom] / 100)];
    [fieldZoomValue setStringValue:parseInt([animation currentZoom])];
}

- (void)animationDidEnd:(CPAnimation)animation
{
    [self changeScale:sliderScaling];
}



/*
    Password management
*/
- (IBAction)rememberPassword:(id)sender
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    var key         = "TNArchipelNOVNCPasswordRememberFor" + [_entity JID];
    
    if ([checkboxPasswordRemember state] == CPOnState)
        [defaults setObject:[fieldPassword stringValue] forKey:key];
    else
        [defaults setObject:@"" forKey:key];
}

- (IBAction)changePassword:(id)sender
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


/*
    VNCView delegate
*/
- (void)vncView:(TNVNCView)aVNCView updateState:(CPString)aState message:(CPString)aMessage
{
    switch(aState)
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
                var growl = [TNGrowlCenter defaultCenter];
                [growl pushNotificationWithTitle:@"VNC" message:aMessage icon:TNGrowlIconError];
            }
            [_vncView clear];
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

- (void)openVNCInNewWindow:(id)sender
{
    var vncSize             = [_vncView canvasSize];
    var winFrame            = CGRectMake(100, 100, vncSize.width + 6, vncSize.height + 6);
    var pfWinFrame          = CGRectMake(100, 100, vncSize.width + 6, vncSize.height + 6);
    var VNCWindow           = [[TNExternalVNCWindow alloc] initWithContentRect:winFrame styleMask:CPTitledWindowMask|CPClosableWindowMask|CPMiniaturizableWindowMask|CPResizableWindowMask|CPBorderlessBridgeWindowMask];
    var platformVNCWindow   = [[CPPlatformWindow alloc] initWithContentRect:pfWinFrame];
    
    [VNCWindow setPlatformWindow:platformVNCWindow];
    [VNCWindow makeKeyAndOrderFront:nil];
    [VNCWindow setTitle:@"Screen for " + [_entity nickname] + " ("+ [_entity JID] +")"];
    
    [VNCWindow setMaxSize:CPSizeMake(vncSize.width + 6, vncSize.height + 6)];
    [VNCWindow setMinSize:CPSizeMake(vncSize.width + 6, vncSize.height + 6)];
    
    [VNCWindow loadVNCViewWithHost:_VMHost port:_vncProxyPort password:[fieldPassword stringValue] encrypt:_useSSL trueColor:YES checkRate:_NOVNCheckRate FBURate:_NOVNCFBURate];
    [VNCWindow makeKeyWindow];
}




@end



