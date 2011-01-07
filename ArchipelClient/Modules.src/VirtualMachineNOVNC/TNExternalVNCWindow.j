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

@import <AppKit/AppKit.j>


var TNVNCWindowToolBarCtrlAltDel        = @"TNVNCWindowToolBarCtrlAltDel",
    TNVNCWindowToolBarSendPasteboard    = @"TNVNCWindowToolBarSendPasteboard",
    TNVNCWindowToolBarGetPasteboard     = @"TNVNCWindowToolBarGetPasteboard";


/*! @ingroup virtualmachinenovnc
    CPWindow that contains the external VNCView
*/
@implementation TNExternalVNCWindow : CPWindow
{
    TNVNCView           _vncView;
    TNToolbar           _mainToolbar;
    TNStropheContact    _entity;
    CPImageView         _imageViewVirtualMachineAvatar;
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
        _mainToolbar = [[TNToolbar alloc] init];
        [self setToolbar:_mainToolbar];

        [_mainToolbar addItemWithIdentifier:@"CUSTOMSPACE" label:@"              "/* incredible huh ?*/ view:nil target:nil action:nil];
        [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarCtrlAltDel label:@"Ctrl Alt Del" icon:[[CPBundle bundleForClass:[self class]] pathForResource:@"toolbarCtrlAtlDel.png"] target:self action:@selector(sendCtrlAltDel:)];
        [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarGetPasteboard label:@"Get Clipboard" icon:[[CPBundle bundleForClass:[self class]] pathForResource:@"toolbarGetPasteboard.png"] target:self action:@selector(getPasteboard:)];
        [_mainToolbar addItemWithIdentifier:TNVNCWindowToolBarSendPasteboard label:@"Send Clipboard" icon:[[CPBundle bundleForClass:[self class]] pathForResource:@"toolbarSendPasteboard.png"] target:self action:@selector(sendPasteboard:)];

        [_mainToolbar setPosition:0 forToolbarItemIdentifier:@"CUSTOMSPACE"];
        [_mainToolbar setPosition:1 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        [_mainToolbar setPosition:2 forToolbarItemIdentifier:TNVNCWindowToolBarGetPasteboard];
        [_mainToolbar setPosition:3 forToolbarItemIdentifier:TNVNCWindowToolBarSendPasteboard];
        [_mainToolbar setPosition:4 forToolbarItemIdentifier:CPToolbarFlexibleSpaceItemIdentifier];
        [_mainToolbar setPosition:5 forToolbarItemIdentifier:TNVNCWindowToolBarCtrlAltDel];

        [_mainToolbar reloadToolbarItems];
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
    [self setTitle:@"Screen for " + [_entity nickname] + " (" + [_entity JID] + ")"];
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

    [self setTitle:@"Screen for " + [_entity nickname] + " (" + [_entity JID] + ")"];
    [[self platformWindow] setTitle:[self title]];
    [[self platformWindow] DOMWindow].onbeforeunload = function(){
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

    [_vncView load];
    [_vncView connect:nil];

}

- (void)fitWindowToVNCView
{
    var vncSize         = [_vncView canvasSize],
        newRect         = [self frame],
        widthOffset     = 6,
        heightOffset    = 6 + 59;

    vncSize.width   += widthOffset;
    vncSize.height  += heightOffset;
    newRect.size    = vncSize;

    [self setFrameSize:vncSize];
    [self setMaxSize:CPSizeMake(vncSize.width, vncSize.height)];
    [self setMinSize:CPSizeMake(vncSize.width, vncSize.height)];

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
    alert("not implemented");
}

/*! send the local pasteboard
    @param aSender the sender of the action
*/
- (IBAction)sendPasteboard:(id)aSender
{
    alert("not implemented");
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
            [self close];
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
    [self fitWindowToVNCView];
}

#pragma mark -
#pragma mark CPWindow overrides

- (void)close
{
    [[CPNotificationCenter defaultCenter] removeObserver:self];
    CPLog.info("disconnecting windowed noVNC client")

    if ([_vncView state] != TNVNCCappuccinoStateDisconnected)
    {
        [_vncView disconnect:nil];
        [_vncView unfocus];
    }
    [super close];
}

@end