/*
 * Objective-J.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008-2010, 280 North, Inc.
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



var CachedRegexData = [];

function regexDataFromRegex(aRegex)
{
    var source = "",
        flags = "";

    if (typeof aRegex == "string")
    {
        if (CachedRegexData[aRegex])
            return CachedRegexData[aRegex];

        string = aRegex;
        source = aRegex;
    }
    else
    {
        string = aRegex.toString();

        if (CachedRegexData[string])
            return CachedRegexData[string];

        var index = string.lastIndexOf('/');

        source = string.substr(0, index);
        flags = string.substr(index + 1);
    }

    source = source.replace("\\[\\^\\\\\\d\\]", ".", "g");
    source = source.replace("\\[([^\\]]*)\\\\b([^\\]]*)\\]", "[$1\\\\cH$2]", "g")
    source = source.replace("(?<!\\\\)\\{(?!\\d)", "\\\\{", "g");
    source = source.replace("(?<!(\\d,?|\\\\))\\}", "\\\\}", "g");

    return CachedRegexData[string] = { pattern:java.util.regex.Pattern.compile(source, 0), flags:flags };
}

function newMatch(regex)
{
    var regexData = regexDataFromRegex(regex);

    var matcher = regexData.pattern.matcher(new java.lang.String(this)),
        flags = regexData.flags;

    if (!matcher.find())
        return [];

    var index = matcher.start(0),
        groups = [];

    if (flags.indexOf('g') != -1)
    {
        do
        {
            groups.push(matcher.group(0) + "");
        }
        while (matcher.find());
    }
    else
    {
        for (index = 0; index <= matcher.groupCount(); ++index)
        {
            var group = matcher.group(index);

            if (group != null)
                groups[index] = group;
        }
    }

    return groups;
}

if (system.platform === "rhino")
    String.prototype.match = newMatch;
