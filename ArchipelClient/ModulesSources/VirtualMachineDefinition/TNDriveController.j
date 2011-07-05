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

var TNArchipelTypeVirtualMachineDisk        = @"archipel:vm:disk",
    TNArchipelTypeVirtualMachineDiskGet     = @"get",
    TNArchipelTypeVirtualMachineISOGet      = @"getiso";

/*! @ingroup virtualmachinedefinition
    this is the virtual drive editor
*/
@implementation TNDriveController : CPObject
{
    @outlet CPButton        buttonOK;
    @outlet CPPopUpButton   buttonDevice;
    @outlet CPPopUpButton   buttonDriverCache;
    @outlet CPPopUpButton   buttonSourcePath;
    @outlet CPPopUpButton   buttonTargetBus;
    @outlet CPPopUpButton   buttonTargetDevice;
    @outlet CPPopUpButton   buttonType;
    @outlet CPTextField     fieldDevicePath;
    @outlet CPWindow        mainWindow;

    id                      _delegate       @accessors(property=delegate);
    CPTableView             _table          @accessors(property=table);
    TNLibvirtDeviceDisk     _drive          @accessors(property=drive);
    TNStropheContact        _entity         @accessors(property=entity);
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [mainWindow setDefaultButton:buttonOK];

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

    [buttonTargetBus setToolTip:CPBundleLocalizedString(@"Set the bus to use for the drive", @"Set the bus to use for the drive")];
    [buttonSourcePath setToolTip:CPBundleLocalizedString(@"Set the source to use for the drive", @"Set the source to use for the drive")];
    [buttonTargetDevice setToolTip:CPBundleLocalizedString(@"Set the target to use for the drive", @"Set the target to use for the drive")];
    [buttonDriverCache setToolTip:CPBundleLocalizedString(@"Set the cache mode the drive", @"Set the cache mode the drive")];
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

    [buttonDriverCache selectItemWithTitle:[[_drive driver] cache]];
    [buttonType selectItemWithTitle:[_drive type]];
    [buttonTargetDevice selectItemWithTitle:[[_drive target] device]];
    [buttonTargetBus selectItemWithTitle:[[_drive target] bus]];

    [self driveTypeDidChange:nil];
}


#pragma mark -
#pragma mark Actions

/*! saves the change
    @param aSender the sender of the action
*/
- (IBAction)save:(id)aSender
{
    [_drive setDevice:[buttonDevice title]];
    [_drive setType:[buttonType title]];

    switch ([buttonType title])
    {
        case TNLibvirtDeviceDiskTypeBlock:
            [[_drive source] setDevice:[fieldDevicePath stringValue]];
            [[_drive source] setFile:nil];
            break;

        case TNLibvirtDeviceDiskTypeFile:
            [[_drive source] setFile:[[buttonSourcePath selectedItem] stringValue]];
            [[_drive source] setDevice:nil];
            break;
    }

    [[_drive driver] setCache:[buttonDriverCache title]];
    [[_drive driver] setType:[[buttonSourcePath selectedItem] objectValue]];
    [[_drive target] setBus:[buttonTargetBus title]];
    [[_drive target] setDevice:[buttonTargetDevice title]];

    [_table reloadData];

    [_delegate handleDefinitionEdition:YES];
    [mainWindow close];
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
}

/*! hange the type of the drive (file or block)
    @param aSender the sender of the action
*/
- (IBAction)driveTypeDidChange:(id)aSender
{
    if ([buttonType title] == TNLibvirtDeviceDiskTypeBlock)
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
}

/*! show the main window
    @param aSender the sender of the action
*/
- (IBAction)showWindow:(id)aSender
{
    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];

    [self update];
}

/*! hide the main window
    @param aSender the sender of the action
*/
- (IBAction)hideWindow:(id)aSender
{
    [mainWindow close];
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
                vSize   = [[[disk valueForAttribute:@"virtualSize"] componentsSeparatedByString:@" "] objectAtIndex:0],
                format  = [disk valueForAttribute:@"format"],
                label   = [[[disk valueForAttribute:@"name"] componentsSeparatedByString:@"."] objectAtIndex:0] + " - " + vSize  + " (" + [disk valueForAttribute:@"diskSize"] + ")",
                item    = [[TNMenuItem alloc] initWithTitle:label action:nil keyEquivalent:nil];
            [item setStringValue:[disk valueForAttribute:@"path"]];
            [item setObjectValue:format];
            [buttonSourcePath addItem:item];
        }

        for (var i = 0; i < [[buttonSourcePath itemArray] count]; i++)
        {
            var item  = [[buttonSourcePath itemArray] objectAtIndex:i];

            if ([item stringValue] == [[_drive source] file])
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
                item    = [[TNMenuItem alloc] initWithTitle:label action:nil keyEquivalent:nil];

            [item setStringValue:[iso valueForAttribute:@"path"]];
            [item setObjectValue:"raw"];
            [buttonSourcePath addItem:item];

        }

        [buttonSourcePath selectItemAtIndex:0];
        for (var i = 0; i < [[buttonSourcePath itemArray] count]; i++)
        {
            var item  = [[buttonSourcePath itemArray] objectAtIndex:i];

            if ([item stringValue] == [[_drive source] file])
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

