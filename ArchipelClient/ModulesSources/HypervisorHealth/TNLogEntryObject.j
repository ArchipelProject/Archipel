/*
 * TNLogEntryObject.j
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



/*! @ingroup hypervisorhealth
    represent a log entry
*/
@implementation TNLogEntry : CPObject
{
    CPString    _date       @accessors(property=date);
    CPString    _file       @accessors(property=file);
    CPString    _level      @accessors(setter=setLevel:);
    CPString    _message    @accessors(setter=setMessage:);
    CPString    _method     @accessors(property=method);
}


#pragma mark -
#pragma mark Initialization

/*! create, initialize and return a TNLogEntry
    @param aLevel the level of the log
    @param aDate date of the log
    @param aFile file of the log
    @param aMethod method of the log
    @param aMessage message of the log
*/
+ (TNLogEntry)logEntryWithLevel:(CPString)aLevel date:(CPString)aDate file:(CPString)aFile method:(CPString)aMethod message:(CPString)aMessage;
{
    var log = [[TNLogEntry alloc] init];
    [log setLevel:aLevel];
    [log setDate:aDate];
    [log setFile:aFile];
    [log setMethod:aMethod];
    [log setMessage:aMessage];

    return log;
}

#pragma mark -
#pragma mark Utilities

/*! strip terminal colors chars
    @param aString the string to strip
    @return stripped string
*/
- (CPString)stripTerminalColors:(CPString)aString
{
    return aString.replace(new RegExp('\\[[0-9]+m', "g"), "");
}


#pragma mark -
#pragma mark Accessors

/*! will clean up log level from eventual colors
    @return cleaned level string
*/
- (CPString)level
{
    return [self stripTerminalColors:_level].replace(/ /g, "");
}

/*! will clean up log message from eventual colors
    @return cleaned message string
*/
- (CPString)message
{
    _message = _message.replace("DEBUG", "");
    _message = _message.replace("INFO", "");
    _message = _message.replace("WARNING", "");
    _message = _message.replace("ERROR", "");
    _message = _message.replace("CRITICAL", "");
    _message = _message.replace(new RegExp('[0-9]+-[0-9]+-[0-9]+ [0-9]+:[0-9]+:[0-9]+', 'g'), '');
    _message = _message.replace('::::', '');
    _message = _message.replace('::', ' ');
    _message = _message.replace(/(^\s*)|(\s*$)/gi,"");
    _message = _message.replace(/[ ]{2,}/gi,"");
    _message = _message.replace(/\n /,"\n");

    return [self stripTerminalColors:_message];
}

@end