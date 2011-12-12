/*
 * TNLibvirtDomainClockTimer.j
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

@import "TNLibvirtBase.j"
@import "TNLibvirtDomainClockTimerCatchup.j"

TNLibvirtDomainClockTimerNameHPET           = @"hpet";
TNLibvirtDomainClockTimerNamePIT            = @"pit";
TNLibvirtDomainClockTimerNamePlatform       = @"platform";
TNLibvirtDomainClockTimerNameRTC            = @"rtc";
TNLibvirtDomainClockTimerNameTSC            = @"tsc";

TNLibvirtDomainClockTimerNames              = [ TNLibvirtDomainClockTimerNameHPET,
                                                TNLibvirtDomainClockTimerNamePIT,
                                                TNLibvirtDomainClockTimerNamePlatform,
                                                TNLibvirtDomainClockTimerNameRTC,
                                                TNLibvirtDomainClockTimerNameTSC];


TNLibvirtDomainClockTimerTrackBoot          = @"boot";
TNLibvirtDomainClockTimerTrackGuest         = @"guest";
TNLibvirtDomainClockTimerTrackWall          = @"wall";

TNLibvirtDomainClockTimerTracks             = [ TNLibvirtDomainClockTimerTrackBoot,
                                                TNLibvirtDomainClockTimerTrackGuest,
                                                TNLibvirtDomainClockTimerTrackWall];

TNLibvirtDomainClockTimerTickPolicyDelay    = @"delay";
TNLibvirtDomainClockTimerTickPolicyCatchup  = @"catchup";
TNLibvirtDomainClockTimerTickPolicyMerge    = @"merge";
TNLibvirtDomainClockTimerTickPolicyDiscard  = @"discard";

TNLibvirtDomainClockTimerTickPolicies       = [ TNLibvirtDomainClockTimerTickPolicyDelay,
                                                TNLibvirtDomainClockTimerTickPolicyCatchup,
                                                TNLibvirtDomainClockTimerTickPolicyMerge,
                                                TNLibvirtDomainClockTimerTickPolicyDiscard];

TNLibvirtDomainClockTimerModeAuto           = @"auto";
TNLibvirtDomainClockTimerModeNative         = @"native";
TNLibvirtDomainClockTimerModeEmulate        = @"emulate";
TNLibvirtDomainClockTimerModeParavirt       = @"paravirt";
TNLibvirtDomainClockTimerModeSMPSafe        = @"smpsafe";

TNLibvirtDomainClockTimerModes              = [ TNLibvirtDomainClockTimerModeAuto,
                                                TNLibvirtDomainClockTimerModeNative,
                                                TNLibvirtDomainClockTimerModeEmulate,
                                                TNLibvirtDomainClockTimerModeParavirt,
                                                TNLibvirtDomainClockTimerModeSMPSafe];


/*! @ingroup virtualmachinedefinition
    Model for clock timer
*/
@implementation TNLibvirtDomainClockTimer : TNLibvirtBase
{
    BOOL                                _present        @accessors(property=present);
    CPString                            _frequency      @accessors(property=frequency);
    CPString                            _mode           @accessors(property=mode);
    CPString                            _name           @accessors(property=name);
    CPString                            _tickpolicy     @accessors(property=tickpolicy);
    CPString                            _track          @accessors(property=track);

    TNLibvirtDomainClockTimerCatchup    _catchup        @accessors(property=catchup);
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
        if ([aNode name] != @"timer")
            [CPException raise:@"XML not valid" reason:@"The TNXMLNode provided is not a valid clock timer"];

        _present    = ([[aNode valueForAttribute:@"present"] lowercaseString] == @"yes");
        _frequency  = [aNode valueForAttribute:@"frequency"];
        _mode       = [aNode valueForAttribute:@"mode"];
        _name       = [aNode valueForAttribute:@"name"];
        _tickpolicy = [aNode valueForAttribute:@"tickpolicy"];
        _track      = [aNode valueForAttribute:@"track"];

        var catchupNode = [aNode firstChildWithName:@"catchup"];
        if (catchupNode)
            _catchup = [[TNLibvirtDomainClockTimerCatchup alloc] initWithXMLNode:catchupNode];
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
    if (!_name)
        [CPException raise:@"Missing clock timer name" reason:@"clock offset timer name is required"];

    var node = [TNXMLNode nodeWithName:@"timer" andAttributes:{@"name": _name}];

    if (_present)
        [node setValue:@"yes" forAttribute:@"present"];
    else
        [node setValue:@"no" forAttribute:@"present"];

    if (_frequency && (_name == TNLibvirtDomainClockTimerNameTSC))
        [node setValue:_frequency forAttribute:@"frequency"];

    if (_mode && (_name == TNLibvirtDomainClockTimerNameTSC))
        [node setValue:_mode forAttribute:@"mode"];

    if (_tickpolicy)
        [node setValue:_tickpolicy forAttribute:@"tickpolicy"];

    if (_track && (_name == TNLibvirtDomainClockTimerNamePlatform || _name == TNLibvirtDomainClockTimerNameRTC))
        [node setValue:_track forAttribute:@"track"];

    if (_catchup && (_tickpolicy == TNLibvirtDomainClockTimerTickPolicyCatchup))
    {
        [node addNode:[_catchup XMLNode]];
        [node up];
    }

    return node;
}

@end
