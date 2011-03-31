/*
 * TNWindowDownloadQueue.j
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
@import <AppKit/CPTableView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNTableViewDataSource.j>

@import "TNCellPercentageView.j"



var TNArchipelTypeHypervisorVMCasting                   = @"archipel:hypervisor:vmcasting",
    TNArchipelTypeHypervisorVMCastingDownloadQueue      = @"downloadqueue";


/*! @ingroup hypervisorvmcasts
    Download  progress window
*/
@implementation TNWindowDownloadQueue : CPWindow
{
    @outlet CPScrollView            mainScrollView;

    TNStropheContact                entity  @accessors;

    CPTableView                     _mainTableView;
    CPTimer                         _timer;
    TNTableViewDataSource           _dlDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    _dlDatasource = [[TNTableViewDataSource alloc] init];

    _mainTableView = [[CPTableView alloc] initWithFrame:[mainScrollView bounds]];
    [_mainTableView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainTableView setUsesAlternatingRowBackgroundColors:YES];
    [_mainTableView setColumnAutoresizingStyle:CPTableViewFirstColumnOnlyAutoresizingStyle];

    var columnIdentifier = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        columnSize = [[CPTableColumn alloc] initWithIdentifier:@"totalSize"],
        columnPercentage = [[CPTableColumn alloc] initWithIdentifier:@"percentage"];

    [[columnIdentifier headerView] setStringValue:@"Name"];

    [[columnSize headerView] setStringValue:@"Size"];
    [columnSize setWidth:70.0];

    [[columnPercentage headerView] setStringValue:@"Progress"];
    [columnPercentage setWidth:130.0];
    [columnPercentage setDataView:[[TNCellPercentageView alloc] init]];

    [_mainTableView addTableColumn:columnIdentifier];
    [_mainTableView addTableColumn:columnSize];
    [_mainTableView addTableColumn:columnPercentage];

    [_dlDatasource setTable:_mainTableView];
    [_dlDatasource setSearchableKeyPaths:[@"name", @"totalSize", @"percentage"]];

    [_mainTableView setDataSource:_dlDatasource];

    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setBorderedWithHexColor:@"#C0C7D2"]
    [mainScrollView setDocumentView:_mainTableView];
    [_mainTableView reloadData];
}


#pragma mark -
#pragma mark CPWindow overrides

- (void)makeKeyAndOrderFront:(id)sender
{
    [self getDownloadQueue:nil];
    if (!_timer)
        _timer = [CPTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(getDownloadQueue:) userInfo:nil repeats:YES];
    [super makeKeyAndOrderFront:sender];
}

- (IBAction)performClose:(id)sender
{
    [_timer invalidate];
    _timer = nil;
    [super performClose:sender];
}


#pragma mark -
#pragma mark XMPP Controls

/*! get the progress of downloads
    @param aTimer the timere that have triggered the message
*/
- (void)getDownloadQueue:(CPTimer)aTimer
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingDownloadQueue}];


    [[self entity] sendStanza:stanza andRegisterSelector:@selector(_didReceiveDownloadQueue:) ofObject:self];
}

/*! compute the answer containng the download progresses
    @param aStanza TNStropheStanza that contains the hypervisor answer
*/
- (void)_didReceiveDownloadQueue:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var downloads = [aStanza childrenWithName:@"download"];

        [_dlDatasource removeAllObjects];

        for (var i = 0; i < [downloads count]; i++)
        {
            var download    = [downloads objectAtIndex:i],
                identifier  = [download valueForAttribute:@"uuid"],
                name        = [download valueForAttribute:@"name"],
                percentage  = Math.round(parseFloat([download valueForAttribute:@"percentage"])),
                totalSize   = Math.round(parseFloat([download valueForAttribute:@"total"])),
                dl          = [TNDownload downloadWithIdentifier:identifier name:name totalSize:totalSize percentage:percentage];

            [_dlDatasource addObject:dl];
        }

        [_mainTableView reloadData];
    }
}

@end