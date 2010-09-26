/*
 * TNDatasourcePieChartView.j
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

@implementation TNDatasourcePieChartView : CPObject
{
    CPArray     _datas;
}

- (void)init
{
    if (self = [super init])
    {
        _datas = [CPArray array];
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
    CGContextSetLineWidth(context, 1.3);
    CGContextSetStrokeColor(context, [CPColor whiteColor]);
    
    //var fillColors = [[CPColor colorWithHexString:@"E29A3E"], [CPColor colorWithHexString:@"75B886"]];
    var fillColors = [
                        [CPColor colorWithHexString:@"4379ca"],
                        [CPColor colorWithHexString:@"7fca43"],
                        [CPColor colorWithHexString:@"ca4343"],
                        [CPColor colorWithHexString:@"dcd639"],
                        [CPColor colorWithHexString:@"ca9f43"],
                        [CPColor colorWithHexString:@"af43ca"],
                        [CPColor colorWithHexString:@"43afca"]
                    ];
    
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