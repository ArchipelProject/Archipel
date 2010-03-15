/*  
 * TNModule.j
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
@import <StropheCappuccino/StropheCappuccino.j>

TNExceptionModuleMethodNRequired = @"TNExceptionModuleMethodNRequired";

@implementation TNModule : CPView
{
    TNStropheRoster         roster              @accessors;
    TNStropheGroup          group               @accessors;
    id                      entity              @accessors;
    TNStropheConnection     connection          @accessors;
    CPNumber                moduleTabIndex      @accessors;
    CPString                moduleName          @accessors;
    CPString                moduleLabel         @accessors;
    CPArray                 moduleTypes         @accessors;

    CPArray                 _registredSelectors;
}

- (void)initializeWithEntity:(id)anEntity connection:(TNStropheConnection)aConnection andRoster:(TNStropheRoster)aRoster
{
    [self setEntity:anEntity];
    [self setRoster:aRoster];
    [self setConnection:aConnection];
}

- (void)registerSelector:(SEL)aSelector forPushNotificationType:(CPString)aPushType
{
    if ([[self entity] class] === TNStropheContact)
    {
        var params = [[CPDictionary alloc] init];

        [params setValue:@"iq" forKey:@"name"];
        [params setValue:[[self entity] jid] forKey:@"from"];
        [params setValue:@"archipel:push" forKey:@"type"];
        [params setValue:aPushType forKey:@"namespace"];
        [params setValue:{"matchBare": YES} forKey:@"options"];

        var pushSelectorId = [[self connection] registerSelector:aSelector ofObject:self withDict:params];

        [_registredSelectors addObject:pushSelectorId];
    }
}

- (void)willLoad
{
    _pushSelectors = [CPArray array];
}

- (void)willUnload
{
    // unregister all selectors
    for(var i = 0; i < [_registredSelectors count]; i++)
    {
        var selector = [_registredSelectors objectAtIndex:i];
        
        [[self connection] deleteRegistredSelector:selector];
    }
    
    // remove all notification observers
    var center  = [CPNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)willShow
{
    
}

- (void)willHide
{
    
}

// - (id)sendStanza:(TNStropheStanza)aStanza andRegisterSelector:(SEL)aSelector
// {
//     var uid     = [[self connection] getUniqueId];
//     var params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
//     var ret     = nil;
//     
//     ret = [[self connection] registerSelector:aSelector ofObject:self withDict:params];
//     [_registredSelectors addObject:ret];
//     
//     [[self connection] send:aStanza];
// 
//     return ret;
// }
@end