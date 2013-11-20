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


/*! @ingroup virtualmachinedrives
    datasource of the snaphot outline view
*/
@implementation TNSnapshotsDatasource : CPObject
{
    CPArray         _contents           @accessors(property=contents);
    CPString        _childCompKeyPath   @accessors(property=childCompKeyPath);
    CPString        _parentKeyPath      @accessors(property=parentKeyPath);
    CPString        _filter             @accessors(property=filter);
}


#pragma mark -
#pragma mark Initialization
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


#pragma mark -
#pragma mark Data Information

/*! return the number of object in datasource
    @return number of objectss
*/
- (int)count
{
    return [_contents count];
}

/*! return the content of the datasource
    @return CPArray containing all objects
*/
- (CPArray)objects
{
    return _contents;
}

/*! get the object at given index
    @param anIndex the index
    @return the object at given index
*/
- (id)objectAtIndex:(int)anIndex
{
   return [_contents objectAtIndex:anIndex];
}

/*! get the object at given indexes
    @param anIndex the index
    @return CPArray of objects at given indexes
*/
- (CPArray)objectsAtIndexes:(CPIndexSet)indexes
{
    return [_contents objectsAtIndexes:indexes];
}

/*! get all the roots objects
    @return CPArray of the root objects
*/
- (CPArray)getRootObjects
{
    var array = [CPArray array];

    for (var i = 0; i < [_contents count]; i++)
    {
        var object = [_contents objectAtIndex:i];

        if ([object valueForKeyPath:_parentKeyPath] == nil)
            [array addObject:object];
    }

    return array;
}

/*! return all children of an object
    @param anObject the object
    @return CPArray containing the children of given object
*/
- (CPArray)getChildrenOfObject:(id)anObject
{
    var array = [CPArray array];

    for (var i = 0; i < [_contents count]; i++)
    {
        var object = [_contents objectAtIndex:i];
        if ([object valueForKey:_parentKeyPath] == [anObject valueForKey:_childCompKeyPath])
            [array addObject:object];
    }

    return array;
}

#pragma mark -
#pragma mark Filtering

/*! Message use internally for filtering
    @param aFilter CPString containing the filter
    @return a CPArray containing the items that matches the filters
*/
- (CPArray)_getEntriesMatching
{
    var filteredEntries = [CPArray array];

    for (var i = 0; i < [_contents count]; i++)
    {
        var entry = [_contents objectAtIndex:i];

        if ([[entry description] uppercaseString].indexOf([_filter uppercaseString]) != -1
            || [[entry creationTime] uppercaseString].indexOf([_filter uppercaseString]) != -1)
        {
            [filteredEntries addObject:entry];
        }
    }
    return filteredEntries;
}

#pragma mark -
#pragma mark Data manipulation

/*! add an object to the datasource
    @param anObject the object to add
*/
- (void)addObject:(id)anObject
{
    [_contents addObject:anObject];
}

/*! remove all objects from datasource
*/
- (void)removeAllObjects
{
    [_contents removeAllObjects];
}


#pragma mark -
#pragma mark Datasource implementation

- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)item
{
    if (_filter)
        return [[self _getEntriesMatching] count];

    if (!item)
        return [[self getRootObjects] count];
    else
        return [[self getChildrenOfObject:item] count];
}

- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)item
{
     if (_filter)
        return NO;

    if (!item)
        return YES;

    return ([[self getChildrenOfObject:item] count] > 0) ? YES : NO;
}

- (id)outlineView:(CPOutlineView)anOutlineView child:(int)index ofItem:(id)item
{
     if (_filter)
        return [[self _getEntriesMatching].sort() objectAtIndex:index];

    if (!item)
        return [[self getRootObjects] objectAtIndex:index];
    else
        return [[self getChildrenOfObject:item] objectAtIndex:index];
}

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
