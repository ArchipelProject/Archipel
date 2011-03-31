/*
 * TNSearchField.j
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
@import <AppKit/CPSearchField.j>


/*! @ingroup archipelcore
    CPSearchField with shortcuts
*/
@implementation TNSearchField : CPSearchField
{
    CPOutlineView   _outlineView @accessors(property=outlineView);
}

- (void)keyDown:(CPEvent)anEvent
{
    switch ([anEvent keyCode])
    {
        case CPDownArrowKeyCode:
            [_outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
            [[_outlineView window] makeFirstResponder:_outlineView];
            break;

        case CPUpArrowKeyCode:
            [_outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:([_outlineView numberOfRows] - 1)] byExtendingSelection:NO];
            [[_outlineView window] makeFirstResponder:_outlineView];
            break;

        case CPReturnKeyCode:
            [_outlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
            [[_outlineView window] makeFirstResponder:_outlineView];
            break;

        case CPEscapeKeyCode:
            [[self cancelButton] performClick:nil];
            break;

        default:
            [super keyDown:anEvent];
    }
}

@end