@import <Foundation/Foundation.j>
@import "MKMapView.j"

@implementation MKMapScene : CPObject
{
    MKMapView           _mapView    @accessors(property=mapView);
    CPMutableArray      _mapItems;
    CPURLConnection     _readConnection;
}

- (id)initWithMapView:(MKMapView)mapView
{

    if (self = [super init]) {
        _mapView = mapView;
        _mapItems = [[CPArray alloc] init];
    }
    return self;
}

- (String)json
{
    return CPJSObjectCreateJSON({
        mapItems: [self mapItemsAsJSObject]
    });
}

- (BOOL)saveToURL:(CPURL)anURL
{
    var request = [CPURLRequest requestWithURL:anURL];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:"data=" + [self json]];
    
    [request setValue:@"close" forHTTPHeaderField:@"Connection"];
    
    //[request setValue:@"true" forHTTPHeaderField:@"x-cappuccino-overwrite"];
    
    var connection = [CPURLConnection connectionWithRequest:request delegate:self];
}

- (BOOL)readFromURL:(CPURL)anURL
{

    [_readConnection cancel];
    _readConnection = [CPURLConnection connectionWithRequest:[CPURLRequest requestWithURL:anURL] delegate:self];
}

- (void)connection:(CPURLConnection)aConnection didFailWithError:(CPError)anError
{
    if (aConnection == _readConnection) {
        alert('Load failed! ' + anError);
        _readConnection = nil;
    } else {
        alert('Save failed! ' + anError);
    }
}
- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)aData
{
    if (aConnection == _readConnection) {
        var aData = aData.replace('while(1);', '');
        var mapItems = CPJSObjectCreateWithJSON(aData);
        var gm = [MKMapView gmNamespace];
        for (var i in mapItems) {
            var mapItem = mapItems[i];
            [self addMapItem:[[MKMarker alloc] initAtLocation:new gm.LatLng(mapItem.anchor.y, mapItem.anchor.x)]];
        }
    }
}
- (void)connectionDidFinishLoading:(CPURLConnection)aConnection
{
    if (aConnection == _readConnection) {
        alert('Loaded successfully!');
        _readConnection = nil;
    } else {
        alert('Saved successfully!');
    }
}




- (Object)mapItemsAsJSObject
{
    var items = [];

    var enumerator = [_mapItems objectEnumerator],
        item;

    while (item = [enumerator nextObject])
    {
        items.push({
            'class': [item typeName],
            'anchor': [[item location].lng(), [item location].lat()]
        });
    }
    return items;
}

- (id)initWithCoder:(CPCoder)coder
{
    if (self = [super init]) {
        _mapItems = [coder decodeObjectForKey:@"mapItems"];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)coder
{
    [coder encodeObject:_mapItems forKey:@"mapItems"];
}

- (void)addMapItem:(MKMapItem)mapItem
{
    [_mapItems addObject:mapItem];
    [_mapView addMapItem:mapItem];
}

@end
