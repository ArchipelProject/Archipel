/*  
 * TNMessageView.j
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


@implementation TNCollectionViewItemVirtualMachines : CPView
{
    CPTextField _fieldVirtualMachineName;
    CPImageView _imageVirtualMachineStatusIcon;
}

- (void)setRepresentedObject:(id)anObject
{
    if (!_fieldVirtualMachineName)
    {
        var frame = [self bounds];
        
        [self setBorderedWithHexColor:@"#9e9e9e"];
        [self setBackgroundColor:[CPColor colorWithHexString:@"d9dfe8"]];
        
        _fieldVirtualMachineName = [[CPTextField alloc] initWithFrame:CGRectMake(21,0, 70, 70)];
        [_fieldVirtualMachineName setFont:[CPFont boldSystemFontOfSize:10]];
        [_fieldVirtualMachineName setTextColor:[CPColor grayColor]];
        [_fieldVirtualMachineName setLineBreakMode:CPLineBreakByWordWrapping];
        [self addSubview:_fieldVirtualMachineName];

        _imageVirtualMachineStatusIcon = [[CPImageView alloc] initWithFrame:CGRectMake(5, 0, 16, 16)];
        [self addSubview:_imageVirtualMachineStatusIcon];
    }
    var name    = [anObject nickname];
    
    [_fieldVirtualMachineName setStringValue:name];
    [_imageVirtualMachineStatusIcon setImage:[anObject statusIcon]]
    
}

- (void)setSelected:(BOOL)isSelected
{
    [self setBackgroundColor:isSelected ? [CPColor colorWithHexString:@"f6f9fc"] : [CPColor colorWithHexString:@"d9dfe8"]];
}
@end
