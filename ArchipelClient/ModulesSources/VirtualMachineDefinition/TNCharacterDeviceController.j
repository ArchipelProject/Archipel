/*
 * TNCharacterDeviceController.j
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

@import "Model/TNLibvirtDeviceCharacter.j"


/*! @ingroup virtualmachinedefinition
    this is the virtual character device editor
*/
@implementation TNCharacterDeviceController : CPObject
{
    @outlet CPPopUpButton       buttonKind;
    @outlet CPPopUpButton       buttonProtocolType;
    @outlet CPPopUpButton       buttonSourceMode;
    @outlet CPPopUpButton       buttonTargetType;
    @outlet CPPopUpButton       buttonType;
    @outlet CPButton            buttonOK;
    @outlet CPPopover           mainPopover;
    @outlet CPTextField         fieldSourceHost;
    @outlet CPTextField         fieldSourcePath;
    @outlet CPTextField         fieldSourceService;
    @outlet CPTextField         fieldTargetAddress;
    @outlet CPTextField         fieldTargetName;
    @outlet CPTextField         fieldTargetPort;

    CPTableView                 _table              @accessors(property=table);
    id                          _delegate           @accessors(property=delegate);
    TNLibvirtDeviceCharacter    _characterDevice    @accessors(property=characterDevice);
}

#pragma mark -
#pragma mark Initilization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [buttonKind removeAllItems];
    [buttonKind addItemsWithTitles:TNLibvirtDeviceCharacterKinds];

    [buttonType removeAllItems];
    [buttonType addItemsWithTitles:TNLibvirtDeviceCharacterTypes];

    [buttonSourceMode removeAllItems];
    [buttonSourceMode addItemsWithTitles:TNLibvirtDeviceCharacterSourceModes];

    [buttonTargetType removeAllItems];
    [buttonTargetType addItemsWithTitles:TNLibvirtDeviceConsoleTargetTypes];

    [buttonProtocolType removeAllItems];
    [buttonProtocolType addItemsWithTitles:TNLibvirtDeviceCharacterProtocolTypes];
}


#pragma mark -
#pragma mark Utilities

/*! update the editor according to the current graphic device to edit
*/
- (void)update
{
    [buttonKind selectItemWithTitle:[_characterDevice kind]];
    [self didDeviceKindChange:nil];
    // rest is computed trought the did*change chain.

    [buttonSourceMode selectItemWithTitle:[[_characterDevice source] mode] || TNLibvirtDeviceCharacterSourceModeNone];
    [buttonTargetType selectItemWithTitle:[[_characterDevice target] type] || TNLibvirtDeviceConsoleTargetTypeNone];
    [buttonProtocolType selectItemWithTitle:[[_characterDevice protocol] type] || TNLibvirtDeviceCharacterProtocolTypeRAW];

    [fieldSourceHost setStringValue:[[_characterDevice source] host] || @""];
    [fieldSourcePath setStringValue:[[_characterDevice source] path] || @""];
    [fieldSourceService setStringValue:[[_characterDevice source] service] || @""];
    [fieldTargetAddress setStringValue:[[_characterDevice target] address] || @""];
    [fieldTargetName setStringValue:[[_characterDevice target] name] || @""];
    [fieldTargetPort setStringValue:[[_characterDevice target] port] || @""];
}


#pragma mark -
#pragma mark Actions

/*! saves the change
    @param aSender the sender of the action
*/
- (IBAction)save:(id)aSender
{
    [_characterDevice setKind:[buttonKind title]];
    [_characterDevice setType:[buttonType title]];

    if (![_characterDevice source])
        [_characterDevice setSource:[[TNLibvirtDeviceCharacterSource alloc] init]];

    [[_characterDevice source] setMode:[buttonSourceMode title]];
    [[_characterDevice source] setHost:([fieldSourceHost stringValue] != @"") ? [fieldSourceHost stringValue] : nil];
    [[_characterDevice source] setService:([fieldSourceService stringValue] != @"") ? [fieldSourceService stringValue] : nil];
    [[_characterDevice source] setPath:([fieldSourcePath stringValue] != @"") ? [fieldSourcePath stringValue] : nil];

    if (![_characterDevice target])
        [_characterDevice setTarget:[[TNLibvirtDeviceCharacterTarget alloc] init]];

    [[_characterDevice target] setType:[buttonTargetType title]];
    [[_characterDevice target] setAddress:([fieldTargetAddress stringValue] != @"") ? [fieldTargetAddress stringValue] : nil];
    [[_characterDevice target] setPort:([fieldTargetPort stringValue] != @"") ? [fieldTargetPort stringValue] : nil];
    [[_characterDevice target] setName:([fieldTargetName stringValue] != @"") ? [fieldTargetName stringValue] : nil];

    if (![_characterDevice protocol])
        [_characterDevice setProtocol:[[TNLibvirtDeviceCharacterProtocol alloc] init]];

    [[_characterDevice protocol] setType:[buttonProtocolType title]];

    if (![[_table dataSource] containsObject:_characterDevice])
        [[_table dataSource] addObject:_characterDevice];

    [_delegate handleDefinitionEdition:YES];
    [_table reloadData];
    [mainPopover close];
    CPLog.debug("Generated character device XML is: " + [_characterDevice description]);
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
        [mainPopover showRelativeToRect:CPRectMake(rect.origin.x, rect.origin.y, 10, 10) ofView:aSender preferredEdge:nil];
    }
    else
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];

    [mainPopover setDefaultButton:buttonOK];
}

/*! Hide the main window
    @param aSender the sender of the action
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close];
}

/*! Update the UI for selected device kind
    @param aSender the sender of the action
*/
- (IBAction)didDeviceKindChange:(id)aSender
{
    [buttonType removeAllItems];

    switch ([buttonKind title])
    {
        case TNLibvirtDeviceCharacterKindConsole:
            [buttonType addItemsWithTitles:TNLibvirtDeviceCharacterTypesForConsole];
            break;

        case TNLibvirtDeviceCharacterKindSerial:
            [buttonType addItemsWithTitles:TNLibvirtDeviceCharacterTypesForSerial];
            break;

        case TNLibvirtDeviceCharacterKindChannel:
            [buttonType addItemsWithTitles:TNLibvirtDeviceCharacterTypesForChannel];
            break;

        case TNLibvirtDeviceCharacterKindParallel:
            [buttonType addItemsWithTitles:TNLibvirtDeviceCharacterTypesForParallel];
            break;
    }

    if ([buttonType itemWithTitle:[_characterDevice type]])
        [buttonType selectItemWithTitle:[_characterDevice type]];
    else
        [buttonType selectItemAtIndex:0];

    [self didDeviceTypeChange:nil];
}

/*! Update the UI for selected device type
    @param aSender the sender of the action
*/
- (IBAction)didDeviceTypeChange:(id)aSender
{
    switch ([buttonType title])
    {
        case TNLibvirtDeviceCharacterTypeUNIX:
        case TNLibvirtDeviceCharacterTypePTY:
        case TNLibvirtDeviceCharacterTypeFILE:
        case TNLibvirtDeviceCharacterTypeDEV:
        case TNLibvirtDeviceCharacterTypePIPE:
            [fieldSourcePath setEnabled:YES];
            [fieldSourceHost setEnabled:NO];
            [fieldSourceService setEnabled:NO];
            break;

        case TNLibvirtDeviceCharacterTypeNULL:
            [fieldSourcePath setEnabled:NO];
            [fieldSourceHost setEnabled:NO];
            [fieldSourceService setEnabled:NO];
            break;

        case TNLibvirtDeviceCharacterTypeUDP:
        case TNLibvirtDeviceCharacterTypeTCP:
            [fieldSourcePath setEnabled:NO];
            [fieldSourceHost setEnabled:YES];
            [fieldSourceService setEnabled:YES];
            break;

        default:
            [fieldSourcePath setEnabled:YES];
            [fieldSourceHost setEnabled:YES];
            [fieldSourceService setEnabled:YES];
            break;
    }
}

/*! Update the UI for the selected source mode
    @param aSender the sender of the action
*/
- (IBAction)didSourceModeChange:(id)aSender
{
    switch ([buttonSourceMode title])
    {
    }
}

/*! Update the UI for selected target type
    @param aSender the sender of the action
*/
- (IBAction)didTargetTypeChange:(id)aSender
{
    switch ([buttonTargetType title])
    {
    }
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNCharacterDeviceController], comment);
}
