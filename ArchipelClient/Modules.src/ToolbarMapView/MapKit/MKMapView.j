@import <AppKit/CPView.j>
@import "MKMapScene.j"
@import "MKMarker.j"
@import "MKLocation.j"
@import "MKPolyline.j"

/* a "class" variable that will hold the domWin.google.maps object/"namespace" */
var gmNamespace = nil;

@implementation CPWebView(ScrollFixes) {
    - (void)loadHTMLStringWithoutMessingUpScrollbars:(CPString)aString
    {
        [self _startedLoading];
    
        _ignoreLoadStart = YES;
        _ignoreLoadEnd = NO;
    
        _url = null;
        _html = aString;
    
        [self _load];
    }
}
@end

@implementation MKMapView : CPWebView
{
    CPString        _apiKey;
    DOMElement      _DOMMapElement;
    JSObject        _gMap               @accessors(property=gMap);
    MKMapScene      _scene              @accessors(property=scene);
    BOOL            _mapReady;
    BOOL            _googleAjaxLoaded;
    id delegate @accessors;
    BOOL hasLoaded;
}

- (id)initWithFrame:(CGRect)aFrame apiKey:(CPString)apiKey
{
    _apiKey = apiKey;
    if (self = [super initWithFrame:aFrame]) {
        _scene = [[MKMapScene alloc] initWithMapView:self];

        var bounds = [self bounds];
        var bundle = [CPBundle bundleForClass:[self class]];
        
        [self setFrameLoadDelegate:self];
        [self setMainFrameURL:[bundle pathForResource:@"map.html"]];
    }

    return self;
}

- (void)webView:(CPWebView)aWebView didFinishLoadForFrame:(id)aFrame {
    // this is called twice for some reason
    if(!hasLoaded) {
        [self loadGoogleMapsWhenReady];
    }
    hasLoaded = YES;
}

- (void)loadGoogleMapsWhenReady() {
    var domWin = [self DOMWindow];
    
    if (typeof(domWin.google) === 'undefined') {
        domWin.window.setTimeout(function() {[self loadGoogleMapsWhenReady];}, 100);
    } else {
        var googleScriptElement = domWin.document.createElement('script');
        domWin.mapsJsLoaded = function () {
            //alert('mapsJsLoaded!');
            _googleAjaxLoaded = YES;
            _DOMMapElement = domWin.document.getElementById('MKMapViewDiv');
            [self createMap];
        };
        googleScriptElement.innerHTML = "google.load('maps', '2', {'callback': mapsJsLoaded});"
        domWin.document.getElementsByTagName('head')[0].appendChild(googleScriptElement);
    }
}

- (void)createMap
{
    var domWin = [self DOMWindow];
    //remember the google maps namespace, but only once because it's a class variable
    if (!gmNamespace) {
        gmNamespace = domWin.google.maps;
    }
    
    // for some things the current google namespace needs to be used...
    var localGmNamespace = domWin.google.maps;

    //console.log("Creating map");
    _gMap = new localGmNamespace.Map2(_DOMMapElement);
    //_gMap.addMapType(G_SATELLITE_3D_MAP);
    _gMap.setMapType(localGmNamespace.G_PHYSICAL_MAP);
    _gMap.setUIToDefault();
    _gMap.enableContinuousZoom();
    _gMap.setCenter(new localGmNamespace.LatLng(52, -1), 8);
    _gMap.setZoom(6);
    
    // Hack to get mouse up event to work
    localGmNamespace.Event.addDomListener(document.body, 'mouseup', function() { try { localGmNamespace.Event.trigger(domWin, 'mouseup'); } catch(e){} });

    _mapReady = YES;
    
    if (delegate && [delegate respondsToSelector:@selector(mapViewIsReady:)]) {
        [delegate mapViewIsReady:self];
    }
}
- (void)setFrameSize:(CGSize)aSize
{
    [super setFrameSize:aSize];
    var bounds = [self bounds];
    if (_gMap) {
        _gMap.checkResize();
    }
}

/* Overriding CPWebView's implementation */
- (BOOL)_resizeWebFrame {
    var width = [self bounds].size.width,
        height = [self bounds].size.height;

    _iframe.setAttribute("width", width);
    _iframe.setAttribute("height", height);

    [_frameView setFrameSize:CGSizeMake(width, height)];
}

- (void)viewDidMoveToSuperview
{
    if (!_mapReady && _googleAjaxLoaded) {
        [self createMap];
    }
    [super viewDidMoveToSuperview];
}

- (void)setCenter:(MKLocation)aLocation {
    if (_mapReady) {
        _gMap.setCenter([aLocation googleLatLng]);
    }
}

- (void)setZoom:(int)zoomLevel {
    if (_mapReady) {
        _gMap.setZoom(zoomLevel);
    }
}

- (MKMarker)addMarker:(MKMarker)aMarker atLocation:(MKLocation)aLocation
{
    if (_mapReady) {
        var gMarker = [aMarker gMarker];
        gMarker.setLatLng([aLocation googleLatLng]);
        _gMap.addOverlay(gMarker);
    } else {
        // TODO some sort of queue?
    }
    return marker;
}

- (void)clearOverlays 
{
    if (_mapReady) {
        _gMap.clearOverlays();
    }
}

- (void)addMapItem:(MKMapItem)mapItem
{
    [mapItem addToMapView:self];
}

- (BOOL)isMapReady 
{
    return _mapReady;
}

- (void)physicalMode
{
    if (_mapReady)
    {
        _gMap.setMapType(gmNamespace.G_PHYSICAL_MAP);
        _gMap.setUIToDefault();
    }
}
- (void)clean
{
    gmNamespace.GUnload();
    gmNamespace = nil;
}

+ (JSObject)gmNamespace {
    return gmNamespace;
}

@end

