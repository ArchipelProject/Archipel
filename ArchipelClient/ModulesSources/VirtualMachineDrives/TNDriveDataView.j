/*
 * TNDriveDataView.j
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

@import <AppKit/CPView.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTextField.j>

var TNDriveDataViewIconQCOW2,
    TNDriveDataViewIconQCOW,
    TNDriveDataViewIconCOW,
    TNDriveDataViewIconVMDK,
    TNDriveDataViewIconRAW;


/*! @ingroup virtualmachinedrives
    This class represent a drive DataView
*/
@implementation TNDriveDataView : TNBasicDataView
{
    @outlet CPImageView imageDriveIcon;
    @outlet CPTextField fieldDriveName;
    @outlet CPTextField fieldGoldenDrive;
    @outlet CPTextField fieldPath;
    @outlet CPTextField fieldRealSize;
    @outlet CPTextField fieldVirtualSize;
    @outlet CPTextField labelGoldenDrive;
    @outlet CPTextField labelRealSize;
    @outlet CPTextField labelVirtualSize;
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:[self class]];
    TNDriveDataViewIconQCOW2    = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"drive_qcow2.png"]];
    TNDriveDataViewIconQCOW     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"drive_qcow.png"]];
    TNDriveDataViewIconCOW      = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"drive_cow.png"]];
    TNDriveDataViewIconVMDK     = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"drive_vmdk.png"]];
    TNDriveDataViewIconRAW      = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"drive_raw.png"]];
}


#pragma mark -
#pragma mark Overrides

/*! Set the object value of the data view
    @param aDrive TNDrive to represent
*/
- (void)setObjectValue:(id)aDrive
{
    switch ([aDrive format])
    {
        case "qcow2":
            [imageDriveIcon setImage:TNDriveDataViewIconQCOW2];
            break;
        case "qcow":
            [imageDriveIcon setImage:TNDriveDataViewIconQCOW];
            break;
        case "cow":
            [imageDriveIcon setImage:TNDriveDataViewIconCOW];
            break;
        case "vmdk":
            [imageDriveIcon setImage:TNDriveDataViewIconVMDK];
            break;
        case "raw":
            [imageDriveIcon setImage:TNDriveDataViewIconRAW];
            break;
    }

    [fieldDriveName setStringValue:[aDrive name]];
    [fieldVirtualSize setStringValue:[aDrive virtualSize]];
    [fieldRealSize setStringValue:[aDrive diskSize]];

    if ([aDrive backingFile] && [aDrive backingFile] != @"")
    {
        [fieldGoldenDrive setHidden:NO];
        [labelGoldenDrive setHidden:NO];
        [fieldGoldenDrive setStringValue:[aDrive backingFile]];
    }
    else
    {
        [fieldGoldenDrive setHidden:YES];
        [labelGoldenDrive setHidden:YES];
    }

    [fieldPath setStringValue:[aDrive path]];
}


#pragma mark -
#pragma mark CPCoding compliance

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        imageDriveIcon = [aCoder decodeObjectForKey:@"imageDriveIcon"];
        fieldDriveName = [aCoder decodeObjectForKey:@"fieldDriveName"];
        fieldVirtualSize = [aCoder decodeObjectForKey:@"fieldVirtualSize"];
        fieldRealSize = [aCoder decodeObjectForKey:@"fieldRealSize"];
        fieldGoldenDrive = [aCoder decodeObjectForKey:@"fieldGoldenDrive"];
        fieldPath = [aCoder decodeObjectForKey:@"fieldPath"];
        labelGoldenDrive = [aCoder decodeObjectForKey:@"labelGoldenDrive"];
        labelVirtualSize = [aCoder decodeObjectForKey:@"labelVirtualSize"];
        labelRealSize = [aCoder decodeObjectForKey:@"labelRealSize"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:imageDriveIcon forKey:@"imageDriveIcon"];
    [aCoder encodeObject:fieldDriveName forKey:@"fieldDriveName"];
    [aCoder encodeObject:fieldVirtualSize forKey:@"fieldVirtualSize"];
    [aCoder encodeObject:fieldRealSize forKey:@"fieldRealSize"];
    [aCoder encodeObject:fieldGoldenDrive forKey:@"fieldGoldenDrive"];
    [aCoder encodeObject:fieldPath forKey:@"fieldPath"];
    [aCoder encodeObject:labelGoldenDrive forKey:@"labelGoldenDrive"];
    [aCoder encodeObject:labelVirtualSize forKey:@"labelVirtualSize"];
    [aCoder encodeObject:labelRealSize forKey:@"labelRealSize"];
}

@end