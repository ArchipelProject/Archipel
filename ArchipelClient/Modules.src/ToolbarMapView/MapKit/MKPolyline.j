@import <AppKit/CPView.j>
@import "MKMapItem.j"
@import "MKMapView.j"
@import "MKLocation.j"

@implementation MKPolyline : MKMapItem
{
    CPArray     _locations     @accessors(property=locations);
    CPString    _colorCode     @accessors(property=colorCode);
    int         _lineStroke    @accessors(property=lineStroke);
}

+ (MKPolyline)polyline
{
    return [[MKPolyline alloc] init];
}

- (id)init
{
    return [self initWithLocations:nil];
}

- (id)initWithLocations:(CPArray)someLocations
{
    if (self = [super init])
    {
        _locations = someLocations;
        _colorCode = @"#ff0000";
        _lineStroke = 5;
    }
    return self;
}

- (void)addLocation:(MKLocation)aLocation
{
    if (!_locations)
    {
        _locations = [[CPArray alloc] init];
    }

    [_locations addObject:aLocation];
}

- (Polyline)googlePolyline
{
    if (_locations)
    {
        var gm = [MKMapView gmNamespace],
            locEnum = [_locations objectEnumerator],
            loc = nil,
            lineCoordinates = [];

        while (loc = [locEnum nextObject])
        {
            lineCoordinates.push([loc googleLatLng]);
        }

        return new gm.Polyline(lineCoordinates, _colorCode, _lineStroke);
    }

    return nil;
}

- (void)addToMapView:(MKMapView)mapView
{
    var googleMap = [mapView gMap];
    googleMap.addOverlay([self googlePolyline]);
}



@end

