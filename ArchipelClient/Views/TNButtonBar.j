/*
 * TNButtonBar.j
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
@import <AppKit/CPButtonBar.j>


@implementation TNButtonBar : CPButtonBar

- (void)awakeFromCib
{
    [super awakeFromCib];
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
        [self _applyTheme];

    return self;
}

- (void)_applyTheme
{
    [self setValue:[CPColor whiteColor] forThemeAttribute:"bezel-color"];
    [self setValue:[CPColor whiteColor] forThemeAttribute:"button-bezel-color"];
    [self setValue:[CPColor colorWithHexString:@"D9D9D9"] forThemeAttribute:"button-bezel-color" inState:CPThemeStateHighlighted];
    self._DOMElement.style.borderTop = "1px solid #f2f2f2";
}

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        [self _applyTheme];
    }

    return self;
}

@end
