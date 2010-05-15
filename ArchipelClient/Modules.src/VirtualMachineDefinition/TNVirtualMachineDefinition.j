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

@import "TNNetworkInterfaceObject.j"
@import "TNDriveObject.j";
@import "TNWindowNicEdition.j";
@import "TNWindowDriveEdition.j";

TNArchipelTypeVirtualMachineControl                 = @"archipel:vm:control";
TNArchipelTypeVirtualMachineDefinition              = @"archipel:vm:definition";

TNArchipelTypeVirtualMachineControlXMLDesc          = @"xmldesc";
TNArchipelTypeVirtualMachineControlInfo             = @"info";
TNArchipelTypeVirtualMachineDefinitionDefine        = @"define";
TNArchipelTypeVirtualMachineDefinitionUndefine      = @"undefine";

TNArchipelPushNotificationDefinitition              = @"archipel:push:virtualmachine:definition";

VIR_DOMAIN_NOSTATE	        =	0;
VIR_DOMAIN_RUNNING	        =	1;
VIR_DOMAIN_BLOCKED	        =	2;
VIR_DOMAIN_PAUSED	        =	3;
VIR_DOMAIN_SHUTDOWN	        =	4;
VIR_DOMAIN_SHUTOFF	        =	5;
VIR_DOMAIN_CRASHED	        =	6;

TNXMLDescBootHardDrive      = @"hd";
TNXMLDescBootCDROM          = @"cdrom";
TNXMLDescBootNetwork        = @"network";
TNXMLDescBootFileDescriptor = @"fd";
TNXMLDescBoots              = [ TNXMLDescBootHardDrive, TNXMLDescBootCDROM,
                                TNXMLDescBootNetwork, TNXMLDescBootFileDescriptor];


TNXMLDescArchx64            = @"x86_64";
TNXMLDescArchi686           = @"i686";
TNXMLDescArchs              = [TNXMLDescArchx64, TNXMLDescArchi686];


TNXMLDescHypervisorKVM          = @"kvm";
TNXMLDescHypervisorXen          = @"xen";
TNXMLDescHypervisorOpenVZ       = @"openvz";
TNXMLDescHypervisorQemu         = @"qemu";
TNXMLDescHypervisorKQemu        = @"kqemu";
TNXMLDescHypervisorLXC          = @"lxc";
TNXMLDescHypervisorUML          = @"uml";
TNXMLDescHypervisorVBox         = @"vbox";
TNXMLDescHypervisorVMWare       = @"vmware";
TNXMLDescHypervisorOpenNebula   = @"one";
TNXMLDescHypervisors            = [ TNXMLDescHypervisorKVM, TNXMLDescHypervisorXen,
                                    TNXMLDescHypervisorOpenVZ, TNXMLDescHypervisorQemu,
                                    TNXMLDescHypervisorKQemu, TNXMLDescHypervisorLXC,
                                    TNXMLDescHypervisorUML, TNXMLDescHypervisorVBox,
                                    TNXMLDescHypervisorVMWare, TNXMLDescHypervisorOpenNebula];

TNXMLDescVNCKeymapFR            = @"fr";
TNXMLDescVNCKeymapEN_US         = @"en-us";
TNXMLDescVNCKeymaps             = [TNXMLDescVNCKeymapEN_US, TNXMLDescVNCKeymapFR];


TNXMLDescLifeCycleDestroy           = @"destroy";
TNXMLDescLifeCycleRestart           = @"restart";
TNXMLDescLifeCyclePreserve          = @"preserve";
TNXMLDescLifeCycleRenameRestart     = @"rename-restart";
TNXMLDescLifeCycles                 = [TNXMLDescLifeCycleDestroy, TNXMLDescLifeCycleRestart, 
                                        TNXMLDescLifeCyclePreserve, TNXMLDescLifeCycleRenameRestart];

TNXMLDescFeaturePAE                 = @"pae";
TNXMLDescFeatureACPI                = @"acpi";
TNXMLDescFeatureAPIC                = @"apic";

TNXMLDescClockUTC       = @"utc";
TNXMLDescClockLocalTime = @"localtime";
TNXMLDescClockTimezone  = @"timezone";
TNXMLDescClockVariable  = @"variable";
TNXMLDescClocks         = [TNXMLDescClockUTC, TNXMLDescClockLocalTime];

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
    @outlet CPTextField             fieldJID                @accessors;
    @outlet CPTextField             fieldName               @accessors;
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
    @outlet CPButton                buttonOnPowerOff        @accessors;
    @outlet CPButton                buttonOnReboot          @accessors;
    @outlet CPButton                buttonOnCrash           @accessors;
    @outlet CPButton                buttonClocks            @accessors;
    @outlet CPCheckBox              checkboxPAE             @accessors;
    @outlet CPCheckBox              checkboxACPI            @accessors;
    @outlet CPCheckBox              checkboxAPIC            @accessors;
    @outlet CPButtonBar             buttonBarLeft           @accessors;
    @outlet TNWindowNicEdition      windowNicEdition        @accessors;
    @outlet TNWindowDriveEdition    windowDriveEdition      @accessors;
    @outlet CPView                  maskingView             @accessors;
    @outlet CPSearchField           fieldFilterDrives;
    @outlet CPSearchField           fieldFilterNics;
    
    CPTableView                     _tableNetworkCards   @accessors;
    TNTableViewDataSource           _nicsDatasource      @accessors;
    CPTableView                     _tableDrives         @accessors;
    TNTableViewDataSource           _drivesDatasource    @accessors;
}

- (void)awakeFromCib
{
    [maskingView setBackgroundColor:[CPColor whiteColor]];
    [maskingView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [maskingView setAlphaValue:0.9];

    [windowNicEdition setDelegate:self];
    [windowDriveEdition setDelegate:self];

    //drives
    _drivesDatasource    = [[TNTableViewDataSource alloc] init];
    _tableDrives         = [[CPTableView alloc] initWithFrame:[scrollViewForDrives bounds]];
    
    [scrollViewForDrives setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewForDrives setAutohidesScrollers:YES];
    [scrollViewForDrives setDocumentView:_tableDrives];
    [scrollViewForDrives setBorderedWithHexColor:@"#9e9e9e"];
    
    [_tableDrives setUsesAlternatingRowBackgroundColors:YES];
    [_tableDrives setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableDrives setAllowsColumnReordering:YES];
    [_tableDrives setAllowsColumnResizing:YES];
    [_tableDrives setAllowsEmptySelection:YES];
    [_tableDrives setTarget:self];
    [_tableDrives setDoubleAction:@selector(editDrive:)];
    
    var driveColumnType = [[CPTableColumn alloc] initWithIdentifier:@"type"];
    [driveColumnType setEditable:YES];
    [[driveColumnType headerView] setStringValue:@"Type"];
    [driveColumnType setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"type" ascending:YES]];
    
    var driveColumnDevice = [[CPTableColumn alloc] initWithIdentifier:@"device"];
    [driveColumnDevice setEditable:YES];
    [[driveColumnDevice headerView] setStringValue:@"Device"];
    [driveColumnDevice setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"device" ascending:YES]];
    
    var driveColumnTarget = [[CPTableColumn alloc] initWithIdentifier:@"target"];
    [driveColumnTarget setEditable:YES];
    [[driveColumnTarget headerView] setStringValue:@"Target"];
    [driveColumnTarget setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"target" ascending:YES]];
    
    var driveColumnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"];
    [driveColumnSource setWidth:300];
    [driveColumnSource setEditable:YES];
    [[driveColumnSource headerView] setStringValue:@"Source"];
    [driveColumnSource setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"source" ascending:YES]];
    
    var driveColumnBus = [[CPTableColumn alloc] initWithIdentifier:@"bus"];
    [driveColumnBus setEditable:YES];
    [[driveColumnBus headerView] setStringValue:@"Bus"];
    [driveColumnBus setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bus" ascending:YES]];
    
    [_tableDrives addTableColumn:driveColumnType];
    [_tableDrives addTableColumn:driveColumnDevice];
    [_tableDrives addTableColumn:driveColumnTarget];
    [_tableDrives addTableColumn:driveColumnBus];
    [_tableDrives addTableColumn:driveColumnSource];
    
    [_drivesDatasource setTable:_tableDrives];
    [_drivesDatasource setSearchableKeyPaths:[@"type", @"device", @"target", @"source", @"bus"]];
    
    [fieldFilterDrives setTarget:_drivesDatasource];
    [fieldFilterDrives setAction:@selector(filterObjects:)];
    
    [_tableDrives setDataSource:_drivesDatasource];


    // NICs
    _nicsDatasource      = [[TNTableViewDataSource alloc] init];
    _tableNetworkCards   = [[CPTableView alloc] initWithFrame:[scrollViewForNics bounds]];

    [scrollViewForNics setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewForNics setDocumentView:_tableNetworkCards];
    [scrollViewForNics setAutohidesScrollers:YES];
    [scrollViewForNics setBorderedWithHexColor:@"#9e9e9e"];

    [_tableNetworkCards setUsesAlternatingRowBackgroundColors:YES];
    [_tableNetworkCards setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableNetworkCards setAllowsColumnReordering:YES];
    [_tableNetworkCards setAllowsColumnResizing:YES];
    [_tableNetworkCards setAllowsEmptySelection:YES];
    [_tableNetworkCards setTarget:self];
    [_tableNetworkCards setDoubleAction:@selector(editNetworkCard:)];

    var columnType = [[CPTableColumn alloc] initWithIdentifier:@"type"];
    [columnType setEditable:YES];
    [[columnType headerView] setStringValue:@"Type"];
    [columnType setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"type" ascending:YES]];
    
    var columnModel = [[CPTableColumn alloc] initWithIdentifier:@"model"];
    [columnModel setEditable:YES];
    [[columnModel headerView] setStringValue:@"Model"];
    [columnModel setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"model" ascending:YES]];

    var columnMac = [[CPTableColumn alloc] initWithIdentifier:@"mac"];
    [columnMac setEditable:YES];
    [columnMac setWidth:150];
    [[columnMac headerView] setStringValue:@"MAC"];
    [columnMac setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"mac" ascending:YES]];

    var columnSource = [[CPTableColumn alloc] initWithIdentifier:@"source"];
    [columnSource setEditable:YES];
    [[columnSource headerView] setStringValue:@"Source"];
    [columnSource setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"source" ascending:YES]];

    [_tableNetworkCards addTableColumn:columnSource];
    [_tableNetworkCards addTableColumn:columnType];
    [_tableNetworkCards addTableColumn:columnModel];
    [_tableNetworkCards addTableColumn:columnMac];

    [_nicsDatasource setTable:_tableNetworkCards];
    [_nicsDatasource setSearchableKeyPaths:[@"type", @"model", @"mac", @"source"]];
    
    [fieldFilterNics setTarget:_nicsDatasource];
    [fieldFilterNics setAction:@selector(filterObjects:)];
    
    [_tableNetworkCards setDataSource:_nicsDatasource];


    // others..
    [buttonBoot removeAllItems];
    [buttonNumberCPUs removeAllItems];
    [buttonArchitecture removeAllItems];
    [buttonHypervisor removeAllItems];
    [buttonVNCKeymap removeAllItems];
    [buttonOnPowerOff removeAllItems];
    [buttonOnReboot removeAllItems];
    [buttonOnCrash removeAllItems];
    [buttonClocks removeAllItems];

    [buttonBoot addItemsWithTitles:TNXMLDescBoots];
    [buttonNumberCPUs addItemsWithTitles:[@"1", @"2", @"3", @"4"]];
    [buttonArchitecture addItemsWithTitles:TNXMLDescArchs];
    [buttonHypervisor addItemsWithTitles:TNXMLDescHypervisors];
    [buttonVNCKeymap addItemsWithTitles:TNXMLDescVNCKeymaps];
    [buttonOnPowerOff addItemsWithTitles:TNXMLDescLifeCycles];
    [buttonOnReboot addItemsWithTitles:TNXMLDescLifeCycles];
    [buttonOnCrash addItemsWithTitles:TNXMLDescLifeCycles];
    [buttonClocks addItemsWithTitles:TNXMLDescClocks];
    
    [checkboxPAE setState:CPOffState];
    [checkboxACPI setState:CPOffState];
    [checkboxAPIC setState:CPOffState];
}

// TNModule impl.

- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    
    [self registerSelector:@selector(didDefinitionPushReceived:) forPushNotificationType:TNArchipelPushNotificationDefinitition];
}

- (void)willShow
{
    [super willShow];
    
    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    
    [maskingView setFrame:[self bounds]];
    
    [self setDefaultValues];
    
    [self checkIfRunning];
    [self getXMLDesc];
}

- (void)willHide
{
    [super willHide];

    [_tableNetworkCards reloadData];
    [_tableDrives reloadData];

    [maskingView removeFromSuperview];
}

- (void)willUnload
{
    [super willUnload];
    
    [self setDefaultValues];
    
    [maskingView removeFromSuperview];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}

- (void)didPresenceUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
        [self checkIfRunning];
    }
}

- (void)setDefaultValues
{
    var bundle  = [CPBundle bundleForClass:[self class]];
    var cpu     = [bundle objectForInfoDictionaryKey:@"TNDescDefaultNumberCPU"];
    var mem     = [bundle objectForInfoDictionaryKey:@"TNDescDefaultMemory"];
    var arch    = [bundle objectForInfoDictionaryKey:@"TNDescDefaultArchitecture"];
    var vnck    = [bundle objectForInfoDictionaryKey:@"TNDescDefaultVNCKeymap"];
    var opo     = [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnPowerOff"];
    var or      = [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnReboot"];
    var oc      = [bundle objectForInfoDictionaryKey:@"TNDescDefaultOnCrash"];
    var clock   = [bundle objectForInfoDictionaryKey:@"TNDescDefaultClockOffset"];
    var pae     = [bundle objectForInfoDictionaryKey:@"TNDescDefaultPAE"];
    var acpi    = [bundle objectForInfoDictionaryKey:@"TNDescDefaultACPI"];
    var apic    = [bundle objectForInfoDictionaryKey:@"TNDescDefaultAPIC"];
    
    [buttonNumberCPUs selectItemWithTitle:cpu];
    [fieldMemory setStringValue:mem];
    [buttonArchitecture selectItemWithTitle:arch];
    [buttonVNCKeymap selectItemWithTitle:vnck];
    [buttonOnPowerOff selectItemWithTitle:opo];
    [buttonOnReboot selectItemWithTitle:or];
    [buttonOnCrash selectItemWithTitle:oc];
    [buttonClocks selectItemWithTitle:clock];
    [checkboxPAE setState:(pae == 1) ? CPOnState : CPOffState];
    [checkboxACPI setState:(acpi == 1) ? CPOnState : CPOffState];
    [checkboxAPIC setState:(apic == 1) ? CPOnState : CPOffState];
    
    [_nicsDatasource removeAllObjects];
    [_drivesDatasource removeAllObjects];
    [_tableNetworkCards reloadData];
    [_tableDrives reloadData];
    
}

- (void)checkIfRunning
{
    var status = [_entity status];
    
    if ((status == TNStropheContactStatusOnline) || (status == TNStropheContactStatusAway) || (status == TNStropheContactStatusOffline))
    {
        [maskingView setFrame:[self bounds]];
        [self addSubview:maskingView];
    }
    else
        [maskingView removeFromSuperview];
}

- (BOOL)didDefinitionPushReceived:(TNStropheStanza)aStanza
{
    CPLog.info("Push notification definition received");
    [self getXMLDesc];
    
    return YES;
}

//  XML Desc
- (void)getXMLDesc
{
    var xmldescStanza   = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineControl}];

    [xmldescStanza addChildName:@"query" withAttributes:{"type" : TNArchipelTypeVirtualMachineControlXMLDesc}];

    [_entity sendStanza:xmldescStanza andRegisterSelector:@selector(didReceiveXMLDesc:) ofObject:self];
}

- (void)didReceiveXMLDesc:(id)aStanza
{
    if ([aStanza getType] == @"success")
    {
        var domain          = [aStanza firstChildWithName:@"domain"];
        var hypervisor      = [domain valueForAttribute:@"type"];
        var memory          = [[domain firstChildWithName:@"currentMemory"] text];
        var arch            = [[[domain firstChildWithName:@"os"] firstChildWithName:@"type"] valueForAttribute:@"arch"];
        var vcpu            = [[domain firstChildWithName:@"vcpu"] text];
        var boot            = [[domain firstChildWithName:@"boot"] valueForAttribute:@"dev"];
        var interfaces      = [domain childrenWithName:@"interface"];
        var disks           = [domain childrenWithName:@"disk"];
        var graphics        = [domain childrenWithName:@"graphics"];
        var onPowerOff      = [domain firstChildWithName:@"on_poweroff"];
        var onReboot        = [domain firstChildWithName:@"on_reboot"];
        var onCrash         = [domain firstChildWithName:@"on_crash"];
        var features        = [domain firstChildWithName:@"features"];
        var clock           = [domain firstChildWithName:@"clock"];

        [_nicsDatasource removeAllObjects];
        [_drivesDatasource removeAllObjects];
    
        [fieldMemory setStringValue:(parseInt(memory) / 1024)];
        [buttonNumberCPUs selectItemWithTitle:vcpu];

        for (var i = 0; i < [graphics count]; i++)
        {
            var graphic = [graphics objectAtIndex:i];
            if ([graphic valueForAttribute:@"type"] == "vnc")
            {
                var keymap = [graphic valueForAttribute:@"keymap"];
                if (keymap)
                {
                    [buttonVNCKeymap selectItemWithTitle:keymap];
                    break;
                }
            }
        }

        if (boot == "cdrom")
            [buttonBoot selectItemWithTitle:TNXMLDescBootCDROM];
        else
            [buttonBoot selectItemWithTitle:TNXMLDescBootHardDrive];
        
        
        //power 
        if (onPowerOff)
            [buttonOnPowerOff selectItemWithTitle:[onPowerOff text]];
        else
            [buttonOnPowerOff selectItemWithTitle:@"Default"];
        
        if (onReboot)
            [buttonOnReboot selectItemWithTitle:[onReboot text]];
        else
            [buttonOnPowerOff selectItemWithTitle:@"Default"];
                
        if (onCrash)
            [buttonOnCrash selectItemWithTitle:[onCrash text]];
        else
            [buttonOnPowerOff selectItemWithTitle:@"Default"];
        
        // features
        [checkboxAPIC setState:CPOffState];
        [checkboxACPI setState:CPOffState];
        [checkboxPAE setState:CPOffState];
        if (features)
        {
            if ([features firstChildWithName:TNXMLDescFeaturePAE])
                [checkboxPAE setState:CPOnState];

            if ([features firstChildWithName:TNXMLDescFeatureACPI])
                [checkboxACPI setState:CPOnState];

            if ([features firstChildWithName:TNXMLDescFeatureAPIC])
                [checkboxAPIC setState:CPOnState];
        }
        
        //clock
        if ((hypervisor == TNXMLDescHypervisorKVM) || (hypervisor == TNXMLDescHypervisorQemu) || (hypervisor == TNXMLDescHypervisorKQemu))
        {
            [buttonClocks setEnabled:YES];
            
            if (clock)
            {
                [buttonClocks selectItemWithTitle:[clock valueForAttribute:@"offset"]];
            }
        }
        else
        {
            [buttonClocks setEnabled:NO];
        }
        
        // NICs
        for (var i = 0; i < [interfaces count]; i++)
        {
            var currentInterface    = [interfaces objectAtIndex:i];
            var iType               = [currentInterface valueForAttribute:@"type"];
            var iModel              = "pcnet"; //interfaces.children[i].getElementsByTagName("model")[0]
            var iMac                = [[currentInterface firstChildWithName:@"mac"] valueForAttribute:@"address"];

            if (iType == "bridge")
                var iSource = [[currentInterface firstChildWithName:@"source"] valueForAttribute:@"bridge"];
            else if (iType == "network")
                var iSource = [[currentInterface firstChildWithName:@"source"] valueForAttribute:@"network"];


            var iTarget = "";//interfaces[i].getElementsByTagName("target")[0].getAttribute("dev");

            var newNic = [TNNetworkInterface networkInterfaceWithType:iType model:iModel mac:iMac source:iSource]

            [_nicsDatasource addObject:newNic];
        }
        [_tableNetworkCards reloadData];

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

            [_drivesDatasource addObject:newDrive];
        }
        [_tableDrives reloadData];
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

// generation of XML
- (TNStropheStanza)generateXMLDescStanzaWithUniqueID:(CPNumber)anUid
{
    var memory      = "" + [fieldMemory intValue] * 1024 + ""; //put it into kb and make a string like a pig
    var arch        = [buttonArchitecture title];
    var hypervisor  = [buttonHypervisor title];
    var nCPUs       = [buttonNumberCPUs title];
    var boot        = [buttonBoot title];
    var nics        = [_nicsDatasource content];
    var drives      = [_drivesDatasource content];

    CPLog.debug(drives);
    
    var stanza      = [TNStropheStanza iqWithAttributes:{"type" : TNArchipelTypeVirtualMachineDefinition, "to": [_entity fullJID], "id": anUid}];

    [stanza addChildName:@"query" withAttributes:{"type": TNArchipelTypeVirtualMachineDefinitionDefine}];
    [stanza addChildName:@"domain" withAttributes:{"type": hypervisor}];

    [stanza addChildName:@"name"];
    [stanza addTextNode:[_entity nodeName]];
    [stanza up];

    [stanza addChildName:@"uuid"];
    [stanza addTextNode:[_entity nodeName]];
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
    
    [stanza addChildName:@"on_poweroff"];
    [stanza addTextNode:[buttonOnPowerOff title]];
    [stanza up];

    [stanza addChildName:@"on_reboot"];
    [stanza addTextNode:[buttonOnReboot title]];
    [stanza up];

    [stanza addChildName:@"on_crash"];
    [stanza addTextNode:[buttonOnCrash title]];
    [stanza up];
    
    // FEATURES
    [stanza addChildName:@"features"];

    if ([checkboxPAE state] == CPOnState)
    {
        [stanza addChildName:TNXMLDescFeaturePAE];
        [stanza up];
    }
    
    if ([checkboxACPI state] == CPOnState)
    {
        [stanza addChildName:TNXMLDescFeatureACPI];
        [stanza up];
    }
    
    if ([checkboxAPIC state] == CPOnState)
    {
        [stanza addChildName:TNXMLDescFeatureAPIC];
        [stanza up];
    }

    [stanza up];

    //Clock
    if ((hypervisor == TNXMLDescHypervisorKVM) || (hypervisor == TNXMLDescHypervisorQemu) || (hypervisor == TNXMLDescHypervisorKQemu))
    {
        [stanza addChildName:@"clock" withAttributes:{"offset": [buttonClocks title]}];
        [stanza up];
    }
    
    
    // Deviaces
    [stanza addChildName:@"devices"];

    if (hypervisor == TNXMLDescHypervisorKVM)
    {
        [stanza addChildName:@"emulator"];
        [stanza addTextNode:@"/usr/bin/kvm"];
        [stanza up];
    }
    if (hypervisor == TNXMLDescHypervisorQemu)
    {
        [stanza addChildName:@"emulator"];
        [stanza addTextNode:@"/usr/bin/qemu"];
        [stanza up];
    }

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
        var nic     = [nics objectAtIndex:i];
        var nicType = [nic type];

        [stanza addChildName:@"interface" withAttributes:{"type": nicType}];
        [stanza addChildName:@"mac" withAttributes:{"address": [nic mac]}];
        [stanza up];
        if (nicType == @"bridge")
            [stanza addChildName:@"source" withAttributes:{"bridge": [nic source]}];
        else
            [stanza addChildName:@"source" withAttributes:{"network": [nic source]}];

        [stanza up];
        [stanza up];
    }

    [stanza addChildName:@"input" withAttributes:{"bus": "ps2", "type": "mouse"}];
    [stanza up];

    if (hypervisor == TNXMLDescHypervisorKVM || hypervisor == TNXMLDescHypervisorQemu
        || hypervisor == TNXMLDescHypervisorKQemu || hypervisor == TNXMLDescHypervisorXen)
    {
        [stanza addChildName:@"graphics" withAttributes:{"autoport": "yes", "type": "vnc", "port": "-1", "keymap": [buttonVNCKeymap title]}];
        [stanza up];
    }

    //devices up
    [stanza up];

    return stanza;
}

// Actions Nics and drives
- (IBAction)editNetworkCard:(id)sender
{
    var selectedIndex   = [[_tableNetworkCards selectedRowIndexes] firstIndex];
    var nicObject       = [_nicsDatasource objectAtIndex:selectedIndex];

    [windowNicEdition setNic:nicObject];
    [windowNicEdition setTable:_tableNetworkCards];
    [windowNicEdition setEntity:_entity];
    [windowNicEdition center];
    [windowNicEdition orderFront:nil];
}

- (IBAction)deleteNetworkCard:(id)sender
{
    if ([_tableNetworkCards numberOfSelectedRows] <= 0)
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a network interface"];
         return;
    }

     var selectedIndex   = [[_tableNetworkCards selectedRowIndexes] firstIndex];

     [_nicsDatasource removeObjectAtIndex:selectedIndex];
     [_tableNetworkCards reloadData];
     [self defineXML:nil];
}

- (IBAction)addNetworkCard:(id)sender
{
    var defaultNic = [TNNetworkInterface networkInterfaceWithType:@"bridge" model:@"pcnet" mac:generateMacAddr() source:@"virbr0"]

    [_nicsDatasource addObject:defaultNic];
    [_tableNetworkCards reloadData];
    [self defineXML:nil];
}

- (IBAction)editDrive:(id)sender
{
    var selectedIndex   = [[_tableDrives selectedRowIndexes] firstIndex];

    if (selectedIndex != -1)
    {
        var driveObject = [_drivesDatasource objectAtIndex:selectedIndex];

        [windowDriveEdition setDrive:driveObject];
        [windowDriveEdition setTable:_tableDrives];
        [windowDriveEdition setEntity:_entity];
        [windowDriveEdition center];
        [windowDriveEdition orderFront:nil];
    }
}

- (IBAction)deleteDrive:(id)sender
{
    if ([_tableDrives numberOfSelectedRows] <= 0)
    {
        [CPAlert alertWithTitle:@"Error" message:@"You must select a drive"];
        return;
    }

     var selectedIndex   = [[_tableDrives selectedRowIndexes] firstIndex];

     [_drivesDatasource removeObjectAtIndex:selectedIndex];
     [_tableDrives reloadData];
     [self defineXML:nil];
}

- (IBAction)addDrive:(id)sender
{
    var defaultDrive = [TNDrive driveWithType:@"file" device:@"disk" source:"/drives/drive.img" target:@"hda" bus:@"ide"]

    [_drivesDatasource addObject:defaultDrive];
    [_tableDrives reloadData];
    [self defineXML:nil];
}

// action XML desc
- (IBAction)defineXML:(id)sender
{
    var uid             = [_connection getUniqueId];
    var defineStanza    = [self generateXMLDescStanzaWithUniqueID:uid];

    [_entity sendStanza:defineStanza andRegisterSelector:@selector(didDefineXML:) ofObject:self withSpecificID:uid];
}

- (void)didDefineXML:(id)aStanza
{
    var responseType    = [aStanza getType];
    var responseFrom    = [aStanza getFrom];

    if (responseType == @"success")
    {
        var msg = @"Definition of virtual machine " + [_entity nickname] + " sucessfuly updated"
        CPLog.info(msg)
    }
    else if (responseType == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


// delegate for panels
- (BOOL)windowShouldClose:(id)window
{
    [self defineXML:nil];

    return YES;
}

@end



