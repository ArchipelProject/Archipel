/*
 * TNDatasourceDisks.j
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

@implementation TNDatasourceGraphDisks : CPObject
{
    CPArray     _datas;
}

- (void)init
{
    if (self = [super init])
    {
        _datas = [];
    }
    return self;
}


- (int)numberOfItemsInPieChartView:(LPPieChartView)aPieChartView
{
    return [_datas count];
}

- (int)pieChartView:(LPPieChartView)aPieChartView floatValueForIndex:(int)anIndex
{
    return _datas[anIndex];
}

- (void)pushData:(id)aData
{
    [_datas addObject:aData];
}

- (void)removeAllObjects
{
    [_datas removeAllObjects];
}

@end




@implementation TNPieChartDrawView : LPPieChartDrawView

- (void)drawInContext:(CGContext)context paths:(CPArray)paths
{
    /*
        Overwrite this method in your subclass.
    */
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColor(context, [CPColor whiteColor]);
    
    var fillColors = [[CPColor colorWithHexString:@"E29A3E"], [CPColor colorWithHexString:@"75B886"]];
    
    for (var i = 0; i < paths.length; i++)
    {
        CGContextBeginPath(context);
        CGContextAddPath(context, paths[i]);
        CGContextClosePath(context);

        CGContextSetFillColor(context, fillColors[i]);

        CGContextFillPath(context);
        CGContextStrokePath(context);
    }
}

@end