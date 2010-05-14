/*
 * TNNetwork.j
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

@import <AppKit/AppKit.j>
@import <Foundation/Foundation.j>

@implementation TNNetwork : CPObject
{
    CPString    networkName             @accessors;
    CPString    UUID                    @accessors;
    CPString    bridgeName              @accessors;
    CPNumber    bridgeDelay             @accessors;
    CPString    bridgeForwardMode       @accessors;
    CPString    bridgeForwardDevice     @accessors;
    CPString    bridgeIP                @accessors;
    CPString    bridgeNetmask           @accessors;
    CPArray     DHCPEntriesRanges       @accessors;
    CPArray     DHCPEntriesHosts        @accessors;
    BOOL        isNetworkEnabled        @accessors(getter=isNetworkEnabled, setter=setNetworkEnabled:);
    BOOL        isSTPEnabled            @accessors(getter=isSTPEnabled, setter=setSTPEnabled:);
    BOOL        isDHCPEnabled           @accessors(getter=isDHCPEnabled, setter=setDHCPEnabled:);
}

+ (TNNetwork)networkWithName:(CPString)aName
                        UUID:(CPString)anUUID
                  bridgeName:(CPString)aBridgeName
                 bridgeDelay:(CPNumber)aBridgeDelay
           bridgeForwardMode:(CPString)aForwardMode
         bridgeForwardDevice:(CPString)aForwardDevice
                    bridgeIP:(CPString)anIP
               bridgeNetmask:(CPString)aNetmask
           DHCPEntriesRanges:(CPArray)someRangeEntries
            DHCPEntriesHosts:(CPArray)someHostsEntries
              networkEnabled:(BOOL)networkEnabled
                  STPEnabled:(BOOL)STPEnabled
                 DHCPEnabled:(BOOL)DHCPEnabled
{
    var net = [[TNNetwork alloc] init];

    [net setNetworkName:aName];
    [net setUUID:anUUID];
    [net setBridgeName:aBridgeName];
    [net setBridgeDelay:aBridgeDelay];
    [net setBridgeForwardMode:aForwardMode];
    [net setBridgeForwardDevice:aForwardDevice];
    [net setBridgeIP:anIP];
    [net setBridgeNetmask:aNetmask];
    [net setDHCPEntriesRanges:someRangeEntries];
    [net setDHCPEntriesHosts:someHostsEntries];
    [net setNetworkEnabled:networkEnabled];
    [net setSTPEnabled:STPEnabled];
    [net setDHCPEnabled:DHCPEnabled];

    return net;
}
@end


@implementation TNDatasourceNetworks : CPObject
{
    CPArray networks @accessors;
    CPTableView table @accessors;
    CPImage _imageNetworkActive;
    CPImage _imageNetworkUnactive;
}

- (id)init
{
    if (self = [super init])
    {
        var bundle  = [CPBundle bundleForClass:[self class]];

        _imageNetworkActive     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"networkActive.png"]];
        _imageNetworkUnactive   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"networkUnactive.png"]];

        networks = [[CPArray alloc] init];

    }
    return self;
}

- (void)addNetwork:(TNNetwork)aNetwork
{
    [[self networks] addObject:aNetwork];
}

/* Datasource impl. */
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable
{
    return [[self networks] count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];

    if (identifier == "isNetworkEnabled")
    {
        if ([[[self networks] objectAtIndex:aRow] isNetworkEnabled])
            return _imageNetworkActive;
        else
            return _imageNetworkUnactive;
    }
    else
        return [[[self networks] objectAtIndex:aRow] valueForKey:identifier];
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{
    [networks sortUsingDescriptors:[aTableView sortDescriptors]];

    [table reloadData];
}

