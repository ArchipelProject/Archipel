/*
 * TNVersion.j
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
    this class represent a version and provide some utilities to compare them
*/
@implementation TNVersion :CPObject
{
    int _major      @accessors(property=major);
    int _minor      @accessors(property=minor);
    int _revision   @accessors(property=revision);
}

#pragma mark -
#pragma mark Initialization

/*! return a new initialized TNVersion
    @param aMajor the value of the major
    @param aMinor the value of the minor
    @param aRevision the value of the revision
    @return a new TNVersion
*/
+ (TNVersion)versionWithMajor:(int)aMajor minor:(int)aMinor revision:(int)aRevision
{
    var version = [[TNVersion alloc] init];
    [version setMajor:aMajor];
    [version setMinor:aMinor];
    [version setRevision:aRevision];

    return version;
}

#pragma mark -
#pragma mark Compare

/*! check if given version is equal
    @param aVersion the version to compare
    @return YES or NO
*/
- (BOOL)equals:(TNVersion)aVersion
{
    return ([aVersion major] == [self major] && [aVersion minor] == [self minor] && [aVersion revision] == [self revision]);
}

/*! check if given version is greater than self
    @param aVersion the version to compare
    @return YES or NO
*/
- (BOOL)greaterThan:(TNVersion)aVersion
{
    if ([self equals:aVersion])
        return NO;

    if ([self major] > [aVersion major])
        return YES;
    else if ([self major] < [aVersion major])
        return NO;

    if ([self minor] > [aVersion minor])
        return YES;
    else if ([self minor] < [aVersion minor])
        return NO

    if ([self revision] > [aVersion revision])
        return YES;
    else if ([self minor] < [aVersion minor])
        return NO;

    return NO;
}

/*! check if given version is lesser than self
    @param aVersion the version to compare
    @return YES or NO
*/
- (BOOL)lesserThan:(TNVersion)aVersion
{
    if ([self equals:aVersion])
        return NO;
    return ![self greaterThan:aVersion];
}

#pragma mark -
#pragma mark Overrides

/*! format the version as a string
    @return the version in a CPString
*/
- (CPString)description
{
    return _major + @"." + _minor + @"." + _revision;
}

@end


@implementation TNVersion (CPCoding)

/*! CPCoder compliance
*/
- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        _major = [aCoder decodeObjectForKey:@"_major"];
        _minor = [aCoder decodeObjectForKey:@"_minor"];
        _revision = [aCoder decodeObjectForKey:@"_revision"];
    }

    return self;
}

/*! CPCoder compliance
*/
- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_major forKey:@"_major"];
    [aCoder encodeObject:_minor forKey:@"_minor"];
    [aCoder encodeObject:_revision forKey:@"_revision"];
}

@end
