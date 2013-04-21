/*
 * TNPushCenter.j
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

@import <StropheCappuccino/TNStropheConnection.j>
@import <StropheCappuccino/TNPubSub.j>

var __defaultPushCenter;

/*! @ingroup archipelcore
    This is standart push center TNModule use this
    center to handle pushed. You should not use directly the TNPushCenter from
    your module's methods. instead use the convenient methods provided by TNModule
*/
@implementation TNPushCenter : CPObject
{
    TNPubSubNode        _pubSubNode @accessors(getter=pubSubNode);
    TNStropheConnection _connection @accessors(getter=connection);

    CPArray             _pubsubRegistrar;
    id                  _pubSubHandlerId;
}


#pragma mark -
#pragma mark Class methods

/*! Return or initialize the default TNPushCenter.
*/
+ (TNPushCenter)defaultCenter
{
    if (!__defaultPushCenter)
        __defaultPushCenter = [[TNPushCenter alloc] init];

    return __defaultPushCenter;
}


#pragma mark -
#pragma mark Initialization

/*! Initiliaze a TNPushCenter with given TNStropheConnection
    @param aConnection the TNStropheConnection to use.
*/
- (TNPushCenter)init
{
    if (__defaultPushCenter)
        [CPException raise:@"Singleton error" reason:@"The default push center is already initialized"];

    if (self = [super init])
    {
        _pubsubRegistrar    = [CPArray array];
    }

    return self;
}


#pragma mark -
#pragma mark Getters / Setters

/*! Set the connection a register to Archipel pubsubevents.
    It will eventually reset the old parameters if _connection
    and _pubSubHandlerId already exist
    @param aConnection TNStropheConnection to use
*/
- (void)setConnection:(TNStropheConnection)aConnection
{
    if (_pubSubHandlerId && _connection)
        [_connection deleteRegisteredSelector:_pubSubHandlerId];

    _connection = aConnection;
    _pubSubHandlerId = [TNPubSubNode registerSelector:@selector(_onPubSubEvents:) ofObject:self forPubSubEventWithConnection:_connection];
}


#pragma mark -
#pragma mark Pubsub events

/*! @ignore
    called when a pubsub event is recieved. It will
    parse the pubsub registrar and perform registred methods
    according to the push type thay have bound.
*/
- (BOOL)_onPubSubEvents:(TNStropheStanza)aStanza
{
    CPLog.debug("PUSH CENTER: Raw pubsub event received from " + [aStanza from]);

    // Debugging code waiting for a crash report.
    // If this case happens, it will crash later anyway.
    if (![[aStanza firstChildWithName:@"items"] valueForAttribute:@"node"])
        [CPException raise:@"DebugException" reason:@"there is not 'node' attribute in the items. stanza is " + [aStanza stringValue]];

    var nodeOwner   = [[aStanza firstChildWithName:@"items"] valueForAttribute:@"node"].split("/")[2],
        pushType    = [[aStanza firstChildWithName:@"push"] valueForAttribute:@"xmlns"],
        pushDate    = [[aStanza firstChildWithName:@"push"] valueForAttribute:@"date"],
        pushChange  = [[aStanza firstChildWithName:@"push"] valueForAttribute:@"change"],
        infoDict    = @{
                        @"owner"    :nodeOwner,
                        @"type"     :pushType,
                        @"date"     :pushDate,
                        @"change"   :pushChange,
                        @"rawStanza":aStanza
                    };

    for (var i = 0; i < [_pubsubRegistrar count]; i++)
    {
        var item = [_pubsubRegistrar objectAtIndex:i];

        if (pushType == [item objectForKey:@"type"])
        {
            var object = [item objectForKey:@"object"],
                selector = [item objectForKey:@"selector"];

            CPLog.debug("PUSH CENTER: Performing selector " + selector + " of object " + object);
            [object performSelector:selector withObject:infoDict];
        }
    }

    return YES;
}


#pragma mark -
#pragma mark Controls

/*! register a selector of a given object to handle a push

    A valid Archipel Push is following the form:
    <message from="pubsub.xmppserver" type="headline" to="controller@xmppserver" >
        <event xmlns="http://jabber.org/protocol/pubsub#event">
            <items node="/archipel/09c206aa-8829-11df-aa46-0016d4e6adab@xmppserver/events" >
                <item id="DEADBEEF" >
                    <push xmlns="archipel:push:disk" date="1984-08-18 09:42:00.00000" change="created">
                        [optional content]
                    </push>
                </item>
            </items>
        </event>
    </message>

    @param anObject the object
    @param aSelector the selector to perform
    @param aPushType the type of push to listen
*/
- (void)addObserver:(id)anObject selector:(SEL)aSelector forPushNotificationType:(CPString)aPushType
{
    var registrarItem = [CPDictionary dictionary];

    CPLog.debug("PUSH CENTER: " + anObject + @" is registring selector " + aSelector + " for push notification of type : " + aPushType);
    [registrarItem setValue:aSelector forKey:@"selector"];
    [registrarItem setValue:anObject forKey:@"object"];
    [registrarItem setValue:aPushType forKey:@"type"];

    [_pubsubRegistrar addObject:registrarItem];

    CPLog.trace("PUSH CENTER: Registrar now contains: " + [_pubsubRegistrar count] + " item(s)");
    CPLog.trace(_pubsubRegistrar);
}

/*! remove the given observer from the listening process
    if aType is null, all will be removed, otherwise, only
    the given registration with given type will be removed.
    @param anObject the observer to remove
    @param aType the optional push notification type
*/
- (void)removeObserver:(id)anObject forPushNotificationType:(CPString)aType
{
    var pubsubRegistrarCopy = [_pubsubRegistrar copy];

    for (var i = 0; i < [pubsubRegistrarCopy count]; i++)
    {
        var item = [pubsubRegistrarCopy objectAtIndex:i];

        if (aType && ![item objectForKey:@"type"] == aType)
            continue;

        [_pubsubRegistrar removeObject:item];
        CPLog.trace("PUSH CENTER: Removing object " + [item objectForKey:@"object"] + ":"
                    +[item objectForKey:@"selector"]+" from TNPushCenter");

        // flush the dictionary
        [item setValue:nil forKey:@"selector"];
        [item setValue:nil forKey:@"object"];
        [item setValue:nil forKey:@"type"];
        item = nil;
    }

    CPLog.trace("PUSH CENTER: Registrar now contains: " + [_pubsubRegistrar count] + " item(s)");
    CPLog.trace(_pubsubRegistrar);
}

- (void)removeObserver:(id)anObject
{
    [self removeObserver:anObject forPushNotificationType:nil];
}


/*! flush all registrations
*/
- (void)flush
{
    [_pubsubRegistrar removeAllObjects];
}

@end
