/*
 * TNInputDeviceController.j
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
@import <AppKit/CPView.j>

@import <TNKit/TNAttachedWindow.j>


/*! @ingroup virtualmachinedefinition
    this is the virtual nic editor
*/
@implementation TNInputDeviceController : CPObject
{
    @outlet CPButton        buttonOK;
    @outlet CPPopover       mainPopover;
    @outlet CPPopUpButton   buttonBus;
    @outlet CPPopUpButton   buttonType;

    CPTableView             _table          @accessors(property=table);
    id                      _delegate       @accessors(property=delegate);
    TNLibvirtDeviceInput    _inputDevice    @accessors(property=inputDevice);
}

#pragma mark -
#pragma mark Initilization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [buttonType removeAllItems];
    [buttonBus removeAllItems];

    [buttonType addItemsWithTitles:TNLibvirtDeviceInputTypes];
    [buttonBus addItemsWithTitles:TNLibvirtDeviceInputBuses];

    [buttonBus setToolTip:CPLocalizedString(@"Set the bus of the input device", @"Set the bus of the input device")];
    [buttonType setToolTip:CPLocalizedString(@"Set the type of the input device", @"Set the type of the input device")];
}


#pragma mark -
#pragma mark Utilities

/*! update the editor according to the current nic to edit
*/
- (void)update
{
    [buttonType selectItemWithTitle:[_inputDevice type]];
    [buttonBus selectItemWithTitle:[_inputDevice bus]];
}


#pragma mark -
#pragma mark Actions

/*! saves the change
    @param aSender the sender of the action
*/
- (IBAction)save:(id)aSender
{
    [_inputDevice setType:[buttonType title]];
    [_inputDevice setBus:[buttonBus title]];

    [_delegate handleDefinitionEdition:YES];
    [_table reloadData];
    [mainPopover close];
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
        rect.origin.y += rect.size.height;
        rect.origin.x += rect.size.width / 2;
        var point = [[aSender superview] convertPoint:rect.origin toView:nil];
        [mainPopover showRelativeToRect:CPRectMake(point.x, point.y, 10, 10) ofView:nil preferredEdge:CPMaxYEdge];
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


@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNInputDeviceController], comment);
}
