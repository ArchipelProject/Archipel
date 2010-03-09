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

@implementation TNDHCPEntry : CPObject
{
    CPString    type    @accessors;
    CPString    start   @accessors;
    CPString    end     @accessors;
    CPString    mac     @accessors;
    CPString    name    @accessors;
    CPString    IP      @accessors;
}

+ (TNDHCPEntry)DHCPRangeWithStartAddress:(CPString)aStartAddr  endAddress:(CPString)aEndAddress 
{
    var entry = [[TNDHCPEntry alloc] init];
    
    [entry setType:TNDHCPEntryTypeRange]
    [entry setStart:aStartAddr];
    [entry setEnd:aEndAddress];
    
    return entry;
}

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


@implementation TNDatasourceDHCPEntries : CPObject
{
    CPArray entries @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        entries = [[CPArray alloc] init];
    }
    return self;
}

- (void)addEntry:(TNDHCPEntry)anEntry
{
    [[self entries] addObject:anEntry];
}

// Datasource impl.
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable 
{
    return [[self entries] count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];

    return [[[self entries] objectAtIndex:aRow] valueForKey:identifier];
}

- (void)tableView:(CPTableView)aTableCiew setObjectValue:(id)aValue forTableColumn:(CPTableColumn)aCol row:(int)aRow
{
    var identifier = [aCol identifier];
    
    [[entries objectAtIndex:aRow] setValue:aValue forKey:identifier];
}
