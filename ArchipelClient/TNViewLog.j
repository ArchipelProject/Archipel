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

@implementation TNViewLog: CPScrollView 
{
    CPArray       logs      @accessors;
    CPTableView   logTable  @accessors;

}

- (void)awakeFromCib 
{
    var logs = [[CPArray alloc] init];
    
    [self setLogTable:[[CPTableView alloc] initWithFrame:[[self contentView] bounds]]];
    [[self logTable] setCornerView:null];
    [[self logTable] setUsesAlternatingRowBackgroundColors:YES];
    
    var columnText = [[CPTableColumn alloc] initWithIdentifier:@"content"];
    [columnText setWidth:500];
    [columnText setResizingMask:CPTableColumnAutoresizingMask] ;
    [[columnText headerView] setStringValue:@"Content"];
    [[columnText headerView] sizeToFit];
    
    var columnDate = [[CPTableColumn alloc] initWithIdentifier:@"date"];
    [columnDate setWidth:160];
    
    [[self logTable] addTableColumn:columnDate];
    [[self logTable] addTableColumn:columnText];
    
    [[self logTable] setDataSource:self];
    
    [self setDocumentView:[self logTable]];
}

- (void)log:(CPString)aString 
{
    [[self logs] insertObject:{ "date" : [CPDate date], "content" : aString} atIndex:0];
    [[self logTable] reloadData];
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