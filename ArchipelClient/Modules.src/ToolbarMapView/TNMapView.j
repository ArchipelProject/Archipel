/*  
 * TNViewHypervisorControl.j
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

@import "Resources/MapKit/MKMapView.j"

@implementation TNMapView : TNModule 
{
    @outlet CPView      mapViewContainer            @accessors;
    @outlet CPTextField textFieldOriginName         @accessors;
    @outlet CPTextField textFieldDestinationName    @accessors;
    @outlet CPSplitView splitViewVertical           @accessors;
    @outlet CPSplitView splitViewHorizontal         @accessors;
    
    @outlet CPCollectionView    collectionViewOrigin        @accessors;
    @outlet CPCollectionView    collectionViewDestination   @accessors;
    MKMapView   _mapView;
}

- (id)awakeFromCib
{
    _mapView = [[MKMapView alloc] initWithFrame:[[self mapViewContainer] bounds] apiKey:''];

    [_mapView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mapView setDelegate:self];
    
    [mapViewContainer setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [mapViewContainer addSubview:_mapView];
    
    [[self splitViewVertical] setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [[self splitViewVertical] setIsPaneSplitter:YES];
}


- (void)willLoad
{
    [super willLoad];
    
    //[_mapView setFrame:bounds];
    //[mapViewContainer setFrame:bounds];
}

- (void)willShow 
{
    [super willShow];
    
    var bounds = [[self superview] bounds];
    
    [[self splitViewVertical] setFrame:bounds];
}

- (void)willHide 
{
    [super willHide];
}

- (void)mapViewIsReady:(MKMapView)aMapView
{
    var rosterItems = [[self roster] contacts];
    CPLogConsole([self roster]);
    
    var latitude = 48.8542;
    for (var i = 0; i < [rosterItems count]; i++)
    {
        var item = [rosterItems objectAtIndex:i];
        
        if ([[[item vCard] firstChildWithName:@"TYPE"] text] == @"hypervisor")
        {
            CPLogConsole("found one hypervisor with name " + [item nickname]);
            
            var loc     = [[MKLocation alloc] initWithLatitude:latitude andLongitude:2.3449]; //TODO: GET POSITION OF HYPERVISOR
            var marker  = [[MKMarker alloc] initAtLocation:loc];
            
            latitude++;
            
            [marker setDraggable:NO];
            [marker setClickable:YES];
            [marker setDelegate:self];
            [marker setUserInfo:[CPDictionary dictionaryWithObjectsAndKeys:item, @"rosterItem"]];
            
            [marker addToMapView:_mapView];
        }
    }
}

- (void)markerClicked:(MKMarker)aMarker userInfo:(CPDictionary)someUserInfo
{
    var item    = [someUserInfo objectForKey:@"rosterItem"];
    
    [[self textFieldDestinationName] setStringValue:[item nickname]];
}



@end



