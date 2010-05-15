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
    CPString    bridgeDelay             @accessors;
    CPString    bridgeForwardMode       @accessors;
    CPString    bridgeForwardDevice     @accessors;
    CPString    bridgeIP                @accessors;
    CPString    bridgeNetmask           @accessors;
    CPArray     DHCPEntriesRanges       @accessors;
    CPArray     DHCPEntriesHosts        @accessors;
    BOOL        isNetworkEnabled        @accessors(getter=isNetworkEnabled, setter=setNetworkEnabled:);
    BOOL        isSTPEnabled            @accessors(getter=isSTPEnabled, setter=setSTPEnabled:);
    BOOL        isDHCPEnabled           @accessors(getter=isDHCPEnabled, setter=setDHCPEnabled:);
    CPImage     icon                    @accessors;
    
    CPImage     imageNetworkActive      @accessors;
    CPImage     imageNetworkUnactive    @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        var bundle = [CPBundle bundleForClass:[self class]];
        imageNetworkActive     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"networkActive.png"]];
        imageNetworkUnactive   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"networkUnactive.png"]];
    }
    
    return self;
}

+ (TNNetwork)networkWithName:(CPString)aName
                        UUID:(CPString)anUUID
                  bridgeName:(CPString)aBridgeName
                 bridgeDelay:(CPString)aBridgeDelay
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
    
    if (networkEnabled)
        [net setIcon:[net imageNetworkActive]];
    else
        [net setIcon:[net imageNetworkUnactive]];
    
    return net;
}

@end