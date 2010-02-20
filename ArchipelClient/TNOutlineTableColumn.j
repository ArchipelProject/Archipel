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
@import <AppKit/CPOutlineView.j>


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

        [self setEditable:YES];

        var width = 170;
    	[self setWidth:width];

        _dataViewForRoot = [[CPTextField alloc] init];
    	[_dataViewForRoot setFont:[CPFont boldSystemFontOfSize:12]];
    	[_dataViewForRoot setTextColor:[CPColor colorWithHexString:@"5F676F"]];
        [_dataViewForRoot setAutoresizingMask: CPViewWidthSizable];
    	[_dataViewForRoot setTextShadowColor:[CPColor grayColor]];
    	[_dataViewForRoot setTextShadowOffset:CGSizeMake(0.4, 0.4)];

    	_dataViewForOther = [[CPTextField alloc] init];
    	[_dataViewForOther setAutoresizingMask: CPViewWidthSizable];
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




@implementation TNOutlineTableColumnStatus  : CPTableColumn 
{
    CPOutlineView   _outlineView;
}

- (id)initWithIdentifier:(CPString)anIdentifier outlineView:(CPOutlineView)anOutlineView 
{
    if (self = [super initWithIdentifier:anIdentifier])
    {
        _outlineView = anOutlineView;
        [self setWidth:16];   
    }
    
    return self;
}

- (id)dataViewForRow:(int)aRowIndex 
{
    var outlineViewItem = [_outlineView itemAtRow:aRowIndex];
    var itemLevel       = [_outlineView levelForItem:outlineViewItem];
    
    if (itemLevel == 0)
    {
        return [[CPTextField alloc] initWithFrame:CGRectMake(0,0, 16, 16)];
    }
    else
    {
        var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0, 16, 16)];
        [imageView setAutoresizingMask: CPViewMaxXMargin ];
        [imageView setImage:[[CPImage alloc] initWithContentsOfFile:@"../Resources/StatusIcons/Offline.png" size:CGSizeMake(16, 16)]];
        [imageView setImageScaling:CPScaleProportionally];
        
        return imageView;
    }
}
@end