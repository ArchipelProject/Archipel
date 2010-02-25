@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@implementation TNNetworkInterface : CPObject
{
    CPString name   @accessors;
    CPString type   @accessors;
    CPString model  @accessors;
    CPString mac    @accessors;
    CPString source @accessors;
    CPString target @accessors;
}

+ (TNNetworkInterface)networkInterfaceWithName:(CPString)aName type:(CPString)aType model:(CPString)aModel mac:(CPString)aMac source:(CPString)aSource target:(CPString)aTarget
{
    var card = [[TNNetworkInterface alloc] init];
    [card setName:aName];
    [card setType:aType];
    [card setModel:aModel];
    [card setMac:aMac];
    [card setSource:aSource];
    [card setTarget:aTarget];
    
    return card;
}

@end

@implementation TNDatasourceNetworkInterfaces : CPObject
{
    CPArray networkInterfaces @accessors;
}

- (id)init
{
    if (self = [super init])
    {
        [self setNetworkInterfaces:[[CPArray alloc] init]];
    }
    return self;
}

- (void)addNic:(TNNetworkInterfaces)aNic
{
    [[self networkInterfaces] addObject:aNic];
}


// Datasource impl.
- (CPNumber)numberOfRowsInTableView:(CPTableView)aTable 
{
    return [[self networkInterfaces] count];
}

- (id)tableView:(CPTableView)aTable objectValueForTableColumn:(CPNumber)aCol row:(CPNumber)aRow
{
    var identifier = [aCol identifier];
    
    return [[[self networkInterfaces] objectAtIndex:aRow] valueForKey:identifier];
}

@end