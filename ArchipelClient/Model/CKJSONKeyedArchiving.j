/*
 * Copyright (c) 2010 Chandler Kent
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

var CKJSONKeyedArchiverClassKey = @"$$CLASS$$",
    CKJSONKeyedUnarchiverClassKey = @"$$CLASS$$";

@implementation CKJSONKeyedArchiver : CPCoder
{
    JSON    _json;
}

+ (JSON)archivedDataWithRootObject:(id)rootObject
{
    var json = {},
        archiver = [[self alloc] initForWritingWithMutableData:json];

    return JSON.stringify([archiver _encodeObject:rootObject]);
}

+ (BOOL)allowsKeyedCoding
{
    return YES;
}

- (id)initForWritingWithMutableData:(JSON)json
{
    if (self = [super init])
        _json = json;
    return self;
}

- (void)encodeObject:(id)objectToEncode forKey:(CPString)aKey
{
    _json[aKey] = [self _encodeObject:objectToEncode];
}

- (JSON)_encodeObject:(id)objectToEncode
{
    var encodedJSON = {};

    if ([self _isObjectAPrimitive:objectToEncode])  // Primitives
        encodedJSON = objectToEncode;
    else if ([objectToEncode isKindOfClass:[CPArray class]]) // Override CPArray's default encoding because we want native JS Objects
    {
        var encodedArray = [];
        for (var i = 0; i < [objectToEncode count]; i++)
            encodedArray[i] = [self _encodeObject:[objectToEncode objectAtIndex:i]];
        encodedJSON = encodedArray;
    }
    else // Capp. objects
    {
        var archiver = [[[self class] alloc] initForWritingWithMutableData:encodedJSON];

        encodedJSON[CKJSONKeyedArchiverClassKey] = CPStringFromClass([objectToEncode class]);
        [objectToEncode encodeWithCoder:archiver];
    }

    return encodedJSON;
}

- (void)encodeNumber:(int)aNumber forKey:(CPString)aKey
{
    [self encodeObject:aNumber forKey:aKey];
}

- (void)encodeInt:(int)anInt forKey:(CPString)aKey
{
    [self encodeObject:anInt forKey:aKey];
}

- (JSON)_encodeDictionaryOfObjects:(CPDictionary)dictionaryToEncode forKey:(CPString)aKey
{
    var encodedDictionary = {},
        keys = [dictionaryToEncode allKeys];

    for (var i = 0; i < [keys count]; i++)
        encodedDictionary[keys[i]] = [self _encodeObject:[dictionaryToEncode objectForKey:keys[i]]];

    _json[aKey] = encodedDictionary;
}

- (BOOL)_isObjectAPrimitive:(id)anObject
{
    var typeOfObject = typeof(anObject);
    return (typeOfObject === "string" || typeOfObject === "number" || typeOfObject === "boolean" || anObject === null);
}

@end

@implementation CKJSONKeyedUnarchiver : CPCoder
{
    JSON    _json;
}

+ (id)unarchiveObjectWithData:(JSON)json
{
    var data = JSON.parse(json),
        unarchiver = [[self alloc] initForReadingWithData:data];
    return [unarchiver _decodeObject:data];
}

- (id)initForReadingWithData:(JSON)json
{
    if (self = [super init])
        _json = json;
    return self;
}

- (id)decodeObjectForKey:(CPString)aKey
{
    return [self _decodeObject:_json[aKey]];
}

- (int)decodeIntForKey:(CPString)aKey
{
    return [self _decodeObject:_json[aKey]];
}

- (id)_decodeObject:(JSON)encodedJSON
{
    var decodedObject = nil;

    if ([self _isJSONAPrimitive:encodedJSON]) // Primitives
        decodedObject = encodedJSON;
    else if (encodedJSON.constructor.toString().indexOf("Array") !== -1) // Handle arrays separately of its own decoding
    {
        var array = encodedJSON;
        for (var i = 0; i < [array count]; i++)
        {
           array[i] = [self _decodeObject:[array objectAtIndex:i]];
        }

        decodedObject = array;
    }
    else // Capp. objects
    {
        var unarchiver = [[[self class] alloc] initForReadingWithData:encodedJSON],
            theClass = CPClassFromString(encodedJSON[CKJSONKeyedUnarchiverClassKey]);
        decodedObject = [[theClass alloc] initWithCoder:unarchiver];
    }

    return decodedObject;
}

- (id)_decodeDictionaryOfObjectsForKey:(CPString)aKey
{
    var decodedDictionary = [CPDictionary dictionary],
        encodedJSON = _json[aKey];

    for (var key in encodedJSON)
        if (key !== CKJSONKeyedUnarchiverClassKey)
            [decodedDictionary setObject:[self _decodeObject:encodedJSON[key]] forKey:key];

    return decodedDictionary;
}

- (BOOL)_isJSONAPrimitive:(JSON)json
{
    var typeOfObject = typeof(json);
    return (typeOfObject === "string" || typeOfObject === "number" || typeOfObject === "boolean" || json === null);
}

@end
