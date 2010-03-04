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


@implementation TNDatasourceGraphCPU : CPObject
{
    CPArray   _datas;
}

- (void)init
{
    if (self = [super init])
    {
        _datas = [0];
        _maxNumberOfPoints = 100;
    }
    return self;
}

- (CPNumber)numberOfSetsInChart:(LPChartView)aCharView
{
    return 1;
}

- (CPNumber)chart:(LPChartView)aChartView numberOfValuesInSet:(CPNumber)setIndex
{
    return [_datas count];
}

- (id)chart:(LPChartView)aChartView valueForIndex:(CPNumber)itemIndex set:(CPNumber)setIndex
{
    if (itemIndex > ([_datas count] - 1))
        return 0;
    
    return [_datas objectAtIndex:itemIndex];
}

- (CPString)chart:(LPChartView)aChartView labelValueForIndex:(int)anIndex
{
    return /*  
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


@implementation TNDatasourceGraphCPU : CPObject
{
    CPArray   _datas;
}

- (void)init
{
    if (self = [super init])
    {
        _datas = [];
        _maxNumberOfPoints = 100;
    }
    return self;
}

- (CPNumber)numberOfSetsInChart:(LPChartView)aCharView
{
    return 1;
}

- (CPNumber)chart:(LPChartView)aChartView numberOfValuesInSet:(CPNumber)setIndex
{
    return [_datas count];
}

- (id)chart:(LPChartView)aChartView valueForIndex:(CPNumber)itemIndex set:(CPNumber)setIndex
{
    if (itemIndex > ([_datas count] - 1))
        return 0;
    
    return [_datas objectAtIndex:itemIndex];
}

- (CPString)chart:(LPChartView)aChartView labelValueForIndex:(int)anIndex
{
    return @"";//@"" + _datas[anIndex] + "%";
}

- (void)pushData:(id)data
{
    if ([_datas count] >= _maxNumberOfPoints)
        [_datas removeObjectAtIndex:0];
    
    _datas.push(parseInt(data));
} 

@end@"" + _datas[anIndex] + "%";
}

- (void)pushData:(id)data
{
    if ([_datas count] >= _maxNumberOfPoints)
        [_datas removeObjectAtIndex:0];
    
    _datas.push(parseInt(data));
}

- (void)removeAllObjects
{
    _datas = [];
}


@end