/*  
 * TNVMCasting.j
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
@import "TNCellApplianceStatus.j";
@import "TNDownoadObject.j";

TNArchipelVMCastsOpenedVMCasts                      = @"TNArchipelVMCastsOpenedVMCasts_";
TNArchipelTypeHypervisorVMCasting                   = @"archipel:hypervisor:vmcasting"
TNArchipelTypeHypervisorVMCastingGet                = @"get";
TNArchipelTypeHypervisorVMCastingRegister           = @"register";
TNArchipelTypeHypervisorVMCastingUnregister         = @"unregister";
TNArchipelTypeHypervisorVMCastingDownload           = @"downloadappliance";
TNArchipelTypeHypervisorVMCastingDeleteAppliance    = @"deleteappliance";

TNArchipelPushNotificationVMCasting      = @"archipel:push:vmcasting";
// TNArchipelPushNotificationSubscriptionAdded = @"downloaded";

/*! @defgroup  templatingmodule Module Templating
    
    @desc This module manages XVM2 templating system
*/


/*! @ingroup templatingmodule
    templating module implementation
*/
@implementation TNHypervisorVMCastsController : TNModule
{
    @outlet CPTextField         fieldJID;
    @outlet CPTextField         fieldName;
    @outlet CPTextField         fieldNewURL;
    @outlet CPCheckBox          checkBoxOnlyInstalled;
    @outlet CPSearchField       fieldFilter;
    @outlet CPScrollView        mainScrollView;
    @outlet CPProgressIndicator downloadIndicator;
    @outlet CPWindow            windowDownloadQueue;
    @outlet CPWindow            windowNewCastURL;
    @outlet CPButtonBar         buttonBarControl;
    @outlet CPView              viewTableContainer;
    
    CPOutlineView               _mainOutlineView;
    TNVMCastDatasource          _castsDatasource;
    CPButton                    _plusButton;
    CPButton                    _minusButton;
    CPButton                    _downloadButton;
    CPButton                    _downloadQueueButton;
}

- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];
    
    [fieldNewURL setValue:[CPColor grayColor] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];
    _castsDatasource = [[TNVMCastDatasource alloc] init];
    
    _mainOutlineView = [[CPOutlineView alloc] initWithFrame:[mainScrollView bounds]];
    [_mainOutlineView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainOutlineView setAllowsColumnResizing:YES];
    [_mainOutlineView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_mainOutlineView setDataSource:_castsDatasource];
    
    var columnName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[columnName headerView] setStringValue:@"VMCasts"];
    [columnName setWidth:300];
    [columnName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    var columnDescription = [[CPTableColumn alloc] initWithIdentifier:@"comment"];
    [[columnDescription headerView] setStringValue:@"Comment"];
    [columnDescription setWidth:250];
    [columnDescription setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"comment" ascending:YES]];
    
    var columnUrl = [[CPTableColumn alloc] initWithIdentifier:@"URL"];
    [[columnUrl headerView] setStringValue:@"URL"];
    [columnUrl setWidth:250];
    [columnUrl setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"URL" ascending:YES]];
    
    var columnSize = [[CPTableColumn alloc] initWithIdentifier:@"size"];
    [[columnSize headerView] setStringValue:@"Size"];
    [columnSize setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"size" ascending:YES]];
    
    var columnStatus        = [[CPTableColumn alloc] initWithIdentifier:@"status"];
    [columnStatus setWidth:120];
    var dataViewPrototype   = [[TNCellApplianceStatus alloc] init];
    [[columnStatus headerView] setStringValue:@"Status"];
    [[columnStatus setDataView:dataViewPrototype]];
    
    [_mainOutlineView setOutlineTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnSize];
    [_mainOutlineView addTableColumn:columnStatus];
    [_mainOutlineView addTableColumn:columnDescription];
    //[_mainOutlineView addTableColumn:columnUrl]
    

    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setDocumentView:_mainOutlineView];
    [_mainOutlineView reloadData];
    [_mainOutlineView recoverExpandedWithBaseKey:TNArchipelVMCastsOpenedVMCasts itemKeyPath:@"name"];
    
    [_mainOutlineView setTarget:self];
    [_mainOutlineView setDoubleAction:@selector(download:)];
    
    // filter field
    [fieldFilter setSendsSearchStringImmediately:YES];
    [fieldFilter setTarget:self];
    [fieldFilter setAction:@selector(fieldFilterDidChange:)];
    
    
    // menuBar
    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(openNewVMCastURLWindow:)];
    
    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(remove:)];
    
    _downloadButton = [CPButtonBar plusButton];
    [_downloadButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-download.png"] size:CPSizeMake(16, 16)]];
    [_downloadButton setTarget:self];
    [_downloadButton setAction:@selector(download:)];
    
    _downloadQueueButton = [CPButtonBar plusButton];
    [_downloadQueueButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-view.png"] size:CPSizeMake(16, 16)]];
    [_downloadQueueButton setTarget:self];
    [_downloadQueueButton setAction:@selector(showDownloadQueue:)];
    
    [_minusButton setEnabled:NO];
    [_downloadButton setEnabled:NO];
    
    [buttonBarControl setButtons:[_plusButton, _minusButton, _downloadButton, _downloadQueueButton]];
}

- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];
    
    [windowDownloadQueue setEntity:_entity];
    //[_mainOutlineView setDelegate:nil];
    [_mainOutlineView setDelegate:self];
    
    [self registerSelector:@selector(didPushReceive:) forPushNotificationType:TNArchipelPushNotificationVMCasting];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [self getVMCasts];
}

- (void)willUnload
{
    [super willUnload];
    
    [windowDownloadQueue orderOut:nil];
    [windowNewCastURL orderOut:nil];
    
    [_mainOutlineView deselectAll];
}

- (void)willShow
{
    [super willShow];
    
    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
}

- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}



- (IBAction)fieldFilterDidChange:(id)sender
{
    [_castsDatasource setFilter:[sender stringValue]];
    [_mainOutlineView reloadData];
}

- (IBAction)openNewVMCastURLWindow:(id)sender
{
    [fieldNewURL setStringValue:@""];
    [windowNewCastURL makeKeyAndOrderFront:nil];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    [fieldName setStringValue:[_entity nickname]] 
}

- (BOOL)didPushReceive:(TNStropheStanza)aStanza
{
    var sender  = [aStanza getFromNode];
    var type    = [[aStanza firstChildWithName:@"x"] valueForAttribute:@"xmlns"];
    var change  = [[aStanza firstChildWithName:@"x"] valueForAttribute:@"change"];
    CPLog.info("PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);
    
    [self getVMCasts];
    
    if (change == @"download_complete")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Appliance" message:@"Download complete"];
    }
    return YES;
}


- (void)getVMCasts
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingGet}];

    [self sendStanza:stanza andRegisterSelector:@selector(didReceivedVMCasts:)];
}

- (void)didReceivedVMCasts:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
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
                var status      = parseInt([appliance valueForAttribute:@"status"]);

                var newCast     = [TNVMCast VMCastWithName:name URL:url comment:comment size:size pubDate:date UUID:uuid status:status];
                
                [[newSource content] addObject:newCast];
            }
            
            [_castsDatasource addSource:newSource];
        }
        [_mainOutlineView reloadData];
        [_mainOutlineView recoverExpandedWithBaseKey:TNArchipelVMCastsOpenedVMCasts itemKeyPath:@"name"];
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}



- (void)updateDownloadProgress:(CPTimer)aTimer
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingDownloadProgress}];
        
    [_entity sendStanza:stanza andRegisterSelector:@selector(didDownloadProgress:) ofObject:self];
}

- (void)didDownloadProgress:(TNStropheStanza)aStanza
{

}



- (IBAction)addNewVMCast:(id)sender
{
    [windowNewCastURL orderOut:nil];
    
    var stanza      = [TNStropheStanza iqWithType:@"set"];
    var url         = [fieldNewURL stringValue];
    
    [fieldNewURL setStringValue:@""];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingRegister,
        "url": url}];

    [self sendStanza:stanza andRegisterSelector:@selector(didAddNewVMCast:)];
}

- (void)didAddNewVMCast:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"VMCast" message:@"VMcast has been registred"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)remove:(id)sender
{
    if (([_mainOutlineView numberOfRows] == 0) || ([_mainOutlineView numberOfSelectedRows] <= 0))
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"VMCast" message:@"You must select a VMCast or an Appliance" icon:TNGrowlIconError];
        
        return;
    }
    
    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex];
    var currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex];
    
    if ([currentVMCast class] == TNVMCast)
        [self removeAppliance:sender];
    else if ([currentVMCast class] == TNVMCastSource)
        [self removeVMCast:sender];
}


- (IBAction)removeAppliance:(id)sender
{
    var alert = [TNAlert alertWithTitle:@"Delete appliance"
                                message:@"Are you sure you want to remove this appliance? This doesn't affect virtual machine that have been instanciated from this template."
                                delegate:self
                                 actions:[["Delete", @selector(performRemoveAppliance:)], ["Cancel", nil]]];

    [alert runModal];
}

- (void)performRemoveAppliance:(id)someUserInfo
{
    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex];
    var currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex];
    var uuid            = [currentVMCast UUID];
    var stanza          = [TNStropheStanza iqWithType:@"set"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingDeleteAppliance,
        "uuid": uuid}];

    [self sendStanza:stanza andRegisterSelector:@selector(didDeleteAppliance:)];
}

- (void)didDeleteAppliance:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Appliance" message:@"Appliance has been uninstalled"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)removeVMCast:(id)someUserInfo
{
    var alert = [TNAlert alertWithTitle:@"Delete VMCast"
                                message:@"Are you sure you want to unregister fro this VMCast? All its appliances will be deleted."
                                delegate:self
                                 actions:[["Unregister", @selector(performRemoveVMCast:)], ["Cancel", nil]]];

    [alert runModal];
}

- (void)performRemoveVMCast:(id)someUserInfo
{
    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex];
    var currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex];
    var uuid            = [currentVMCast UUID];
    var stanza          = [TNStropheStanza iqWithType:@"set"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingUnregister,
        "uuid": uuid}];


    [self sendStanza:stanza andRegisterSelector:@selector(didUnregistred:)]
}

- (void)didUnregistred:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"VMCast" message:@"VMcast has been unregistred"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)download:(id)sender
{
    var selectedIndex   = [[ _mainOutlineView selectedRowIndexes] firstIndex];
    var item            = [_mainOutlineView itemAtRow:selectedIndex];
    
    if (([item status] != TNArchipelApplianceNotInstalled) && ([item status] != TNArchipelApplianceInstallationError))
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"VMCast" message:@"Appliance is already downloaded. If you want to instanciante it, create a new Virtual Machine and choose Packaging module." icon:TNGrowlIconError];
        
        return;
    }
    
    var alert = [TNAlert alertWithTitle:@"Download"
                                message:@"Are you sure you want to download this appliance?"
                                delegate:self
                                 actions:[["Download", @selector(performDownload:)], ["Cancel", nil]]];

    [alert runModal];
}

- (void)performDownload:(id)someUserInfo
{
    var selectedIndex   = [[ _mainOutlineView selectedRowIndexes] firstIndex];
    var item            = [_mainOutlineView itemAtRow:selectedIndex];
    var uuid            = [item UUID];
    
    var stanza  = [TNStropheStanza iqWithType:@"set"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingDownload,
        "uuid": uuid}];

    [self sendStanza:stanza andRegisterSelector:@selector(didDownload:)]
}

- (void)didDownload:(TNStropheStanza)aStanza
{
    [windowDownloadQueue orderFront:nil];
}


- (IBAction)showDownloadQueue:(id)sender
{
    [windowNewCastURL setTitle:@"Download queue for " + [_entity nickname]];
    [windowDownloadQueue makeKeyAndOrderFront:nil];
}


- (IBAction)fieldFilterDidChange:(id)sender
{
    [_castsDatasource setFilter:[sender stringValue]];
    [_mainOutlineView reloadData];
}

- (IBAction)clickOnFilterCheckBox:(id)sender
{
    if ([sender state] == CPOnState)
        [_castsDatasource setFilterInstalled:YES];
    else
        [_castsDatasource setFilterInstalled:NO];
        
    [_mainOutlineView reloadData];
    [_mainOutlineView recoverExpandedWithBaseKey:TNArchipelVMCastsOpenedVMCasts itemKeyPath:@"name"];
}



- (void)outlineViewSelectionDidChange:(CPNotification)aNotification
{
    [_minusButton setEnabled:NO];
    [_downloadButton setEnabled:NO];
    
    if ([_mainOutlineView numberOfSelectedRows] > 0)
    {
        var selectedIndexes = [_mainOutlineView selectedRowIndexes];
        var object          = [_mainOutlineView itemAtRow:[selectedIndexes firstIndex]];
        
        if ([object class] == TNVMCast)
        {
            [_downloadButton setEnabled:(([object status] == TNArchipelApplianceNotInstalled) || ([object status] == TNArchipelApplianceInstallationError))];
            [_minusButton setEnabled:([object status] == TNArchipelApplianceInstalled)];
        }
        else if ([object class] == TNVMCastSource)
        {
            [_minusButton setEnabled:YES];
            [_downloadButton setEnabled:NO];
        } 
    }
}


- (void)outlineViewItemWillExpand:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"];
    var defaults    = [TNUserDefaults standardUserDefaults];
    var key         = TNArchipelVMCastsOpenedVMCasts + [item name];

    [defaults setObject:"expanded" forKey:key];
}

- (void)outlineViewItemWillCollapse:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"];
    var defaults    = [TNUserDefaults standardUserDefaults];
    var key         = TNArchipelVMCastsOpenedVMCasts + [item name];

    [defaults setObject:"collapsed" forKey:key];
}

@end



