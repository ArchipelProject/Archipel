/*  
 * TNViewHypervisorControl.j
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
 
@import "TNDatasourceNetworkInterfaces.j"
@import "TNDatasourceDrives.j"
@import "TNPanelNicEdition.j";
@import "TNPanelDriveEdition.j";

trinityTypeVirtualMachineControl            = @"trinity:vm:control";
trinityTypeVirtualMachineDefinition         = @"trinity:vm:definition";

trinityTypeVirtualMachineControlXMLDesc         = @"xmldesc";
trinityTypeVirtualMachineDefinitionDefine       = @"define";
trinityTypeVirtualMachineDefinitionUndefine     = @"undefine";


@implementation TNVirtualMachineDefinition : TNModule 
{
    @outlet CPScrollView        scrollViewForNics       @accessors;
    @outlet CPScrollView        scrollViewForDrives     @accessors;
    @outlet CPTextField         fieldMemory             @accessors;
    @outlet CPPopUpButton       buttonNumberCPUs        @accessors;
    @outlet CPPopUpButton       buttonBoot              @accessors;
    @outlet CPButton            buttonAddNic            @accessors;
    @outlet CPButton            buttonDelNic            @accessors;
    @outlet TNPanelNicEdition   panelNicEdition         @accessors;
    @outlet TNPanelDriveEdition panelDriveEdition       @accessors;
    
    CPTableView                     tableNetworkCards   @accessors;
    TNDatasourceNetworkInterfaces   nicsDatasource      @accessors;
    CPTableView                     tableDrives         @accessors;
    TNDatasourceDrives              drivesDatasource    @accessors;
    id                              virtualMachineXML   @accessors;
}

- (void)awakeFromCib
{
    
    //drives
    drivesDatasource    = [[TNDatasourceDrives alloc] init];
    tableDrives         = [[CPTableView alloc] initWithFrame:[[self scrollViewForDrives] bounds]];
    
    [[self scrollViewForDrives] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewForDrives] setAutohidesScrollers:YES];
    [[self scrollViewForDrives] setDocumentView:[self tableDrives]];
    
    [[self tableDrives] setUsesAlternatingRowBackgroundColors:YES];
    [[self tableDrives] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self tableDrives] setAllowsColumnReordering:YES];
    [[self tableDrives] setAllowsColumnResizing:YES];
    [[self tableDrives] setAllowsEmptySelection:YES];
    [[self tableDrives] setTarget:self];
    [[self tableDrives] setDoubleAction:@selector(editDrive:)];
    
    var driveColumnType = [[CPTableColumn alloc] initWithIdentifier:@"type"];
    [driveColumnType setResizingMask:CPTableColumnAutoresizingMask ];
    [driveColumnType setEditable:YES];
    [[driveColumnType headerView] setStringValue:@"Type"];

    var driveColumnDevice = [[CPTableColumn alloc] initWithIdentifier:@"device"];
    [driveColumnDevice setResizingMask:CPTableColumnAutoresizingMask ];
    [driveColumnDevice setEditable:YES];
    [[driveColumnDevice headerView] setStringValue:@"Device"];

    var driveColumnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"];
    [driveColumnSource setResizingMask:CPTableColumnAutoresizingMask ];
    [driveColumnSource setWidth:400];
    [driveColumnSource setEditable:YES];
    [[driveColumnSource headerView] setStringValue:@"Source"];

    var driveColumnTarget = [[CPTableColumn alloc] initWithIdentifier:@"target"];
    [driveColumnTarget setResizingMask:CPTableColumnAutoresizingMask ];
    [driveColumnTarget setEditable:YES];
    [[driveColumnTarget headerView] setStringValue:@"Target"];
    
    var driveColumnBus = [[CPTableColumn alloc] initWithIdentifier:@"bus"];
    [driveColumnBus setResizingMask:CPTableColumnAutoresizingMask ];
    [driveColumnBus setEditable:YES];
    [[driveColumnBus headerView] setStringValue:@"Bus"];
    
    [[self tableDrives] addTableColumn:driveColumnType];
    [[self tableDrives] addTableColumn:driveColumnDevice];
    [[self tableDrives] addTableColumn:driveColumnTarget];
    [[self tableDrives] addTableColumn:driveColumnBus];
    [[self tableDrives] addTableColumn:driveColumnSource];
    
    [[self tableDrives] setDataSource:[self drivesDatasource]];
    
    
    
    // NICs
    nicsDatasource      = [[TNDatasourceNetworkInterfaces alloc] init];
    tableNetworkCards   = [[CPTableView alloc] initWithFrame:[[self scrollViewForNics] bounds]];
    
    [[self scrollViewForNics] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewForNics] setDocumentView:[self tableNetworkCards]];
    [[self scrollViewForNics] setAutohidesScrollers:YES];
    
    [[self tableNetworkCards] setUsesAlternatingRowBackgroundColors:YES];
    [[self tableNetworkCards] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self tableNetworkCards] setAllowsColumnReordering:YES];
    [[self tableNetworkCards] setAllowsColumnResizing:YES];
    [[self tableNetworkCards] setAllowsEmptySelection:YES];
    [[self tableNetworkCards] setTarget:self];
    [[self tableNetworkCards] setDoubleAction:@selector(editNetworkCard:)];
    
    var columnName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [columnName setResizingMask:CPTableColumnAutoresizingMask ];
    [columnName setEditable:YES];
    [[columnName headerView] setStringValue:@"Name"];

    var columnType = [[CPTableColumn alloc] initWithIdentifier:@"type"];
    [columnType setResizingMask:CPTableColumnAutoresizingMask ];
    [columnType setEditable:YES];
    [[columnType headerView] setStringValue:@"Type"];

    var columnModel = [[CPTableColumn alloc] initWithIdentifier:@"model"];
    [columnModel setResizingMask:CPTableColumnAutoresizingMask ];
    [columnModel setEditable:YES];
    [[columnModel headerView] setStringValue:@"Model"];
    
    var columnMac = [[CPTableColumn alloc] initWithIdentifier:@"mac"];
    [columnMac setResizingMask:CPTableColumnAutoresizingMask];
    [columnMac setEditable:YES];
    [columnMac setWidth:150];
    [[columnMac headerView] setStringValue:@"MAC"];

    var columnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"];
    [columnSource setResizingMask:CPTableColumnAutoresizingMask ];
    [columnSource setEditable:YES];
    [[columnSource headerView] setStringValue:@"Source"];

    var columnTarget = [[CPTableColumn alloc] initWithIdentifier:@"target"];
    [columnTarget setResizingMask:CPTableColumnAutoresizingMask ];
    [columnTarget setEditable:YES];
    [[columnTarget headerView] setStringValue:@"Target"];
    
    [[self tableNetworkCards] addTableColumn:columnName];
    [[self tableNetworkCards] addTableColumn:columnSource];
    [[self tableNetworkCards] addTableColumn:columnType];
    [[self tableNetworkCards] addTableColumn:columnModel];
    [[self tableNetworkCards] addTableColumn:columnTarget];
    [[self tableNetworkCards] addTableColumn:columnMac];

    [[self tableNetworkCards] setDataSource:[self nicsDatasource]];
    
    
    // others..
    [[self buttonBoot] removeAllItems];
    [[self buttonNumberCPUs] removeAllItems];
    
    var bootTypes = ["Hard Drive", "CD-Rom"];
    for (var i = 0; i < bootTypes.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:bootTypes[i] action:nil keyEquivalent:nil];
        [[self buttonBoot] addItem:item];
    }
    
    for (var i = 1; i < 5; i++)
    {
        var n = "" + i + "";
        var item = [[CPMenuItem alloc] initWithTitle:n action:nil keyEquivalent:nil];
        [[self buttonNumberCPUs] addItem:item];
    }
}


- (void)willBeDisplayed
{
    // message sent when view will be added from superview;
    // MUST be declared
}

- (void)willBeUnDisplayed
{
   // message sent when view will be removed from superview;
   // MUST be declared
}

- (void)initializeWithContact:(TNStropheContact)aContact andRoster:(TNStropheRoster)aRoster
{
    [super initializeWithContact:aContact andRoster:aRoster]
    
    [self getXMLDesc];
    // do killers stuff
}


- (void)getXMLDesc
{
    var uid = [[[self contact] connection] getUniqueId];
    var xmldescStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControlXMLDesc, "to": [[self contact] fullJID], "id": uid}];
    var params;
        
    [xmldescStanza addChildName:@"query" withAttributes:{"xmlns" : trinityTypeVirtualMachineControl}];
    
    params= [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    [[[self contact] connection] registerSelector:@selector(didReceiveXMLDesc:) ofObject:self withDict:params];
    [[[self contact] connection] send:[xmldescStanza stanza]];
}

- (void)didReceiveXMLDesc:(id)aStanza 
{   
    var xmlDesc     = aStanza.getElementsByTagName("domain")[0];
    var memory      = $(xmlDesc.getElementsByTagName("currentMemory")[0]).text();
    var vcpu        = $(xmlDesc.getElementsByTagName("vcpu")[0]).text();
    var boot        = xmlDesc.getElementsByTagName("boot")[0].getAttribute("dev");
    var interfaces  = xmlDesc.getElementsByTagName("interface");
    var disks       = xmlDesc.getElementsByTagName("disk");
    
    [[self fieldMemory] setStringValue:(parseInt(memory) / 1024)];
    [[self buttonNumberCPUs] selectItemWithTitle:vcpu];
    
    if (boot == "cdrom")
        [[self buttonBoot] selectItemWithTitle:@"CD-Rom"];
    else
        [[self buttonBoot] selectItemWithTitle:@"Hard Drive"];
    
    // NICs
    for (var i = 0; i < interfaces.length; i++)
    {
        var iType   = interfaces[i].getAttribute("type");
        var iModel  = "pcnet"; //interfaces.children[i].getElementsByTagName("model")[0]
        var iMac    = interfaces[i].getElementsByTagName("mac")[0].getAttribute("address");
        
        if (iType == "bridge")
            var iSource = interfaces[i].getElementsByTagName("source")[0].getAttribute("bridge");
        else
            var iSource = "NOT IMPLEMENTED";
        
        var iTarget = interfaces[i].getElementsByTagName("target")[0].getAttribute("dev");
        
        var newNic = [TNNetworkInterface networkInterfaceWithName:@"Interface" type:iType model:iModel mac:iMac source:iSource target:iTarget]
        
        [[self nicsDatasource] addNic:newNic];
    }
    [[self tableNetworkCards] reloadData];
    
    //Drives
    for (var i = 0; i < disks.length; i++)
    {
        var iType       = disks[i].getAttribute("type");
        var iDevice     = disks[i].getAttribute("device");
        var iTarget     = disks[i].getElementsByTagName("target")[0].getAttribute("dev");
        var iBus        = disks[i].getElementsByTagName("target")[0].getAttribute("bus");
        var iSource     = disks[i].getElementsByTagName("source")[0].getAttribute("file");
        
        var newDrive =  [TNDrive driveWithType:iType device:iDevice source:iSource target:iTarget bus:iBus]
        
        [[self drivesDatasource] addDrive:newDrive];
    }
    [[self tableDrives] reloadData];
}



- (IBAction)editNetworkCard:(id)sender
{
    var selectedIndex   = [[[self tableNetworkCards] selectedRowIndexes] firstIndex];
    var nicObject       = [[[self nicsDatasource] networkInterfaces] objectAtIndex:selectedIndex];
    
    [[self panelNicEdition] setNic:nicObject];
    [[self panelNicEdition] setTable:[self tableNetworkCards]];
    [[self panelNicEdition] center];
    [[self panelNicEdition] orderFront:nil];
}

- (IBAction)deleteNetworkCard:(id)sender
{
     var selectedIndex   = [[[self tableNetworkCards] selectedRowIndexes] firstIndex];
     
     [[[self nicsDatasource] networkInterfaces] removeObjectAtIndex:selectedIndex];
     [[self tableNetworkCards] reloadData];
}

- (IBAction)addNetworkCard:(id)sender
{
    var defaultNic = [TNNetworkInterface networkInterfaceWithName:@"Interface" type:@"bridge" model:@"pcnet" mac:@"00:00:00:00:00" source:@"virbr0" target:@"vnet0"]
    
    [[self nicsDatasource] addNic:defaultNic];
    [[self tableNetworkCards] reloadData];
}


- (IBAction)editDrive:(id)sender
{
    var selectedIndex   = [[[self tableDrives] selectedRowIndexes] firstIndex];
    var driveObject       = [[[self drivesDatasource] drives] objectAtIndex:selectedIndex];
    
    [[self panelDriveEdition] setDrive:driveObject];
    [[self panelDriveEdition] setTable:[self tableDrives]];
    [[self panelDriveEdition] center];
    [[self panelDriveEdition] orderFront:nil];
}

- (IBAction)deleteDrive:(id)sender
{
     var selectedIndex   = [[[self tableDrives] selectedRowIndexes] firstIndex];
     
     [[[self drivesDatasource] drives] removeObjectAtIndex:selectedIndex];
     [[self tableDrives] reloadData];
}

- (IBAction)addDrive:(id)sender
{
    var defaultDrive = [TNDrive driveWithType:@"file" device:@"disk" source:"/drives/drive.img" target:@"hda" bus:@"ide"]
    
    [[self drivesDatasource] addDrive:defaultDrive];
    [[self tableDrives] reloadData];
}

@end



