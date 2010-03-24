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
    @outlet CPView      mapViewContainer    @accessors;
    
    MKMapView   _mapView;
}

- (id)awakeFromCib
{

    CPLogConsole("YOUHOU!!!!!");
    
    var bounds = [self bounds];
    
    _mapView = [[MKMapView alloc] initWithFrame:bounds apiKey:''];

    [_mapView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mapView setDelegate:self];

    [mapViewContainer setFrame:bounds];
    [mapViewContainer setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [mapViewContainer addSubview:_mapView];
    [mapViewContainer setBackgroundColor:[CPColor blueColor]];
}


- (void)willLoad
{
    [super willLoad];

    var bounds = [self bounds];
    
    [_mapView setFrame:bounds];
    [mapViewContainer setFrame:bounds];
}

- (void)willShow 
{
    [super willShow];
    
    var bounds = [[self superview] bounds];
    [self setFrame:bounds];
}

- (void)willHide 
{
    [super willHide];
}

- (void)mapViewIsReady:(MKMapView)aMapView
{
    CPLogConsole("MapView is ready");
    
    var loc = [[MKLocation alloc] initWithLatitude:48.8542 andLongitude:2.3449];
    var marker = [[MKMarker alloc] initAtLocation:loc];
    [marker closeInfoWindow];
    [marker addToMapView:aMapView];
    [marker addEventForName:@"click" withFunction:function(theEvent){
        
        var aPoint = [CPEvent mouseLocation];
        console.log(aPoint.x + ":" + aPoint.y);
        var bubble = [[TNMarkerBubbleView alloc] initAtPosition:aPoint];
        [self addSubview:bubble];
    }]
    
    [aMapView setCenter:loc];
}



@end



