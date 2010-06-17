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

/*! @ingroup archipelcore
    Subclass of TNOutlineView. This will display the roster according to the TNDatasourceRoster given as datasource.
*/
@implementation TNOutlineViewRoster: CPOutlineView
{
    CPSearchField   _searchField        @accessors(property=searchField);
    CPTabView       _tabViewModules     @accessors(property=modulesTabView);
    CPTextField     _entityRenameField  @accessors(property=entityRenameField);
}
/*! init the class
    @param aFrame CPRect the frame of the view
*/
- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        var center      = [CPNotificationCenter defaultCenter];
        var columnLabel = [[TNOutlineTableColumnLabel alloc] initWithIdentifier:"nickname" outlineView:self];

        [center addObserver:self selector:@selector(_populateOutlineViewFromRoster:) name:TNStropheRosterRetrievedNotification object:nil];
        
        [self setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
        [self setHeaderView:nil];
        [self setCornerView:nil];
        [self setBackgroundColor:[CPColor colorWithHexString:@"D8DFE8"]];
        [self setRowHeight:35];
        [self setIndentationPerLevel:13];
        
        [columnLabel setWidth:aFrame.size.width];
        
        [self setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
        
        
        //[columnLabel setResizingMask:CPTableColumnAutoresizingMask];
        
        [self addTableColumn:columnLabel];
        [self setOutlineTableColumn:columnLabel];

        // highlight style
        _sourceListActiveGradient           = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [172.0/255.0, 189.0/255.0, 217.0/255.0,1.0, 128.0/255.0, 151.0/255.0, 189.0/255.0,1.0], [0,1], 2);
        _sourceListActiveTopLineColor       = [CPColor colorWithHexString:@"9eafcd"];
        _sourceListActiveBottomLineColor    = [CPColor colorWithHexString:@"7c95bb"];
        
        [self setTarget:self];
        [self setDoubleAction:@selector(onDoubleAction:)];
    }

	return self;
}

- (IBAction)onDoubleAction:(id)sender
{
    // var frame = [self rectOfRow:[[self selectedRowIndexes] firstIndex]];
    // 
    // var pv = [[TNQuickEditView alloc] initWithObjectFrame:frame size:CGSizeMake(200,200)];
    // [pv orderFront:self];
}

/*! Use to set the datasource. It plugs what needed to be plugged. It will be trigger by
    TNStropheRosterRetrievedNotification notification sent by TNStropheRoster
    @param aNotification CPNotification sent by TNStropheRoster
*/
- (void)_populateOutlineViewFromRoster:(CPNotification)aNotification
{
    var roster = [aNotification object];

    [self setDataSource:roster];
    [roster setMainOutlineView:self];
    [self expandAll];
}



- (void)moveLeft:(id)sender
{
    var index = [self selectedRowIndexes];
    
    if ([index firstIndex] == -1)
        return;
    
    var item = [self itemAtRow:[index firstIndex]];
    
    if ([self isExpandable:item])
        [self collapseItem:item];
    else
    {
        //mouarf... crappy mode on..
        // I should patch capp..
        var selectedIndex   = [_tabViewModules indexOfTabViewItem:[_tabViewModules selectedTabViewItem]];
        var numberOfItems   = [_tabViewModules numberOfTabViewItems];
        
        if (selectedIndex > 0)
            [_tabViewModules selectPreviousTabViewItem:nil];
        else if (numberOfItems > 1) // avoid looping if there is one item
            [_tabViewModules selectLastTabViewItem:nil];
    }
}

- (void)moveRight:(id)sender
{
    var index = [self selectedRowIndexes];
    
    if ([index firstIndex] == -1)
        return;
    
    var item = [self itemAtRow:[index firstIndex]];
    
    if ([self isExpandable:item])
        [self expandItem:item];
    else
    {
        //mouarf... crappy mode on..
        // I should patch capp..
        var selectedIndex   = [_tabViewModules indexOfTabViewItem:[_tabViewModules selectedTabViewItem]];
        var numberOfItems   = [_tabViewModules numberOfTabViewItems];
        
        if (selectedIndex < numberOfItems - 1)
            [_tabViewModules selectNextTabViewItem:nil];
        else if (numberOfItems > 1) // avoid looping if there is one item
            [_tabViewModules selectFirstTabViewItem:nil];
    }
}

- (void)moveDown:(id)sender
{
    var index = [[self selectedRowIndexes] firstIndex];
    
    if (index == [self numberOfRows] - 1)
    {
        [[self window] makeFirstResponder:_searchField];
        [self deselectAll];
    }
    else
        [super moveDown:sender];
}

- (void)moveUp:(id)sender
{
    var index = [[self selectedRowIndexes] firstIndex];
    
    if (index == 0)
    {
        [[self window] makeFirstResponder:_searchField];
        [self deselectAll];
    }
    else
        [super moveUp:sender];
}

- (void)keyDown:(CPEvent)anEvent
{
    if ([anEvent keyCode] == CPDeleteKeyCode)
    {
        var center = [CPNotificationCenter defaultCenter];
        [center postNotificationName:TNArchipelActionRemoveSelectedRosterEntityNotification object:self];
        
        return
    }
    else if ([anEvent keyCode] == CPEscapeKeyCode)
    {
        [_searchField _searchFieldCancel:self];
        
        return
    }
    else if ([anEvent keyCode] == CPReturnKeyCode)
    {
        [_entityRenameField setPreviousResponder:self];
        [_entityRenameField mouseDown:nil];
        [_entityRenameField _inputElement].focus();
        [[self window] makeFirstResponder:_entityRenameField];
        
        return;
    }
    
    [super keyDown:anEvent];
}

@end