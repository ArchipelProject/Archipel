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

@implementation TNExternalVNCWindow : CPWindow
{
    TNVNCView       _vncView;
}

- (void)loadVNCViewWithHost:(CPString)aHost port:(CPString)aPort password:(CPString)aPassword encrypt:(BOOL)isEncrypted trueColor:(BOOL)isTrueColor
{
    [[self platformWindow] setTitle:[self title]];
    _vncView  = [[TNVNCView alloc] initWithFrame:[[self contentView] bounds]];
    
    [_vncView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [[self contentView] addSubview:_vncView];
    
    [_vncView setFocusContainer:[[self platformWindow] DOMWindow].document];
    [_vncView load];
    [_vncView setHost:aHost];
    [_vncView setPort:aPort];
    [_vncView setPassword:aPassword];
    [_vncView setZoom:1];
    [_vncView setTrueColor:isTrueColor];
    [_vncView setEncrypted:isEncrypted];
    [_vncView setDelegate:self];
    [_vncView connect:nil];
    
    
    
    [[self platformWindow] DOMWindow].onbeforeunload = function(){
        [self close];
    };
}

- (void)vncView:(TNVNCView)aVNCView updateState:(CPString)aState message:(CPString)aMessage
{
    switch(aState)
    {
        case TNVNCCappuccinoStateFailed:
            [self close];
            break;
        
        case TNVNCCappuccinoStateNormal:
            [_vncView focus];
            break;
    }
}

- (void)close
{
    CPLog.info("disconnecting windowed noVNC client")
    
    if ([_vncView state] != TNVNCCappuccinoStateDisconnected)
    {
        [_vncView disconnect:nil];
        [_vncView clear];
        [_vncView unfocus];
    }
    [_vncView invalidate];
    [super close];
}
@end