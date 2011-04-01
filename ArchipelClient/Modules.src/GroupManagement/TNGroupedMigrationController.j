/*
 * TNGroupedMigrationController.j
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

@import <AppKit/CPScrollView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPTableView.j>

@import <TNKit/TNTableViewDataSource.j>


@implementation TNGroupedMigrationController : CPObject
{
    @outlet CPScrollView    scrollViewTableHypervisors;
    @outlet CPSearchField   searchFieldHypervisors;
    @outlet CPWindow        mainWindow;

    id                      _delegate @accessors(property=delegate);

    CPTableView             _tableHypervisors;
    TNTableViewDataSource   _datasourceHypervisors;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    _datasourceHypervisors  = [[TNTableViewDataSource alloc] init];
    _tableHypervisors       = [[CPTableView alloc] initWithFrame:[scrollViewTableHypervisors bounds]];

    [scrollViewTableHypervisors setBorderedWithHexColor:@"#C0C7D2"];
    [scrollViewTableHypervisors setAutohidesScrollers:YES];
    [scrollViewTableHypervisors setDocumentView:_tableHypervisors];

    [_tableHypervisors setUsesAlternatingRowBackgroundColors:YES];
    [_tableHypervisors setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableHypervisors setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableHypervisors setAllowsEmptySelection:YES];
    [_tableHypervisors setAllowsMultipleSelection:NO];

    var columnNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"],
        columnJID      = [[CPTableColumn alloc] initWithIdentifier:@"JID"];

    [columnNickname setWidth:150];
    [[columnNickname headerView] setStringValue:@"Name"];

    [columnJID setWidth:450];
    [[columnJID headerView] setStringValue:@"Jabber ID"];

    [_tableHypervisors addTableColumn:columnNickname];
    [_tableHypervisors addTableColumn:columnJID];

    [_datasourceHypervisors setTable:_tableHypervisors];
    [_datasourceHypervisors setSearchableKeyPaths:[@"nickname", @"JID"]];
    [_tableHypervisors setDataSource:_datasourceHypervisors];

    [searchFieldHypervisors setTarget:_datasourceHypervisors];
    [searchFieldHypervisors setAction:@selector(filterObjects:)];
}


#pragma mark -
#pragma mark Utilities

/*! populate the tableview with all hypervisors
*/
- (void)populateHypervisors
{
    [_datasourceHypervisors removeAllObjects];
    var rosterItems = [[[TNStropheIMClient defaultClient] roster] contacts];

    for (var i = 0; i < [rosterItems count]; i++)
    {
        var item = [rosterItems objectAtIndex:i];

        if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[item vCard]] == TNArchipelEntityTypeHypervisor)
            [_datasourceHypervisors addObject:item];
    }
    [_tableHypervisors reloadData];
}


#pragma mark -
#pragma mark Actions

/*! show the main window
    @param aSender the sender of the action
*/
- (IBAction)showMainWindow:(id)aSender
{
    [self populateHypervisors];
    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];
}

/*! hide the main window
    @param aSender the sender of the action
*/
- (IBAction)closeMainWindow:(id)aSender
{
    [mainWindow close];
}

/*! send migration info to the delegate
    @param aSender the sender of the action
*/
- (IBAction)sendMigration:(id)aSender
{
    var index = [[_tableHypervisors selectedRowIndexes] firstIndex];

    [_delegate performGroupedMigration:[_datasourceHypervisors objectAtIndex:index]];
    [mainWindow close];
}

@end