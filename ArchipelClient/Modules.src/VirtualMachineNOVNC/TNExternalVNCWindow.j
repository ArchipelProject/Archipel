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

/*! @ingroup virtualmachinenovnc
    Category that enable the set the title of a physical window
*/
@implementation CPPlatformWindow (cool)

- (void)setTitle:(CPString)aTitle
{
    _DOMWindow.document.title = aTitle;
}

- (id)DOMWindow
{
    return _DOMWindow;
}
@end


/*! @ingroup virtualmachinenovnc
    CPWindow that contains the external VNCView
*/
@implementation TNExternalVNCWindow : CPWindow
{
    TNVNCView       _vncView;
}


#pragma mark -
#pragma mark Initialization

/*! Initialize the window with given parameters
    @param aHost VNC host
    @param aPort VNC port
    @param aPassword VNC password
    @param isEncrypted set encrypted or not
    @param isTrueColor set true color or not
    @param aCheckRate the check rate
    @param aFBURate the FBU rate
*/
- (void)loadVNCViewWithHost:(CPString)aHost port:(CPString)aPort password:(CPString)aPassword encrypt:(BOOL)isEncrypted trueColor:(BOOL)isTrueColor checkRate:(int)aCheckRate FBURate:(int)aFBURate
{
    [[self platformWindow] setTitle:[self title]];
    _vncView  = [[TNVNCView alloc] initWithFrame:[[self contentView] bounds]];

    [_vncView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [[self contentView] addSubview:_vncView];

    if ([[self platformWindow] DOMWindow])
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

    [_vncView load];
    [_vncView connect:nil];

    [[self platformWindow] DOMWindow].onbeforeunload = function(){
        [self close];
    };
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
            var vncSize         = [_vncView canvasSize],
                newRect         = [self frame],
                widthOffset     = 6,
                heightOffset    = 6;

            // if on chrome take care of the address bar and it's fuckness about counting it into the size of the window...
            if ([CPPlatform isBrowser] && (navigator.appVersion.indexOf("Chrome") != -1))
            {
                widthOffset     = 6;
                heightOffset    = 56;
            }

            vncSize.width += widthOffset;
            vncSize.height += heightOffset;
            newRect.size = vncSize;

            [self setFrameSize:vncSize];
            [self setMaxSize:CPSizeMake(vncSize.width, vncSize.height)];
            [self setMinSize:CPSizeMake(vncSize.width, vncSize.height)];

            [[self platformWindow] setContentRect:newRect];
            [[self platformWindow] updateNativeContentRect];

            [_vncView focus];
            break;
    }
}


#pragma mark -
#pragma mark CPWindow overrides

- (void)close
{
    CPLog.info("disconnecting windowed noVNC client")

    if ([_vncView state] != TNVNCCappuccinoStateDisconnected)
    {
        [_vncView disconnect:nil];
        [_vncView unfocus];
    }
    [super close];
}

@end