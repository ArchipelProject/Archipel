/*  
 * TNSnapshotsDatasource.j
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
 
@implementation TNSnapshotsDatasource : CPObject
{
    BOOL            filterInstalled     @accessors(setter=setFilterInstalled:, getter=isFilterInstalled);
    CPArray         _contents           @accessors(property=contents);
    CPArray         _searchableKeyPaths @accessors(property=searchableKeyPaths);
    CPString        _childCompKeyPath   @accessors(property=childCompKeyPath);
    CPString        _parentKeyPath      @accessors(property=parentKeyPath);
}

/*! Initialization of the class
    @return an initialized instance of TNVMCastDatasource
*/
- (id)init
{
    if (self = [super init])
    {
        _contents = [CPArray array];
    }
    
    return self;
}

- (void)count
{
    return [_contents count];
}

- (CPArray)objects
{
    return _contents;
}

- (void)addObject:(id)anObject
{
    [_contents addObject:anObject];
}

- (void)removeAllObjects
{
    [_contents removeAllObjects];
}

- (id)objectAtIndex:(int)anIndex
{
   return [_contents objectAtIndex:anIndex];
}

- (CPArray)objectsAtIndexes:(CPIndexSet)indexes
{
    return [_contents objectsAtIndexes:indexes];
}

- (id)getRootObjects
{
    var array = [CPArray array];
     
    for(var i = 0; i < [_contents count]; i++)
    {
        var object = [_contents objectAtIndex:i];
        
        if ([object valueForKeyPath:_parentKeyPath] == nil)
            [array addObject:object];
    }
    
    return array;
}

- (CPArray)getChildrenOfObject:(id)anObject
{
    var array = [CPArray array];
    
    for(var i = 0; i < [_contents count]; i++)
    {
        var object = [_contents objectAtIndex:i];
        if ([object valueForKey:_parentKeyPath] == [anObject valueForKey:_childCompKeyPath])
            [array addObject:object];
    }
    
    return array;
}


/*! CPOutlineView Delegate
*/
- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
	    return [[self getRootObjects] count];
	else
        return [[self getChildrenOfObject:item] count];
}

/*! CPOutlineView Delegate
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)item
{
    if (!item)
        return YES;
    
	return ([[self getChildrenOfObject:item] count] > 0) ? YES : NO;
}

/*! CPOutlineView Delegate
*/
- (id)outlineView:(CPOutlineView)anOutlineView child:(int)index ofItem:(id)item
{
    if (!item)
        return [[self getRootObjects] objectAtIndex:index];
    else
        return [[self getChildrenOfObject:item] objectAtIndex:index];
}

/*! CPOutlineView Delegate
*/
- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    var identifier = [tableColumn identifier];
    
    if (identifier == @"outline")
        return nil;
    
    return [item valueForKey:identifier];
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{
    [_contents sortUsingDescriptors:[aTableView sortDescriptors]];

    [aTableView reloadData];
}

@end
