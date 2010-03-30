/*
 * TNDatasourceMigarationVMs.j
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

@
/*
 * TNDatasourceVMs.j
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
@import <AppKit/AppKit.j>

// @implementation TNMigrationVMItem : CPObject
// {
//     CPString jid @accessors;
// }
// + (TNMigrationVMItem)migrationVMitemWithJid:(CPString)aJid
// {
//     var item = [[TNMigrationVMItem alloc] init];
//     [item setJid:aJid];
//     return item;
// }
// @end

@implementation TNDatasourceMigrationVMs : CPObject
{
    CPArray VMs @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        [self setVMs:[[CPArray alloc] init]];
    }
    return self;
}

- (void)addVM:(TNStropheContact)aVM
{
    [[self VMs] addObject:aVM];
}

// Datasource impl.
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable
{
    return [[self VMs] count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];

    return [[[self VMs] objectAtIndex:aRow] valueForKey:identifier];
}
