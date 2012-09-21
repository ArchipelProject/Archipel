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

TNLibvirtDomainOSBootHardDrive          = @"hd";
TNLibvirtDomainOSBootCDROM              = @"cdrom";
TNLibvirtDomainOSBootNetwork            = @"network";
TNLibvirtDomainOSBootFileDescriptor     = @"fd";
TNLibvirtDomainOSBoots                  = [ TNLibvirtDomainOSBootHardDrive,
                                            TNLibvirtDomainOSBootCDROM,
                                            TNLibvirtDomainOSBootNetwork,
                                            TNLibvirtDomainOSBootFileDescriptor];


/*! @ingroup virtualmachinedefinition
    Model for domain OS
*/
@implementation TNLibvirtDomainOS : TNLibvirtBase
{
    BOOL                    _bootMenuEnabled    @accessors(getter=isBootMenuEnabled, setter=setBootMenuEnabled:);
    CPString                _boot               @accessors(property=boot);
    CPString                _commandLine        @accessors(property=commandLine);
    CPString                _initrd             @accessors(property=initrd);
    CPString                _kernel             @accessors(property=kernel);
    CPString                _loader             @accessors(property=loader);
    TNLibvirtDomainOSType   _type               @accessors(property=type);
}


#pragma mark -
#pragma mark Initialization

- (void)init
{
    if (self = [super init])
    {
        _type   = [[TNLibvirtDomainOSType alloc] init];
    }

    return self;
}

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode domainType:(CPString)aDomainType
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"os")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid os"];

        _boot               = [[aNode firstChildWithName:@"boot"] valueForAttribute:@"dev"];
        _bootMenuEnabled    = ([[aNode firstChildWithName:@"bootmenu"] valueForAttribute:@"enable"] == @"yes") ? YES : NO;
        _commandLine        = [[aNode firstChildWithName:@"cmdline"] text];
        _initrd             = [[aNode firstChildWithName:@"initrd"] text];
        _kernel             = [[aNode firstChildWithName:@"kernel"] text];
        _loader             = [[aNode firstChildWithName:@"loader"] text];

        _type               = [[TNLibvirtDomainOSType alloc] initWithXMLNode:[aNode firstChildWithName:@"type"] domainType:aDomainType];
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
    var node = [TNXMLNode nodeWithName:@"os"];

    if (_type)
    {
        [node addNode:[_type XMLNode]];
        [node up];
    }
    if (_loader && _loader != @"")
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
    if (_bootMenuEnabled != nil)
    {
        var enabled = (_bootMenuEnabled) ? @"yes" : @"no";
        [node addChildWithName:@"bootmenu" andAttributes:{@"enable": enabled}];
        [node up];
    }
    if (_kernel  && _kernel != @"")
    {
        [node addChildWithName:@"kernel"];
        [node addTextNode:_kernel];
        [node up];
    }
    if (_initrd  && _initrd != @"")
    {
        [node addChildWithName:@"initrd"];
        [node addTextNode:_initrd];
        [node up];
    }
    if (_commandLine  && _commandLine != @"")
    {
        [node addChildWithName:@"cmdline"];
        [node addTextNode:_commandLine];
        [node up];
    }

    return node;
}

@end
