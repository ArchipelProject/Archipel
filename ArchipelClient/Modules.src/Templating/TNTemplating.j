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

TNArchipelPushNotificationVMCasting      = @"archipel:push:vmcasting";
// TNArchipelPushNotificationSubscriptionAdded = @"downloaded";

/*! @defgroup  templatingmodule Module Templating
    
    @desc This module manages XVM2 templating system
*/


/*! @ingroup templatingmodule
    templating module implementation
*/
@implementation TNTemplating : TNModule
{
    @outlet CPTextField         fieldJID                @accessors;
    @outlet CPTextField         fieldName               @accessors;
    @outlet CPTextField         fieldNewURL             @accessors;
    
    @outlet CPScrollView        mainScrollView          @accessors;
    @outlet CPProgressIndicator downloadIndicator       @accessors;
    @outlet CPWindow            windowDownloadQueue     @accessors;

    CPOutlineView               _mainOutlineView;
    TNVMCastDatasource          _castsDatasource;
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
    [columnDescription setWidth:250];
    
    var columnUrl = [[CPTableColumn alloc] initWithIdentifier:@"URL"];
    [[columnUrl headerView] setStringValue:@"URL"];
    [columnUrl setWidth:250];
    
    var columnSize = [[CPTableColumn alloc] initWithIdentifier:@"size"];
    [[columnSize headerView] setStringValue:@"Size"];
    [columnSize setResizingMask:CPTableColumnAutoresizingMask];
    
    var columnStatus = [[CPTableColumn alloc] initWithIdentifier:@"status"];
    [[columnStatus headerView] setStringValue:@"Status"];
    
    [_mainOutlineView setOutlineTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnSize];
    [_mainOutlineView addTableColumn:columnStatus];
    [_mainOutlineView addTableColumn:columnDescription];
    //[_mainOutlineView addTableColumn:columnUrl];

    [_mainOutlineView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];

    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setBorderedWithHexColor:@"#9e9e9e"]
    [mainScrollView setDocumentView:_mainOutlineView];
    [_mainOutlineView reloadData];
    [_mainOutlineView expandAll];
}

- (void)willLoad
{
    [super willLoad];
    [[self windowDownloadQueue] setEntity:[self entity]];
    [self registerSelector:@selector(didVMCastingPushReceived:) forPushNotificationType:TNArchipelPushNotificationVMCasting];
}

- (void)willUnload
{
    [super willUnload];
    
}

- (void)willShow
{
    [super willShow];
    
    [[self fieldName] setStringValue:[[self entity] nickname]];
    [[self fieldJID] setStringValue:[[self entity] jid]];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:[self entity]];
    
    [self getVMCasts];
}

- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}


- (void)didNickNameUpdated:(CPNotification)aNotification
{
    [[self fieldName] setStringValue:[[self entity] nickname]] 
}

- (BOOL)didVMCastingPushReceived:(TNStropheStanza)aStanza
{
    CPLogConsole("PUSH RECIEVED")
    [self getVMCasts];
    
    return YES;
}

- (void)getVMCasts
{
    var stanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorVMCasting}];
        
    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorVMCastingGet}];

    [self sendStanza:stanza andRegisterSelector:@selector(didReceivedVMCasts:)]
}

- (void)didReceivedVMCasts:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
        [[_castsDatasource contents] removeAllObjects];
        
        var sources = [aStanza childrenWithName:@"source"];
        
        for (var i = 0; i < [sources count]; i++)
        {
            var source  = [sources objectAtIndex:i];
            var name    = [source valueForAttribute:@"name"];
            var url     = [CPURL URLWithString:[source valueForAttribute:@"url"]];
            var uuid    = [CPURL URLWithString:[source valueForAttribute:@"uuid"]];
            var comment = [source valueForAttribute:@"description"];
            
            var newSource = [TNVMCastSource VMCastSourceWithName:name UUID:uuid URL:url comment:comment];
            
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
                var status      = [appliance valueForAttribute:@"status"];

                var newCast     = [TNVMCast VMCastWithName:name URL:url comment:comment size:size pubDate:date UUID:uuid status:status];
                
                [[newSource content] addObject:newCast];
            }
            
            [_castsDatasource addSource:newSource];
        }
        [_mainOutlineView reloadData];
        [_mainOutlineView expandAll];
    }
    else if ([aStanza getType] == @"error")
    {
        var msg = [[aStanza firstChildWithName:@"error"] text];
        [CPAlert alertWithTitle:@"Error" message:msg];
    }
}

- (IBAction)download:(id)sender
{
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorVMCasting}];
    var selectedIndex   = [[ _mainOutlineView selectedRowIndexes] firstIndex];
    var item            = [_mainOutlineView itemAtRow:selectedIndex];
    var uuid            = [item UUID];
    
    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorVMCastingDownload, "uuid": uuid}];
    
    [self sendStanza:stanza andRegisterSelector:@selector(didDownload:)]
}

- (void)didDownload:(TNStropheStanza)aStanza
{
    [[self windowDownloadQueue] orderFront:nil];
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

- (IBAction)addNewVMCast:(id)sender
{
    var stanza      = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorVMCasting}];
    var url         = [fieldNewURL stringValue];
    
    [fieldNewURL setStringValue:@""];
    
    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorVMCastingRegister, "url": url}];

    [self sendStanza:stanza andRegisterSelector:@selector(didRegistred:)]
}

- (void)didRegistred:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"error")
    {
        var msg = [[aStanza firstChildWithName:@"error"] text];
        [CPAlert alertWithTitle:@"Error" message:msg];
    }
    else
        [self getVMCasts];
}

- (IBAction)removeVMCast:(id)sender
{
    if (([_mainOutlineView numberOfRows] == 0) || ([_mainOutlineView numberOfSelectedRows] <= 0))
    {
        [CPAlert alertWithTitle:@"Error" message:@"You must select a VMCast"];
        return;
    }

    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex];
    var currentVMCast   = [[_castsDatasource contents] objectAtIndex:selectedIndex];
    var uuid             = [currentVMCast UUID];
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeHypervisorVMCasting}];
    
    
    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeHypervisorVMCastingUnregister, "uuid": uuid}];

    [self sendStanza:stanza andRegisterSelector:@selector(didUnregistred:)]
}

- (void)didUnregistred:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"error")
    {
        var msg = [[aStanza firstChildWithName:@"error"] text];
        [CPAlert alertWithTitle:@"Error" message:msg];
    }
}
@end



