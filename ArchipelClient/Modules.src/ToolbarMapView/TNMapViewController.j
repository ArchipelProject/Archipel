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
@import <AppKit/AppKit.j>

@import "MapKit/MKMapView.j";
@import "TNDragDropTableViewDataSource.j";


TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control";
TNArchipelTypeHypervisorControlAlloc        = @"alloc";
TNArchipelTypeHypervisorControlFree         = @"free";
TNArchipelTypeHypervisorControlRosterVM     = @"rostervm";

TNArchipelTypeHypervisorGeolocalization     = @"archipel:hypervisor:geolocalization";
TNArchipelTypeHypervisorGeolocalizationGet  = @"get";

TNArchipelTypeVirtualMachineControl         = @"archipel:vm:control";
TNArchipelTypeVirtualMachineControlMigrate  = @"migrate";


/*! @defgroup  toolbarmapview Module Toolbar Map View
    @desc This module display a Map of the world and localize the hypervisor. It can also perform live migration
*/


/*! @ingroup toolbarmapview
    The module main controller
*/
@implementation TNMapViewController : TNModule
{
    @outlet CPScrollView            scrollViewDestination;
    @outlet CPScrollView            scrollViewOrigin;
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

    CPTableView                     _tableVMDestination;
    CPTableView                     _tableVMOrigin;
    MKMapView                       _mainMapView;
    TNDragDropTableViewDataSource   _dataSourceVMDestination;
    TNDragDropTableViewDataSource   _dataSourceVMOrigin;
    TNStropheContact                _destinationHypervisor;
    TNStropheContact                _originHypervisor;
}

//#pragma mark -
//#pragma mark Initialization

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

    if (posy = [defaults integerForKey:@"mapViewSplitViewPosition"])
        [splitViewHorizontal setPosition:posy ofDividerAtIndex:0];

    [splitViewHorizontal setDelegate:self];

    [mapViewContainer setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [splitViewVertical setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [splitViewVertical setIsPaneSplitter:YES];

    // VM origin table view
    _dataSourceVMOrigin     = [[TNDragDropTableViewDataSource alloc] init];
    _tableVMOrigin          = [[CPTableView alloc] initWithFrame:[scrollViewOrigin bounds]];

    [scrollViewOrigin setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewOrigin setAutohidesScrollers:YES];
    [scrollViewOrigin setDocumentView:_tableVMOrigin];

    [_tableVMOrigin setUsesAlternatingRowBackgroundColors:YES];
    [_tableVMOrigin setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableVMOrigin setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableVMOrigin setAllowsColumnResizing:YES];
    [_tableVMOrigin setAllowsEmptySelection:YES];

    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"],
        vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"JID"],
        vmColumStatusIcon = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"],
        imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [vmColumNickname setWidth:150];
    [[vmColumNickname headerView] setStringValue:@"Name"];

    [[vmColumJID headerView] setStringValue:@"Jabber ID"];

    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];

    [filterFieldOrigin setTarget:_dataSourceVMOrigin];
    [filterFieldOrigin setAction:@selector(filterObjects:)];

    [_dataSourceVMOrigin setTable:_tableVMOrigin];
    [_dataSourceVMOrigin setSearchableKeyPaths:[@"nickname", @"JID"]];
    [_tableVMOrigin addTableColumn:vmColumStatusIcon];
    [_tableVMOrigin addTableColumn:vmColumNickname];
    [_tableVMOrigin addTableColumn:vmColumJID];
    [_tableVMOrigin setDataSource:_dataSourceVMOrigin];
    // [_tableVMOrigin registerForDraggedTypes:[CPArray arrayWithObjects:CPGeneralPboardType, nil]];


    // VM Destination table view
    _dataSourceVMDestination     = [[TNDragDropTableViewDataSource alloc] init];
    _tableVMDestination         = [[CPTableView alloc] initWithFrame:[scrollViewDestination bounds]];

    [scrollViewDestination setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewDestination setAutohidesScrollers:YES];
    [scrollViewDestination setDocumentView:_tableVMDestination];

    [_tableVMDestination setUsesAlternatingRowBackgroundColors:YES];
    [_tableVMDestination setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableVMDestination setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableVMDestination setAllowsColumnReordering:YES];
    [_tableVMDestination setAllowsColumnResizing:YES];
    [_tableVMDestination setAllowsEmptySelection:YES];

    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"],
        vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"JID"],
        vmColumStatusIcon = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"],
        imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [vmColumNickname setWidth:150];
    [[vmColumNickname headerView] setStringValue:@"Name"];

    [[vmColumJID headerView] setStringValue:@"Jabber ID"];

    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setResizingMask:CPTableColumnAutoresizingMask ];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];

    [filterFieldDestination setTarget:_dataSourceVMDestination];
    [filterFieldDestination setAction:@selector(filterObjects:)];

    [_dataSourceVMDestination setTable:_tableVMDestination];
    [_dataSourceVMDestination setSearchableKeyPaths:[@"nickname", @"JID"]];
    [_tableVMDestination addTableColumn:vmColumStatusIcon];
    [_tableVMDestination addTableColumn:vmColumNickname];
    [_tableVMDestination addTableColumn:vmColumJID];
    [_tableVMDestination setDataSource:_dataSourceVMDestination];


    [_tableVMOrigin setDraggingSourceOperationMask:CPDragOperationEvery forLocal:YES];
    [_tableVMOrigin setDraggingSourceOperationMask:CPDragOperationEvery forLocal:NO];
    [_tableVMDestination setDraggingSourceOperationMask:CPDragOperationEvery forLocal:YES];
    [_tableVMDestination setDraggingSourceOperationMask:CPDragOperationEvery forLocal:NO];
}


//#pragma mark -
//#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willShow
{
    [super willShow];

    _mainMapView = [[MKMapView alloc] initWithFrame:[mapViewContainer bounds] apiKey:''];

    [_mainMapView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainMapView setDelegate:self];

    [_tableVMOrigin setDelegate:nil];
    [_tableVMOrigin setDelegate:self];
    [_tableVMDestination setDelegate:nil];
    [_tableVMDestination setDelegate:self];

    [mapViewContainer addSubview:_mainMapView];


    var defaults = [CPUserDefaults standardUserDefaults];
    if (posy = [defaults integerForKey:@"mapViewSplitViewPosition"])
        [splitViewHorizontal setPosition:posy ofDividerAtIndex:0];
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


//#pragma mark -
//#pragma mark Utilities

/*! set the origin hypervisor
    @param anItem TNStropheContact representing the hypervisor
*/
- (void)setOriginHypervisor:(id)anItem
{
    _originHypervisor = anItem;
    [textFieldOriginName setStringValue:[anItem nickname]];
    [self rosterOfHypervisor:anItem];
}

/*! set the destination hypervisor
    @param anItem TNStropheContact representing the hypervisor
*/
- (void)setDestinationHypervisor:(id)anItem
{
    _destinationHypervisor= anItem;
    [textFieldDestinationName setStringValue:[anItem nickname]];
    [self rosterOfHypervisor:anItem];
}


//#pragma mark -
//#pragma mark XMPP Controls

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
        var latitude    = [[aStanza firstChildWithName:@"Latitude"] text],
            longitude   = [[aStanza firstChildWithName:@"Longitude"] text],
            item        = [_roster contactWithJID:[aStanza from]],
            loc         = [[MKLocation alloc] initWithLatitude:latitude andLongitude:longitude],
            marker      = [[MKMarker alloc] initAtLocation:loc];

        [marker setDraggable:NO];
        [marker setClickable:YES];
        [marker setDelegate:self];
        [marker setUserInfo:[CPDictionary dictionaryWithObjectsAndKeys:item, @"rosterItem"]];
        [marker addToMapView:_mainMapView];
        [_mainMapView setCenter:loc];
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
                entry   = [_roster contactWithJID:JID];

            if (entry)
            {
               if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
               {
                    [_dataSourceVMOrigin addObject:entry];
               }
            }
        }
        [_tableVMOrigin reloadData];
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
                entry   = [_roster contactWithJID:JID];

            if (entry)
            {
               if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
               {
                    [_dataSourceVMDestination addObject:entry];
               }
            }
        }
        [_tableVMDestination reloadData];
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Migration" message:@"Migration has started. It can take a while"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}


//#pragma mark -
//#pragma mark Delegates

- (void)mapViewIsReady:(MKMapView)aMapView
{
    [_mainMapView setZoom:2];
    [_mainMapView physicalMode];

    var rosterItems = [_roster contacts];

    for (var i = 0; i < [rosterItems count]; i++)
    {
        var item = [rosterItems objectAtIndex:i];

        if ([[[item vCard] firstChildWithName:@"TYPE"] text] == @"hypervisor")
            [self locationOfHypervisor:item]
    }
}

- (void)markerClicked:(MKMarker)aMarker userInfo:(CPDictionary)someUserInfo
{
    var item    = [someUserInfo objectForKey:@"rosterItem"],
        alert   = [TNAlert alertWithMessage:@"Define path"
                                informative:@"Please choose if this " + [item nickname] + @" is origin or destination of the migration."
                                 target:self
                                 actions:[[@"Cancel", nil], ["Destination",  @selector(setDestinationHypervisor:)], ["Origin", @selector(setOriginHypervisor:)]]];
    [alert setUserInfo:item];
    [alert runModal];
}

- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    var defaults    = [CPUserDefaults standardUserDefaults],
        splitView   = [aNotification object],
        newPos      = [splitView rectOfDividerAtIndex:0].origin.y;

    [defaults setInteger:newPos forKey:@"mapViewSplitViewPosition"];
}


@end



