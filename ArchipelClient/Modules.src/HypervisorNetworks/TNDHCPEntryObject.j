/*
 * TNDatasourceDHCPRanges.j
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

TNDHCPEntryTypeRange    = @"TNDHCPEntryTypeRange";
TNDHCPEntryTypeHost     = @"TNDHCPEntryTypeHost";

/*! @ingroup hypervisornetworks
    this class represents a DHCP entry
*/
@implementation TNDHCPEntry : CPObject
{
    CPString    -name    @accessors(property = name);
    CPString    _end     @accessors(property = end);
    CPString    _IP      @accessors(property = IP);
    CPString    _mac     @accessors(property = mac);
    CPString    _start   @accessors(property = start);
    CPString    _type    @accessors(property = type);
}


//#pragma mark -
//#pragma mark Initialization

/*! initialize a TNDHCPEntry as a range
    @param aStartAddr range intial addr
    @param aStartAddr range final addr
    @return initialized TNDHCPEntry
*/
+ (TNDHCPEntry)DHCPRangeWithStartAddress:(CPString)aStartAddr  endAddress:(CPString)aEndAddress
{
    var entry = [[TNDHCPEntry alloc] init];

    [entry setType:TNDHCPEntryTypeRange]
    [entry setStart:aStartAddr];
    [entry setEnd:aEndAddress];

    return entry;
}

/*! initialize a TNDHCPEntry as a host
    @param aMac the mac address of the host
    @param aName the domain name of the host
    @param anIP the IP of th e host
    @return initialized TNDHCPEntry
*/
+ (TNDHCPEntry)DHCPHostWithMac:(CPString)aMac  name:(CPString)aName ip:(CPString)anIP
{
    var entry = [[TNDHCPEntry alloc] init];

    [entry setType:TNDHCPEntryTypeHost]
    [entry setMac:aMac];
    [entry setName:aName];
    [entry setIP:anIP];

    return entry;
}

@end
