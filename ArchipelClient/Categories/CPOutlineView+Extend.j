/*
 * CPOutlineView+Extend.j
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


/*! @ingroup categories
    add expandAll to CPOutlineView
*/
@implementation CPOutlineView (TNKit)

/*! Expand all items in the view
*/
- (void)expandAll
{
    for (var count = 0; [self itemAtRow:count]; count++)
    {
        var item = [self itemAtRow:count];
        if ([self isExpandable:item])
            [self expandItem:item];
    }
}

/*! Collapse all items in the view
*/
- (void)collapseAll
{
    for (var count = 0; [self itemAtRow:count]; count++)
    {
        var item = [self itemAtRow:count];
        if ([self isExpandable:item])
            [self collapseItem:item];
    }
}

/*! allow to remember which items has been expanded over reloads
    @param aBaseKey the prefix of the key
    @param aKeyPath the keypath of item to look for
*/
- (void)recoverExpandedWithBaseKey:(CPString)aBaseKey itemKeyPath:(CPString)aKeyPath
{
    var defaults    = [CPUserDefaults standardUserDefaults];

    for (var count = 0; [self itemAtRow:count]; count++)
    {
        var item = [self itemAtRow:count];

        if ([self isExpandable:item])
        {
            var key =  aBaseKey + [item valueForKey:aKeyPath];

            if (([[defaults objectForKey:@"TNOutlineViewsExpandedGroups"] objectForKey:key] == @"expanded")
                || ([[defaults objectForKey:@"TNOutlineViewsExpandedGroups"] objectForKey:key] == nil))
                [self expandItem:item];
        }
    }
}

@end
