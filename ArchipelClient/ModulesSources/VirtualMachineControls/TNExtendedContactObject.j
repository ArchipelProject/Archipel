/*
 * TNExtendedContactObject.j
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


var TNExtendedContactImageSelected;

// TODO: this class is useless

/*! @ingroup virtualmachinecontrols
    represents an contact with a selection
*/
@implementation TNExtendedContact: CPObject
{
    CPString    _nickname   @accessors(property=nickname);
    CPString    _fullJID    @accessors(property=fullJID);
    BOOL        _selected   @accessors(setter=setSelected:);
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    TNExtendedContactImageSelected = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/check.png"] size:CGSizeMake(12, 12)];
}

/*! intialize a TNExtendedContact with given values
    @param aNickname contact nickname
    @param aFullJID the full JID of the contact
    @return initialized contact
*/
- (id)initWithNickName:(CPString)aNickname fullJID:(CPString)aFullJID
{
    if (self = [super init])
    {
        _nickname       = aNickname;
        _fullJID        = aFullJID;
        _selected       = NO;
    }

    return self;
}


#pragma mark -
#pragma mark Accessors

- (CPImage)isSelected
{
    if (_selected)
    {
        return TNExtendedContactImageSelected;
    }
    return nil;
}

@end
