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

/*! @global
    @group TNToolBarItem
    identifier for item logout
*/
TNToolBarItemLogout         = @"TNToolBarItemLogout";

/*! @global
    @group TNToolBarItem
    identifier for item add JID
*/
TNToolBarItemAddJID         = @"TNToolBarItemAddJID";

/*! @global
    @group TNToolBarItem
    identifier for item delete JID
*/
TNToolBarItemDeleteJID      = @"TNToolBarItemDeleteJID";

/*! @global
    @group TNToolBarItem
    identifier for item add group
*/
TNToolBarItemAddGroup       = @"TNToolBarItemAddGroup";

/*! @global
    @group TNToolBarItem
    identifier for item delete group
*/
TNToolBarItemDeleteGroup    = @"TNToolBarItemDeleteGroup";

/*! @global
    @group TNToolBarItem
    identifier for item help
*/
TNToolBarItemHelp           = @"TNToolBarItemHelp";

/*! @global
    @group TNToolBarItem
    identifier for item status
*/
TNToolBarItemStatus           = @"TNToolBarItemStatus";



/*! @ingroup archipelcore
    subclass of CPToolbar that allow dynamic insertion. This is used by TNModuleLoader
*/
@implementation TNToolbar  : CPToolbar
{
    CPDictionary    _toolbarItems;
    CPArray         _toolbarItemsOrder;
}

/*! initialize the class with a target
    @param aTarget the target
    @return a initialized instance of TNToolbar
*/
-(id)initWithTarget:(id)aTarget
{
    if (self = [super init])
    {
        var bundle          = [CPBundle bundleForClass:self];
        _toolbarItems       = [CPDictionary dictionary];
        _toolbarItemsOrder  = [CPArray array];

        [self addItemWithIdentifier:TNToolBarItemLogout label:@"Log out" icon:[bundle pathForResource:@"logout.png"] target:aTarget action:@selector(toolbarItemLogoutClick:)];
        [self addItemWithIdentifier:TNToolBarItemAddJID label:@"Add JID" icon:[bundle pathForResource:@"add.png"] target:aTarget action:@selector(toolbarItemAddContactClick:)];
        [self addItemWithIdentifier:TNToolBarItemDeleteJID label:@"Delete JID" icon:[bundle pathForResource:@"delete.png"] target:aTarget action:@selector(toolbarItemDeleteContactClick:)];
        [self addItemWithIdentifier:TNToolBarItemAddGroup label:@"Add Group" icon:[bundle pathForResource:@"groupAdd.png"] target:aTarget action:@selector(toolbarItemAddGroupClick:)];
        [self addItemWithIdentifier:TNToolBarItemDeleteGroup label:@"Delete Group" icon:[bundle pathForResource:@"groupDelete.png"] target:aTarget action:@selector(toolbarItemDeleteGroupClick:)];
        [self addItemWithIdentifier:TNToolBarItemHelp label:@"Help" icon:[bundle pathForResource:@"help.png"] target:aTarget action:@selector(toolbarItemHelpClick:)];
        [self addItemWithIdentifier:TNToolBarItemDeleteGroup label:@"Delete Group" icon:[bundle pathForResource:@"groupDelete.png"] target:aTarget action:@selector(toolbarItemDeleteGroupClick:)];
        
        var statusSelector = [[CPPopUpButton alloc] initWithFrame:CGRectMake(8.0, 8.0, 120.0, 24.0)];

        var availableItem = [[CPMenuItem alloc] init];
        [availableItem setTitle:TNArchipelStatusAvailableLabel];
        [availableItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Available.png"]]];
        [statusSelector addItem:availableItem];
        
        var awayItem = [[CPMenuItem alloc] init];
        [awayItem setTitle:TNArchipelStatusAwayLabel];
        [awayItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Away.png"]]];
        [statusSelector addItem:awayItem];
        
        var busyItem = [[CPMenuItem alloc] init];
        [busyItem setTitle:TNArchipelStatusBusyLabel];
        [busyItem setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"Busy.png"]]];
        [statusSelector addItem:busyItem];
        
        [self addItemWithIdentifier:TNToolBarItemStatus label:@"Status" view:statusSelector target:aTarget action:@selector(toolbarItemPresenceStatusClick:)];
        
        
        [self setPosition:0 forToolbarItemIdentifier:TNToolBarItemStatus];
        [self setPosition:1 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        // [self setPosition:2 forToolbarItemIdentifier:TNToolBarItemAddJID];
        // [self setPosition:3 forToolbarItemIdentifier:TNToolBarItemDeleteJID];
        // [self setPosition:4 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        // [self setPosition:5 forToolbarItemIdentifier:TNToolBarItemAddGroup];
        // [self setPosition:6 forToolbarItemIdentifier:TNToolBarItemDeleteGroup];
        // [self setPosition:7 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        [self setPosition:2 forToolbarItemIdentifier:CPToolbarFlexibleSpaceItemIdentifier];
        [self setPosition:3 forToolbarItemIdentifier:CPToolbarSeparatorItemIdentifier];
        [self setPosition:900 forToolbarItemIdentifier:TNToolBarItemHelp];
        [self setPosition:900 forToolbarItemIdentifier:TNToolBarItemLogout];
        
        
        [self setDelegate:self];
    }

    return self;
}

/*! add a new CPToolbarItem
    @param anIdentifier CPString containing the identifier
    @param aLabel CPString containing the label
    @param anImage CPImage containing the icon of the item
    @param aTarget an object that will be the target of the item
    @param anAction a selector of the aTarget to perform on click
*/
- (void)addItemWithIdentifier:(CPString)anIdentifier label:(CPString)aLabel icon:(CPImage)anImage target:(id)aTarget action:(SEL)anAction
{
    var newItem = [[CPToolbarItem alloc] initWithItemIdentifier:anIdentifier];

    [newItem setLabel:aLabel];
    [newItem setImage:[[CPImage alloc] initWithContentsOfFile:anImage size:CPSizeMake(32,32)]];
    [newItem setTarget:aTarget];
    [newItem setAction:anAction];

    [_toolbarItems setObject:newItem forKey:anIdentifier];
}

/*! add a new CPToolbarItem with a custom view
    @param anIdentifier CPString containing the identifier
    @param aLabel CPString containing the label
    @param anImage CPImage containing the icon of the item
    @param aTarget an object that will be the target of the item
    @param anAction a selector of the aTarget to perform on click
*/
- (void)addItemWithIdentifier:(CPString)anIdentifier label:(CPString)aLabel view:(CPView)aView target:(id)aTarget action:(SEL)anAction
{
    var newItem = [[CPToolbarItem alloc] initWithItemIdentifier:anIdentifier];
    
    [newItem setMinSize:CGSizeMake(120.0, 24.0)];
    [newItem setMaxSize:CGSizeMake(120.0, 24.0)]
            
    [newItem setLabel:aLabel];
    [newItem setView:aView];
    [newItem setTarget:aTarget];
    [newItem setAction:anAction];

    [_toolbarItems setObject:newItem forKey:anIdentifier];
}

/*! define the position of a given existing CPToolbarItem according to its identifier
    @param anIndentifier CPString containing the identifier
*/
- (void)setPosition:(CPNumber)aPosition forToolbarItemIdentifier:(CPString)anIndentifier
{
     [_toolbarItemsOrder insertObject:anIndentifier atIndex:aPosition];
}

/*! CPToolbar Protocol
*/
- (CPArray)toolbarAllowedItemIdentifiers:(CPToolbar)aToolbar
{
    return  _toolbarItemsOrder;
}

/*! CPToolbar Protocol
*/
- (CPArray)toolbarDefaultItemIdentifiers:(CPToolbar)aToolbar
{
    return  _toolbarItemsOrder;
}

/*! CPToolbar Protocol
*/
- (CPToolbarItem)toolbar:(CPToolbar)aToolbar itemForItemIdentifier:(CPString)anItemIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
    var toolbarItem = [[CPToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];

    return ([_toolbarItems objectForKey:anItemIdentifier]) ? [_toolbarItems objectForKey:anItemIdentifier] : toolbarItem;
}

@end