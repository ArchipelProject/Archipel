/*
 * CPProgressIndicator+CPCoding.j
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

@import <AppKit/CPProgressIndicator.j>


/*! @ingroup categories
    Makes CPProgressIndicator CPCoding compliant
*/
@implementation CPProgressIndicator (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _minValue                   = [aCoder decodeObjectForKey:@"_minValue"];
        _maxValue                   = [aCoder decodeObjectForKey:@"_maxValue"];
        _doubleValue                = [aCoder decodeObjectForKey:@"_doubleValue"];
        _controlSize                = [aCoder decodeObjectForKey:@"_controlSize"];
        _isIndeterminate            = [aCoder decodeObjectForKey:@"_isIndeterminate"];
        _style                      = [aCoder decodeObjectForKey:@"_style"];
        _isAnimating                = [aCoder decodeObjectForKey:@"_isAnimating"];
        _isDisplayedWhenStoppedSet  = [aCoder decodeObjectForKey:@"_isDisplayedWhenStoppedSet"];
        _isDisplayedWhenStopped     = [aCoder decodeObjectForKey:@"_isDisplayedWhenStopped"];
        _barView                    = [aCoder decodeObjectForKey:@"_barView"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_minValue forKey:@"_minValue"];
    [aCoder encodeObject:_maxValue forKey:@"_maxValue"];
    [aCoder encodeObject:_doubleValue forKey:@"_doubleValue"];
    [aCoder encodeObject:_controlSize forKey:@"_controlSize"];
    [aCoder encodeObject:_isIndeterminate forKey:@"_isIndeterminate"];
    [aCoder encodeObject:_style forKey:@"_style"];
    [aCoder encodeObject:_isAnimating forKey:@"_isAnimating"];
    [aCoder encodeObject:_isDisplayedWhenStoppedSet forKey:@"_isDisplayedWhenStoppedSet"];
    [aCoder encodeObject:_isDisplayedWhenStopped forKey:@"_isDisplayedWhenStopped"];
    [aCoder encodeObject:_barView forKey:@"_barView"];
}

@end
