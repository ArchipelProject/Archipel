/*
 * TNArchipelLogEntry.j
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


/*! @ingroup toolbarlogs
    Represent a client log entry
*/
@implementation TNArchipelClientLog : CPObject
{
    CPString _date      @accessors(property=date);
    CPString _message   @accessors(property=message);
    CPString _title     @accessors(property=title);
    CPString _level     @accessors(property=level);
}

//#pragma mark -
//#pragma mark Initialization

/*! initializes and returns a new TNArchipelClientLog with given values
    @param aDate the date of the log
    @param aMessage the message of the log
    @param aTitle the title of the log
    @param aLevel the level of the log
    @return an initialized instance of TNArchipelClientLog
*/
+ (TNArchipelClientLog)archipelLogWithDate:(CPString)aDate message:(CPString)aMessage title:(CPString)aTitle level:(CPString)aLevel
{
    var log = [[TNArchipelClientLog alloc] init];

    [log setDate:aDate];
    [log setMessage:aMessage];
    [log setTitle:aTitle];
    [log setLevel:aLevel];

    return log;
}

//#pragma mark -
//#pragma mark CPCoding compliance

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        _date       = [aCoder decodeObjectForKey:@"_date"];
        _message    = [aCoder decodeObjectForKey:@"_message"];
        _title      = [aCoder decodeObjectForKey:@"_title"];
        _level      = [aCoder decodeObjectForKey:@"_level"];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_date forKey:@"_date"];
    [aCoder encodeObject:_message forKey:@"_message"];
    [aCoder encodeObject:_title forKey:@"_title"];
    [aCoder encodeObject:_level forKey:@"_level"];
}

@end
