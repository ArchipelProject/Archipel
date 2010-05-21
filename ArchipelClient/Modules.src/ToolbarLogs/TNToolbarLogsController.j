/*
 * TNToolbarLogs.j
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
@import <AppKit/AppKit.j>

@import "TNCellLogLevel.j";

TNLogLevelFatal = @"fatal";
TNLogLevelError = @"error";
TNLogLevelWarn  = @"warn";
TNLogLevelInfo  = @"info";
TNLogLevelDebug = @"debug";
TNLogLevelTrace = @"trace";

TNLogLevels     = [TNLogLevelTrace, TNLogLevelDebug, TNLogLevelInfo, TNLogLevelWarn, TNLogLevelError, TNLogLevelFatal];

/*! @ingroup archipelcore
    provides a logging facility. Logs are store using HTML5 storage.
*/
@implementation TNToolbarLogsController: TNModule
{
    @outlet CPScrollView    mainScrollView;
    @outlet CPPopUpButton   buttonLogLevel;
    @outlet CPSearchField   fieldFilter;
    
    CPArray         _logs;
    CPTableView     _tableViewLogging;
    id              _logFunction;
    CPString        _filter;
}

- (void)willLoad
{
    [super willLoad];
    // message sent when view will be added from superview;
}

- (void)willUnload
{
    [super willUnload];
   // message sent when view will be removed from superview;
}

- (void)willShow
{
    [super willShow];
    // message sent when the tab is clicked
}

- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}

/*! init the class with a rect
    @param aFrame a CPRect containing the frame information
*/
- (void)awakeFromCib
{
    // search field
    [fieldFilter setSendsSearchStringImmediately:YES];
    [fieldFilter setTarget:self];
    [fieldFilter setAction:@selector(filterFieldDidChange:)];
    
    _logFunction = function (aMessage, aLevel, aTitle) {
        [self logMessage:aMessage title:aTitle level:aLevel];
    };
    
    [mainScrollView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setBorderedWithHexColor:@"#C0C7D2"];
    [mainScrollView setAutohidesScrollers:YES];
    
    var defaults = [TNUserDefaults standardUserDefaults];
    maxLogLevel = [defaults objectForKey:@"TNArchipelLogStoredMaximumLevel"];
    
    if (!maxLogLevel)
        maxLogLevel = [[CPBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"TNDefaultLogLevel"];
    
    CPLogRegister(_logFunction, maxLogLevel);
    
    _logs = [self restaure];

    _tableViewLogging = [[CPTableView alloc] initWithFrame:[[mainScrollView contentView] frame]];

    [_tableViewLogging setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableViewLogging setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewLogging setAllowsColumnResizing:YES];
    [_tableViewLogging setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    
    var columnMessage = [[CPTableColumn alloc] initWithIdentifier:@"message"];
    [[columnMessage headerView] setStringValue:@"Message"];

    var columnDate = [[CPTableColumn alloc] initWithIdentifier:@"date"];
    [columnDate setWidth:130];
    [[columnDate headerView] setStringValue:@"Date"];

    var levelCellPrototype = [[TNCellLogLevel alloc] init];
    var columnLevel = [[CPTableColumn alloc] initWithIdentifier:@"level"];
    [columnLevel setWidth:50];
    [columnLevel setDataView:levelCellPrototype];
    [[columnLevel headerView] setStringValue:@"Level"];
    
    [_tableViewLogging addTableColumn:columnLevel];
    [_tableViewLogging addTableColumn:columnDate];
    [_tableViewLogging addTableColumn:columnMessage];

    [_tableViewLogging setDataSource:self];

    [mainScrollView setDocumentView:_tableViewLogging];
    
    [buttonLogLevel removeAllItems];
    [buttonLogLevel addItemsWithTitles:TNLogLevels];
    [buttonLogLevel selectItemWithTitle:maxLogLevel];
    
    theSharedLogger = self;
}

- (IBAction)filterFieldDidChange:(id)sender
{
    _filter = [sender stringValue];
    [_tableViewLogging reloadData];
}

- (void)save
{
    // var defaults = [TNUserDefaults standardUserDefaults];
    // [defaults setObject:JSON.stringify(_logs) forKey:@"TNArchipelLogStored"];    
    // I can't use TNDefault here or Safari hangs. This is weird.
    
    localStorage.setItem("TNArchipelLogStored", JSON.stringify(_logs));
}

- (CPArray)restaure
{
    // var defaults        = [TNUserDefaults standardUserDefaults];
    // var recoveredLogs   = JSON.parse([defaults objectForKey:@"TNArchipelLogStored"]);
    // I can't use TNDefault here or Safari hangs. This is weird.
    
    var recoveredLogs = JSON.parse(localStorage.getItem("TNArchipelLogStored"));
    
    return (recoveredLogs) ? recoveredLogs : [CPArray array];
}

/*! write log to the logger
    @param aString CPString containing the log message
*/
- (void)logMessage:(CPString)aMessage title:(CPString)aTitle level:(CPString)aLevel
{
    var theDate     = [CPDate dateWithFormat:@"Y-m-d H:i:s"];
    var logEntry    = {"date": theDate, "message": aMessage, "title": aTitle, "level": aLevel};
    
    [_logs insertObject:logEntry atIndex:0];
    
    [_tableViewLogging reloadData];

    [self save];
}

/*! remove all previous stored logs
*/
- (IBAction)clearLog:(id)sender
{
    [_logs removeAllObjects];
    [_tableViewLogging reloadData];

    [self save];
}

- (IBAction)setLogLevel:(id)sender
{
    var defaults = [TNUserDefaults standardUserDefaults];
    var logLevel = [buttonLogLevel title];
    
    [defaults setObject:logLevel forKey:@"TNArchipelLogStoredMaximumLevel"];
    
    CPLogUnregister(_logFunction);
    
    CPLogRegister(_logFunction, logLevel);
}


- (CPArray)getEntriesInArray:(CPArray)anArray matchingFilter:(CPString)aFilter
{
    if (!aFilter)
        return anArray;

    var filteredArray = [CPArray array];
    
    for (var i = 0; i < [anArray count]; i++)
    {
        var entry = [anArray objectAtIndex:i];

        if ((entry["level"].toUpperCase().indexOf([aFilter uppercaseString]) != -1) 
            || (entry["message"].toUpperCase().indexOf([aFilter uppercaseString]) != -1)
            || (entry["date"].toUpperCase().indexOf([aFilter uppercaseString]) != -1))
            [filteredArray addObject:entry];
    }

    return filteredArray;
}

/*! CPTableView delegate
*/
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable
{
    var entry = [self getEntriesInArray:_logs matchingFilter:_filter];
    
    return [entry count];
}

/*! CPTableView delegate
*/
- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPTableColumn)aCol row:(CPNumber)aRow
{
    var entry           = [self getEntriesInArray:_logs matchingFilter:_filter];
    var anIdentifier    = [aCol identifier];
    var value           = entry[aRow][anIdentifier];
    
    return value;
}

@end


