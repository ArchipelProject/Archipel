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
    CPArray                 _pushSelectors;
}

- (void)initializeWithEntity:(id)anEntity connection:(TNStropheConnection)aConnection andRoster:(TNStropheRoster)aRoster
{
    [self setEntity:anEntity];
    [self setRoster:aRoster];
    [self setConnection:aConnection];
}

- (void)registerSelector:(SEL)aSelector forPushNotificationType:(CPString)aPushType
{
    if (! _pushSelectors)
        _pushSelectors = [CPArray array]
    
    if ([[self entity] class] === TNStropheContact)
    {
        var params = [[CPDictionary alloc] init];

        [params setValue:@"iq" forKey:@"name"];
        [params setValue:[[self entity] jid] forKey:@"from"];
        [params setValue:@"trinity:push" forKey:@"type"];
        [params setValue:aPushType forKey:@"namespace"];
        [params setValue:{"matchBare": YES} forKey:@"options"];

        var pushSelectorId = [[self connection] registerSelector:@selector(didSubscriptionPushReceived:) ofObject:self withDict:params];
    }
}

- (void)willLoad
{
    var center  = [CPNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)willUnload
{
    //@each(pushSelector in _pushSelectors)
    for(var i = 0; i < [_pushSelectors count]; i++)
    {
        pushSelector = [_pushSelectors objectAtIndex:i];
        
        [[self connection] deleteRegistredSelector:pushSelector];
    }
}

- (void)willShow
{
    
}

- (void)willHide
{
    
}

- (id)sendStanza:(TNStropheStanza)aStanza andRegisterSelector:(SEL)aSelector
{
    var uid     = [[self connection] getUniqueId];
    var params  = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];;
    var ret     = nil;
    
    if (aSelector)
        ret = [[self connection] registerSelector:aSelector ofObject:self withDict:params];
    
    [[self connection] send:aStanza];

    return ret;
}
@end