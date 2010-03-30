@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation TNNetworkInterface : CPObject
{
    CPString type   @accessors;
    CPString model  @accessors;
    CPString mac    @accessors;
    CPString source @accessors;
}

+ (TNNetworkInterface)networkInterfaceWithType:(CPString)aType model:(CPString)aModel mac:(CPString)aMac source:(CPString)aSource
{
    var card = [[TNNetworkInterface alloc] init];
    [card setType:aType];
    [card setModel:aModel];
    [card setMac:aMac];
    [card setSource:aSource];

    return card;
}

@end

@implementation TNDatasourceNetworkInterfaces : CPObject
{
    CPArray nics @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        [self setNics:[[CPArray alloc] init]];
    }
    return self;
}

- (void)addNic:(TNNetworkInterfaces)aNic
{
    [[self nics] addObject:aNic];
}


// Datasource impl.
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable
{
    return [[self nics] count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];

    return [[[self nics] objectAtIndex:aRow] valueForKey:identifier];
}

@end