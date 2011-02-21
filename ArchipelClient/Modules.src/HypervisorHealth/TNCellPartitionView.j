/*
 * TNCellPartitionView.j
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

/*! represent a Partition object in a CPTableView
*/
@implementation TNCellPartitionView : CPView
{
    CPProgressIndicator     _progressBar;
    CPTextField             _nameLabel;
    CPTextField             _totalLabel;
    CPTextField             _usedLabel;
    CPTextField             _availableLabel;
}

#pragma mark -
#pragma mark Initialization

/*! initialize the view
*/
- (id)init
{
    if (self = [super initWithFrame:CPRectMake(0.0, 0.0, 420.0, 60.0)])
    {
        [self setAutoresizingMask: CPViewWidthSizable];

        _nameLabel = [CPTextField labelWithTitle:@"Partition name"];
        [_nameLabel setFont:[CPFont boldSystemFontOfSize:12.0]];
        [_nameLabel sizeToFit];
        [_nameLabel setFrameOrigin:CPPointMake(3.0, 3.0)]

        _usedLabel = [CPTextField labelWithTitle:@"Used: "];
        [_usedLabel setFont:[CPFont systemFontOfSize:10.0]];
        [_usedLabel setFrameOrigin:CPPointMake(260.0, 3.0)];
        [_usedLabel setAutoresizingMask:CPViewMinXMargin];
        [_usedLabel sizeToFit];

        _availableLabel = [CPTextField labelWithTitle:@"Available: "];
        [_availableLabel setFont:[CPFont systemFontOfSize:10.0]];
        [_availableLabel setFrameOrigin:CPPointMake(330.0, 3.0)];
        [_availableLabel setAutoresizingMask:CPViewMinXMargin];
        [_availableLabel sizeToFit];

        _progressBar = [[CPProgressIndicator alloc] initWithFrame:CPRectMake(3.0, 20.0, 415.0, 16.0)];
        [_progressBar setAutoresizingMask:CPViewWidthSizable];
        [_progressBar setMaxValue:100];
        [_progressBar setMinValue:0];

        [self addSubview:_nameLabel];
        [self addSubview:_usedLabel];
        [self addSubview:_availableLabel];
        [self addSubview:_progressBar];
    }

    return self;
}

/*! set the object value of the cell
    @params aValue the current value
*/
- (void)setObjectValue:(CPDictionary)aContent
{
    [_progressBar setDoubleValue:parseInt([aContent objectForKey:@"capacity"])];

    [_nameLabel setStringValue:[aContent objectForKey:@"mount"]];
    [_nameLabel sizeToFit];

    [_usedLabel setStringValue:@"Used: " + Math.round([aContent objectForKey:@"used"] / 1024 / 1024) + @"Gb"];
    [_usedLabel sizeToFit];

    [_availableLabel setStringValue:@"Available: " + Math.round([aContent objectForKey:@"available"] / 1024 / 1024) + @"Gb"];
    [_availableLabel sizeToFit];
}


#pragma mark -
#pragma mark CPCoding compliance

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _progressBar    = [aCoder decodeObjectForKey:@"_progressBar"];
        _nameLabel      = [aCoder decodeObjectForKey:@"_nameLabel"];
        _usedLabel      = [aCoder decodeObjectForKey:@"_usedLabel"];
        _availableLabel = [aCoder decodeObjectForKey:@"_availableLabel"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:_nameLabel forKey:@"_nameLabel"];
    [aCoder encodeObject:_progressBar forKey:@"_progressBar"];
    [aCoder encodeObject:_usedLabel forKey:@"_usedLabel"];
    [aCoder encodeObject:_availableLabel forKey:@"_availableLabel"];
}

@end