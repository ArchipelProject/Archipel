/*  
 * TNLibvirtDomainOS.j
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
@import <StropheCappuccino/TNXMLNode.j>

@import "TNLibvirtBase.j";


@implementation TNLibvirtDomainOS : TNLibvirtBase
{
    TNLibvirtDomainOSType _type               @accessors(property=type);
    CPString        _loader             @accessors(property=loader);
    CPString        _boot               @accessors(property=boot);
    BOOL            _bootMenuEnabled    @accessors(getter=isBootMenuEnabled, setter=setBootMenuEnabled:);
    CPString        _kernel             @accessors(property=kernel);
    CPString        _initrd             @accessors(property=initrd);
    CPString        _commandLine        @accessors(property=commandLine);
}

- (TNXMLNode)XMLNode
{
    var node = [TNXMLNode nodeWithName:@"os"];

    if (_type)
    {
        [node addNode:[_type XMLNode]];
        [node up];
    }
    if (_loader)
    {
        [node addChildWithName:@"loader"];
        [node addTextNode:_loader];
        [node up];
    }
    if (_boot)
    {
        [node addChildWithName:@"boot" andAttributes:{@"dev": _boot}];
        [node up];
    }
    if (_bootMenuEnabled)
    {
        var enabled = (_bootMenuEnabled) ? @"yes" : @"no";
        [node addChildWithName:@"bootmenu" andAttributes:{@"enabled": enabled}];
        [node up];
    }
    if (_kernel)
    {
        [node addChildWithName:@"kernel"];
        [node addTextNode:_kernel];
        [node up];
    }
    if (_initrd)
    {
        [node addChildWithName:@"initrd"];
        [node addTextNode:_initrd];
        [node up];
    }
    if (_commandLine)
    {
        [node addChildWithName:@"cmdline"];
        [node addTextNode:_commandLine];
        [node up];
    }

    return node;
}

@end
