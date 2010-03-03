/*  
 * TNDatasourceRoster.j
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
@import <StropheCappuccino/StropheCappuccino.j>


@implementation TNDatasourceRoster  : TNStropheRoster 
{
    CPOutlineView   outlineView     @accessors;
    CPString        filter          @accessors;
    CPTextField     filterField     @accessors;
}

- (id)initWithConnection:(TNStropheConnection)aConnection
{
    if (self = [super initWithConnection:aConnection])
    {
        [self setFilter:nil];
        
        // register for notifications that should trigger outlineview reload
        var center = [CPNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterRetrievedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineViewAndKeepOldSelection:) name:TNStropheRosterRemovedContactNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineViewAndKeepOldSelection:) name:TNStropheRosterAddedContactNotification object:nil];
        
        [center addObserver:self selector:@selector(updateOutlineViewItem:) name:TNStropheContactPresenceUpdatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactNicknameUpdatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactGroupUpdatedNotification object:nil];
        
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterAddedGroupNotification object:nil];
        
        [center addObserver:self selector:@selector(updateOutlineViewAndKeepOldSelection:) name:TNStropheContactMessageReceivedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineViewAndKeepOldSelection:) name:TNStropheContactMessageTreatedNotification object:nil];
    }
     
    return self;
}

- (void)setFilterField:(CPTextField)aField
{
    filterField = aField;
    [[self filterField] addObserver:self forKeyPath:@"stringValue" options:CPKeyValueObservingOptionNew context:nil];
    
}

- (void)observeValueForKeyPath:(CPString)keyPath ofObject:(id)object change:(CPDictionary)change context:(id)context 
{
    if ([object stringValue] == "")
        [self setFilter:nil]
    else
        [self setFilter:[object stringValue]];

    [self updateOutlineView:nil];
}
                       
- (void)updateOutlineViewAndKeepOldSelection:(CPNotification)aNotification 
{   
    [[self outlineView] reloadData];
}

- (void)updateOutlineView:(CPNotification)aNotification 
{       
    [[self outlineView] reloadData];
    
    var index = [[self outlineView] rowForItem:[aNotification object]];
    var set = [CPIndexSet indexSetWithIndex:index];
    [[self outlineView] selectRowIndexes:set byExtendingSelection:NO];
}


- (void)updateOutlineViewItem:(CPNotification)aNotification
{
    [[self outlineView] reloadItem:[aNotification object]];
}

- (void)updateOutlineViewGroupItem:(CPNotification)aNotification
{

    [[self outlineView] reloadItem:[self getGroup:[[aNotification object] group]]];
}


- (int)outlineView:(CPOutlineView)outlineView numberOfChildrenOfItem:(id)item 
{
    if (!item) 
    {
	    return [[self getGroupContainingEntriesMatching:[self filter]] count];
	}
	else 
	{
	    return [[self getEntriesMatching:[self filter] inGroup:item] count];
	}
}

- (BOOL)outlineView:(CPOutlineView)outlineView isItemExpandable:(id)item 
{
	return ([item type] == @"group") ? YES : NO;
}

- (id)outlineView:(CPOutlineView)outlineView child:(int)index ofItem:(id)item  
{
    if (!item) 
    {
        return [[self getGroupContainingEntriesMatching:[self filter]].sort() objectAtIndex:index];
    }
    else 
    {
        return [[self getEntriesMatching:[self filter] inGroup:[item name]].sort() objectAtIndex:index];
    }
}

- (id)outlineView:(CPOutlineView)outlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item 
{
    var cid = [tableColumn identifier];

    if (cid == @"nickname")
    {
        return item;
    }
    else if (cid == @"statusIcon") 
    {
        if ([item type] == @"contact")
            return [item statusIcon];
        else
            return nil;
    }
}



- (CPArray)getEntriesMatching:(CPString)aFilter 
{
    var theEntries      = [self entries];
    var filteredEntries = [[CPArray alloc] init];
    var i;
    
    if (!aFilter)
        return theEntries;
    
    //@each (var entry in theEntries)
    for(var i = 0; i < [theEntries count]; i++)
    {
        var entry = [theEntries objectAtIndex:i];
        
        if ([[entry nickname] uppercaseString].indexOf([aFilter uppercaseString]) != -1)
            [filteredEntries addObject:entry]
    }
    return filteredEntries;
}

- (CPArray)getEntriesMatching:(CPString)aFilter inGroup:(CPString)aGroup
{
    var theEntries      = [self getContactsInGroup:aGroup];
    var filteredEntries = [[CPArray alloc] init];
    var i;
    
    if (!aFilter)
        return theEntries;
    
    //@each (var entry in theEntries)
    for(var i = 0; i < [theEntries count]; i++)
    {
        var entry = [theEntries objectAtIndex:i];
        
        if ([[entry nickname] uppercaseString].indexOf([aFilter uppercaseString]) != -1)
            [filteredEntries addObject:entry];
    }
    
    return filteredEntries;
}

- (CPArray)getGroupContainingEntriesMatching:(CPString)aFilter
{
    var theGroups      = [self groups];
    var filteredGroup   = [[CPArray alloc] init];
    var i;
    
    if (!aFilter)
        return [self groups];
        
    //@each (var group in theGroups)
    for(var i = 0; i < [theGroups count]; i++)
    {
        var group = [theGroups objectAtIndex:i];
        
        if ([[self getEntriesMatching:aFilter inGroup:[group name]] count] > 0)
            [filteredGroup addObject:group];
    }
    
    return filteredGroup;
}

@end