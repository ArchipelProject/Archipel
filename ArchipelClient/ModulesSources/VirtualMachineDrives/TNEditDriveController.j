/*
 * TNEditDriveController.j
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

@import <AppKit/CPButton.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNAlert.j>

@import "TNDriveObject.j"


var TNArchipelTypeVirtualMachineDisk        = @"archipel:vm:disk",
    TNArchipelTypeVirtualMachineDiskConvert = @"convert",
    TNArchipelTypeVirtualMachineDiskRename  = @"rename";


@implementation TNEditDriveController : CPObject
{
    @outlet CPButton                buttonConvert;
    @outlet CPButton                buttonOK;
    @outlet CPPopover               mainPopover;
    @outlet CPPopUpButton           buttonEditDiskFormat;
    @outlet CPTextField             fieldEditDiskName;

    id                              _delegate           @accessors(property=delegate);
    CPDictionary                    _currentEditedDisk  @accessors(property=currentEditedDisk);
}


#pragma mark -
#pragma mark Initialization

/*! call at cib awakening
*/
- (void)awakeFromCib
{
    [buttonEditDiskFormat removeAllItems];
    [buttonEditDiskFormat addItemsWithTitles:TNArchipelDrivesFormats];

    [fieldEditDiskName setToolTip:CPBundleLocalizedString(@"Set the name of the virtual drive", @"Set the name of the virtual drive")];
    [buttonEditDiskFormat setToolTip:CPBundleLocalizedString(@"Choose the format of the virtual drive", @"Choose the format of the virtual drive")];
}


#pragma mark -
#pragma mark Utilities

/*! open the controller window
*/
- (IBAction)openWindow:(id)aSender
{
    [mainPopover close];
    if (!_currentEditedDisk)
    {
        CPLog.error("Cannot open edit panel without having a drive to edit");
        return;
    }

    var backingFile = [_currentEditedDisk backingFile];
    if (backingFile && backingFile != @"")
    {
        [buttonEditDiskFormat setEnabled:NO];
        [buttonConvert setEnabled:NO];
    }
    else
    {
        [buttonEditDiskFormat setEnabled:YES];
        [buttonConvert setEnabled:YES];
    }

    [buttonEditDiskFormat selectItemWithTitle:[_currentEditedDisk format]];
    [fieldEditDiskName setStringValue:[_currentEditedDisk name]];

    if ([aSender isKindOfClass:CPTableView])
    {
        var rect = [aSender rectOfRow:[aSender selectedRow]];
        rect.origin.y += rect.size.height;
        rect.origin.x += rect.size.width / 2;
        [mainPopover showRelativeToRect:CPRectMake(rect.origin.x, rect.origin.y, 10, 19) ofView:aSender preferredEdge:CPMaxYEdge];
    }
    else
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];

    [mainPopover makeFirstResponder:fieldEditDiskName];
    [mainPopover setDefaultButton:buttonOK];
}

/*! close the controller window
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close];
}


#pragma mark -
#pragma mark Actions

/*! converts a disk
    @param aSender the sender of the action
*/
- (IBAction)convert:(id)aSender
{
    [self convert];
}

/*! rename a disk
    @param aSender the sender of the action
*/
- (IBAction)rename:(id)aSender
{
    [self rename];
}



#pragma mark -
#pragma mark XMPP Controls

/*! asks virtual machine to connvert a disk
*/
- (void)convert
{
    if (_currentEditedDisk && [_currentEditedDisk format] == [buttonEditDiskFormat title])
    {
        [TNAlert showAlertWithMessage:CPBundleLocalizedString(@"Error", @"Error")
                          informative:CPBundleLocalizedString(@"You must choose a different format", @"You must choose a different format")];
        return;
    }

    var stanza          = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineDiskConvert,
        "path": [_currentEditedDisk path],
        "format": [buttonEditDiskFormat title]}];

    [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didConvertDisk:) ofObject:self];

    [mainPopover close];
}

/*! compute virtual machine disk conversion results
    @param aStanza TNStropheStanza that contains the answer
*/
- (BOOL)_didConvertDisk:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                         message:CPBundleLocalizedString(@"Disk has been converted", @"Disk has been converted")];
    else if ([aStanza type] == @"error")
        [_delegate handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! asks virtual machine to rename a disk
*/
- (void)rename
{
    if ([_delegate isEntityOnline])
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                         message:CPBundleLocalizedString(@"You can't edit disks of a running virtual machine", @"You can't edit disks of a running virtual machine") icon:TNGrowlIconError];
        return;
    }

    if ([fieldEditDiskName stringValue] != [_currentEditedDisk name])
    {
        [_currentEditedDisk setName:[fieldEditDiskName stringValue]];

        var stanza = [TNStropheStanza iqWithType:@"set"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineDisk}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "xmlns": TNArchipelTypeVirtualMachineDisk,
            "action": TNArchipelTypeVirtualMachineDiskRename,
            "path": [_currentEditedDisk path],
            "newname": [_currentEditedDisk name]}];

        [[_delegate entity] sendStanza:stanza andRegisterSelector:@selector(_didRename:) ofObject:self];
    }

   [mainPopover close];
}

/*! compute virtual machine disk renaming results
    @param aStanza TNStropheStanza that contains the answer
*/
- (BOOL)_didRename:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                         message:CPBundleLocalizedString(@"Disk has been renamed", @"Disk has been renamed")];
    else if ([aStanza type] == @"error")
        [_delegate handleIqErrorFromStanza:aStanza];

    return NO;
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNEditDriveController], comment);
}

