/*  
 * TNNetworkInterfaceObject.j
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

@implementation TNNetworkInterface : CPObject
{
    CPString _mac    @accessors(property=mac);
    CPString _model  @accessors(property=model);
    CPString _source @accessors(property=source);
    CPString _type   @accessors(property=type);
}

+ (TNNetworkInterface)networkInterfaceWithType:(CPString)aType model:(CPString)aModel mac:(CPString)aMac source:(CPString)aSource
{
    var card = [[TNNetworkInterface alloc] init];
    [card setType:aType];
    [card setModel:aModel];
    [card setMac:aMac];
    [card setSource:aSource];

    return card;
}

@end