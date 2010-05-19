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

TNArchipelPushNotificationVMCasting                     = @"archipel:push:vmcasting";
    
/*! @defgroup  virtualmachinepackaging Module VirtualMachinePackaging
    @desc Allow to instanciate virtual machine from installed appliances
*/

/*! @ingroup virtualmachinepackaging
    main class of the module
*/
@implementation TNVirtualMachinePackaging : TNModule
{
    @outlet CPTextField                 fieldJID                    @accessors;
    @outlet CPTextField                 fieldName                   @accessors;
    @outlet CPScrollView                mainScrollView;
    @outlet CPSearchField               fieldFilterAppliance;
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPView                      viewTableContainer;
    
    CPTableView                         _tableAppliances;
    TNTableViewDataSource               _appliancesDatasource;
    
    CPButton    _instanciateButton;
    CPButton    _dettachButton;
}

- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#9e9e9e"];
    
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
    [_tableAppliances setDoubleAction:@selector(instanciate:)];
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
    [_tableAppliances setMenu:menu];
    
    _instanciateButton  = [CPButtonBar plusButton];
    [_instanciateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-combine.png"] size:CPSizeMake(16, 16)]];
    [_instanciateButton setTarget:self];
    [_instanciateButton setAction:@selector(instanciate:)];
    
    _dettachButton  = [CPButtonBar plusButton];
    [_dettachButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-decombine.png"] size:CPSizeMake(16, 16)]];
    [_dettachButton setTarget:self];
    [_dettachButton setAction:@selector(dettach:)];
    
    [_instanciateButton setEnabled:NO];
    [_dettachButton setEnabled:NO];
    [buttonBarControl setButtons:[_instanciateButton, _dettachButton]];
}

- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];   
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    
    [self registerSelector:@selector(didDownloadPushReceived:) forPushNotificationType:TNArchipelPushNotificationVMCasting];
    
    [_tableAppliances setDelegate:nil];
    [_tableAppliances setDelegate:self]; // hum....
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
    
    [self getInstalledAppliances];
}

- (void)willHide
{
    [super willHide];
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
    
    // if (sender != [_entity JID])
    //     return;
    
    if (change == @"applianceinstalled")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Appliance" message:"Appliance is installed"];
    }

    if ((change != "applianceunpacking") && (change != "applianceunpacked") && (change != @"appliancecopying"))
        [self getInstalledAppliances];

    return YES;
}

- (void)getInstalledAppliances
{
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineVMCasting}];

    [infoStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineVMCastingInstalledAppliances}];

    [_entity sendStanza:infoStanza andRegisterSelector:@selector(didReceiveInstalledAppliances:) ofObject:self];
    
    CPLog.info("I asked installed appliances");
}

- (void)didReceiveInstalledAppliances:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
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

    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex];
    var appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineVMCasting}];

    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineVMCastingInstall}];
    [stanza addChildName:@"uuid"];
    [stanza addTextNode:[appliance UUID]];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didInstallAppliance:) ofObject:self];
}

- (IBAction)dettach:(id)sender
{
    if (([_tableAppliances numberOfRows]) && ([_tableAppliances numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select an appliance"];
         return;
    }

    var selectedIndex   = [[_tableAppliances selectedRowIndexes] firstIndex];
    var appliance       = [_appliancesDatasource objectAtIndex:selectedIndex];
    
    if ([appliance statusString] != TNArchipelApplianceStatusInstalled)
        return;
    
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineVMCasting}];

    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineVMCastingDettach}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didDettachAppliance:) ofObject:self];
}


- (void)didInstallAppliance:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
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

- (void)didDettachAppliance:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {        
        var growl   = [TNGrowlCenter defaultCenter];
        var msg     = @"Appliance has been dettached";
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



