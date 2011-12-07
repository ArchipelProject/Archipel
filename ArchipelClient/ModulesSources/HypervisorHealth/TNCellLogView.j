/*
 * TNCellLogView.j
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

/*! represent a LogEntry object in a CPTableView
*/
@implementation TNCellLogView : TNBasicDataView
{
    @outlet CPTextField     fieldDate;
    @outlet CPTextField     fieldLevel;
    @outlet CPTextField     fieldMessage;
}


#pragma mark -
#pragma mark CPColumn view protocol

/*! set the object value of the cell
    @params aPartition the current value
*/
- (void)setObjectValue:(TNLogEntryObject)aLog
{
    [fieldLevel setStringValue:[aLog level]];
    [fieldDate setStringValue:[aLog date]];
    [fieldMessage setStringValue:[aLog message]];

    switch ([[aLog level] lowercaseString])
    {
        case "debug":
            [fieldLevel setTextColor:[CPColor colorWithHexString:@"4C8AFF"]];
            break;
        case "info":
            [fieldLevel setTextColor:[CPColor colorWithHexString:@"EAD700"]];
            break;
        case "warn":
            [fieldLevel setTextColor:[CPColor colorWithHexString:@"EC9C1B"]];
            break;
        case "error":
            [fieldLevel setTextColor:[CPColor colorWithHexString:@"ED4E44"]];
            break;
    }
}


#pragma mark -
#pragma mark CPCoding compliance

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        fieldDate       = [aCoder decodeObjectForKey:@"fieldDate"];
        fieldLevel      = [aCoder decodeObjectForKey:@"fieldLevel"];
        fieldMessage    = [aCoder decodeObjectForKey:@"fieldMessage"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:fieldDate forKey:@"fieldDate"];
    [aCoder encodeObject:fieldLevel forKey:@"fieldLevel"];
    [aCoder encodeObject:fieldMessage forKey:@"fieldMessage"];
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNCellPartitionView], comment);
}