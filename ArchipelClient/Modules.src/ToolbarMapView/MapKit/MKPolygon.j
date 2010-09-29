@import <AppKit/CPView.j>
@import "MKMapItem.j"
@import "MKMapView.j"
@import "MKLocation.j"

@implementation MKPolygon : MKMapItem
{
    CPArray     _locations     @accessors(property=locations);
    CPString    _lineColorCode @accessors(property=lineColorCode);
    int         _lineStroke    @accessors(property=lineStroke);
    int         _fillColorCode @accessors(property=fillColorCode);
    float       _fillOpacity   @accessors(property=fillOpacity);
    float       _lineOpacity   @accessors(property=lineOpacity);
}

+ (MKPolygon)polygon
{
    return [[MKPolygon alloc] init];
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
        _lineColorCode = @"#ff0000";
        _fillColorCode = @"#000000";
        _fillOpacity = 0.7;
        _lineOpacity = 1;
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

- (Polygon)googlePolygon
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

        return new gm.Polygon(lineCoordinates, _lineColorCode, _lineStroke,  _lineOpacity, _fillColorCode, _fillOpacity);
    }

    return nil;
}

- (void)addToMapView:(MKMapView)mapView
{
    var googleMap = [mapView gMap];
    googleMap.addOverlay([self googlePolygon]);
}

@end
