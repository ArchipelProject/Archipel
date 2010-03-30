/*  
 * TNToolbar.j
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


TNToolBarItemLogout         = @"TNToolBarItemLogout";
TNToolBarItemAddJid         = @"TNToolBarItemAddJid";
TNToolBarItemDeleteJid      = @"TNToolBarItemDeleteJid";
TNToolBarItemAddGroup       = @"TNToolBarItemAddGroup";
TNToolBarItemDeleteGroup    = @"TNToolBarItemDeleteGroup";
TNToolBarItemViewLog        = @"TNToolBarItemViewLog";
TNToolBarItemClearLog       = @"TNToolBarItemClearLog";
TNToolBarItemViewMap        = @"TNToolBarItemViewMap";

TNToolBarItemLogoutClickedNotification = @"TNToolBarItemLogoutClickedNotification";


@implementation TNToolbar  : CPToolbar
{
    CPDictionary    toolbarItems            @accessors;
    CPArray         toolbarItemsOrder       @accessors;
}

-(id)initWithTarget:(id)aTarget
{
    var bundle = [CPBundle bundleForClass:self];
    
    if (self = [super init])
    {
        toolbarItems        = [CPDictionary dictionary];
        toolbarItemsOrder   = [CPArray array];
        
        [self addItemWithIdentifier:TNToolBarItemLogout label:@"Log out" icon:[bundle pathForResource:@"logout.png"] target:aTarget action:@selector(toolbarItemLogoutClick:)];
        [self addItemWithIdentifier:TNToolBarItemAddJid label:@"Add JID" icon:[bundle pathForResource:@"add.png"] target:aTarget action:@selector(toolbarItemAddContactClick:)];
        [self addItemWithIdentifier:TNToolBarItemDeleteJid label:@"Delete JID" icon:[bundle pathForResource:@"delete.png"] target:aTarget action:@selector(toolbarItemDeleteContactClick:)];
        [self addItemWithIdentifier:TNToolBarItemAddGroup label:@"Add Group" icon:[bundle pathForResource:@"groupAdd.png"] target:aTarget action:@selector(toolbarItemAddGroupClick:)];
        [self addItemWithIdentifier:TNToolBarItemDeleteGroup label:@"Delete Group" icon:[bundle pathForResource:@"groupDelete.png"] target:nil action:nil];
        [self addItemWithIdentifier:TNToolBarItemViewLog label:@"View Log" icon:[bundle pathForResource:@"log.png"] target:aTarget action:@selector(toolbarItemViewLogClick:)];
        [self addItemWithIdentifier:TNToolBarItemClearLog label:@"Clear Log" icon:[bundle pathForResource:@"clearlog.png"] target:aTarget action:@selector(toolbarItemClearLogClick:)];
        
        [self setPosition:0 forToolbarItemIdentifier:TNToolBarItemAddJid];
        [self setPosition:1 forToolbarItemIdentifier:TNToolBarItemDeleteJid];
        [self setPosition:2 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        [self setPosition:3 forToolbarItemIdentifier:TNToolBarItemAddGroup];
        [self setPosition:4 forToolbarItemIdentifier:TNToolBarItemDeleteGroup];
        [self setPosition:5 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        [self setPosition:6 forToolbarItemIdentifier:CPToolbarFlexibleSpaceItemIdentifier];
        [self setPosition:7 forToolbarItemIdentifier:TNToolBarItemViewLog];
        [self setPosition:8 forToolbarItemIdentifier:TNToolBarItemClearLog];
        [self setPosition:9 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        [self setPosition:10 forToolbarItemIdentifier:TNToolBarItemLogout];
        
        [self setDelegate:self];
    }
    
    return self;
}

- (void)addItemWithIdentifier:(CPString)anIdentifier label:(CPString)aLabel icon:(CPImage)anImage target:(id)aTarget action:(SEL)anAction
{
    var newItem = [[CPToolbarItem alloc] initWithItemIdentifier:anIdentifier];
    
    [newItem setLabel:aLabel];
    [newItem setImage:[[CPImage alloc] initWithContentsOfFile:anImage size:CPSizeMake(32,32)]];
    [newItem setTarget:aTarget];
    [newItem setAction:anAction];
    
    [[self toolbarItems] setObject:newItem forKey:anIdentifier];
}

- (void)setPosition:(CPNumber)aPosition forToolbarItemIdentifier:(CPString)anIndentifier
{
     [[self toolbarItemsOrder] insertObject:anIndentifier atIndex:aPosition];
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar 
{
    return  [self toolbarItemsOrder];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar 
{
    return  [self toolbarItemsOrder];
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anItemIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{     
    var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];
    
    return ([[self toolbarItems] objectForKey:anItemIdentifier]) ? [[self toolbarItems] objectForKey:anItemIdentifier] : toolbarItem;
}
@end