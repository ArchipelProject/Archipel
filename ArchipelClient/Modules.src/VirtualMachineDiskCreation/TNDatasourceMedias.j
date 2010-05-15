/*
 * TNDatasourceMedias.j
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


@implementation TNMedia : CPObject
{
    CPString    path            @accessors;
    CPString    name            @accessors;
    CPString    format          @accessors;
    CPString    virtualSize     @accessors;
    CPString    diskSize        @accessors;
}

+ (TNMedia)mediaWithPath:(CPString)aPath name:(CPString)aName format:(CPString)aFormat virtualSize:(CPString)vSize diskSize:(CPString)dSize
{
    var media = [[TNMedia alloc] init];
    [media setPath:aPath];
    [media setName:aName];
    [media setFormat:aFormat];
    [media setVirtualSize:vSize];
    [media setDiskSize:dSize];

    return media;
}

@end

@implementation TNDatasourceMedias : CPObject
{
    CPArray medias @accessors;
    CPTableView table @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        [self setMedias:[[CPArray alloc] init]];
    }
    return self;
}

- (void)addMedia:(TNMedia)aMedia
{
    [[self medias] addObject:aMedia];
}

// Datasource impl.
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable
{
    return [[self medias] count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];

    return [[[self medias] objectAtIndex:aRow] valueForKey:identifier];
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{
    [medias sortUsingDescriptors:[aTableView sortDescriptors]];

    [table reloadData];
}
@end