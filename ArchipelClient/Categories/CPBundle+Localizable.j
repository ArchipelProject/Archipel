/*
 * CPBundle.sj
 * AppKit
 *
 * Created by Nicholas Small.
 * Copyright 2009, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <AppKit/CPApplication.j>


var StringTables;

function CPLocalizedString(key, comment)
{
    return CPLocalizedStringFromTable(key, nil, comment);
}

function CPLocalizedStringFromTable(key, table, comment)
{
    return CPLocalizedStringFromTableInBundle(key, table, [CPBundle mainBundle], comment);
}

function CPLocalizedStringFromTableInBundle(key, table, bundle, comment)
{
    return [bundle localizedStringForKey:key value:comment table:table];
}


@implementation CPBundle (CPLocale)

- (CPString)bundleLocale
{
    return [[CPUserDefaults standardUserDefaults] objectForKey:@"CPBundleLocale"] || [self objectForInfoDictionaryKey:@"CPBundleLocale"];
}

- (CPString)localizedStringForKey:(CPString)aKey value:(CPString)aValue table:(CPString)aTable
{
    if (!StringTables)
        StringTables = [CPDictionary dictionary];

    if (!aTable)
        aTable = "Localizable";

    var table = [StringTables objectForKey:aTable];

    if (!table)
    {
        table = [CPDictionary dictionary];
        [StringTables setObject:table forKey:aTable];
    }

    var string = [table objectForKey:aKey];

    if (!string)
    {
        string = aValue;
        [table setObject:string forKey:aKey];
    }

    return string;
}

- (void)setDictionary:(CPDictionary)aDictionary forTable:(CPString)aTable
{
    if (!StringTables)
        StringTables = [CPDictionary dictionary];

    [StringTables setObject:aDictionary forKey:aTable];
}

- (CPCib)loadCibFile:(CPString)aFileName externalNameTable:(CPDictionary)aNameTable loadDelegate:(id)aDelegate
{
    var localizedCibFile = [self bundleLocale] + @".lproj/" + aFileName;

    return ([[CPCib alloc] initWithCibNamed:localizedCibFile bundle:self loadDelegate:[[_CPCibLoadDelegate alloc] initWithLoadDelegate:aDelegate externalNameTable:aNameTable]]);
}


@end

window.LocaleCPApplicationMain = CPApplicationMain;
CPApplicationMain = function(args, namedArgs)
{
    var mainBundle = [CPBundle mainBundle],
        bundleLocale = [mainBundle bundleLocale];

    if (bundleLocale)
    {
        var request = [CPURLRequest requestWithURL:@"Resources/" + bundleLocale + ".lproj/Localizable.xstrings"],
            response = [CPURLConnection sendSynchronousRequest:request returningResponse:response];

        var plist = [CPPropertyListSerialization propertyListFromData:response format:nil];
        [mainBundle setDictionary:plist forTable:@"Localizable"];
    }

    window.LocaleCPApplicationMain(args, namedArgs);
}
