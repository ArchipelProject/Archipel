/*
 * TNWindowNICEdition.j
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


var TNArchipelTypeHypervisorNetwork             = @"archipel:hypervisor:network",
    TNArchipelTypeHypervisorNetworkGetNames     = @"getnames",
    TNArchipelTypeHypervisorNetworkBridges      = @"bridges",
    TNArchipelTypeHypervisorNetworkGetNWFilters = @"getnwfilters";

/*! @ingroup virtualmachinedefinition
    this is the virtual nic editor
*/
@implementation TNNetworkController : CPObject
{
    @outlet CPButton        buttonOK;
    @outlet CPButtonBar     buttonBarNetworkParameters;
    @outlet CPPopUpButton   buttonModel;
    @outlet CPPopUpButton   buttonNetworkFilter;
    @outlet CPPopUpButton   buttonSource;
    @outlet CPPopUpButton   buttonType;
    @outlet CPTableView     tableViewNetworkFilterParameters;
    @outlet CPTextField     fieldMac;
    @outlet CPView          viewNWFilterParametersContainer;
    @outlet CPWindow        mainWindow;

    id                      _delegate   @accessors(property=delegate);
    CPTableView             _table      @accessors(property=table);
    TNNetworkInterface      _nic        @accessors(property=nic);
    TNStropheContact        _entity     @accessors(property=entity);

    TNTableViewDataSource   _datasourceNWFilterParameters;
}

#pragma mark -
#pragma mark Initilization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewNWFilterParametersContainer setBorderedWithHexColor:@"#C0C7D2"];

    [mainWindow setDefaultButton:buttonOK];

    [buttonType removeAllItems];
    [buttonModel removeAllItems];
    [buttonSource removeAllItems];
    [buttonNetworkFilter removeAllItems];

    [buttonModel addItemsWithTitles:TNLibvirtDeviceInterfaceModels];
    [buttonType addItemsWithTitles: TNLibvirtDeviceInterfaceTypes];

    [buttonSource setToolTip:CPBundleLocalizedString(@"Set the source to use", @"Set the source to use")];
    [buttonModel setToolTip:CPBundleLocalizedString(@"Set the model of the card", @"Set the model of the card")];
    [fieldMac setToolTip:CPBundleLocalizedString(@"Set the MAC address of the card", @"Set the MAC address of the card")];

    var addButton  = [CPButtonBar plusButton];
    [addButton setTarget:self];
    [addButton setAction:@selector(addNWFilterParameter:)];

    var removeButton  = [CPButtonBar minusButton];
    [removeButton setTarget:self];
    [removeButton setAction:@selector(removeNWFilterParameter:)];

    [buttonBarNetworkParameters setButtons:[addButton, removeButton]];
}


#pragma mark -
#pragma mark Utilities

/*! send this message to update GUI according to permissions
*/
- (void)updateAfterPermissionChanged
{
    [_delegate setControl:buttonType enabledAccordingToPermissions:[@"network_getnames", @"network_bridges"]]
}

/*! update the editor according to the current nic to edit
*/
- (void)update
{
    [buttonSource removeAllItems];
    [buttonNetworkFilter removeAllItems];

    [buttonType selectItemWithTitle:[_nic type]];

    [self performNicTypeChanged:nil];
    [self updateAfterPermissionChanged];

    [buttonModel selectItemWithTitle:[_nic model]];

    [fieldMac setStringValue:[_nic MAC]];

    _datasourceNWFilterParameters = [[TNTableViewDataSource alloc] init];
    [tableViewNetworkFilterParameters setDataSource:_datasourceNWFilterParameters];
    [_datasourceNWFilterParameters setTable:tableViewNetworkFilterParameters];
    [_datasourceNWFilterParameters removeAllObjects];

    if ([_nic filterref])
        [_datasourceNWFilterParameters setContent:[[_nic filterref] parameters]];
    [tableViewNetworkFilterParameters reloadData];
}


#pragma mark -
#pragma mark Actions


/*! add a new entry in the network filter parameter
    @param aSender the sender of the action
*/
- (void)addNWFilterParameter:(id)aSender
{
    [_datasourceNWFilterParameters addObject:[CPDictionary dictionaryWithObjectsAndKeys:@"parameter", @"name", @"value", @"value"]];
    [tableViewNetworkFilterParameters reloadData];
}

/*! remove the selected network filter parameter entries.
    @param aSender the sender of the action
*/
- (void)removeNWFilterParameter:(id)aSender
{
    var index = [tableViewNetworkFilterParameters selectedRow];

    if (index != -1)
        [_datasourceNWFilterParameters removeObjectAtIndex:index];

    [tableViewNetworkFilterParameters reloadData];
}

/*! saves the change
    @param aSender the sender of the action
*/
- (IBAction)save:(id)aSender
{
    [_nic setMAC:[fieldMac stringValue]];
    [_nic setModel:[buttonModel title]];
    [_nic setType:[buttonType title]];

    if (![_nic source])
    {
        var source = [[TNLibvirtDeviceInterfaceSource alloc] init];
        [_nic setSource:source]
    }

    switch ([_nic type])
    {
        case TNLibvirtDeviceInterfaceTypeNetwork:
            [[_nic source] setNetwork:[buttonSource title]];
            [[_nic source] setBridge:nil];
            [[_nic source] setDevice:nil];
            break;
        case TNLibvirtDeviceInterfaceTypeBridge:
            [[_nic source] setNetwork:nil];
            [[_nic source] setBridge:[buttonSource title]];
            [[_nic source] setDevice:nil];
            break;
        case TNLibvirtDeviceInterfaceTypeUser:
            [[_nic source] setNetwork:nil];
            [[_nic source] setBridge:nil];
            [[_nic source] setDevice:nil];
            break;
    }

    if ([buttonNetworkFilter title] != @"None")
    {
        var filter = [[TNLibvirtDeviceInterfaceFilterRef alloc] init];

        [filter setName:[buttonNetworkFilter title]];
        [filter setParameters:[_datasourceNWFilterParameters content]];

        [_nic setFilterref:filter];
    }
    else
        [_nic setFilterref:nil];

    [_delegate handleDefinitionEdition:YES];
    [_table reloadData];
    [mainWindow close];
}

/*! change the type of the network
    @param aSender the sender of the action
*/
- (IBAction)performNicTypeChanged:(id)aSender
{
    var nicType = [buttonType title];

    switch (nicType)
    {
        case TNLibvirtDeviceInterfaceTypeNetwork:
            if ([_delegate currentEntityHasPermission:@"network_getnames"])
            {
                [_delegate setControl:buttonSource enabledAccordingToPermission:@"network_getnames"];
                [buttonSource removeAllItems];
                [self getHypervisorNetworks];
            }
            else
                [buttonSource setEnabled:NO];
            break;

        case TNLibvirtDeviceInterfaceTypeBridge:
            if ([_delegate currentEntityHasPermission:@"network_bridges"])
            {
                [_delegate setControl:buttonSource enabledAccordingToPermission:@"network_bridges"];
                [buttonSource removeAllItems];
                [self getBridges];
            }
            else
                [buttonSource setEnabled:NO]
            break;

        case TNLibvirtDeviceInterfaceTypeUser:
            [buttonSource removeAllItems];
            [buttonSource setEnabled:NO];
            break;
    }

    [self getHypervisorNWFilters];
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
#pragma mark XMPP Controls

/*! ask hypervisor for its networks
*/
- (void)getHypervisorNetworks
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkGetNames}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorNetworks:) ofObject:self];
}

/*! compute hypervisor networks
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveHypervisorNetworks:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var names = [aStanza childrenWithName:@"network"];

        for (var i = 0; i < [names count]; i++)
        {
            var name = [[names objectAtIndex:i] valueForAttribute:@"name"];

            [buttonSource addItemWithTitle:name];
        }

        [buttonSource selectItemWithTitle:[[_nic source] network]];

        if (![buttonSource selectedItem])
            [buttonSource selectItemAtIndex:0];
    }
    else
    {
        [_delegate handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! ask hypervisor for its bridges
*/
- (void)getBridges
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkBridges}];
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveBridges:) ofObject:self];
}

/*! compute hypervisor bridges
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveBridges:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var bridges = [aStanza childrenWithName:@"bridge"];

        [buttonSource removeAllItems];
        for (var i = 0; i < [bridges count]; i++)
        {
            var bridge = [[bridges objectAtIndex:i] valueForAttribute:@"name"];

            [buttonSource addItemWithTitle:bridge];
        }
        [buttonSource selectItemWithTitle:[[_nic source] bridge]];

        if (![buttonSource selectedItem])
            [buttonSource selectItemAtIndex:0];
    }
    else
        [_delegate handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! get existing nics on the hypervisor
*/
- (void)getHypervisorNWFilters
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkGetNWFilters}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorNWFilters:) ofObject:self];
}

/*! compute the answer containing the nics information
*/
- (void)_didReceiveHypervisorNWFilters:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var filters = [aStanza childrenWithName:@"filter"];

        [buttonNetworkFilter removeAllItems];
        [buttonNetworkFilter addItemWithTitle:@"None"]
        for (var i = 0; i < [filters count]; i++)
        {
            var filter = [filters objectAtIndex:i],
                name = [filter valueForAttribute:@"name"];
            [buttonNetworkFilter addItemWithTitle:name];
        }

        if ([_nic filterref])
            [buttonNetworkFilter selectItemWithTitle:[[_nic filterref] name]];
        else
            [buttonNetworkFilter selectItemWithTitle:@"None"];
    }
    else
        [_delegate handleIqErrorFromStanza:aStanza];
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNNetworkController], comment);
}
