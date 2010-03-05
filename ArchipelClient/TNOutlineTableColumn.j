/*  
 * TNOutlineTableColumn.j
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


@implementation TNViewOutlineViewContact : CPView
{
    CPImageView statusIcon  @accessors;
    CPTextField events      @accessors;
    CPTextField name        @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        statusIcon  = [[CPImageView alloc] initWithFrame:CGRectMake(0, 0, 16, 16)];
        name        = [[CPTextField alloc] initWithFrame:CGRectMake(15, 0, 170, 100)];
        events      = [[CPTextField alloc] initWithFrame:CGRectMake(148, 0, 23, 14)];
        
        [self setAutoresizingMask: CPViewWidthSizable];
        [self addSubview:statusIcon];
        [self addSubview:name];
        [self addSubview:events];
        
        var bundle = [CPBundle mainBundle];
        [events setBackgroundColor:[CPColor colorWithPatternImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"cartouche.png"]]]]
        [events setAlignment:CPCenterTextAlignment];
        [events setVerticalAlignment:CPCenterVerticalTextAlignment];
        [events setFont:[CPFont boldSystemFontOfSize:11]];
        [events setTextColor:[CPColor whiteColor]];
        
        [[self events] setHidden:NO];
    }
    return self;
}

- (void)setObjectValue:(id)aContact
{
    [name setAutoresizingMask:CPViewWidthSizable];
    [events setAutoresizingMask:CPViewMinXMargin | CPViewMaxYMargin];
    
    [[self name] setStringValue:[aContact nickname]];
    [[self statusIcon] setImage:[aContact statusIcon]];

    if ([aContact numberOfEvents] > 0)
    {
        [[self events] setHidden:NO];
        [[self events] setStringValue:[aContact numberOfEvents]];
    }
    else
    {
        [[self events] setHidden:YES];
    }
        
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];
    
    if (self)
    {
        [self setName:[aCoder decodeObjectForKey:@"name"]];
        [self setStatusIcon:[aCoder decodeObjectForKey:@"statusIcon"]];
        [self setEvents:[aCoder decodeObjectForKey:@"events"]];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:name forKey:@"name"];
    [aCoder encodeObject:statusIcon forKey:@"statusIcon"];
    [aCoder encodeObject:events forKey:@"events"];
}

@end

@implementation TNOutlineTableColumnLabel  : CPTableColumn 
{
    CPOutlineView       _outlineView;
    CPView              _dataViewForOther;
    CPView              _dataViewForRoot;
}

- (id)initWithIdentifier:(CPString)anIdentifier outlineView:(CPOutlineView)anOutlineView 
{
    if (self = [super initWithIdentifier:anIdentifier])
    {
        _outlineView = anOutlineView;

    	[self setWidth:200];
        _dataViewForRoot = [[CPTextField alloc] init];
    	[_dataViewForRoot setFont:[CPFont boldSystemFontOfSize:12]];
    	[_dataViewForRoot setTextColor:[CPColor colorWithHexString:@"5F676F"]];
        [_dataViewForRoot setAutoresizingMask: CPViewWidthSizable];
    
    	_dataViewForOther = [[TNViewOutlineViewContact alloc] init];
    }
	
    return self;
}

- (id)dataViewForRow:(int)aRowIndex 
{
    var outlineViewItem = [_outlineView itemAtRow:aRowIndex];
    var itemLevel       = [_outlineView levelForItem:outlineViewItem];
    
    if (itemLevel == 0)
    {
        return _dataViewForRoot;
    }
    else
    {
        return _dataViewForOther;
    }
        
}
@end