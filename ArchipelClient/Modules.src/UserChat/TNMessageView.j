/*
 * TNMessageView.j
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

/*! @ingroup userchat
    subclass of CPView representing the collection view prototype
*/
@implementation TNMessageView : CPView
{
    CPTextField _fieldSenderName;
    CPTextField _fieldMessage;
}

/*! CPCollectionView protocol impl.
*/
- (void)setRepresentedObject:(id)anObject
{

    if (! _fieldSenderName)
    {
        [self setBorderedWithHexColor:@"AAAAAA"];
        var frame = [self bounds];

        _fieldSenderName = [[CPTextField alloc] initWithFrame:CGRectMake(10,0, 300, 50)];
        [_fieldSenderName setFont:[CPFont boldSystemFontOfSize:12]];
        [_fieldSenderName setTextColor:[CPColor grayColor]];
        [self addSubview:_fieldSenderName];

        _fieldMessage = [[CPTextField alloc] initWithFrame:CGRectMake(10,20, CGRectGetWidth(frame) - 10, 50)];
        [_fieldMessage setAutoresizingMask:CPViewWidthSizable];
        [_fieldMessage setLineBreakMode:CPLineBreakByWordWrapping];
        [self addSubview:_fieldMessage];
    }
    var name    = [anObject valueForKey:@"name"];
    var message = [anObject valueForKey:@"message"];
    var color   = [anObject valueForKey:@"color"];

    [_fieldSenderName setStringValue:name + " : "];
    [_fieldMessage setStringValue:message];
    [self setBackgroundColor:[CPColor colorWithHexString:color]]
}

/*! CPCollectionView protocol impl.
*/
- (void)setSelected:(BOOL)isSelected
{
    [self setBackgroundColor:isSelected ? [CPColor colorWithHexString:@"f6f9fc"] : nil];
}

@end
