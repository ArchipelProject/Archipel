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

@import <TNKit/TNAttachedWindow.j>


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
    [buttonKeymap setToolTip:CPLocalizedString(@"Select the keymap to use", @"Select the keymap to use")];

    [buttonType removeAllItems];
    [buttonType addItemsWithTitles:[TNLibvirtDeviceGraphicTypeVNC, TNLibvirtDeviceGraphicTypeRDP]];
    [buttonType setToolTip:CPLocalizedString(@"Set the graphic type", @"Set the graphic type")];

    [fieldPassword setToolTip:CPBundleLocalizedString(@"Set the VNC password (no password if blank)", @"Set the VNC password (no password if blank)")];
    [fieldListenAddress setToolTip:CPLocalizedString(@"Set the real VNC Server (not the websocket proxy) listen addr. Leave blank for qemu default (127.0.0.1)", @"Set the real VNC Server (not the websocket proxy) listen addr. Leave blank for qemu default (127.0.0.1)")];
    [fieldListenPort setToolTip:CPLocalizedString(@"Set the real VNC server listen port. leave it to blank for autoport", @"Set the real VNC server listen port. leave it to blank for autoport")];

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
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNGraphicDeviceController], comment);
}
