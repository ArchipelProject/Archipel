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

- (void)populate
{
    var request     = [CPURLRequest requestWithURL:[self URL]];
    var connection  = [CPURLConnection connectionWithRequest:request delegate:self];
    
    [connection start];
}

- (void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    CPLogConsole("RECEIVED DATA: " + data);
}

- (CPString)description
{
    return [self name];
}

@end

@implementation TNVMCast : CPObject
{
    CPString    name            @accessors;
    CPURL       downloadURL     @accessors;
    CPString    comment         @accessors;
}

+ (TNVMCast)VMCastWithName:(CPString)aName downloadURL:(CPURL)anURL comment:(CPString)aComment
{
    var vmcast = [[TNVMCast alloc] init];
    [vmcast setName:aName];
    [vmcast setDownloadURL:anURL];
    [vmcast setComment:aComment];
    
    return vmcast;
}

- (CPString)description
{
    return [self name];
}

@end


@implementation TNVMCastDatasource : CPObject
{
    CPArray _contents;
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
    CPLogConsole("FILTER child number " + index + " of item " + item);
    if (!item)
    {
        return [_contents objectAtIndex:index];
    }
    else
    {
        CPLogConsole("+++++++++++++> " + item);
        return [[item content] objectAtIndex:index];
    }
}

/*! CPOutlineView Delegate
*/
- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    CPLogConsole("FILTER Getting value for item " + item)
    var identifier = [tableColumn identifier];
    
    return [item valueForKey:identifier];
}

@end
