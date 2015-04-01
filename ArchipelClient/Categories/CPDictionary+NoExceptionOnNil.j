/*
 * CPDictionary+NoExceptionOnNil.j
 *
 * Copyright (C) 2015 Cyril Peponnet <cyril@peponnet.fr>
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

@import <Foundation/CPDictionary.j>


/*! @ingroup categories
    Make CPDictionary less stric about nil key and values
*/

var CPDictionaryShowNilDeprecationMessage = YES;

@implementation CPDictionary (removeUglyChange)

- (id)initWithObjects:(CPArray)objects forKeys:(CPArray)keyArray
{
    self = [super init];

    if ([objects count] != [keyArray count])
        [CPException raise:CPInvalidArgumentException reason:[CPString stringWithFormat:@"Counts are different.(%d != %d)", [objects count], [keyArray count]]];

    if (self)
    {
        var i = [keyArray count];

        while (i--)
        {
            var value = objects[i],
                key = keyArray[i];

            if (value === nil)
            {
                CPDictionaryShowNilDeprecationMessage = NO;
                CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: Attempt to insert nil object from objects[%d]", [self className], _cmd, i]);

                // FIXME: After release of 0.9.7 change this block to:
                // [CPException raise:CPInvalidArgumentException reason:@"Attempt to insert nil object from objects[" + i + @"]"];
            }

            if (key === nil)
            {
                CPDictionaryShowNilDeprecationMessage = NO;
                CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: Attempt to insert nil key from keys[%d]", [self className], _cmd, i]);

                // FIXME: After release of 0.9.7 change this block to:
                // [CPException raise:CPInvalidArgumentException reason:@"Attempt to insert nil key from keys[" + i + @"]"];
            }

            [self setObject:value forKey:key];
        }
    }

    return self;
}

- (id)initWithObjectsAndKeys:(id)firstObject, ...
{
    var argCount = arguments.length;

    if (argCount % 2 !== 0)
        [CPException raise:CPInvalidArgumentException reason:"Key-value count is mismatched. (" + argCount + " arguments passed)"];

    self = [super init];

    if (self)
    {
        // The arguments array contains self and _cmd, so the first object is at position 2.
        var index = 2;

        for (; index < argCount; index += 2)
        {
            var value = arguments[index],
                key = arguments[index + 1];

            if (value === nil)
            {
                CPDictionaryShowNilDeprecationMessage = NO;
                CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: Attempt to insert nil object from objects[%d]", [self className], _cmd, (index / 2) - 1]);

                // FIXME: After release of 0.9.7 change 3 lines above to this:
                // [CPException raise:CPInvalidArgumentException reason:@"Attempt to insert nil object from objects[" + ((index / 2) - 1) + @"]"];
            }

            if (key === nil)
            {
                CPDictionaryShowNilDeprecationMessage = NO;
                CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: Attempt to insert nil key from keys[%d]", [self className], _cmd, (index / 2) - 1]);

                // FIXME: After release of 0.9.7 change 3 lines above to this:
                // [CPException raise:CPInvalidArgumentException reason:@"Attempt to insert nil key from keys[" + ((index / 2) - 1) + @"]"];
            }

            [self setObject:value forKey:key];
        }
    }

    return self;
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    // FIXME: After release of 0.9.7, remove this test and leave the contents of its block
    if (CPDictionaryShowNilDeprecationMessage)
    {
        if (aKey === nil)
        {
            CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: key cannot be nil", [self className], _cmd]);

            // FIXME: After release of 0.9.7 change this block to:
            // [CPException raise:CPInvalidArgumentException reason:@"key cannot be nil"];
        }

        if (anObject === nil)
        {
            CPLog.warn([CPString stringWithFormat:@"[%s %s] DEPRECATED: object cannot be nil (key: %s)", [self className], _cmd, aKey]);

            // FIXME: After release of 0.9.7 change this block to:
            // [CPException raise:CPInvalidArgumentException reason:@"object cannot be nil (key: " + aKey + @")"];
        }
    }
    // FIXME: After release of 0.9.7 remove 2 lines below.
    else
        CPDictionaryShowNilDeprecationMessage = YES;

    self.setValueForKey(aKey, anObject);
}



@end
