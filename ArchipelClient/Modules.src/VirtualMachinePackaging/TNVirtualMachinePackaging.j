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

@import "TNInstalledAppliancesDatasource.j";

TNArchipelTypeVirtualMachineVMCasting                       = @"archipel:virtualmachine:vmcasting";

TNArchipelTypeVirtualMachineVMCastingInstalledAppliances    = @"getinstalledappliances";
TNArchipelTypeVirtualMachineVMCastingInstall                = @"install";

TNArchipelPushNotificationVMCasting                     = @"archipel:push:vmcasting";
    
/*! @defgroup  virtualmachinepackaging Module VirtualMachinePackaging
    @desc Allow to instanciate virtual machine from installed appliances
*/

/*! @ingroup virtualmachinepackaging
    main class of the module
*/
@implementation TNVirtualMachinePackaging : TNModule
{
    @outlet CPTextField                 fieldJID                @accessors;
    @outlet CPTextField                 fieldName               @accessors;
    
    @outlet CPScrollView                mainScrollView;
    
    CPTableView                         _tableAppliances;
    TNInstalledAppliancesDatasource     _appliancesDatasource;
    
}

- (void)awakeFromCib
{
    // Media table view
    _appliancesDatasource    = [[TNInstalledAppliancesDatasource alloc] init];
    _tableAppliances         = [[CPTableView alloc] initWithFrame:[mainScrollView bounds]];

    [mainScrollView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setDocumentView:_tableAppliances];
    [mainScrollView setBorderedWithHexColor:@"#9e9e9e"];

    [_tableAppliances setUsesAlternatingRowBackgroundColors:YES];
    [_tableAppliances setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableAppliances setAllowsColumnReordering:YES];
    [_tableAppliances setAllowsColumnResizing:YES];
    [_tableAppliances setAllowsEmptySelection:YES];
    [_tableAppliances setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    
    var columnName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [columnName setWidth:200]
    [[columnName headerView] setStringValue:@"Name"];

    var columnComment = [[CPTableColumn alloc] initWithIdentifier:@"comment"];
    [columnComment setWidth:250];
    [[columnComment headerView] setStringValue:@"Comment"];
    
    var columnUUID = [[CPTableColumn alloc] initWithIdentifier:@"UUID"];
    [[columnUUID headerView] setStringValue:@"UUID"];

    [_tableAppliances addTableColumn:columnName];
    [_tableAppliances addTableColumn:columnComment];
    [_tableAppliances addTableColumn:columnUUID];


    [_tableAppliances setDataSource:_appliancesDatasource];
}

- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];   
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:[self entity]];
    
    [self registerSelector:@selector(didDownloadPushReceived:) forPushNotificationType:TNArchipelPushNotificationVMCasting];
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
    
    [self getInstalledAppliances];
}

- (void)willHide
{
    [super willHide];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == [self entity])
    {
       [[self fieldName] setStringValue:[[self entity] nickname]]
    }
}

- (BOOL)didDownloadPushReceived:(TNStropheStanza)aStanza
{
    CPLog.info("receiving push notification TNArchipelPushNotificationVMCast");
    [self getInstalledAppliances];
    
    return YES;
}

- (void)getInstalledAppliances
{
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineVMCasting}];

    [infoStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineVMCastingInstalledAppliances}];

    [[self entity] sendStanza:infoStanza andRegisterSelector:@selector(didReceiveInstalledAppliances:) ofObject:self];
}

- (void)didReceiveInstalledAppliances:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
        [[_appliancesDatasource content] removeAllObjects];

        var appliances = [aStanza childrenWithName:@"appliance"];

        for (var i = 0; i < [appliances count]; i++)
        {
            var appliance   = [appliances objectAtIndex:i];
            var name        = [appliance valueForAttribute:@"name"];
            var comment     = [appliance valueForAttribute:@"description"];
            var path        = [appliance valueForAttribute:@"path"];
            var uuid        = [appliance valueForAttribute:@"uuid"];

            var newAppliance = [TNInstalledAppliance InstalledApplianceWithName:name UUID:uuid path:path comment:comment];
            [_appliancesDatasource addInstalledAppliance:newAppliance];
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
    var appliance       = [[_appliancesDatasource content] objectAtIndex:selectedIndex];
    var stanza          = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineVMCasting}];

    [stanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineVMCastingInstall}];
    [stanza addChildName:@"uuid"];
    [stanza addTextNode:[appliance UUID]];

    [[self entity] sendStanza:stanza andRegisterSelector:@selector(didInstallAppliance:) ofObject:self];
}

- (void)didInstallAppliance:(TNStropheStanza)aStanza
{
    if ([aStanza getType] == @"success")
    {
         [CPAlert alertWithTitle:@"GOOF" message:@"GOOD"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

@end



