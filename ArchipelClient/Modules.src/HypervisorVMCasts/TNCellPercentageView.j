/*
 * TNCellPercentageView.j
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


@implementation TNCellPercentageView : CPView
{
    CPProgressIndicator     _progressBar;
}

#pragma mark -
#pragma mark Initialization

/*! initialize the view
*/
- (id)init
{
    if (self = [super init])
    {
        _progressBar = [[CPProgressIndicator alloc] initWithFrame:CPRectMake(0.0, 0.0, 0.0, 16.0)];
        [_progressBar setAutoresizingMask:CPViewWidthSizable];
        [_progressBar setMaxValue:100];
        [_progressBar setMinValue:0];

        [self addSubview:_progressBar];
    }

    return self;
}

/*! set the object value of the cell
    @params aValue the current value
*/
- (void)setObjectValue:(float)aValue
{
    [_progressBar setDoubleValue:aValue];
}

#pragma mark -
#pragma mark CPCoding compliance

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _progressBar = [aCoder decodeObjectForKey:@"_progressBar"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_progressBar forKey:@"_progressBar"];
}

@end