/*  
 * TNCollectionViews.j
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


@implementation TNCollectionViewVirtualMachines : CPCollectionView
{
    CPArray virtualMachines @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        virtualMachines = [CPArray array];
        
        [self setContent:virtualMachines];
        
        var vm     = [[TNCollectionViewItemVirtualMachines alloc] initWithFrame:CGRectMakeZero()]

        [self setMaxNumberOfRows:1];
        [self setMinItemSize:CGSizeMake(100, 70)];
        [self setMaxItemSize:CGSizeMake(100, 70)];
        [self setSelectable:YES];
        [self setItemPrototype:[[CPCollectionViewItem alloc] init]];
        [[self itemPrototype] setView:vm];
        [self setAutoresizingMask:CPViewWidthSizable];
        
        [self setBackgroundColor:[CPColor whiteColor]];
    }
    
    return self;
}
@end

@implementation TNCollectionViewVirtualMachinesInNetwork : CPCollectionView
{
    CPArray virtualMachinesInNetwork @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        virtualMachinesInNetwork = [CPArray array];
        [self setContent:virtualMachinesInNetwork];
        
        var vmInNetItemView     = [[TNCollectionViewItemVirtualMachines alloc] initWithFrame:CGRectMakeZero()]
        
        [self setMaxNumberOfRows:1];
        [self setMinItemSize:CGSizeMake(100, 70)];
        [self setMaxItemSize:CGSizeMake(100, 70)];
        [self setSelectable:YES];
        [self setItemPrototype:[[CPCollectionViewItem alloc] init]];
        [[self itemPrototype] setView:vmInNetItemView];
        [self setAutoresizingMask:CPViewWidthSizable];
        
        [self registerForDraggedTypes:[dragTypeVirtualMachine]];
        [self setBackgroundColor:[CPColor whiteColor]];
    }
    
    return self;
}

- (void)performDragOperation:(CPDraggingInfo)aSender
{
    var data                = [[aSender draggingPasteboard] dataForType:dragTypeVirtualMachine];
    var unarchivedObject    = [CPKeyedUnarchiver unarchiveObjectWithData:data];
    
    [virtualMachinesInNetwork addObject:unarchivedObject];
    [self reloadContent];
}
@end

@implementation TNCollectionViewNetworks : CPCollectionView
{
    CPArray networks @accessors;
}

- (id)initWithFrame:(CGRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        networks = [CPArray array];
        [self setContent:networks];
        
        var networkItem = [[TNCollectionViewItemNetworks alloc] initWithFrame:CGRectMakeZero()];
        
        [self setAutoresizingMask:CPViewWidthSizable];
        [self setMinItemSize:CGSizeMake(70, 70)];
        [self setMaxItemSize:CGSizeMake(70, 70)];
        [self setSelectable:YES];
        [self setItemPrototype:[[CPCollectionViewItem alloc] init]];
        [[self itemPrototype] setView:networkItem];
        
        [self setBackgroundColor:[CPColor whiteColor]];
    }
    
    return self;
}
@end