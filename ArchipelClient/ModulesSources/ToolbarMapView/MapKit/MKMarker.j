@import <AppKit/CPView.j>
@import "MKMapItem.j"
@import "MKLocation.j"

@class MKMapView


@implementation MKMarker : MKMapItem
{
    BOOL            _clickable          @accessors(getter=isClickable, setter=setClickable:);
    BOOL            _draggable          @accessors(getter=isDraggable, setter=setDraggable:);
    BOOL            _withShadow         @accessors(property=withShadow);
    CPString        _iconUrl            @accessors(property=iconUrl);
    CPString        _shadowUrl          @accessors(property=shadowUrl);
    id              _delegate           @accessors(property=delegate);
    id              _userInfo           @accessors(property=userInfo);
    MKMarker        _gMarker            @accessors(property=gMarker);
    MKLocation      _location           @accessors(property=location);

    CPString        _infoWindowHTML;
    CPDictionary    _eventHandlers;
}

+ (MKMarker)marker
{
    return [[MKMarker alloc] init];
}

- (id)initAtLocation:(MKLocation)aLocation
{
    if (self = [super init])
    {
        var bundle = [CPBundle bundleForClass:[self class]];

        _location       = aLocation;
        _withShadow     = NO;
        _draggable      = YES;
        _clickable      = YES;
        _iconUrl        = [bundle pathForResource:@"pin.png"];

        [self addEventForName:@"click" withFunction:function(){
            if ([_delegate respondsToSelector:@selector(markerClicked:userInfo:)])
                [_delegate markerClicked:self userInfo:_userInfo];
        }];
    }
    return self;
}

- (void)updateLocation
{
    _location = [[MKLocation alloc] initWithLatLng:_gMarker.getLatLng()];

    if (_delegate && [_delegate respondsToSelector:@selector(mapMarker:didMoveToLocation:)])
    {
        [_delegate mapMarker:self didMoveToLocation:_location];
    }
}

- (void)setGoogleIcon:(CPString)anIconName withShadow:(BOOL)withShadow
{
    _withShadow = withShadow;

    if (anIconName)
    {
        _iconUrl = "http://maps.google.com/mapfiles/ms/micons/" + anIconName + ".png"

        if (withShadow)
        {
            if (anIconName.match(/dot/) || anIconName.match(/(blue|green|lightblue|orange|pink|purple|red|yellow)$/))
            {
                _shadowUrl = "http://maps.google.com/mapfiles/ms/micons/msmarker.shadow.png";
            }
            else if (anIconName.match(/pushpin/))
            {
                _shadowUrl = "http://maps.google.com/mapfiles/ms/micons/pushpin_shadow.png";
            }
            else
            {
                _shadowUrl = "http://maps.google.com/mapfiles/ms/micons/" + anIconName + ".shadow.png";
            }
        }
    }
    else
    {
        _iconUrl    = nil;
        _shadowUrl  = "http://maps.google.com/mapfiles/ms/micons/msmarker.shadow.png"; //default shadow
    }
}

- (void)setGoogleIcon:(CPString)anIconName
{
    [self setGoogleIcon:anIconName withShadow:YES];
}

- (void)openInfoWindow
{
    if (_gMarker)
    {
        _gMarker.closeInfoWindow();
        _gMarker.openInfoWindowHtml(_infoWindowHTML);
    }
}

- (void)closeInfoWindow
{
    if (_gMarker)
    {
        _gMarker.closeInfoWindow();
    }
}

- (void)setInfoWindowHTML:(CPString)someHTML
{
   [self setInfoWindowHTML:someHTML openOnClick:NO];
}

- (void)setInfoWindowHTML:(CPString)someHTML openOnClick:(BOOL)shouldOpenOnClick
{
    _infoWindowHTML = someHTML;

    if (shouldOpenOnClick)
    {
        [self addEventForName:@"click" withFunction:function() {[self openInfoWindow];}];
    }
}

- (CPString)infoWindowHTML
{
    return _infoWindowHTML;
}

- (void)addEventForName:(CPString)anEvent withFunction:(JSObject)aFunction
{
    if (!_eventHandlers)
    {
        _eventHandlers = {};
    }

    // remember the event handler
    _eventHandlers[anEvent] = aFunction;

    // if we have a marker, we can add it right away...
    if (_gMarker)
    {
       [MKMapView gmNamespace].Event.addListener(_gMarker, anEvent, aFunction);
    }
}


- (void)addToMapView:(MKMapView)mapView
{
    var googleMap   = [mapView gMap],
        gm          = [MKMapView gmNamespace],
        icon        = new gm.Icon(gm.DEFAULT_ICON);

    icon.shadow = nil;
    // set a different icon if the _iconUrl is set
    if (_iconUrl)
    {
        icon.image = _iconUrl;
        icon.iconSize = new gm.Size(29, 36);
        icon.iconAnchor = new gm.Point(9, 36);
    }

    // set the shadow
    if (_withShadow && _shadowUrl)
    {
        icon.shadow = _shadowUrl;
        icon.shadowSize = new gm.Size(59, 32);
    }

    var markerOptions = { "icon":icon, "clickable":_clickable, "draggable":_draggable };
    _gMarker = new gm.Marker([_location googleLatLng], markerOptions);

    // add the infowindow html
    if (_infoWindowHTML)
    {
        _gMarker.openInfoWindowHtml(_infoWindowHTML);
    }

    // are there events that should be added?
    if (_eventHandlers)
    {
        for (var key in _eventHandlers)
        {
            var func = _eventHandlers[key];
            gm.Event.addListener(_gMarker, key, func);
        }
    }

    gm.Event.addListener(_gMarker, 'dragend', function() { [self updateLocation]; });
    googleMap.addOverlay(_gMarker);
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:[[_location latitude], [_location longitude]] forKey:@"location"];
}

@end

