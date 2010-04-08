/*  
 * TNUserPreferences
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

var standardUserDefaultsInstance;

TNUserDefaultsUserStandard      = @"TNUserDefaultsUserStandard";

@implementation TNUserDefaults : CPObject
{
    CPDictionary    _appDefaults;
    CPDictionary    _defaults;
    CPString        _user;
}

+ (TNUserDefaults)standardUserDefaults
{
    if (!standardUserDefaultsInstance)
    {
        standardUserDefaultsInstance = [[TNUserDefaults alloc] init];
    }
    
    return standardUserDefaultsInstance;
}

+ (void)resetStandardUserDefaults
{
    localStorage.removeItem(TNUserDefaultsStorageIdentifier);
    
    standardUserDefaultsInstance = [[TNUserDefaults alloc] init];
}

- (TNUserDefaults)initWithUser:(CPString)aUser
{
    var recovering;
    
    if (recovering = [self recover])
    {
        self = recovering;
    }
    else if (self = [super init])
    {
        _defaults   = [CPDictionary dictionary];
        _user       = aUser;
        
        [_defaults setObject:[CPDictionary dictionary] forKey:_user];
        [self synchronize];
    }
    
    return self;
}

- (TNUserDefaults)init
{
    return [self initWithUser:TNUserDefaultsUserStandard];
}

- (void)recover
{
    var rawDataString;
    var ret;
    var identifier = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"];

    if (rawDataString = localStorage.getItem(identifier))
        ret = [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:rawDataString]];
    
    return ret;
}

- (void)synchronize
{
    var datas       = [CPKeyedArchiver archivedDataWithRootObject:self];
    var identifier  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"];

    localStorage.setItem(identifier, [datas rawString]);
}

- (void)clean
{
    localStorage.clear();
}

- (void)registerDefaults:(CPDictionary)someDefaults
{
    _appDefaults = [someDefaults copy];
    
    [self synchronize];
}

- (void)removeObjectForKey:(CPString)aKey
{
    var currentDefault = [_defaults objectForKey:_user];
    
    [currentDefault removeObjectForKey:aKey];
    
    [self synchronize];
}



// GETTERS
- (id)objectForKey:(CPString)aKey
{
    var currentDefault  = [_defaults objectForKey:_user];
    var value           = [currentDefault objectForKey:aKey];

    if (!value)
        value = [_appDefaults objectForKey:aKey];

    return value;
}

- (CPArray)arrayForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

- (BOOL)boolForKey:(CPString)aKey
{
    var value = [self objectForKey:aKey];
    
    return (value == @"YES") ? YES : NO;
}

- (CPData)dataForKey:(CPString)aKey
{
   return [self objectForKey:aKey];
}

- (CPDictionary)dictionaryForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

- (CPNumber)floatForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

- (CPNumber)integerForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

- (CPArray)stringArrayForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

- (CPString)stringForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

- (CPNumber)doubleForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

- (CPURL)URLForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}


// SETTERS
- (void)setObject:(id)aValue forKey:(CPString)aKey
{
    var currentDefault = [_defaults objectForKey:_user];
    
    [currentDefault setObject:aValue forKey:aKey];
    
    [self synchronize];
}

- (void)setBool:(BOOL)aValue forKey:(CPString)aKey
{
    var value = (aValue) ? @"YES" : @"NO";
    
    [self setObject:value forKey:aKey];
}

- (void)setFloat:(CPNumber)aValue forKey:(CPString)aKey
{
    [self setObject:aValue forKey:aKey];
}

- (void)setInteger:(CPNumber)aValue forKey:(CPString)aKey
{
    [self setObject:aValue forKey:aKey];
}

- (void)setDouble:(CPNumber)aValue forKey:(CPString)aKey
{
    [self setObject:aValue forKey:aKey];
}

- (void)setURL:(CPURL)aValue forKey:(CPString)aKey
{
    [self setObject:aValue forKey:aKey];
}

- (id)initWithCoder:(CPCoder)aCoder
{
    _defaults       = [aCoder decodeObjectForKey:@"_defaults"];
    _appDefaults    = [aCoder decodeObjectForKey:@"_appDefaults"];
    _user           = [aCoder decodeObjectForKey:@"_user"];
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_defaults forKey:@"_defaults"];
    [aCoder encodeObject:_appDefaults forKey:@"_appDefaults"];
    [aCoder encodeObject:_user forKey:@"_user"];
}


@end
