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

@import <Foundation/Foundation.j>

@import <LPKit/LPChartView.j>



/*! @ingroup hypervisorhealth
    Datasource for LPChartView
*/
@implementation TNDatasourceChartView : CPObject
{
    CPArray     _datas;
    int         _maxNumberOfPoints;
}

#pragma mark -
#pragma mark Initialization

/*! initializes the datasource with the given number of set
    @param numberOfSets the number of different data set to use
*/
- (id)initWithNumberOfSets:(int)numberOfSets
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

/*! initializes the datasource with 1 data sat
*/
- (id)init
{
    return [self initWithSets:1];
}


#pragma mark -
#pragma mark Datasource implementation

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


#pragma mark -
#pragma mark Content controls

/*! Add the given data to the datasource in the given dataset
    @param aData the data to push into the datasource
    @param setIndex the index of set in which you want to push the data
*/
- (void)pushData:(id)data inSet:(CPNumber)setIndex
{
    if (setIndex >= [_datas count])
        return;

    if ([[_datas objectAtIndex:setIndex] count] >= _maxNumberOfPoints)
        [[_datas objectAtIndex:setIndex] removeObjectAtIndex:0];

    [_datas objectAtIndex:setIndex].push(parseFloat(data));

}

/*! Set the complete set of data for the given set index
    @param data the CPArray of data to set into the datasource
    @param setIndex the index of set in which you want to push the data
*/
- (void)setData:(CPArray)data inSet:(CPNumber)setIndex
{
    if (setIndex >= [_datas count])
    {
        [CPException raise:@"set index too big" reason:@"setIndex set to " + setIndex + ". Maximum is " + [_datas count] - 1];
    }

    _datas[setIndex] = [CPArray arrayWithArray:data];
}

/*! remove all object from the datasource
*/
- (void)removeAllObjects
{
    _datas = [];
}

@end


/*! @ingroup hypervisorhealth
    override LPChartDrawView in order to theme it and not having dealing with theme
*/
@implementation TNChartDrawView : LPChartDrawView

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
