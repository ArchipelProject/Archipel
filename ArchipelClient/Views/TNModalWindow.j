/*  
 * NTModalWindow.j
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

/*! @ingroup archipelcore
    a nice modal CPWindow
*/
@implementation TNModalWindow: CPWindow

- (id)initWithContentRect:(CPRect)aFrame styleMask:(id)aMask
{
 if (self = [super initWithContentRect:aFrame styleMask:CPBorderlessWindowMask])
 {
     var bundle  = [CPBundle mainBundle],
         frame   = [[self contentView] frame],
         bgImage = [[CPNinePartImage alloc] initWithImageSlices:[
             [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ModalWindow/modal-bezel-0.png"] size:CPSizeMake(24, 63)],
             [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ModalWindow/modal-bezel-1.png"] size:CPSizeMake(1, 63)],
             [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ModalWindow/modal-bezel-2.png"] size:CPSizeMake(24, 63)],
             [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ModalWindow/modal-bezel-3.png"] size:CPSizeMake(24, 1)],
             [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ModalWindow/modal-bezel-4.png"] size:CPSizeMake(1, 1)],
             [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ModalWindow/modal-bezel-5.png"] size:CPSizeMake(24, 1)],
             [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ModalWindow/modal-bezel-6.png"] size:CPSizeMake(24, 25)],
             [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ModalWindow/modal-bezel-7.png"] size:CPSizeMake(1, 25)],
             [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"ModalWindow/modal-bezel-8.png"] size:CPSizeMake(24, 25)]
         ]];

     [self setBackgroundColor:[CPColor colorWithPatternImage:bgImage]];
 }

 return self;
}

@end