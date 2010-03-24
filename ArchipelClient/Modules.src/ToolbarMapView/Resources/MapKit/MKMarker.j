@import <AppKit/CPView.j>
@import "MKMapItem.j"
@import "MKMapView.j"
@import "MKLocation.j"

@implementation MKMarker : MKMapItem
{
    Marker      _gMarker    @accessors(property=gMarker);
    MKLocation  _location   @accessors(property=location);
    BOOL        _draggable  @accessors(property=draggable);
    BOOL        _withShadow  @accessors(property=withShadow);
    CPString    _iconUrl    @accessors(property=iconUrl);
    CPString    _shadowUrl  @accessors(property=shadowUrl);
    id          _delegate  @accessors(property=delegate);
    CPString    _infoWindowHTML;
    CPDictionary _eventHandlers;
}

+ (MKMarker)marker
{
    return [[MKMarker alloc] init];
}

- (id)initAtLocation:(MKLocation)aLocation
{
    if (self = [super init]) {
        _location = aLocation;
        _withShadow = YES;
        _draggable = YES;
    }
    return self;
}

- (void)updateLocation
{
    _location = [[MKLocation alloc] initWithLatLng:_gMarker.getLatLng()];
    
    if (_delegate && [_delegate respondsToSelector:@selector(mapMarker:didMoveToLocation:)]) {
        [_delegate mapMarker:self didMoveToLocation:_location];
    }
}

/*!
    Sets the icon URL based on this url pattern:
    http://maps.google.com/mapfiles/ms/micons/<anIconName>.png
    
    Some examples:
    
    POI
    arts
    bar
    blue-dot
    blue-pushpin
    blue
    bus
    cabs
    camera
    campfire
    campground
    caution
    coffeehouse
    convienancestore
    cycling
    dollar
    drinking_water
    earthquake
    electronics
    euro
    fallingrocks
    ferry
    firedept
    fishing
    flag
    gas
    golfer
    green-dot
    green
    grn-pushpin
    grocerystore
    groecerystore
    helicopter
    hiker
    homegardenbusiness
    horsebackriding
    hospitals
    hotsprings
    info
    info_circle
    landmarks-jp
    lightblue
    lodging
    ltblu-pushpin
    ltblue-dot
    man
    marina
    mechanic
    motorcycling
    movies
    orange-dot
    orange
    parkinglot
    partly_cloudy
    pharmacy-us
    phone
    picnic
    pink-dot
    pink-pushpin
    pink
    plane
    police
    postoffice-jp
    postoffice-us
    purple-dot
    purple-pushpin
    purple
    question
    rail
    rainy
    rangerstation
    realestate
    recycle
    red-dot
    red-pushpin
    red
    restaurant
    sailing
    salon
    shopping
    ski
    ski
    snack_bar
    snowflake_simple
    sportvenue
    subway
    sunny
    swimming
    toilets
    trail
    tram
    tree
    truck
    volcano
    water
    waterfalls
    webcam
    wheel_chair_accessible
    woman
    yellow-dot
    yellow
    yen
    ylw-pushpin
    
    You can find a list of official google maps icons here:
    http://www.visual-case.it/cgi-bin/vc/GMapsIcons.pl
*/
- (void)setGoogleIcon:(CPString)anIconName withShadow:(BOOL)withShadow
{
    _withShadow = withShadow;
    
    if (anIconName) {
        _iconUrl = "http://maps.google.com/mapfiles/ms/micons/" + anIconName + ".png"
        
        if (withShadow) {
            if (anIconName.match(/dot/) || anIconName.match(/(blue|green|lightblue|orange|pink|purple|red|yellow)$/)) {
                _shadowUrl = "http://maps.google.com/mapfiles/ms/micons/msmarker.shadow.png";
            } else if (anIconName.match(/pushpin/)) {
                _shadowUrl = "http://maps.google.com/mapfiles/ms/micons/pushpin_shadow.png";
            } else {
                _shadowUrl = "http://maps.google.com/mapfiles/ms/micons/" + anIconName + ".shadow.png";
            }
        }
    } else {
        _iconUrl = nil;
        _shadowUrl = "http://maps.google.com/mapfiles/ms/micons/msmarker.shadow.png"; //default shadow
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
    var googleMap = [mapView gMap];
    var gm = [MKMapView gmNamespace];
    
    var icon = new gm.Icon(gm.DEFAULT_ICON);
    
    // set a different icon if the _iconUrl is set
    if (_iconUrl) 
    {
        icon.image = _iconUrl;
        icon.iconSize = new gm.Size(32, 32);
        icon.iconAnchor = new gm.Point(16, 32);
    }
    
    // set the shadow
    if (_withShadow && _shadowUrl) 
    {
        icon.shadow = _shadowUrl;
        icon.shadowSize = new gm.Size(59, 32);
    }
        
    var markerOptions = { "icon":icon, "clickable":false, "draggable":_draggable };    
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

