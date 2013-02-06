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

@import <AppKit/CPOutlineView.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPTextField.j>

@import <StropheCappuccino/TNStropheContact.j>

@import "../Model/TNDatasourceRoster.j"

@global TNArchipelRememberOpenedGroup


TNArchipelRosterOutlineViewReload                   = @"TNArchipelRosterOutlineViewReload";
TNArchipelPropertiesViewDidShowNotification         = @"TNArchipelPropertiesViewDidShowNotification";
TNArchipelRosterOutlineViewDeselectAll              = @"TNArchipelRosterOutlineDeselectAll";
TNArchipelRosterOutlineViewSelectItemNotification   = @"TNArchipelRosterOutlineViewSelectItemNotification";

/*! @ingroup archipelcore
    Subclass of TNOutlineView. This will display the roster according to the TNDatasourceRoster given as datasource.
*/
@implementation TNOutlineViewRoster: CPOutlineView
{
    CPSearchField   _searchField        @accessors(property=searchField);
    CPTabView       _tabViewModules     @accessors(property=modulesTabView);
    CPTextField     _entityRenameField  @accessors(property=entityRenameField);
}

#pragma mark -
#pragma mark Initialization

/*! init the class
    @param aFrame CGRect the frame of the view
*/
- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        var columnLabel     = [[CPTableColumn alloc] initWithIdentifier:"nickname"],
            columnOutline   = [[CPTableColumn alloc] initWithIdentifier:"outline"],
            rosterLayout    = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelRosterLayout"];

        [columnLabel setWidth:aFrame.size.width];
        [columnOutline setWidth:12.0];

        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:TNArchipelRosterOutlineViewReload object:nil];
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(deselectAll:) name:TNArchipelRosterOutlineViewDeselectAll object:nil];
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didPropertiesViewUpdate:) name:TNArchipelPropertiesViewDidShowNotification object:nil];
        [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveSelectItemNotification:) name:TNArchipelRosterOutlineViewSelectItemNotification object:nil];

        [self setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
        [self setHeaderView:nil];
        [self setCornerView:nil];
        [self setBackgroundColor:nil];
        [self setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
        [self addTableColumn:columnLabel];
        [self setOutlineTableColumn:columnLabel];
        [self setTarget:self];
        [self setAllowsMultipleSelection:YES];
    }

    return self;
}


#pragma mark -
#pragma mark Notification handlers

/*! called when TNArchipelRosterOutlineViewReload is received.
    It will reload the data
    @param aNotification the notification
*/
- (void)reload:(CPNotification)aNotification
{
    var index = [[self selectedRowIndexes] firstIndex],
        item  = [self itemAtRow:index];

    [self reloadData];

    if ((item) && ([self rowForItem:item] != -1))
    {
        var index = [self rowForItem:item];
        [self selectRowIndexes:[CPIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    }
    else
    {
        if ([self numberOfSelectedRows] > 0)
            [self deselectAll];
    }

    [self recoverExpandedWithBaseKey:TNArchipelRememberOpenedGroup itemKeyPath:@"name"];
    [self getVCardsForVisibleEntitiesIfNeeded];
}

/*! called when TNArchipelRosterOutlineViewDeselectAll is received.
    It will deselect all
    @param aNotification the notification
*/
- (void)deselectAll:(CPNotification)aNotification
{
    [self deselectAll];
}

/*! called when TNArchipelPropertiesViewDidShowNotification is received.
    It will scroll to make selected row visible
    @param aNotification the notification
*/
- (void)didPropertiesViewUpdate:(CPNotification)aNotification
{
    var selectedIndex = [[self selectedRowIndexes] firstIndex];

    [self scrollRowToVisible:selectedIndex];
}

/*! called when TNArchipelRosterOutlineViewSelectItemNotification is received.
    It will select the item if present
    @param aNotification the notification
*/
- (void)didReceiveSelectItemNotification:(CPNotification)aNotification
{
    if (![aNotification userInfo])
    {
        CPLog.warning("received notification to select an item, but no item is provided.")
        return;
    }

    var rowIndex = [self rowForItem:[aNotification userInfo]];
    if (rowIndex !== CPNotFound)
        [[_searchField cancelButton] performClick:self];
        [self reloadData];
        [self selectRowIndexes:[CPIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
}

#pragma mark -
#pragma mark Utilities

- (void)getVCardsForVisibleEntitiesIfNeeded
{
    var visibleRange = [self rowsInRect:[self visibleRect]];

    for (var i = visibleRange.location; i < (visibleRange.location + visibleRange.length); i++)
    {
        var item = [self itemAtRow:i];
        if ([item isKindOfClass:TNStropheContact] && ![item vCard])
            [item getVCard];
    }
}

#pragma mark -
#pragma mark Overrides

- (void)moveLeft
{
    var index = [self selectedRowIndexes];

    if ([index firstIndex] == -1)
        return;

    var item = [self itemAtRow:[index firstIndex]];

    if ([self isExpandable:item])
        [self collapseItem:item];
    else
    {
        var selectedIndex   = [_tabViewModules indexOfTabViewItem:[_tabViewModules selectedTabViewItem]],
            numberOfItems   = [_tabViewModules numberOfTabViewItems];

        if (selectedIndex > 0)
            [_tabViewModules selectPreviousTabViewItem:nil];
        else if (numberOfItems > 1) // avoid looping if there is one item
            [_tabViewModules selectLastTabViewItem:nil];
    }
}

- (void)moveRight
{
    var index = [self selectedRowIndexes];

    if ([index firstIndex] == -1)
        return;

    var item = [self itemAtRow:[index firstIndex]];

    if ([self isExpandable:item])
        [self expandItem:item];
    else
    {
        var selectedIndex   = [_tabViewModules indexOfTabViewItem:[_tabViewModules selectedTabViewItem]],
            numberOfItems   = [_tabViewModules numberOfTabViewItems];

        if (selectedIndex < numberOfItems - 1)
            [_tabViewModules selectNextTabViewItem:nil];
        else if (numberOfItems > 1) // avoid looping if there is one item
            [_tabViewModules selectFirstTabViewItem:nil];
    }
}

- (void)moveDown
{
    var index = [[self selectedRowIndexes] firstIndex];


    if (index == [self numberOfRows] - 1)
    {
        [[self window] makeFirstResponder:_searchField];
        [self deselectAll];
    }
    else
    {
        [self selectRowIndexes:[CPIndexSet indexSetWithIndex:(index + 1)] byExtendingSelection:NO];
    }
}

- (void)moveUp
{
    var index = [[self selectedRowIndexes] firstIndex];

    if (index == 0)
    {
        [[self window] makeFirstResponder:_searchField];
        [self deselectAll];
    }
    else
    {
        [self selectRowIndexes:[CPIndexSet indexSetWithIndex:(index - 1)] byExtendingSelection:NO];
    }
}

- (void)keyDown:(CPEvent)anEvent
{
    switch ([anEvent keyCode])
    {
        case CPEscapeKeyCode:
            [[_searchField cancelButton] performClick:self];
            break;

        case CPReturnKeyCode:
            if ([_entityRenameField isEnabled])
            {
                [_entityRenameField setPreviousResponder:self];
                [_entityRenameField mouseDown:nil];
                [_entityRenameField _inputElement].focus();
                [[self window] makeFirstResponder:_entityRenameField];
            }
            break;

        case CPDownArrowKeyCode:
            [self moveDown];
            break;

        case CPUpArrowKeyCode:
            [self moveUp];
            break;

        case CPLeftArrowKeyCode:
            [self moveLeft];
            break;

        case CPRightArrowKeyCode:
            [self moveRight];
            break;

        default:
            [super keyDown:anEvent];
    }
}

#pragma mark -
#pragma mark Scroll View delegates

- (void)scrollViewDidScroll:(CPScrollView)aView
{
    [self getVCardsForVisibleEntitiesIfNeeded];
}

@end
