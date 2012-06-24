/*
 * TNLibvirtDeviceFilesystem.j
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

@import "TNLibvirtDeviceFilesystemSource.j"
@import "TNLibvirtDeviceFilesystemTarget.j"
@import "TNLibvirtDeviceFilesystemDriver.j"

@import "TNLibvirtBase.j";


TNLibvirtDeviceFilesystemTypeTemplate           = @"template";
TNLibvirtDeviceFilesystemTypeMount              = @"mount";
TNLibvirtDeviceFilesystemTypeFile               = @"file";
TNLibvirtDeviceFilesystemTypeBlock              = @"block";
TNLibvirtDeviceFilesystemTypes                  = [ TNLibvirtDeviceFilesystemTypeTemplate,
                                                    TNLibvirtDeviceFilesystemTypeMount,
                                                    TNLibvirtDeviceFilesystemTypeFile,
                                                    TNLibvirtDeviceFilesystemTypeBlock];

TNLibvirtDeviceFilesystemAccessModePassthrough  = @"passthrough";
TNLibvirtDeviceFilesystemAccessModeMapped       = @"mapped";
TNLibvirtDeviceFilesystemAccessModeSquash       = @"squash";
TNLibvirtDeviceFilesystemAccessModes            = [ TNLibvirtDeviceFilesystemAccessModePassthrough,
                                                    TNLibvirtDeviceFilesystemAccessModeMapped,
                                                    TNLibvirtDeviceFilesystemAccessModeSquash];


/*! @ingroup virtualmachinedefinition
    Model for filesystem
*/
@implementation TNLibvirtDeviceFilesystem : TNLibvirtBase
{
    CPString                                _type       @accessors(property=type);
    CPString                                _accessmode @accessors(property=accessmode);
    TNLibvirtDeviceFilesystemSource         _source     @accessors(property=source);
    TNLibvirtDeviceFilesystemTarget         _target     @accessors(property=target);
    TNLibvirtDeviceFilesystemDriver         _driver     @accessors(property=driver);
    BOOL                                    _readonly   @accessors(getter=isReadOnly, setter=setReadOnly:);
}


#pragma mark -
#pragma mark Initialization

/*! initialize the Disk
*/
- (void)init
{
    if (self = [super init])
    {
        _source     = [[TNLibvirtDeviceFilesystemSource alloc] init];
        _target     = [[TNLibvirtDeviceFilesystemTarget alloc] init];
        _driver     = [[TNLibvirtDeviceFilesystemDriver alloc] init];
        _readonly   = NO;
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
        if ([aNode name] != @"filesystem")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid filesystem"];

        _accessmode = [aNode valueForAttribute:@"accessmode"];
        _type       = [aNode valueForAttribute:@"type"];

        _source     = [[TNLibvirtDeviceFilesystemSource alloc] initWithXMLNode:[aNode firstChildWithName:@"source"]];
        _target     = [[TNLibvirtDeviceFilesystemTarget alloc] initWithXMLNode:[aNode firstChildWithName:@"target"]];
        _driver     = [[TNLibvirtDeviceFilesystemDriver alloc] initWithXMLNode:[aNode firstChildWithName:@"driver"]];
        _readonly   = [aNode containsChildrenWithName:@"readonly"];
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
        [CPException raise:@"Missing filesystem type" reason:@"filesystem type is required"];

    var attributes = {@"type": _type};

    if (_accessmode)
        attributes.accessmode = _accessmode;

    var node = [TNXMLNode nodeWithName:@"filesystem" andAttributes:attributes];

    if (_source)
    {
        [node addNode:[_source XMLNode]];
        [node up];
    }

    if (_target)
    {
        [node addNode:[_target XMLNode]];
        [node up];
    }

    if (_driver)
    {
        [node addNode:[_driver XMLNode]];
        [node up];
    }

    if (_readonly)
    {
        [node addChildWithName:@"readonly"];
        [node up];
    }

    return node;
}

@end
