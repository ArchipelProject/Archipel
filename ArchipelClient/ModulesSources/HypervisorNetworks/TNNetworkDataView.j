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

var TNNetworkDataViewStatusImageActive,
    TNNetworkDataViewStatusImageUnactive;

/*! @ingroup hypervisornetworks
    This class represent a network DataView
*/
@implementation TNNetworkDataView : TNBasicDataView
{
    @outlet CPImageView         imageStatus;
    @outlet CPTableView         tableDHCPHosts;
    @outlet CPTableView         tableDHCPRanges;
    @outlet CPTextField         fieldAutostart;
    @outlet CPTextField         fieldBridgeDelay;
    @outlet CPTextField         fieldBridgeForwardDevice;
    @outlet CPTextField         fieldBridgeForwardMode;
    @outlet CPTextField         fieldBridgeIP;
    @outlet CPTextField         fieldBridgeName;
    @outlet CPTextField         fieldBridgeNetmask;
    @outlet CPTextField         fieldBridgeSTP;
    @outlet CPTextField         fieldInLimit;
    @outlet CPTextField         fieldName;
    @outlet CPTextField         fieldOutLimit;
    @outlet CPTextField         labelAutostart;
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
    @outlet CPTextField         labelInLimit;
    @outlet CPTextField         labelOutLimit;

    TNLibvirtNetwork            _network;
    TNTableViewDataSource       _datasourceHosts;
    TNTableViewDataSource       _datasourceRanges;
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    var bundle  = [CPBundle bundleForClass:TNNetworkDataView];
    TNNetworkDataViewStatusImageActive     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"networkActive.png"]];
    TNNetworkDataViewStatusImageUnactive   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"networkUnactive.png"]];
}

- (void)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
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

    [imageStatus setImage:[aNetwork isActive] ? TNNetworkDataViewStatusImageActive : TNNetworkDataViewStatusImageUnactive];
    [fieldName setStringValue:[aNetwork name]];
    [fieldBridgeName setStringValue:[[aNetwork bridge] name] || @"No bridge"];
    [fieldBridgeForwardDevice setStringValue:[[aNetwork forward] dev]];
    [fieldBridgeForwardMode setStringValue:([[aNetwork forward] mode] != @"") ? [[aNetwork forward] mode] : @"Nothing"];
    [fieldBridgeIP setStringValue:[[aNetwork IP] address] || @"No IP"];
    [fieldBridgeNetmask setStringValue:[[aNetwork IP] netmask] || @"No Netmask"];
    [fieldBridgeSTP setStringValue:[[aNetwork bridge] isSTPEnabled] ? @"Yes" : @"No"];
    [fieldBridgeDelay setStringValue:[[aNetwork bridge] delay] || @"None"];
    [fieldAutostart setStringValue:([aNetwork isAutostart]) ? @"On" : @"Off"];

    [fieldInLimit setHidden:YES];
    [labelInLimit setHidden:YES];
    if ([[aNetwork bandwidth] inbound])
    {
        var average = [[[aNetwork bandwidth] inbound] average] || @"None",
            peak = [[[aNetwork bandwidth] inbound] peak] || @"None",
            burst = [[[aNetwork bandwidth] inbound] burst] || @"None";
        [fieldInLimit setStringValue:[CPString stringWithFormat:@"%s/%s/%s", average, peak, burst]];
        [fieldInLimit setHidden:NO];
        [labelInLimit setHidden:NO];
    }

    [fieldOutLimit setHidden:YES];
    [labelOutLimit setHidden:YES];
    if ([[aNetwork bandwidth] outbound])
    {
        var average = [[[aNetwork bandwidth] outbound] average] || @"None",
            peak = [[[aNetwork bandwidth] outbound] peak] || @"None",
            burst = [[[aNetwork bandwidth] outbound] burst] || @"None";
        [fieldOutLimit setStringValue:[CPString stringWithFormat:@"%s/%s/%s", average, peak, burst]];
        [fieldOutLimit setHidden:NO];
        [labelOutLimit setHidden:NO];
    }
    [_datasourceRanges setTable:tableDHCPRanges];
    [_datasourceRanges setContent:[[[aNetwork IP] DHCP] ranges]];
    [tableDHCPRanges setDataSource:_datasourceRanges];
    [tableDHCPRanges reloadData];

    [_datasourceHosts setTable:tableDHCPHosts];
    [_datasourceHosts setContent:[[[aNetwork IP] DHCP] hosts]];
    [tableDHCPHosts setDataSource:_datasourceHosts];
    [tableDHCPHosts reloadData];
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
        fieldInLimit = [aCoder decodeObjectForKey:@"fieldInLimit"];
        fieldOutLimit = [aCoder decodeObjectForKey:@"fieldOutLimit"];
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
        labelInLimit = [aCoder decodeObjectForKey:@"labelInLimit"];
        labelOutLimit = [aCoder decodeObjectForKey:@"labelOutLimit"];
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
    [aCoder encodeObject:fieldInLimit forKey:@"fieldInLimit"];
    [aCoder encodeObject:fieldOutLimit forKey:@"fieldOutLimit"];
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
    [aCoder encodeObject:labelInLimit forKey:@"labelInLimit"];
    [aCoder encodeObject:labelOutLimit forKey:@"labelOutLimit"];

}

@end