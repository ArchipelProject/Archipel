/*
 * TNMapView.j
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

@import <AppKit/CPSearchField.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>

@import <TNKit/TNAlert.j>
@import <StropheCappuccino/TNStropheIMClient.j>

@import "../../Model/TNModule.j"
@import "MapKit/MKMapView.j";
@import "TNDragDropTableViewDataSource.j";

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNArchipelEntityTypeHypervisor
@global TNArchipelEntityTypeVirtualMachine


var TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control",
    TNArchipelTypeHypervisorControlAlloc        = @"alloc",
    TNArchipelTypeHypervisorControlFree         = @"free",
    TNArchipelTypeHypervisorControlRosterVM     = @"rostervm",
    TNArchipelTypeHypervisorGeolocalization     = @"archipel:hypervisor:geolocalization",
    TNArchipelTypeHypervisorGeolocalizationGet  = @"get",
    TNArchipelTypeVirtualMachineControl         = @"archipel:vm:control",
    TNArchipelTypeVirtualMachineControlMigrate  = @"migrate";


/*! @defgroup  toolbarmapview Module Toolbar Map View
    @desc This module display a Map of the world and localize the hypervisor. It can also perform live migration
*/


/*! @ingroup toolbarmapview
    The module main controller
*/
@implementation TNMapViewController : TNModule
{
    @outlet CPSearchField           filterFieldDestination;
    @outlet CPSearchField           filterFieldOrigin;
    @outlet CPSplitView             splitViewHorizontal;
    @outlet CPSplitView             splitViewVertical;
    @outlet CPTextField             textFieldDestinationName;
    @outlet CPTextField             textFieldDestinationNameLabel;
    @outlet CPTextField             textFieldOriginName;
    @outlet CPTextField             textFieldOriginNameLabel;
    @outlet CPView                  mapViewContainer;
    @outlet CPView                  viewDestination;
    @outlet CPView                  viewOrigin;
    @outlet CPTableView             tableVMDestination;
    @outlet CPTableView             tableVMOrigin;


    MKMapView                       _mainMapView;
    TNDragDropTableViewDataSource   _dataSourceVMDestination;
    TNDragDropTableViewDataSource   _dataSourceVMOrigin;
    TNStropheContact                _destinationHypervisor;
    TNStropheContact                _originHypervisor;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (id)awakeFromCib
{
    var posy,
        defaults    = [CPUserDefaults standardUserDefaults],
        bundle      = [CPBundle bundleForClass:[self class]],
        gradBG      = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gradientbg.png"]];

    [viewOrigin setBackgroundColor:[CPColor colorWithPatternImage:gradBG]];
    [viewDestination setBackgroundColor:[CPColor colorWithPatternImage:gradBG]];

    [textFieldOriginNameLabel setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldDestinationNameLabel setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldOriginName setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldDestinationName setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldOriginNameLabel setValue:[CPColor colorWithHexString:@"C4CAD6"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldDestinationNameLabel setValue:[CPColor colorWithHexString:@"C4CAD6"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldOriginName setValue:[CPColor colorWithHexString:@"C4CAD6"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldDestinationName setValue:[CPColor colorWithHexString:@"C4CAD6"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldOriginNameLabel setTextColor:[CPColor colorWithHexString:@"00000"]];
    [textFieldOriginName setTextColor:[CPColor colorWithHexString:@"00000"]];
    [textFieldDestinationNameLabel setTextColor:[CPColor colorWithHexString:@"00000"]];
    [textFieldDestinationName setTextColor:[CPColor colorWithHexString:@"00000"]];

    var posy;
    if (posy = [defaults integerForKey:@"TNArchipelMapViewSplitViewPosition"])
        [splitViewHorizontal setPosition:posy ofDividerAtIndex:0];

    [splitViewHorizontal setDelegate:self];

    [mapViewContainer setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [splitViewVertical setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];

    // VM origin table view
    _dataSourceVMOrigin = [[TNDragDropTableViewDataSource alloc] init];
    [_dataSourceVMOrigin setTable:tableVMOrigin];
    [_dataSourceVMOrigin setSearchableKeyPaths:[@"name", @"JID.bare"]];
    [filterFieldOrigin setTarget:_dataSourceVMOrigin];
    [filterFieldOrigin setAction:@selector(filterObjects:)];

    // VM Destination table view
    _dataSourceVMDestination = [[TNDragDropTableViewDataSource alloc] init];
    [_dataSourceVMDestination setTable:tableVMDestination];
    [_dataSourceVMDestination setSearchableKeyPaths:[@"name", @"JID.bare"]];
    [filterFieldDestination setTarget:_dataSourceVMDestination];
    [filterFieldDestination setAction:@selector(filterObjects:)];

    // [tableVMOrigin setDraggingSourceOperationMask:CPDragOperationEvery forLocal:YES];
    // [tableVMOrigin setDraggingSourceOperationMask:CPDragOperationEvery forLocal:NO];
    // [tableVMDestination setDraggingSourceOperationMask:CPDragOperationEvery forLocal:YES];
    // [tableVMDestination setDraggingSourceOperationMask:CPDragOperationEvery forLocal:NO];
    // [tableVMOrigin registerForDraggedTypes:[CPArray arrayWithObjects:CPGeneralPboardType, nil]];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    _mainMapView = [[MKMapView alloc] initWithFrame:[mapViewContainer bounds] apiKey:''];

    [_mainMapView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainMapView setDelegate:self];

    [tableVMOrigin setDelegate:nil];
    [tableVMOrigin setDelegate:self];
    [tableVMDestination setDelegate:nil];
    [tableVMDestination setDelegate:self];

    [mapViewContainer addSubview:_mainMapView];


    var defaults = [CPUserDefaults standardUserDefaults],
        posy;

    if (posy = [defaults integerForKey:@"TNArchipelMapViewSplitViewPosition"])
        [splitViewHorizontal setPosition:posy ofDividerAtIndex:0];

    return YES;
}

/*! called when module becomes unvisible
*/
- (void)willHide
{
    [super willHide];

    [_mainMapView clearOverlays];
    [_mainMapView setDelegate:nil];
    [_mainMapView removeFromSuperview];
    [_mainMapView clean];
    _mainMapView = nil;
}


#pragma mark -
#pragma mark Utilities

/*! set the origin hypervisor
    @param anItem TNStropheContact representing the hypervisor
*/
- (void)setOriginHypervisor:(id)anItem
{
    _originHypervisor = anItem;
    [textFieldOriginName setStringValue:[anItem name]];
    [self rosterOfHypervisor:anItem];
}

/*! set the destination hypervisor
    @param anItem TNStropheContact representing the hypervisor
*/
- (void)setDestinationHypervisor:(id)anItem
{
    _destinationHypervisor= anItem;
    [textFieldDestinationName setStringValue:[anItem name]];
    [self rosterOfHypervisor:anItem];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask given hypervisor for its coordinates
    @param anHypervisor TNStropheContact representing the hypervisor
*/
- (void)locationOfHypervisor:(TNStropheContact)anHypervisor
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorGeolocalization}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorGeolocalizationGet}];

    [anHypervisor sendStanza:stanza andRegisterSelector:@selector(_didReceivedGeolocalization:) ofObject:self];
}

/*! compute the hypervisor answer about its coordinates
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceivedGeolocalization:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        try
        {
            var latitude    = [[aStanza firstChildWithName:@"Latitude"] text],
                longitude   = [[aStanza firstChildWithName:@"Longitude"] text],
                item        = [[[TNStropheIMClient defaultClient] roster] contactWithJID:[aStanza from]],
                loc         = [[MKLocation alloc] initWithLatitude:latitude andLongitude:longitude],
                marker      = [[MKMarker alloc] initAtLocation:loc];

            [marker setDraggable:NO];
            [marker setClickable:YES];
            [marker setDelegate:self];
            [marker setUserInfo:@{@"rosterItem":item}];
            [marker addToMapView:_mainMapView];
            [_mainMapView setCenter:loc];
        }
        catch(e)
        {
            CPLog.warn("The map view has been removed. this happens when the module is hidden while loading info");
        }
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! ask given hypervisor for its roster
    @param anHypervisor TNStropheContact representing the hypervisor
*/
- (void)rosterOfHypervisor:(TNStropheContact)anHypervisor
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorControlRosterVM}];

    if (anHypervisor === _originHypervisor)
        [anHypervisor sendStanza:stanza andRegisterSelector:@selector(_didReceiveOriginHypervisorRoster:) ofObject:self];
    else
        [anHypervisor sendStanza:stanza andRegisterSelector:@selector(_didReceiveDestinationHypervisorRoster:) ofObject:self];
}

/*! compute the origin hypervisor answer about its roster
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveOriginHypervisorRoster:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var queryItems  = [aStanza childrenWithName:@"item"];

        [_dataSourceVMOrigin removeAllObjects];

        for (var i = 0; i < [queryItems count]; i++)
        {
            var JID     = [TNStropheJID stropheJIDWithString:[[queryItems objectAtIndex:i] text]],
                entry   = [[[TNStropheIMClient defaultClient] roster] contactWithJID:JID];

            if (entry && ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[entry vCard]] == TNArchipelEntityTypeVirtualMachine))
                [_dataSourceVMOrigin addObject:entry];
        }
        [tableVMOrigin reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! compute the destination hypervisor answer about its roster
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didReceiveDestinationHypervisorRoster:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        var queryItems  = [aStanza childrenWithName:@"item"];

        [_dataSourceVMDestination removeAllObjects];

        for (var i = 0; i < [queryItems count]; i++)
        {
            var JID     = [TNStropheJID stropheJIDWithString:[[queryItems objectAtIndex:i] text]],
                entry   = [[[TNStropheIMClient defaultClient] roster] contactWithJID:JID];

            if (entry && ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[entry vCard]] == TNArchipelEntityTypeVirtualMachine))
                [_dataSourceVMDestination addObject:entry];
        }
        [tableVMDestination reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! ask a virtual machine to migrate to given hypervisor
    @param aVirualMachine the virtual machine to migrate
    @param aHypervisor the destination hypervisor
*/
- (void)migrate:(TNStropheContact)aVirualMachine toHypervisor:(TNStropheContact)aHypervisor
{
    var stanza = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeVirtualMachineControlMigrate,
        "hypervisorjid": [aHypervisor fullJID]}];
    [aVirualMachine sendStanza:stanza andRegisterSelector:@selector(_didMigrate:) ofObject:self];

}

/*! compute virtual machine answer about its migration
    @param aStanza TNStropheStanza containing the answer
*/
- (BOOL)_didMigrate:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Migration has started. It can take a while", @"Migration has started. It can take a while")];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


#pragma mark -
#pragma mark Delegates

- (void)mapViewIsReady:(MKMapView)aMapView
{
    [_mainMapView setZoom:2];
    [_mainMapView physicalMode];

    var rosterItems = [[[TNStropheIMClient defaultClient] roster] contacts];

    for (var i = 0; i < [rosterItems count]; i++)
    {
        var item = [rosterItems objectAtIndex:i];

        if ([[[TNStropheIMClient defaultClient] roster] analyseVCard:[item vCard]] == TNArchipelEntityTypeHypervisor)
            [self locationOfHypervisor:item]
    }
}

- (void)markerClicked:(MKMarker)aMarker userInfo:(CPDictionary)someUserInfo
{
    var item    = [someUserInfo objectForKey:@"rosterItem"],
        alert   = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Define path", @"Define path")
                                informative:CPBundleLocalizedString(@"Please choose if this ", @"Please choose if this ") + [item name] + CPBundleLocalizedString(@" is origin or destination of the migration.", @" is origin or destination of the migration.")
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Cancel", @"Cancel"), nil], [CPBundleLocalizedString("Destination", "Destination"),  @selector(setDestinationHypervisor:)], [CPBundleLocalizedString("Origin", "Origin"), @selector(setOriginHypervisor:)]]];
    [alert setUserInfo:item];
    [alert runModal];
}

- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        splitView   = [aNotification object],
        newPos      = [splitView rectOfDividerAtIndex:0].origin.y;

    [defaults setInteger:newPos forKey:@"TNArchipelMapViewSplitViewPosition"];
}


@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNMapViewController], comment);
}

