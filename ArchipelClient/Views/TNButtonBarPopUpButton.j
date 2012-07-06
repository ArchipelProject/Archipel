/*
 * TNButtonBarPopUpButton.j
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

@import <AppKit/CPButton.j>


/*! @ingroup archipelcore
    Allow to perform a right click on left click
*/
@implementation TNButtonBarPopUpButton: CPButton

- (void)mouseDown:(CPEvent)anEvent
{
    var wp = CPPointMake(16, 12);

    wp = [self convertPoint:wp toView:nil];

    var fake = [CPEvent mouseEventWithType:CPRightMouseDown
                        location:wp
                        modifierFlags:0 timestamp:[anEvent timestamp]
                        windowNumber:[anEvent windowNumber]
                        context:nil
                        eventNumber:0
                        clickCount:1
                        pressure:1];
    [CPMenu popUpContextMenu:[self menu] withEvent:fake forView:self];
}

@end
