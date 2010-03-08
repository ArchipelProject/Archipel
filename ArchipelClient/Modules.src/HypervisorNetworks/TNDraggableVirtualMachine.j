/*  
 * TNDraggableVirtualMachine.j
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

@implementation TNDraggableVirtualMachine : CPObject
{
    CPString nickname   @accessors;
    CPImage statusIcon  @accessors;
    CPString jid        @accessors;
}
+ (TNDraggableVirtualMachine) draggableVirtualMachineWithJid:(CPString)aJid nickname:(CPString)aNickname statusIcon:(CPImage)anIcon
{
    var ret = [[TNDraggableVirtualMachine alloc] init]
    [ret setJid:aJid];
    [ret setNickname:aNickname];
    [ret setStatusIcon:anIcon];
    return ret;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    [self setJid:[aCoder decodeObjectForKey:@"jid"]];
    [self setNickname:[aCoder decodeObjectForKey:@"nickname"]];
    [self setStatusIcon:[aCoder decodeObjectForKey:@"statusIcon"]];

    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:jid forKey:@"jid"];
    [aCoder encodeObject:nickname forKey:@"nickname"];
    [aCoder encodeObject:statusIcon forKey:@"statusIcon"];
}

@end