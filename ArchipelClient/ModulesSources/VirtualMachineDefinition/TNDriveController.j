/*
 * TNWindowDriveEdition.j
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

@import <AppKit/CPButton.j>
@import <AppKit/CPMenuItem.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <Foundation/Foundation.j>

@import <StropheCappuccino/TNStropheStanza.j>
@import <TNKit/TNAlert.j>

@import "Model/TNLibvirt.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


var TNArchipelTypeVirtualMachineDisk        = @"archipel:vm:disk",
    TNArchipelTypeVirtualMachineDiskGet     = @"get",
    TNArchipelTypeVirtualMachineISOGet      = @"getiso";

/*! @ingroup virtualmachinedefinition
    this is the virtual drive editor
*/
@implementation TNDriveController : CPObject
{
    @outlet CPButton        buttonOK;
    @outlet CPCheckBox      checkBoxReadOnly;
    @outlet CPCheckBox      checkBoxShareable;
    @outlet CPCheckBox      checkBoxTransient;
    @outlet CPPopover       mainPopover;
    @outlet CPPopUpButton   buttonDevice;
    @outlet CPPopUpButton   buttonDriverCache;
    @outlet CPPopUpButton   buttonSourcePath;
    @outlet CPPopUpButton   buttonTargetBus;
    @outlet CPPopUpButton   buttonTargetDevice;
    @outlet CPPopUpButton   buttonType;
    @outlet CPTextField     fieldDevicePath;

    id                      _delegate       @accessors(property=delegate);
    CPTableView             _table          @accessors(property=table);
    TNLibvirtDeviceDisk     _drive          @accessors(property=drive);
    TNLibvirtDeviceDisk     _otherDrives    @accessors(property=otherDrives);
    TNStropheContact        _entity         @accessors(property=entity);
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [buttonDevice removeAllItems];
    [buttonType removeAllItems];
    [buttonTargetDevice removeAllItems];
    [buttonTargetBus removeAllItems];
    [buttonSourcePath removeAllItems];
    [buttonDriverCache removeAllItems];

    [buttonDevice addItemsWithTitles:TNLibvirtDeviceDiskDevices];
    [buttonType addItemsWithTitles:TNLibvirtDeviceDiskTypes];
    [buttonTargetDevice addItemsWithTitles:TNLibvirtDeviceDiskTargetDevices];
    [buttonTargetBus addItemsWithTitles:TNLibvirtDeviceDiskTargetBuses];
    [buttonDriverCache addItemsWithTitles:TNLibvirtDeviceDiskDriverCaches];
}

#pragma mark -
#pragma mark Getters and Setters

- (void)disableAlreadyUsedTargetDevices
{
    for (var i = 0; i < [[buttonTargetDevice itemArray] count]; i++)
        [[[buttonTargetDevice itemArray] objectAtIndex:i] setEnabled:YES];

    for (var i = 0; i < [_otherDrives count]; i++)
    {
        var dev = [[[_otherDrives objectAtIndex:i] target] device],
            item = [buttonTargetDevice itemWithTitle:dev];

        if (item && [[_drive target] device] != dev)
            [item setEnabled:NO];
    }
}

#pragma mark -
#pragma mark Utilities

/*! send this message to update GUI according to permissions
*/
- (void)updateAfterPermissionChanged
{
    [_delegate setControl:buttonDevice enabledAccordingToPermission:[@"drives_getiso", @"drives_get"]];
}

/*! update the editor according to the current drive to edit
*/
- (void)update
{
    [buttonDevice selectItemWithTitle:[_drive device]];

    [self updateAfterPermissionChanged];

    switch ([_drive device])
    {
        case TNLibvirtDeviceDiskDeviceDisk:
            if ([_delegate currentEntityHasPermission:@"drives_get"])
                [self getDisksInfo];
            break;

        case TNLibvirtDeviceDiskDeviceCDROM:
            if ([_delegate currentEntityHasPermission:@"drives_getiso"])
                [self getISOsInfo];
            break;
    }

    [self performDeviceTypeChanged:nil];

    [buttonDriverCache selectItemWithTitle:[[_drive driver] cache]];
    [buttonType selectItemWithTitle:[_drive type]];
    [self busTypeChanged:buttonTargetBus];
    [buttonTargetBus selectItemWithTitle:[[_drive target] bus]];
    [self busTypeChanged:buttonTargetBus];
    [self driveTypeDidChange:nil];
    [checkBoxTransient setState:([_drive isTransient]) ? CPOnState : CPOffState];
    [checkBoxShareable setState:([_drive isShareable]) ? CPOnState : CPOffState];
    [checkBoxReadOnly setState:([_drive isReadOnly]) ? CPOnState : CPOffState];
}


#pragma mark -
#pragma mark Actions

/*! saves the change
    @param aSender the sender of the action
*/
- (IBAction)save:(id)aSender
{
    if ([_drive type] != [buttonType title])
        [[_drive driver] setName:nil];

    [_drive setDevice:[buttonDevice title]];
    [_drive setType:[buttonType title]];

    switch ([buttonType title])
    {
        case TNLibvirtDeviceDiskTypeBlock:
            [[_drive source] setDevice:[fieldDevicePath stringValue]];
            [[_drive source] setFile:nil];
            [[_drive source] setHosts:nil];
            [[_drive source] setProtocol:nil];
            [[_drive source] setName:nil];
            break;

        case TNLibvirtDeviceDiskTypeNetwork:
            var host = [[TNLibvirtDeviceDiskSourceHost alloc] init],
                hostName = [fieldDevicePath stringValue].split("-")[0].split(":")[0],
                hostPort = [fieldDevicePath stringValue].split("-")[0].split(":")[1],
                hostProtocol = [fieldDevicePath stringValue].split("-")[1].split("/")[0],
                hostProtocolName = [fieldDevicePath stringValue].split("-")[1].split("/")[1];

            [host setName:hostName];
            [host setPort:hostPort];
            [[_drive source] setHosts:[]];
            [[[_drive source] hosts] addObject:host];
            [[_drive source] setDevice:nil];
            [[_drive source] setFile:nil];
            [[_drive source] setProtocol:hostProtocol];
            [[_drive source] setName:hostProtocolName];
            break;

        case TNLibvirtDeviceDiskTypeFile:
            [[_drive source] setFile:[[buttonSourcePath selectedItem] representedObject].path];
            [[_drive source] setDevice:nil];
            [[_drive source] setHosts:nil];
            [[_drive source] setProtocol:nil];
            [[_drive source] setName:nil];
            break;
    }

    if (![[_drive source] sourceObject] || [[_drive source] sourceObject] == @"")
    {
        [TNAlert showAlertWithMessage:CPLocalizedString(@"Source is not selected", @"Source is not selected")
                          informative:CPLocalizedString(@"You must select a source for your drive", @"You must select a source for your drive")];
        [mainPopover close];
        return;
    }

    [[_drive driver] setCache:[buttonDriverCache title]];
    [[_drive driver] setType:[[buttonSourcePath selectedItem] representedObject].format];
    [[_drive target] setBus:[buttonTargetBus title]];
    [[_drive target] setDevice:[buttonTargetDevice title]];

    [_drive setTransient:[checkBoxTransient state] == CPOnState ? YES : NO]
    [_drive setShareable:[checkBoxShareable state] == CPOnState ? YES : NO]
    [_drive setReadOnly:[checkBoxReadOnly state] == CPOnState ? YES : NO];

    if (![[_table dataSource] containsObject:_drive])
        [[_table dataSource] addObject:_drive];

    [_delegate setDefinitionEdited:YES];
    [_table reloadData];

    [mainPopover close];
}

/*! change the type of the drive
    @param aSender the sender of the action
*/
- (IBAction)performDeviceTypeChanged:(id)aSender
{
    var driveType = [buttonDevice title];

    switch (driveType)
    {
        case TNLibvirtDeviceDiskDeviceDisk:
            [self getDisksInfo];
            break;

        case TNLibvirtDeviceDiskDeviceCDROM:
            [self getISOsInfo];
            break;

        default:
            CPLog.warn("unrecognized disk type.");
    }
    [self busTypeChanged:aSender];
}

/*! Change the type of the drive (file or block)
    @param aSender the sender of the action
*/
- (IBAction)driveTypeDidChange:(id)aSender
{
    if ([buttonType title] == TNLibvirtDeviceDiskTypeBlock || [buttonType title] == TNLibvirtDeviceDiskTypeDir)
    {
        [fieldDevicePath setHidden:NO];
        [fieldDevicePath setEnabled:YES];
        [buttonSourcePath setHidden:YES];
        [buttonSourcePath setEnabled:NO];

        if (aSender)
            [fieldDevicePath setStringValue:@"/dev/cdrom"];
        else
            [fieldDevicePath setStringValue:[[_drive source] device]];
    }
    else if ([buttonType title] == TNLibvirtDeviceDiskTypeFile)
    {
        [fieldDevicePath setHidden:YES];
        [fieldDevicePath setEnabled:NO];
        [buttonSourcePath setHidden:NO];
        [buttonSourcePath setEnabled:YES];

        [fieldDevicePath setStringValue:@""];
    }
    else if ([buttonType title] == TNLibvirtDeviceDiskTypeNetwork)
    {
        [fieldDevicePath setHidden:NO];
        [fieldDevicePath setEnabled:YES];
        [buttonSourcePath setHidden:YES];
        [buttonSourcePath setEnabled:NO];

        if (aSender)
            [fieldDevicePath setStringValue:@"127.0.0.1:4242-sheepdog/myshare"];
        else
        {
            var host = [[[_drive source] hosts] firstObject],
                driveSource = [_drive source],
                hostname = [host name],
                port = [host port],
                protocol = [driveSource protocol],
                sourceName = [driveSource name],
                hostString = hostname + @":" + port + @"-" + protocol + @"/" + sourceName;

            [fieldDevicePath setStringValue:hostString];
        }
    }
}

/*! Called when changing the bus type. It will update the targets
    @param aSender the sender of the action
*/
- (IBAction)busTypeChanged:(id)aSender
{
    [buttonTargetDevice removeAllItems];

    switch ([buttonTargetBus title])
    {
        case TNLibvirtDeviceDiskTargetBusIDE:
            [buttonTargetDevice addItemsWithTitles:TNLibvirtDeviceDiskTargetDevicesIDE];
            break;
        case TNLibvirtDeviceDiskTargetBusSATA:
        case TNLibvirtDeviceDiskTargetBusSCSI:
            [buttonTargetDevice addItemsWithTitles:TNLibvirtDeviceDiskTargetDevicesSCSI];
            break;
        case TNLibvirtDeviceDiskTargetBusXEN:
            [buttonTargetDevice addItemsWithTitles:TNLibvirtDeviceDiskTargetDevicesXEN];
            break;
        case TNLibvirtDeviceDiskTargetBusVIRTIO:
            [buttonTargetDevice addItemsWithTitles:TNLibvirtDeviceDiskTargetDevicesVIRTIO];
            break;
        default:
            [buttonTargetDevice addItemsWithTitles:TNLibvirtDeviceDiskTargetDevices];
    }

    [self disableAlreadyUsedTargetDevices];

    switch ([buttonDevice title])
    {
        case TNLibvirtDeviceDiskDeviceDisk:
            for (var i = 0; i < [[buttonTargetDevice itemArray] count]; i++)
            {
                if ([[buttonTargetDevice itemAtIndex:i] isEnabled])
                {
                    [buttonTargetDevice selectItemAtIndex:i];
                    break;
                }
            }
            break;
        case  TNLibvirtDeviceDiskDeviceCDROM:
            for (var i = 2; i < [[buttonTargetDevice itemArray] count]; i++)
            {
                if ([[buttonTargetDevice itemAtIndex:i] isEnabled])
                {
                    [buttonTargetDevice selectItemAtIndex:i];
                    break;
                }
            }
            break;
        default:
            [buttonTargetDevice selectItemAtIndex:0];
    }

    if ([[buttonTargetDevice itemTitles] containsObject:[[_drive target] device]])
        [buttonTargetDevice selectItemWithTitle:[[_drive target] device]];

}

/*! show the main window
    @param aSender the sender of the action
*/
- (IBAction)openWindow:(id)aSender
{
    [mainPopover close];
    [self update];

    if ([aSender isKindOfClass:CPTableView])
    {
        var rect = [aSender rectOfRow:[aSender selectedRow]];
        rect.origin.y += rect.size.height / 2;
        rect.origin.x += rect.size.width / 2;
        [mainPopover showRelativeToRect:CGRectMake(rect.origin.x, rect.origin.y, 10, 10) ofView:aSender preferredEdge:nil];
    }
    else
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];

    [mainPopover setDefaultButton:buttonOK];
}

/*! hide the main window
    @param aSender the sender of the action
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close];
}


#pragma mark -
#pragma mark  XMPP Controls

/*! ask virtual machine for its drives
*/
- (void)getDisksInfo
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineDiskGet}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveDisksInfo:) ofObject:self];
}

/*! compute virtual machine drives
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveDisksInfo:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var disks = [aStanza childrenWithName:@"disk"];
        [buttonSourcePath removeAllItems];

        for (var i = 0; i < [disks count]; i++)
        {
            var disk    = [disks objectAtIndex:i],
                vSize   = [CPString formatByteSize:[disk valueForAttribute:@"virtualSize"]],
                dSize   = [CPString formatByteSize:[disk valueForAttribute:@"diskSize"]],
                format  = [disk valueForAttribute:@"format"],
                label   = [[[disk valueForAttribute:@"name"] componentsSeparatedByString:@"."] objectAtIndex:0] + " - " + vSize  + " (" + dSize + " used)",
                item    = [[CPMenuItem alloc] initWithTitle:label action:nil keyEquivalent:nil];

            [item setRepresentedObject:{"format": format, "path": [disk valueForAttribute:@"path"]}];
            [buttonSourcePath addItem:item];
        }

        [buttonSourcePath selectItemAtIndex:0];
        for (var i = 0; i < [[buttonSourcePath itemArray] count]; i++)
        {
            var item  = [[buttonSourcePath itemArray] objectAtIndex:i];

            if ([item representedObject].path == [[_drive source] file])
            {
                [buttonSourcePath selectItem:item];
                break;
            }
        }
    }

    return NO;
}

/*! ask virtual machine for avaiable ISOs
*/
- (void)getISOsInfo
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildWithName:@"archipel" andAttributes:{"action": TNArchipelTypeVirtualMachineISOGet}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(didReceiveISOsInfo:) ofObject:self];
}

/*! compute virtual machine ISOs
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)didReceiveISOsInfo:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var isos = [aStanza childrenWithName:@"iso"];

        [buttonSourcePath removeAllItems];

        for (var i = 0; i < [isos count]; i++)
        {
            var iso     = [isos objectAtIndex:i],
                label   = [iso valueForAttribute:@"name"],
                item    = [[CPMenuItem alloc] initWithTitle:label action:nil keyEquivalent:nil];

            [item setRepresentedObject:{"format": "raw", "path": [iso valueForAttribute:@"path"]}];
            [buttonSourcePath addItem:item];

        }

        [buttonSourcePath selectItemAtIndex:0];
        for (var i = 0; i < [[buttonSourcePath itemArray] count]; i++)
        {
            var item  = [[buttonSourcePath itemArray] objectAtIndex:i];

            if ([item representedObject].path == [[_drive source] file])
            {
                [buttonSourcePath selectItem:item];
                break;
            }
        }
    }

    return NO;
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNDriveController], comment);
}

