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
@import "TNWindowNicEdition.j";
@import "TNWindowDriveEdition.j";

trinityTypeVirtualMachineControl            = @"trinity:vm:control";
trinityTypeVirtualMachineDefinition         = @"trinity:vm:definition";

trinityTypeVirtualMachineControlXMLDesc         = @"xmldesc";
trinityTypeVirtualMachineControlInfo            = @"info";
trinityTypeVirtualMachineDefinitionDefine       = @"define";
trinityTypeVirtualMachineDefinitionUndefine     = @"undefine";

VIR_DOMAIN_NOSTATE	                        =	0;
VIR_DOMAIN_RUNNING	                        =	1;
VIR_DOMAIN_BLOCKED	                        =	2;
VIR_DOMAIN_PAUSED	                        =	3;
VIR_DOMAIN_SHUTDOWN	                        =	4;
VIR_DOMAIN_SHUTOFF	                        =	5;
VIR_DOMAIN_CRASHED	                        =	6;

TNXMLDescBootHardDrive  = @"Hard Drive";
TNXMLDescBootCDROM      = @"CD-Rom";

function generateMacAddr()
{
    var hexTab      = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"];
    var dA          = "DE";
    var dB          = "AD";
    var dC          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)];
    var dD          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)];
    var dE          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)];
    var dF          = hexTab[Math.round(Math.random() * 15)] + hexTab[Math.round(Math.random() * 15)];
    var macaddress  = dA + ":" + dB + ":" + dC + ":" + dD + ":" + dE + ":" + dF;
    
    return macaddress
}

@implementation TNVirtualMachineDefinition : TNModule 
{
    @outlet CPScrollView            scrollViewForNics       @accessors;
    @outlet CPScrollView            scrollViewForDrives     @accessors;
    @outlet CPTextField             fieldMemory             @accessors;
    @outlet CPPopUpButton           buttonNumberCPUs        @accessors;
    @outlet CPPopUpButton           buttonBoot              @accessors;
    @outlet CPPopUpButton           buttonVNCKeymap         @accessors;
    @outlet CPButton                buttonAddNic            @accessors;
    @outlet CPButton                buttonDelNic            @accessors;
    @outlet CPButton                buttonArchitecture      @accessors;
    @outlet CPButton                buttonHypervisor        @accessors;
    @outlet TNWindowNicEdition      windowNicEdition         @accessors;
    @outlet TNWindowDriveEdition    windowDriveEdition       @accessors;
    @outlet CPView                  maskingView             @accessors;
    
    CPTableView                     tableNetworkCards   @accessors;
    TNDatasourceNetworkInterfaces   nicsDatasource      @accessors;
    CPTableView                     tableDrives         @accessors;
    TNDatasourceDrives              drivesDatasource    @accessors;
    id                              virtualMachineXML   @accessors;
    
    
}

- (void)awakeFromCib
{
    [[self maskingView] setBackgroundColor:[CPColor whiteColor]];
    [[self maskingView] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self maskingView] setAlphaValue:0.9];
    
    [[self windowNicEdition] setDelegate:self];
    [[self windowDriveEdition] setDelegate:self];
    
    //drives
    drivesDatasource    = [[TNDatasourceDrives alloc] init];
    tableDrives         = [[CPTableView alloc] initWithFrame:[[self scrollViewForDrives] bounds]];
    
    [[self scrollViewForDrives] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewForDrives] setAutohidesScrollers:YES];
    [[self scrollViewForDrives] setDocumentView:[self tableDrives]];
    [[self scrollViewForDrives] setBorderedWithHexColor:@"#9e9e9e"];
    
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
    
    var driveColumnTarget = [[CPTableColumn alloc] initWithIdentifier:@"target"];
    [driveColumnTarget setResizingMask:CPTableColumnAutoresizingMask ];
    [driveColumnTarget setEditable:YES];
    [[driveColumnTarget headerView] setStringValue:@"Target"];
    
    var driveColumnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"];
    [driveColumnSource setResizingMask:CPTableColumnAutoresizingMask ];
    [driveColumnSource setWidth:400];
    [driveColumnSource setEditable:YES];
    [[driveColumnSource headerView] setStringValue:@"Source"];
    
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
    [[self scrollViewForNics] setBorderedWithHexColor:@"#9e9e9e"];
    
    [[self tableNetworkCards] setUsesAlternatingRowBackgroundColors:YES];
    [[self tableNetworkCards] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self tableNetworkCards] setAllowsColumnReordering:YES];
    [[self tableNetworkCards] setAllowsColumnResizing:YES];
    [[self tableNetworkCards] setAllowsEmptySelection:YES];
    [[self tableNetworkCards] setTarget:self];
    [[self tableNetworkCards] setDoubleAction:@selector(editNetworkCard:)];

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

    [[self tableNetworkCards] addTableColumn:columnSource];
    [[self tableNetworkCards] addTableColumn:columnType];
    [[self tableNetworkCards] addTableColumn:columnModel];
    [[self tableNetworkCards] addTableColumn:columnMac];

    [[self tableNetworkCards] setDataSource:[self nicsDatasource]];
    
    
    // others..
    [[self buttonBoot] removeAllItems];
    [[self buttonNumberCPUs] removeAllItems];
    [[self buttonArchitecture] removeAllItems];
    [[self buttonHypervisor] removeAllItems];
    
    var bootTypes = [TNXMLDescBootHardDrive, TNXMLDescBootCDROM];
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
    
    var archTypes = ["x86_64", "i686"];
    for (var i = 0; i < archTypes.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:archTypes[i] action:nil keyEquivalent:nil];
        [[self buttonArchitecture] addItem:item];
    }
    
    var hypervisorsTypes = ["kvm", "xen", "openvz", "qemu", "lxc", "uml", "virtualbox", "vmware"];
    for (var i = 0; i < hypervisorsTypes.length; i++)
    {
        var item = [[CPMenuItem alloc] initWithTitle:hypervisorsTypes[i] action:nil keyEquivalent:nil];
        [[self buttonHypervisor] addItem:item];
    }
}

// TNModule impl.
- (void)willShow
{
    [[self maskingView] setFrame:[self bounds]];

    [self getVirtualMachineInfo];
    [self getXMLDesc];
}

- (void)willHide
{
    [[[self nicsDatasource] nics] removeAllObjects];
    [[[self drivesDatasource] drives] removeAllObjects];
    
    [[self tableNetworkCards] reloadData];
    [[self tableDrives] reloadData];
    
    [[self fieldMemory] setStringValue:@""];
    [[self buttonNumberCPUs] selectItemWithTitle:@"1"];
    [[self buttonArchitecture] selectItemWithTitle:@"kvm"];
    [[self buttonArchitecture] selectItemWithTitle:@"x86_64"];
    
    [[self buttonBoot] selectItemWithTitle:TNXMLDescBootHardDrive];
    
    [[self maskingView] removeFromSuperview];
}

- (void)willUnload
{
    [[self maskingView] removeFromSuperview];
}

//  XML Desc
- (void)getXMLDesc
{
    var uid             = [[[self contact] connection] getUniqueId];
    var xmldescStanza   = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControl, "to": [[self contact] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
        
    [xmldescStanza addChildName:@"query" withAttributes:{"type" : trinityTypeVirtualMachineControlXMLDesc}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveXMLDesc:) ofObject:self withDict:params];
    [[[self contact] connection] send:xmldescStanza];
}

- (void)didReceiveXMLDesc:(id)aStanza 
{    
    if ([aStanza getType] == @"error")
    {
        CPLogConsole("XML not defined");
        return;
    }
    var domain      = [aStanza firstChildWithName:@"domain"];
    var hypervisor  = [domain valueForAttribute:@"type"];
    var memory      = [[domain firstChildWithName:@"currentMemory"] text];
    var arch        = [[[domain firstChildWithName:@"os"] firstChildWithName:@"type"] valueForAttribute:@"arch"];
    var vcpu        = [[domain firstChildWithName:@"vcpu"] text];
    var boot        = [[domain firstChildWithName:@"boot"] valueForAttribute:@"dev"];
    var interfaces  = [domain childrenWithName:@"interface"];
    var disks       = [domain childrenWithName:@"disk"];
    
    [[self fieldMemory] setStringValue:(parseInt(memory) / 1024)];
    [[self buttonNumberCPUs] selectItemWithTitle:vcpu];
    
    if (boot == "cdrom")
        [[self buttonBoot] selectItemWithTitle:TNXMLDescBootCDROM];
    else
        [[self buttonBoot] selectItemWithTitle:TNXMLDescBootHardDrive];
    
    // NICs
    for (var i = 0; i < [interfaces count]; i++)
    {
        var currentInterface    = [interfaces objectAtIndex:i];
        var iType               = [currentInterface valueForAttribute:@"type"];
        var iModel              = "pcnet"; //interfaces.children[i].getElementsByTagName("model")[0]
        var iMac                = [[currentInterface firstChildWithName:@"mac"] valueForAttribute:@"address"];
        
        if (iType == "bridge")
            var iSource = [[currentInterface firstChildWithName:@"source"] valueForAttribute:@"bridge"];
        else
            var iSource = "NOT IMPLEMENTED";
        
        var iTarget = "";//interfaces[i].getElementsByTagName("target")[0].getAttribute("dev");
        
        var newNic = [TNNetworkInterface networkInterfaceWithType:iType model:iModel mac:iMac source:iSource]
        
        [[self nicsDatasource] addNic:newNic];
    }
    [[self tableNetworkCards] reloadData];
    
    //Drives
    for (var i = 0; i < [disks count]; i++)
    {
        var currentDisk = [disks objectAtIndex:i];
        var iType       = [currentDisk valueForAttribute:@"type"];
        var iDevice     = [currentDisk valueForAttribute:@"device"];
        var iTarget     = [[currentDisk firstChildWithName:@"target"] valueForAttribute:@"dev"];
        var iBus        = [[currentDisk firstChildWithName:@"target"] valueForAttribute:@"bus"];
        var iSource     = [[currentDisk firstChildWithName:@"source"] valueForAttribute:@"file"];
        
        var newDrive =  [TNDrive driveWithType:iType device:iDevice source:iSource target:iTarget bus:iBus]
        
        [[self drivesDatasource] addDrive:newDrive];
    }
    [[self tableDrives] reloadData];
}

// generation of XML
- (TNStropheStanza)generateXMLDescStanzaWithUniqueID:(CPNumber)anUid
{
    var memory      = "" + [[self fieldMemory] intValue] * 1024 + ""; //put it into kb and make a string like a pig
    var arch        = [[self buttonArchitecture] title];
    var hypervisor  = [[self buttonHypervisor] title];
    var nCPUs       = [[self buttonNumberCPUs] title];
    var boot        = ([[self buttonBoot] title] == TNXMLDescBootHardDrive) ? @"hd" : @"cdrom";
    var nics        = [[self nicsDatasource] nics];
    var drives      = [[self drivesDatasource] drives];
    
    
    var stanza      = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineDefinition, "to": [[self contact] fullJID], "id": anUid}];
    
    [stanza addChildName:@"query" withAttributes:{"type": trinityTypeVirtualMachineDefinitionDefine}];
    [stanza addChildName:@"domain" withAttributes:{"type": hypervisor}];

    [stanza addChildName:@"name"];
    [stanza addTextNode:[[self contact] nodeName]];
    [stanza up];

    [stanza addChildName:@"uuid"];
    [stanza addTextNode:[[self contact] nodeName]];
    [stanza up];

    [stanza addChildName:@"memory"];
    [stanza addTextNode:memory];
    [stanza up];
    
    [stanza addChildName:@"currentMemory"];
    [stanza addTextNode:memory];
    [stanza up];
    
    [stanza addChildName:@"vcpu"];
    [stanza addTextNode:nCPUs];
    [stanza up];
    
    [stanza addChildName:@"os"];
    [stanza addChildName:@"type" withAttributes:{"machine": "pc-0.11", "arch": arch}]
    [stanza addTextNode:@"hvm"];
    [stanza up];
    [stanza addChildName:@"boot" withAttributes:{"dev": boot}]
    [stanza up];
    [stanza up];
    
    [stanza addChildName:@"clock" withAttributes:{"offset": "utc"}];
    [stanza up];
    
    [stanza addChildName:@"on_poweroff"];
    [stanza addTextNode:@"destroy"];
    [stanza up];

    [stanza addChildName:@"on_reboot"];
    [stanza addTextNode:@"restart"];
    [stanza up];

    [stanza addChildName:@"on_crash"];
    [stanza addTextNode:@"destroy"];
    [stanza up];
    
    [stanza addChildName:@"devices"];
    [stanza addChildName:@"emulator"];
    [stanza addTextNode:@"/usr/bin/kvm"];
    [stanza up];
    
    for (var i = 0; i < [drives count]; i++)
    {
        var drive = [drives objectAtIndex:i];
        
        [stanza addChildName:@"disk" withAttributes:{"device": [drive device], "type": [drive type]}];
        [stanza addChildName:@"source" withAttributes:{"file": [drive source]}];
        [stanza up];
        [stanza addChildName:@"target" withAttributes:{"bus": [drive bus], "dev": [drive target]}];
        [stanza up];
        [stanza up];
    }
    
    for (var i = 0; i < [nics count]; i++)
    {
        var nic = [nics objectAtIndex:i];
        
        [stanza addChildName:@"interface" withAttributes:{"type": [nic type]}];
        [stanza addChildName:@"mac" withAttributes:{"address": [nic mac]}];
        [stanza up];
        [stanza addChildName:@"source" withAttributes:{"bridge": [nic source]}];
        [stanza up];
        [stanza up];
    }

    [stanza addChildName:@"input" withAttributes:{"bus": "ps2", "type": "mouse"}];
    [stanza up];
    
    [stanza addChildName:@"graphics" withAttributes:{"autoport": "yes", "type": "vnc", "port": "-1"}];
    [stanza up];
    
    //devices up
    [stanza up];
        
    return stanza;
}


- (void)getVirtualMachineInfo
{    
    var uid = [[[self contact] connection] getUniqueId];
    var infoStanza = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeVirtualMachineControl, "to": [[self contact] fullJID], "id": uid}];
    var params = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    
    [infoStanza addChildName:@"query" withAttributes:{"type" : trinityTypeVirtualMachineControlInfo}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveVirtualMachineInfo:) ofObject:self withDict:params];
    [[[self contact] connection] send:infoStanza];
}

- (void)didReceiveVirtualMachineInfo:(id)aStanza 
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];
    
    if (responseType == @"success")
    {
        var infoNode = [aStanza firstChildWithName:@"info"];
        var libvirtSate = [infoNode valueForAttribute:@"state"];
        if (libvirtSate == VIR_DOMAIN_RUNNING || libvirtSate == VIR_DOMAIN_PAUSED)
            [self addSubview:[self maskingView]];
        else
            [[self maskingView] removeFromSuperview];
    }   
}


// Actions Nics and drives
- (IBAction)editNetworkCard:(id)sender
{
    var selectedIndex   = [[[self tableNetworkCards] selectedRowIndexes] firstIndex];
    var nicObject       = [[[self nicsDatasource] nics] objectAtIndex:selectedIndex];
    
    [[self windowNicEdition] setNic:nicObject];
    [[self windowNicEdition] setTable:[self tableNetworkCards]];
    [[self windowNicEdition] center];
    [[self windowNicEdition] orderFront:nil];
}

- (IBAction)deleteNetworkCard:(id)sender
{
    if ([[self tableNetworkCards] numberOfSelectedRows] <= 0)
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a network interface"];
         return;
    }
    
     var selectedIndex   = [[[self tableNetworkCards] selectedRowIndexes] firstIndex];
     
     [[[self nicsDatasource] nics] removeObjectAtIndex:selectedIndex];
     [[self tableNetworkCards] reloadData];
     [self defineXML:nil];
}

- (IBAction)addNetworkCard:(id)sender
{
    var defaultNic = [TNNetworkInterface networkInterfaceWithType:@"bridge" model:@"pcnet" mac:generateMacAddr() source:@"virbr0"]
    
    [[self nicsDatasource] addNic:defaultNic];
    [[self tableNetworkCards] reloadData];
    [self defineXML:nil];
}

- (IBAction)editDrive:(id)sender
{
    var selectedIndex   = [[[self tableDrives] selectedRowIndexes] firstIndex];
    
    if (selectedIndex != -1)
    {
        var driveObject = [[[self drivesDatasource] drives] objectAtIndex:selectedIndex];

        [[self windowDriveEdition] setDrive:driveObject];
        [[self windowDriveEdition] setTable:[self tableDrives]];
        [[self windowDriveEdition] setContact:[self contact]];
        [[self windowDriveEdition] center];
        [[self windowDriveEdition] orderFront:nil];
    }
}

- (IBAction)deleteDrive:(id)sender
{
    if ([[self tableDrives] numberOfSelectedRows] <= 0)
    {
        [CPAlert alertWithTitle:@"Error" message:@"You must select a drive"];
        return;
    }
       
     var selectedIndex   = [[[self tableDrives] selectedRowIndexes] firstIndex];
     
     [[[self drivesDatasource] drives] removeObjectAtIndex:selectedIndex];
     [[self tableDrives] reloadData];
     [self defineXML:nil];
}

- (IBAction)addDrive:(id)sender
{
    var defaultDrive = [TNDrive driveWithType:@"file" device:@"disk" source:"/drives/drive.img" target:@"hda" bus:@"ide"]
    
    [[self drivesDatasource] addDrive:defaultDrive];
    [[self tableDrives] reloadData];
    [self defineXML:nil];
}

// action XML desc
- (IBAction)defineXML:(id)sender
{
    var uid             = [[[self contact] connection] getUniqueId];
    var defineStanza    = [self generateXMLDescStanzaWithUniqueID:uid];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [[[self contact] connection] registerSelector:@selector(didDefineXML:) ofObject:self withDict:params];
    [[[self contact] connection] send:defineStanza];
}


- (void)onLibvirtError:(TNStropheStanza)errorStanza
{
    var errorNode               = [errorStanza firstChildWithName:@"error"];
    var libvirtErrorCode        = [errorNode valueForAttribute:@"code"];
    var libvirtErrorMessage     = [errorNode text];   
    var title                   = @"Unable to create virtual machine. Error " + libvirtErrorCode;
    
    [CPAlert alertWithTitle:title message:libvirtErrorMessage style:CPCriticalAlertStyle]
    
    [[TNViewLog sharedLogger] log:@"Error code :" + libvirtErrorCode + ". " + libvirtErrorMessage];
}

- (void)didDefineXML:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"success")
    {
        [[TNViewLog sharedLogger] log:@"definition of virtual machine " + responseFrom + " sucessfuly updated"];
    }
    else
    {
        [self onLibvirtError:aStanza];
    }
}


// delegate for panels
-(BOOL)windowShouldClose:(id)window
{
    [self defineXML:nil];
    
    return YES;
}

@end



