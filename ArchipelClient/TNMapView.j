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
@import <MapKit/MKMapView.j>

@implementation TNMarkerBubbleView : CPView
{
    
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        [self setBackgroundColor:[CPColor blueColor]];
    }
    return self;
}

- (id)initAtPosition:(CGPoint)aPoint
{
    var frame = CGRectMake(aPoint.x, aPoint.y, 200, 100);
    
    if (self = [super initWithFrame:frame])
    {
        [self setBackgroundColor:[CPColor blueColor]];
        console.log("YEAH");
    }
    return self;
}
@end

@implementation TNMapView : CPView
{
    MKMapView   _mapView;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        console.log([self bounds]);
        
        var bounds = [self bounds];
        
        _mapView = [[MKMapView alloc] initWithFrame:bounds apiKey:''];
        
        [_mapView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
        [_mapView setDelegate:self];
        [self addSubview:_mapView];
        
    }
    return self;
}

- (void)mapViewIsReady:(MKMapView)aMapView
{
    var loc = [[MKLocation alloc] initWithLatitude:48.8542 andLongitude:2.3449];
    var marker = [[MKMarker alloc] initAtLocation:loc];
    [marker closeInfoWindow];
    [marker addToMapView:_mapView];
    [marker addEventForName:@"click" withFunction:function(theEvent){
        
        var aPoint = [CPEvent mouseLocation];
        console.log(aPoint.x + ":" + aPoint.y);
        var bubble = [[TNMarkerBubbleView alloc] initAtPosition:aPoint];
        [self addSubview:bubble];
    }]
    
    [_mapView setCenter:loc];
}
@end
