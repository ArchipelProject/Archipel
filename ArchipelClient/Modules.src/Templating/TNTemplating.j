/*  
 * TNSampleToolbarModule.j
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

@import "TNVMCastDatasource.j";


TNArchipelTypeHypervisorVMCasting                   = @"archipel:hypervisor:vmcasting"
TNArchipelTypeHypervisorVMCastingGet                = @"get";
TNArchipelTypeHypervisorVMCastingRegister           = @"register";
TNArchipelTypeHypervisorVMCastingUnregister         = @"unregister";
TNArchipelTypeHypervisorVMCastingDownload           = @"download";
TNArchipelTypeHypervisorVMCastingDownloadProgress   = @"downloadprogress";

// TNArchipelPushNotificationVMCasting      = @"archipel:push:vmcasting:download";
// TNArchipelPushNotificationSubscriptionAdded = @"downloaded";

/*! @defgroup  templatingmodule Module Templating
    
    @desc This module manages XVM2 templating system
*/


/*! @ingroup templatingmodule
    templating module implementation
*/
@implementation TNTemplating : TNModule
{
    @outlet CPScrollView        mainScrollView  @accessors;
    @outlet CPProgressIndicator downloadIndicator     @accessors;
    
    CPOutlineView           _mainOutlineView;
    TNVMCastDatasource      _castsDatasource;
}

- (void)awakeFromCib
{
    _castsDatasource = [[TNVMCastDatasource alloc] init];
    
    _mainOutlineView = [[CPOutlineView alloc] initWithFrame:[mainScrollView bounds]];
    [_mainOutlineView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainOutlineView setDataSource:_castsDatasource];
    
    var columnName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[columnName headerView] setStringValue:@"VM Casts"];
    [columnName setResizingMask:CPTableColumnAutoresizingMask];
    [columnName setWidth:200];
    
    var columnDescription = [[CPTableColumn alloc] initWithIdentifier:@"comment"];
    [[columnDescription headerView] setStringValue:@"Comment"];
    [columnDescription setResizingMask:CPTableColumnAutoresizingMask];
    [columnDescription setWidth:300];
    
    var columnUrl = [[CPTableColumn alloc] initWithIdentifier:@"URL"];
    [[columnUrl headerView] setStringValue:@"URL"];
    [columnUrl setWidth:300];
    
    var columnSize = [[CPTableColumn alloc] initWithIdentifier:@"size"];
    [[columnSize headerView] setStringValue:@"Size"];
    [columnSize setResizingMask:CPTableColumnAutoresizingMask];
    
    [_mainOutlineView setOutlineTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnDescription];
    [_mainOutlineView addTableColumn:columnSize];
    [_mainOutlineView addTableColumn:columnUrl];
    
    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setBorderedWithHexColor:@"#9e9e9e"]
    [mainScrollView setDocumentView:_mainOutlineView];
    [_mainOutlineView reloadData];
}

- (void)willLoad
{
    [super willLoad];
}

- (void)willUnload
{
    [super willUnload];
   // message sent when view will be removed from superview;
}

- (void)willShow
{
    [super willShow];
    
    [[_castsDatasource contents] removeAllObjects];
    [self getVMCasts];
}

- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}


- (void)getVMCasts
{
    var stanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorVMCasting}];
        
    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorVMCastingGet}];
    [[self entity] sendStanza:stanza andRegisterSelector:@selector(didReceivedVMCasts:) ofObject:self];
    
}

- (void)didReceivedVMCasts:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
        var sources = [aStanza childrenWithName:@"source"];
        
        for (var i = 0; i < [sources count]; i++)
        {
            var source  = [sources objectAtIndex:i];
            var name    = [source valueForAttribute:@"name"];
            var url     = [CPURL URLWithString:[source valueForAttribute:@"url"]];
            var comment = [source valueForAttribute:@"description"];
            
            var newSource = [TNVMCastSource VMCastSourceWithName:name URL:url comment:comment];
            
            var appliances = [source childrenWithName:@"appliance"];
            
            for (var j = 0; j < [appliances count]; j++)
            {
                var appliance   = [appliances objectAtIndex:j];
                var name        = [appliance valueForAttribute:@"name"];
                var url         = [CPURL URLWithString:[appliance valueForAttribute:@"url"]];
                var comment     = [appliance valueForAttribute:@"description"];
                var size        = [appliance valueForAttribute:@"size"];
                var date        = [appliance valueForAttribute:@"pubDate"];
                var uuid        = [appliance valueForAttribute:@"uuid"];
                
                var newCast    = [TNVMCast VMCastWithName:name URL:url comment:comment size:size pubDate:date UUID:uuid];
                
                [[newSource content] addObject:newCast];
            }
            
            [_castsDatasource addSource:newSource];
        }
        [_mainOutlineView reloadData];
    }
}

- (IBAction)download:(id)sender
{
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorVMCasting}];
    var selectedIndex   = [[ _mainOutlineView selectedRowIndexes] firstIndex];
    var item            = [_mainOutlineView itemAtRow:selectedIndex];
    var uuid            = [item UUID];
    
    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorVMCastingDownload, "uuid": uuid}];
    
    [[self entity] sendStanza:stanza andRegisterSelector:@selector(didDownload:) ofObject:self];
}

- (void)didDownload:(TNStropheStanza)aStanza
{
    console.log("done...");
    
    //[CPTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateDownloadProgress:) userInfo:nil repeats:YES];
}

- (void)updateDownloadProgress:(CPTimer)aTimer
{
    CPLogConsole("sending progress getter..")
    var stanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorVMCasting}];
        
    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorVMCastingDownloadProgress}];
    [[self entity] sendStanza:stanza andRegisterSelector:@selector(didDownloadProgress:) ofObject:self];
}

- (void)didDownloadProgress:(TNStropheStanza)aStanza
{
    //var download [aStanza firstChildWithName:@"query"]
    CPLogConsole("UPDATED DL PROGRESS...");
}

@end



