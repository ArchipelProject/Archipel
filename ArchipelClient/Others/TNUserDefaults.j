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

/*! @global
    the default TNUserDefaults instance
*/
standardUserDefaultsInstance        = nil;

/*! @global
    the user's TNUserDefaults instance
*/
currentUserDefaultsInstance         = nil;

/*! @global
    the identifier of the standard user
*/
TNUserDefaultsUserStandard          = @"TNUserDefaultsUserStandard";


/*! @global
    @group TNUserDefaultStorage
    HTML5 storage type identifier
*/
TNUserDefaultStorageTypeHTML5       = @"TNUserDefaultStorageTypeHTML5";

/*! @global
    @group TNUserDefaultStorage
    Cookie-based storage type identifier
*/
TNUserDefaultStorageTypeCookie      = @"TNUserDefaultStorageTypeCookie";

/*! @global
    @group TNUserDefaultStorage
    No storage. (all data will be lost with the session)
*/
TNUserDefaultStorageTypeNoStorage   = @"TNUserDefaultStorageTypeNoStorage";



TNUserDefaultStorageType            = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNUserDefaultStorageType"];

#pragma mark -
#pragma mark TNUserDefaults Base

/*! @ingroup archipelcore

    This class is an implementation of NSUserDefaults.
    It allows to store using different methods (HTML5 or Cookie)
    datas in order to be recovered in future session.
*/
@implementation TNUserDefaults : CPObject
{
    int             _storageType    @accessors(property=storagetype);

    CPDictionary    _appDefaults;
    CPDictionary    _defaults;
    CPString        _user;
}


#pragma mark -
#pragma mark Initialization

/*! return the standart preferences manager
    If it doesn't exists, it will be created and initialized
    with appDefault

    @return standard TNUserDefaults
*/
+ (TNUserDefaults)standardUserDefaults
{
    if (!standardUserDefaultsInstance)
        standardUserDefaultsInstance = [[TNUserDefaults alloc] init];

    return standardUserDefaultsInstance;
}

/*! return the preferences manager for a specific user.
    If it doesn't exists, it will be created and initialized
    with appDefault

    @param aUser the owner of the preferences
    @return user's TNUserDefaults
*/
+ (TNUserDefaults)defaultsForUser:(CPString)aUser
{
    if (!currentUserDefaultsInstance)
        currentUserDefaultsInstance = [[TNUserDefaults alloc] initWithUser:aUser];

    return currentUserDefaultsInstance;
}

/*! reset the standard preferences manager
*/
+ (void)resetStandardUserDefaults
{
    localStorage.removeItem(TNUserDefaultsStorageIdentifier);

    standardUserDefaultsInstance = [[TNUserDefaults alloc] init];
}

/*! Initializes TNUserDefaults with specific user

    @param aUser the owner of the preferences

    @return initialized TNUserDefaults
*/
- (TNUserDefaults)initWithUser:(CPString)aUser
{
    if (self = [super init])
    {
        _defaults       = [CPDictionary dictionary];
        _appDefaults    = [CPDictionary dictionary];
        _user           = aUser;
        _storageType    = TNUserDefaultStorageType;

        [_defaults setObject:[CPDictionary dictionary] forKey:_user];
    }

    return self;
}

/*! Initializes standard TNUserDefaults

    @return initialized TNUserDefaults
*/
- (TNUserDefaults)init
{
    return [self initWithUser:TNUserDefaultsUserStandard];
}

/*! Register the default values for given key in given dictionary.
    If you try to get a value for a key that haven't been set but present
    into the Defaults, TNUserDefaults will retun this value

    @param someDefaults CPDictionary containing the default {"key1": "value1", ..., "keyN": "valueN"}
*/
- (void)registerDefaults:(CPDictionary)someDefaults
{
    [_appDefaults addEntriesFromDictionary:someDefaults];
}


#pragma mark -
#pragma mark Core storage system

/*! recover from storage the the value of object stored for given key.
    You shouldn't use this method yourself.

    @param aKey the key
    @return the value associated to the key
*/
- (void)recoverObjectForKey:(CPString)aKey
{
    var rawDataString,
        ret,
        identifier  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"] + @"_" +_user + @"_"+ aKey;

    switch (_storageType)
    {
        case TNUserDefaultStorageTypeHTML5:
            CPLog.trace(@"Recovering from HTML5 storage");
            try
            {
                if (rawDataString = localStorage.getItem(identifier))
                    ret = [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:rawDataString]]
                if (typeof(ret) == "undefined")
                    ret = nil;
            }
            catch(e)
            {
                CPLog.error("Error while trying to recovering : " + e);
            }
            break;

        case TNUserDefaultStorageTypeCookie:
            CPLog.trace(@"Recovering from cookie storage");

            if ((rawDataString = [[CPCookie alloc] initWithName:identifier]) && [rawDataString value] != @"")
            {
                var decodedString =  [rawDataString value].replace(/__dotcoma__/g, ";").replace(/__dollar__/g, "$");
                ret = [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:decodedString]];
                if (typeof(ret) == "undefined")
                    ret = nil;
            }
            break;

        case TNUserDefaultStorageTypeNoStorage:
            CPLog.trace(@"No storage specified");
            ret = nil;
            break;

        default:
            throw new Error("Unknown storage type: " + _storageType + " storage type is unknown");
    }

    return ret ? ret : [_appDefaults objectForKey:aKey];
}

/*! saves the given object associated with the given key into the
    choosen storage engine

    @param anObject the object to store
    @param aKey the key associated to the object
*/
- (void)synchronizeObject:(id)anObject forKey:(CPString)aKey
{
    var datas       = [CPKeyedArchiver archivedDataWithRootObject:anObject],
        identifier  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"] + @"_" +_user + @"_"+ aKey;
        string      = [datas rawString];

    switch (_storageType)
    {
        case TNUserDefaultStorageTypeHTML5:
            try
            {
                localStorage.setItem(identifier, string);
            }
            catch(e)
            {
                CPLog.error("Error while trying to synchronize : " + e);
            }
            break;

        case TNUserDefaultStorageTypeCookie:
            var cookie      = [[CPCookie alloc] initWithName:identifier],
                theString   = string.replace(/;/g, "__dotcoma__").replace(/$/g, "__dollar__");
            CPLog.trace(@"saving into cookie storage");
            [cookie setValue:theString expires:[CPDate distantFuture] domain:@""];
            break;

        case TNUserDefaultStorageTypeNoStorage:
            break;

        default:
            throw new Error("Unknown storage type: " + _storageType + " storage type is unknown");
    }
}

/*! remove an object associated to the given key from the choosen storage engine
    @param aKey the key associated to the object to remove
*/
- (void)removeObjectForKey:(CPString)aKey
{
    var identifier  = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"] + @"_" +_user + @"_"+ aKey;

    switch (_storageType)
    {
        case TNUserDefaultStorageTypeHTML5:
            CPLog.trace(@"clearing HTML5 storage for key " + aKey);
            localStorage.removeItem(identifier);
            break;

        case TNUserDefaultStorageTypeCookie:
            CPLog.trace(@"clearing cookie storage for key " + aKey);
            var cookie  = [[CPCookie alloc] initWithName:identifier];
            [cookie setValue:@"" expires:[CPDate distantFuture] domain:@""];

        case TNUserDefaultStorageTypeNoStorage:
            break;

        default:
            throw new Error("Unknown storage type: " + _storageType + " storage type is unknown");
    }
}

/*! clears the content of the localStorage.
*/
- (void)clear
{
    switch (_storageType)
    {
        case TNUserDefaultStorageTypeHTML5:
            CPLog.trace(@"clearing HTML5 storage");
            localStorage.clear();
            break;

        case TNUserDefaultStorageTypeCookie || TNUserDefaultStorageTypeNoStorage:
            CPLog.warn(@"Can't clear cookie storage or no storage");
            break;

        default:
            throw new Error("Unknown storage type: " + _storageType + " storage type is unknown");
    }
}

@end


#pragma mark -
#pragma mark TNUserDefaults CocoaInterface

@implementation TNUserDefaults (CocoaInterface)

#pragma mark -
#pragma mark Getters

/*! recover from storage the the value of object stored for given key.

    @param aKey the key
    @return the object associated to the key
*/
- (id)objectForKey:(CPString)aKey
{
    return [self recoverObjectForKey:aKey];
}

/*! recover from storage the the value of array stored for given key.

    @param aKey the key
    @return the array associated to the key
*/
- (CPArray)arrayForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}


/*! recover from storage the the value of boolean stored for given key.

    @param aKey the key
    @return the boolean associated to the key
*/
- (BOOL)boolForKey:(CPString)aKey
{
    var value = [self objectForKey:aKey];

    if (value === nil)
        return nil;

    return (value === @"YES") || (value === 1) || (value === YES) ? YES : NO;
}

/*! recover from storage the the value of data stored for given key.

    @param aKey the key
    @return the data associated to the key
*/
- (CPData)dataForKey:(CPString)aKey
{
   return [self objectForKey:aKey];
}

/*! recover from storage the the value of dictionary stored for given key.

    @param aKey the key
    @return the dictionary associated to the key
*/
- (CPDictionary)dictionaryForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

/*! recover from storage the the value of float stored for given key.

    @param aKey the key
    @return the float associated to the key
*/
- (CPNumber)floatForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

/*! recover from storage the the value of integer stored for given key.

    @param aKey the key
    @return the integer associated to the key
*/
- (CPNumber)integerForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

/*! recover from storage the the value of string array stored for given key.

    @param aKey the key
    @return the string array associated to the key
*/
- (CPArray)stringArrayForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

/*! recover from storage the the value of string stored for given key.

    @param aKey the key
    @return the string associated to the key
*/
- (CPString)stringForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

/*! recover from storage the the value of double stored for given key.

    @param aKey the key
    @return the double associated to the key
*/
- (CPNumber)doubleForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}

/*! recover from storage the the value of URL stored for given key.

    @param aKey the key
    @return the URL associated to the key
*/
- (CPURL)URLForKey:(CPString)aKey
{
    return [self objectForKey:aKey];
}


#pragma mark -
#pragma mark Setters


/*! saves the given object associated with the given key into the
    choosen storage engine

    @param aValue the object to store
    @param aKey the key associated to the object
*/
- (void)setObject:(id)aValue forKey:(CPString)aKey
{
    //CPLog.trace("Setting default " + aKey + " = " + aValue);

    var currentDefault = [_defaults objectForKey:_user],
        datas       = [CPKeyedArchiver archivedDataWithRootObject:aValue],
        identifier  = ([[CPBundle mainBundle] objectForInfoDictionaryKey:@"CPBundleIdentifier"] + "_" + aKey),
        string      = [datas rawString];

    [currentDefault setObject:aValue forKey:aKey];
    [self synchronizeObject:aValue forKey:aKey];
}

/*! saves the given bool associated with the given key into the
    choosen storage engine

    @param aValue the bool to store
    @param aKey the key associated to the object
*/
- (void)setBool:(BOOL)aValue forKey:(CPString)aKey
{
    var value = (aValue) ? @"YES" : @"NO";

    [self setObject:value forKey:aKey];
}

/*! saves the given float associated with the given key into the
    choosen storage engine

    @param aValue the float to store
    @param aKey the key associated to the object
*/
- (void)setFloat:(CPNumber)aValue forKey:(CPString)aKey
{
    [self setObject:aValue forKey:aKey];
}

/*! saves the given integer associated with the given key into the
    choosen storage engine

    @param aValue the integer to store
    @param aKey the key associated to the object
*/
- (void)setInteger:(CPNumber)aValue forKey:(CPString)aKey
{
    [self setObject:aValue forKey:aKey];
}

/*! saves the given double associated with the given key into the
    choosen storage engine

    @param aValue the double to store
    @param aKey the key associated to the object
*/
- (void)setDouble:(CPNumber)aValue forKey:(CPString)aKey
{
    [self setObject:aValue forKey:aKey];
}

/*! saves the given URL associated with the given key into the
    choosen storage engine

    @param aValue the URL to store
    @param aKey the key associated to the object
*/
- (void)setURL:(CPURL)aValue forKey:(CPString)aKey
{
    [self setObject:aValue forKey:aKey];
}

@end


#pragma mark -
#pragma mark TNUserDefaults CodingCompliant

@implementation TNUserDefaults (CPCodingCompliant)

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
