/*
 * TNDatasourceMedias.j
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


TNArchipelDrivesFormats = [@"qcow2", @"qcow", @"cow", @"raw", @"vmdk"];


/*! @ingroup virtualmachinedrives
    This class represent a media (a drive)
*/
@implementation TNMedia : CPObject
{
    CPString    _diskSize        @accessors(setter=setDiskSize:);
    CPString    _format          @accessors(property=format);
    CPString    _name            @accessors(property=name);
    CPString    _path            @accessors(property=path);
    CPString    _virtualSize     @accessors(property=virtualSize);
}


#pragma mark -
#pragma mark Initialization

/*! initializes and returns TNMedia with given values
    @param aPath the path of the media
    @param aName the name of the media
    @param aFormat the format of the media
    @param vSize the virtual size of the media
    @param dSize the real size of the media
    @return initialized TNMedia
*/
+ (TNMedia)mediaWithPath:(CPString)aPath name:(CPString)aName format:(CPString)aFormat virtualSize:(CPString)vSize diskSize:(CPString)dSize
{
    var media = [[TNMedia alloc] init];
    [media setPath:aPath];
    [media setName:aName];
    [media setFormat:aFormat];
    [media setVirtualSize:vSize];
    [media setDiskSize:dSize];

    return media;
}


- (CPString)diskSize
{
    if (Math.round(_diskSize / 1024 / 1024 / 1024) > 0)
        return Math.round(_diskSize / 1024 / 1024 / 1024) + CPBundleLocalizedString(@"GB", @"GB");
    else if (Math.round(_diskSize / 1024 / 1024) > 0)
        return Math.round(_diskSize / 1024 / 1024) + CPBundleLocalizedString(@"MB", @"MB");
    else if (Math.round(_diskSize / 1024) > 0)
        return Math.round(_diskSize / 1024) + CPBundleLocalizedString(@"KB", @"KB");
    else
        return _diskSize + CPBundleLocalizedString(@"B", @"B");
}
@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNMedia], comment);
}
