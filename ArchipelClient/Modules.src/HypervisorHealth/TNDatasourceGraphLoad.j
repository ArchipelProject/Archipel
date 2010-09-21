/*
 * temp_graphDatasource.j
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

@implementation TNDatasourceGraphLoad : CPObject
{
    CPArray     _datas;
    CPArray     _datasOne;
    CPArray     _datasFive;
    CPArray     _datasFifteen;
    int         _maxNumberOfPoints;
}

- (void)init
{
    if (self = [super init])
    {
        _datasOne = [];
        _datasFive = [];
        _datasFifteen = [];
        
        _datas = [_datasOne, _datasFive, _datasFifteen];
        _maxNumberOfPoints = 100;
    }
    return self;
}

- (CPNumber)numberOfSetsInChart:(LPChartView)aCharView
{
    return [_datas count];
}

- (CPNumber)chart:(LPChartView)aChartView numberOfValuesInSet:(CPNumber)setIndex
{
    return [[_datas objectAtIndex:setIndex] count];
}

- (id)chart:(LPChartView)aChartView valueForIndex:(CPNumber)itemIndex set:(CPNumber)setIndex
{
    if (itemIndex > ([[_datas objectAtIndex:setIndex] count] - 1))
        return 0;

    return [[_datas objectAtIndex:setIndex] objectAtIndex:itemIndex];
}

- (CPString)chart:(LPChartView)aChartView labelValueForIndex:(int)anIndex
{
    return @"";
}

- (void)pushData:(id)data inSet:(CPNumber)setIndex
{
    if ([[_datas objectAtIndex:setIndex] count] >= _maxNumberOfPoints)
        [[_datas objectAtIndex:setIndex] removeObjectAtIndex:0];

    [_datas objectAtIndex:setIndex].push(parseInt(data));
}

- (void)removeAllObjects
{
    _datas = [];
}

@end



@implementation TNChartDrawView : LPChartDrawView
{
}

- (void)drawSetWithFrames:(CPArray)aFramesSet inContext:(CGContext)context
{
    // Overwrite this method in your subclass
    // to get complete control of the drawing.
    
    var colors = [[CPColor colorWithHexString:@"4379ca"], [CPColor colorWithHexString:@"E29A3E"], [CPColor colorWithHexString:@"ABC93F"]]
    
    CGContextSetLineWidth(context, 1.0);
    
    for (var setIndex = 0; setIndex < aFramesSet.length; setIndex++)
    {
        CGContextSetStrokeColor(context, colors[setIndex]);
        
        var items = aFramesSet[setIndex];
        
        // Start path
        CGContextBeginPath(context);
        
        for (var itemIndex = 0; itemIndex < items.length; itemIndex++)
        {
            var itemFrame = items[itemIndex],
                point = CGPointMake(CGRectGetMidX(itemFrame), CGRectGetMinY(itemFrame));
            
            // Begin path
            if (itemIndex == 0)
                CGContextMoveToPoint(context, point.x, point.y);
            
            // Add point
            else
                CGContextAddLineToPoint(context, point.x, point.y);
        }
        
        // Stroke path
        CGContextStrokePath(context);
        
        // Close path
        CGContextClosePath(context);
    }
}

@end
