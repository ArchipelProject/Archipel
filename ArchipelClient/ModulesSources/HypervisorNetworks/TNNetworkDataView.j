/*
 * TNNetworkDataView.j
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

@import <AppKit/CPView.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>

@import <TNKit/TNTableViewDataSource.j>

/*! @ingroup hypervisornetworks
    This class represent a network DataView
*/
@implementation TNNetworkDataView : CPView
{
    @outlet CPImageView         imageStatus;
    @outlet CPTableView         tableDHCPHosts;
    @outlet CPTableView         tableDHCPRanges;
    @outlet CPTextField         fieldBridgeDelay;
    @outlet CPTextField         fieldBridgeForwardDevice;
    @outlet CPTextField         fieldBridgeForwardMode;
    @outlet CPTextField         fieldBridgeIP;
    @outlet CPTextField         fieldBridgeName;
    @outlet CPTextField         fieldBridgeNetmask;
    @outlet CPTextField         fieldBridgeSTP;
    @outlet CPTextField         fieldName;
    @outlet CPTextField         fieldAutostart;
    @outlet CPTextField         labelBridgeDelay;
    @outlet CPTextField         labelBridgeForwardDevice;
    @outlet CPTextField         labelBridgeForwardMode;
    @outlet CPTextField         labelBridgeInformation;
    @outlet CPTextField         labelBridgeIP;
    @outlet CPTextField         labelBridgeName;
    @outlet CPTextField         labelBridgeNetmask;
    @outlet CPTextField         labelBridgeSTP;
    @outlet CPTextField         labelDHCPHosts;
    @outlet CPTextField         labelDHCPRanges;
    @outlet CPTextField         labelAutostart;

    TNHypervisorNetwork         _network;
    TNTableViewDataSource       _datasourceHosts;
    TNTableViewDataSource       _datasourceRanges;
}

- (void)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [fieldBridgeDelay setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [fieldBridgeForwardDevice setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [fieldBridgeForwardMode setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [fieldBridgeIP setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [fieldBridgeName setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [fieldBridgeNetmask setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [fieldBridgeSTP setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [fieldAutostart setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelBridgeDelay setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelBridgeForwardDevice setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelBridgeForwardMode setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelBridgeIP setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelBridgeName setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelBridgeNetmask setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelBridgeSTP setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelBridgeInformation setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelDHCPRanges setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelDHCPHosts setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
        [labelAutostart setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];

        [tableDHCPRanges setIntercellSpacing:CPSizeMake(2.0, 2.0)];
        [tableDHCPHosts setIntercellSpacing:CPSizeMake(2.0, 2.0)];
    }

    return self;
}

#pragma mark -
#pragma mark Overrides

/*! Message used by CPOutlineView to set the value of the object
    @param aContact TNStropheContact to represent
*/
- (void)setObjectValue:(id)aNetwork
{
    _network                = aNetwork;
    _datasourceRanges       = [[TNTableViewDataSource alloc] init];
    _datasourceHosts        = [[TNTableViewDataSource alloc] init];

    [imageStatus setImage:[aNetwork icon]];
    [fieldName setStringValue:[aNetwork networkName]];
    [fieldBridgeName setStringValue:[aNetwork bridgeName]];
    [fieldBridgeForwardDevice setStringValue:[aNetwork bridgeForwardDevice]];
    [fieldBridgeForwardMode setStringValue:([aNetwork bridgeForwardMode] != @"") ? [aNetwork bridgeForwardMode] : @"Nothing"];
    [fieldBridgeIP setStringValue:[aNetwork bridgeIP]];
    [fieldBridgeNetmask setStringValue:[aNetwork bridgeNetmask]];
    [fieldBridgeSTP setStringValue:[aNetwork isSTPEnabled] ? @"Yes" : @"No"];
    [fieldBridgeDelay setStringValue:[aNetwork bridgeDelay]];
    [fieldAutostart setStringValue:([aNetwork isAutostart]) ? @"On" : @"Off"];

    [tableDHCPRanges setDataSource:_datasourceRanges];
    [_datasourceRanges setTable:tableDHCPRanges];
    [_datasourceRanges setContent:[aNetwork DHCPEntriesRanges]];
    [tableDHCPRanges reloadData];

    [tableDHCPHosts setDataSource:_datasourceHosts];
    [_datasourceHosts setTable:tableDHCPHosts];
    [_datasourceHosts setContent:[aNetwork DHCPEntriesHosts]];
    [tableDHCPHosts reloadData];
}


#pragma mark -
#pragma mark Overrides

/*! forward the theme state set to the inner controls
    @param aState the theme state
*/
- (void)setThemeState:(id)aState
{
    [super setThemeState:aState];

    [fieldName setThemeState:aState];
    [fieldBridgeDelay setThemeState:aState];
    [fieldBridgeForwardDevice setThemeState:aState];
    [fieldBridgeForwardMode setThemeState:aState];
    [fieldBridgeIP setThemeState:aState];
    [fieldBridgeName setThemeState:aState];
    [fieldBridgeNetmask setThemeState:aState];
    [fieldBridgeSTP setThemeState:aState];
    [fieldAutostart setThemeState:aState];
    [labelBridgeDelay setTextColor:[CPColor whiteColor]];
    [labelBridgeForwardDevice setThemeState:aState];
    [labelBridgeForwardMode setThemeState:aState];
    [labelBridgeIP setThemeState:aState];
    [labelBridgeName setThemeState:aState];
    [labelBridgeNetmask setThemeState:aState];
    [labelBridgeSTP setThemeState:aState];
    [labelBridgeInformation setThemeState:aState];
    [labelDHCPRanges setThemeState:aState];
    [labelDHCPHosts setThemeState:aState];
    [labelAutostart setThemeState:aState];
}

/*! forward the theme state unset to the inner controls
    @param aState the theme state
*/
- (void)unsetThemeState:(id)aState
{
    [super unsetThemeState:aState];

    [fieldName unsetThemeState:aState];
    [fieldBridgeDelay unsetThemeState:aState];
    [fieldBridgeForwardDevice unsetThemeState:aState];
    [fieldBridgeForwardMode unsetThemeState:aState];
    [fieldBridgeIP unsetThemeState:aState];
    [fieldBridgeName unsetThemeState:aState];
    [fieldBridgeNetmask unsetThemeState:aState];
    [fieldBridgeSTP unsetThemeState:aState];
    [fieldAutostart unsetThemeState:aState];
    [labelBridgeDelay unsetThemeState:aState];
    [labelBridgeForwardDevice unsetThemeState:aState];
    [labelBridgeForwardMode unsetThemeState:aState];
    [labelBridgeIP unsetThemeState:aState];
    [labelBridgeName unsetThemeState:aState];
    [labelBridgeNetmask unsetThemeState:aState];
    [labelBridgeSTP unsetThemeState:aState];
    [labelBridgeInformation unsetThemeState:aState];
    [labelDHCPRanges unsetThemeState:aState];
    [labelDHCPHosts unsetThemeState:aState];
    [labelAutostart unsetThemeState:aState];
}


#pragma mark -
#pragma mark CPCoding compliance

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        imageStatus = [aCoder decodeObjectForKey:@"imageStatus"];
        tableDHCPRanges = [aCoder decodeObjectForKey:@"tableDHCPRanges"];
        tableDHCPHosts = [aCoder decodeObjectForKey:@"tableDHCPHosts"];
        fieldName = [aCoder decodeObjectForKey:@"fieldName"];
        fieldBridgeName = [aCoder decodeObjectForKey:@"fieldBridgeName"];
        fieldBridgeForwardDevice = [aCoder decodeObjectForKey:@"fieldBridgeForwardDevice"];
        fieldBridgeForwardMode = [aCoder decodeObjectForKey:@"fieldBridgeForwardMode"];
        fieldBridgeIP = [aCoder decodeObjectForKey:@"fieldBridgeIP"];
        fieldBridgeNetmask = [aCoder decodeObjectForKey:@"fieldBridgeNetmask"];
        fieldBridgeSTP = [aCoder decodeObjectForKey:@"fieldBridgeSTP"];
        fieldBridgeDelay = [aCoder decodeObjectForKey:@"fieldBridgeDelay"];
        fieldAutostart = [aCoder decodeObjectForKey:@"fieldAutostart"];
        labelBridgeDelay = [aCoder decodeObjectForKey:@"labelBridgeDelay"];
        labelBridgeForwardDevice = [aCoder decodeObjectForKey:@"labelBridgeForwardDevice"];
        labelBridgeForwardMode = [aCoder decodeObjectForKey:@"labelBridgeForwardMode"];
        labelBridgeIP = [aCoder decodeObjectForKey:@"labelBridgeIP"];
        labelBridgeName = [aCoder decodeObjectForKey:@"labelBridgeName"];
        labelBridgeNetmask = [aCoder decodeObjectForKey:@"labelBridgeNetmask"];
        labelBridgeSTP = [aCoder decodeObjectForKey:@"labelBridgeSTP"];
        labelBridgeInformation = [aCoder decodeObjectForKey:@"labelBridgeInformation"];
        labelDHCPRanges = [aCoder decodeObjectForKey:@"labelDHCPRanges"];
        labelDHCPHosts = [aCoder decodeObjectForKey:@"labelDHCPHosts"];
        labelAutostart = [aCoder decodeObjectForKey:@"labelAutostart"];

        // yeah, well, with its little friends it doesn't work for this field...
        // sometimes I feel tired...
        [fieldName setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:imageStatus forKey:@"imageStatus"];
    [aCoder encodeObject:tableDHCPRanges forKey:@"tableDHCPRanges"];
    [aCoder encodeObject:tableDHCPHosts forKey:@"tableDHCPHosts"];
    [aCoder encodeObject:fieldName forKey:@"fieldName"];
    [aCoder encodeObject:fieldBridgeName forKey:@"fieldBridgeName"];
    [aCoder encodeObject:fieldBridgeForwardDevice forKey:@"fieldBridgeForwardDevice"];
    [aCoder encodeObject:fieldBridgeForwardMode forKey:@"fieldBridgeForwardMode"];
    [aCoder encodeObject:fieldBridgeIP forKey:@"fieldBridgeIP"];
    [aCoder encodeObject:fieldBridgeNetmask forKey:@"fieldBridgeNetmask"];
    [aCoder encodeObject:fieldBridgeSTP forKey:@"fieldBridgeSTP"];
    [aCoder encodeObject:fieldBridgeDelay forKey:@"fieldBridgeDelay"];
    [aCoder encodeObject:fieldAutostart forKey:@"fieldAutostart"];
    [aCoder encodeObject:labelBridgeDelay forKey:@"labelBridgeDelay"];
    [aCoder encodeObject:labelBridgeForwardDevice forKey:@"labelBridgeForwardDevice"];
    [aCoder encodeObject:labelBridgeForwardMode forKey:@"labelBridgeForwardMode"];
    [aCoder encodeObject:labelBridgeIP forKey:@"labelBridgeIP"];
    [aCoder encodeObject:labelBridgeName forKey:@"labelBridgeName"];
    [aCoder encodeObject:labelBridgeNetmask forKey:@"labelBridgeNetmask"];
    [aCoder encodeObject:labelBridgeSTP forKey:@"labelBridgeSTP"];
    [aCoder encodeObject:labelBridgeInformation forKey:@"labelBridgeInformation"];
    [aCoder encodeObject:labelDHCPRanges forKey:@"labelDHCPRanges"];
    [aCoder encodeObject:labelDHCPHosts forKey:@"labelDHCPHosts"];
    [aCoder encodeObject:labelAutostart forKey:@"labelAutostart"];
}

@end