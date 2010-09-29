/*
 * TNVMCastDatasource.j
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

TNArchipelApplianceInstalled            = 1;
TNArchipelApplianceInstalling           = 2;
TNArchipelApplianceNotInstalled         = 3;
TNArchipelApplianceInstallationError    = 4;

TNArchipelApplianceStatusString          = [@"", @"Installed", @"Installing", @"Not installed", @"Installation error"];

@implementation TNVMCastSource : CPObject
{
    CPArray     _content         @accessors(property=content);
    CPString    _comment         @accessors(property=comment);
    CPString    _name            @accessors(property=name);
    CPString    _UUID            @accessors(property=UUID);
    CPURL       _URL             @accessors(property=URL);
}

+ (TNVMCastSource)VMCastSourceWithName:(CPString)aName UUID:(CPString)anUUID URL:(CPURL)anURL comment:(CPString)aComment
{
    var source = [[TNVMCastSource alloc] init];
    [source setName:aName];
    [source setURL:anURL];
    [source setUUID:anUUID];
    [source setComment:aComment];

    return source;
}

- (id)init
{
    if (self = [super init])
    {
        _content = [CPArray array];
    }

    return self;
}

- (id)valueForUndefinedKey:(CPString)aKey
{
    return @"";
}

- (CPString)description
{
    return _name;
}

@end

@implementation TNVMCast : CPObject
{
    CPString    _comment         @accessors(property=comment);
    CPString    _name            @accessors(property=name);
    CPString    _pubDate         @accessors(property=pubDate);
    CPString    _size            @accessors(property=size);
    CPString    _UUID            @accessors(property=UUID);
    CPURL       _URL             @accessors(property=URL);
    int         _status          @accessors(property=status);

}

+ (TNVMCast)VMCastWithName:(CPString)aName URL:(CPURL)anURL comment:(CPString)aComment size:(CPString)aSize pubDate:(CPString)aDate UUID:(CPString)anUUID status:(int)aStatus
{
    var vmcast = [[TNVMCast alloc] init];
    [vmcast setName:aName];
    [vmcast setURL:anURL];
    [vmcast setComment:aComment];
    [vmcast setSize:aSize];
    [vmcast setUUID:anUUID];
    [vmcast setPubDate:aDate];
    [vmcast setStatus:aStatus];

    return vmcast;
}

- (CPString)description
{
    return _name;
}

- (CPString)size
{
    return @"" + Math.round(parseInt(_size) / 1024 / 1024) + @" Mo";
}
@end


@implementation TNVMCastDatasource : CPObject
{
    BOOL        _filterInstalled    @accessors(setter=setFilterInstalled:, getter=isFilterInstalled);
    CPArray     _contents           @accessors(property=contents);
    CPString    _filter             @accessors(property=filter);
}

/*! Initialization of the class
    @return an initialized instance of TNVMCastDatasource
*/
- (id)init
{
    if (self = [super init])
    {
        _contents           = [CPArray array];
        _filterInstalled    = NO;
    }

    return self;
}

- (void)addSource:(TNVMCastSource)aSource
{
    [_contents addObject:aSource];
}

- (void)addVMCast:(TNVMCast)aVMCast toSourceAtIndex:(int)anIndex
{
    var source  = [self sourceAtIndex:anIndex];
    [[source content] addObject:aVMCast];
}

- (TNVMCastSource)sourceAtIndex:(int)anIndex
{
    return [_contents objectAtIndex:anIndex];
}

- (CPArray)filterOnlyInstalled:(CPArray)anArray
{
    if (_filterInstalled)
    {
        var array = [CPArray array];
        for (var i = 0; i < [anArray count]; i++)
        {
            if ([[anArray objectAtIndex:i] status] == TNArchipelApplianceInstalled)
                [array addObject:[anArray objectAtIndex:i]];
        }
        return array;
    }
    else
        return anArray;
}

- (CPArray)filterOnlyMatching:(CPArray)anArray
{
    if (_filter && _filter != @"")
    {
        var array = [CPArray array];
        for (var i = 0; i < [anArray count]; i++)
        {
            var object = [anArray objectAtIndex:i];

            if (([[object name] uppercaseString].indexOf([_filter uppercaseString]) != -1)
                || ([[object comment] uppercaseString].indexOf([_filter uppercaseString]) != -1))
                [array addObject:object];
        }
        return array;
    }
    else
        return anArray;
}

- (CPArray)applyFilters:(CPArray)anArray
{
    anArray = [self filterOnlyInstalled:anArray];
    anArray = [self filterOnlyMatching:anArray];

    return anArray;
}

/*! CPOutlineView Delegate
*/
- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        return [_contents count];
    }
    else
    {
        return [[self applyFilters:[item content]] count];
    }
}

/*! CPOutlineView Delegate
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)item
{
    return ([item class] == @"TNVMCastSource") ? YES : NO;
}

/*! CPOutlineView Delegate
*/
- (id)outlineView:(CPOutlineView)anOutlineView child:(int)index ofItem:(id)item
{
    if (!item)
    {
        return [_contents objectAtIndex:index];
    }
    else
    {
        return [[self applyFilters:[item content]] objectAtIndex:index];
    }
}

/*! CPOutlineView Delegate
*/
- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    var identifier = [tableColumn identifier];

    return [item valueForKey:identifier];
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{
    [_contents sortUsingDescriptors:[aTableView sortDescriptors]];

    [aTableView reloadData];
}

@end
