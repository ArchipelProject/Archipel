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

TNArchipelTypeHypervisorVMCasting                   = @"archipel:hypervisor:vmcasting"
TNArchipelTypeHypervisorVMCastingDownloadQueue      = @"downloadqueue";


@implementation TNWindowDownloadQueue : CPWindow 
{
    @outlet CPScrollView            mainScrollView;
    
    TNStropheContact                entity  @accessors;
    
    CPTableView                     _mainTableView;
    TNTableViewDataSource           _dlDatasource;
    
    CPTimer                         _timer;
}

- (void)awakeFromCib
{
    _dlDatasource = [[TNTableViewDataSource alloc] init];

    _mainTableView = [[CPTableView alloc] initWithFrame:[mainScrollView bounds]];
    [_mainTableView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

    var columnIdentifier = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[columnIdentifier headerView] setStringValue:@"Name"];

    var columnSize = [[CPTableColumn alloc] initWithIdentifier:@"totalSize"];
    [[columnSize headerView] setStringValue:@"Total Size"];    
     
    var columnPercentage = [[CPTableColumn alloc] initWithIdentifier:@"percentage"];
    [[columnPercentage headerView] setStringValue:@"Percentage"];
    //[columnPercentage setDataView:progressBar];
    
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

- (void)orderFront:(id)sender
{
    [self getDownloadQueue:nil];
    if (!_timer)
        _timer = [CPTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(getDownloadQueue:) userInfo:nil repeats:YES];
    [super orderFront:sender];
}

- (void)performClose:(id)sender
{
    [_timer invalidate];
    _timer = nil;
    [super performClose:sender];
}

- (void)getDownloadQueue:(CPTimer)aTimer
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeHypervisorVMCasting, 
        "action": TNArchipelTypeHypervisorVMCastingDownloadQueue}];

    
    [[self entity] sendStanza:stanza andRegisterSelector:@selector(didReceiveDownloadQueue:) ofObject:self];
}

- (void)didReceiveDownloadQueue:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
    {
        var downloads = [aStanza childrenWithName:@"download"];
        
        [_dlDatasource removeAllObjects];
        
        for (var i = 0; i < [downloads count]; i++)
        {
            var download    = [downloads objectAtIndex:i];
            var identifier  = [download valueForAttribute:@"uuid"];
            var name        = [download valueForAttribute:@"name"];
            var percentage  = Math.round(parseFloat([download valueForAttribute:@"percentage"]));
            var totalSize   = Math.round(parseFloat([download valueForAttribute:@"total"]));
            
            var dl = [TNDownload downloadWithIdentifier:identifier name:name totalSize:totalSize percentage:percentage];
            
            [_dlDatasource addObject:dl];
        }
        
        [_mainTableView reloadData];
    }
}
@end
