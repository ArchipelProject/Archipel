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
    // CPToolbar       _toolbar;
    // CPDictionary    _toolbarItems;
}


// - (id)initWithContentRect:(CPRect)aRect styleMask:(id)aStyleMask
// {
//     if (self = [super initWithContentRect:aRect styleMask:aStyleMask])
//     {
//         var bundle      = [CPBundle mainBundle];
//         _toolbar        = [[CPToolbar alloc] initWithIdentifier:[CPString UUID]];
//         _toolbarItems   = [CPDictionary dictionary];
//         
//         var lockItem    = [[CPToolbarItem alloc] initWithItemIdentifier:@"lock"];
//         var imageLock   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"lock.png"]];
//         
//         [lockItem setLabel:@"Lock"];
//         [lockItem setImage:[[CPImage alloc] initWithContentsOfFile:imageLock size:CPSizeMake(32,32)]];
//         [_toolbarItems setObject:lockItem forKey:@"lock"];
//         
//         [_toolbar setDelegate:self];
//         [self setToolbar:_toolbar];
//     }
//     
//     return self;
// }

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

// - (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)toolbar
// {
//     CPLog.info([_toolbarItems allKeys])
//     return [_toolbarItems allKeys];
// }
// 
// - (CPToolbarItem)toolbar:(CPToolbar)toolbar itemForItemIdentifier:(CPString)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
// {
//     var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
//     
//     return ([_toolbarItems objectForKey:itemIdentifier]) ? [_toolbarItems objectForKey:itemIdentifier] : toolbarItem;
// }

@end