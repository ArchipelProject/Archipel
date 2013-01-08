/*
 * TNVirtualMachineDataView.j
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

@import "../../Views/TNBasicDataView.j"

var TNVirtualMachineDataViewAvatarUnknown;


/*! @ingroup hypervisorvmcreation
    This class represent a virtual machine DataView
*/
@implementation TNVirtualMachineDataView : TNBasicDataView
{
    @outlet CPImageView imageAvatar;
    @outlet CPImageView imageStatusIcon;
    @outlet CPTextField fieldCategories;
    @outlet CPTextField fieldCompany;
    @outlet CPTextField fieldHypervisor;
    @outlet CPTextField fieldJID;
    @outlet CPTextField fieldLocality;
    @outlet CPTextField fieldLocality;
    @outlet CPTextField fieldName;
    @outlet CPTextField fieldNickName;
    @outlet CPTextField fieldOwner;
    @outlet CPTextField fieldServer;
    @outlet CPTextField fieldStatus;
    @outlet CPTextField fieldUnit;
    @outlet CPTextField labelCategories;
    @outlet CPTextField labelCompany;
    @outlet CPTextField labelHypervisor;
    @outlet CPTextField labelLocality;
    @outlet CPTextField labelName;
    @outlet CPTextField labelOwner;
    @outlet CPTextField labelServer;
    @outlet CPTextField labelStatus;
    @outlet CPTextField labelUnit;
}


#pragma mark -
#pragma mark Initialization

+ (void)initialize
{
    var bundle = [CPBundle mainBundle];
    TNVirtualMachineDataViewAvatarUnknown = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"user-unknown.png"]];
}

- (void)shouldHideLabels:(BOOL)shouldHide
{
    [fieldCompany setHidden:shouldHide];
    [fieldLocality setHidden:shouldHide];
    [fieldOwner setHidden:shouldHide];
    [fieldUnit setHidden:shouldHide];
    [fieldStatus setHidden:shouldHide];
    [fieldName setHidden:shouldHide];
    [labelCompany setHidden:shouldHide];
    [fieldCategories setHidden:shouldHide];
    [labelLocality setHidden:shouldHide];
    [labelStatus setHidden:shouldHide];
    [labelName setHidden:shouldHide];
    [labelUnit setHidden:shouldHide];
    [labelOwner setHidden:shouldHide];
    [labelCategories setHidden:shouldHide];
}

#pragma mark -
#pragma mark Overrides

/*! Set the object value of the data view
    @param aDrive TNStropheContact to represent
*/
- (void)setObjectValue:(TNStropheContact)aContact
{
    [fieldJID setStringValue:[aContact JID]];
    [fieldServer setStringValue:[[aContact JID] domain]];
    [fieldHypervisor setStringValue:[[aContact JID] resource]];

    if ([aContact vCard])
    {
        [self shouldHideLabels:NO];
        [fieldName setStringValue:[[[aContact vCard] firstChildWithName:@"FN"] text]];
        [fieldLocality setStringValue:[[[aContact vCard] firstChildWithName:@"LOCALITY"] text]];
        [fieldCompany setStringValue:[[[aContact vCard] firstChildWithName:@"ORGNAME"] text]];
        [fieldUnit setStringValue:[[[aContact vCard] firstChildWithName:@"ORGUNIT"] text]];
        [fieldOwner setStringValue:[[[aContact vCard] firstChildWithName:@"USERID"] text]];
        [fieldCategories setStringValue:[[[aContact vCard] firstChildWithName:@"CATEGORIES"] text]];
        [fieldNickName setStringValue:[aContact nickname]];
        [fieldStatus setStringValue:[aContact XMPPStatus]];
        [imageAvatar setImage:[aContact avatar]];
    }
    else
    {
        [fieldNickName setStringValue:[aContact nickname] || @"This machine is not in your roster"];
        [imageAvatar setImage:TNVirtualMachineDataViewAvatarUnknown];
        [self shouldHideLabels:YES];
    }

    [imageStatusIcon setImage:[aContact statusIcon]];
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
        fieldCategories = [aCoder decodeObjectForKey:@"fieldCategories"];
        fieldCompany = [aCoder decodeObjectForKey:@"fieldCompany"];
        fieldHypervisor = [aCoder decodeObjectForKey:@"fieldHypervisor"];
        fieldJID = [aCoder decodeObjectForKey:@"fieldJID"];
        fieldLocality = [aCoder decodeObjectForKey:@"fieldLocality"];
        fieldName = [aCoder decodeObjectForKey:@"fieldName"];
        fieldNickName = [aCoder decodeObjectForKey:@"fieldNickName"];
        fieldOwner = [aCoder decodeObjectForKey:@"fieldOwner"];
        fieldServer = [aCoder decodeObjectForKey:@"fieldServer"];
        fieldStatus = [aCoder decodeObjectForKey:@"fieldStatus"];
        fieldUnit = [aCoder decodeObjectForKey:@"fieldUnit"];
        labelCategories = [aCoder decodeObjectForKey:@"labelCategories"];
        labelCompany = [aCoder decodeObjectForKey:@"labelCompany"];
        labelHypervisor = [aCoder decodeObjectForKey:@"labelHypervisor"];
        labelLocality = [aCoder decodeObjectForKey:@"labelLocality"];
        labelName = [aCoder decodeObjectForKey:@"labelName"];
        labelServer = [aCoder decodeObjectForKey:@"labelServer"];
        labelStatus = [aCoder decodeObjectForKey:@"labelStatus"];

        imageStatusIcon = [aCoder decodeObjectForKey:@"imageStatusIcon"];
        imageAvatar = [aCoder decodeObjectForKey:@"imageAvatar"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:fieldCategories forKey:@"fieldCategories"];
    [aCoder encodeObject:fieldCompany forKey:@"fieldCompany"];
    [aCoder encodeObject:fieldHypervisor forKey:@"fieldHypervisor"];
    [aCoder encodeObject:fieldJID forKey:@"fieldJID"];
    [aCoder encodeObject:fieldLocality forKey:@"fieldLocality"];
    [aCoder encodeObject:fieldName forKey:@"fieldName"];
    [aCoder encodeObject:fieldNickName forKey:@"fieldNickName"];
    [aCoder encodeObject:fieldOwner forKey:@"fieldOwner"];
    [aCoder encodeObject:fieldServer forKey:@"fieldServer"];
    [aCoder encodeObject:fieldStatus forKey:@"fieldStatus"];
    [aCoder encodeObject:fieldUnit forKey:@"fieldUnit"];
    [aCoder encodeObject:imageAvatar forKey:@"imageAvatar"];
    [aCoder encodeObject:imageStatusIcon forKey:@"imageStatusIcon"];
    [aCoder encodeObject:labelCategories forKey:@"labelCategories"];
    [aCoder encodeObject:labelCompany forKey:@"labelCompany"];
    [aCoder encodeObject:labelHypervisor forKey:@"labelHypervisor"];
    [aCoder encodeObject:labelLocality forKey:@"labelLocality"];
    [aCoder encodeObject:labelName forKey:@"labelName"];
    [aCoder encodeObject:labelServer forKey:@"labelServer"];
    [aCoder encodeObject:labelStatus forKey:@"labelStatus"];
}

@end
