/*
 * TNDownloadQueueController.j
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

@import <AppKit/CPTableView.j>
@import <AppKit/CPWindow.j>

@import <StropheCappuccino/TNStropheStanza.j>
@import <TNKit/TNTableViewDataSource.j>

@import "TNCellPercentageView.j"
@import "TNDownoadObject.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNArchipelTypeHypervisorVMCastingDownloadQueue


var TNArchipelTypeHypervisorVMCasting                   = @"archipel:hypervisor:vmcasting",
    TNArchipelTypeHypervisorVMCastingDownloadQueue      = @"downloadqueue";


/*! @ingroup hypervisorvmcasts
    Download  progress window
*/
@implementation TNDownloadQueueController : CPObject
{
    @outlet CPPopover       mainPopover;
    @outlet CPTableView     mainTableView;
    @outlet CPTextField     labelTarget;

    id                      _delegate  @accessors(property=delegate);

    CPTimer                 _timer;
    TNTableViewDataSource   _dlDatasource;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    _dlDatasource = [[TNTableViewDataSource alloc] init];
    [_dlDatasource setTable:mainTableView];
    [_dlDatasource setSearchableKeyPaths:[@"name", @"totalSize", @"percentage"]];
    [[mainTableView tableColumnWithIdentifier:@"percentage"] setDataView:[[TNCellPercentageView alloc] init]];
    [mainTableView setDataSource:_dlDatasource];
    [mainTableView reloadData];
}


#pragma mark -
#pragma mark CPWindow overrides

- (void)showWindow:(id)aSender
{
    [mainPopover close];
    [self getDownloadQueue:nil];
    if (!_timer)
        _timer = [CPTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(getDownloadQueue:) userInfo:nil repeats:YES];
    [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [labelTarget setStringValue:CPBundleLocalizedString(@"Download queue for ", @"Download queue for ") + [[_delegate entity] name]];
}

- (IBAction)closeWindow:(id)sender
{
    [_timer invalidate];
    _timer = nil;
    [mainPopover close];
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

    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didReceiveDownloadQueue:) ofObject:self];
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

        [mainTableView reloadData];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNDownloadQueueController], comment);
}
