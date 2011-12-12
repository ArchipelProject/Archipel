/*
 * TNPartitionObject.j
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



/*! @ingroup hypervisorhealth
    represent a partition entry
*/
@implementation TNPartitionObject : CPObject
{
    CPString    _capacity   @accessors(property=capacity);
    CPString    _mount      @accessors(property=mount);
    CPString    _used       @accessors(property=used);
    CPString    _available  @accessors(property=available);

}

@end