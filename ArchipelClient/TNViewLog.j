/*  
 * TNViewLog.j
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

var theSharedLogger;

@implementation TNViewLog: CPScrollView 
{
    CPArray         logs        @accessors;
    CPTableView     logTable    @accessors;
}

+ (id)sharedLogger
{
    if (!theSharedLogger)
        theSharedLogger = [[TNViewLog alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        
    return theSharedLogger;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
        
        var storedLogs = JSON.parse(localStorage.getItem("storedLogs"));
        
        if (storedLogs)
            [self setLogs:storedLogs];
        else
            [self setLogs:[[CPArray alloc] init]];
        
        [self setLogTable:[[CPTableView alloc] initWithFrame:[[self contentView] frame]]];
        
        [[self logTable] setUsesAlternatingRowBackgroundColors:YES];
        [[self logTable] setAllowsColumnResizing:YES];
        [[self logTable] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
        
        var columnText = [[CPTableColumn alloc] initWithIdentifier:@"content"];
        [columnText setWidth:768];
        [columnText setResizingMask:CPTableColumnAutoresizingMask ] ;
        [[columnText headerView] setStringValue:@"Content"];
        
        var columnDate = [[CPTableColumn alloc] initWithIdentifier:@"date"];
        [columnDate setWidth:260];
        [[columnDate headerView] setStringValue:@"Date"];
        
        [[self logTable] addTableColumn:columnDate];
        [[self logTable] addTableColumn:columnText];
        
        [[self logTable] setDataSource:self];
        
        [self setDocumentView:[self logTable]];
        
        theSharedLogger = self;   
    }
    
    return self;
}

- (void)log:(CPString)aString 
{
    [[self logs] insertObject:{ "date" : [CPDate date], "content" : aString} atIndex:0];
    [[self logTable] reloadData];
    
    var storedLogs = [self logs];
    localStorage.setItem("storedLogs", JSON.stringify(storedLogs));
}

- (void)clearLog 
{
    [[self logs] removeAllObjects];
    [[self logTable] reloadData];
    
    var storedLogs = [self logs];
    localStorage.setItem("storedLogs", JSON.stringify(storedLogs));
}


// tableView delegate
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable 
{
    return [[self logs] count]
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    return logs[aRow][[aCol identifier]];
}

@end