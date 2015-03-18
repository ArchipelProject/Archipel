/*
 * TNBasicDataView.j
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
@import <AppKit/CPView.j>
@import <AppKit/CGGradient.j>


@implementation TNBasicDataView : CPView
{
    CPDictionary _colorRegistry;
}

- (id)initWithFrame:(CGRect)aRect
{
    if (self = [super initWithFrame:aRect])
    {
        [self _init]
    }

    return self;
}

- (void)_init
{
    _colorRegistry = [CPDictionary dictionary];
}

- (BOOL)setThemeState:(ThemeState)aThemeState
{
    if ([self hasThemeState:aThemeState])
        return;

    [super setThemeState:aThemeState];

    if (aThemeState == CPThemeStateSelectedDataView)
    {
        for (var i = 0; i < [[self subviews] count]; i++)
        {
            var view = [[self subviews] objectAtIndex:i];
            if ([view isKindOfClass:CPTextField] && ![view isBezeled])
            {
                [_colorRegistry setObject:[view textColor] forKey:view];
                [view setTextColor:[CPColor whiteColor]];
            }

            [view setThemeState:aThemeState];
        }
    }
}

- (BOOL)unsetThemeState:(ThemeState)aThemeState
{
    if (![self hasThemeState:aThemeState])
        return;

    [super unsetThemeState:aThemeState];

    if (aThemeState == CPThemeStateSelectedDataView)
    {
        for (var i = 0; i < [[self subviews] count]; i++)
        {
            var view = [[self subviews] objectAtIndex:i];
            if ([view isKindOfClass:CPTextField] && ![view isBezeled])
                [view setTextColor:[_colorRegistry objectForKey:view]];

            [view unsetThemeState:aThemeState];
        }
        [self applyShadow];
    }
}



/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _init];
        [self applyShadow];
    }

    return self;
}

@end
