/*  
 * TNViewHypervisorControl.j
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
@import <AppKit/CPCollectionView.j>

@import "TNNetwork.j"
@import "TNCollectionViewItemVirtualMachines.j"
@import "TNCollectionViewItemNetworks.j"
@import "TNDraggableVirtualMachine.j"
@import "TNCollectionViews.j"

dragTypeVirtualMachine                  = @"dragTypeVirtualMachine";

trinityTypeHypervisorControl            = @"trinity:hypervisor:control";
trinityTypeHypervisorControlRosterVM    = @"rostervm";

trinityTypeHypervisorNetwork            = @"trinity:hypervisor:network";
trinityTypeHypervisorNetworkList        = @"list";
trinityTypeHypervisorNetworkDefine      = @"define";
trinityTypeHypervisorNetworkUndefine    = @"indefine";
trinityTypeHypervisorNetworkCreate      = @"create";
trinityTypeHypervisorNetworkDestroy     = @"destroy";




@implementation TNHypervisorNetworks : TNModule 
{
    @outlet CPScrollView    scrollViewVirtualMachines           @accessors;
    @outlet CPScrollView    scrollViewNetworks                  @accessors;
    @outlet CPScrollView    scrollViewVirtualMachinesInNetwork  @accessors;

    TNCollectionViewVirtualMachines                 collectionViewVirtualMachines           @accessors;
    TNCollectionViewNetworks                        collectionViewNetworks                 @accessors;
    TNCollectionViewVirtualMachinesInNetwork        collectionViewVirtualMachinesInNetwork  @accessors;    
}

- (void)awakeFromCib
{    
    // virtual machines
    var frame                       = [[self scrollViewVirtualMachines] bounds];
    collectionViewVirtualMachines   = [[TNCollectionViewVirtualMachines alloc] initWithFrame:frame];
    
    [[self collectionViewVirtualMachines] setDelegate:self];
    
    [[self scrollViewVirtualMachines] setBorderedWithHexColor:@"#9e9e9e"];
    [[self scrollViewVirtualMachines] setAutoresizingMask:CPViewWidthSizable];
    [[self scrollViewVirtualMachines] setAutohidesScrollers:YES];
    [[self scrollViewVirtualMachines] setDocumentView:collectionViewVirtualMachines];
    [[self scrollViewVirtualMachines] setBackgroundColor:[CPColor whiteColor]];
    
    
    //networks TODO replace with a TableView.
    var frame                       = [[self scrollViewNetworks] bounds];
    collectionViewNetworks          = [[TNCollectionViewNetworks alloc] initWithFrame:frame];
    
    [[self scrollViewNetworks] setBorderedWithHexColor:@"#9e9e9e"];
    [[self scrollViewNetworks] setAutohidesScrollers:YES];
    [[self scrollViewNetworks] setDocumentView:collectionViewNetworks];
    [[self scrollViewNetworks] setBackgroundColor:[CPColor whiteColor]];
    
    
    //virtual machines in networks
    var frame                               = [[self scrollViewVirtualMachinesInNetwork] bounds];    
    collectionViewVirtualMachinesInNetwork  = [[TNCollectionViewVirtualMachinesInNetwork alloc] initWithFrame:frame];
    
    [[self collectionViewVirtualMachinesInNetwork] setDelegate:self];
    
    [[self scrollViewVirtualMachinesInNetwork] setBorderedWithHexColor:@"#9e9e9e"];
    [[self scrollViewVirtualMachinesInNetwork] setAutohidesScrollers:YES];
    [[self scrollViewVirtualMachinesInNetwork] setDocumentView:collectionViewVirtualMachinesInNetwork];
    [[self scrollViewVirtualMachinesInNetwork] setBackgroundColor:[CPColor whiteColor]];
}

- (void)willLoad
{
    // message sent when view will be added from superview;
    // MUST be declared
}

- (void)willUnload
{
   // message sent when view will be removed from superview;
   // MUST be declared
}

- (void)willShow 
{
    [self getHypervisorRoster];
    [self getHypervisorNetworks];
}

- (void)willHide 
{
    // message sent when the tab is changed
}

- (void)getHypervisorRoster
{   
    var uid             = [[[self contact] connection] getUniqueId];
    var rosterStanza    = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
        
    [rosterStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlRosterVM}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorRoster:) ofObject:self withDict:params];
    [[[self contact] connection] send:rosterStanza];
}

- (void)didReceiveHypervisorRoster:(id)aStanza 
{
    var queryItems  = [aStanza childrenWithName:@"item"];
    
    [[[self collectionViewVirtualMachines] virtualMachines] removeAllObjects];
    
    for (var i = 0; i < [queryItems count]; i++)
    {
        var jid     = [[queryItems objectAtIndex:i] text];
        var entry   = [[self roster] getContactFromJID:jid];
        
        if (entry) 
        {
            if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
            {
                var draggableVM = [TNDraggableVirtualMachine draggableVirtualMachineWithJid:[entry jid] nickname:[entry nickname] statusIcon:[entry statusIcon]];
                [[[self collectionViewVirtualMachines] virtualMachines] addObject:draggableVM];
            }
        }
    }
    [[self collectionViewVirtualMachines] reloadContent];
}

- (void)getHypervisorNetworks
{
    var uid             = [[[self contact] connection] getUniqueId];
    var networksStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorNetwork, "to": [[self contact] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
        
    [networksStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorNetworkList}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorNetworks:) ofObject:self withDict:params];
    [[[self contact] connection] send:networksStanza];
}

- (void)didReceiveHypervisorNetworks:(id)aStanza 
{
    var activeNetworks  = [[[aStanza childrenWithName:@"activedNetworks"] objectAtIndex:0] children];
    var unactiveNetworks  = [[[aStanza childrenWithName:@"unactivedNetworks"] objectAtIndex:0] children];
    
    [[[self collectionViewNetworks] networks] removeAllObjects];
    
    for (var i = 0; i < [activeNetworks count]; i++)
    {
        var network     = [activeNetworks objectAtIndex:i];
        var name        = [[network firstChildWithName:@"name"] text];
        var newNetwork  = [TNNetwork networkWithName:name];
        
        [[[self collectionViewNetworks] networks] addObject:newNetwork];   
    }
    
    for (var i = 0; i < [unactiveNetworks count]; i++)
    {
        var network     = [unactiveNetworks objectAtIndex:i];
        var name        = [[network firstChildWithName:@"name"] text];
        var newNetwork  = [TNNetwork networkWithName:name];
        
        [[[self collectionViewNetworks] networks] addObject:newNetwork];
    }
    
    [[self collectionViewNetworks] reloadContent];
}


// DnD delegates methods
- (CPArray)collectionView:(CPCollectionView)aCollectionView dragTypesForItemsAtIndexes:(CPIndexSet)indices
{
    if (aCollectionView === [self collectionViewVirtualMachines])
        return [dragTypeVirtualMachine];
}

- (CPData)collectionView:(CPCollectionView)aCollectionView dataForItemsAtIndexes:(CPIndexSet)indices forType:(CPString)aType
{
    if (aCollectionView === [self collectionViewVirtualMachines])
    {
        var firstIndex = [indices firstIndex];
        return [CPKeyedArchiver archivedDataWithRootObject:[[[self collectionViewVirtualMachines] virtualMachines] objectAtIndex:firstIndex]];
    }
}





@end



