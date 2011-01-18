/*
 * TNEditableLabel.j
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

@import <AppKit/CPTextField.j>


/*! @ingroup archipelcore
    A Label that is editable on click
*/
@implementation TNEditableLabel: CPTextField
{
    CPColor     _oldColor;
    id          _previousResponder  @accessors(property=previousResponder);
}

- (void)mouseDown:(CPEvent)anEvent
{
    [self setEditable:YES];
    [self selectAll:nil];

    [super mouseDown:anEvent];
}

- (void)textDidFocus:(CPNotification)aNotification
{
    [super textDidFocus:aNotification];
    [self setTextColor:[CPColor whiteColor]];
}

- (void)textDidBlur:(CPNotification)aNotification
{
    [super textDidBlur:aNotification];
    [self setEditable:NO];
    [self setSelectedRange:CPMakeRange(0, 0)];
    [self setTextColor:[CPColor colorWithHexString:@"515151"]];
}

@end
