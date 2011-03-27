/*
 * TNXMPPUserDatasource.j
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

TNXMPPUserDatasourceMe = @"ME";
TNXMPPUserDatasourceRosterUsers = @"ROSTER USERS";
TNXMPPUserDatasourceServerUsers = @"SERVER USERS";
/*! @ingroup permissions
    This object represent a datasource for the outline view
*/
@implementation TNXMPPUserDatasource : CPObject
{
    CPArray     _titles             @accessors(property=titles);
    CPArray     _rosterUsers        @accessors(property=rosterUsers);
    CPArray     _serverUsers        @accessors(property=serverUsers);
    CPString    _filter             @accessors(property=filter);
}

/*! Initialization of the class
    @return an initialized instance of TNVMCastDatasource
*/
- (id)init
{
    if (self = [super init])
    {
        _rosterUsers = [CPArray array];
        _serverUsers = [CPArray array];
        _titles = [TNXMPPUserDatasourceMe, TNXMPPUserDatasourceRosterUsers, TNXMPPUserDatasourceServerUsers];
    }

    return self;
}

- (void)addRosterUser:(TNStropheContact)aContact
{
    [_rosterUsers addObject:aContact];
}

- (void)addXMPPUser:(TNStropheContact)aContact
{
    [_serverUsers addObject:aContact];
}

- (void)removeAllObjects
{
    [_rosterUsers removeAllObjects];
    [_serverUsers removeAllObjects];
}

/*! CPOutlineView Delegate
*/
- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        return [_titles count];
    }
    else
    {
        if (item == TNXMPPUserDatasourceRosterUsers)
            return [_rosterUsers count];
        else if (item == TNXMPPUserDatasourceServerUsers)
            return [_serverUsers count];
    }
}

/*! CPOutlineView Delegate
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)item
{
    return ([item isKindOfClass:CPString] && item != TNXMPPUserDatasourceMe) ? YES : NO;
}

/*! CPOutlineView Delegate
*/
- (id)outlineView:(CPOutlineView)anOutlineView child:(int)index ofItem:(id)item
{
    if (!item)
    {
        return [_titles objectAtIndex:index];
    }
    else
    {
        if (item == TNXMPPUserDatasourceRosterUsers)
            return [_rosterUsers objectAtIndex:index];
        else if (item == TNXMPPUserDatasourceServerUsers)
            return [_serverUsers objectAtIndex:index];
    }
}

/*! CPOutlineView Delegate
*/
- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    var identifier = [tableColumn identifier];

    return [item valueForKey:identifier];
}

@end
