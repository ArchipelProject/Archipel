/*
 * TNNetworkEditionController.j
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
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNTableViewDataSource.j>

@import "Model/TNNuage.j"



/*! @ingroup hypervisornetworks
    The newtork window edition
*/
@implementation TNNuageEditionController : CPObject
{
    @outlet CPButton            buttonOK;
    @outlet CPCheckBox          checkBoxBandwidthInbound;
    @outlet CPCheckBox          checkBoxBandwidthOutbound;
    @outlet CPPopover           mainPopover;
    @outlet CPPopUpButton       buttonNuageType;
    @outlet CPTextField         fieldAddress;
    @outlet CPTextField         fieldBandwidthInboundAverage;
    @outlet CPTextField         fieldBandwidthInboundBurst;
    @outlet CPTextField         fieldBandwidthInboundPeak;
    @outlet CPTextField         fieldBandwidthOutboundAverage;
    @outlet CPTextField         fieldBandwidthOutboundBurst;
    @outlet CPTextField         fieldBandwidthOutboundPeak;
    @outlet CPTextField         fieldErrorMessage;
    @outlet CPTextField         fieldGateway;
    @outlet CPTextField         fieldName;
    @outlet CPTextField         fieldNetmask;
    @outlet CPTableView         tableViewDomains;
    @outlet CPTableView         tableViewZones;

    BOOL                        _isNewNuage @accessors(setter=setIsNewNuage:);
    id                          _delegate   @accessors(property=delegate);
    TNNuage                     _nuage      @accessors(property=nuage);

    TNTableViewDataSource       _dataSourceDomains;
    TNTableViewDataSource       _dataSourceZones;
}


#pragma mark -
#pragma mark  Initialization

- (void)awakeFromCib
{
    [buttonNuageType removeAllItems];
    [buttonNuageType addItemsWithTitles:TNNuageNetworkTypes]
    [buttonNuageType setToolTip:CPBundleLocalizedString(@"Select the Nuage Network type", @"Select the Nuage Network type")];

    [fieldName setToolTip:CPBundleLocalizedString(@"Enter the name of the Nuage network", @"Enter the name of the Nuage network")];
    [fieldAddress setToolTip:CPBundleLocalizedString(@"The IP address to the Nuage network", @"The IP address to the Nuage network")];
    [fieldNetmask setToolTip:CPBundleLocalizedString(@"The netmask to use for Nuage network", @"The netmask to use for the Nuage network")];
    [fieldGateway setToolTip:CPBundleLocalizedString(@"The gateway to use for Nuage network", @"The gateway to use for the Nuage network")];

    _dataSourceDomains = [[TNTableViewDataSource alloc] init];
    [_dataSourceDomains setTable:tableViewDomains];
    [tableViewDomains setDataSource:_dataSourceDomains];
    [tableViewDomains setDelegate:self];

    _dataSourceZones = [[TNTableViewDataSource alloc] init];
    [_dataSourceZones setTable:tableViewZones];
    [tableViewZones setDataSource:_dataSourceZones];
}


#pragma mark -
#pragma mark CPWindow override

/*! Update the controller with a new network object
*/
- (void)update
{
    [fieldErrorMessage setStringValue:@""];

    [fieldName setStringValue:[_nuage name]];
    [fieldAddress setStringValue:[[_nuage subnet] address] || @""];
    [fieldNetmask setStringValue:[[_nuage subnet] netmask] || @""];
    [fieldGateway setStringValue:[[_nuage subnet] gateway] || @""];

    [buttonNuageType selectItemWithTitle:[_nuage type]];

    [fieldName setEnabled:_isNewNuage];

    // Bandwidth
    [checkBoxBandwidthInbound setState:[[_nuage bandwidth] inbound] ? CPOnState : CPOffState];
    [self inboundLimitChange:nil];
    [checkBoxBandwidthOutbound setState:[[_nuage bandwidth] outbound] ? CPOnState : CPOffState];
    [self outboundLimitChange:nil];

    [fieldBandwidthInboundAverage setStringValue:[[[_nuage bandwidth] inbound] average] || @""];
    [fieldBandwidthInboundPeak setStringValue:[[[_nuage bandwidth] inbound] peak] || @""];
    [fieldBandwidthInboundBurst setStringValue:[[[_nuage bandwidth] inbound] burst] || @""];

    [fieldBandwidthOutboundAverage setStringValue:[[[_nuage bandwidth] outbound] average] || @""];
    [fieldBandwidthOutboundPeak setStringValue:[[[_nuage bandwidth] outbound] peak] || @""];
    [fieldBandwidthOutboundBurst setStringValue:[[[_nuage bandwidth] outbound] burst] || @""];

    [[TNCNACommunicator defaultCNACommunicator] fetchDomainsAndCallSelector:@selector(_didFetchDomains:) ofObject:self];
}

/*! Update the network object with value and
    send defineNetwork delegate method
*/
- (void)save
{
    if (![fieldName stringValue] || [fieldName stringValue] == @"")
    {
        [fieldErrorMessage setStringValue:CPLocalizedString(@"You must enter a valid network name", @"You must enter a valid network name")];
        return;
    }

    if ([tableViewDomains numberOfSelectedRows] != 1)
    {
        [fieldErrorMessage setStringValue:CPLocalizedString(@"You must enter a valid domain name", @"You must enter a valid domain name")];
        return;
    }

    if ([tableViewZones numberOfSelectedRows] != 1)
    {
        [fieldErrorMessage setStringValue:CPLocalizedString(@"You must enter a valid zone name", @"You must enter a valid zone name")];
        return;
    }

    [_nuage setName:[fieldName stringValue]];
    [_nuage setType:[buttonNuageType title]];
    [_nuage setDomain:[[_dataSourceDomains objectAtIndex:[tableViewDomains selectedRow]] objectForKey:@"name"]];
    [_nuage setZone:[[_dataSourceZones objectAtIndex:[tableViewZones selectedRow]] objectForKey:@"name"]];

    if (![_nuage subnet])
        [_nuage setSubnet:[[TNNuageNetworkSubnet alloc] init]];

    if ([fieldAddress stringValue] != @"")
        [[_nuage subnet] setAddress:[fieldAddress stringValue]];
    if ([fieldNetmask stringValue] != @"")
        [[_nuage subnet] setNetmask:[fieldNetmask stringValue]];
    if ([fieldGateway stringValue] != @"")
        [[_nuage subnet] setGateway:[fieldGateway stringValue]];

    if ([checkBoxBandwidthInbound state] == CPOnState)
    {
        if (![_nuage bandwidth])
            [_nuage setBandwidth:[TNNuageNetworkBandwidth defaultNuageBandwidth]];

        if (![[_nuage bandwidth] inbound])
            [[_nuage bandwidth] setInbound:[[TNNuageNetworkBandwidthInbound alloc] init]];

        if ([fieldBandwidthInboundAverage stringValue] == @"")
        {
            [fieldErrorMessage setStringValue:CPLocalizedString(@"You must set at least the \"average\" value for inbound limit", @"You must set at least the \"average\" value for inbound limit")];
            return;
        }
        [[[_nuage bandwidth] inbound] setAverage:[fieldBandwidthInboundAverage intValue]];
        [[[_nuage bandwidth] inbound] setPeak:[fieldBandwidthInboundPeak intValue]];
        [[[_nuage bandwidth] inbound] setBurst:[fieldBandwidthInboundBurst intValue]];
    }
    else
    {
        [[_nuage bandwidth] setInbound:nil];
    }

    if ([checkBoxBandwidthOutbound state] == CPOnState)
    {
        if (![_nuage bandwidth])
            [_nuage setBandwidth:[TNNuageNetworkBandwidth defaultNuageBandwidth]];

        if (![[_nuage bandwidth] outbound])
            [[_nuage bandwidth] setOutbound:[[TNNuageNetworkBandwidthOutbound alloc] init]];

        if ([fieldBandwidthOutboundAverage stringValue] == @"")
        {
            [fieldErrorMessage setStringValue:CPLocalizedString(@"You must set at least the \"average\" value for outbound limit", @"You must set at least the \"average\" value for outbound limit")];
            return;
        }
        [[[_nuage bandwidth] outbound] setAverage:[fieldBandwidthOutboundAverage intValue]];
        [[[_nuage bandwidth] outbound] setPeak:[fieldBandwidthOutboundPeak intValue]];
        [[[_nuage bandwidth] outbound] setBurst:[fieldBandwidthOutboundBurst intValue]];
    }
    else
    {
        [[_nuage bandwidth] setOutbound:nil];
    }

    CPLog.info("Nuage information is :" + _nuage);

    if (_isNewNuage)
        [_delegate createNuage:_nuage];
    else
        [_delegate updateNuage:_nuage];

    [mainPopover close];
}


#pragma mark -
#pragma mark REST handler

- (void)_didFetchDomains:(TNRESTConnection)aConnection
{
    var JSON = [[aConnection responseData] JSONObject],
        domains = [CPArray array],
        currentDomainIndex = 0;

    for (var i = 0; i < [JSON count]; i++)
    {
        var domain = JSON[i],
            domainName = domain.name,
            domainID = domain.ID;

        [domains addObject:[CPDictionary dictionaryWithObjectsAndKeys: domainName, @"name", domainID, @"ID"]];

        if (domainName == [_nuage domain])
            currentDomainIndex = i;
    }

    [_dataSourceDomains setContent:domains];
    [tableViewDomains reloadData];

    [tableViewDomains selectRowIndexes:[CPIndexSet indexSetWithIndex:currentDomainIndex] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:nil];
}

- (void)_didFetchZones:(TNRESTConnection)aConnection
{
    var JSON = [[aConnection responseData] JSONObject],
        zones = [CPArray array],
        currentZoneIndex = 0;

    for (var i = 0; i < [JSON count]; i++)
    {
        var zone = JSON[i],
            zoneName = zone.name,
            zoneID = zone.ID;

        [zones addObject:[CPDictionary dictionaryWithObjectsAndKeys: zoneName, @"name", zoneID, @"ID"]];

        if (zoneName == [_nuage zone])
            currentZoneIndex = i;
    }

    [_dataSourceZones setContent:zones];
    [tableViewZones reloadData];

    [tableViewZones selectRowIndexes:[CPIndexSet indexSetWithIndex:currentZoneIndex] byExtendingSelection:NO];
}


#pragma mark -
#pragma mark Actions

/*! save the changes
    @param sender the sender of the action
*/
- (IBAction)save:(id)sender
{
    [self save];
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
        [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil]

    [mainPopover makeFirstResponder:fieldName];
    [mainPopover setDefaultButton:buttonOK];
}

/*! hide the main window
    @param aSender the sender of the action
*/
- (IBAction)closeWindow:(id)sender
{
    [mainPopover close];
}

/*! Called when checkbox for inbound changed
    @param aSender the sender of the action
*/
- (IBAction)inboundLimitChange:(id)aSender
{
    if ([checkBoxBandwidthInbound state] == CPOnState)
    {
        [fieldBandwidthInboundAverage setEnabled:YES];
        [fieldBandwidthInboundPeak setEnabled:YES];
        [fieldBandwidthInboundBurst setEnabled:YES];
        if (![_nuage bandwidth])
            [_nuage setBandwidth:[TNLibvirtNetworkBandwidth defaultNetworkBandwidth]];
    }
    else
    {
        [fieldBandwidthInboundAverage setEnabled:NO];
        [fieldBandwidthInboundPeak setEnabled:NO];
        [fieldBandwidthInboundBurst setEnabled:NO];
        [fieldBandwidthInboundAverage setStringValue:@""];
        [fieldBandwidthInboundPeak setStringValue:@""];
        [fieldBandwidthInboundBurst setStringValue:@""];

        if (![_nuage bandwidth])
            [[_nuage bandwidth] setInbound:nil];
    }
}

/*! Called when checkbox for outbound changed
    @param aSender the sender of the action
*/
- (IBAction)outboundLimitChange:(id)aSender
{
    if ([checkBoxBandwidthOutbound state] == CPOnState)
    {
        [fieldBandwidthOutboundAverage setEnabled:YES];
        [fieldBandwidthOutboundPeak setEnabled:YES];
        [fieldBandwidthOutboundBurst setEnabled:YES];
        if (![_nuage bandwidth])
            [_nuage setBandwidth:[TNLibvirtNetworkBandwidth defaultNetworkBandwidth]];
    }
    else
    {
        [fieldBandwidthOutboundAverage setEnabled:NO];
        [fieldBandwidthOutboundPeak setEnabled:NO];
        [fieldBandwidthOutboundBurst setEnabled:NO];
        [fieldBandwidthOutboundAverage setStringValue:@""];
        [fieldBandwidthOutboundPeak setStringValue:@""];
        [fieldBandwidthOutboundBurst setStringValue:@""];

        if (![_nuage bandwidth])
            [[_nuage bandwidth] setOutbound:nil];
    }
}

#pragma mark -
#pragma mark Delegates

- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
    var selectedObject = [_dataSourceDomains objectAtIndex:[tableViewDomains selectedRow]];

    [[TNCNACommunicator defaultCNACommunicator] fetchZonesInDomainWithID:[selectedObject objectForKey:@"ID"]
                                                         andCallSelector:@selector(_didFetchZones:)
                                                               ofObject:self];
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNNuageEditionController], comment);
}
