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

@import <AppKit/CPButton.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPTableView.j>

@import <TNKit/TNAttachedWindow.j>
@import <TNKit/TNTableViewDataSource.j>
@import <TNKit/TNUIKitScrollView.j>


/*! @ingroup groupmanagement
    Allow to migrate several virtual machines
*/
@implementation TNGroupedMigrationController : CPObject
{
    @outlet CPButton            buttonMigrate;
    @outlet CPSearchField       searchFieldHypervisors;
    @outlet CPTableView         tableHypervisors;
    @outlet CPView              mainContentView;

    id                          _delegate @accessors(property=delegate);

    TNAttachedWindow            _mainWindow;
    TNTableViewDataSource       _datasourceHypervisors;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    _datasourceHypervisors  = [[TNTableViewDataSource alloc] init];
    [_datasourceHypervisors setTable:tableHypervisors];
    [_datasourceHypervisors setSearchableKeyPaths:[@"nickname", @"JID"]];
    [tableHypervisors setDataSource:_datasourceHypervisors];

    [searchFieldHypervisors setTarget:_datasourceHypervisors];
    [searchFieldHypervisors setAction:@selector(filterObjects:)];

    _mainWindow = [[TNAttachedWindow alloc] initWithContentRect:CPRectMake(0.0, 0.0, [mainContentView frameSize].width, [mainContentView frameSize].height) styleMask:TNAttachedWhiteWindowMask | CPClosableWindowMask];
    [_mainWindow setContentView:mainContentView];
    [_mainWindow setDefaultButton:buttonMigrate];
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
    [tableHypervisors reloadData];
}


#pragma mark -
#pragma mark Actions

/*! show the main window
    @param aSender the sender of the action
*/
- (IBAction)openWindow:(id)aSender
{
    [self populateHypervisors];
    [_mainWindow positionRelativeToView:aSender];
}

/*! hide the main window
    @param aSender the sender of the action
*/
- (IBAction)closeWindow:(id)aSender
{
    [_mainWindow close];
}

/*! send migration info to the delegate
    @param aSender the sender of the action
*/
- (IBAction)sendMigration:(id)aSender
{
    var index = [[tableHypervisors selectedRowIndexes] firstIndex];

    [_delegate performGroupedMigration:[_datasourceHypervisors objectAtIndex:index]];
    [_mainWindow close];
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNGroupedMigrationController], comment);
}