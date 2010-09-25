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

@import "MapKit/MKMapView.j"
@import "TNDatasourceMigrationVMs.j"

TNArchipelTypeHypervisorControl             = @"archipel:hypervisor:control";
TNArchipelTypeHypervisorControlAlloc        = @"alloc";
TNArchipelTypeHypervisorControlFree         = @"free";
TNArchipelTypeHypervisorControlRosterVM     = @"rostervm";

TNArchipelTypeHypervisorGeolocalization     = @"archipel:hypervisor:geolocalization";
TNArchipelTypeHypervisorGeolocalizationGet  = @"get";

@implementation TNMapViewController : TNModule
{
    @outlet CPScrollView    scrollViewDestination;
    @outlet CPScrollView    scrollViewOrigin;
    @outlet CPSplitView     splitViewHorizontal;
    @outlet CPSplitView     splitViewVertical;
    @outlet CPTextField     textFieldDestinationName;
    @outlet CPTextField     textFieldOriginName;
    @outlet CPTextField     textFieldDestinationNameLabel;
    @outlet CPTextField     textFieldOriginNameLabel;
    @outlet CPView          viewOrigin;
    @outlet CPView          viewDestination;
    @outlet CPSearchField   filterFieldOrigin;
    @outlet CPSearchField   filterFieldDestination;
    
    @outlet CPView          mapViewContainer;

    CPTableView             _tableVMDestination;
    CPTableView             _tableVMOrigin;
    MKMapView               _mainMapView;
    TNStropheContact        _destinationHypervisor;
    TNStropheContact        _originHypervisor;
    TNTableViewDataSource   _dataSourceVMDestination;
    TNTableViewDataSource   _dataSourceVMOrigin;
}

- (id)awakeFromCib
{
    var posy;
    var defaults    = [TNUserDefaults standardUserDefaults];
    var bundle      = [CPBundle bundleForClass:[self class]];
    
    var gradBG = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"gradientbg.png"]];
    
    [viewOrigin setBackgroundColor:[CPColor colorWithPatternImage:gradBG]];
    [viewDestination setBackgroundColor:[CPColor colorWithPatternImage:gradBG]];
    
    [textFieldOriginNameLabel setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldDestinationNameLabel setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldOriginName setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldDestinationName setTextShadowOffset:CGSizeMake(0.0, 1.0)];
    [textFieldOriginNameLabel setValue:[CPColor colorWithHexString:@"f2f0e4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldDestinationNameLabel setValue:[CPColor colorWithHexString:@"f2f0e4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldOriginName setValue:[CPColor colorWithHexString:@"f2f0e4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [textFieldDestinationName setValue:[CPColor colorWithHexString:@"f2f0e4"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    
    if (posy = [defaults integerForKey:@"mapViewSplitViewPosition"])
        [splitViewHorizontal setPosition:posy ofDividerAtIndex:0];

    [splitViewHorizontal setDelegate:self];
    
    [mapViewContainer setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [splitViewVertical setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [splitViewVertical setIsPaneSplitter:YES];

    // VM origin table view
    _dataSourceVMOrigin     = [[TNTableViewDataSource alloc] init];
    _tableVMOrigin          = [[CPTableView alloc] initWithFrame:[scrollViewOrigin bounds]];

    [scrollViewOrigin setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewOrigin setAutohidesScrollers:YES];
    [scrollViewOrigin setDocumentView:_tableVMOrigin];

    [_tableVMOrigin setUsesAlternatingRowBackgroundColors:YES];
    [_tableVMOrigin setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableVMOrigin setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableVMOrigin setAllowsColumnResizing:YES];
    [_tableVMOrigin setAllowsEmptySelection:YES];

    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"];
    [vmColumNickname setWidth:150];
    [[vmColumNickname headerView] setStringValue:@"Name"];

    var vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"JID"];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];

    var vmColumStatusIcon = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"];
    var imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
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


    // VM Destination table view
    _dataSourceVMDestination     = [[TNTableViewDataSource alloc] init];
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

    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"];
    [vmColumNickname setWidth:150];
    [[vmColumNickname headerView] setStringValue:@"Name"];

    var vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"JID"];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];

    var vmColumStatusIcon = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"];
    var imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
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
}


// TNModule

- (void)willShow
{
    [super willShow];

    _mainMapView = [[MKMapView alloc] initWithFrame:[mapViewContainer bounds] apiKey:''];

    [_mainMapView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainMapView setDelegate:self];

    [mapViewContainer addSubview:_mainMapView];
    
    
    var defaults = [TNUserDefaults standardUserDefaults];
    if (posy = [defaults integerForKey:@"mapViewSplitViewPosition"])
        [splitViewHorizontal setPosition:posy ofDividerAtIndex:0];
}

- (void)willHide
{
    [super willHide];

    [_mainMapView clearOverlays];
    [_mainMapView setDelegate:nil];
    [_mainMapView removeFromSuperview];
    [_mainMapView clean];
    _mainMapView = nil;
}


// mapview delegate
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


// Archipel
- (void)locationOfHypervisor:(TNStropheContact)anHypervisor
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorGeolocalization}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorGeolocalizationGet}];

    [anHypervisor sendStanza:stanza andRegisterSelector:@selector(didReceivedGeolocalization:) ofObject:self];
}

- (void)didReceivedGeolocalization:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var latitude    = [[aStanza firstChildWithName:@"Latitude"] text];
        var longitude   = [[aStanza firstChildWithName:@"Longitude"] text];
        var item        = [_roster contactWithJID:[aStanza fromNode]];

        var loc         = [[MKLocation alloc] initWithLatitude:latitude andLongitude:longitude];
        var marker      = [[MKMarker alloc] initAtLocation:loc];

        [marker setDraggable:NO];
        [marker setClickable:YES];
        [marker setDelegate:self];
        [marker setUserInfo:[CPDictionary dictionaryWithObjectsAndKeys:item, @"rosterItem"]];

        //[_mainMapView addMarker:marker atLocation:loc];
        [marker addToMapView:_mainMapView];
        [_mainMapView setCenter:loc];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)rosterOfHypervisor:(TNStropheContact)anHypervisor
{
    var stanza = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeHypervisorControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeHypervisorControlRosterVM}];

    if (anHypervisor == _originHypervisor)
        [anHypervisor sendStanza:stanza andRegisterSelector:@selector(didReceiveOriginHypervisorRoster:) ofObject:self];
    else
        [anHypervisor sendStanza:stanza andRegisterSelector:@selector(didReceiveDestinationHypervisorRoster:) ofObject:self];
}

- (void)didReceiveOriginHypervisorRoster:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var queryItems  = [aStanza childrenWithName:@"item"];
        var center      = [CPNotificationCenter defaultCenter];

        [_dataSourceVMOrigin removeAllObjects];

        for (var i = 0; i < [queryItems count]; i++)
        {
            var JID     = [[queryItems objectAtIndex:i] text];
            var entry   = [_roster contactWithJID:JID];

            if (entry)
            {
               if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
               {
                    [_dataSourceVMOrigin addObject:entry];
                    //[center addObserver:self selector:@selector(didVirtualMachineChangesStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];
               }
            }
        }
        [_tableVMOrigin reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}

- (void)didReceiveDestinationHypervisorRoster:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var queryItems  = [aStanza childrenWithName:@"item"];
        var center      = [CPNotificationCenter defaultCenter];

        [_dataSourceVMDestination removeAllObjects];

        for (var i = 0; i < [queryItems count]; i++)
        {
            var JID     = [[queryItems objectAtIndex:i] text];
            var entry   = [_roster contactWithJID:JID];

            if (entry)
            {
               if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
               {
                    [_dataSourceVMDestination addObject:entry];
                    //[center addObserver:self selector:@selector(didVirtualMachineChangesStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];
               }
            }
        }
        [_tableVMDestination reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


// marker delegate
- (void)markerClicked:(MKMarker)aMarker userInfo:(CPDictionary)someUserInfo
{
    var item    = [someUserInfo objectForKey:@"rosterItem"];
    var alert   = [TNAlert alertWithTitle:@"Define path"
                                message:@"Please choose if this " + [item nickname] + @" is origin or destination of the migration."
                                delegate:self
                                 actions:[["Origin", @selector(setOrigin:)], ["Destination",  @selector(setDestination:)], [@"Cancel", nil]]];
    [alert setUserInfo:item];
    [alert runModal];


}

- (void)setOrigin:(id)anItem
{
    _originHypervisor = anItem;
    [textFieldOriginName setStringValue:[anItem nickname]];
    [self rosterOfHypervisor:anItem];
}

- (void)setDestination:(id)anItem
{
    _destinationHypervisor= anItem;
    [textFieldDestinationName setStringValue:[anItem nickname]];
    [self rosterOfHypervisor:anItem];
}


/*! Delegate of SplitView
*/
- (void)splitViewDidResizeSubviews:(CPNotification)aNotification
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    var splitView   = [aNotification object];
    var newPos      = [splitView rectOfDividerAtIndex:0].origin.y;
    
    [defaults setInteger:newPos forKey:@"mapViewSplitViewPosition"];
}

@end



