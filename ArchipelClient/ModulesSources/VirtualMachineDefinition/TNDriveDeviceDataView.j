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

@import "../../Views/TNBasicDataView.j"
@import "Model/TNLibvirtDeviceDisk.j"
@import "Model/TNLibvirtDeviceDiskDriver.j"
@import "Model/TNLibvirtDeviceDiskSource.j"
@import "Model/TNLibvirtDeviceDiskTarget.j"

var TNDriveDeviceDataViewIconQCOW2,
    TNDriveDeviceDataViewIconQCOW,
    TNDriveDeviceDataViewIconCOW,
    TNDriveDeviceDataViewIconVMDK,
    TNDriveDeviceDataViewIconRAW,
    TNDriveDeviceDataViewIconCDROM,
    TNDriveDeviceDataViewIconDISK,
    TNDriveDeviceDataViewIconNETWORK,
    TNDriveDeviceDataViewIconFLOPPY;

/*! @ingroup virtualmachinedefinition
    This is a representation of a data view for displaying a drive device
*/
@implementation TNDriveDeviceDataView : TNBasicDataView
{
    @outlet CPImageView     imageIcon;
    @outlet CPTextField     fieldCache;
    @outlet CPTextField     fieldDevice;
    @outlet CPTextField     fieldFormat;
    @outlet CPTextField     fieldPath;
    @outlet CPTextField     fieldReadOnly;
    @outlet CPTextField     fieldShareable;
    @outlet CPTextField     fieldTarget;
    @outlet CPTextField     fieldTransient;
    @outlet CPTextField     fieldType;

    @outlet CPTextField     labelCache;
    @outlet CPTextField     labelDevice;
    @outlet CPTextField     labelFormat;
    @outlet CPTextField     labelReadOnly;
    @outlet CPTextField     labelShareable;
    @outlet CPTextField     labelTarget;
    @outlet CPTextField     labelTransient;
    @outlet CPTextField     labelType;

    TNLibvirtDeviceDisk     _currentDisk;
}


#pragma mark -
#pragma mark Initialization

/*! initialize the data view
*/
+ (void)initialize
{
    var bundle = [CPBundle bundleForClass:TNDriveDeviceDataView];

    TNDriveDeviceDataViewIconQCOW2      = CPImageInBundle(@"drive_qcow2.png", nil, bundle);
    TNDriveDeviceDataViewIconQCOW       = CPImageInBundle(@"drive_qcow.png", nil, bundle);
    TNDriveDeviceDataViewIconCOW        = CPImageInBundle(@"drive_cow.png", nil, bundle);
    TNDriveDeviceDataViewIconVMDK       = CPImageInBundle(@"drive_vmdk.png", nil, bundle);
    TNDriveDeviceDataViewIconRAW        = CPImageInBundle(@"drive_raw.png", nil, bundle);
    TNDriveDeviceDataViewIconCDROM      = CPImageInBundle(@"drive_cdrom.png", nil, bundle);
    TNDriveDeviceDataViewIconDISK       = CPImageInBundle(@"drive_dev.png", nil, bundle);
    TNDriveDeviceDataViewIconNETWORK    = CPImageInBundle(@"drive_net.png", nil, bundle);
    TNDriveDeviceDataViewIconFLOPPY     = CPImageInBundle(@"drive_floppy.png", nil, bundle);
}


#pragma mark -
#pragma mark Overrides

/*! Set the current object Value
    @param aDisk the disk to represent
*/
- (void)setObjectValue:(TNLibvirtDeviceDisk)aDisk
{
    _currentDisk = aDisk;

    switch ([_currentDisk device])
    {
        case TNLibvirtDeviceDiskDeviceCDROM:
            [imageIcon setImage:TNDriveDeviceDataViewIconCDROM];
            [fieldFormat setStringValue:TNLibvirtDeviceDiskDriverTypeRaw];
            break;

        case TNLibvirtDeviceDiskDeviceFloppy:
            [imageIcon setImage:TNDriveDeviceDataViewIconFLOPPY];
            [fieldFormat setStringValue:TNLibvirtDeviceDiskDriverTypeRaw];
            break;

        case TNLibvirtDeviceDiskDeviceDisk:
            switch ([_currentDisk type])
            {
                case TNLibvirtDeviceDiskTypeDir:
                case TNLibvirtDeviceDiskTypeBlock:
                    [imageIcon setImage:TNDriveDeviceDataViewIconDISK];
                    [fieldFormat setStringValue:TNLibvirtDeviceDiskDriverTypeRaw];
                    break;

                case TNLibvirtDeviceDiskTypeNetwork:
                    [imageIcon setImage:TNDriveDeviceDataViewIconNETWORK];
                    [fieldFormat setStringValue:TNLibvirtDeviceDiskDriverTypeRaw];
                    break

                case TNLibvirtDeviceDiskTypeFile:
                    var _disk_format = ( [_currentDisk source]
                                         && [[_currentDisk source] sourceObject]
                                         && [[_currentDisk source] sourceObject] != @""
                                         && ! ([[[_currentDisk source] sourceObject] isKindOfClass:CPArray])
                                         && [[_currentDisk driver] name] != TNLibvirtDeviceDiskDriverNameQemu
                                       ) ? [[[_currentDisk source] sourceObject].split(".") lastObject] : [[_currentDisk driver] type];

                    switch (_disk_format)
                    {
                        case @"qcow2":
                            [imageIcon setImage:TNDriveDeviceDataViewIconQCOW2];
                            [fieldFormat setStringValue:TNLibvirtDeviceDiskDriverTypeQcow2];
                            break;

                        case @"qcow":
                            [imageIcon setImage:TNDriveDeviceDataViewIconQCOW];
                            [fieldFormat setStringValue:TNLibvirtDeviceDiskDriverTypeQcow];
                            break;

                        case @"cow":
                            [imageIcon setImage:TNDriveDeviceDataViewIconCOW];
                            [fieldFormat setStringValue:TNLibvirtDeviceDiskDriverTypeCow];
                            break;

                        case @"vmdk":
                            [imageIcon setImage:TNDriveDeviceDataViewIconVMDK];
                            [fieldFormat setStringValue:TNLibvirtDeviceDiskDriverTypeVmdk];
                            break;

                        default:
                            [imageIcon setImage:TNDriveDeviceDataViewIconRAW];
                            [fieldFormat setStringValue:TNLibvirtDeviceDiskDriverTypeRaw];
                    }
                    break;

            }
            break;
    }

    if ([_currentDisk source] && [[_currentDisk source] sourceObject] && [[_currentDisk source] sourceObject] != @"")
    {
        if ([[[_currentDisk source] sourceObject] isKindOfClass:CPArray])
        {
            var host = [[[_currentDisk source] sourceObject] firstObject],
                others = [[[_currentDisk source] sourceObject] count] > 1 ? @" (and other sources)" : @"";

            [fieldPath setStringValue:[host name] + @":" + [host port] + others];
        }
        else
            [fieldPath setStringValue:[[[_currentDisk source] sourceObject].split("/") lastObject]];
    }
    else
        [fieldPath setStringValue:@"No source defined"];

    [fieldType setStringValue:[_currentDisk type]];
    [fieldDevice setStringValue:[_currentDisk device]];
    [fieldTarget setStringValue:[[_currentDisk target] bus] + @":" + [[_currentDisk target] device]];
    [fieldCache setStringValue:[[_currentDisk driver] cache]];
    [fieldTransient setStringValue:[_currentDisk isTransient] ? @"Yes" : @"No"];
    [fieldShareable setStringValue:[_currentDisk isShareable] ? @"Yes" : @"No"];
    [fieldReadOnly setStringValue:[_currentDisk isReadOnly] ? @"Yes" : @"No"];

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
        fieldCache = [aCoder decodeObjectForKey:@"fieldCache"];
        fieldDevice = [aCoder decodeObjectForKey:@"fieldDevice"];
        fieldFormat = [aCoder decodeObjectForKey:@"fieldFormat"];
        fieldPath = [aCoder decodeObjectForKey:@"fieldPath"];
        fieldReadOnly = [aCoder decodeObjectForKey:@"fieldReadOnly"];
        fieldShareable = [aCoder decodeObjectForKey:@"fieldShareable"];
        fieldTarget = [aCoder decodeObjectForKey:@"fieldTarget"];
        fieldTransient = [aCoder decodeObjectForKey:@"fieldTransient"];
        fieldType = [aCoder decodeObjectForKey:@"fieldType"];
        imageIcon = [aCoder decodeObjectForKey:@"imageIcon"];
        labelCache = [aCoder decodeObjectForKey:@"labelCache"];
        labelDevice = [aCoder decodeObjectForKey:@"labelDevice"];
        labelFormat = [aCoder decodeObjectForKey:@"labelFormat"];
        labelReadOnly = [aCoder decodeObjectForKey:@"labelReadOnly"];
        labelShareable = [aCoder decodeObjectForKey:@"labelShareable"];
        labelTarget = [aCoder decodeObjectForKey:@"labelTarget"];
        labelTransient = [aCoder decodeObjectForKey:@"labelTransient"];
        labelType = [aCoder decodeObjectForKey:@"labelType"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:imageIcon forKey:@"imageIcon"];

    [aCoder encodeObject:fieldCache forKey:@"fieldCache"];
    [aCoder encodeObject:fieldDevice forKey:@"fieldDevice"];
    [aCoder encodeObject:fieldFormat forKey:@"fieldFormat"];
    [aCoder encodeObject:fieldPath forKey:@"fieldPath"];
    [aCoder encodeObject:fieldReadOnly forKey:@"fieldReadOnly"];
    [aCoder encodeObject:fieldShareable forKey:@"fieldShareable"];
    [aCoder encodeObject:fieldTarget forKey:@"fieldTarget"];
    [aCoder encodeObject:fieldTransient forKey:@"fieldTransient"];
    [aCoder encodeObject:fieldType forKey:@"fieldType"];
    [aCoder encodeObject:labelCache forKey:@"labelCache"];
    [aCoder encodeObject:labelDevice forKey:@"labelDevice"];
    [aCoder encodeObject:labelFormat forKey:@"labelFormat"];
    [aCoder encodeObject:labelReadOnly forKey:@"labelReadOnly"];
    [aCoder encodeObject:labelShareable forKey:@"labelShareable"];
    [aCoder encodeObject:labelTarget forKey:@"labelTarget"];
    [aCoder encodeObject:labelTransient forKey:@"labelTransient"];
    [aCoder encodeObject:labelType forKey:@"labelType"];
}

@end
