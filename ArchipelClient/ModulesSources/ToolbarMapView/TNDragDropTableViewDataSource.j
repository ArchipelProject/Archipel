/*
 * TNDragDropTableViewDatasource.j
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
@import <AppKit/CPTableView.j>

@import <TNKit/TNTableViewDataSource.j>


var TNDragTypeMigration = @"TNDragTypeMigration";


@implementation TNDragDropTableViewDataSource: TNTableViewDataSource
{
    id _draggedItem;
}

// drag and drop
- (BOOL)tableView:(CPTableView)tableView writeRowsWithIndexes:(CPIndexSet)rowIndexes toPasteboard:(CPPasteboard)pboard
{
    _draggedItem = [_content objectAtIndex:[rowIndexes firstIndex]];

    [pboard declareTypes:[TNDragTypeMigration] owner:nil];
    [pboard setData:[CPKeyedArchiver archivedDataWithRootObject:_draggedItem] forType:TNDragTypeMigration];

    return YES;
}

- (CPDragOperation)tableView:(CPTableView)aTableView validateDrop:(id)info proposedRow:(CPInteger)row proposedDropOperation:(CPTableViewDropOperation)operation
{
    alert("BIDREL");

    // if ([info draggingSource] !== aTableView)
    //     return CPDragOperationNone;

    [aTableView setDropRow:row dropOperation:CPTableViewDropAbove];

    return CPDragOperationDelete;
}


- (BOOL)tableView:(CPTableView)tableView acceptDrop:(id <CPDraggingInfo>)info row:(int)row dropOperation:(CPTableViewDropOperation)operation
{

    var pboard  = [info draggingPasteboard],
        data    = [pboard dataForType:TNDragTypeMigration],
        object  = [CPKeyedUnarchiver unarchiveObjectWithData:_draggedItem];

    [_content insertObject:object atIndex:row];
    [tableView reloadData];

        return YES;
    }

    return NO;
}


@end