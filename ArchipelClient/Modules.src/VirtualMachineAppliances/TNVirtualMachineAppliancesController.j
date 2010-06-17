/*  
 * TNSampleTabModule.j
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

@import "TNInstalledAppliancesObject.j";

TNArchipelTypeVirtualMachineVMCasting                       = @"archipel:virtualmachine:vmcasting";

TNArchipelTypeVirtualMachineVMCastingInstalledAppliances    = @"getinstalledappliances";
TNArchipelTypeVirtualMachineVMCastingInstall                = @"install";
TNArchipelTypeVirtualMachineVMCastingDettach                = @"dettach";
TNArchipelTypeVirtualMachineVMCastingPackage                = @"package";

TNArchipelPushNotificationVMCasting                     = @"archipel:push:vmcasting";
    
/*! @defgroup  virtualmachinepackaging Module VirtualMachinePackaging
    @desc Allow to instanciate virtual machine from installed appliances
*/

/*! @ingroup virtualmachinepackaging
    main class of the module
*/
@implementation TNVirtualMachineAppliancesController : TNModule
{
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPScrollView                mainScrollView;
    @outlet CPSearchField               fieldFilterAppliance;
    @outlet CPTextField                 fieldJID;
    @outlet CPTextField                 fieldName;
    @outlet CPTextField                 fieldNewApplianceName;
    @outlet CPView                      maskingView;
    @outlet CPView                      viewTableContainer;
    @outlet CPWindow                    windowNewAppliance;
    
    CPButton                            _dettachButton;
    CPButton                            _instanciateButton;
    CPButton                            _packageButton;
    CPTableView                         _tableAppliances;
    TNTableViewDataSource               _appliancesDatasource;
}

- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];
    [fieldJID setSelectable:YES];
    
    // Media table view
    _appliancesDatasource    = [[TNTableViewDataSource alloc] init];
    _tableAppliances         = [[CPTableView alloc] initWithFrame:[mainScrollView bounds]];

    var bundle = [CPBundle bundleForClass:[self class]];
    
    [mainScrollView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setDocumentView:_tableAppliances];

    [_tableAppliances setUsesAlternatingRowBackgroundColors:YES];
    [_tableAppliances setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableAppliances setAllowsColumnReordering:YES];
    [_tableAppliances setAllowsColumnResizing:YES];
    [_tableAppliances setTarget:self];
    [_tableAppliances setDoubleAction:@selector(tableDoubleClicked:)];
    [_tableAppliances setAllowsEmptySelection:YES];
    [_tableAppliances setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    
    var columnName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [columnName setWidth:200]
    [[columnName headerView] setStringValue:@"Name"];
    [columnName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];
    
    var columnComment = [[CPTableColumn alloc] initWithIdentifier:@"comment"];
    [columnComment setWidth:250];
    [[columnComment headerView] setStringValue:@"Comment"];
    [columnComment setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"comment" ascending:YES]];
    
    var columnUUID = [[CPTableColumn alloc] initWithIdentifier:@"UUID"];
    [[columnUUID headerView] setStringValue:@"UUID"];
    [columnUUID setWidth:250];
    [columnUUID setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"UUID" ascending:YES]];
    
    var columnStatus    = [[CPTableColumn alloc] initWithIdentifier:@"status"];
    var imgView         = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [columnStatus setDataView:imgView];
    [columnStatus setWidth:16];
    [[columnStatus headerView] setStringValue:@" "];
    
    [_tableAppliances addTableColumn:columnStatus];
    [_tableAppliances addTableColumn:columnName];
    [_tableAppliances addTableColumn:columnComment];
    //[_tableAppliances addTableColumn:columnUUID];

    [_appliancesDatasource setTable:_tableAppliances];
    [_appliancesDatasource setSearchableKeyPaths:[@"name", @"path", @"comment"]]
    
    [_tableAppliances setDataSource:_appliancesDatasource];
    
    [fieldFilterAppliance setTarget:_appliancesDatasource];
    [fieldFilterAppliance setAction:@selector(filterObjects:)];
    
    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:@"Install" action:@selector(instanciate:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Dettach" action:@selector(dettach:) keyEquivalent:@""];
    [_tableAppliances setMenu:menu];
    
    _packageButton      = [CPButtonBar plusButton];
    [_packageButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-package.png"] size:CPSizeMake(16, 16)]];
    [_packageButton setTarget:self];
    [_packageButton setAction:@selector(openNewApplianceWindow:)];
    
    
    _instanciateButton  = [CPButtonBar plusButton];
    [_instanciateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-lock.png"] size:CPSizeMake(16, 16)]];
    [_instanciateButton setTarget:self];
    [_instanciateButton setAction:@selector(instanciate:)];
    
    _dettachButton  = [CPButtonBar plusButton];
    [_dettachButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-unlock.png"] size:CPSizeMake(16, 16)]];
    [_dettachButton setTarget:self];
    [_dettachButton setAction:@selector(dettach:)];
    
    [_instanciateButton setEnabled:NO];
    [_dettachButton setEnabled:NO];
    [buttonBarControl setButtons:[_instanciateButton, _dettachButton, _packageButton]];
}

- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];   
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [self registerSelector:@selector(didDownloadPushReceived:) forPushNotificationType:TNArchipelPushNotificationVMCasting];
    
    [_tableAppliances setDelegate:nil];
    [_tableAppliances setDelegate:self]; // hum....
    
    [self getInstalledAppliances];
}

- (void)willUnload
{
    [super willUnload];
    
    [_appliancesDatasource removeAllObjects];
    [_tableAppliances reloadData];
}

- (void)willShow
{
    [super willShow];

    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    
    [self checkIfRunning];
}

- (void)willHide
{
    [super willHide];
}

- (void)checkIfRunning
{
    if ([_entity status] == TNStropheContactStatusBusy)
    {
        [maskingView removeFromSuperview];
    }
    else
    {
        [maskingView setFrame:[[self view] bounds]];
        [[self view] addSubview:maskingView];
    }
}

- (void)didPresenceUpdated:(CPNotification)aNotification
{
    [self checkIfRunning];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

- (BOOL)didDownloadPushReceived:(TNStropheStanza)aStanza
{
    var sender = [aStanza getFromNode].split("/")[0];
    var change = [aStanza valueForAttribute:@"change"];
    
    CPLog.info("receiving push notification TNArchipelPushNotificationVMCast with change " + change);
    
    if (change == @"applianceinstalled")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Appliance" message:"Appliance is installed"];
    }

    if ((change != "applianceunpacking") && (change != "applianceunpacked") && (change != @"appliancecopying"))
        [self getInstalledAppliances];

    return YES;
}

- (IBAction)openNewApplianceWindow:(id)sender
{
    [fieldNewApplianceName setStringValue:[CPString UUID]];
    [windowNewAppliance makeFirstResponder:fieldNewApplianceName];
    [windowNewAppliance makeKeyAndOrderFront:nil];
}

- (IBAction)tableDoubleClicked:(id)sender
{
    if ([_tableAppliances numberOfSelectedRows] <= 0)
        return;
    
    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex];
    var appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];
    
    if ([appliance statusString] == TNArchipelApplianceStatusInstalled)
        [self dettach:sender];
    else
        [self instanciate:sender];
    
}

- (void)getInstalledAppliances
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeVirtualMachineVMCasting, 
        "action": TNArchipelTypeVirtualMachineVMCastingInstalledAppliances}];
        
    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveInstalledAppliances:) ofObject:self];
}

- (void)didReceiveInstalledAppliances:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
    {
        [_appliancesDatasource removeAllObjects];

        var appliances = [aStanza childrenWithName:@"appliance"];

        for (var i = 0; i < [appliances count]; i++)
        {
            var appliance   = [appliances objectAtIndex:i];
            var name        = [appliance valueForAttribute:@"name"];
            var comment     = [appliance valueForAttribute:@"description"];
            var path        = [appliance valueForAttribute:@"path"];
            var uuid        = [appliance valueForAttribute:@"uuid"];
            var status      = [appliance valueForAttribute:@"status"]

            var newAppliance = [TNInstalledAppliance InstalledApplianceWithName:name UUID:uuid path:path comment:comment status:status];
            [_appliancesDatasource addObject:newAppliance];
        }
        [_tableAppliances reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}



- (IBAction)instanciate:(id)sender
{
    if (([_tableAppliances numberOfRows]) && ([_tableAppliances numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select an appliance"];
         return;
    }
    
    var alert = [TNAlert alertWithTitle:@"Instanciate appliance"
                                message:@"Are you sure you want to instanciate this appliance? This will reset all your virtual machine."
                                delegate:self
                                 actions:[["Instanciate", @selector(performInstanciate:)], ["Cancel", nil]]];
    [alert runModal];
    
}

- (void)performInstanciate:(id)someUserInfo
{
    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex];
    var appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];
    var stanza          = [TNStropheStanza iqWithType:@"set"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeVirtualMachineVMCasting, 
        "action": TNArchipelTypeVirtualMachineVMCastingInstall,
        "uuid": [appliance UUID]}];

    [_instanciateButton setEnabled:NO];
    [_entity sendStanza:stanza andRegisterSelector:@selector(didInstanciate:) ofObject:self];
}

- (void)didInstanciate:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
    {        
        var growl   = [TNGrowlCenter defaultCenter];
        var msg     = @"Instanciation has started";
        [growl pushNotificationWithTitle:@"Appliance" message:msg];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)dettach:(id)sender
{
    if (([_tableAppliances numberOfRows]) && ([_tableAppliances numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select an appliance"];
         return;
    }
    
    var alert = [TNAlert alertWithTitle:@"Detach from appliance"
                                message:@"Are you sure you want to detach virtual machine from this appliance?"
                                delegate:self
                                 actions:[["Detach", @selector(performDettach:)], ["Cancel", nil]]];
    [alert runModal];
}

- (void)performDettach:(id)someUserInfo
{
    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex];
    var appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];
    
    if ([appliance statusString] != TNArchipelApplianceStatusInstalled)
        return;
    
    var stanza          = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeVirtualMachineVMCasting, 
        "action": TNArchipelTypeVirtualMachineVMCastingDettach}];    

    [_dettachButton setEnabled:NO];
    [_entity sendStanza:stanza andRegisterSelector:@selector(didDettachAppliance:) ofObject:self];
}

- (void)didDettachAppliance:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
    {        
        var growl   = [TNGrowlCenter defaultCenter];
        var msg     = @"Appliance has been dettached";
        [growl pushNotificationWithTitle:@"Appliance" message:msg];
        
        [_instanciateButton setEnabled:YES];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)package:(id)sender
{
    if ([_entity status] != TNStropheContactStatusBusy)
    {
         [CPAlert alertWithTitle:@"Error" message:@"Virtual machine must not be running to package it."];
         return;
    }
    
    var stanza  = [TNStropheStanza iqWithType:@"get"];
    var name    = [fieldNewApplianceName stringValue];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineVMCasting}];
    [stanza addChildName:@"archipel" withAttributes:{
        "xmlns": TNArchipelTypeVirtualMachineVMCasting, 
        "action": TNArchipelTypeVirtualMachineVMCastingPackage,
        "name": name}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didPackageAppliance:) ofObject:self];
    
    [windowNewAppliance close];
}

- (void)didPackageAppliance:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"result")
    {        
        var growl   = [TNGrowlCenter defaultCenter];
        var msg     = @"Virtual machine has been packaged";
        [growl pushNotificationWithTitle:@"Appliance" message:msg];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (void)tableViewSelectionDidChange:(CPTableView)aTableView
{
    [_instanciateButton setEnabled:NO];
    [_dettachButton setEnabled:NO];
    
    if ([_tableAppliances numberOfSelectedRows] <= 0)
        return;
    
    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex];
    var appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];
    
    if ([appliance statusString] == TNArchipelApplianceStatusInstalled)
        [_dettachButton setEnabled:YES];
    else
        [_instanciateButton setEnabled:YES];
    
}


@end



