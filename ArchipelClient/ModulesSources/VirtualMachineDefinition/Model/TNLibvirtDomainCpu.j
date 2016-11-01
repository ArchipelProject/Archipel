/*
 * TNLibvirtDomainCpu.j
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
@import "TNLibvirtDomainCpuModel.j"
@import "TNLibvirtDomainCpuTopology.j"
@import "TNLibvirtDomainCpuFeature.j"

TNLibvirtDomainCpuMatchMinimum          = @"minimum";
TNLibvirtDomainCpuMatchExact            = @"exact";
TNLibvirtDomainCpuMatchStrict           = @"strict";
DomainCpuMatches                        = [ TNLibvirtDomainCpuMatchMinimum,
                                            TNLibvirtDomainCpuMatchExact,
                                            TNLibvirtDomainCpuMatchStrict];

TNLibvirtDomainCpuModeCustom            = @"custom";
TNLibvirtDomainCpuModeHostModel         = @"host-model";
TNLibvirtDomainCpuModeHostPassthrough   = @"host-passthrough";
DomainCpuModes                          = [ TNLibvirtDomainCpuModeCustom,
                                            TNLibvirtDomainCpuModeHostModel,
                                            TNLibvirtDomainCpuModeHostPassthrough];


/*! @ingroup virtualmachinedefinition
    Model for domain CPU
*/
@implementation TNLibvirtDomainCpu : TNLibvirtBase
{
    CPString                    _match              @accessors(property=match);
    CPString                    _mode               @accessors(property=mode);
    CPString                    _vendor             @accessors(property=vendor)
    TNLibvirtDomainCpuModel     _model              @accessors(property=model);
    TNLibvirtDomainCpuTopology  _topology           @accessors(property=topology);
    CPArray                     _features           @accessors(property=features);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"cpu")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid cpu"];

        _match = [aNode valueForAttribute:@"match"];
        _mode = [aNode valueForAttribute:@"mode"];

        if ([aNode containsChildrenWithName:@"vendor"])
            _vendor             = [[aNode firstChildWithName:@"vendor"] text];
        if ([aNode containsChildrenWithName:@"model"])
            _model              = [[TNLibvirtDomainCpuModel    alloc] initWithXMLNode:[aNode firstChildWithName:@"model"]];
        if ([aNode containsChildrenWithName:@"topology"])
            _topology           = [[TNLibvirtDomainCpuTopology alloc] initWithXMLNode:[aNode firstChildWithName:@"topology"]];

        _features = [CPArray array];
        var featureNodes = [aNode ownChildrenWithName:@"feature"];
        for (var i = 0; i < [featureNodes count]; i++)
            [_features addObject:[[TNLibvirtDomainCpuFeature  alloc] initWithXMLNode:[featureNodes objectAtIndex:i]]];


    }

    return self;
}


#pragma mark -
#pragma mark Generation

/*! return a TNXMLNode representing the object
    @return TNXMLNode
*/
- (TNXMLNode)XMLNode
{
    var node = [TNXMLNode nodeWithName:@"cpu"];

    if (_match)
    {
        [node setValue:_match forAttribute:@"match"];
        [node up];
    }
    if (_mode)
    {
        [node setValue:_mode forAttribute:@"mode"];
        [node up];
    }
    if (_vendor)
    {
        [node addChildWithName:@"vendor"];
        [node addTextNode:_vendor];
        [node up];
    }
    if (_model)
    {
        [node addNode:[_model XMLNode]];
        [node up];
    }
    if (_topology)
    {
        [node addNode:[_topology XMLNode]];
        [node up];
    }
    for (var i = 0; i < [_features count]; i++)
    {
        [node addNode:[[_features objectAtIndex:i] XMLNode]];
        [node up];
    }
    return node;
}

@end
