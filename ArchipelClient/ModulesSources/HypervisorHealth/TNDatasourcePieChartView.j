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

@import <Foundation/Foundation.j>

@import <LPKit/LPPieChartView.j>



/*! @ingroup hypervisorhealth
    Datasource for LPPieChartView
*/
@implementation TNDatasourcePieChartView : CPObject
{
    CPArray     _datas;
}

/*! initialize the datasource
*/
- (void)init
{
    if (self = [super init])
    {
        _datas = [CPArray array];
    }
    return self;
}


#pragma mark -
#pragma mark Datasource implementation

- (int)numberOfItemsInPieChartView:(LPPieChartView)aPieChartView
{
    return [_datas count];
}

- (int)pieChartView:(LPPieChartView)aPieChartView floatValueForIndex:(int)anIndex
{
    return _datas[anIndex];
}


#pragma mark -
#pragma mark Content controls

/*! Add the given data to the datasource
    @param aData the data to push into the datasource
*/
- (void)pushData:(id)aData
{
    [_datas addObject:aData];
}

/*! remove all object from the datasource
*/
- (void)removeAllObjects
{
    [_datas removeAllObjects];
}

@end



/*! @ingroup hypervisorhealth
    override LPPieChartDrawView in order to theme it and not having dealing with theme
*/
@implementation TNPieChartDrawView : LPPieChartDrawView

- (void)drawInContext:(CGContext)context paths:(CPArray)paths
{
    /*
        Overwrite this method in your subclass.
    */
    CGContextSetLineWidth(context, 1.3);
    CGContextSetStrokeColor(context, [CPColor whiteColor]);

    var blueColor       = [CPColor colorWithHexString:@"4379ca"],
        darkBlueColor   = [CPColor colorWithHexString:@"3A5FA5"],
        greenColor      = [CPColor colorWithHexString:@"7fca43"],
        darkGreenColor  = [CPColor colorWithHexString:@"758B2C"],
        fillColors = [
                        [[blueColor redComponent], [blueColor greenComponent], [blueColor blueComponent],1.0, [darkBlueColor redComponent], [darkBlueColor greenComponent], [darkBlueColor blueComponent],1.0],
                        [[greenColor redComponent], [greenColor greenComponent], [greenColor blueComponent],1.0, [darkGreenColor redComponent], [darkGreenColor greenComponent], [darkGreenColor blueComponent],1.0]
                     ];
    for (var i = 0; i < paths.length; i++)
    {
        CGContextBeginPath(context);
        CGContextAddPath(context, paths[i]);

        var gradient = CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), fillColors[i], [0,1], 2);
        CGContextDrawLinearGradient(context, gradient, [self frame].origin, CGPointMake(0.0, 200.0), 0);

        CGContextClosePath(context);
        CGContextStrokePath(context);
    }
}

@end