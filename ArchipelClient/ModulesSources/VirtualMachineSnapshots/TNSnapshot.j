/*
 * TNSnapshot.j
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
@import <AppKit/CPImage.j>

/*! @ingroup virtualmachinedrives
    this class represent a snapshot
*/
@implementation TNSnapshot : CPObject
{
    BOOL        _isCurrent      @accessors(getter=isCurrent, setter=setCurrent:);
    CPString    _creationTime   @accessors(property=creationTime);
    CPString    _description    @accessors(property=description);
    CPString    _domain         @accessors(property=domain);
    CPString    _name           @accessors(property=name);
    CPString    _parent         @accessors(property=parent);
    CPString    _state          @accessors(property=state);
    CPString    _UUID           @accessors(property=UUID);

    CPImage     _currentIcon;
}


#pragma mark -
#pragma mark Initialization

/*! initialize the TNSnapshot
*/
- (id)init
{
    if (self = [super init])
    {
        _currentIcon    = CPImageInBundle(@"IconsButtons/check.png", CGSizeMake(16, 16), [CPBundle mainBundle]);
    }

    return self;
}


#pragma mark -
#pragma mark Accessors

- (BOOL)isCurrent
{
    if (_isCurrent)
        return _currentIcon;
    return nil;
}

@end
