/*  
 * TNAvatarManager.j
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


@implementation TNAvatarManager : CPImageView
{
    CPMenu  avatarMenu @accessors;

    CPPanel avatarPanel @accessors;
}

- (id)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        
        
    }
    
    return self;
}

- (void)awakeFromCib
{
    avatarPanel = [[CPPanel alloc] initWithContentRect:CPRectMake(50, 50, 300, 200) styleMask:CPTitledWindowMask];
}

- (void)mouseDown:(CPEvent)anEvent
{
    // avatarPanel = [[CPPanel alloc] initWithContentRect:CPRectMake(50, 50, 300, 200) styleMask:CPTitledWindowMask];
    [avatarPanel orderFront:nil];
    [super mouseDown:anEvent];
}



/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        avatarMenu  = [aCoder decodeObjectForKey:@"avatarMenu"];
        avatarPanel = [aCoder decodeObjectForKey:@"avatarPanel"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:avatarPanel forKey:@"avatarPanel"];
    [aCoder encodeObject:avatarMenu forKey:@"avatarMenu"];
}

@end