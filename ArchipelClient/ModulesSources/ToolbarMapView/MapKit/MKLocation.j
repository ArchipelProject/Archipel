@import <Foundation/CPObject.j>

@class MKMapView

@implementation MKLocation : CPObject
{
    float         _latitude   @accessors(property=latitude);
    float         _longitude  @accessors(property=longitude);
}

+ (MKLocation)location
{
    return [[MKLocation alloc] init];
}

+ (MKLocation)locationWithLatitude:(float)aLat andLongitude:(float)aLng
{
    return [[MKLocation alloc] initWithLatitude:aLat andLongitude:aLng];
}

- (id)initWithLatLng:(LatLng)aLatLng
{
    return [self initWithLatitude:aLatLng.lat() andLongitude:aLatLng.lng()];
}

- (id)initWithLatitude:(float)aLat andLongitude:(float)aLng
{
    if (self = [super init])
    {
        _latitude = aLat;
        _longitude = aLng;
    }
    return self;
}

- (LatLng)googleLatLng
{
    var gm = [MKMapView gmNamespace];
    return new gm.LatLng(_latitude, _longitude);
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:[_latitude, _longitude] forKey:@"location"];
}

@end

