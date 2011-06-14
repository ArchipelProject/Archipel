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
@import <AppKit/CPWindow.j>

@import <TNKit/TNToolbar.j>
@import <TNKit/TNToolbar.j>
@import <VNCCappuccino/TNVNCView.j>

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
    CPImageView         _imageViewVirtualMachineAvatar;
    double              _currentZoom;
    TNStropheContact    _entity;
    TNToolbar           _mainToolbar;
    TNVNCView           _vncView;
}


#pragma mark -
#pragma mark Initialization

/*! intialize the window
    @param aRect the content rect of the window
    @param aStyleMask the style mask of the window
*/
- (id)initWithContentRect:(CGRect)aRect styleMask:(int)aStyleMask
{
    if (self = [super initWithContentRect:aRect styleMask:aStyleMask])
    {
        _currentZoom = 1.0;

        _mainToolbar = [[TNToolbar alloc] init];
        [self setToolbar:_mainToolbar];

        var zoomSlider = [[CPSlider alloc] initWithFrame:CPRectMake(0.0, 0.0, 96.0, 21.0)];
        [zoomSlider setMinValue:1.0];
        [zoomSlider setDoubleValue:100.0];
        [zoomSlider setMaxValue:200.0];

        [_mainToolbar addItemWithIdentifier:@"CUSTOMSPACE" label:@"              " view:nil target:nil action:nil];
        [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarGetPasteboard label:CPBundleLocalizedString(@"Get Clipboard", @"Get Clipboard") icon:[[CPBundle bundleForClass:[self class]] pathForResource:@"toolbarGetPasteboard.png"] target:self action:@selector(getPasteboard:)];
        [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarSendPasteboard label:CPBundleLocalizedString(@"Send Clipboard", @"Send Clipboard") icon:[[CPBundle bundleForClass:[self class]] pathForResource:@"toolbarSendPasteboard.png"] target:self action:@selector(sendPasteboard:)];
        [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarFullScreen label:CPBundleLocalizedString(@"Full Screen", @"Full Screen") icon:[[CPBundle mainBundle] pathForResource:@"IconsButtons/fullscreen.png"] target:self action:@selector(setFullScreen:)];
        [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarCtrlAltDel label:CPBundleLocalizedString(@"Ctrl Alt Del", @"Ctrl Alt Del") icon:[[CPBundle bundleForClass:[self class]] pathForResource:@"toolbarCtrlAtlDel.png"] target:self action:@selector(sendCtrlAltDel:)];
        zoomItem = [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarZoom label:CPBundleLocalizedString(@"Zoom", @"Zoom") view:zoomSlider target:self action:@selector(changeScale:)];

        [zoomItem setMinSize:CGSizeMake(120.0, 24.0)];
        [zoomItem setMaxSize:CGSizeMake(120.0, 24.0)];

        [_mainToolbar setPosition:0 forToolbarItemIdentifier:@"CUSTOMSPACE"];
        [_mainToolbar setPosition:1 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        [_mainToolbar setPosition:2 forToolbarItemIdentifier:TNVNCWindowToolBarGetPasteboard];
        [_mainToolbar setPosition:3 forToolbarItemIdentifier:TNVNCWindowToolBarSendPasteboard];
        [_mainToolbar setPosition:4 forToolbarItemIdentifier:TNVNCWindowToolBarCtrlAltDel];
        [_mainToolbar setPosition:5 forToolbarItemIdentifier:TNVNCWindowToolBarZoom];
        [_mainToolbar setPosition:10 forToolbarItemIdentifier:CPToolbarFlexibleSpaceItemIdentifier];
        [_mainToolbar setPosition:11 forToolbarItemIdentifier:TNVNCWindowToolBarFullScreen];
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
    [self setTitle:CPBundleLocalizedString(@"Screen for ", @"Screen for ") + [_entity nickname] + " (" + [_entity JID] + ")"];
    [[self platformWindow] setTitle:[self title]];
}


#pragma mark -
#pragma mark Utilities

/*! Initialize the window with given parameters
    @param aHost VNC host
    @param aPort VNC port
    @param aPassword VNC password
    @param isEncrypted set encrypted or not
    @param isTrueColor set true color or not
    @param aCheckRate the check rate
    @param aFBURate the FBU rate
*/
- (void)loadVNCViewWithHost:(CPString)aHost port:(CPString)aPort password:(CPString)aPassword encrypt:(BOOL)isEncrypted trueColor:(BOOL)isTrueColor checkRate:(int)aCheckRate FBURate:(int)aFBURate entity:(TNStropheContact)anEntity
{
    _entity = anEntity;

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_entityVCardUpdated:) name:TNStropheContactVCardReceivedNotification object:_entity];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_entityNicknameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];

    [self setTitle:CPBundleLocalizedString(@"Screen for ", @"Screen for ") + [_entity nickname] + " (" + [_entity JID] + ")"];
    [[self platformWindow] setTitle:[self title]];
    [[self platformWindow] DOMWindow].onbeforeunload = function(){
        [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode];
        [self close];
        // FIXME: should we free self ?
    };

    _imageViewVirtualMachineAvatar = [[CPImageView alloc] initWithFrame:CPRectMake(7.0, 4.0, 50.0, 50.0)];
    [_imageViewVirtualMachineAvatar setImage:[_entity avatar]];
    [[_mainToolbar customSubViews] addObject:_imageViewVirtualMachineAvatar];
    [_mainToolbar reloadToolbarItems];

    _vncView  = [[TNVNCView alloc] initWithFrame:[[self contentView] bounds]];

    [_vncView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_vncView setFocusContainer:[[self platformWindow] DOMWindow].document];
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

    CPLog.info("VNC: connecting to " + aHost + ":" + aPort + " using SSL:" + isEncrypted);

    [_vncView load];
    [_vncView connect:nil];
}

- (void)fitWindowToVNCView
{
    [self fitWindowToSize:[_vncView displaySize]];
}

- (void)fitWindowToSize:(CPSize)aSize
{
    var vncSize         = aSize,
        newRect         = [[self platformWindow] contentRect],
        widthOffset     = 6,
        heightOffset    = 6 + 59;

    vncSize.width   *= _currentZoom;
    vncSize.height  *= _currentZoom;
    vncSize.width   += widthOffset;
    vncSize.height  += heightOffset;
    newRect.size    = vncSize;

    [self setFrameSize:vncSize];
    [[self platformWindow] setContentRect:newRect];

    // seems needed with Safari/WebKit nightlies
    if ([CPPlatform isBrowser] && (navigator.vendor.indexOf("Apple Computer, Inc.") != -1))
        [[self platformWindow] updateNativeContentRect];
}


#pragma mark -
#pragma mark Actions

/*! send CTRL ALT DEL to the VNC server
    @param aSender the sender of the action
*/
- (IBAction)sendCtrlAltDel:(id)aSender
{
    [_vncView sendCtrlAltDel:aSender];
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
    [_vncView setFullScreen:![_vncView isFullScreen]];
}

/*! set the zoom factor
    @param sender the sender of the action
*/
- (IBAction)changeScale:(id)aSender
{
    // seems that isContinuous is keyvalue coded.
    // this is a hack. but it works.
    [aSender setContinuous:NO];
    _currentZoom = [aSender intValue] / 100;
    [_vncView setZoom:_currentZoom];

    [self fitWindowToVNCView];
}


#pragma mark -
#pragma mark Delegate

/*! VNCView delegate
*/
- (void)vncView:(TNVNCView)aVNCView updateState:(CPString)aState message:(CPString)aMessage
{
    switch (aState)
    {
        case TNVNCCappuccinoStateFailed:
            var growl = [[TNGrowlCenter alloc] init];
            [growl setView:[self contentView]];
            [growl pushNotificationWithTitle:CPBundleLocalizedString(@"Connection fail", @"Connection fail")
                                     message:CPBundleLocalizedString(@"Cannot connect to the VNC screen at ", @"Cannot connect to the VNC screen at ") + [_vncView host] + @":" + [_vncView port]
                                        icon:TNGrowlIconError];

            CPLog.error(@"Cannot connect to the VNC screen at " + [_vncView host] + @":" + [_vncView port]);
            break;

        case TNVNCCappuccinoStateNormal:
            [self fitWindowToVNCView];
            [_vncView focus];
            break;
    }
}

/*! VNCView delegate
*/
- (void)vncView:(TNVNCView)aVNCView didDesktopSizeChange:(CPSize)aNewSize
{
    [self fitWindowToSize:aNewSize];
}

/*! VNCView delegate
*/
- (void)vncView:(TNVNCView)aVNCView didBecomeFullScreen:(BOOL)isFullScreen size:(CPSize)aSize zoomFactor:(float)zoomFactor
{
    [_vncView setZoom:zoomFactor];
}

- (void)vncViewDoesNotSupportFullScreen:(TNVNCView)aVNCView
{
    var growl = [[TNGrowlCenter alloc] init];
    [growl setView:[self contentView]];
    [growl pushNotificationWithTitle:CPBundleLocalizedString(@"FullScreen not supported", @"FullScreen not supported")
                             message:CPBundleLocalizedString(@"Your browser does not support javascript fullscreen", @"Your browser does not support javascript fullscreen")
                                icon:TNGrowlIconWarning];
}

#pragma mark -
#pragma mark CPWindow overrides

- (void)close
{
    [[CPNotificationCenter defaultCenter] removeObserver:self];
    CPLog.info("disconnecting windowed noVNC client")

    if ([_vncView state] != TNVNCCappuccinoStateDisconnected)
        [_vncView disconnect:nil];
    [_vncView unfocus];
    [super close];
}

@end

// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNExternalVNCWindow], comment);
}

