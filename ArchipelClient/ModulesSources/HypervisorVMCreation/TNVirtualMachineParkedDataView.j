/*
 * TNVirtualMachineParkedDataView.j
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


var TNVirtualMachineDataViewAvatarUnknown;


/*! @ingroup hypervisorvmcreation
    This class represent a virtual machine DataView
*/
@implementation TNVirtualMachineParkedDataView : TNBasicDataView
{
    @outlet CPTextField fieldUUID;
    @outlet CPTextField fieldName;
    @outlet CPTextField fieldDate;
    @outlet CPTextField fieldParker;
    @outlet CPTextField labelParker;
    @outlet CPTextField labelDate;
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    // var bundle = [CPBundle mainBundle];
    // TNVirtualMachineDataViewAvatarUnknown = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
}


#pragma mark -
#pragma mark Overrides

/*! Set the object value of the data view
    @param aParkedVM The praked vm informations to display
*/
- (void)setObjectValue:(CPDictionary)aParkedVM
{
    [fieldName setStringValue:[aParkedVM name]];
    [fieldUUID setStringValue:[aParkedVM UUID]];
    [fieldDate setStringValue:[aParkedVM date]];
    [fieldParker setStringValue:[aParkedVM parker]];
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
        fieldName = [aCoder decodeObjectForKey:@"fieldName"];
        fieldUUID = [aCoder decodeObjectForKey:@"fieldUUID"];
        fieldParker = [aCoder decodeObjectForKey:@"fieldParker"];
        fieldDate = [aCoder decodeObjectForKey:@"fieldDate"];
        labelParker = [aCoder decodeObjectForKey:@"labelName"];
        labelDate= [aCoder decodeObjectForKey:@"labelUUID"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:fieldName forKey:@"fieldName"];
    [aCoder encodeObject:fieldUUID forKey:@"fieldUUID"];
    [aCoder encodeObject:fieldDate forKey:@"fieldDate"];
    [aCoder encodeObject:fieldParker forKey:@"fieldParker"];
    [aCoder encodeObject:labelParker forKey:@"labelName"];
    [aCoder encodeObject:labelDate forKey:@"labelUUID"];
}

@end