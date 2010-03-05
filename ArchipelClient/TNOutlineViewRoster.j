/*  
 * TNOutlineViewRoster.j
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
@import <AppKit/CPOutlineView.j>

@import "TNOutlineTableColumn.j"
@import "TNWindowRosterEdition.j"


@implementation TNOutlineViewRoster: CPOutlineView 
{
}


- (id)initWithFrame:(CPRect)aFrame 
{
    if (self = [super initWithFrame:aFrame])
    {
     	[self setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    	[self setFrameOrigin:CGPointMake(5, 5)];
    	
    	[self setRowHeight:20];
    	[self setHeaderView:nil];
    	[self setCornerView:nil];
    	[self setIndentationPerLevel:10];
        [self setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
        
        var columnLabel = [[TNOutlineTableColumnLabel alloc] initWithIdentifier:"nickname" outlineView:self];
        //[columnLabel setResizingMask:CPTableColumnAutoresizingMask];
        [self addTableColumn:columnLabel];  
        
    	[self setOutlineTableColumn:columnLabel];
        
    	var center = [CPNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(populateOutlineViewFromRoster:) name:TNStropheRosterRetrievedNotification object:nil];   
    }
    
	return self;
}

- (void)expandAll 
{
    var count;
    
    for (count = 0; [self itemAtRow:count]; count++) 
    {
        var item = [self itemAtRow:count];
        if ([self isExpandable:item]) 
        {
            [self expandItem:item];
        }
    }
}


- (void)populateOutlineViewFromRoster:(CPNotification)aNotification 
{
    var roster = [aNotification object];
    
    [self setDataSource:roster];
    [roster setOutlineView:self];
    [self expandAll];
}

@end