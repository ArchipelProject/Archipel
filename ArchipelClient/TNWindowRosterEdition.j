/*  
 * TNWindowRosterEdition.j
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

@implementation TNWindowRosterEdition: CPWindow 
{
    @outlet CPImageView entryStatusIcon;
    @outlet CPTextField entryDomain;
    @outlet CPTextField entryName;
    @outlet CPTextField entryRessource;
    @outlet CPTextField entryStatus;

    id  item @accessors;
}


- (void)updateValue
{
    [[self entryName] setStringValue:[item nickname]];
    [[self entryDomain] setStringValue:[item domain]];
    [[self entryRessource] setStringValue:[item resource]];
    [[self entryStatusIcon] setImage:[item statusIcon]];
    [[self entryStatus] setStringValue:[item status]];
}

- (IBAction)removeUser:(id)sender 
{
    [[self item] removeUser];
}
@end
