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
@import "TNArchipelClientLog.j";

TNLogLevelFatal = @"fatal";
TNLogLevelError = @"error";
TNLogLevelWarn  = @"warn";
TNLogLevelInfo  = @"info";
TNLogLevelDebug = @"debug";
TNLogLevelTrace = @"trace";

TNLogLevels     = [TNLogLevelTrace, TNLogLevelDebug, TNLogLevelInfo, TNLogLevelWarn, TNLogLevelError, TNLogLevelFatal];

/*! @defgroup  toolbarlogs Module Toolbar Logs
    @desc This module displays Archipel Client logs
*/


/*! @ingroup toolbarlogs
    The module main controller
*/
@implementation TNToolbarLogsController: TNModule
{
    @outlet CPPopUpButton   buttonLogLevel;
    @outlet CPScrollView    mainScrollView;
    @outlet CPSearchField   fieldFilter;

    CPString                _filter;
    CPTableView             _tableViewLogging;
    TNTableViewDataSource   _datasourceLogs;
    id                      _logFunction;
    CPString                _logLevel;
    int                     _maxLogEntries;
}


//#pragma mark -
//#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    _datasourceLogs = [[TNTableViewDataSource alloc] init];

    _logFunction = function (aMessage, aLevel, aTitle) {
        [self logMessage:aMessage title:aTitle level:aLevel];
    };

    [self restaure];

    [fieldFilter setTarget:_datasourceLogs];
    [fieldFilter setAction:@selector(filterObjects:)];

    [mainScrollView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setBorderedWithHexColor:@"#C0C7D2"];
    [mainScrollView setAutohidesScrollers:YES];

    var defaults = [CPUserDefaults standardUserDefaults];
    _logLevel       = [defaults objectForKey:@"TNArchipelLogStoredMaximumLevel"];

    if (!_logLevel)
        _logLevel = [[CPBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"TNDefaultLogLevel"];

    _maxLogEntries  = [[CPBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"TNMaxLogsEntries"];

    CPLogRegister(_logFunction, _logLevel);

    _tableViewLogging = [[CPTableView alloc] initWithFrame:[[mainScrollView contentView] frame]];

    [_tableViewLogging setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableViewLogging setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewLogging setAllowsColumnResizing:YES];
    [_tableViewLogging setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];

    var columnMessage       = [[CPTableColumn alloc] initWithIdentifier:@"message"],
        columnDate          = [[CPTableColumn alloc] initWithIdentifier:@"date"],
        levelCellPrototype  = [[TNCellLogLevel alloc] init],
        columnLevel         = [[CPTableColumn alloc] initWithIdentifier:@"level"];


    [[columnMessage headerView] setStringValue:@"Message"];

    [columnDate setWidth:130];
    [[columnDate headerView] setStringValue:@"Date"];

    [columnLevel setWidth:50];
    [columnLevel setDataView:levelCellPrototype];
    [[columnLevel headerView] setStringValue:@"Level"];

    [_tableViewLogging addTableColumn:columnLevel];
    [_tableViewLogging addTableColumn:columnDate];
    [_tableViewLogging addTableColumn:columnMessage];

    [_tableViewLogging setDataSource:_datasourceLogs];
    [_datasourceLogs setTable:_tableViewLogging];
    [_datasourceLogs setSearchableKeyPaths:[@"message", @"date", @"level"]];

    [mainScrollView setDocumentView:_tableViewLogging];

    [buttonLogLevel removeAllItems];
    [buttonLogLevel addItemsWithTitles:TNLogLevels];
    [buttonLogLevel selectItemWithTitle:_logLevel];
}


//#pragma mark -
//#pragma mark Utilities

/*! write log to the logger
    @param aString CPString containing the log message
*/
- (void)logMessage:(CPString)aMessage title:(CPString)aTitle level:(CPString)aLevel
{
    var theDate     = [CPDate dateWithFormat:@"Y-m-d H:i:s"],
        logEntry    = [TNArchipelClientLog archipelLogWithDate:theDate message:aMessage title:aTitle level:aLevel];

    if ([_datasourceLogs count] > _maxLogEntries)
        [_datasourceLogs removeLastObject];

    [_datasourceLogs insertObject:logEntry atIndex:0];
    [_tableViewLogging reloadData];

    [self save];
}

/*! save the logs into localStorage
*/
- (void)save
{
    // CPLogUnregister(_logFunction);
    // 
    // var defaults = [CPUserDefaults standardUserDefaults];
    // [defaults setObject:[_datasourceLogs content] forKey:@"TNArchipelLogStored"];
    // 
    // CPLogRegister(_logFunction, _logLevel);
}

/*! recover and returns the stored logs
*/
- (void)restaure
{
    // CPLogUnregister(_logFunction);
    // 
    // var defaults        = [CPUserDefaults standardUserDefaults],
    //     recoveredLogs   = [defaults objectForKey:@"TNArchipelLogStored"];
    // 
    // CPLogRegister(_logFunction, _logLevel);
    //[_datasourceLogs setContent:recoveredLogs ? recoveredLogs : [CPArray array]];
    [_datasourceLogs setContent:[CPArray array]];
}


//#pragma mark -
//#pragma mark Actions

/*! remove all previous stored logs
    @param sender the sender of the action
*/
- (IBAction)clearLog:(id)sender
{
    [_datasourceLogs removeAllObjects];
    [_tableViewLogging reloadData];

    [self save];
}

/*! set the minimum log level
    @param sender the sender of the action
*/
- (IBAction)setLogLevel:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults];

    _logLevel = [buttonLogLevel title];

    [defaults setObject:_logLevel forKey:@"TNArchipelLogStoredMaximumLevel"];

    CPLogUnregister(_logFunction);
    CPLogRegister(_logFunction, _logLevel);
}

@end
