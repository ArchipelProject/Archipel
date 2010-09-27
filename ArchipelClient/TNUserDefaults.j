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

standardUserDefaultsInstance = nil;

TNUserDefaultsUserStandard      = @"TNUserDefaultsUserStandard";


TNUserDefaultStorageTypeHTML5       = @"TNUserDefaultStorageTypeHTML5";
TNUserDefaultStorageTypeCookie      = @"TNUserDefaultStorageTypeCookie";
TNUserDefaultStorageTypeNoStorage   = @"TNUserDefaultStorageTypeNoStorage";

TNUserDefaultStorageType            = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNUserDefaultStorageType"];

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
    if (self = [super init])
    {
        _defaults   = [CPDictionary dictionary];
        _user       = aUser;

        [_defaults setObject:[CPDictionary dictionary] forKey:_user];
    }

    return self;
}

- (TNUserDefaults)init
{
    return [self initWithUser:TNUserDefaultsUserStandard];
}

- (void)recoverObjectForKey:(CPString)aKey
{
    var rawDataString,
        ret,
        identifier  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"] + "_" + aKey;

    if (TNUserDefaultStorageType == TNUserDefaultStorageTypeHTML5)
    {
        CPLog.trace(@"Recovering from HTML5 storage");

        try
        {
            if (rawDataString = localStorage.getItem(identifier))
                ret = [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:rawDataString]];
        }
        catch(e)
        {
            CPLog.error("Error while trying to recovering : " + e);
        }
    }
    else if (TNUserDefaultStorageType == TNUserDefaultStorageTypeCookie)
    {
        CPLog.trace(@"Recovering from cookie storage");

        if ((rawDataString = [[CPCookie alloc] initWithName:identifier]) && [rawDataString value] != @"")
        {
            var decodedString =  [rawDataString value].replace(/__dotcoma__/g, ";").replace(/__dollar__/g, "$");

            ret = [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:decodedString]];
        }
    }
    else if ( TNUserDefaultStorageType == TNUserDefaultStorageTypeNoStorage)
    {
        CPLog.trace(@"No storage specified");

        ret = nil;
    }
    else
    {
        throw new Error("Unknown storage type: " + _defaultStorageType + " storage type is unknown");
    }

    if (!ret)
        ret = [_appDefaults objectForKey:aKey];

    return ret;
}

- (void)synchronizeObject:(id)anObject forKey:(CPString)aKey
{
    var datas       = [CPKeyedArchiver archivedDataWithRootObject:anObject],
        identifier  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"] + "_" + aKey,
        string      = [datas rawString];

    if (TNUserDefaultStorageType == TNUserDefaultStorageTypeHTML5)
    {
        try
        {
            localStorage.setItem(identifier, string);
        }
        catch(e)
        {
            CPLog.error("Error while trying to synchronize : " + e);
        }
    }
    else if (TNUserDefaultStorageType == TNUserDefaultStorageTypeCookie)
    {
        CPLog.trace(@"saving into cookie storage");

        var cookie      = [[CPCookie alloc] initWithName:identifier],
            theString   = string.replace(/;/g, "__dotcoma__").replace(/$/g, "__dollar__");

        [cookie setValue:theString expires:[CPDate distantFuture] domain:@""];
    }
    else if (TNUserDefaultStorageType == TNUserDefaultStorageTypeNoStorage)
    {
        // we do nothing here
    }
    else
    {
        throw new Error("Unknown storage type: " + TNUserDefaultStorageType + " storage type is unknown");
    }
}

- (void)clean
{
    var identifier  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"];

    if (TNUserDefaultStorageType == TNUserDefaultStorageTypeHTML5)
    {
        CPLog.trace(@"clearing HTML5 storage");

        localStorage.clear(identifier);
    }
    else if (TNUserDefaultStorageType == TNUserDefaultStorageTypeCookie)
    {
        CPLog.warn(@"clearing cookie storage is not supported. Use your browser to do this");
    }
    else
    {
        throw new Error("Unknown storage type: " + TNUserDefaultStorageType + " storage type is unknown");
    }
}

- (void)registerDefaults:(CPDictionary)someDefaults
{
    _appDefaults = [someDefaults copy];
}

- (void)removeObjectForKey:(CPString)aKey
{
    var identifier  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"] + "_" + aKey;

    if (TNUserDefaultStorageType == TNUserDefaultStorageTypeHTML5)
    {
        CPLog.trace(@"clearing HTML5 storage for key " + aKey);

        localStorage.removeItem(identifier);
    }
    else if (TNUserDefaultStorageType == TNUserDefaultStorageTypeCookie)
    {
        CPLog.trace(@"clearing cookie storage for key " + aKey);

        var cookie  = [[CPCookie alloc] initWithName:identifier];

        [cookie setValue:@"" expires:[CPDate distantFuture] domain:@""];
    }
    else
    {
        throw new Error("Unknown storage type: " + TNUserDefaultStorageType + " storage type is unknown");
    }
}



// GETTERS
- (id)objectForKey:(CPString)aKey
{
    return [self recoverObjectForKey:aKey];
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
    //CPLog.trace("Setting default " + aKey + " = " + aValue);

    var currentDefault = [_defaults objectForKey:_user],
        datas       = [CPKeyedArchiver archivedDataWithRootObject:aValue],
        identifier  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"] + "_" + aKey,
        string      = [datas rawString];

    [currentDefault setObject:aValue forKey:aKey];
    [self synchronizeObject:aValue forKey:aKey];
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
    _defaults        = [aCoder decodeObjectForKey:@"_defaults"];
    _appDefaults     = [aCoder decodeObjectForKey:@"_appDefaults"];
    _user            = [aCoder decodeObjectForKey:@"_user"];

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_defaults forKey:@"_defaults"];
    [aCoder encodeObject:_appDefaults forKey:@"_appDefaults"];
    [aCoder encodeObject:_user forKey:@"_user"];
}


@end
