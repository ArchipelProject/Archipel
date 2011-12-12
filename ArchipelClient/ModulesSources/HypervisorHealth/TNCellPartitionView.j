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
@import <AppKit/CPLevelIndicator.j>
@import <AppKit/CPProgressIndicator.j>
@import <AppKit/CPTextField.j>

/*! represent a Partition object in a CPTableView
*/
@implementation TNCellPartitionView : TNBasicDataView
{
    @outlet CPLevelIndicator        levelIndicator;
    @outlet CPTextField             nameLabel;
    @outlet CPTextField             totalLabel;
    @outlet CPTextField             usedLabel;
    @outlet CPTextField             availableLabel;
}


#pragma mark -
#pragma mark CPColumn view protocol

/*! set the object value of the cell
    @params aPartition the current value
*/
- (void)setObjectValue:(CPDictionary)aPartition
{
    var capacity = parseInt([aPartition capacity]);
    [levelIndicator setDoubleValue:50 - capacity / 2];

    [nameLabel setStringValue:[aPartition mount]];
    [usedLabel setStringValue:CPBundleLocalizedString(@"Used: ", @"Used: ") + [CPString formatByteSize:[[aPartition used] intValue]]];
    [availableLabel setStringValue:CPBundleLocalizedString(@"Available: ", @"Available: ") + [CPString formatByteSize:[[aPartition available] intValue]]];
}


#pragma mark -
#pragma mark CPCoding compliance

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        levelIndicator = [aCoder decodeObjectForKey:@"levelIndicator"];
        nameLabel      = [aCoder decodeObjectForKey:@"nameLabel"];
        usedLabel      = [aCoder decodeObjectForKey:@"usedLabel"];
        availableLabel = [aCoder decodeObjectForKey:@"availableLabel"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:nameLabel forKey:@"nameLabel"];
    [aCoder encodeObject:levelIndicator forKey:@"levelIndicator"];
    [aCoder encodeObject:usedLabel forKey:@"usedLabel"];
    [aCoder encodeObject:availableLabel forKey:@"availableLabel"];
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNCellPartitionView], comment);
}