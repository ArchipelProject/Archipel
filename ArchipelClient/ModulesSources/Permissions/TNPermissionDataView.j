/*
 * TNPermissionDataView.j
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
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPTextField.j>

@import "../../Views/TNBasicDataView.j"


/*! @ingroup permissions
    This class represent a permission DataView
*/
@implementation TNPermissionDataView : TNBasicDataView
{
    @outlet CPTextField fieldName;
    @outlet CPTextField fieldDescription;
    @outlet CPCheckBox  checkboxState;

    TNPermission _currentPermission;
}

#pragma mark -
#pragma mark Overrides

/*! Set the object value of the data view
    @param aPermission The permission informations to display
*/
- (void)setObjectValue:(CPDictionary)aPermission
{
    _currentPermission = aPermission;

    [fieldName setStringValue:[_currentPermission name]];
    [fieldDescription setStringValue:[_currentPermission description]];
    [checkboxState setState:[_currentPermission state] ? CPOnState : CPOffState];

    [checkboxState setTarget:self];
    [checkboxState setAction:@selector(updateState:)];
}

- (IBAction)updateState:(id)aSender
{
    [_currentPermission setState:([aSender state] == CPOnState)]
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
        fieldDescription = [aCoder decodeObjectForKey:@"fieldDescription"];
        checkboxState = [aCoder decodeObjectForKey:@"checkboxState"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:fieldName forKey:@"fieldName"];
    [aCoder encodeObject:fieldDescription forKey:@"fieldDescription"];
    [aCoder encodeObject:checkboxState forKey:@"checkboxState"];
}

@end
