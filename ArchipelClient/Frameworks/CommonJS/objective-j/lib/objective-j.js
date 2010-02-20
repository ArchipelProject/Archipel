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




var FILE = require("file");
var window = exports.window = require("browser/window");

if (system.engine === "rhino")
{
    window.__parent__ = null;
    window.__proto__ = global;
}


window.OBJJ_HOME = exports.OBJJ_HOME = FILE.resolve(module.path, "..");

var frameworksPath = FILE.resolve(window.OBJJ_HOME, "Frameworks/");

var OBJJ_INCLUDE_PATHS = global.OBJJ_INCLUDE_PATHS = exports.OBJJ_INCLUDE_PATHS = [frameworksPath];
if (!this.JSON) {
    JSON = {};
}
(function () {
    function f(n) {
        return n < 10 ? '0' + n : n;
    }
    if (typeof Date.prototype.toJSON !== 'function') {
        Date.prototype.toJSON = function (key) {
            return this.getUTCFullYear() + '-' +
                 f(this.getUTCMonth() + 1) + '-' +
                 f(this.getUTCDate()) + 'T' +
                 f(this.getUTCHours()) + ':' +
                 f(this.getUTCMinutes()) + ':' +
                 f(this.getUTCSeconds()) + 'Z';
        };
        String.prototype.toJSON =
        Number.prototype.toJSON =
        Boolean.prototype.toJSON = function (key) {
            return this.valueOf();
        };
    }
    var cx = new RegExp('/[\\u0000\\u00ad\\u0600-\\u0604\\u070f\\u17b4\\u17b5\\u200c-\\u200f\\u2028-\\u202f\\u2060-\\u206f\\ufeff\\ufff0-\\uffff]/g');
    var escapable = new RegExp('/[\\\\\\"\\x00-\\x1f\\x7f-\\x9f\\u00ad\\u0600-\\u0604\\u070f\\u17b4\\u17b5\\u200c-\\u200f\\u2028-\\u202f\\u2060-\\u206f\\ufeff\\ufff0-\\uffff]/g');
    var gap,
        indent,
        meta = {
            '\b': '\\b',
            '\t': '\\t',
            '\n': '\\n',
            '\f': '\\f',
            '\r': '\\r',
            '"' : '\\"',
            '\\': '\\\\'
        },
        rep;
    function quote(string) {
        escapable.lastIndex = 0;
        return escapable.test(string) ?
            '"' + string.replace(escapable, function (a) {
                var c = meta[a];
                return typeof c === 'string' ? c :
                    '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
            }) + '"' :
            '"' + string + '"';
    }
    function str(key, holder) {
        var i,
            k,
            v,
            length,
            mind = gap,
            partial,
            value = holder[key];
        if (value && typeof value === 'object' &&
                typeof value.toJSON === 'function') {
            value = value.toJSON(key);
        }
        if (typeof rep === 'function') {
            value = rep.call(holder, key, value);
        }
        switch (typeof value) {
        case 'string':
            return quote(value);
        case 'number':
            return isFinite(value) ? String(value) : 'null';
        case 'boolean':
        case 'null':
            return String(value);
        case 'object':
            if (!value) {
                return 'null';
            }
            gap += indent;
            partial = [];
            if (Object.prototype.toString.apply(value) === '[object Array]') {
                length = value.length;
                for (i = 0; i < length; i += 1) {
                    partial[i] = str(i, value) || 'null';
                }
                v = partial.length === 0 ? '[]' :
                    gap ? '[\n' + gap +
                            partial.join(',\n' + gap) + '\n' +
                                mind + ']' :
                          '[' + partial.join(',') + ']';
                gap = mind;
                return v;
            }
            if (rep && typeof rep === 'object') {
                length = rep.length;
                for (i = 0; i < length; i += 1) {
                    k = rep[i];
                    if (typeof k === 'string') {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            } else {
                for (k in value) {
                    if (Object.hasOwnProperty.call(value, k)) {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            }
            v = partial.length === 0 ? '{}' :
                gap ? '{\n' + gap + partial.join(',\n' + gap) + '\n' +
                        mind + '}' : '{' + partial.join(',') + '}';
            gap = mind;
            return v;
        }
    }
    if (typeof JSON.stringify !== 'function') {
        JSON.stringify = function (value, replacer, space) {
            var i;
            gap = '';
            indent = '';
            if (typeof space === 'number') {
                for (i = 0; i < space; i += 1) {
                    indent += ' ';
                }
            } else if (typeof space === 'string') {
                indent = space;
            }
            rep = replacer;
            if (replacer && typeof replacer !== 'function' &&
                    (typeof replacer !== 'object' ||
                     typeof replacer.length !== 'number')) {
                throw new Error('JSON.stringify');
            }
            return str('', {'': value});
        };
    }
    if (typeof JSON.parse !== 'function') {
        JSON.parse = function (text, reviver) {
            var j;
            function walk(holder, key) {
                var k, v, value = holder[key];
                if (value && typeof value === 'object') {
                    for (k in value) {
                        if (Object.hasOwnProperty.call(value, k)) {
                            v = walk(value, k);
                            if (v !== undefined) {
                                value[k] = v;
                            } else {
                                delete value[k];
                            }
                        }
                    }
                }
                return reviver.call(holder, key, value);
            }
            cx.lastIndex = 0;
            if (cx.test(text)) {
                text = text.replace(cx, function (a) {
                    return '\\u' +
                        ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
                });
            }
            if (/^[\],:{}\s]*$/.
test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@').
replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').
replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {
                j = eval('(' + text + ')');
                return typeof reviver === 'function' ?
                    walk({'': j}, '') : j;
            }
            throw new SyntaxError('JSON.parse');
        };
    }
}());
var formatRegex = new RegExp("([^%]+|%[\\+\\-\\ \\#0]*[0-9\\*]*(.[0-9\\*]+)?[hlL]?[cbBdieEfgGosuxXpn%@])", "g");
var tagRegex = new RegExp("(%)([\\+\\-\\ \\#0]*)([0-9\\*]*)((.[0-9\\*]+)?)([hlL]?)([cbBdieEfgGosuxXpn%@])");
sprintf = function(format)
{
    var format = arguments[0],
        tokens = format.match(formatRegex),
        index = 0,
        result = "",
        arg = 1;
    for (var i = 0; i < tokens.length; i++)
    {
        var t = tokens[i];
        if (format.substring(index, index + t.length) != t)
        {
            return result;
        }
        index += t.length;
        if (t.charAt(0) != "%")
        {
            result += t;
        }
        else
        {
            var subtokens = t.match(tagRegex);
            if (subtokens.length != 8 || subtokens[0] != t)
            {
                return result;
            }
            var percentSign = subtokens[1],
                flags = subtokens[2],
                widthString = subtokens[3],
                precisionString = subtokens[4],
                length = subtokens[6],
                specifier = subtokens[7];
            var width = null;
            if (widthString == "*")
                width = arguments[arg++];
            else if (widthString != "")
                width = Number(widthString);
            var precision = null;
            if (precisionString == ".*")
                precision = arguments[arg++];
            else if (precisionString != "")
                precision = Number(precisionString.substring(1));
            var leftJustify = (flags.indexOf("-") >= 0);
            var padZeros = (flags.indexOf("0") >= 0);
            var subresult = "";
            if (RegExp("[bBdiufeExXo]").test(specifier))
            {
                var num = Number(arguments[arg++]);
                var sign = "";
                if (num < 0)
                {
                    sign = "-";
                }
                else
                {
                    if (flags.indexOf("+") >= 0)
                        sign = "+";
                    else if (flags.indexOf(" ") >= 0)
                        sign = " ";
                }
                if (specifier == "d" || specifier == "i" || specifier == "u")
                {
                    var number = String(Math.abs(Math.floor(num)));
                    subresult = justify(sign, "", number, "", width, leftJustify, padZeros)
                }
                if (specifier == "f")
                {
                    var number = String((precision != null) ? Math.abs(num).toFixed(precision) : Math.abs(num));
                    var suffix = (flags.indexOf("#") >= 0 && number.indexOf(".") < 0) ? "." : "";
                    subresult = justify(sign, "", number, suffix, width, leftJustify, padZeros);
                }
                if (specifier == "e" || specifier == "E")
                {
                    var number = String(Math.abs(num).toExponential(precision != null ? precision : 21));
                    var suffix = (flags.indexOf("#") >= 0 && number.indexOf(".") < 0) ? "." : "";
                    subresult = justify(sign, "", number, suffix, width, leftJustify, padZeros);
                }
                if (specifier == "x" || specifier == "X")
                {
                    var number = String(Math.abs(num).toString(16));
                    var prefix = (flags.indexOf("#") >= 0 && num != 0) ? "0x" : "";
                    subresult = justify(sign, prefix, number, "", width, leftJustify, padZeros);
                }
                if (specifier == "b" || specifier == "B")
                {
                    var number = String(Math.abs(num).toString(2));
                    var prefix = (flags.indexOf("#") >= 0 && num != 0) ? "0b" : "";
                    subresult = justify(sign, prefix, number, "", width, leftJustify, padZeros);
                }
                if (specifier == "o")
                {
                    var number = String(Math.abs(num).toString(8));
                    var prefix = (flags.indexOf("#") >= 0 && num != 0) ? "0" : "";
                    subresult = justify(sign, prefix, number, "", width, leftJustify, padZeros);
                }
                if (RegExp("[A-Z]").test(specifier))
                    subresult = subresult.toUpperCase();
                else
                    subresult = subresult.toLowerCase();
            }
            else
            {
                var subresult = "";
                if (specifier == "%")
                    subresult = "%";
                else if (specifier == "c")
                    subresult = String(arguments[arg++]).charAt(0);
                else if (specifier == "s" || specifier == "@")
                    subresult = String(arguments[arg++]);
                else if (specifier == "p" || specifier == "n")
                {
                    arg++;
                    subresult = "";
                }
                subresult = justify("", "", subresult, "", width, leftJustify, false);
            }
            result += subresult;
        }
    }
    return result;
}
function justify(sign, prefix, string, suffix, width, leftJustify, padZeros)
{
    var length = (sign.length + prefix.length + string.length + suffix.length);
    if (leftJustify)
    {
        return sign + prefix + string + suffix + pad(width - length, " ");
    }
    else
    {
        if (padZeros)
            return sign + prefix + pad(width - length, "0") + string + suffix;
        else
            return pad(width - length, " ") + sign + prefix + string + suffix;
    }
}
function pad(n, ch)
{
    return Array(MAX(0,n)+1).join(ch);
}
CPLogDisable = false;
var CPLogDefaultTitle = "Cappuccino";
var CPLogLevels = ["fatal", "error", "warn", "info", "debug", "trace"];
var CPLogDefaultLevel = CPLogLevels[3];
var _CPLogLevelsInverted = {};
for (var i = 0; i < CPLogLevels.length; i++)
    _CPLogLevelsInverted[CPLogLevels[i]] = i;
var _CPLogRegistrations = {};
CPLogRegister = function(aProvider, aMaxLevel)
{
    CPLogRegisterRange(aProvider, CPLogLevels[0], aMaxLevel || CPLogLevels[CPLogLevels.length-1]);
}
CPLogRegisterRange = function(aProvider, aMinLevel, aMaxLevel)
{
    var min = _CPLogLevelsInverted[aMinLevel];
    var max = _CPLogLevelsInverted[aMaxLevel];
    if (min !== undefined && max !== undefined)
        for (var i = 0; i <= max; i++)
            CPLogRegisterSingle(aProvider, CPLogLevels[i]);
}
CPLogRegisterSingle = function(aProvider, aLevel)
{
    if (!_CPLogRegistrations[aLevel])
        _CPLogRegistrations[aLevel] = [];
    for (var i = 0; i < _CPLogRegistrations[aLevel].length; i++)
        if (_CPLogRegistrations[aLevel][i] === aProvider)
            return;
    _CPLogRegistrations[aLevel].push(aProvider);
}
CPLogUnregister = function(aProvider) {
    for (var aLevel in _CPLogRegistrations)
        for (var i = 0; i < _CPLogRegistrations[aLevel].length; i++)
            if (_CPLogRegistrations[aLevel][i] === aProvider)
                _CPLogRegistrations[aLevel].splice(i--, 1);
}
function _CPLogDispatch(parameters, aLevel, aTitle)
{
    if (aTitle == undefined)
        aTitle = CPLogDefaultTitle;
    if (aLevel == undefined)
        aLevel = CPLogDefaultLevel;
    var message = (typeof parameters[0] == "string" && parameters.length > 1) ? sprintf.apply(null, parameters) : String(parameters[0]);
    if (_CPLogRegistrations[aLevel])
        for (var i = 0; i < _CPLogRegistrations[aLevel].length; i++)
             _CPLogRegistrations[aLevel][i](message, aLevel, aTitle);
}
CPLog = function() { _CPLogDispatch(arguments); }
for (var i = 0; i < CPLogLevels.length; i++)
    CPLog[CPLogLevels[i]] = (function(level) { return function() { _CPLogDispatch(arguments, level); }; })(CPLogLevels[i]);
var _CPFormatLogMessage = function(aString, aLevel, aTitle)
{
    var now = new Date();
    aLevel = ( aLevel == null ? '' : ' [' + aLevel + ']' );
    if (typeof sprintf == "function")
        return sprintf("%4d-%02d-%02d %02d:%02d:%02d.%03d %s%s: %s",
            now.getFullYear(), now.getMonth(), now.getDate(),
            now.getHours(), now.getMinutes(), now.getSeconds(), now.getMilliseconds(),
            aTitle, aLevel, aString);
    else
        return now + " " + aTitle + aLevel + ": " + aString;
}
var ANSI_ESC = String.fromCharCode(0x1B);
var ANSI_CSI = ANSI_ESC + '[';
var ANSI_TEXT_PROP = 'm';
var ANSI_RESET = '0';
var ANSI_BOLD = '1';
var ANSI_FAINT = '2';
var ANSI_NORMAL = '22';
var ANSI_ITALIC = '3';
var ANSI_UNDER = '4';
var ANSI_UNDER_DBL = '21';
var ANSI_UNDER_OFF = '24';
var ANSI_BLINK = '5';
var ANSI_BLINK_FAST = '6';
var ANSI_BLINK_OFF = '25';
var ANSI_REVERSE = '7';
var ANSI_POSITIVE = '27';
var ANSI_CONCEAL = '8';
var ANSI_REVEAL = '28';
var ANSI_FG = '3';
var ANSI_BG = '4';
var ANSI_FG_INTENSE = '9';
var ANSI_BG_INTENSE = '10';
var ANSI_BLACK = '0';
var ANSI_RED = '1';
var ANSI_GREEN = '2';
var ANSI_YELLOW = '3';
var ANSI_BLUE = '4';
var ANSI_MAGENTA = '5';
var ANSI_CYAN = '6';
var ANSI_WHITE = '7';
var colorCodeMap = {
    "black" : ANSI_BLACK,
    "red" : ANSI_RED,
    "green" : ANSI_GREEN,
    "yellow" : ANSI_YELLOW,
    "blue" : ANSI_BLUE,
    "magenta" : ANSI_MAGENTA,
    "cyan" : ANSI_CYAN,
    "white" : ANSI_WHITE
}
function ANSIControlCode(code, parameters)
{
    if (parameters == undefined)
        parameters = "";
    else if (typeof(parameters) == 'object' && (parameters instanceof Array))
        parameters = parameters.join(';');
    return ANSI_CSI + String(parameters) + String(code);
}
function ANSITextApplyProperties(string, properties)
{
    return ANSIControlCode(ANSI_TEXT_PROP, properties) + String(string) + ANSIControlCode(ANSI_TEXT_PROP);
}
ANSITextColorize = function(string, color)
{
    if (colorCodeMap[color] == undefined)
        return string;
    return ANSITextApplyProperties(string, ANSI_FG + colorCodeMap[color]);
}
var levelColorMap = {
    "fatal": "red",
    "error": "red",
    "warn" : "yellow",
    "info" : "green",
    "debug": "cyan",
    "trace": "blue"
}
CPLogConsole = function(aString, aLevel, aTitle)
{
    if (typeof console != "undefined")
    {
        var message = _CPFormatLogMessage(aString, aLevel, aTitle);
        var logger = {
            "fatal": "error",
            "error": "error",
            "warn": "warn",
            "info": "info",
            "debug": "debug",
            "trace": "debug"
        }[aLevel];
        if (logger && console[logger])
            console[logger](message);
        else if (console.log)
            console.log(message);
    }
}
CPLogPrint = function(aString, aLevel, aTitle)
{
    if (typeof print != "undefined")
    {
        if (aLevel == "fatal" || aLevel == "error" || aLevel == "warn")
            var message = ANSITextColorize(_CPFormatLogMessage(aString, aLevel, aTitle), levelColorMap[aLevel]);
        else
            var message = _CPFormatLogMessage(aString, ANSITextColorize(aLevel, levelColorMap[aLevel]), aTitle);
        require("system").stderr.print(message);
    }
}
var undefined;
if (typeof window !== "undefined")
{
    window.setNativeTimeout = window.setTimeout;
    window.clearNativeTimeout = window.clearTimeout;
    window.setNativeInterval = window.setInterval;
    window.clearNativeInterval = window.clearNativeInterval;
}
NO = false;
YES = true;
nil = null;
Nil = null;
NULL = null;
ABS = Math.abs;
ASIN = Math.asin;
ACOS = Math.acos;
ATAN = Math.atan;
ATAN2 = Math.atan2;
SIN = Math.sin;
COS = Math.cos;
TAN = Math.tan;
EXP = Math.exp;
POW = Math.pow;
CEIL = Math.ceil;
FLOOR = Math.floor;
ROUND = Math.round;
MIN = Math.min;
MAX = Math.max;
RAND = Math.random;
SQRT = Math.sqrt;
E = Math.E;
LN2 = Math.LN2;
LN10 = Math.LN10;
LOG2E = Math.LOG2E;
LOG10E = Math.LOG10E;
PI = Math.PI;
PI2 = Math.PI * 2.0;
PI_2 = Math.PI / 2.0;
SQRT1_2 = Math.SQRT1_2;
SQRT2 = Math.SQRT2;
function Event( aType)
{
    this.type = aType;
}
function EventDispatcher( anOwner)
{
    this._eventListenersForEventNames = { };
    this._owner = anOwner;
}
EventDispatcher.prototype.addEventListener = function( anEventName, anEventListener)
{
    var eventListenersForEventNames = this._eventListenersForEventNames;
    if (!hasOwnProperty.call(this._eventListenersForEventNames, anEventName))
    {
        var eventListenersForEventName = [];
        eventListenersForEventNames[anEventName] = eventListenersForEventName;
    }
    else
        var eventListenersForEventName = eventListenersForEventNames[anEventName];
    var index = eventListenersForEventName.length;
    while (index--)
        if (eventListenersForEventName[index] === anEventListener)
            return;
    eventListenersForEventName.push(anEventListener);
}
EventDispatcher.prototype.removeEventListener = function( anEventName, anEventListener)
{
    var eventListenersForEventNames = this._eventListenersForEventNames;
    if (!hasOwnProperty.call(eventListenersForEventNames, anEventName))
        return;
    var eventListenersForEventName = eventListenersForEventNames[anEventName].
        index = eventListenersForEventName.length;
    while (index--)
        if (eventListenersForEventName[index] === anEventListener)
            return eventListenersForEventName.splice(index, 1);
}
EventDispatcher.prototype.dispatchEvent = function( anEvent)
{
    var type = anEvent.type,
        eventListenersForEventNames = this._eventListenersForEventNames;
    if (hasOwnProperty.call(eventListenersForEventNames, type))
    {
        var eventListenersForEventName = this._eventListenersForEventNames[type],
            index = 0,
            count = eventListenersForEventName.length;
        for (; index < count; ++index)
            eventListenersForEventName[index](anEvent);
    }
    var manual = (this._owner || this)["on" + type];
    if (manual)
        manual(anEvent);
}
var asynchronousTimeoutCount = 0,
    asynchronousTimeoutId = null,
    asynchronousFunctionQueue = [];
function Asynchronous( aFunction)
{
    var currentAsynchronousTimeoutCount = asynchronousTimeoutCount;
    if (asynchronousTimeoutId === null)
    {
        window.setNativeTimeout(function()
        {
            var queue = asynchronousFunctionQueue,
                index = 0,
                count = asynchronousFunctionQueue.length;
            ++asynchronousTimeoutCount;
            asynchronousTimeoutId = null;
            asynchronousFunctionQueue = [];
            for (; index < count; ++index)
                queue[index]();
        }, 0);
    }
    return function()
    {
        var args = arguments;
        if (asynchronousTimeoutCount > currentAsynchronousTimeoutCount)
            aFunction.apply(this, args);
        else
            asynchronousFunctionQueue.push(function() { aFunction.apply(this, args) });
    };
}
var NativeRequest = null;
if (window.ActiveXObject !== undefined)
{
    var MSXML_XMLHTTP_OBJECTS = ["Msxml2.XMLHTTP.3.0", "Msxml2.XMLHTTP.6.0"],
        index = MSXML_XMLHTTP_OBJECTS.length;
    while (index--)
    {
        try
        {
            var MSXML_XMLHTTP = MSXML_XMLHTTP_OBJECTS[index];
            new ActiveXObject(MSXML_XMLHTTP);
            NativeRequest = function()
            {
                return new ActiveXObject(MSXML_XMLHTTP);
            }
            break;
        }
        catch (anException)
        {
        }
    }
}
if (!NativeRequest)
    NativeRequest = window.XMLHttpRequest;
CFHTTPRequest = function()
{
    this._eventDispatcher = new EventDispatcher(this);
    this._nativeRequest = new NativeRequest();
    var self = this;
    this._nativeRequest.onreadystatechange = function()
    {
        determineAndDispatchHTTPRequestEvents(self);
    }
}
CFHTTPRequest.UninitializedState = 0;
CFHTTPRequest.LoadingState = 1;
CFHTTPRequest.LoadedState = 2;
CFHTTPRequest.InteractiveState = 3;
CFHTTPRequest.CompleteState = 4;
CFHTTPRequest.prototype.status = function()
{
    try
    {
        return this._nativeRequest.status || 0;
    }
    catch (anException)
    {
        return 0;
    }
}
CFHTTPRequest.prototype.statusText = function()
{
    try
    {
        return this._nativeRequest.statusText || "";
    }
    catch (anException)
    {
        return "";
    }
}
CFHTTPRequest.prototype.readyState = function()
{
    return this._nativeRequest.readyState;
}
CFHTTPRequest.prototype.success = function()
{
    var status = this.status();
    if (status >= 200 && status < 300)
        return YES;
    return status === 0 && this.responseText() && this.responseText().length;
}
CFHTTPRequest.prototype.responseXML = function()
{
    var responseXML = this._nativeRequest.responseXML;
    if (responseXML && (NativeRequest === window.XMLHttpRequest))
        return responseXML;
    return parseXML(this.responseText());
}
CFHTTPRequest.prototype.responsePropertyList = function()
{
    var responseText = this.responseText();
    if (CFPropertyList.sniffedFormatOfString(responseText) === CFPropertyList.FormatXML_v1_0)
        return CFPropertyList.propertyListFromXML(this.responseXML());
    return CFPropertyList.propertyListFromString(responseText);
}
CFHTTPRequest.prototype.responseText = function()
{
    return this._nativeRequest.responseText;
}
CFHTTPRequest.prototype.setRequestHeader = function( aHeader, aValue)
{
    return this._nativeRequest.setRequestHeader(aHeader, aValue);
}
CFHTTPRequest.prototype.getResponseHeader = function( aHeader)
{
    return this._nativeRequest.getResponseHeader(aHeader);
}
CFHTTPRequest.prototype.getAllResponseHeaders = function()
{
    return this._nativeRequest.getAllResponseHeaders();
}
CFHTTPRequest.prototype.overrideMimeType = function( aMimeType)
{
    if ("overrideMimeType" in this._nativeRequest)
        return this._nativeRequest.overrideMimeType(aMimeType);
}
CFHTTPRequest.prototype.open = function( )
{
    return this._nativeRequest.open(arguments[0], arguments[1], arguments[2], arguments[3], arguments[4]);
}
CFHTTPRequest.prototype.send = function( aBody)
{
    try
    {
        return this._nativeRequest.send(aBody);
    }
    catch (anException)
    {
        this._eventDispatcher.dispatchEvent({ type:"failure", request:this });
    }
}
CFHTTPRequest.prototype.abort = function()
{
    return this._nativeRequest.abort();
}
CFHTTPRequest.prototype.addEventListener = function( anEventName, anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
}
CFHTTPRequest.prototype.removeEventListener = function( anEventName, anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
}
function determineAndDispatchHTTPRequestEvents( aRequest)
{
    var eventDispatcher = aRequest._eventDispatcher;
    eventDispatcher.dispatchEvent({ type:"readystatechange", request:aRequest});
    var nativeRequest = aRequest._nativeRequest,
        readyState = ["uninitialized", "loading", "loaded", "interactive", "complete"][aRequest.readyState()];
    eventDispatcher.dispatchEvent({ type:readyState, request:aRequest});
    if (readyState === "complete")
    {
        var status = "HTTP" + aRequest.status();
        eventDispatcher.dispatchEvent({ type:status, request:aRequest });
        var result = aRequest.success() ? "success" : "failure";
        eventDispatcher.dispatchEvent({ type:result, request:aRequest });
    }
}
function FileRequest( aFilePath, onsuccess, onfailure)
{
    if (!FILE.exists(aFilePath))
        return onfailure();
    this._responseText = FILE.read(aFilePath, { charset:"UTF-8" });
    onsuccess({ type:"success", request:this });
}
FileRequest.prototype.responseText = function()
{
    return this._responseText;
}
FileRequest.prototype.responseXML = function()
{
    return new DOMParser().parseFromString(anXMLString, "text/xml");
}
FileRequest.prototype.responsePropertyList = function()
{
    return CFPropertyList.propertyListFromString(this.responseText());
}
var OBJECT_COUNT = 0;
objj_generateObjectUID = function()
{
    return OBJECT_COUNT++;
}
CFPropertyList = function()
{
    this._UID = objj_generateObjectUID();
}
CFPropertyList.DTDRE = /^\s*(?:<\?\s*xml\s+version\s*=\s*\"1.0\"[^>]*\?>\s*)?(?:<\!DOCTYPE[^>]*>\s*)?/i
CFPropertyList.XMLRE = /^\s*(?:<\?\s*xml\s+version\s*=\s*\"1.0\"[^>]*\?>\s*)?(?:<\!DOCTYPE[^>]*>\s*)?<\s*plist[^>]*\>/i;
CFPropertyList.FormatXMLDTD = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">";
CFPropertyList.Format280NorthMagicNumber = "280NPLIST";
CFPropertyList.FormatOpenStep = 1,
CFPropertyList.FormatXML_v1_0 = 100,
CFPropertyList.FormatBinary_v1_0 = 200,
CFPropertyList.Format280North_v1_0 = -1000;
CFPropertyList.sniffedFormatOfString = function( aString)
{
    if (aString.match(CFPropertyList.XMLRE))
        return CFPropertyList.FormatXML_v1_0;
    if (aString.substr(0, CFPropertyList.Format280NorthMagicNumber.length) === CFPropertyList.Format280NorthMagicNumber)
       return CFPropertyList.Format280North_v1_0;
    return NULL;
}
CFPropertyList.dataFromPropertyList = function( aPropertyList, aFormat)
{
    var data = new CFMutableData();
    data.setEncodedString(CFPropertyList.stringFromPropertyList(aPropertyList, aFormat));
    return data;
}
CFPropertyList.stringFromPropertyList = function( aPropertyList, aFormat)
{
    if (!aFormat)
        aFormat = CFPropertyList.Format280North_v1_0;
    var serializers = CFPropertyListSerializers[aFormat];
    return serializers["start"]() +
            serializePropertyList(aPropertyList, serializers) +
            serializers["finish"]();
}
CFPropertyList.readPropertyListFromFile = function( aFilePath)
{
    return CFPropertyList.propertyListFromString(FILE.read(aFilePath, { charset:"UTF-8" }));
}
CFPropertyList.writePropertyListToFile = function( aPropertyList, aFilePath, aFormat)
{
    return FILE.write(aFilePath, CFPropertyList.stringFromPropertyList(aPropertyList, aFormat), { charset:"UTF-8" });
}
function serializePropertyList( aPropertyList, serializers)
{
    var type = typeof aPropertyList,
        valueOf = aPropertyList.valueOf(),
        typeValueOf = typeof valueOf;
    if (type !== typeValueOf)
    {
        type = typeValueOf;
        aPropertyList = valueOf;
    }
    if (aPropertyList === YES || aPropertyList === NO)
        type = "boolean";
    else if (type === "number")
    {
        if (FLOOR(aPropertyList) === aPropertyList)
            type = "integer";
        else
            type = "real";
    }
    else if (type !== "string")
    {
        if (aPropertyList.slice)
            type = "array";
        else
            type = "dictionary";
    }
    return serializers[type](aPropertyList, serializers);
}
var CFPropertyListSerializers = { };
CFPropertyListSerializers[CFPropertyList.FormatXML_v1_0] =
{
    "start": function()
                    {
                        return CFPropertyList.FormatXMLDTD + "<plist version = \"1.0\">";
                    },
    "finish": function()
                    {
                        return "</plist>";
                    },
    "string": function( aString)
                    {
                        return "<string>" + encodeHTMLComponent(aString) + "</string>";;
                    },
    "boolean" : function( aBoolean)
                    {
                        return aBoolean ? "<true/>" : "<false/>";
                    },
    "integer": function( anInteger)
                    {
                        return "<integer>" + anInteger + "</integer>";
                    },
    "real": function( aFloat)
                    {
                        return "<real>" + aFloat + "</real>";
                    },
    "array": function( anArray, serializers)
                    {
                        var index = 0,
                            count = anArray.length,
                            string = "<array>";
                        for (; index < count; ++index)
                            string += serializePropertyList(anArray[index], serializers);
                        return string + "</array>";
                    },
    "dictionary": function( aDictionary, serializers)
                    {
                        var keys = aDictionary._keys,
                            index = 0,
                            count = keys.length,
                            string = "<dict>";
                        for (; index < count; ++index)
                        {
                            var key = keys[index];
                            string += "<key>" + key + "</key>";
                            string += serializePropertyList(aDictionary.valueForKey(key), serializers);
                        }
                        return string + "</dict>";
                    }
}
var ARRAY_MARKER = "A",
    DICTIONARY_MARKER = "D",
    FLOAT_MARKER = "f",
    INTEGER_MARKER = "d",
    STRING_MARKER = "S",
    TRUE_MARKER = "T",
    FALSE_MARKER = "F",
    KEY_MARKER = "K",
    END_MARKER = "E";
CFPropertyListSerializers[CFPropertyList.Format280North_v1_0] =
{
    "start": function()
                    {
                        return CFPropertyList.Format280NorthMagicNumber + ";1.0;";
                    },
    "finish": function()
                    {
                        return "";
                    },
    "string" : function( aString)
                    {
                        return STRING_MARKER + ';' + aString.length + ';' + aString;
                    },
    "boolean" : function( aBoolean)
                    {
                        return (aBoolean ? TRUE_MARKER : FALSE_MARKER) + ';';
                    },
    "integer": function( anInteger)
                    {
                        var string = "" + anInteger;
                        return INTEGER_MARKER + ';' + string.length + ';' + string;
                    },
    "real": function( aFloat)
                    {
                        var string = "" + aFloat;
                        return FLOAT_MARKER + ';' + string.length + ';' + string;
                    },
    "array": function( anArray, serializers)
                    {
                        var index = 0,
                            count = anArray.length,
                            string = ARRAY_MARKER + ';';
                        for (; index < count; ++index)
                            string += serializePropertyList(anArray[index], serializers);
                        return string + END_MARKER + ';';
                    },
    "dictionary": function( aDictionary, serializers)
                    {
                        var keys = aDictionary._keys,
                            index = 0,
                            count = keys.length,
                            string = DICTIONARY_MARKER +';';
                        for (; index < count; ++index)
                        {
                            var key = keys[index];
                            string += KEY_MARKER + ';' + key.length + ';' + key;
                            string += serializePropertyList(aDictionary.valueForKey(key), serializers);
                        }
                        return string + END_MARKER + ';';
                    }
}
var XML_XML = "xml",
    XML_DOCUMENT = "#document",
    PLIST_PLIST = "plist",
    PLIST_KEY = "key",
    PLIST_DICTIONARY = "dict",
    PLIST_ARRAY = "array",
    PLIST_STRING = "string",
    PLIST_BOOLEAN_TRUE = "true",
    PLIST_BOOLEAN_FALSE = "false",
    PLIST_NUMBER_REAL = "real",
    PLIST_NUMBER_INTEGER = "integer",
    PLIST_DATA = "data";
var _plist_traverseNextNode = function(anXMLNode, stayWithin, stack)
{
    var node = anXMLNode;
    node = (node.firstChild); if (node !== NULL && ((node.nodeType) === 8 || (node.nodeType) === 3)) while ((node = (node.nextSibling)) && ((node.nodeType) === 8 || (node.nodeType) === 3)) ;;
    if (node)
        return node;
    if ((String(anXMLNode.nodeName)) === PLIST_ARRAY || (String(anXMLNode.nodeName)) === PLIST_DICTIONARY)
        stack.pop();
    else
    {
        if (node === stayWithin)
            return NULL;
        node = anXMLNode;
        while ((node = (node.nextSibling)) && ((node.nodeType) === 8 || (node.nodeType) === 3)) ;;
        if (node)
            return node;
    }
    node = anXMLNode;
    while (node)
    {
        var next = node;
        while ((next = (next.nextSibling)) && ((next.nodeType) === 8 || (next.nodeType) === 3)) ;;
        if (next)
            return next;
        var node = (node.parentNode);
        if (stayWithin && node === stayWithin)
            return NULL;
        stack.pop();
    }
    return NULL;
}
CFPropertyList.propertyListFromData = function( aData, aFormat)
{
    return CFPropertyList.propertyListFromString(aData.encodedString(), aFormat);
}
CFPropertyList.propertyListFromString = function( aString, aFormat)
{
    if (!aFormat)
        aFormat = CFPropertyList.sniffedFormatOfString(aString);
    if (aFormat === CFPropertyList.FormatXML_v1_0)
        return CFPropertyList.propertyListFromXML(aString);
    if (aFormat === CFPropertyList.Format280North_v1_0)
        return propertyListFrom280NorthString(aString);
    return NULL;
}
var ARRAY_MARKER = "A",
    DICTIONARY_MARKER = "D",
    FLOAT_MARKER = "f",
    INTEGER_MARKER = "d",
    STRING_MARKER = "S",
    TRUE_MARKER = "T",
    FALSE_MARKER = "F",
    KEY_MARKER = "K",
    END_MARKER = "E";
function propertyListFrom280NorthString( aString)
{
    var stream = new MarkedStream(aString),
        marker = NULL,
        key = "",
        object = NULL,
        plistObject = NULL,
        containers = [],
        currentContainer = NULL;
    while (marker = stream.getMarker())
    {
        if (marker === END_MARKER)
        {
            containers.pop();
            continue;
        }
        var count = containers.length;
        if (count)
            currentContainer = containers[count - 1];
        if (marker === KEY_MARKER)
        {
            key = stream.getString();
            marker = stream.getMarker();
        }
        switch (marker)
        {
            case ARRAY_MARKER: object = []
                                    containers.push(object);
                                    break;
            case DICTIONARY_MARKER: object = new CFMutableDictionary();
                                    containers.push(object);
                                    break;
            case FLOAT_MARKER: object = parseFloat(stream.getString());
                                    break;
            case INTEGER_MARKER: object = parseInt(stream.getString(), 10);
                                    break;
            case STRING_MARKER: object = stream.getString();
                                    break;
            case TRUE_MARKER: object = YES;
                                    break;
            case FALSE_MARKER: object = NO;
                                    break;
            default: throw new Error("*** " + marker + " marker not recognized in Plist.");
        }
        if (!plistObject)
            plistObject = object;
        else if (currentContainer)
            if (currentContainer.slice)
                currentContainer.push(object);
            else
                currentContainer.setValueForKey(key, object);
    }
    return plistObject;
}
function encodeHTMLComponent( aString)
{
    return aString.replace(/&/g,'&amp;').replace(/"/g, '&quot;').replace(/'/g, '&apos;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
function decodeHTMLComponent( aString)
{
    return aString.replace(/&quot;/g, '"').replace(/&apos;/g, '\'').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&');
}
function parseXML( aString)
{
    if (window.DOMParser)
        return (new window.DOMParser().parseFromString(aString, "text/xml").documentElement);
    else if (window.ActiveXObject)
    {
        XMLNode = new ActiveXObject("Microsoft.XMLDOM");
        var matches = aString.match(CFPropertyList.DTDRE);
        if (matches)
            aString = aString.substr(matches[0].length);
        XMLNode.loadXML(aString);
        return XMLNode
    }
    return NULL;
}
CFPropertyList.propertyListFromXML = function( aStringOrXMLNode)
{
    var XMLNode = aStringOrXMLNode;
    if (aStringOrXMLNode.valueOf && typeof aStringOrXMLNode.valueOf() === "string")
        XMLNode = parseXML(aStringOrXMLNode);
    while (((String(XMLNode.nodeName)) === XML_DOCUMENT) || ((String(XMLNode.nodeName)) === XML_XML))
        XMLNode = (XMLNode.firstChild); if (XMLNode !== NULL && ((XMLNode.nodeType) === 8 || (XMLNode.nodeType) === 3)) while ((XMLNode = (XMLNode.nextSibling)) && ((XMLNode.nodeType) === 8 || (XMLNode.nodeType) === 3)) ;;
    if (((XMLNode.nodeType) === 10))
        while ((XMLNode = (XMLNode.nextSibling)) && ((XMLNode.nodeType) === 8 || (XMLNode.nodeType) === 3)) ;;
    if (!((String(XMLNode.nodeName)) === PLIST_PLIST))
        return NULL;
    var key = "",
        object = NULL,
        plistObject = NULL,
        plistNode = XMLNode,
        containers = [],
        currentContainer = NULL;
    while (XMLNode = _plist_traverseNextNode(XMLNode, plistNode, containers))
    {
        var count = containers.length;
        if (count)
            currentContainer = containers[count - 1];
        if ((String(XMLNode.nodeName)) === PLIST_KEY)
        {
            key = ((String((XMLNode.firstChild).nodeValue)));
            while ((XMLNode = (XMLNode.nextSibling)) && ((XMLNode.nodeType) === 8 || (XMLNode.nodeType) === 3)) ;;
        }
        switch (String((String(XMLNode.nodeName))))
        {
            case PLIST_ARRAY: object = []
                                        containers.push(object);
                                        break;
            case PLIST_DICTIONARY: object = new CFMutableDictionary();
                                        containers.push(object);
                                        break;
            case PLIST_NUMBER_REAL: object = parseFloat(((String((XMLNode.firstChild).nodeValue))));
                                        break;
            case PLIST_NUMBER_INTEGER: object = parseInt(((String((XMLNode.firstChild).nodeValue))), 10);
                                        break;
            case PLIST_STRING: object = decodeHTMLComponent((XMLNode.firstChild) ? ((String((XMLNode.firstChild).nodeValue))) : "");
                                        break;
            case PLIST_BOOLEAN_TRUE: object = YES;
                                        break;
            case PLIST_BOOLEAN_FALSE: object = NO;
                                        break;
            case PLIST_DATA: object = new CFMutableData();
                                        object.bytes = (XMLNode.firstChild) ? base64_decode_to_array(((String((XMLNode.firstChild).nodeValue))), YES) : [];
                                        break;
            default: throw new Error("*** " + (String(XMLNode.nodeName)) + " tag not recognized in Plist.");
        }
        if (!plistObject)
            plistObject = object;
        else if (currentContainer)
            if (currentContainer.slice)
                currentContainer.push(object);
            else
                currentContainer.setValueForKey(key, object);
    }
    return plistObject;
}
kCFPropertyListOpenStepFormat = CFPropertyList.FormatOpenStep;
kCFPropertyListXMLFormat_v1_0 = CFPropertyList.FormatXML_v1_0;
kCFPropertyListBinaryFormat_v1_0 = CFPropertyList.FormatBinary_v1_0;
kCFPropertyList280NorthFormat_v1_0 = CFPropertyList.Format280North_v1_0;
CFPropertyListCreate = function()
{
    return new CFPropertyList();
}
CFPropertyListCreateFromXMLData = function( data)
{
    return CFPropertyList.propertyListFromData(data, CFPropertyList.FormatXML_v1_0);
}
CFPropertyListCreateXMLData = function( aPropertyList)
{
    return CFPropertyList.dataFromPropertyList(aPropertyList, CFPropertyList.FormatXML_v1_0);
}
CFPropertyListCreateFrom280NorthData = function( data)
{
    return CFPropertyList.propertyListFromData(data, CFPropertyList.Format280North_v1_0);
}
CFPropertyListCreate280NorthData = function( aPropertyList)
{
    return CFPropertyList.dataFromPropertyList(aPropertyList, CFPropertyList.Format280North_v1_0);
}
CPPropertyListCreateFromData = function( data, aFormat)
{
    return CFPropertyList.propertyListFromData(data, aFormat);
}
CPPropertyListCreateData = function( aPropertyList, aFormat)
{
    return CFPropertyList.dataFromPropertyList(aPropertyList, aFormat);
}
CFDictionary = function( aDictionary)
{
    this._keys = [];
    this._count = 0;
    this._buckets = { };
    this._UID = objj_generateObjectUID();
}
var indexOf = Array.prototype.indexOf,
    hasOwnProperty = Object.prototype.hasOwnProperty;
CFDictionary.prototype.copy = function()
{
    return this;
}
CFDictionary.prototype.mutableCopy = function()
{
    var newDictionary = new CFMutableDictionary(),
        keys = this._keys,
        count = this._count;
    newDictionary._keys = keys.slice();
    newDictionary._count = count;
    var index = 0,
        buckets = this._buckets,
        newBuckets = newDictionary._buckets;
    for (; index < count; ++index)
    {
        var key = keys[index];
        newBuckets[key] = buckets[key];
    }
    return newDictionary;
}
CFDictionary.prototype.containsKey = function( aKey)
{
    return hasOwnProperty.apply(this._buckets, [aKey]);
}
CFDictionary.prototype.containsValue = function( anObject)
{
    var keys = this._keys,
        buckets = this._buckets,
        index = 0,
        count = keys.length;
    for (; index < count; ++index)
        if (buckets[keys] === anObject)
            return YES;
    return NO;
}
CFDictionary.prototype.count = function()
{
    return this._count;
}
CFDictionary.prototype.countOfKey = function( aKey)
{
    return this.containsKey(aKey) ? 1 : 0;
}
CFDictionary.prototype.countOfValue = function( anObject)
{
    var keys = this._keys,
        buckets = this._buckets,
        index = 0,
        count = keys.length,
        countOfValue = 0;
    for (; index < count; ++index)
        if (buckets[keys] === anObject)
            return ++countOfValue;
    return countOfValue;
}
CFDictionary.prototype.keys = function()
{
    return this._keys.slice();
}
CFDictionary.prototype.valueForKey = function( aKey)
{
    var buckets = this._buckets;
    if (!hasOwnProperty.apply(buckets, [aKey]))
        return nil;
    return buckets[aKey];
}
CFDictionary.prototype.toString = function()
{
    var string = "{\n",
        keys = this._keys,
        index = 0,
        count = this._count;
    for (; index < count; ++index)
    {
        var key = keys[index];
        string += "\t" + key + " = \"" + String(this.valueForKey(key)).split('\n').join("\n\t") + "\"\n";
    }
    return string + "}";
}
CFMutableDictionary = function( aDictionary)
{
    CFDictionary.apply(this, []);
}
CFMutableDictionary.prototype = new CFDictionary();
CFMutableDictionary.prototype.copy = function()
{
    return this.mutableCopy();
}
CFMutableDictionary.prototype.addValueForKey = function( aKey, aValue)
{
    if (this.containsKey(aKey))
        return;
    ++this._count;
    this._keys.push(aKey);
    this._buckets[aKey] = aValue;
}
CFMutableDictionary.prototype.removeValueForKey = function( aKey)
{
    var indexOfKey = -1;
    if (indexOf)
        indexOfKey = indexOf.call(this._keys, aKey);
    else
    {
        var keys = this._keys,
            index = 0,
            count = keys.length;
        for (; index < count; ++index)
            if (keys[index] === aKey)
            {
                indexOfKey = index;
                break;
            }
    }
    if (indexOfKey === -1)
        return;
    --this._count;
    this._keys.splice(indexOfKey, 1);
    delete this._buckets[aKey];
}
CFMutableDictionary.prototype.removeAllValues = function()
{
    this._count = 0;
    this._keys = [];
    this._buckets = { };
}
CFMutableDictionary.prototype.replaceValueForKey = function( aKey, aValue)
{
    if (!this.containsKey(aKey))
        return;
    this._buckets[aKey] = aValue;
}
CFMutableDictionary.prototype.setValueForKey = function( aKey, aValue)
{
    if (aValue === nil || aValue === undefined)
        this.removeValueForKey(aKey);
    else if (this.containsKey(aKey))
        this.replaceValueForKey(aKey, aValue);
    else
        this.addValueForKey(aKey, aValue);
}
CFData = function()
{
    this._encodedString = NULL;
    this._serializedPropertyList = NULL;
    this._bytes = NULL;
    this._base64 = NULL;
}
CFData.prototype.serializedPropertyList = function()
{
    if (!this._serializedPropertyList)
        this._serializedPropertyList = CFPropertyList.propertyListFromString(this.encodedString());
    return this._serializedPropertyList;
}
CFData.prototype.encodedString = function()
{
    if (this._encodedString === NULL)
    {
        var serializedPropertyList = this._serializedPropertyList;
        if (this._serializedPropertyList)
            this._encodedString = CFPropertyList.stringFromPropertyList(serializedPropertyList);
        else
            throw "Can't convert data to string.";
    }
    return this._encodedString;
}
CFData.prototype.bytes = function()
{
    return this._bytes;
}
CFData.prototype.base64 = function()
{
    return this._base64;
}
CFMutableData = function()
{
    CFData.call(this);
}
CFMutableData.prototype = new CFData();
function clearMutableData( aData)
{
    this._encodedString = NULL;
    this._serializedPropertyList = NULL;
    this._bytes = NULL;
    this._base64 = NULL;
}
CFMutableData.prototype.setSerializedPropertyList = function( aPropertyList)
{
    clearMutableData(this);
    this._serializedPropertyList = aPropertyList;
}
CFMutableData.prototype.setEncodedString = function( aString)
{
    clearMutableData(this);
    this._encodedString = aString;
}
CFMutableData.prototype.setBytes = function( bytes)
{
    clearMutableData(this);
    this._bytes = bytes;
}
CFMutableData.prototype.setBase64String = function( aBase64String)
{
    clearMutableData(this);
    this._base64 = aBase64String;
}
var base64_map_to = [
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "0","1","2","3","4","5","6","7","8","9","+","/","="],
    base64_map_from = [];
for (var i = 0; i < base64_map_to.length; i++)
    base64_map_from[base64_map_to[i].charCodeAt(0)] = i;
function base64_decode_to_array(input, strip)
{
    if (strip)
        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
    var pad = (input[input.length-1] == "=" ? 1 : 0) + (input[input.length-2] == "=" ? 1 : 0),
        length = input.length,
        output = [];
    var i = 0;
    while (i < length)
    {
        var bits = (base64_map_from[input.charCodeAt(i++)] << 18) |
                    (base64_map_from[input.charCodeAt(i++)] << 12) |
                    (base64_map_from[input.charCodeAt(i++)] << 6) |
                    (base64_map_from[input.charCodeAt(i++)]);
        output.push((bits & 0xFF0000) >> 16);
        output.push((bits & 0xFF00) >> 8);
        output.push(bits & 0xFF);
    }
    if (pad > 0)
        return output.slice(0, -1 * pad);
    return output;
}
function base64_encode_array(input)
{
    var pad = (3 - (input.length % 3)) % 3,
        length = input.length + pad,
        output = [];
    if (pad > 0) input.push(0);
    if (pad > 1) input.push(0);
    var i = 0;
    while (i < length)
    {
        var bits = (input[i++] << 16) |
                    (input[i++] << 8) |
                    (input[i++]);
        output.push(base64_map_to[(bits & 0xFC0000) >> 18]);
        output.push(base64_map_to[(bits & 0x3F000) >> 12]);
        output.push(base64_map_to[(bits & 0xFC0) >> 6]);
        output.push(base64_map_to[bits & 0x3F]);
    }
    if (pad > 0)
    {
        output[output.length-1] = "=";
        input.pop();
    }
    if (pad > 1)
    {
        output[output.length-2] = "=";
        input.pop();
    }
    return output.join("");
}
function base64_decode_to_string(input, strip)
{
    return bytes_to_string(base64_decode_to_array(input, strip));
}
bytes_to_string = function(bytes)
{
    return String.fromCharCode.apply(NULL, bytes);
}
base64_encode_string = function(input)
{
    var temp = [];
    for (var i = 0; i < input.length; i++)
        temp.push(input.charCodeAt(i));
    return base64_encode_array(temp);
}
function MarkedStream( aString)
{
    this._string = aString;
    var index = aString.indexOf(";");
    this._magicNumber = aString.substr(0, index);
    this._location = aString.indexOf(";", ++index);
    this._version = aString.substring(index, this._location++);
}
MarkedStream.prototype.magicNumber = function()
{
    return this._magicNumber;
}
MarkedStream.prototype.version = function()
{
    return this._version;
}
MarkedStream.prototype.getMarker = function()
{
    var string = this._string,
        location = this._location;
    if (location >= string.length)
        return null;
    var next = string.indexOf(';', location);
    if (next < 0)
        return null;
    var marker = string.substring(location, next);
    if (marker === 'e')
        return null;
    this._location = next + 1;
    return marker;
}
MarkedStream.prototype.getString = function()
{
    var string = this._string,
        location = this._location;
    if (location >= string.length)
        return null;
    var next = string.indexOf(';', location);
    if (next < 0)
        return null;
    var size = parseInt(string.substring(location, next)),
        text = string.substr(next + 1, size);
    this._location = next + 1 + size;
    return text;
}
var CFBundleUnloaded = 0,
    CFBundleLoading = 1 << 0,
    CFBundleLoadingInfoPlist = 1 << 1,
    CFBundleLoadingExecutable = 1 << 2,
    CFBundleLoadingSpritedImages = 1 << 3,
    CFBundleLoaded = 1 << 4;
var CFBundlesForPaths = { },
    CFBundlesForClasses = { },
    CFCacheBuster = new Date().getTime();
CFBundle = function( aPath)
{
    aPath = FILE.absolute(aPath);
    var existingBundle = CFBundlesForPaths[aPath];
    if (existingBundle)
        return existingBundle;
    CFBundlesForPaths[aPath] = this;
    this._path = aPath;
    this._name = FILE.basename(aPath);
    this._staticResource = NULL;
    this._loadStatus = CFBundleUnloaded;
    this._loadRequests = [];
    this._infoDictionary = NULL;
    this._URIMap = { };
    this._eventDispatcher = new EventDispatcher(this);
}
CFBundle.environments = function()
{
    return ["CommonJS", "ObjJ"];
}
CFBundle.bundleContainingPath = function( aPath)
{
    aPath = FILE.absolute(aPath);
    while (aPath !== "/")
    {
        var bundle = CFBundlesForPaths[aPath];
        if (bundle)
            return bundle;
        aPath = FILE.dirname(aPath);
    }
    return NULL;
}
CFBundle.mainBundle = function()
{
    return new CFBundle(FILE.cwd());
}
function addClassToBundle(aClass, aBundle)
{
    if (aBundle)
        CFBundlesForClasses[aClass.name] = aBundle;
}
CFBundle.bundleForClass = function( aClass)
{
    return CFBundlesForClasses[aClass.name] || CFBundle.mainBundle();
}
CFBundle.prototype.path = function()
{
    return this._path;
}
CFBundle.prototype.infoDictionary = function()
{
    return this._infoDictionary;
}
CFBundle.prototype.valueForInfoDictionary = function( aKey)
{
    return this._infoDictionary.valueForKey(aKey);
}
CFBundle.prototype.resourcesPath = function()
{
    return FILE.join(this.path(), "Resources");
}
CFBundle.prototype.pathForResource = function( aPath)
{
    var mappedPath = this._URIMap[FILE.join("Resources", aPath)];
    if (mappedPath)
        return mappedPath;
    return FILE.join(this.resourcesPath(), aPath);
}
CFBundle.prototype.executablePath = function()
{
    var executableSubPath = this._infoDictionary.valueForKey("CPBundleExecutable");
    if (executableSubPath)
        return FILE.join(this.path(), this.mostEligibleEnvironment() + ".environment", executableSubPath);
    return NULL;
}
CFBundle.prototype.hasSpritedImages = function()
{
    var environments = this._infoDictionary.valueForKey("CPBundleEnvironmentsWithImageSprites") || [],
        index = environments.length,
        mostEligibleEnvironment = this.mostEligibleEnvironment();
    while (index--)
        if (environments[index] === mostEligibleEnvironment)
            return YES;
    return NO;
}
CFBundle.prototype.environments = function()
{
    return this._infoDictionary.valueForKey("CPBundleEnvironments") || ["ObjJ"];
}
CFBundle.prototype.mostEligibleEnvironment = function( environments)
{
    environments = environments || this.environments();
    var objj_environments = CFBundle.environments(),
        index = 0,
        count = objj_environments.length,
        innerCount = environments.length;
    for(; index < count; ++index)
    {
        var innerIndex = 0,
            environment = objj_environments[index];
        for (; innerIndex < innerCount; ++innerIndex)
            if(environment === environments[innerIndex])
                return environment;
    }
    return NULL;
}
CFBundle.prototype.isLoading = function()
{
    return this._loadStatus & CFBundleLoading;
}
CFBundle.prototype.load = function( shouldExecute)
{
    if (this._loadStatus !== CFBundleUnloaded)
        return;
    this._loadStatus = CFBundleLoading | CFBundleLoadingInfoPlist;
    var self = this;
    rootResource.resolveSubPath(FILE.dirname(self.path()), YES, function(aStaticResource)
    {
        var path = self.path();
        if (path === "/")
            self._staticResource = rootResource;
        else
        {
            var name = FILE.basename(path);
            self._staticResource = aStaticResource._children[name];
            if (!self._staticResource)
                self._staticResource = new StaticResource(name, aStaticResource, YES, NO);
        }
        function onsuccess( anEvent)
        {
            self._loadStatus &= ~CFBundleLoadingInfoPlist;
            self._infoDictionary = anEvent.request.responsePropertyList();
            if (!self._infoDictionary)
            {
                finishBundleLoadingWithError(self, new Error("Could not load bundle at \"" + path + "\""));
                return;
            }
            loadExecutableAndResources(self, shouldExecute);
        }
        function onfailure()
        {
            self._loadStatus = CFBundleUnloaded;
            finishBundleLoadingWithError(self, new Error("Could not load bundle at \"" + path + "\""));
        }
        new FileRequest(FILE.join(path, "Info.plist"), onsuccess, onfailure);
    });
}
function finishBundleLoadingWithError( aBundle, anError)
{
    resolveStaticResource(aBundle._staticResource);
    aBundle._eventDispatcher.dispatchEvent(
    {
        type:"error",
        error:anError,
        bundle:aBundle
    });
}
function loadExecutableAndResources( aBundle, shouldExecute)
{
    if (!aBundle.mostEligibleEnvironment())
        return failure();
    loadExecutableForBundle(aBundle, success, failure);
    loadSpritedImagesForBundle(aBundle, success, failure);
    if (aBundle._loadStatus === CFBundleLoading)
        return success();
    function failure( anError)
    {
        var loadRequests = aBundle._loadRequests,
            count = loadRequests.length;
        while (count--)
            loadRequests[count].abort();
        this._loadRequests = [];
        aBundle._loadStatus = CFBundleUnloaded;
        finishBundleLoadingWithError(aBundle, anError || new Error("Could not recognize executable code format in Bundle " + aBundle));
    }
    function success()
    {
        if (aBundle._loadStatus === CFBundleLoading)
            aBundle._loadStatus = CFBundleLoaded;
        else
            return;
        resolveStaticResource(aBundle._staticResource);
        function complete()
        {
            aBundle._eventDispatcher.dispatchEvent(
            {
                type:"load",
                bundle:aBundle
            });
        }
        if (shouldExecute)
            executeBundle(aBundle, complete);
        else
            complete();
    }
}
function loadExecutableForBundle( aBundle, success, failure)
{
    if (!aBundle.executablePath())
        return;
    aBundle._loadStatus |= CFBundleLoadingExecutable;
    new FileRequest(aBundle.executablePath(), function( anEvent)
    {
        try
        {
            decompileStaticFile(aBundle, anEvent.request.responseText(), aBundle.executablePath());
            aBundle._loadStatus &= ~CFBundleLoadingExecutable;
            success();
        }
        catch(anException)
        {
            failure(anException);
        }
    }, failure);
}
function loadSpritedImagesForBundle( aBundle, success, failure)
{
    if (!aBundle.hasSpritedImages())
        return;
    aBundle._loadStatus |= CFBundleLoadingSpritedImages;
    if (!CFBundleHasTestedSpriteSupport())
        return CFBundleTestSpriteSupport(spritedImagesTestPathForBundle(aBundle), function()
        {
            loadSpritedImagesForBundle(aBundle, success, failure);
        });
    var spritedImagesPath = spritedImagesPathForBundle(aBundle);
    if (!spritedImagesPath)
    {
        aBundle._loadStatus &= ~CFBundleLoadingSpritedImages;
        return success();
    }
    new FileRequest(spritedImagesPath, function( anEvent)
    {
        try
        {
            decompileStaticFile(aBundle, anEvent.request.responseText(), spritedImagesPath);
            aBundle._loadStatus &= ~CFBundleLoadingSpritedImages;
            success();
        }
        catch(anException)
        {
            failure(anException);
        }
    }, failure);
}
var CFBundleSpriteSupportListeners = [],
    CFBundleSupportedSpriteType = -1,
    CFBundleNoSpriteType = 0,
    CFBundleDataURLSpriteType = 1,
    CFBundleMHTMLSpriteType = 2,
    CFBundleMHTMLUncachedSpriteType = 3;
function CFBundleHasTestedSpriteSupport()
{
    return CFBundleSupportedSpriteType !== -1;
}
function CFBundleTestSpriteSupport( MHTMLPath, aCallback)
{
    if (CFBundleHasTestedSpriteSupport())
        return;
    CFBundleSpriteSupportListeners.push(aCallback);
    if (CFBundleSpriteSupportListeners.length > 1)
        return;
    CFBundleTestSpriteTypes([
        CFBundleDataURLSpriteType,
        "data:image/gif;base64,R0lGODlhAQABAIAAAMc9BQAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw==",
        CFBundleMHTMLSpriteType,
        MHTMLPath+"!test",
        CFBundleMHTMLUncachedSpriteType,
        MHTMLPath+"?"+CFCacheBuster+"!test"
    ]);
}
function CFBundleNotifySpriteSupportListeners()
{
    var count = CFBundleSpriteSupportListeners.length;
    while (count--)
        CFBundleSpriteSupportListeners[count]();
}
function CFBundleTestSpriteTypes( spriteTypes)
{
    if (spriteTypes.length < 2)
    {
        CFBundleSupportedSpriteType = CFBundleNoSpriteType;
        CFBundleNotifySpriteSupportListeners();
        return;
    }
    var image = new Image();
    image.onload = function()
    {
        if (image.width === 1 && image.height === 1)
        {
            CFBundleSupportedSpriteType = spriteTypes[0];
            CFBundleNotifySpriteSupportListeners();
        }
        else
            image.onerror();
    }
    image.onerror = function()
    {
        CFBundleTestSpriteTypes(spriteTypes.slice(2));
    }
    image.src = spriteTypes[1];
}
function mhtmlBasePath()
{
    return "";
}
function spritedImagesTestPathForBundle( aBundle)
{
    return "mhtml:" + mhtmlBasePath() + FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "MHTMLTest.txt");
}
function spritedImagesPathForBundle( aBundle)
{
    if (CFBundleSupportedSpriteType === CFBundleDataURLSpriteType)
        return FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "dataURLs.txt");
    if (CFBundleSupportedSpriteType === CFBundleMHTMLSpriteType || CFBundleSupportedSpriteType === CFBundleMHTMLUncachedSpriteType)
        return mhtmlBasePath() + FILE.join(aBundle.path(), aBundle.mostEligibleEnvironment() + ".environment", "MHTMLPaths.txt");
    return NULL;
}
CFBundle.dataContentsAtPath = function( aPath)
{
    var data = new CFMutableData();
    data.setEncodedString(rootResource.nodeAtSubPath(aPath).contents());
    return data;
}
function executeBundle( aBundle, aCallback)
{
    var staticResources = [aBundle._staticResource],
        resourcesPath = aBundle.resourcesPath();
    function executeStaticResources(index)
    {
        for (; index < staticResources.length; ++index)
        {
            var staticResource = staticResources[index];
            if (staticResource.isNotFound())
                continue;
            if (staticResource.isFile())
            {
                var executable = new FileExecutable(staticResource.path());
                if (executable.hasLoadedFileDependencies())
                    executable.execute();
                else
                {
                    executable.addEventListener("dependenciesload", function()
                    {
                        executeStaticResources(index);
                    });
                    executable.loadFileDependencies();
                    return;
                }
            }
            else
            {
                if (staticResource.path() === aBundle.resourcesPath())
                    continue;
                var children = staticResource.children();
                for (var name in children)
                    if (hasOwnProperty.call(children, name))
                        staticResources.push(children[name]);
            }
        }
        aCallback();
    }
    executeStaticResources(0);
}
var STATIC_MAGIC_NUMBER = "@STATIC",
    MARKER_PATH = "p",
    MARKER_URI = "u",
    MARKER_CODE = "c",
    MARKER_TEXT = "t",
    MARKER_IMPORT_STD = 'I',
    MARKER_IMPORT_LOCAL = 'i';
function decompileStaticFile( aBundle, aString, aPath)
{
    var stream = new MarkedStream(aString);
    if (stream.magicNumber() !== STATIC_MAGIC_NUMBER)
        throw new Error("Could not read static file: "+aPath);
    if (stream.version() !== "1.0")
        throw new Error("Could not read static file: "+aPath);
    var marker,
        bundlePath = aBundle.path(),
        file = NULL;
    while (marker = stream.getMarker())
    {
        var text = stream.getString();
        if (marker === MARKER_PATH)
        {
            var absolutePath = FILE.join(bundlePath, text),
                parent = rootResource.nodeAtSubPath(FILE.dirname(absolutePath), YES);
            file = new StaticResource(FILE.basename(absolutePath), parent, NO, YES);
        }
        else if (marker === MARKER_URI)
        {
            var URI = stream.getString();
            if (URI.toLowerCase().indexOf("mhtml:") === 0)
            {
                URI = "mhtml:" + mhtmlBasePath() + FILE.join(bundlePath, URI.substr("mhtml:".length));
                if (CFBundleSupportedSpriteType === CFBundleMHTMLUncachedSpriteType)
                {
                    var exclamationIndex = URI.indexOf("!"),
                        firstPart = URI.substring(0, exclamationIndex),
                        lastPart = URI.substring(exclamationIndex);
                    URI = firstPart + "?" + CFCacheBuster + lastPart;
                }
            }
            aBundle._URIMap[text] = URI;
            var parent = rootResource.nodeAtSubPath(FILE.join(bundlePath, FILE.dirname(text)), YES);
            new StaticResource(FILE.basename(text), parent, NO, YES);
        }
        else if (marker === MARKER_TEXT)
            file.write(text);
    }
}
CFBundle.prototype.addEventListener = function( anEventName, anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
}
CFBundle.prototype.removeEventListener = function( anEventName, anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
}
CFBundle.prototype.onerror = function( anEvent)
{
    throw anEvent.error;
}
var FILE =
require("file");
function StaticResource( aName, aParent, isDirectory, isResolved)
{
    this._parent = aParent;
    this._eventDispatcher = new EventDispatcher(this);
    this._name = aName;
    this._isResolved = !!isResolved;
    this._path = FILE.join(aParent ? aParent.path() : "", aName);
    this._isDirectory = !!isDirectory;
    this._isNotFound = NO;
    if (aParent)
        aParent._children[aName] = this;
    if (isDirectory)
        this._children = { };
    else
        this._contents = "";
}
exports.StaticResource = StaticResource;
function resolveStaticResource( aResource)
{
    aResource._isResolved = YES;
    aResource._eventDispatcher.dispatchEvent(
    {
        type:"resolve",
        staticResource:aResource
    });
}
StaticResource.prototype.resolve = function()
{
    if (this.isDirectory())
    {
        var bundle = new CFBundle(this.path());
        bundle.onerror = function() { };
        bundle.load(NO);
    }
    else
    {
        var self = this;
        function onsuccess( anEvent)
        {
            self._contents = anEvent.request.responseText();
            resolveStaticResource(self);
        }
        function onfailure()
        {
            self._isNotFound = YES;
            resolveStaticResource(self);
        }
        new FileRequest(this.path(), onsuccess, onfailure);
    }
}
StaticResource.prototype.name = function()
{
    return this._name;
}
StaticResource.prototype.path = function()
{
    return this._path;
}
StaticResource.prototype.contents = function()
{
    return this._contents;
}
StaticResource.prototype.children = function()
{
    return this._children;
}
StaticResource.prototype.type = function()
{
    return this._type;
}
StaticResource.prototype.parent = function()
{
    return this._parent;
}
StaticResource.prototype.isResolved = function()
{
    return this._isResolved;
}
StaticResource.prototype.write = function( aString)
{
    this._contents += aString;
}
StaticResource.prototype.resolveSubPath = function( aPath, isDirectory, aCallback)
{
    aPath = FILE.normal(aPath);
    if (aPath === "/")
        return aCallback(rootResource);
    if (!FILE.isAbsolute(aPath))
        aPath = FILE.join(this.path(), aPath);
    var components = FILE.split(aPath),
        index = this === rootResource ? 1 : FILE.split(this.path()).length;
    resolvePathComponents(this, isDirectory, components, index, aCallback);
}
function resolvePathComponents( startResource, isDirectory, components, index, aCallback)
{
    var count = components.length,
        parent = startResource;
    function continueResolution()
    {
        resolvePathComponents(parent, isDirectory, components, index, aCallback);
    }
    for (; index < count; ++index)
    {
        var name = components[index],
            child = parent._children[name];
        if (!child)
        {
            child = new StaticResource(name, parent, index + 1 < count || isDirectory , NO);
            child.resolve();
        }
        if (!child.isResolved())
            return child.addEventListener("resolve", continueResolution);
        if (child.isNotFound())
            return aCallback(null, new Error("File not found: " + components.join("/")));
        if ((index + 1 < count) && child.isFile())
            return aCallback(null, new Error("File is not a directory: " + components.join("/")));
        parent = child;
    }
    return aCallback(parent);
}
StaticResource.prototype.addEventListener = function( anEventName, anEventListener)
{
    this._eventDispatcher.addEventListener(anEventName, anEventListener);
}
StaticResource.prototype.removeEventListener = function( anEventName, anEventListener)
{
    this._eventDispatcher.removeEventListener(anEventName, anEventListener);
}
StaticResource.prototype.isNotFound = function()
{
    return this._isNotFound;
}
StaticResource.prototype.isFile = function()
{
    return !this._isDirectory;
}
StaticResource.prototype.isDirectory = function()
{
    return this._isDirectory;
}
StaticResource.prototype.toString = function( includeNotFounds)
{
    if (this.isNotFound())
        return "<file not found: " + this.name() + ">";
    var string = this.parent() ? this.name() : "/",
        type = this.type();
    if (this.isDirectory())
    {
        var children = this._children;
        for (var name in children)
            if (children.hasOwnProperty(name))
            {
                var child = children[name];
                if (includeNotFounds || !child.isNotFound())
                    string += "\n\t" + children[name].toString(includeNotFounds).split('\n').join("\n\t");
            }
    }
    return string;
}
StaticResource.prototype.nodeAtSubPath = function( aPath, shouldResolveAsDirectories)
{
    aPath = FILE.normal(aPath);
    var components = FILE.split(FILE.isAbsolute(aPath) ? aPath : FILE.join(this.path(), aPath)),
        index = 1,
        count = components.length,
        parent = rootResource;
    for (; index < count; ++index)
    {
        var name = components[index];
        if (hasOwnProperty.call(parent._children, name))
            parent = parent._children[name];
        else if (shouldResolveAsDirectories)
            parent = new StaticResource(name, parent, YES, YES);
        else
            throw NULL;
    }
    return parent;
}
StaticResource.resolveStandardNodeAtPath = function( aPath, aCallback)
{
    var includePaths = StaticResource.includePaths(),
        resolveStandardNodeAtPath = function( aPath, anIndex)
        {
            var searchPath = FILE.absolute(FILE.join(includePaths[anIndex], FILE.normal(aPath)));
            rootResource.resolveSubPath(searchPath, NO, function( aStaticResource)
            {
                if (!aStaticResource)
                {
                    if (anIndex + 1< includePaths.length)
                        resolveStandardNodeAtPath(aPath, anIndex + 1);
                    else
                        aCallback(NULL);
                    return;
                }
                aCallback(aStaticResource);
            });
        };
    resolveStandardNodeAtPath(aPath, 0);
}
StaticResource.includePaths = function()
{
    return global.OBJJ_INCLUDE_PATHS || ["Frameworks", "Frameworks/Debug"];
}
StaticResource.cwd = FILE.cwd();
var TOKEN_ACCESSORS = "accessors",
    TOKEN_CLASS = "class",
    TOKEN_END = "end",
    TOKEN_FUNCTION = "function",
    TOKEN_IMPLEMENTATION = "implementation",
    TOKEN_IMPORT = "import",
    TOKEN_EACH = "each",
    TOKEN_OUTLET = "outlet",
    TOKEN_ACTION = "action",
    TOKEN_NEW = "new",
    TOKEN_SELECTOR = "selector",
    TOKEN_SUPER = "super",
    TOKEN_VAR = "var",
    TOKEN_IN = "in",
    TOKEN_EQUAL = '=',
    TOKEN_PLUS = '+',
    TOKEN_MINUS = '-',
    TOKEN_COLON = ':',
    TOKEN_COMMA = ',',
    TOKEN_PERIOD = '.',
    TOKEN_ASTERISK = '*',
    TOKEN_SEMICOLON = ';',
    TOKEN_LESS_THAN = '<',
    TOKEN_OPEN_BRACE = '{',
    TOKEN_CLOSE_BRACE = '}',
    TOKEN_GREATER_THAN = '>',
    TOKEN_OPEN_BRACKET = '[',
    TOKEN_DOUBLE_QUOTE = '"',
    TOKEN_PREPROCESSOR = '@',
    TOKEN_CLOSE_BRACKET = ']',
    TOKEN_QUESTION_MARK = '?',
    TOKEN_OPEN_PARENTHESIS = '(',
    TOKEN_CLOSE_PARENTHESIS = ')',
    TOKEN_WHITESPACE = /^(?:(?:\s+$)|(?:\/(?:\/|\*)))/,
    TOKEN_NUMBER = /^[+-]?\d+(([.]\d+)*([eE][+-]?\d+))?$/,
    TOKEN_IDENTIFIER = /^[a-zA-Z_$](\w|$)*$/;
function Lexer( aString)
{
    this._index = -1;
    this._tokens = (aString + '\n').match(/\/\/.*(\r|\n)?|\/\*(?:.|\n|\r)*?\*\/|\w+\b|[+-]?\d+(([.]\d+)*([eE][+-]?\d+))?|"[^"\\]*(\\[\s\S][^"\\]*)*"|'[^'\\]*(\\[\s\S][^'\\]*)*'|\s+|./g);
    this._context = [];
    return this;
}
Lexer.prototype.push = function()
{
    this._context.push(this._index);
}
Lexer.prototype.pop = function()
{
    this._index = this._context.pop();
}
Lexer.prototype.peak = function(shouldSkipWhitespace)
{
    if (shouldSkipWhitespace)
    {
        this.push();
        var token = this.skip_whitespace();
        this.pop();
        return token;
    }
    return this._tokens[this._index + 1];
}
Lexer.prototype.next = function()
{
    return this._tokens[++this._index];
}
Lexer.prototype.previous = function()
{
    return this._tokens[--this._index];
}
Lexer.prototype.last = function()
{
    if (this._index < 0)
        return NULL;
    return this._tokens[this._index - 1];
}
Lexer.prototype.skip_whitespace= function(shouldMoveBackwards)
{
    var token;
    if (shouldMoveBackwards)
        while((token = this.previous()) && TOKEN_WHITESPACE.test(token)) ;
    else
        while((token = this.next()) && TOKEN_WHITESPACE.test(token)) ;
    return token;
}
exports.Lexer = Lexer;
function StringBuffer()
{
    this.atoms = [];
}
StringBuffer.prototype.toString = function()
{
    return this.atoms.join("");
}
exports.preprocess = function( aString, aPath, flags)
{
    return new Preprocessor(aString, aPath, flags).executable();
}
exports.eval = function( aString)
{
    return eval(exports.preprocess(aString).code());
}
var Preprocessor = function( aString, aPath, flags)
{
    aString = aString.replace(/^#[^\n]+\n/, "\n");
    this._currentSelector = "";
    this._currentClass = "";
    this._currentSuperClass = "";
    this._currentSuperMetaClass = "";
    this._filePath = aPath;
    this._buffer = new StringBuffer();
    this._preprocessed = NULL;
    this._dependencies = [];
    this._tokens = new Lexer(aString);
    this._flags = flags;
    this._classMethod = false;
    this._executable = NULL;
    this.preprocess(this._tokens, this._buffer);
}
exports.Preprocessor = Preprocessor;
Preprocessor.Flags = { };
Preprocessor.Flags.IncludeDebugSymbols = 1 << 0;
Preprocessor.Flags.IncludeTypeSignatures = 1 << 1;
Preprocessor.prototype.executable = function()
{
    if (!this._executable)
        this._executable = new Executable(this._buffer.toString(), this._dependencies);
    return this._executable;
}
Preprocessor.prototype.accessors = function(tokens)
{
    var token = tokens.skip_whitespace(),
        attributes = {};
    if (token != TOKEN_OPEN_PARENTHESIS)
    {
        tokens.previous();
        return attributes;
    }
    while ((token = tokens.skip_whitespace()) != TOKEN_CLOSE_PARENTHESIS)
    {
        var name = token,
            value = true;
        if (!/^\w+$/.test(name))
            throw new SyntaxError(this.error_message("*** @property attribute name not valid."));
        if ((token = tokens.skip_whitespace()) == TOKEN_EQUAL)
        {
            value = tokens.skip_whitespace();
            if (!/^\w+$/.test(value))
                throw new SyntaxError(this.error_message("*** @property attribute value not valid."));
            if (name == "setter")
            {
                if ((token = tokens.next()) != TOKEN_COLON)
                    throw new SyntaxError(this.error_message("*** @property setter attribute requires argument with \":\" at end of selector name."));
                value += ":";
            }
            token = tokens.skip_whitespace();
        }
        attributes[name] = value;
        if (token == TOKEN_CLOSE_PARENTHESIS)
            break;
        if (token != TOKEN_COMMA)
            throw new SyntaxError(this.error_message("*** Expected ',' or ')' in @property attribute list."));
    }
    return attributes;
}
Preprocessor.prototype.brackets = function( tokens, aStringBuffer)
{
    var tuples = [];
    while (this.preprocess(tokens, NULL, NULL, NULL, tuples[tuples.length] = [])) ;
    if (tuples[0].length === 1)
    {
        aStringBuffer.atoms[aStringBuffer.atoms.length] = '[';
        aStringBuffer.atoms[aStringBuffer.atoms.length] = tuples[0][0];
        aStringBuffer.atoms[aStringBuffer.atoms.length] = ']';
    }
    else
    {
        var selector = new StringBuffer();
        if (tuples[0][0].atoms[0] == TOKEN_SUPER)
        {
            aStringBuffer.atoms[aStringBuffer.atoms.length] = "objj_msgSendSuper(";
            aStringBuffer.atoms[aStringBuffer.atoms.length] = "{ receiver:self, super_class:" + (this._classMethod ? this._currentSuperMetaClass : this._currentSuperClass ) + " }";
        }
        else
        {
            aStringBuffer.atoms[aStringBuffer.atoms.length] = "objj_msgSend(";
            aStringBuffer.atoms[aStringBuffer.atoms.length] = tuples[0][0];
        }
        selector.atoms[selector.atoms.length] = tuples[0][1];
        var index = 1,
            count = tuples.length,
            marg_list = new StringBuffer();
        for(; index < count; ++index)
        {
            var pair = tuples[index];
            selector.atoms[selector.atoms.length] = pair[1]
            marg_list.atoms[marg_list.atoms.length] = ", " + pair[0];
        }
        aStringBuffer.atoms[aStringBuffer.atoms.length] = ", \"";
        aStringBuffer.atoms[aStringBuffer.atoms.length] = selector;
        aStringBuffer.atoms[aStringBuffer.atoms.length] = '\"';
        aStringBuffer.atoms[aStringBuffer.atoms.length] = marg_list;
        aStringBuffer.atoms[aStringBuffer.atoms.length] = ')';
    }
}
Preprocessor.prototype.directive = function(tokens, aStringBuffer, allowedDirectivesFlags)
{
    var buffer = aStringBuffer ? aStringBuffer : new StringBuffer(),
        token = tokens.next();
    if (token.charAt(0) == TOKEN_DOUBLE_QUOTE)
        buffer.atoms[buffer.atoms.length] = token;
    else if (token === TOKEN_CLASS)
    {
        tokens.skip_whitespace();
        return;
    }
    else if (token === TOKEN_IMPLEMENTATION)
        this.implementation(tokens, buffer);
    else if (token === TOKEN_IMPORT)
        this._import(tokens);
    else if (token === TOKEN_EACH)
        this.each(tokens, buffer);
    else if (token === TOKEN_SELECTOR)
        this.selector(tokens, buffer);
    if (!aStringBuffer)
        return buffer;
}
var fastEnumeratorCount = 0;
Preprocessor.prototype.each = function(tokens, aStringBuffer)
{
    var token = tokens.skip_whitespace();
    if (token !== TOKEN_OPEN_PARENTHESIS)
       throw new SyntaxError(this.error_message("*** Expecting (, found: \"" + token + "\"."));
    var identifiers = [],
        isVared = NO;
    do
    {
        token = tokens.skip_whitespace();
        if (identifiers.length === 0 && token === TOKEN_VAR)
        {
            isVared = YES;
            token = tokens.skip_whitespace();
        }
        if (!TOKEN_IDENTIFIER.test(token))
            throw new SyntaxError(this.error_message("*** Expecting identifier, found: \"" + token + "\"."));
        identifiers.push(token);
        token = tokens.skip_whitespace();
        if (token !== TOKEN_COMMA && token !== TOKEN_IN)
            throw new SyntaxError(this.error_message("*** Expecting \",\", found: \"" + token + "\"."));
    } while (token && token === TOKEN_COMMA);
    if (token !== TOKEN_IN)
        throw new SyntaxError(this.error_message("*** Expecting \"in\", found: \"" + token + "\"."));
    var generatedFastEnumeratorName = "$OBJJ_GENERATED_FAST_ENUMERATOR_" + fastEnumeratorCount++;
    aStringBuffer.atoms[aStringBuffer.atoms.length] = "var ";
    aStringBuffer.atoms[aStringBuffer.atoms.length] = generatedFastEnumeratorName;
    aStringBuffer.atoms[aStringBuffer.atoms.length] = " = new objj_fastEnumerator(";
    this.preprocess(tokens, aStringBuffer, TOKEN_CLOSE_PARENTHESIS, TOKEN_OPEN_PARENTHESIS);
    aStringBuffer.atoms[aStringBuffer.atoms.length] = ", ";
    aStringBuffer.atoms[aStringBuffer.atoms.length] = identifiers.length;
    aStringBuffer.atoms[aStringBuffer.atoms.length] = ");\n";
    aStringBuffer.atoms[aStringBuffer.atoms.length] = "for (";
    if (isVared)
    {
        aStringBuffer.atoms[aStringBuffer.atoms.length] = "var ";
        aStringBuffer.atoms[aStringBuffer.atoms.length] = identifiers.join(", ");
    }
    aStringBuffer.atoms[aStringBuffer.atoms.length] = ";(";
    aStringBuffer.atoms[aStringBuffer.atoms.length] = generatedFastEnumeratorName;
    aStringBuffer.atoms[aStringBuffer.atoms.length] = ".i < ";
    aStringBuffer.atoms[aStringBuffer.atoms.length] = generatedFastEnumeratorName;
    aStringBuffer.atoms[aStringBuffer.atoms.length] = ".l || ";
    aStringBuffer.atoms[aStringBuffer.atoms.length] = generatedFastEnumeratorName;
    aStringBuffer.atoms[aStringBuffer.atoms.length] = ".e()) && ((";
    for (var index = 0, count = identifiers.length; index < count; ++index)
    {
        aStringBuffer.atoms[aStringBuffer.atoms.length] = identifiers[index];
        aStringBuffer.atoms[aStringBuffer.atoms.length] = " = ";
        aStringBuffer.atoms[aStringBuffer.atoms.length] = generatedFastEnumeratorName;
        aStringBuffer.atoms[aStringBuffer.atoms.length] = ".o";
        aStringBuffer.atoms[aStringBuffer.atoms.length] = index;
        aStringBuffer.atoms[aStringBuffer.atoms.length] = "[";
        aStringBuffer.atoms[aStringBuffer.atoms.length] = generatedFastEnumeratorName;
        aStringBuffer.atoms[aStringBuffer.atoms.length] = ".i]";
        if (index + 1 < count)
            aStringBuffer.atoms[aStringBuffer.atoms.length] = ", ";
    }
    aStringBuffer.atoms[aStringBuffer.atoms.length] = ") || YES); ++";
    aStringBuffer.atoms[aStringBuffer.atoms.length] = generatedFastEnumeratorName;
    aStringBuffer.atoms[aStringBuffer.atoms.length] = ".i)";
}
Preprocessor.prototype.implementation = function(tokens, aStringBuffer)
{
    var buffer = aStringBuffer,
        token = "",
        category = NO,
        class_name = tokens.skip_whitespace(),
        superclass_name = "Nil",
        instance_methods = new StringBuffer(),
        class_methods = new StringBuffer();
    if (!(/^\w/).test(class_name))
        throw new Error(this.error_message("*** Expected class name, found \"" + class_name + "\"."));
    this._currentSuperClass = "objj_getClass(\"" + class_name + "\").super_class";
    this._currentSuperMetaClass = "objj_getMetaClass(\"" + class_name + "\").super_class";
    this._currentClass = class_name;
    this._currentSelector = "";
    if((token = tokens.skip_whitespace()) == TOKEN_OPEN_PARENTHESIS)
    {
        token = tokens.skip_whitespace();
        if (token == TOKEN_CLOSE_PARENTHESIS)
            throw new SyntaxError(this.error_message("*** Can't Have Empty Category Name for class \"" + class_name + "\"."));
        if (tokens.skip_whitespace() != TOKEN_CLOSE_PARENTHESIS)
            throw new SyntaxError(this.error_message("*** Improper Category Definition for class \"" + class_name + "\"."));
        buffer.atoms[buffer.atoms.length] = "{\nvar the_class = objj_getClass(\"" + class_name + "\")\n";
        buffer.atoms[buffer.atoms.length] = "if(!the_class) throw new SyntaxError(\"*** Could not find definition for class \\\"" + class_name + "\\\"\");\n";
        buffer.atoms[buffer.atoms.length] = "var meta_class = the_class.isa;";
    }
    else
    {
        if(token == TOKEN_COLON)
        {
            token = tokens.skip_whitespace();
            if (!TOKEN_IDENTIFIER.test(token))
                throw new SyntaxError(this.error_message("*** Expected class name, found \"" + token + "\"."));
            superclass_name = token;
            token = tokens.skip_whitespace();
        }
        buffer.atoms[buffer.atoms.length] = "{var the_class = objj_allocateClassPair(" + superclass_name + ", \"" + class_name + "\"),\nmeta_class = the_class.isa;";
        if (token == TOKEN_OPEN_BRACE)
        {
            var ivar_count = 0,
                declaration = [],
                attributes,
                accessors = {};
            while((token = tokens.skip_whitespace()) && token != TOKEN_CLOSE_BRACE)
            {
                if (token === TOKEN_PREPROCESSOR)
                {
                    token = tokens.next();
                    if (token === TOKEN_ACCESSORS)
                        attributes = this.accessors(tokens);
                    else if (token !== TOKEN_OUTLET)
                        throw new SyntaxError(this.error_message("*** Unexpected '@' token in ivar declaration ('@"+token+"')."));
                }
                else if (token == TOKEN_SEMICOLON)
                {
                    if (ivar_count++ == 0)
                        buffer.atoms[buffer.atoms.length] = "class_addIvars(the_class, [";
                    else
                        buffer.atoms[buffer.atoms.length] = ", ";
                    var name = declaration[declaration.length - 1];
                    buffer.atoms[buffer.atoms.length] = "new objj_ivar(\"" + name + "\")";
                    declaration = [];
                    if (attributes)
                    {
                        accessors[name] = attributes;
                        attributes = NULL;
                    }
                }
                else
                    declaration.push(token);
            }
            if (declaration.length)
                throw new SyntaxError(this.error_message("*** Expected ';' in ivar declaration, found '}'."));
            if (ivar_count)
                buffer.atoms[buffer.atoms.length] = "]);\n";
            if (!token)
                throw new SyntaxError(this.error_message("*** Expected '}'"));
            for (ivar_name in accessors)
            {
                var accessor = accessors[ivar_name],
                    property = accessor["property"] || ivar_name;
                var getterName = accessor["getter"] || property,
                    getterCode = "(id)" + getterName + "\n{\nreturn " + ivar_name + ";\n}";
                if (instance_methods.atoms.length !== 0)
                    instance_methods.atoms[instance_methods.atoms.length] = ",\n";
                instance_methods.atoms[instance_methods.atoms.length] = this.method(new Lexer(getterCode));
                if (accessor["readonly"])
                    continue;
                var setterName = accessor["setter"];
                if (!setterName)
                {
                    var start = property.charAt(0) == '_' ? 1 : 0;
                    setterName = (start ? "_" : "") + "set" + property.substr(start, 1).toUpperCase() + property.substring(start + 1) + ":";
                }
                var setterCode = "(void)" + setterName + "(id)newValue\n{\n";
                if (accessor["copy"])
                    setterCode += "if (" + ivar_name + " !== newValue)\n" + ivar_name + " = [newValue copy];\n}";
                else
                    setterCode += ivar_name + " = newValue;\n}";
                if (instance_methods.atoms.length !== 0)
                    instance_methods.atoms[instance_methods.atoms.length] = ",\n";
                instance_methods.atoms[instance_methods.atoms.length] = this.method(new Lexer(setterCode));
            }
        }
        else
            tokens.previous();
        buffer.atoms[buffer.atoms.length] = "objj_registerClassPair(the_class);\n";
    }
    while ((token = tokens.skip_whitespace()))
    {
        if (token == TOKEN_PLUS)
        {
            this._classMethod = true;
            if (class_methods.atoms.length !== 0)
                class_methods.atoms[class_methods.atoms.length] = ", ";
            class_methods.atoms[class_methods.atoms.length] = this.method(tokens);
        }
        else if (token == TOKEN_MINUS)
        {
            this._classMethod = false;
            if (instance_methods.atoms.length !== 0)
                instance_methods.atoms[instance_methods.atoms.length] = ", ";
            instance_methods.atoms[instance_methods.atoms.length] = this.method(tokens);
        }
        else if (token == TOKEN_PREPROCESSOR)
        {
            if ((token = tokens.next()) == TOKEN_END)
                break;
            else
                throw new SyntaxError(this.error_message("*** Expected \"@end\", found \"@" + token + "\"."));
        }
    }
    if (instance_methods.atoms.length !== 0)
    {
        buffer.atoms[buffer.atoms.length] = "class_addMethods(the_class, [";
        buffer.atoms[buffer.atoms.length] = instance_methods;
        buffer.atoms[buffer.atoms.length] = "]);\n";
    }
    if (class_methods.atoms.length !== 0)
    {
        buffer.atoms[buffer.atoms.length] = "class_addMethods(meta_class, [";
        buffer.atoms[buffer.atoms.length] = class_methods;
        buffer.atoms[buffer.atoms.length] = "]);\n";
    }
    buffer.atoms[buffer.atoms.length] = '}';
    this._currentClass = "";
}
Preprocessor.prototype._import = function(tokens)
{
    var path = "",
        token = tokens.skip_whitespace(),
        isLocal = (token != TOKEN_LESS_THAN);
    if (token === TOKEN_LESS_THAN)
    {
        while((token = tokens.next()) && token != TOKEN_GREATER_THAN)
            path += token;
        if(!token)
            throw new SyntaxError(this.error_message("*** Unterminated import statement."));
    }
    else if (token.charAt(0) == TOKEN_DOUBLE_QUOTE)
        path = token.substr(1, token.length - 2);
    else
        throw new SyntaxError(this.error_message("*** Expecting '<' or '\"', found \"" + token + "\"."));
    this._buffer.atoms[this._buffer.atoms.length] = "objj_executeFile(\"";
    this._buffer.atoms[this._buffer.atoms.length] = path;
    this._buffer.atoms[this._buffer.atoms.length] = isLocal ? "\", true);" : "\", false);";
    this._dependencies.push(new FileDependency(path, isLocal));
}
Preprocessor.prototype.method = function( tokens)
{
    var buffer = new StringBuffer(),
        token,
        selector = "",
        parameters = [],
        types = [null];
    while((token = tokens.skip_whitespace()) && token != TOKEN_OPEN_BRACE)
    {
        if (token == TOKEN_COLON)
        {
            var type = "";
            selector += token;
            token = tokens.skip_whitespace();
            if (token == TOKEN_OPEN_PARENTHESIS)
            {
                while((token = tokens.skip_whitespace()) && token != TOKEN_CLOSE_PARENTHESIS)
                    type += token;
                token = tokens.skip_whitespace();
            }
            types[parameters.length+1] = type || null;
            parameters[parameters.length] = token;
        }
        else if (token == TOKEN_OPEN_PARENTHESIS)
        {
            var type = "";
            while((token = tokens.skip_whitespace()) && token != TOKEN_CLOSE_PARENTHESIS)
                type += token;
            types[0] = type || null;
        }
        else if (token == TOKEN_COMMA)
        {
            if ((token = tokens.skip_whitespace()) != TOKEN_PERIOD || tokens.next() != TOKEN_PERIOD || tokens.next() != TOKEN_PERIOD)
                throw new SyntaxError(this.error_message("*** Argument list expected after ','."));
        }
        else
            selector += token;
    }
    var index = 0,
        count = parameters.length;
    buffer.atoms[buffer.atoms.length] = "new objj_method(sel_getUid(\"";
    buffer.atoms[buffer.atoms.length] = selector;
    buffer.atoms[buffer.atoms.length] = "\"), function";
    this._currentSelector = selector;
    if (this._flags & Preprocessor.Flags.IncludeDebugSymbols)
        buffer.atoms[buffer.atoms.length] = " $" + this._currentClass + "__" + selector.replace(/:/g, "_");
    buffer.atoms[buffer.atoms.length] = "(self, _cmd";
    for(; index < count; ++index)
    {
        buffer.atoms[buffer.atoms.length] = ", ";
        buffer.atoms[buffer.atoms.length] = parameters[index];
    }
    buffer.atoms[buffer.atoms.length] = ")\n{ with(self)\n{";
    buffer.atoms[buffer.atoms.length] = this.preprocess(tokens, NULL, TOKEN_CLOSE_BRACE, TOKEN_OPEN_BRACE);
    buffer.atoms[buffer.atoms.length] = "}\n}";
    if (this._flags & Preprocessor.Flags.IncludeDebugSymbols)
        buffer.atoms[buffer.atoms.length] = ","+JSON.stringify(types);
    buffer.atoms[buffer.atoms.length] = ")";
    this._currentSelector = "";
    return buffer;
}
Preprocessor.prototype.preprocess = function(tokens, aStringBuffer, terminator, instigator, tuple)
{
    var buffer = aStringBuffer ? aStringBuffer : new StringBuffer(),
        count = 0,
        token = "";
    if (tuple)
    {
        tuple[0] = buffer;
        var bracket = false,
            closures = [0, 0, 0];
    }
    while ((token = tokens.next()) && ((token !== terminator) || count))
    {
        if (tuple)
        {
            if (token === TOKEN_QUESTION_MARK)
                ++closures[2];
            else if (token === TOKEN_OPEN_BRACE)
                ++closures[0];
            else if (token === TOKEN_CLOSE_BRACE)
                --closures[0];
            else if (token === TOKEN_OPEN_PARENTHESIS)
                ++closures[1];
            else if (token === TOKEN_CLOSE_PARENTHESIS)
                --closures[1];
            else if ((token === TOKEN_COLON && closures[2]-- === 0 ||
                    (bracket = (token === TOKEN_CLOSE_BRACKET))) &&
                    closures[0] === 0 && closures[1] === 0)
            {
                tokens.push();
                var label = bracket ? tokens.skip_whitespace(true) : tokens.previous(),
                    isEmptyLabel = TOKEN_WHITESPACE.test(label);
                if (isEmptyLabel || TOKEN_IDENTIFIER.test(label) && TOKEN_WHITESPACE.test(tokens.previous()))
                {
                    tokens.push();
                    var last = tokens.skip_whitespace(true),
                        operatorCheck = true,
                        isDoubleOperator = false;
                    if (last === '+' || last === '-'){
                        if (tokens.previous() !== last)
                            operatorCheck = false;
                        else
                        {
                            last = tokens.skip_whitespace(true);
                            isDoubleOperator = true;
                        }}
                    tokens.pop();
                    tokens.pop();
                    if (operatorCheck && (
                        (!isDoubleOperator && (last === TOKEN_CLOSE_BRACE)) ||
                        last === TOKEN_CLOSE_PARENTHESIS || last === TOKEN_CLOSE_BRACKET ||
                        last === TOKEN_PERIOD || TOKEN_NUMBER.test(last) ||
                        last.charAt(last.length - 1) === '\"' || last.charAt(last.length - 1) === '\'' ||
                        TOKEN_IDENTIFIER.test(last) && !/^(new|return|case|var)$/.test(last)))
                    {
                        if (isEmptyLabel)
                            tuple[1] = ':';
                        else
                        {
                            tuple[1] = label;
                            if (!bracket)
                                tuple[1] += ':';
                            var count = buffer.atoms.length;
                            while (buffer.atoms[count--] !== label) ;
                            buffer.atoms.length = count;
                        }
                        return !bracket;
                    }
                    if (bracket)
                        return NO;
                }
                tokens.pop();
                if (bracket)
                    return NO;
            }
            closures[2] = MAX(closures[2], 0);
        }
        if (instigator)
        {
            if (token === instigator)
                ++count;
            else if (token === terminator)
                --count;
        }
        if (token === TOKEN_FUNCTION)
        {
            var accumulator = "";
            while((token = tokens.next()) && token !== TOKEN_OPEN_PARENTHESIS && !(/^\w/).test(token))
                accumulator += token;
            if (token === TOKEN_OPEN_PARENTHESIS)
            {
                if (instigator === TOKEN_OPEN_PARENTHESIS)
                    ++count;
                buffer.atoms[buffer.atoms.length] = "function" + accumulator + '(';
                if (tuple)
                    ++closures[1];
            }
            else
            {
                buffer.atoms[buffer.atoms.length] = token + "= function";
            }
        }
        else if (token == TOKEN_PREPROCESSOR)
            this.directive(tokens, buffer);
        else if (token == TOKEN_OPEN_BRACKET)
            this.brackets(tokens, buffer);
        else
            buffer.atoms[buffer.atoms.length] = token;
    }
    if (tuple)
        new SyntaxError(this.error_message("*** Expected ']' - Unterminated message send or array."));
    if (!aStringBuffer)
        return buffer;
}
Preprocessor.prototype.selector = function(tokens, aStringBuffer)
{
    var buffer = aStringBuffer ? aStringBuffer : new StringBuffer();
    buffer.atoms[buffer.atoms.length] = "sel_getUid(\"";
    if (tokens.skip_whitespace() != TOKEN_OPEN_PARENTHESIS)
        throw new SyntaxError(this.error_message("*** Expected '('"));
    var selector = tokens.skip_whitespace();
    if (selector == TOKEN_CLOSE_PARENTHESIS)
        throw new SyntaxError(this.error_message("*** Unexpected ')', can't have empty @selector()"));
    aStringBuffer.atoms[aStringBuffer.atoms.length] = selector;
    var token,
        starting = true;
    while ((token = tokens.next()) && token != TOKEN_CLOSE_PARENTHESIS)
    {
        if (starting && /^\d+$/.test(token) || !(/^(\w|$|\:)/.test(token)))
        {
            if (!(/\S/).test(token))
                if (tokens.skip_whitespace() == TOKEN_CLOSE_PARENTHESIS)
                    break;
                else
                    throw new SyntaxError(this.error_message("*** Unexpected whitespace in @selector()."));
            else
                throw new SyntaxError(this.error_message("*** Illegal character '" + token + "' in @selector()."));
        }
        buffer.atoms[buffer.atoms.length] = token;
        starting = (token == TOKEN_COLON);
    }
    buffer.atoms[buffer.atoms.length] = "\")";
    if (!aStringBuffer)
        return buffer;
}
Preprocessor.prototype.error_message = function(errorMessage)
{
    return errorMessage + " <Context File: "+ this._filePath +
                                (this._currentClass ? " Class: "+this._currentClass : "") +
                                (this._currentSelector ? " Method: "+this._currentSelector : "") +">";
}
function FileDependency( aPath, isLocal)
{
    this._path = FILE.normal(aPath);
    this._isLocal = isLocal;
}
exports.FileDependency = FileDependency;
FileDependency.prototype.path = function()
{
    return this._path;
}
FileDependency.prototype.isLocal = function()
{
    return this._isLocal;
}
FileDependency.prototype.toMarkedString = function()
{
    return (this.isLocal() ? MARKER_IMPORT_LOCAL : MARKER_IMPORT_STD) + ";" +
            this.path().length + ";" + this.path();
}
FileDependency.prototype.toString = function()
{
    return (this.isLocal() ? "LOCAL: " : "STD: ") + this.path();
}
var ExecutableUnloadedFileDependencies = 0,
    ExecutableLoadingFileDependencies = 1,
    ExecutableLoadedFileDependencies = 2;
function Executable( aCode, fileDependencies, aScope, aFunction)
{
    if (arguments.length === 0)
        return this;
    this._code = aCode;
    this._function = aFunction || NULL;
    this._scope = aScope || "(Anonymous)";
    this._fileDependencies = fileDependencies;
    this._fileDependencyLoadStatus = ExecutableUnloadedFileDependencies;
    this._eventDispatcher = new EventDispatcher(this);
    if (this._function)
        return;
    this.setCode(aCode);
}
exports.Executable = Executable;
Executable.prototype.path = function()
{
    return FILE.join(FILE.cwd(), "(Anonymous)");
}
Executable.prototype.functionParameters = function()
{
    var functionParameters = ["global", "objj_executeFile", "objj_importFile"];
    functionParameters = functionParameters.concat("require", "exports", "module", "system", "print", "window");
    return functionParameters;
}
Executable.prototype.functionArguments = function()
{
    var functionArguments = [global, this.fileExecuter(), this.fileImporter()];
    functionArguments = functionArguments.concat(Executable.commonJSArguments());
    return functionArguments;
}
Executable.setCommonJSParameters = function()
{
    this._commonJSParameters = Array.prototype.slice.call(arguments);
}
Executable.commonJSParameters = function()
{
    return this._commonJSParameters || [];
}
Executable.setCommonJSArguments = function()
{
    this._commonJSArguments = Array.prototype.slice.call(arguments);
}
Executable.commonJSArguments = function()
{
    return this._commonJSArguments || [];
}
Executable.prototype.toMarkedString = function()
{
    var markedString = "@STATIC;1.0;",
        dependencies = this.fileDependencies(),
        index = 0,
        count = dependencies.length;
    for (; index < count; ++index)
        markedString += dependencies[index].toMarkedString();
    var code = this.code();
    return markedString + MARKER_TEXT + ";" + code.length + ";" + code;
}
Executable.prototype.execute = function()
{
    var oldContextBundle = CONTEXT_BUNDLE;
    CONTEXT_BUNDLE = CFBundle.bundleContainingPath(this.path());
    var result = this._function.apply(global, this.functionArguments());
    CONTEXT_BUNDLE = oldContextBundle;
    return result;
}
Executable.prototype.code = function()
{
    return this._code;
}
Executable.prototype.setCode = function(code)
{
    this._code = code;
    var parameters = this.functionParameters().join(",");
    if (typeof system !== "undefined" && system.engine === "rhino")
    {
        code = "function(" + parameters + "){" + code + "/**/\n}";
        this._function = Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(window, code, this._scope, 0, NULL);
    }
    else
    {
        code += "/**/\n//@ sourceURL=" + this._scope;
        this._function = new Function(parameters, code);
    this._function.displayName = this._scope;
    }
}
Executable.prototype.fileDependencies = function()
{
    return this._fileDependencies;
}
Executable.prototype.scope = function()
{
    return this._scope;
}
Executable.prototype.hasLoadedFileDependencies = function()
{
    return this._fileDependencyLoadStatus === ExecutableLoadedFileDependencies;
}
var globalIteration = 0;
Executable.prototype.loadFileDependencies = function()
{
    if (this._fileDependencyLoadStatus !== ExecutableUnloadedFileDependencies)
        return;
    this._fileDependencyLoadStatus = ExecutableLoadingFileDependencies;
    var searchedPaths = [{ }, { }],
        fileExecutableSearches = new CFMutableDictionary(),
        incompleteFileExecutableSearches = new CFMutableDictionary(),
        loadingExecutables = { };
    function searchForFileDependencies( anExecutable)
    {
        var executables = [anExecutable],
            executableIndex = 0,
            executableCount = executables.length;
        for (; executableIndex < executableCount; ++executableIndex)
        {
            var executable = executables[executableIndex];
            if (executable.hasLoadedFileDependencies())
                continue;
            var executablePath = executable.path();
            loadingExecutables[executablePath] = executable;
            var cwd = FILE.dirname(executablePath),
                fileDependencies = executable.fileDependencies(),
                fileDependencyIndex = 0,
                fileDependencyCount = fileDependencies.length;
            for (; fileDependencyIndex < fileDependencyCount; ++fileDependencyIndex)
            {
                var fileDependency = fileDependencies[fileDependencyIndex],
                    isLocal = fileDependency.isLocal(),
                    path = importablePath(fileDependency.path(), isLocal, cwd);
                if (searchedPaths[isLocal ? 1 : 0][path])
                    continue;
                searchedPaths[isLocal ? 1 : 0][path] = YES;
                var fileExecutableSearch = new FileExecutableSearch(path, isLocal),
                    fileExecutableSearchUID = fileExecutableSearch.UID();
                if (fileExecutableSearches.containsKey(fileExecutableSearchUID))
                    continue;
                fileExecutableSearches.setValueForKey(fileExecutableSearchUID, fileExecutableSearch);
                if (fileExecutableSearch.isComplete())
                {
                    executables.push(fileExecutableSearch.result());
                    ++executableCount;
                }
                else
                {
                    incompleteFileExecutableSearches.setValueForKey(fileExecutableSearchUID, fileExecutableSearch);
                    fileExecutableSearch.addEventListener("complete", function( anEvent)
                    {
                        var fileExecutableSearch = anEvent.fileExecutableSearch;
                        incompleteFileExecutableSearches.removeValueForKey(fileExecutableSearch.UID());
                        searchForFileDependencies(fileExecutableSearch.result());
                    });
                }
            }
        }
        if (incompleteFileExecutableSearches.count() > 0)
            return;
        for (var path in loadingExecutables)
            if (hasOwnProperty.call(loadingExecutables, path))
                loadingExecutables[path]._fileDependencyLoadStatus = ExecutableLoadedFileDependencies;
        for (var path in loadingExecutables)
            if (hasOwnProperty.call(loadingExecutables, path))
            {
                var executable = loadingExecutables[path];
                executable._eventDispatcher.dispatchEvent(
                {
                    type:"dependenciesload",
                    executable:executable
                });
            }
    }
    searchForFileDependencies(this);
}
Executable.prototype.addEventListener = function( anEventName, aListener)
{
    this._eventDispatcher.addEventListener(anEventName, aListener);
}
Executable.prototype.removeEventListener = function( anEventName, aListener)
{
    this._eventDispatcher.removeEventListener(anEventName, aListener);
}
function importablePath( aPath, isLocal, aCWD)
{
    aPath = FILE.normal(aPath);
    if (FILE.isAbsolute(aPath))
        return aPath;
    if (isLocal)
        aPath = FILE.normal(FILE.join(aCWD, aPath));
    return aPath;
}
Executable.prototype.fileImporter = function()
{
    return Executable.fileImporterForPath(FILE.dirname(this.path()));
}
Executable.prototype.fileExecuter = function()
{
    return Executable.fileExecuterForPath(FILE.dirname(this.path()));
}
var cachedFileExecutersForPaths = { };
Executable.fileExecuterForPath = function( referencePath)
{
    referencePath = FILE.normal(referencePath);
    var fileExecuter = cachedFileExecutersForPaths[referencePath];
    if (!fileExecuter)
    {
        fileExecuter = function( aPath, isLocal, shouldForce)
        {
            aPath = importablePath(aPath, isLocal, referencePath);
            var fileExecutableSearch = new FileExecutableSearch(aPath, isLocal),
                fileExecutable = fileExecutableSearch.result();
            if (0 && !fileExecutable.hasLoadedFileDependencies())
                throw "No executable loaded for file at path " + aPath;
            fileExecutable.execute(shouldForce);
        }
        cachedFileExecutersForPaths[referencePath] = fileExecuter;
    }
    return fileExecuter;
}
var cachedImportersForPaths = { };
Executable.fileImporterForPath = function( referencePath)
{
    referencePath = FILE.normal(referencePath);
    var cachedImporter = cachedImportersForPaths[referencePath];
    if (!cachedImporter)
    {
        cachedImporter = function( aPath, isLocal, aCallback)
        {
            aPath = importablePath(aPath, isLocal, referencePath);
            var fileExecutableSearch = new FileExecutableSearch(aPath, isLocal);
            function searchComplete( aFileExecutableSearch)
            {
                var fileExecutable = aFileExecutableSearch.result(),
                    fileExecuter = Executable.fileExecuterForPath(referencePath),
                    executeAndCallback = function ()
                    {
                        fileExecuter(aPath, isLocal);
                        if (aCallback)
                            aCallback();
                    }
                if (!fileExecutable.hasLoadedFileDependencies())
                {
                    fileExecutable.addEventListener("dependenciesload", executeAndCallback);
                    fileExecutable.loadFileDependencies();
                }
                else
                    executeAndCallback();
            }
            if (fileExecutableSearch.isComplete())
                searchComplete(fileExecutableSearch);
            else
                fileExecutableSearch.addEventListener("complete", function( anEvent)
                {
                    searchComplete(anEvent.fileExecutableSearch);
                });
        }
        cachedImportersForPaths[referencePath] = cachedImporter;
    }
    return cachedImporter;
}
var FileExecutablesForPaths = { };
function FileExecutable( aPath)
{
    var existingFileExecutable = FileExecutablesForPaths[aPath];
    if (existingFileExecutable)
        return existingFileExecutable;
    FileExecutablesForPaths[aPath] = this;
    var fileContents = rootResource.nodeAtSubPath(aPath).contents(),
        executable = NULL,
        extension = FILE.extension(aPath);
    if (fileContents.match(/^@STATIC;/))
        executable = decompile(fileContents, aPath);
    else if (extension === ".j" || extension === "")
        executable = exports.preprocess(fileContents, aPath, Preprocessor.OBJJ_PREPROCESSOR_DEBUG_SYMBOLS);
    else
        executable = new Executable(fileContents, [], aPath);
    Executable.apply(this, [executable.code(), executable.fileDependencies(), aPath, executable._function]);
    this._path = aPath;
    this._hasExecuted = NO;
}
exports.FileExecutable = FileExecutable;
FileExecutable.prototype = new Executable();
FileExecutable.allFileExecutables = function()
{
    var fileExecutables = [];
    for (path in FileExecutablesForPaths)
        if (hasOwnProperty.call(FileExecutablesForPaths, path))
            fileExecutables.push(FileExecutablesForPaths[path]);
    return fileExecutables;
}
FileExecutable.prototype.execute = function( shouldForce)
{
    if (this._hasExecuted && !shouldForce)
        return;
    this._hasExecuted = YES;
    Executable.prototype.execute.call(this);
}
FileExecutable.prototype.path = function()
{
    return this._path;
}
FileExecutable.prototype.hasExecuted = function()
{
    return this._hasExecuted;
}
function decompile( aString, aPath)
{
    var stream = new MarkedStream(aString);
    var marker = NULL,
        code = "",
        dependencies = [];
    while (marker = stream.getMarker())
    {
        var text = stream.getString();
        if (marker === MARKER_TEXT)
            code += text;
        else if (marker === MARKER_IMPORT_STD)
            dependencies.push(new FileDependency(FILE.normal(text), NO));
        else if (marker === MARKER_IMPORT_LOCAL)
            dependencies.push(new FileDependency(FILE.normal(text), YES));
    }
    return new Executable(code, dependencies, aPath);
}
var FileExecutableSearchesForPaths = [{ }, { }];
function FileExecutableSearch( aPath, isLocal)
{
    if (!FILE.isAbsolute(aPath) && isLocal)
        throw "Local searches cannot be relative: " + aPath;
    var existingSearch = FileExecutableSearchesForPaths[isLocal ? 1 : 0][aPath];
    if (existingSearch)
        return existingSearch;
    FileExecutableSearchesForPaths[isLocal ? 1 : 0][aPath] = this;
    this._UID = objj_generateObjectUID();
    this._isComplete = NO;
    this._eventDispatcher = new EventDispatcher(this);
    this._path = aPath;
    this._result = NULL;
    var self = this;
    function completed( aStaticResource)
    {
        if (!aStaticResource)
            throw new Error("Could not load file at " + aPath);
        self._result = new FileExecutable(aStaticResource.path());
        self._isComplete = YES;
        self._eventDispatcher.dispatchEvent(
        {
            type:"complete",
            fileExecutableSearch:self
        });
    }
    if (isLocal)
        rootResource.resolveSubPath(aPath, NO, completed);
    else
        StaticResource.resolveStandardNodeAtPath(aPath, completed);
}
exports.FileExecutableSearch = FileExecutableSearch;
FileExecutableSearch.prototype.path = function()
{
    return this._path;
}
FileExecutableSearch.prototype.result = function()
{
    return this._result;
}
FileExecutableSearch.prototype.UID = function()
{
    return this._UID;
}
FileExecutableSearch.prototype.isComplete = function()
{
    return this._isComplete;
}
FileExecutableSearch.prototype.result = function()
{
    return this._result;
}
FileExecutableSearch.prototype.addEventListener = function( anEventName, aListener)
{
    this._eventDispatcher.addEventListener(anEventName, aListener);
}
FileExecutableSearch.prototype.removeEventListener = function( anEventName, aListener)
{
    this._eventDispatcher.removeEventListener(anEventName, aListener);
}
var CLS_CLASS = 0x1,
    CLS_META = 0x2,
    CLS_INITIALIZED = 0x4,
    CLS_INITIALIZING = 0x8;
objj_ivar = function( aName, aType)
{
    this.name = aName;
    this.type = aType;
}
objj_method = function( aName, anImplementation, types)
{
    this.name = aName;
    this.method_imp = anImplementation;
    this.types = types;
}
objj_class = function()
{
    this.isa = NULL;
    this.super_class = NULL;
    this.sub_classes = [];
    this.name = NULL;
    this.info = 0;
    this.ivars = [];
    this.method_list = [];
    this.method_hash = {};
    this.method_store = function() { };
    this.method_dtable = this.method_store.prototype;
    this.allocator = function() { };
    this._UID = -1;
}
objj_object = function()
{
    this.isa = NULL;
    this._UID = -1;
}
class_getName = function( aClass)
{
    if (aClass == Nil)
        return "";
    return aClass.name;
}
class_isMetaClass = function( aClass)
{
    if (!aClass)
        return NO;
    return ((aClass.info & (CLS_META)));
}
class_getSuperclass = function( aClass)
{
    if (aClass == Nil)
        return Nil;
    return aClass.super_class;
}
class_setSuperclass = function( aClass, aSuperClass)
{
    aClass.super_class = aSuperClass;
    aClass.isa.super_class = aSuperClass.isa;
}
class_addIvar = function( aClass, aName, aType)
{
    var thePrototype = aClass.allocator.prototype;
    if (typeof thePrototype[aName] != "undefined")
        return NO;
    aClass.ivars.push(new objj_ivar(aName, aType));
    thePrototype[aName] = NULL;
    return YES;
}
class_addIvars = function( aClass, ivars)
{
    var index = 0,
        count = ivars.length,
        thePrototype = aClass.allocator.prototype;
    for (; index < count; ++index)
    {
        var ivar = ivars[index],
            name = ivar.name;
        if (typeof thePrototype[name] === "undefined")
        {
            aClass.ivars.push(ivar);
            thePrototype[name] = NULL;
        }
    }
}
class_copyIvarList = function( aClass)
{
    return aClass.ivars.slice(0);
}
class_addMethod = function( aClass, aName, anImplementation, types)
{
    if (aClass.method_hash[aName])
        return NO;
    var method = new objj_method(aName, anImplementation, types);
    aClass.method_list.push(method);
    aClass.method_dtable[aName] = method;
    method.method_imp.displayName = (((aClass.info & (CLS_META))) ? '+' : '-') + " [" + class_getName(aClass) + ' ' + method_getName(method) + ']';
    if (!((aClass.info & (CLS_META))) && (((aClass.info & (CLS_META))) ? aClass : aClass.isa).isa === (((aClass.info & (CLS_META))) ? aClass : aClass.isa))
        class_addMethod((((aClass.info & (CLS_META))) ? aClass : aClass.isa), aName, anImplementation, types);
    return YES;
}
class_addMethods = function( aClass, methods)
{
    var index = 0,
        count = methods.length,
        method_list = aClass.method_list,
        method_dtable = aClass.method_dtable;
    for (; index < count; ++index)
    {
        var method = methods[index];
        if (aClass.method_hash[method.name])
            continue;
        method_list.push(method);
        method_dtable[method.name] = method;
        method.method_imp.displayName = (((aClass.info & (CLS_META))) ? '+' : '-') + " [" + class_getName(aClass) + ' ' + method_getName(method) + ']';
    }
    if (!((aClass.info & (CLS_META))) && (((aClass.info & (CLS_META))) ? aClass : aClass.isa).isa === (((aClass.info & (CLS_META))) ? aClass : aClass.isa))
        class_addMethods((((aClass.info & (CLS_META))) ? aClass : aClass.isa), methods);
}
class_getInstanceMethod = function( aClass, aSelector)
{
    if (!aClass || !aSelector)
        return NULL;
    var method = aClass.method_dtable[aSelector];
    return method ? method : NULL;
}
class_getClassMethod = function( aClass, aSelector)
{
    if (!aClass || !aSelector)
        return NULL;
    var method = (((aClass.info & (CLS_META))) ? aClass : aClass.isa).method_dtable[aSelector];
    return method ? method : NULL;
}
class_copyMethodList = function( aClass)
{
    return aClass.method_list.slice(0);
}
class_replaceMethod = function( aClass, aSelector, aMethodImplementation)
{
    if (!aClass || !aSelector)
        return NULL;
    var method = aClass.method_dtable[aSelector],
        method_imp = NULL;
    if (method)
        method_imp = method.method_imp;
    method.method_imp = aMethodImplementation;
    return method_imp;
}
var _class_initialize = function( aClass)
{
    var meta = (((aClass.info & (CLS_META))) ? aClass : aClass.isa);
    if ((aClass.info & (CLS_META)))
        aClass = objj_getClass(aClass.name);
    if (aClass.super_class && !((((aClass.super_class.info & (CLS_META))) ? aClass.super_class : aClass.super_class.isa).info & (CLS_INITIALIZED)))
        _class_initialize(aClass.super_class);
    if (!(meta.info & (CLS_INITIALIZED)) && !(meta.info & (CLS_INITIALIZING)))
    {
        meta.info = (meta.info | (CLS_INITIALIZING)) & ~(0);
        objj_msgSend(aClass, "initialize");
        meta.info = (meta.info | (CLS_INITIALIZED)) & ~(CLS_INITIALIZING);
    }
}
var _objj_forward = new objj_method("forward", function(self, _cmd)
{
    return objj_msgSend(self, "forward::", _cmd, arguments);
});
class_getMethodImplementation = function( aClass, aSelector)
{
    if (!((((aClass.info & (CLS_META))) ? aClass : aClass.isa).info & (CLS_INITIALIZED))) _class_initialize(aClass); var method = aClass.method_dtable[aSelector]; if (!method) method = _objj_forward; var implementation = method.method_imp;;
    return implementation;
}
var REGISTERED_CLASSES = { };
objj_allocateClassPair = function( superclass, aName)
{
    var classObject = new objj_class(),
        metaClassObject = new objj_class(),
        rootClassObject = classObject;
    if (superclass)
    {
        rootClassObject = superclass;
        while (rootClassObject.superclass)
            rootClassObject = rootClassObject.superclass;
        classObject.allocator.prototype = new superclass.allocator;
        classObject.method_store.prototype = new superclass.method_store;
        classObject.method_dtable = classObject.method_store.prototype;
        metaClassObject.method_store.prototype = new superclass.isa.method_store;
        metaClassObject.method_dtable = metaClassObject.method_store.prototype;
        classObject.super_class = superclass;
        metaClassObject.super_class = superclass.isa;
    }
    else
        classObject.allocator.prototype = new objj_object();
    classObject.isa = metaClassObject;
    classObject.name = aName;
    classObject.info = CLS_CLASS;
    classObject._UID = objj_generateObjectUID();
    metaClassObject.isa = rootClassObject.isa;
    metaClassObject.name = aName;
    metaClassObject.info = CLS_META;
    metaClassObject._UID = objj_generateObjectUID();
    return classObject;
}
var CONTEXT_BUNDLE = nil;
objj_registerClassPair = function( aClass)
{
    global[aClass.name] = aClass;
    REGISTERED_CLASSES[aClass.name] = aClass;
    addClassToBundle(aClass, CONTEXT_BUNDLE);
}
class_createInstance = function( aClass)
{
    if (!aClass)
        objj_exception_throw(new objj_exception(OBJJNilClassException, "*** Attempting to create object with Nil class."));
    var object = new aClass.allocator();
    object.isa = aClass;
    object._UID = objj_generateObjectUID();
    return object;
}
var prototype_bug = function() { }
prototype_bug.prototype.member = false;
with (new prototype_bug())
    member = true;
if (new prototype_bug().member)
{
var fast_class_createInstance = class_createInstance;
class_createInstance = function( aClass)
{
    var object = fast_class_createInstance(aClass);
    if (object)
    {
        var theClass = object.isa,
            actualClass = theClass;
        while (theClass)
        {
            var ivars = theClass.ivars;
                count = ivars.length;
            while (count--)
                object[ivars[count].name] = NULL;
            theClass = theClass.super_class;
        }
        object.isa = actualClass;
    }
    return object;
}
}
object_getClassName = function( anObject)
{
    if (!anObject)
        return "";
    var theClass = anObject.isa;
    return theClass ? class_getName(theClass) : "";
}
objj_lookUpClass = function( aName)
{
    var theClass = REGISTERED_CLASSES[aName];
    return theClass ? theClass : Nil;
}
objj_getClass = function( aName)
{
    var theClass = REGISTERED_CLASSES[aName];
    if (!theClass)
    {
    }
    return theClass ? theClass : Nil;
}
objj_getMetaClass = function( aName)
{
    var theClass = objj_getClass(aName);
    return (((theClass.info & (CLS_META))) ? theClass : theClass.isa);
}
ivar_getName = function(anIvar)
{
    return anIvar.name;
}
ivar_getTypeEncoding = function(anIvar)
{
    return anIvar.type;
}
objj_msgSend = function( aReceiver, aSelector)
{
    if (aReceiver == nil)
        return nil;
    if (!((((aReceiver.isa.info & (CLS_META))) ? aReceiver.isa : aReceiver.isa.isa).info & (CLS_INITIALIZED))) _class_initialize(aReceiver.isa); var method = aReceiver.isa.method_dtable[aSelector]; if (!method) method = _objj_forward; var implementation = method.method_imp;;
    switch(arguments.length)
    {
        case 2: return implementation(aReceiver, aSelector);
        case 3: return implementation(aReceiver, aSelector, arguments[2]);
        case 4: return implementation(aReceiver, aSelector, arguments[2], arguments[3]);
    }
    return implementation.apply(aReceiver, arguments);
}
objj_msgSendSuper = function( aSuper, aSelector)
{
    var super_class = aSuper.super_class;
    arguments[0] = aSuper.receiver;
    if (!((((super_class.info & (CLS_META))) ? super_class : super_class.isa).info & (CLS_INITIALIZED))) _class_initialize(super_class); var method = super_class.method_dtable[aSelector]; if (!method) method = _objj_forward; var implementation = method.method_imp;;
    return implementation.apply(aSuper.receiver, arguments);
}
method_getName = function( aMethod)
{
    return aMethod.name;
}
method_getImplementation = function( aMethod)
{
    return aMethod.method_imp;
}
method_setImplementation = function( aMethod, anImplementation)
{
    var oldImplementation = aMethod.method_imp;
    aMethod.method_imp = anImplementation;
    return oldImplementation;
}
method_exchangeImplementations = function( lhs, rhs)
{
    var lhs_imp = method_getImplementation(lhs),
        rhs_imp = method_getImplementation(rhs);
    method_setImplementation(lhs, rhs_imp);
    method_setImplementation(rhs, lhs_imp);
}
sel_getName = function(aSelector)
{
    return aSelector ? aSelector : "<null selector>";
}
sel_getUid = function( aName)
{
    return aName;
}
sel_isEqual = function( lhs, rhs)
{
    return lhs === rhs;
}
sel_registerName = function( aName)
{
    return aName;
}
var fastEnumerationSelector = sel_getUid("countByEnumeratingWithState:objects:count:");
objj_fastEnumerator = function( anObject, anAssigneeCount)
{
    if (anObject && (!anObject.isa || !class_getInstanceMethod(anObject.isa, fastEnumerationSelector)))
        this._target = [anObject];
    else
        this._target = anObject;
    this._state = { state:0, assigneeCount:anAssigneeCount };
    this._index = 0;
    if (!anObject)
    {
        this.i = 0;
        this.l = 0;
    }
    else
        this.e();
}
objj_fastEnumerator.prototype.e = function()
{
    var object = this._target;
    if (!object)
        return NO;
    var state = this._state,
        index = state.assigneeCount;
    while (index--)
        state["items" + index] = nil;
    this.i = 0;
    if (CPArray && object.isa === CPArray)
    {
        if (this.l)
            return NO;
        this.o0 = object;
        this.l = object.length;
    }
    else
    {
        state.items = nil;
        state.itemsPtr = nil;
        this.o0 = [];
        this.l = objj_msgSend(object, fastEnumerationSelector, state, this.o0, 16);
        this.o0 = state.items || state.itemsPtr || state.items0 || this.o0;
        if (this.l === undefined)
            this.l = this.o0.length;
    }
    var assigneeCount = state.assigneeCount;
    index = assigneeCount - 1;
    while (index-- > 1)
        this["o" + index] = state["items" + index] || [];
    var lastAssigneeIndex = assigneeCount - 1;
    if (lastAssigneeIndex > 0)
        if (state["items" + lastAssigneeIndex])
            this["o" + lastAssigneeIndex] = state["items" + lastAssigneeIndex];
        else
        {
            var count = this.l,
                indexIndex = 0,
                indexes = new Array(count)
            for (; indexIndex < count; ++indexIndex, ++this._index)
                indexes[indexIndex] = this._index;
            this["o" + lastAssigneeIndex] = indexes;
        }
    return this.l > 0;
}
var cwd = FILE.cwd(),
    rootResource = new StaticResource("", NULL, YES, cwd !== "/");
StaticResource.root = rootResource;
exports.objj_frameworks = [];
exports.objj_debug_frameworks = [];
var catalog = require("packages").catalog;
for (var name in catalog)
{
    if (!catalog.hasOwnProperty(name))
        continue;
    var info = catalog[name];
    if (!info)
        continue;
    var frameworks = info["objj-frameworks"];
    if (frameworks) {
        if (!Array.isArray(frameworks))
            frameworks = [String(frameworks)];
        exports.objj_frameworks.push.apply(exports.objj_frameworks, frameworks.map(function(aFrameworkPath) {
            return FILE.join(info.directory, aFrameworkPath);
        }));
    }
    var debugFrameworks = info["objj-debug-frameworks"];
    if (debugFrameworks) {
        if (!Array.isArray(debugFrameworks))
            debugFrameworks = [String(debugFrameworks)];
        exports.objj_debug_frameworks.push.apply(exports.objj_debug_frameworks, debugFrameworks.map(function(aFrameworkPath) {
            return FILE.join(info.directory, aFrameworkPath);
        }));
    }
}
OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, exports.objj_frameworks);
OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, exports.objj_debug_frameworks);
if (system.env["OBJJ_INCLUDE_PATHS"])
    OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, system.env["OBJJ_INCLUDE_PATHS"].split(":"));
with (window)
{
exports.run = function(args)
{
    if (args)
    {
        var argv = args.slice(1);
        while (argv.length && argv[0].indexOf('-I') === 0)
            OBJJ_INCLUDE_PATHS.unshift.apply(OBJJ_INCLUDE_PATHS, argv.shift().substr(2).split(':'));
    }
    if (argv && argv.length > 0)
    {
        var arg0 = argv.shift();
        var mainFilePath = FILE.canonical(arg0);
        exports.make_narwhal_factory(mainFilePath)(require, { }, module, system, print, window);
        if (typeof main === "function")
            main([arg0].concat(argv));
        require("browser/timeout").serviceTimeouts();
    }
    else
    {
        exports.repl();
    }
}
exports.repl = function()
{
    var READLINE = require("readline");
    var historyPath = FILE.path(system.env["HOME"], ".objj_history");
    var historyFile = null;
    if (historyPath.exists() && READLINE.addHistory) {
        historyPath.read({ charset : "UTF-8" }).split("\n").forEach(function(line) {
            if (line.trim())
                READLINE.addHistory(line);
        });
    }
    try {
        historyFile = historyPath.open("a", { charset : "UTF-8" });
    } catch (e) {
        system.stderr.print("Warning: Can't open history file '"+historyFile+"' for writing.");
    }
    while (true)
    {
        try {
            system.stdout.write("objj> ").flush();
            var line = READLINE.readline();
            if (line && historyFile)
                historyFile.write(line).write("\n").flush();
            var result = exports.objj_eval(line);
            if (result !== undefined)
                print(result);
        } catch (e) {
            print(e);
        }
        require("browser/timeout").serviceTimeouts();
    }
}
exports.objj_eval = function( aString)
{
    Executable.setCommonJSArguments(require, exports, module, system, print, window);
    var executable = preprocess(aString, "", 0);
    if (!executable.hasLoadedFileDependencies())
        executable.loadFileDependencies();
    var code = executable._code;
    global.objj_executeFile = Executable.fileExecuterForPath(FILE.cwd());
    global.objj_importFile = Executable.fileImporterForPath(FILE.cwd());
    if (typeof system !== "undefined" && system.engine === "rhino")
        return Packages.org.mozilla.javascript.Context.getCurrentContext().evaluateString(global, code, "objj_eval", 0, NULL);
    return eval(code);
}
Executable.setCommonJSParameters("require", "exports", "module", "system", "print", "window");
exports.make_narwhal_factory = function(path)
{
    return function(require, exports, module, system, print)
    {
        Executable.setCommonJSArguments(require, exports, module, system, print, window);
        Executable.fileImporterForPath(FILE.dirname(path))(path, function()
        {
            print("all done");
        });
    }
}
}
if (require.main == module.id)
    exports.run(system.args);
