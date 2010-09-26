/*
 * TNDatasourceGraphChartView.j
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

@implementation TNDatasourceChartView : CPObject
{
    CPArray     _datas;
    int         _maxNumberOfPoints;
}

- (void)initWithNumberOfSets:(int)numberOfSets
{
    if (self = [super init])
    {
        _datas = [CPArray array];
        
        for (var i = 0 ; i < numberOfSets; i++)
            [_datas addObject:[CPArray array]];
        
        _maxNumberOfPoints = 100;
    }
    return self;
}

- (void)init
{
    return [self initWithSets:1];
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
    
    var fillColors = [
                        [CPColor colorWithHexString:@"4379ca"],
                        [CPColor colorWithHexString:@"7fca43"],
                        [CPColor colorWithHexString:@"ca4343"],
                        [CPColor colorWithHexString:@"dcd639"],
                        [CPColor colorWithHexString:@"ca9f43"],
                        [CPColor colorWithHexString:@"af43ca"],
                        [CPColor colorWithHexString:@"43afca"]
                    ];
    
    CGContextSetLineWidth(context, 1.6);
    
    for (var setIndex = 0; setIndex < aFramesSet.length; setIndex++)
    {
        CGContextSetStrokeColor(context, fillColors[setIndex]);
        
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
