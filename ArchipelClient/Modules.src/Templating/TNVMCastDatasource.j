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

@implementation TNVMCastSource : CPObject
{
    CPString    name            @accessors;
    CPURL       URL             @accessors;
    CPString    comment         @accessors;
    CPArray     content         @accessors;
}

+ (TNVMCastSource)VMCastSourceWithName:(CPString)aName URL:(CPURL)anURL comment:(CPString)aComment
{
    var source = [[TNVMCastSource alloc] init];
    [source setName:aName];
    [source setURL:anURL];
    [source setComment:aComment];
    
    return source;
}

- (id)init
{
    if (self = [super init])
    {
        content = [CPArray array];
    }
    
    return self;
}

- (id)valueForUndefinedKey:(CPString)aKey
{
    return @"Not Applicable";
}

- (CPString)description
{
    return [self name];
}

@end

@implementation TNVMCast : CPObject
{
    CPString    name            @accessors;
    CPURL       URL             @accessors;
    CPString    comment         @accessors;
    CPString    size            @accessors;
    CPString    pubDate         @accessors;
    CPString    UUID            @accessors;
}

+ (TNVMCast)VMCastWithName:(CPString)aName URL:(CPURL)anURL comment:(CPString)aComment size:(CPString)aSize pubDate:(CPString)aDate UUID:(CPString)anUUID
{
    var vmcast = [[TNVMCast alloc] init];
    [vmcast setName:aName];
    [vmcast setURL:anURL];
    [vmcast setComment:aComment];
    [vmcast setSize:aSize];
    [vmcast setUUID:anUUID];
    [vmcast setPubDate:aDate];
    
    return vmcast;
}

- (CPString)description
{
    return [self name];
}

@end


@implementation TNVMCastDatasource : CPObject
{
    CPArray _contents @accessors(getter=contents);
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

/*! CPOutlineView Delegate
*/
- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)item
{
    CPLogConsole("FILTER get number of child for item " + item);
    if (!item)
    {
	    return [_contents count];
	}
	else
	{
	    CPLogConsole(" FILTER answer is " + [[item content] count])
        return [[item content] count];
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
        return [[item content] objectAtIndex:index];
    }
}

/*! CPOutlineView Delegate
*/
- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    var identifier = [tableColumn identifier];
    
    return [item valueForKey:identifier];
}

@end
