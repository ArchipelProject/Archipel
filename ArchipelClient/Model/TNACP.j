/*
 * TNACP.j
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
@import <StropheCappuccino/TNStropheStanza.j>

TNACPGet = @"get";
TNACPSet = @"set";

// var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex],
//     currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex],
//     uuid            = [currentVMCast UUID],
//     stanza          = [TNStropheStanza iqWithType:@"set"];
//
// [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
// [stanza addChildWithName:@"archipel" andAttributes:{
//     "action": TNArchipelTypeHypervisorVMCastingUnregister,
//     "uuid": uuid}];
//
//
// [self sendStanza:stanza andRegisterSelector:@selector(_didRemoveVMCast:)]

@implementation TNACP : CPObject
{
    TNStropheStanza     _stanza     @accessors(getter=stanza);
    TNStropheContact    _to         @accessors(getter=to);
    CPString            _type       @accessors(getter=type);
    CPString            _namespace  @accessors(getter=namespace);
    CPString            _action     @accessors(getter=action);
    CPDictionary        _parameters @accessors(getter=parameters);
    TNXMLNode           _content    @accessors(getter=content);

    BOOL                _needsBuild;
}

#pragma mark -
#pragma mark Class methods

/*! ret
*/
+ (TNCAP)ACP
{
    return [[TNACP alloc] init];
}

+ (TNACP)ACPWithNamespace:(CPString)aNamespace to:(TNStropheContact)aContact type:(CPString)aType action:(CPString)anAction parameters:(CPDictionary)someParameters content:(TNXMLNode)aContent
{
    var ACP = [[TNACP alloc] init];

    [ACP setNamespace:aNamespace];
    [ACP setTo:aContact];
    [ACP setType:aType];
    [ACP setAction:anAction];
    [ACP setParameters:someParameters];
    [ACP setContent:aContent];

    return ACP;
}

- (TNACP)init
{
    if (self = [super init])
    {
        _stanza     = [TNStropheStanza stanzaWithName:@"iq"];
        _needsBuild = YES;
    }

    return self;
}

- (void)setNamespace:(CPString)aNamespace
{
    _needsBuild = YES;
    _namespace = aNamespace;
}

- (void)setTo:(TNStropheContact)aContact
{
    _needsBuild = YES;
    _to = aContact;
}

- (void)setType:(CPString)aType
{
    _needsBuild = YES;
    _type = aType;
}

- (void)setAction:(CPString)anAction
{
    _needsBuild = YES;
    _action = anAction;
}

- (void)setAction:(CPDictionary)someParameters
{
    _needsBuild = YES;
    _parameters = someParameters;
}

- (void)setContent:(TNXMLNode)aContent
{
    _needsBuild = YES;
    _content = aContent;
}

- (void)buildStanza
{
    if (_needsBuild)
    {
        [_stanza setTo:_to];
        [_stanza setType:_type];
        [_stanza addChildWithName:@"query" andAttributes:{"xmlns": _namespace}];
        [_stanza addChildWithName:@"archipel"];

        for (var i = 0 ; i < [[_parameters allKeys] count]; i++)
        {
            var attribute = [[_parameters allKeys] objectAtIndex:i],
                value = [_parameters valueForKey:key];
            [_stanza setValue:value forAttribute:attribute];
        }

        if (_content)
            [_stanza addNode:_content];
    }

    return _stanza;
}

- (void)sendAndRegisterSelector:(SEL)aSelector ofObject:(id)anObject
{
    return [_to sendStanza:[self buildStanza] andRegisterSelector:aSelector ofObject:anObject];
}

- (void)sendAndRegisterSelector:(SEL)aSelector ofObject:(id)anObject withSpecificID:(id)anUID
{
    return [_to sendStanza:[self buildStanza] andRegisterSelector:aSelector ofObject:anObject withSpecificID:anUID];
}

- (void)send
{
    return [_to sendStanza:[self buildStanza] andRegisterSelector:nil ofObject:nil];
}

@end