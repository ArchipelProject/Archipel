/*  
 * TNStropheStanza.j
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

@implementation TNStropheStanza: CPObject
{   
    id          _stanza     @accessors(readonly, getter=stanza);
}

+ (TNStropheStanza)stanzaWithName:(CPString)aName andAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:aName andAttributes:attributes];
}

+ (TNStropheStanza)iqWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"iq" andAttributes:attributes];
}

+ (TNStropheStanza)presenceWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"presence" andAttributes:attributes];
}

+ (TNStropheStanza)messageWithAttributes:(CPDictionary)attributes
{
    return [[TNStropheStanza alloc] initWithName:@"message" andAttributes:attributes];
}

- (id)initWithName:(CPString)aName andAttributes:(CPDictionary)attributes
{
    if (self = [super init])
        _stanza = new Strophe.Builder(aName, attributes);
    
    return self;
}

- (id)initFromStropheStanza:(id)aStanza
{    
    if (self = [super init])
        _stanza = aStanza;

    return self;
}

- (void)addChildName:(CPString)aTagName withAttributes:(CPDictionary)attributes 
{
    _stanza = _stanza.c(aTagName, attributes);
}

- (void)addTextNode:(CPString)aText
{
    _stanza = _stanza.t(aText);
}

- (id)tree
{
    return _stanza.tree();
}

- (CPString)stringValue
{
    return _stanza.toString();
}

- (void)up
{
    _stanza = _stanza.up();
}

- (CPString)getType
{
    return _stanza.getAttribute("type");
}

- (CPString)description
{
    return [self stringValue];
}
@end

