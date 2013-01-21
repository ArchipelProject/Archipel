/*
 * TNGraphicDeviceController.j
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
@import <AppKit/CPTableView.j>

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle


/*! @ingroup virtualmachinedefinition
    this is the virtual graphic editor
*/
@implementation TNGraphicDeviceController : CPObject
{
    @outlet CPButton        buttonOK;
    @outlet CPPopover       mainPopover;
    @outlet CPPopUpButton   buttonKeymap;
    @outlet CPPopUpButton   buttonType;
    @outlet CPTextField     fieldPassword;
    @outlet CPTextField     fieldListenAddress;
    @outlet CPTextField     fieldListenPort;

    CPTableView             _table          @accessors(property=table);
    id                      _delegate       @accessors(property=delegate);
    TNLibvirtDeviceGraphic  _graphicDevice  @accessors(property=graphicDevice);
}

#pragma mark -
#pragma mark Initilization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [fieldPassword setSecure:YES];

    [buttonKeymap removeAllItems];
    [buttonKeymap addItemsWithTitles:TNLibvirtDeviceGraphicVNCKeymaps];

    [buttonType removeAllItems];
    [buttonType addItemsWithTitles:[TNLibvirtDeviceGraphicTypeVNC, TNLibvirtDeviceGraphicTypeRDP, TNLibvirtDeviceGraphicTypeSPICE]];
}


#pragma mark -
#pragma mark Utilities

/*! update the editor according to the current graphic device to edit
*/
- (void)update
{
    [buttonKeymap selectItemWithTitle:[_graphicDevice keymap]];
    [buttonType selectItemWithTitle:[_graphicDevice type]];
    [fieldPassword setStringValue:[_graphicDevice password]];
    [fieldListenAddress setStringValue:([_graphicDevice listen] && [_graphicDevice listen] != @"") ? [_graphicDevice listen] : @""];
    [fieldListenPort setStringValue:([_graphicDevice port] && [_graphicDevice port] != @"-1") ? [_graphicDevice port] : @""];

    [self graphicTypeChange:nil];
}


#pragma mark -
#pragma mark Actions

/*! saves the change
    @param aSender the sender of the action
*/
- (IBAction)save:(id)aSender
{
    [_graphicDevice setType:[buttonType title]];
    [_graphicDevice setKeymap:[buttonKeymap title]];
    [_graphicDevice setListen:[fieldListenAddress stringValue]];
    [_graphicDevice setPort:[fieldListenPort stringValue]];
    [_graphicDevice setPassword:[fieldPassword stringValue]];
    [_graphicDevice setAutoPort:([fieldListenPort stringValue] == @"")];

    if (![[_table dataSource] containsObject:_graphicDevice])
        [[_table dataSource] addObject:_graphicDevice];

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
        rect.origin.y += rect.size.height / 2;
        rect.origin.x += rect.size.width / 2;
        [mainPopover showRelativeToRect:CGRectMake(rect.origin.x, rect.origin.y, 10, 10) ofView:aSender preferredEdge:nil];
    }
    else
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];

    [mainPopover setDefaultButton:buttonOK];
}

/*! Called to update the GUI when graphic type change
    @param aSender the sender of the action
*/
- (IBAction)graphicTypeChange:(id)aSender
{
    switch ([buttonType title])
    {
        case TNLibvirtDeviceGraphicTypeVNC:

            [fieldPassword setEnabled:YES];
            [fieldListenAddress setEnabled:YES];
            break;
        default:
            [fieldPassword setStringValue:@""];
            [fieldListenAddress setStringValue:@""];
            [fieldPassword setEnabled:NO];
            [fieldListenAddress setEnabled:NO];
    }
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
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNGraphicDeviceController], comment);
}
