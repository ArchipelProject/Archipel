/*
 * TNLibvirtDomain.j
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


TNLibvirtDomainTypeKVM                      = @"kvm";
TNLibvirtDomainTypeXen                      = @"xen";
TNLibvirtDomainTypeOpenVZ                   = @"openvz";
TNLibvirtDomainTypeQemu                     = @"qemu";
TNLibvirtDomainTypeKQemu                    = @"kqemu";
TNLibvirtDomainTypeLXC                      = @"lxc";
TNLibvirtDomainTypeUML                      = @"uml";
TNLibvirtDomainTypeVBox                     = @"vbox";
TNLibvirtDomainTypeVMWare                   = @"vmware";
TNLibvirtDomainTypeOpenNebula               = @"one";

TNLibvirtDomainLifeCycleDestroy             = @"destroy";
TNLibvirtDomainLifeCycleRestart             = @"restart";
TNLibvirtDomainLifeCyclePreserve            = @"preserve";
TNLibvirtDomainLifeCycleRenameRestart       = @"rename-restart";

TNLibvirtDomainLifeCycles                   = [ TNLibvirtDomainLifeCycleDestroy,
                                                TNLibvirtDomainLifeCycleRestart,
                                                TNLibvirtDomainLifeCyclePreserve,
                                                TNLibvirtDomainLifeCycleRenameRestart];


/*! @ingroup virtualmachinedefinition
    Model for domain
*/
@implementation TNLibvirtDomain : TNLibvirtBase
{
    CPString                        _bootloader         @accessors(property=bootloader);
    CPString                        _description        @accessors(property=description);
    CPString                        _type               @accessors(property=type);
    CPString                        _name               @accessors(property=name);
    CPString                        _onCrash            @accessors(property=onCrash);
    CPString                        _onPowerOff         @accessors(property=onPowerOff);
    CPString                        _onReboot           @accessors(property=onReboot);
    CPString                        _UUID               @accessors(property=UUID);
    CPString                        _currentMemory      @accessors(property=currentMemory);
    CPString                        _memory             @accessors(property=memory);
    CPString                        _vcpu               @accessors(property=VCPU);
    CPArray                         _commandLine        @accessors(property=commandLine);
    TNLibvirtDevices                _devices            @accessors(property=devices);
    TNLibvirtDomainBlockIOTune      _blkiotune          @accessors(property=blkiotune);
    TNLibvirtDomainClock            _clock              @accessors(property=clock);
    TNLibvirtDomainFeatures         _features           @accessors(property=features);
    TNLibvirtDomainMemoryBacking    _memoryBacking      @accessors(property=memoryBacking);
    TNLibvirtDomainMemoryTune       _memoryTuning       @accessors(property=memoryTuning);
    TNLibvirtDomainOS               _OS                 @accessors(property=OS);
    TNLibvirtDomainMetadata         _metadata           @accessors(property=metadata);
}

#pragma mark -
#pragma mark Class Method

+ (TNLibvirtDomain)defaultDomainWithType:(CPString)aType
{
    var domain = [[TNLibvirtDomain alloc] init];

    [domain setType:aType];
    [[[domain OS] type] setType:TNLibvirtDomainOSTypeTypeHVM];

    return domain;
}

#pragma mark -
#pragma mark Initialization

- (TNLibvirtDomain)init
{
    if (self = [super init])
    {
        _devices        = [[TNLibvirtDevices alloc] init];
        _blkiotune      = [[TNLibvirtDomainBlockIOTune alloc] init];
        _features       = [[TNLibvirtDomainFeatures alloc] init];
        _clock          = [[TNLibvirtDomainClock alloc] init];
        _memoryBacking  = [[TNLibvirtDomainMemoryBacking alloc] init];
        _memoryTuning   = [[TNLibvirtDomainMemoryTune alloc] init];
        _OS             = [[TNLibvirtDomainOS alloc] init];
    }

    return self;
}

/*! initialize the object with a given XML node
    @param aNode the node to use
*/
- (id)initWithXMLNode:(TNXMLNode)aNode
{
    if (self = [super initWithXMLNode:aNode])
    {
        if ([aNode name] != @"domain")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid domain"];

        _bootloader     = [[aNode firstChildWithName:@"bootloaded"] text];
        _currentMemory  = [[[aNode firstChildWithName:@"currentMemory"] text] intValue];
        _description    = [[aNode firstChildWithName:@"description"] text];
        _type           = [aNode valueForAttribute:@"type"];
        _memory         = [[[aNode firstChildWithName:@"memory"] text] intValue];
        _name           = [[aNode firstChildWithName:@"name"] text];
        _onCrash        = [[aNode firstChildWithName:@"on_crash"] text];
        _onPowerOff     = [[aNode firstChildWithName:@"on_poweroff"] text];
        _onReboot       = [[aNode firstChildWithName:@"on_reboot"] text];
        _UUID           = [[aNode firstChildWithName:@"uuid"] text];
        _vcpu           = [[[aNode firstChildWithName:@"vcpu"] text] intValue];

        _blkiotune      = [[TNLibvirtDomainBlockIOTune alloc] initWithXMLNode:[aNode firstChildWithName:@"blkiotune"]];
        _clock          = [[TNLibvirtDomainClock alloc] initWithXMLNode:[aNode firstChildWithName:@"clock"]];
        _devices        = [[TNLibvirtDevices alloc] initWithXMLNode:[aNode firstChildWithName:@"devices"]];
        _features       = [[TNLibvirtDomainFeatures alloc] initWithXMLNode:[aNode firstChildWithName:@"features"]];
        _memoryBacking  = [[TNLibvirtDomainMemoryBacking alloc] initWithXMLNode:[aNode firstChildWithName:@"memoryBacking"]];
        _memoryTuning   = [[TNLibvirtDomainMemoryTune alloc] initWithXMLNode:[aNode firstChildWithName:@"memtune"]];
        _OS             = [[TNLibvirtDomainOS alloc] initWithXMLNode:[aNode firstChildWithName:@"os"]];

        _commandLine    = [CPArray array];
        var clNodes     = [aNode childrenWithName:@"commandline"];
        for (var i = 0; i < [clNodes count]; i++)
            [_commandLine addObject:[[TNLibvirtDomainQEMUCommandLine alloc] initWithXMLNode:[clNodes objectAtIndex:i]]];

        if ([aNode firstChildWithName:@"metadata"])
            _metadata = [[TNLibvirtDomainMetadata alloc] initWithXMLNode:[aNode firstChildWithName:@"metadata"]]
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
    if (!_type)
        [CPException raise:@"Missing domainType" reason:@"domainType is required"];

    var node = [TNXMLNode nodeWithName:@"domain" andAttributes:{@"type":_type}];

    if (_name)
    {
        [node addChildWithName:@"name"];
        [node addTextNode:_name];
        [node up];
    }
    if (_UUID)
    {
        [node addChildWithName:@"uuid"];
        [node addTextNode:_UUID];
        [node up];
    }
    if (_memory)
    {
        [node addChildWithName:@"memory"];
        [node addTextNode:@"" + _memory];
        [node up];
    }
    if (_currentMemory)
    {
        [node addChildWithName:@"currentMemory"];
        [node addTextNode:@"" + _currentMemory];
        [node up];
    }
    if (_vcpu)
    {
        [node addChildWithName:@"vcpu"];
        [node addTextNode:@"" + _vcpu];
        [node up];
    }
    if (_bootloader)
    {
        [node addChildWithName:@"bootloader"];
        [node addTextNode:_bootloader];
        [node up];
    }
    if (_OS)
    {
        [node addNode:[_OS XMLNode]];
        [node up];
    }
    if (_clock)
    {
        [node addNode:[_clock XMLNode]];
        [node up];
    }
    if (_onPowerOff)
    {
        [node addChildWithName:@"on_poweroff"];
        [node addTextNode:_onPowerOff];
        [node up];
    }
    if (_onReboot)
    {
        [node addChildWithName:@"on_reboot"];
        [node addTextNode:_onReboot];
        [node up];
    }
    if (_onCrash)
    {
        [node addChildWithName:@"on_crash"];
        [node addTextNode:_onCrash];
        [node up];
    }
    if (_features)
    {
        [node addNode:[_features XMLNode]];
        [node up];
    }
    if (_memoryBacking)
    {
        [node addNode:[_memoryBacking XMLNode]];
        [node up];
    }
    if (_blkiotune)
    {
        [node addNode:[_blkiotune XMLNode]];
        [node up];
    }
    if (_devices)
    {
        [node addNode:[_devices XMLNode]];
        [node up];
    }
    if (_memoryTuning)
    {
        [node addNode:[_memoryTuning XMLNode]];
        [node up];
    }
    if (_metadata)
    {
        [node addNode:[_metadata XMLNode]];
        [node up];
    }
    if (_commandLine)
    {
        for (var i = 0; i < [_commandLine count]; i++)
        {
            [node addNode:[[_commandLine objectAtIndex:i] XMLNode]];
            [node up];
        }
    }

    return node;
}

@end
