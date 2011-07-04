/*
 * TNNotificationHistoryController.j
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

@import <AppKit/CPButton.j>
@import <AppKit/CPCollectionView.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNTableViewDataSource.j>

/*! @ingroup archipelcore
    Representation of Archipel entity avatar controler
*/
@implementation TNNotificationHistoryController : CPObject
{
    @outlet CPButton            buttonClear;
    @outlet CPTableView         tableHistory;
    @outlet CPWindow            mainWindow              @accessors(readonly);

    TNTableViewDataSource       _datasourceNotification;
}


#pragma mark -
#pragma mark Initialization

- (void)awakeFromCib
{
    var columnIcon  = [tableHistory tableColumnWithIdentifier:@"icon"],
        imageView   = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];

    [imageView setImageScaling:CPScaleProportionally];
    [columnIcon setWidth:16];
    [columnIcon setDataView:imageView]

    _datasourceNotification  = [[TNTableViewDataSource alloc] init];
    [_datasourceNotification setTable:tableHistory];
    [tableHistory setDataSource:_datasourceNotification];
}


#pragma mark -
#pragma mark Actions

/*! overide the super makeKeyAndOrderFront in order to getAvailableAvatars on display
    @param sender the sender of the action
*/
- (IBAction)showWindow:(id)aSender
{
    [tableHistory setNeedsLayout];
    [_datasourceNotification setContent:[[TNGrowlCenter defaultCenter] notificationsHistory]];
    [tableHistory reloadData];
    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];
}

/*! clean the history
    @param sender the sender of the action
*/

- (IBAction)cleanHistory:(id)aSender
{
    [[TNGrowlCenter defaultCenter] clearHistory];
    // this is weird actually, TNTableViewDataSource seems to still copy the content.
    // But I have fixed this a while ago...
    [_datasourceNotification setContent:[[TNGrowlCenter defaultCenter] notificationsHistory]];
    [tableHistory reloadData];
}

@end
