/*
 * TNUserDefaultsTest.j
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
@import "../TNUserDefaults.j"


TNUserDefaultStorageType = @"TNUserDefaultStorageTypeHTML5";

@implementation TNUserDefaultsTest : OJTestCase
{
    TNUserDefaults  target;
    TNUserDefaults  targetUser;
}

- (void)setUp
{
    target = [TNUserDefaults standardUserDefaults];
    targetUser = [TNUserDefaults defaultsForUser:@"TEST"];
}

- (void)tearDown
{
    [target removeObjectForKey:@"TESTBOOLKEY"];
    [target removeObjectForKey:@"TESTOBJECTKEY"];
    [targetUser removeObjectForKey:@"TESTBOOLKEY"];
    [targetUser removeObjectForKey:@"TESTOBJECTKEY"];
}

- (void)testSetBoolForKey
{
    [target setBool:YES forKey:@"TESTBOOLKEY"];
    [targetUser setBool:NO forKey:@"TESTBOOLKEY"];

    [self assertTrue:[target boolForKey:@"TESTBOOLKEY"]];
    [self assertFalse:[targetUser boolForKey:@"TESTBOOLKEY"]]
}

- (void)testSetObjectForKey
{
    [target setObject:[CPArray arrayWithObjects:@"cell1", @"cell2"] forKey:@"TESTOBJECTKEY"];
    [targetUser setObject:[CPArray arrayWithObjects:@"cell1-1", @"cell2-1"] forKey:@"TESTOBJECTKEY"];

    var cell1 = [[target objectForKey:@"TESTOBJECTKEY"] objectAtIndex:0],
        cell2 = [[target objectForKey:@"TESTOBJECTKEY"] objectAtIndex:1],
        cell11 = [[targetUser objectForKey:@"TESTOBJECTKEY"] objectAtIndex:0],
        cell21 = [[targetUser objectForKey:@"TESTOBJECTKEY"] objectAtIndex:1];

    [self assert:cell1 equals:@"cell1"];
    [self assert:cell2 equals:@"cell2"];
    [self assert:cell11 equals:@"cell1-1"];
    [self assert:cell21 equals:@"cell2-1"];
}

- (void)testRemoveObjectForKey
{
    [target setBool:YES forKey:@"TESTREMOVE"];
    [targetUser setBool:NO forKey:@"TESTREMOVE"];

    [target removeObjectForKey:@"TESTREMOVE"];
    [targetUser removeObjectForKey:@"TESTREMOVE"];

    [self assert:[target boolForKey:@"TESTREMOVE"] equals:nil];
    [self assert:[targetUser boolForKey:@"TESTREMOVE"] equals:nil];
}

- (void)testAppDefault
{
    var appDefaults = [CPDictionary dictionaryWithObjectsAndKeys:YES, @"TESTAPPDEF-A", @"Hello!", @"TESTAPPDEF-B"];
    [target registerDefaults:appDefaults];

    [self assert:[target boolForKey:@"TESTAPPDEF-A"] equals:YES];
    [self assert:[target objectForKey:@"TESTAPPDEF-B"] equals:@"Hello!"];
    [self assert:[targetUser boolForKey:@"TESTAPPDEF-A"] equals:nil];
}


@end