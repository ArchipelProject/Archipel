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


@implementation TNDownload : CPObject
{
    CPString    identifier  @accessors;
    CPString    name        @accessors;
    float       totalSize   @accessors;
    float       percentage  @accessors(setter=setPercentage:);
}

+ (TNDownload)downloadWithIdentifier:(CPString)anIdentifier name:(CPString)aName totalSize:(float)aSize percentage:(float)aPercentage
{
    var dl = [[TNDownload alloc] init];
    [dl setIdentifier:anIdentifier];
    [dl setTotalSize:aSize];
    [dl setName:aName];
    [dl setPercentage:aPercentage];
    
    return dl;
}

- (CPString)percentage
{
    return @"" + percentage + @"%";
}

@end

@implementation TNDownloadDatasource : CPObject
{
    CPArray downloads @accessors;
}

- (id)init
{
    if (self = [super init])
    {
       downloads = [CPArray array];
    }
    return self;
}

- (void)addDownload:(TNDownload)aDownload
{
    [downloads addObject:aDownload];
}

// Datasource impl.
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable
{
    return [downloads count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];
    
    return [[downloads objectAtIndex:aRow] valueForKey:identifier];
}

@end

@implementation TNWindowDownloadQueue : CPWindow 
{
    @outlet CPScrollView            mainScrollView;
    
    TNStropheContact                entity  @accessors;
    
    CPTableView                     _mainTableView;
    TNDownloadDatasource            _dlDatasource;
    
    CPTimer                         _timer;
}

- (void)awakeFromCib
{
    _dlDatasource = [[TNDownloadDatasource alloc] init];

    _mainTableView = [[CPTableView alloc] initWithFrame:[mainScrollView bounds]];
    [_mainTableView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainTableView setDataSource:_dlDatasource];

    var columnIdentifier = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[columnIdentifier headerView] setStringValue:@"Name"];

    var columnSize = [[CPTableColumn alloc] initWithIdentifier:@"totalSize"];
    [[columnSize headerView] setStringValue:@"Total Size"];

    //var progressBar = [CPProgressIndicator initialize];
    //[progressBar setMinValue:0.0];
    //[progressBar setMaxValue:100.0];
     
    var columnPercentage = [[CPTableColumn alloc] initWithIdentifier:@"percentage"];
    [[columnPercentage headerView] setStringValue:@"Percentage"];
    //[columnPercentage setDataView:progressBar];
    
    [_mainTableView addTableColumn:columnIdentifier];
    [_mainTableView addTableColumn:columnSize];
    [_mainTableView addTableColumn:columnPercentage];


    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setBorderedWithHexColor:@"#9e9e9e"]
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
    var stanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorVMCasting}];

    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorVMCastingDownloadQueue}];
    
    [[self entity] sendStanza:stanza andRegisterSelector:@selector(didReceiveDownloadQueue:) ofObject:self];
}

- (void)didReceiveDownloadQueue:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
        var downloads = [aStanza childrenWithName:@"download"];
        
        [[_dlDatasource downloads] removeAllObjects];
        
        for (var i = 0; i < [downloads count]; i++)
        {
            var download    = [downloads objectAtIndex:i];
            var identifier  = [download valueForAttribute:@"uuid"];
            var name        = [download valueForAttribute:@"name"];
            var percentage  = Math.round(parseFloat([download valueForAttribute:@"percentage"]));
            var totalSize   = Math.round(parseFloat([download valueForAttribute:@"total"]));
            
            var dl = [TNDownload downloadWithIdentifier:identifier name:name totalSize:totalSize percentage:percentage];
            
            [_dlDatasource addDownload:dl];
        }
        
        [_mainTableView reloadData];
    }
}
@end
