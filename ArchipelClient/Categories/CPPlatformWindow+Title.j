/*
 * CPPlatformWindow+Title.j
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

@import <AppKit/AppKit.j>


/*! @ingroup categories
    Category that enable the set the title of a physical window
*/
@implementation CPPlatformWindow (title)

- (void)setTitle:(CPString)aTitle
{
    _DOMWindow.document.title = aTitle;
}

- (id)DOMWindow
{
    return _DOMWindow;
}

@end