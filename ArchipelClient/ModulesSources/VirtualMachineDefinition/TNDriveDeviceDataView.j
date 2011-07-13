/*
 * TNDriveDeviceDataView.j
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

@import "Model/TNLibvirtDeviceDisk.j"
@import "Model/TNLibvirtDeviceDiskDriver.j"
@import "Model/TNLibvirtDeviceDiskSource.j"
@import "Model/TNLibvirtDeviceDiskTarget.j"

var TNDriveDeviceDataViewIconQCOW2,
    TNDriveDeviceDataViewIconQCOW,
    TNDriveDeviceDataViewIconCOW,
    TNDriveDeviceDataViewIconVMDK,
    TNDriveDeviceDataViewIconRAW,
    TNDriveDeviceDataViewIconCDROM;

@implementation TNDriveDeviceDataView : TNBasicDataView
{
    @outlet CPImageView     imageIcon;
    @outlet CPTextField     fieldPath;
    @outlet CPTextField     fieldType;
    @outlet CPTextField     fieldDevice;
    @outlet CPTextField     fieldTarget;
    @outlet CPTextField     fieldCache;
    @outlet CPTextField     fieldFormat;
    @outlet CPTextField     labelType;
    @outlet CPTextField     labelDevice;
    @outlet CPTextField     labelTarget;
    @outlet CPTextField     labelCache;
    @outlet CPTextField     labelFormat;

    TNLibvirtDeviceDisk     _currentDisk;
}


#pragma mark -
#pragma mark Initialization

/*! initialize the data view
*/
- (void)initWithFrame:(CPRect)aFrame
{
    if (self = [super initWithFrame:aFrame])
    {
        if (!TNDriveDeviceDataViewIconQCOW2)
        {
            TNDriveDeviceDataViewIconQCOW2 = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"drive_qcow2.png"]];
            TNDriveDeviceDataViewIconQCOW = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"drive_qcow.png"]];
            TNDriveDeviceDataViewIconCOW = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"drive_cow.png"]];
            TNDriveDeviceDataViewIconVMDK = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"drive_vmdk.png"]];
            TNDriveDeviceDataViewIconRAW = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"drive_raw.png"]];
            TNDriveDeviceDataViewIconCDROM = [[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[self class]] pathForResource:@"drive_cdrom.png"]];
        }
    }

    return self;
}


#pragma mark -
#pragma mark Overides

/*! Set the current object Value
    @param aGraphicDevice the disk to represent
*/
- (void)setObjectValue:(TNLibvirtDeviceDisk)aDisk
{
    _currentDisk = aDisk;

    switch ([[_currentDisk driver] type])
    {
        case @"qcow2":
            [imageIcon setImage:TNDriveDeviceDataViewIconQCOW2];
            break;
        case @"qcow":
            [imageIcon setImage:TNDriveDeviceDataViewIconQCOW];
            break;
        case @"cow":
            [imageIcon setImage:TNDriveDeviceDataViewIconCOW];
            break;
        case @"vmdk":
            [imageIcon setImage:TNDriveDeviceDataViewIconVMDK];
            break;
        case @"raw":
            [imageIcon setImage:TNDriveDeviceDataViewIconRAW];
            break;
    }

    if ([_currentDisk device] == TNLibvirtDeviceDiskDeviceCDROM)
        [imageIcon setImage:TNDriveDeviceDataViewIconCDROM];

    [fieldPath setStringValue:[[[_currentDisk source] sourceObject].split("/") lastObject]];
    [fieldType setStringValue:[_currentDisk type]];
    [fieldDevice setStringValue:[_currentDisk device]];
    [fieldTarget setStringValue:[[_currentDisk target] bus] + @":" + [[_currentDisk target] device]];
    [fieldCache setStringValue:[[_currentDisk driver] cache]];
    [fieldFormat setStringValue:[[_currentDisk driver] type]];
}



#pragma mark -
#pragma mark CPCoding

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        imageIcon = [aCoder decodeObjectForKey:@"imageIcon"];
        fieldPath = [aCoder decodeObjectForKey:@"fieldPath"];
        fieldType = [aCoder decodeObjectForKey:@"fieldType"];
        fieldDevice = [aCoder decodeObjectForKey:@"fieldDevice"];
        fieldTarget = [aCoder decodeObjectForKey:@"fieldTarget"];
        fieldCache = [aCoder decodeObjectForKey:@"fieldCache"];
        fieldFormat = [aCoder decodeObjectForKey:@"fieldFormat"];
        labelType = [aCoder decodeObjectForKey:@"labelType"];
        labelDevice = [aCoder decodeObjectForKey:@"labelDevice"];
        labelTarget = [aCoder decodeObjectForKey:@"labelTarget"];
        labelCache = [aCoder decodeObjectForKey:@"labelCache"];
        labelFormat = [aCoder decodeObjectForKey:@"labelFormat"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:imageIcon forKey:@"imageIcon"];

    [aCoder encodeObject:fieldPath forKey:@"fieldPath"];
    [aCoder encodeObject:fieldType forKey:@"fieldType"];
    [aCoder encodeObject:fieldDevice forKey:@"fieldDevice"];
    [aCoder encodeObject:fieldTarget forKey:@"fieldTarget"];
    [aCoder encodeObject:fieldCache forKey:@"fieldCache"];
    [aCoder encodeObject:fieldFormat forKey:@"fieldFormat"];
    [aCoder encodeObject:labelType forKey:@"labelType"];
    [aCoder encodeObject:labelDevice forKey:@"labelDevice"];
    [aCoder encodeObject:labelTarget forKey:@"labelTarget"];
    [aCoder encodeObject:labelCache forKey:@"labelCache"];
    [aCoder encodeObject:labelFormat forKey:@"labelFormat"];

}

@end