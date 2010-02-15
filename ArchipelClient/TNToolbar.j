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


TNToolBarItemLogout = @"TNToolBarItemLogout";
TNToolBarItemAddJid = @"TNToolBarItemAddJid";
TNToolBarItemDeleteJid = @"TNToolBarItemDeleteJid";
TNToolBarItemAddGroup = @"TNToolBarItemAddGroup";
TNToolBarItemDeleteGroup = @"TNToolBarItemDeleteGroup";

TNToolBarItemLogoutClickedNotification = @"TNToolBarItemLogoutClickedNotification";


@implementation TNToolbar  : CPToolbar
{    
    CPToolbarItem itemAddJid        @accessors;
    CPToolbarItem itemDeleteJid     @accessors;
    CPToolbarItem itemAddGroup      @accessors;
    CPToolbarItem itemDeleteGroup   @accessors;
    CPToolbarItem itemLogout        @accessors;
}

-(id)initWithTarget:(id)aTarget
{
    if (self = [super init])
    {
        [self setItemLogout:[[CPToolbarItem alloc] initWithItemIdentifier:TNToolBarItemLogout]];
        [[self itemLogout] setLabel:@"Log out"];
        [[self itemLogout] setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/logout.png" size:CPSizeMake(32,32)]];
        [[self itemLogout] setTarget:aTarget];
        [[self itemLogout] setAction:@selector(toolbarItemLogoutClick:)];

        [self setItemAddJid:[[CPToolbarItem alloc] initWithItemIdentifier:TNToolBarItemAddJid]];
        [[self itemAddJid] setLabel:@"Add JID"];
        [[self itemAddJid] setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/add.png" size:CPSizeMake(32,32)]];
        [[self itemAddJid] setTarget:aTarget];
        [[self itemAddJid] setAction:@selector(toolbarItemAddContactClick:)];

        [self setItemDeleteJid:[[CPToolbarItem alloc] initWithItemIdentifier:TNToolBarItemDeleteJid]];
        [[self itemDeleteJid] setLabel:@"Delete JID"];
        [[self itemDeleteJid] setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/delete.png" size:CPSizeMake(32,32)]];
        [[self itemDeleteJid] setTarget:aTarget];
        [[self itemDeleteJid] setAction:@selector(toolbarItemDeleteContactClick:)];

        [self setItemAddGroup:[[CPToolbarItem alloc] initWithItemIdentifier:TNToolBarItemAddGroup]];
        [[self itemAddGroup] setLabel:@"Add Group"];
        [[self itemAddGroup] setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/groupAdd.png" size:CPSizeMake(32,32)]];
        [[self itemAddGroup] setTarget:aTarget];
        [[self itemAddGroup] setAction:@selector(toolbarItemAddGroupClick:)];

        [self setItemDeleteGroup:[[CPToolbarItem alloc] initWithItemIdentifier:TNToolBarItemDeleteGroup]];
        [[self itemDeleteGroup] setLabel:@"Delete Group"];
        [[self itemDeleteGroup] setImage:[[CPImage alloc] initWithContentsOfFile:@"Resources/groupDelete.png" size:CPSizeMake(32,32)]];
        //[[self itemDeleteGroup] setTarget:aTarget];
        //[[self itemDeleteGroup] setAction:@selector(toolbarItemDeleteClick:)];

        [self setDelegate:self];
    }
    
    return self;
}

- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar 
{
   return [TNToolBarItemAddJid,TNToolBarItemDeleteJid, CPToolbarSeparatorItemIdentifier, 
                TNToolBarItemAddGroup, TNToolBarItemDeleteGroup, CPToolbarFlexibleSpaceItemIdentifier, TNToolBarItemLogout];
}

- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar 
{
   return [TNToolBarItemAddJid,TNToolBarItemDeleteJid,CPToolbarSeparatorItemIdentifier, 
                TNToolBarItemAddGroup, TNToolBarItemDeleteGroup, CPToolbarFlexibleSpaceItemIdentifier, TNToolBarItemLogout];
}

- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anItemIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{     
    var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];
    
    if (anItemIdentifier == TNToolBarItemLogout)
        toolbarItem = [self itemLogout];
    else if (anItemIdentifier == TNToolBarItemAddJid)
        toolbarItem = [self itemAddJid];
    else if (anItemIdentifier == TNToolBarItemDeleteJid)
        toolbarItem = [self itemDeleteJid];
    else if (anItemIdentifier == TNToolBarItemDeleteGroup)
        toolbarItem = [self itemDeleteGroup];
    else if (anItemIdentifier == TNToolBarItemAddGroup)
        toolbarItem = [self itemAddGroup];
    
    return toolbarItem;
}
@end