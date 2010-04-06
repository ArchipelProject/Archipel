/*  
 * TNSampleToolbarModule.j
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

@import "TNVMCastDatasource.j";

/*! @defgroup  templatingmodule Module Templating
    
    @desc This module manages XVM2 templating system
*/


/*! @ingroup templatingmodule
    templating module implementation
*/
@implementation TNTemplating : TNModule
{
    @outlet CPScrollView    mainScrollView @accessors;
    
    CPOutlineView           _mainOutlineView;
    TNVMCastDatasource      _castsDatasource;
}

- (void)awakeFromCib
{
    _castsDatasource = [[TNVMCastDatasource alloc] init];
    
    _mainOutlineView = [[CPOutlineView alloc] initWithFrame:[mainScrollView bounds]];
    [_mainOutlineView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainOutlineView setDataSource:_castsDatasource];
    
    var columnName = [[CPTableColumn alloc] initWithIdentifier:@"name"];
    [[columnName headerView] setStringValue:@"VM Casts"];
    [columnName setResizingMask:CPTableColumnAutoresizingMask];
    [columnName setWidth:200];
    
    var columnDescription = [[CPTableColumn alloc] initWithIdentifier:@"comment"];
    [[columnDescription headerView] setStringValue:@"Comment"];
    [columnDescription setResizingMask:CPTableColumnAutoresizingMask];
    [columnDescription setWidth:300];
    
    [_mainOutlineView setOutlineTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnDescription];
    
    // test
    
    var urlA        = [CPURL URLWithString:@"http://enomalism.com/vmcast_appliances.php"];
    
    var newSourceA = [TNVMCastSource VMCastSourceWithName:@"Amazon EC2 A" URL:urlA comment:@"My first datasource"];
    //var newSourceB = [TNVMCastSource VMCastSourceWithName:@"Amazon EC2 B" URL:nil comment:@"My second datasource"];

    
    // var newCastA    = [TNVMCast VMCastWithName:@"Debian 4.0" downloadURL:nil comment:@"Debian 4.0 packaged"];
    // var newCastB    = [TNVMCast VMCastWithName:@"RHEL 4.0" downloadURL:nil comment:@"RHEL 4.0 packaged"];
    
    //[[newSourceA content] addObject:newCastA];
    //[[newSourceA content] addObject:newCastB];
    
    [newSourceA populate];
    [_castsDatasource addSource:newSourceA];
    // [_castsDatasource addSource:newSourceB];
    // end test
    
    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setBorderedWithHexColor:@"#9e9e9e"]
    [mainScrollView setDocumentView:_mainOutlineView];
    [_mainOutlineView reloadData];
}


- (void)willLoad
{
    [super willLoad];
    // message sent when view will be added from superview;
}

- (void)willUnload
{
    [super willUnload];
   // message sent when view will be removed from superview;
}

- (void)willShow
{
    [super willShow];
    // message sent when the tab is clicked
}

- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}

@end



