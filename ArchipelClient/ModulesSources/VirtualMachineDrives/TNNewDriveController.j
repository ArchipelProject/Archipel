/*
 * TNNewDriveController.j
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

@import <AppKit/CPCheckBox.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPPopover.j>

@import <TNKit/TNAlert.j>
@import <StropheCappuccino/TNStropheStanza.j>

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNArchipelDrivesFormats


var TNArchipelTypeVirtualMachineDisk            = @"archipel:vm:disk",
    TNArchipelTypeVirtualMachineDiskCreate      = @"create",
    TNArchipelTypeVirtualMachineDiskGoldenList  = @"getgolden";


@implementation TNNewDriveController : CPObject
{
    @outlet CPButton        buttonOK;
    @outlet CPCheckBox      checkBoxUseMasterDrive;
    @outlet CPCheckBox      checkBoxUseQCOW2Preallocation;
    @outlet CPPopover       mainPopover;
    @outlet CPPopUpButton   buttonGoldenDrive;
    @outlet CPPopUpButton   buttonNewDiskFormat;
    @outlet CPPopUpButton   buttonNewDiskSizeUnit;
    @outlet CPTextField     fieldNewDiskName;
    @outlet CPTextField     fieldNewDiskSize;

    id                      _delegate   @accessors(property=delegate);
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awakening
*/
- (void)awakeFromCib
{
    [buttonNewDiskFormat removeAllItems];
    [buttonNewDiskFormat addItemsWithTitles:TNArchipelDrivesFormats];

    [buttonNewDiskSizeUnit removeAllItems];
    [buttonNewDiskSizeUnit addItemsWithTitles:[CPBundleLocalizedString(@"GB", @"GB"), CPBundleLocalizedString(@"MB", @"MB")]];

    [fieldNewDiskName setValue:[CPColor grayColor] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];
    [fieldNewDiskSize setValue:[CPColor grayColor] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];
}


#pragma mark -
#pragma mark Utilities

/*! open the controller window
*/
- (IBAction)openWindow:(id)aSender
{
    [buttonGoldenDrive removeAllItems];
    [self getGoldenList];
    [fieldNewDiskName setStringValue:@""];
    [fieldNewDiskSize setStringValue:@""];
    [buttonNewDiskFormat selectItemWithTitle:@"qcow2"];
    [self diskCreationFormatChanged:nil];

    [buttonGoldenDrive setEnabled:NO];
    [checkBoxUseMasterDrive setEnabled:YES];
    [checkBoxUseQCOW2Preallocation setEnabled:YES];
    [checkBoxUseMasterDrive setState:CPOffState];
    [checkBoxUseQCOW2Preallocation setState:CPOffState];

    [mainPopover close];
    [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [mainPopover setDefaultButton:buttonOK];
    [mainPopover makeFirstResponder:fieldNewDiskName];
}

/*! close the controller window
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close];
}


#pragma mark -
#pragma mark Actions

/*! called when format of the drive changed
*/
- (IBAction)diskCreationFormatChanged:(id)aSender
{
    if ([buttonNewDiskFormat title] == @"qcow2")
    {
        [checkBoxUseQCOW2Preallocation setHidden:NO];
        [checkBoxUseMasterDrive setHidden:NO];
        [buttonGoldenDrive setHidden:NO];
    }
    else
    {
        [checkBoxUseQCOW2Preallocation setHidden:YES];
        [checkBoxUseMasterDrive setHidden:YES];
        [buttonGoldenDrive setHidden:YES];
    }
}

/*! handle mutual exclusion of the checkboxes
*/
- (IBAction)didCheckBoxesChange:(id)aSender
{
    if ([checkBoxUseQCOW2Preallocation state] == CPOnState)
    {
        [checkBoxUseMasterDrive setState:CPOffState];
        [checkBoxUseMasterDrive setEnabled:NO];
        [buttonGoldenDrive setEnabled:NO];
        return;
    }
    else
    {
        [checkBoxUseMasterDrive setEnabled:YES];
        [buttonGoldenDrive setEnabled:NO];
    }

    if ([checkBoxUseMasterDrive state] == CPOnState)
    {
        [checkBoxUseQCOW2Preallocation setState:CPOffState];
        [checkBoxUseQCOW2Preallocation setEnabled:NO];
        [buttonGoldenDrive setEnabled:YES];
        return;
    }
    else
    {
        [checkBoxUseQCOW2Preallocation setEnabled:YES];
        [buttonGoldenDrive setEnabled:NO];
    }
}


/*! creates a disk
    @param aSender the sender of the action
*/
- (IBAction)createDisk:(id)aSender
{
    [self createDisk];
}


#pragma mark -
#pragma mark XMPP Controls

/*! asks virtual machine to create a new disk
*/
- (void)getGoldenList
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "xmlns": TNArchipelTypeVirtualMachineDisk,
        "action": TNArchipelTypeVirtualMachineDiskGoldenList}];

    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didGetGoldenList:) ofObject:self];
}

- (BOOL)_didGetGoldenList:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"error")
    {
        [_delegate handleIqErrorFromStanza:aStanza];
        return NO;
    }

    var goldens = [aStanza childrenWithName:@"golden"];

    [buttonGoldenDrive removeAllItems];
    for (var i = 0; i < [goldens count]; i++)
        [buttonGoldenDrive addItemWithTitle:[[goldens objectAtIndex:i] valueForAttribute:@"name"]];

    [buttonGoldenDrive selectItemAtIndex:0];
    return NO;
}


/*! asks virtual machine to create a new disk
*/
- (void)createDisk
{
    var dUnit,
        dName       = [fieldNewDiskName stringValue],
        dSize       = [fieldNewDiskSize stringValue],
        format      = [buttonNewDiskFormat title],
        prealloc    = ((format == @"qcow2") && ([checkBoxUseQCOW2Preallocation state] == CPOnState)),
        golden      = ((format == @"qcow2") && ([checkBoxUseMasterDrive state] == CPOnState));

    if (dSize == @"" || isNaN(dSize))
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPBundleLocalizedString(@"You must enter a numeric value", @"You must enter a numeric value")
                                style:CPCriticalAlertStyle];
        return;
    }

    if (dName == @"")
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPBundleLocalizedString(@"You must enter a valid name", @"You must enter a valid name")
                                style:CPCriticalAlertStyle];
        return;
    }

    switch ([buttonNewDiskSizeUnit title])
    {
        case CPBundleLocalizedString(@"GB", @"GB"):
            dUnit = "G";
            break;

        case CPBundleLocalizedString(@"MB", @"MB"):
            dUnit = "M";
            break;
    }

    var stanza  = [TNStropheStanza iqWithType:@"set"],
        params  = {"action": TNArchipelTypeVirtualMachineDiskCreate, "name": dName, "size": dSize, "unit": dUnit, "format": format};

    if (prealloc)
        params.preallocation = "metadata";

    if (golden)
        params.golden = [buttonGoldenDrive title];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildWithName:@"archipel" andAttributes:params];
    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didCreateDisk:) ofObject:self];
    [mainPopover close];
    [fieldNewDiskName setStringValue:@""];
    [fieldNewDiskSize setStringValue:@""];
}

/*! compute virtual machine disk creation results
    @param aStanza TNStropheStanza that contains the answer
*/
- (BOOL)_didCreateDisk:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"error")
        [_delegate handleIqErrorFromStanza:aStanza];

    return NO;
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNNewDriveController], comment);
}
