/*  
 * TNCellLogLevel.j
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


@implementation TNCellLogLevel: CPView
{
    CPTextField _fieldLevel;
}

- (void)init
{
    if (self = [super init])
    {
        _fieldLevel = [[CPTextField alloc] initWithFrame:CGRectMake(0, 2, 170, 100)];
        [_fieldLevel setFont:[CPFont boldSystemFontOfSize:12]];
    
        [_fieldLevel setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelected];
        
        
        [self addSubview:_fieldLevel];
    }
    return self;
}

- (void)setObjectValue:(id)aLevel
{
    var aColor;
    
    if (aLevel == @"trace")
        aColor = [CPColor blueColor];
    else if (aLevel == @"debug")
        aColor = [CPColor grayColor];
    else if (aLevel == @"warn")
        aColor = [CPColor orangeColor];
    else if (aLevel == @"info")
        aColor = [CPColor colorWithHexString:@"5a8b35"];
    else if (aLevel == @"error")
        aColor = [CPColor redColor];
    else if (aLevel == @"fatal")
        aColor = [CPColor redColor];
    
    [_fieldLevel setValue:aColor forThemeAttribute:@"text-color" inState:CPThemeStateNormal];

    [_fieldLevel setStringValue:aLevel];
}

/*! implement theming in order to allow change color of selected item
*/
- (void)setThemeState:(id)aState
{
    [super setThemeState:aState];
    [_fieldLevel setThemeState:aState];
}

/*! implement theming in order to allow change color of selected item
*/
- (void)unsetThemeState:(id)aState
{
    [super unsetThemeState:aState];
    [_fieldLevel unsetThemeState:aState];
}

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _fieldLevel = [aCoder decodeObjectForKey:@"_fieldLevel"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_fieldLevel forKey:@"_fieldLevel"];
}


@end