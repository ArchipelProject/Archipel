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
    BOOL        _isDHCPEnabled           @accessors(getter=isDHCPEnabled, setter=setDHCPEnabled:);
    BOOL        _isNetworkEnabled        @accessors(getter=isNetworkEnabled, setter=setNetworkEnabled:);
    BOOL        _isSTPEnabled            @accessors(getter=isSTPEnabled, setter=setSTPEnabled:);
    CPArray     _DHCPEntriesHosts        @accessors(property=DHCPEntriesHosts);
    CPArray     _DHCPEntriesRanges       @accessors(property=DHCPEntriesRanges);
    CPImage     _icon                    @accessors(property=icon);
    CPImage     _imageNetworkActive      @accessors(property=imageNetworkActive);
    CPImage     _imageNetworkUnactive    @accessors(property=imageNetworkUnactive);
    CPString    _bridgeDelay             @accessors(property=bridgeDelay);
    CPString    _bridgeForwardDevice     @accessors(property=bridgeForwardDevice);
    CPString    _bridgeForwardMode       @accessors(property=bridgeForwardMode);
    CPString    _bridgeIP                @accessors(property=bridgeIP);
    CPString    _bridgeName              @accessors(property=bridgeName);
    CPString    _bridgeNetmask           @accessors(property=bridgeNetmask);
    CPString    _networkName             @accessors(property=networkName);
    CPString    _UUID                    @accessors(property=UUID);
}

- (id)init
{
    if (self = [super init])
    {
        var bundle = [CPBundle bundleForClass:[self class]];
        _imageNetworkActive     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"networkActive.png"]];
        _imageNetworkUnactive   = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"networkUnactive.png"]];
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