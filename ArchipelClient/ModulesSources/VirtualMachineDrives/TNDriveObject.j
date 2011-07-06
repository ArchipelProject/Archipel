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

/*! @ingroup virtualmachinedrives
    This class represent a media (a drive)
*/
@implementation TNDrive : CPObject
{
    CPString    _diskSize        @accessors(property=diskSize);
    CPString    _format          @accessors(property=format);
    CPString    _name            @accessors(property=name);
    CPString    _path            @accessors(property=path);
    CPString    _virtualSize     @accessors(property=virtualSize);
    CPString    _backingFile     @accessors(property=backingFile);
}


#pragma mark -
#pragma mark Initialization

/*! initializes and returns TNDrive with given values
    @param aPath the path of the media
    @param aName the name of the media
    @param aFormat the format of the media
    @param vSize the virtual size of the media
    @param dSize the real size of the media
    @return initialized TNDrive
*/
+ (TNDrive)mediaWithPath:(CPString)aPath
                    name:(CPString)aName
                  format:(CPString)aFormat
             virtualSize:(CPString)vSize
                diskSize:(CPString)dSize
           backingFile:(CPString)aBackingFile
{
    var media = [[TNDrive alloc] init];
    [media setPath:aPath];
    [media setName:aName];
    [media setFormat:aFormat];
    [media setVirtualSize:vSize];
    [media setDiskSize:dSize];
    [media setBackingFile:aBackingFile];

    return media;
}

@end