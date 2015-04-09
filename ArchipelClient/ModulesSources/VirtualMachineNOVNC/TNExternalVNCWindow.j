/*
 * TNExternalVNCWindow.j
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

@import <AppKit/CPImageView.j>
@import <AppKit/CPSlider.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNToolbar.j>
@import <TNKit/TNAlert.j>
@import <StropheCappuccino/TNStropheContact.j>
@import <GrowlCappuccino/TNGrowlCenter.j>
@import <VNCCappuccino/VNCCappuccino.j>

@global CPLocalizedStringTNAlert
@global CPLocalizedStringFromTableInBundle
@global TNStropheContactVCardReceivedNotification
@global TNStropheContactNicknameUpdatedNotification
@global TNArchipelVNCScreenTypeVNC
@global TNArchipelVNCScreenTypeSPICE

var TNVNCWindowToolBarCtrlAltDel        = @"TNVNCWindowToolBarCtrlAltDel",
    TNVNCWindowToolBarSendPasteboard    = @"TNVNCWindowToolBarSendPasteboard",
    TNVNCWindowToolBarGetPasteboard     = @"TNVNCWindowToolBarGetPasteboard",
    TNVNCWindowToolBarFullScreen        = @"TNVNCWindowToolBarFullScreen",
    TNVNCWindowToolBarZoom              = @"TNVNCWindowToolBarZoom";


/*! @ingroup virtualmachinenovnc
    CPWindow that contains the external VNCView
*/
@implementation TNExternalVNCWindow : CPWindow
{
    BOOL                _hasBeenConnected;
    CPImageView         _imageViewVirtualMachineAvatar;
    double              _currentZoom;
    TNStropheContact    _entity;
    TNToolbar           _mainToolbar;
    TNVNCView           _vncView;
    TNSpiceView         _spiceView;
    TNRemoteScreenView  _screenView;
}


#pragma mark -
#pragma mark Initialization

/*! intialize the window
    @param aRect the content rect of the window
    @param aStyleMask the style mask of the window
*/
- (id)initWithContentRect:(CGRect)aRect styleMask:(unsigned)aStyleMask
{
    if (self = [super initWithContentRect:aRect styleMask:aStyleMask])
    {
        _currentZoom = 1.0;
        _hasBeenConnected = NO;

        _mainToolbar = [[TNToolbar alloc] init];
        [self setToolbar:_mainToolbar];

        var zoomSlider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 96.0, 21.0)];
        [zoomSlider setMinValue:0.3];
        [zoomSlider setDoubleValue:1.0];
        [zoomSlider setMaxValue:1.0];

        var bundle = [CPBundle bundleForClass:[self class]];
        [_mainToolbar addItemWithIdentifier:@"CUSTOMSPACE" label:@"              " view:nil target:nil action:nil];
        [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarFullScreen label:CPBundleLocalizedString(@"Full Screen", @"Full Screen") icon:CPImageInBundle(@"IconsButtons/fullscreen.png", 32, 32, [CPBundle mainBundle]) target:self action:@selector(setFullScreen:)];
        [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarCtrlAltDel label:CPBundleLocalizedString(@"Ctrl Alt Del", @"Ctrl Alt Del") icon:CPImageInBundle(@"toolbarCtrlAtlDel.png", 32, 32, bundle) target:self action:@selector(sendCtrlAltDel:)];

        var zoomItem = [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarZoom label:CPBundleLocalizedString(@"Zoom", @"Zoom") view:zoomSlider target:self action:@selector(changeScale:)];

        [zoomItem setMinSize:CGSizeMake(120.0, 24.0)];
        [zoomItem setMaxSize:CGSizeMake(120.0, 24.0)];

        [_mainToolbar setPosition:0 forToolbarItemIdentifier:@"CUSTOMSPACE"];
        [_mainToolbar setPosition:1 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        [_mainToolbar setPosition:4 forToolbarItemIdentifier:TNVNCWindowToolBarCtrlAltDel];
        [_mainToolbar setPosition:5 forToolbarItemIdentifier:TNVNCWindowToolBarZoom];
        [_mainToolbar setPosition:10 forToolbarItemIdentifier:CPToolbarFlexibleSpaceItemIdentifier];
        [_mainToolbar setPosition:11 forToolbarItemIdentifier:TNVNCWindowToolBarFullScreen];

        [[self contentView] setBackgroundColor:[CPColor blackColor]];
    }

    return self;
}


#pragma mark -
#pragma mark Notification handlers

/*! called when entity updates its vCard (and so the avatar)
    @param aNotification the notification
*/
- (void)_entityVCardUpdated:(CPNotification)aNotification
{
    [_imageViewVirtualMachineAvatar setImage:[_entity avatar]];
}

/*! called when entity updates its nickname
    @param aNotification the notification
*/
- (void)_entityNicknameUpdated:(CPNotification)aNotification
{
    [self setTitle:CPBundleLocalizedString(@"Screen for ", @"Screen for ") + [_entity name] + " (" + [_entity JID] + ")"];
}


#pragma mark -
#pragma mark Utilities

/*! Initialize the window with given parameters
    @param aHost VNC host
    @param aPort VNC port
    @param aType the screen type (VNC, SPICE, etc)
    @param aPassword VNC password
    @param isEncrypted set encrypted or not
    @param isTrueColor set true color or not
    @param aCheckRate the check rate
    @param aFBURate the FBU rate
*/
- (void)loadVNCViewWithHost:(CPString)aHost port:(CPString)aPort type:(CPString)aType password:(CPString)aPassword encrypt:(BOOL)isEncrypted trueColor:(BOOL)isTrueColor checkRate:(int)aCheckRate FBURate:(int)aFBURate entity:(TNStropheContact)anEntity
{
    _entity = anEntity;

    [[CPNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(_entityVCardUpdated:)
                                                name:TNStropheContactVCardReceivedNotification
                                              object:_entity];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_entityNicknameUpdated:)
                                                 name:TNStropheContactNicknameUpdatedNotification
                                               object:_entity];

    [self setTitle:CPBundleLocalizedString(@"Screen for ", @"Screen for ") + [_entity name] + " (" + [_entity JID] + ")"];

    var domWindow = [[self platformWindow] DOMWindow],
        unloadFunction = function() {
                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
                [self close];
            };

    if (window.onbeforeunload)
        domWindow.onbeforeunload = unloadFunction;
    else if (window.onunload)
        domWindow.onunload = unloadFunction;

    _imageViewVirtualMachineAvatar = [[CPImageView alloc] initWithFrame:CGRectMake(7.0, 4.0, 50.0, 50.0)];
    [_imageViewVirtualMachineAvatar setImage:[_entity avatar]];
    [[_mainToolbar customSubViews] addObject:_imageViewVirtualMachineAvatar];
    [_mainToolbar reloadToolbarItems];

    switch (aType)
    {
        case TNArchipelVNCScreenTypeVNC:

            _vncView  = [[TNVNCView alloc] initWithFrame:[[self contentView] bounds]];

            [_vncView setFocusContainer:[[self platformWindow] DOMWindow].document];
            [_vncView setAutoResizeViewPort:NO];
            [_vncView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
            [_vncView setHost:aHost];
            [_vncView setPort:aPort];
            [_vncView setPassword:aPassword];
            [_vncView setZoom:1];
            [_vncView setTrueColor:isTrueColor];
            [_vncView setEncrypted:isEncrypted];
            [_vncView setCheckRate:aCheckRate];
            [_vncView setFrameBufferRequestRate:aFBURate];
            [_vncView setDelegate:self];

            [[self contentView] addSubview:_vncView];

            _screenView = _vncView;
            break;

        case TNArchipelVNCScreenTypeSPICE:
            _spiceView  = [[TNSpiceView alloc] initWithFrame:[[self contentView] bounds] focusContainer:[[self platformWindow] DOMWindow].document];

            [_spiceView setAutoResizeViewPort:NO];
            [_spiceView setHost:aHost];
            [_spiceView setPort:aPort];
            [_spiceView setPassword:aPassword];
            [_spiceView setZoom:1];
            [_spiceView setEncrypted:isEncrypted];
            [_spiceView setDelegate:self];

            [[self contentView] addSubview:_spiceView];

            _screenView = _spiceView;
            break;
    }

    CPLog.info("VNC: type: %@ connecting to %@:%@ using SSL: %@ ", aType, aHost, aPort, isEncrypted);

    try
    {
        [_screenView load];
        [_screenView connect:nil];
    }
    catch(e)
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Websocket error for VNC", @"Websocket error for VNC")
                          informative:CPBundleLocalizedString(@"It seems your websocket configuration is not properly configured. If you are using Firefox, go to about:config and set 'network.websocket.override-security-block' and 'network.websocket.enabled' to 'True'.", @"It seems your websocket configuration is not properly configured. If you are using Firefox, go to about:config and set 'network.websocket.override-security-block' and 'network.websocket.enabled' to 'True'.")
                                style:CPCriticalAlertStyle];
        CPLog.error("Websocket problem. unable to start noVNC subsystem.");
        [self close];
    }

    [self makeKeyAndOrderFront:nil];
}

- (void)fitWindowToVNCView
{
    [self fitWindowToSize:[_screenView displaySize]];
}

- (void)fitWindowToSize:(CGSize)aSize
{
    var newRect         = [[self platformWindow] contentRect],
        heightOffset    = 59;

    aSize.width   *= _currentZoom;
    aSize.height  *= _currentZoom;
    aSize.height  += heightOffset;
    newRect.size  = aSize;

    [self setFrameSize:aSize];
    [[self platformWindow] setContentRect:newRect];
}


#pragma mark -
#pragma mark Actions

/*! send CTRL ALT DEL to the VNC server
    @param aSender the sender of the action
*/
- (IBAction)sendCtrlAltDel:(id)aSender
{
    [_screenView sendCtrlAltDel:aSender];
}

/*! get the remote pasteboard
    @param aSender the sender of the action
*/
- (IBAction)getPasteboard:(id)aSender
{
    //test
    [_mainToolbar reloadToolbarItems];
    // alert("not implemented");
}

/*! send the local pasteboard
    @param aSender the sender of the action
*/
- (IBAction)sendPasteboard:(id)aSender
{
    alert("not implemented");
}

/*! display in full screen
    @param aSender the sender of the action
*/
- (IBAction)setFullScreen:(id)aSender
{
    [_screenView setFullScreen:![_screenView isFullScreen]];
}

/*! set the zoom factor
    @param sender the sender of the action
*/
- (IBAction)changeScale:(id)aSender
{
    // seems that isContinuous is keyvalue coded.
    // this is a hack. but it works.
    [aSender setContinuous:NO];
    _currentZoom = [aSender floatValue];
    [_screenView setZoom:_currentZoom];

    [self fitWindowToVNCView];
}


#pragma mark -
#pragma mark Delegate

/*! VNCView delegate
*/
- (void)remoteScreenView:(TNRemoteScreenView)aScreenView updateState:(CPString)aState message:(CPString)aMessage
{
    switch (aState)
    {
        case TNRemoteScreenViewStateError:
            [aScreenView setHidden:YES];
            var growl = [[TNGrowlCenter alloc] init];
            [growl setView:[self contentView]];
            [growl pushNotificationWithTitle:[_entity name]
                                     message:CPBundleLocalizedString(@"Error connecting to the VNC screen. Use the VNC tab for more information.", @"Error connecting to the VNC screen. Use the VNC tab for more information.")
                                        icon:TNGrowlIconError];

            CPLog.error(@"Cannot connect to the VNC screen at " + [aScreenView host] + @":" + [aScreenView port]);
            break;

        case TNRemoteScreenViewStateConnected:
            _hasBeenConnected = YES;
            [aScreenView setHidden:NO];
            [aScreenView focus];
            setTimeout(function(){
                [self fitWindowToVNCView];
            }, 500);

            break;

        case TNRemoteScreenViewStateDisconnected:
            if (_hasBeenConnected)
            {
                [aScreenView setHidden:YES];
                [self close];
                [[self platformWindow] orderOut:nil];
            }
    }
}

/*! VNCView delegate
*/
- (void)remoteScreenView:(TNRemoteScreenView)aScreenView didDesktopSizeChange:(CGSize)aNewSize
{
    [self fitWindowToSize:aNewSize];
}

/*! VNCView delegate
*/
- (void)remoteScreenView:(TNRemoteScreenView)aScreenView didBecomeFullScreen:(BOOL)isFullScreen size:(CGSize)aSize zoomFactor:(float)zoomFactor
{
    [aScreenView setZoom:zoomFactor];
}

/*! VNCView delegate
*/
- (void)remoteScreenViewDoesNotSupportFullScreen:(TNRemoteScreenView)aScreenView
{
    var growl = [[TNGrowlCenter alloc] init];
    [growl setView:[self contentView]];
    [growl pushNotificationWithTitle:[_entity name]
                             message:CPBundleLocalizedString(@"Your browser does not support javascript fullscreen", @"Your browser does not support javascript fullscreen")
                                icon:TNGrowlIconWarning];
}


#pragma mark -
#pragma mark CPWindow overrides

- (void)close
{
    [[CPNotificationCenter defaultCenter] removeObserver:self];
    CPLog.info("disconnecting windowed noVNC client")

    if ([_screenView state] != TNRemoteScreenViewStateDisconnected)
        [_screenView disconnect:nil];

    [_screenView unfocus];
    [super close];
}

@end

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNExternalVNCWindow], comment);
}

