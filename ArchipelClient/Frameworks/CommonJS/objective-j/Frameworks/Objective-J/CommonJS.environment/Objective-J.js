/*
 * Objective-J.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

var NO = false,
    YES = true,
    nil = null,
    Nil = null,
    NULL = null,
    ABS = Math.abs,
    ASIN = Math.asin,
    ACOS = Math.acos,
    ATAN = Math.atan,
    ATAN2 = Math.atan2,
    SIN = Math.sin,
    COS = Math.cos,
    TAN = Math.tan,
    EXP = Math.exp,
    POW = Math.pow,
    CEIL = Math.ceil,
    FLOOR = Math.floor,
    ROUND = Math.round,
    MIN = Math.min,
    MAX = Math.max,
    RAND = Math.random,
    SQRT = Math.sqrt,
    E = Math.E,
    LN2 = Math.LN2,
    LN10 = Math.LN10,
    LOG2E = Math.LOG2E,
    LOG10E = Math.LOG10E,
    PI = Math.PI,
    PI2 = Math.PI * 2.0,
    PI_2 = Math.PI / 2.0,
    SQRT1_2 = Math.SQRT1_2,
    SQRT2 = Math.SQRT2;
window.setNativeTimeout = window.setTimeout;
window.clearNativeTimeout = window.clearTimeout;
window.setNativeInterval = window.setInterval;
window.clearNativeInterval = window.clearInterval;
var objj_continue_alerting = NO;
function objj_alert(aString)
{
    if (!objj_continue_alerting)
        return;
    objj_continue_alerting = confirm(aString + "\n\nClick cancel to prevent further alerts.");
}
function objj_fprintf(stream, string)
{
    stream(string);
}
function objj_printf(string)
{
    objj_fprintf(alert, string);
}
if (window.console && window.console.warn)
    var warning_stream = function(aString) { window.console.warn(aString); }
else
    var warning_stream = function(){};
var _sprintfFormatRegex = new RegExp("([^%]+|%[\\+\\-\\ \\#0]*[0-9\\*]*(.[0-9\\*]+)?[hlL]?[cbBdieEfgGosuxXpn%@])", "g");
var _sprintfTagRegex = new RegExp("(%)([\\+\\-\\ \\#0]*)([0-9\\*]*)((.[0-9\\*]+)?)([hlL]?)([cbBdieEfgGosuxXpn%@])");
function sprintf(format)
{
    var format = arguments[0],
        tokens = format.match(_sprintfFormatRegex),
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
            var subtokens = t.match(_sprintfTagRegex);
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
                    subresult = _sprintf_justify(sign, "", number, "", width, leftJustify, padZeros)
                }
                if (specifier == "f")
                {
                    var number = String((precision != null) ? Math.abs(num).toFixed(precision) : Math.abs(num));
                    var suffix = (flags.indexOf("#") >= 0 && number.indexOf(".") < 0) ? "." : "";
                    subresult = _sprintf_justify(sign, "", number, suffix, width, leftJustify, padZeros);
                }
                if (specifier == "e" || specifier == "E")
                {
                    var number = String(Math.abs(num).toExponential(precision != null ? precision : 21));
                    var suffix = (flags.indexOf("#") >= 0 && number.indexOf(".") < 0) ? "." : "";
                    subresult = _sprintf_justify(sign, "", number, suffix, width, leftJustify, padZeros);
                }
                if (specifier == "x" || specifier == "X")
                {
                    var number = String(Math.abs(num).toString(16));
                    var prefix = (flags.indexOf("#") >= 0 && num != 0) ? "0x" : "";
                    subresult = _sprintf_justify(sign, prefix, number, "", width, leftJustify, padZeros);
                }
                if (specifier == "b" || specifier == "B")
                {
                    var number = String(Math.abs(num).toString(2));
                    var prefix = (flags.indexOf("#") >= 0 && num != 0) ? "0b" : "";
                    subresult = _sprintf_justify(sign, prefix, number, "", width, leftJustify, padZeros);
                }
                if (specifier == "o")
                {
                    var number = String(Math.abs(num).toString(8));
                    var prefix = (flags.indexOf("#") >= 0 && num != 0) ? "0" : "";
                    subresult = _sprintf_justify(sign, prefix, number, "", width, leftJustify, padZeros);
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
                subresult = _sprintf_justify("", "", subresult, "", width, leftJustify, false);
            }
            result += subresult;
        }
    }
    return result;
}
var _sprintf_justify = function(sign, prefix, string, suffix, width, leftJustify, padZeros)
{
    var length = (sign.length + prefix.length + string.length + suffix.length);
    if (leftJustify)
    {
        return sign + prefix + string + suffix + _sprintf_pad(width - length, " ");
    }
    else
    {
        if (padZeros)
            return sign + prefix + _sprintf_pad(width - length, "0") + string + suffix;
        else
            return _sprintf_pad(width - length, " ") + sign + prefix + string + suffix;
    }
}
var _sprintf_pad = function(n, ch)
{
    return Array(MAX(0,n)+1).join(ch);
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
function bytes_to_string(bytes)
{
    return String.fromCharCode.apply(null, bytes);
}
function base64_encode_string(input)
{
    var temp = [];
    for (var i = 0; i < input.length; i++)
        temp.push(input.charCodeAt(i));
    return base64_encode_array(temp);
}
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
    var cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        gap,
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
var CLS_CLASS = 0x1,
    CLS_META = 0x2,
    CLS_INITIALIZED = 0x4,
    CLS_INITIALIZING = 0x8;
function objj_ivar( aName, aType)
{
    this.name = aName;
    this.type = aType;
}
function objj_method( aName, anImplementation, types)
{
    this.name = aName;
    this.method_imp = anImplementation;
    this.types = types;
}
function objj_class()
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
    this.__address = -1;
}
function objj_object()
{
    this.isa = NULL;
    this.__address = -1;
}
var OBJECT_COUNT = 0;
function _objj_generateObjectHash()
{
    return OBJECT_COUNT++;
}
function class_getName( aClass)
{
    if (aClass == Nil)
        return "";
    return aClass.name;
}
function class_isMetaClass( aClass)
{
    if (!aClass)
        return NO;
    return ((aClass.info & (CLS_META)));
}
function class_getSuperclass( aClass)
{
    if (aClass == Nil)
        return Nil;
    return aClass.super_class;
}
function class_setSuperclass( aClass, aSuperClass)
{
}
function class_isMetaClass( aClass)
{
    return ((aClass.info & (CLS_META)));
}
function class_addIvar( aClass, aName, aType)
{
    var thePrototype = aClass.allocator.prototype;
    if (typeof thePrototype[aName] != "undefined")
        return NO;
    aClass.ivars.push(new objj_ivar(aName, aType));
    thePrototype[aName] = NULL;
    return YES;
}
function class_addIvars( aClass, ivars)
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
function class_copyIvarList( aClass)
{
    return aClass.ivars.slice(0);
}
function class_addMethod( aClass, aName, anImplementation, types)
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
function class_addMethods( aClass, methods)
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
function class_getInstanceMethod( aClass, aSelector)
{
    if (!aClass || !aSelector)
        return NULL;
    var method = aClass.method_dtable[aSelector];
    return method ? method : NULL;
}
function class_getClassMethod( aClass, aSelector)
{
    if (!aClass || !aSelector)
        return NULL;
    var method = (((aClass.info & (CLS_META))) ? aClass : aClass.isa).method_dtable[aSelector];
    return method ? method : NULL;
}
function class_copyMethodList( aClass)
{
    return aClass.method_list.slice(0);
}
function class_replaceMethod( aClass, aSelector, aMethodImplementation)
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
function class_getMethodImplementation( aClass, aSelector)
{
    if (!((((aClass.info & (CLS_META))) ? aClass : aClass.isa).info & (CLS_INITIALIZED))) _class_initialize(aClass); var method = aClass.method_dtable[aSelector]; if (!method) method = _objj_forward; var implementation = method.method_imp;;
    return implementation;
}
var GLOBAL_NAMESPACE = window,
    REGISTERED_CLASSES = {};
function objj_allocateClassPair( superclass, aName)
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
    classObject.__address = (OBJECT_COUNT++);
    metaClassObject.isa = rootClassObject.isa;
    metaClassObject.name = aName;
    metaClassObject.info = CLS_META;
    metaClassObject.__address = (OBJECT_COUNT++);
    return classObject;
}
function objj_registerClassPair( aClass)
{
    GLOBAL_NAMESPACE[aClass.name] = aClass;
    REGISTERED_CLASSES[aClass.name] = aClass;
}
function class_createInstance( aClass)
{
    if (!aClass)
        objj_exception_throw(new objj_exception(OBJJNilClassException, "*** Attempting to create object with Nil class."));
    var object = new aClass.allocator;
    object.__address = (OBJECT_COUNT++);
    object.isa = aClass;
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
function object_getClassName( anObject)
{
    if (!anObject)
        return "";
    var theClass = anObject.isa;
    return theClass ? class_getName(theClass) : "";
}
function objj_lookUpClass( aName)
{
    var theClass = REGISTERED_CLASSES[aName];
    return theClass ? theClass : Nil;
}
function objj_getClass( aName)
{
    var theClass = REGISTERED_CLASSES[aName];
    if (!theClass)
    {
    }
    return theClass ? theClass : Nil;
}
function objj_getMetaClass( aName)
{
    var theClass = objj_getClass(aName);
    return (((theClass.info & (CLS_META))) ? theClass : theClass.isa);
}
function ivar_getName(anIvar)
{
    return anIvar.name;
}
function ivar_getTypeEncoding(anIvar)
{
    return anIvar.type;
}
function objj_msgSend( aReceiver, aSelector)
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
function objj_msgSendSuper( aSuper, aSelector)
{
    var super_class = aSuper.super_class;
    arguments[0] = aSuper.receiver;
    if (!((((super_class.info & (CLS_META))) ? super_class : super_class.isa).info & (CLS_INITIALIZED))) _class_initialize(super_class); var method = super_class.method_dtable[aSelector]; if (!method) method = _objj_forward; var implementation = method.method_imp;;
    return implementation.apply(aSuper.receiver, arguments);
}
function method_getName( aMethod)
{
    return aMethod.name;
}
function method_getImplementation( aMethod)
{
    return aMethod.method_imp;
}
function method_setImplementation( aMethod, anImplementation)
{
    var oldImplementation = aMethod.method_imp;
    aMethod.method_imp = anImplementation;
    return oldImplementation;
}
function method_exchangeImplementations( lhs, rhs)
{
    var lhs_imp = method_getImplementation(lhs),
        rhs_imp = method_getImplementation(rhs);
    method_setImplementation(lhs, rhs_imp);
    method_setImplementation(rhs, lhs_imp);
}
function sel_getName(aSelector)
{
    return aSelector ? aSelector : "<null selector>";
}
function sel_getUid( aName)
{
    return aName;
}
function sel_isEqual( lhs, rhs)
{
    return lhs === rhs;
}
function sel_registerName(aName)
{
    return aName;
}
function objj_dictionary()
{
    this._keys = [];
    this.count = 0;
    this._buckets = {};
    this.__address = (OBJECT_COUNT++);
}
objj_dictionary.prototype.containsKey = function(aKey) { return dictionary_containsKey(this, aKey); }
objj_dictionary.prototype.getCount = function() { return dictionary_getCount(this); }
objj_dictionary.prototype.getValue = function(aKey) { return dictionary_getValue(this, aKey); }
objj_dictionary.prototype.setValue = function(aKey, aValue) { return dictionary_setValue(this, aKey, aValue); }
objj_dictionary.prototype.removeValue = function(aKey) { return dictionary_removeValue(this, aKey); }
function dictionary_containsKey(aDictionary, aKey)
{
    return aDictionary._buckets[aKey] != NULL;
}
function dictionary_getCount(aDictionary)
{
    return aDictionary.count;
}
function dictionary_getValue(aDictionary, aKey)
{
    return aDictionary._buckets[aKey];
}
function dictionary_setValue(aDictionary, aKey, aValue)
{
    if (aDictionary._buckets[aKey] == NULL)
    {
        aDictionary._keys.push(aKey);
        ++aDictionary.count;
    }
    if ((aDictionary._buckets[aKey] = aValue) == NULL)
        --aDictionary.count;
}
function dictionary_removeValue(aDictionary, aKey)
{
    if (aDictionary._buckets[aKey] == NULL)
        return;
    --aDictionary.count;
    if (aDictionary._keys.indexOf)
        aDictionary._keys.splice(aDictionary._keys.indexOf(aKey), 1);
    else
    {
        var keys = aDictionary._keys,
            index = 0,
            count = keys.length;
        for (; index < count; ++index)
            if (keys[index] == aKey)
            {
                keys.splice(index, 1);
                break;
            }
    }
    delete aDictionary._buckets[aKey];
}
function dictionary_replaceValue(aDictionary, aKey, aValue)
{
    if (aDictionary[aKey] == NULL)
        return;
}
function dictionary_description(aDictionary)
{
    var str = "{ ";
    for ( x in aDictionary._buckets)
        str += x + ":" + aDictionary._buckets[x] + ",";
    str += " }";
    return str;
}
var kCFPropertyListOpenStepFormat = 1,
    kCFPropertyListXMLFormat_v1_0 = 100,
    kCFPropertyListBinaryFormat_v1_0 = 200,
    kCFPropertyList280NorthFormat_v1_0 = -1000;
var OBJJPlistParseException = "OBJJPlistParseException",
    OBJJPlistSerializeException = "OBJJPlistSerializeException";
var kCFPropertyList280NorthMagicNumber = "280NPLIST";
function objj_data()
{
    this.string = "";
    this._plistObject = NULL;
    this.bytes = NULL;
    this.base64 = NULL;
}
var objj_markedStream = function(aString)
{
    var index = aString.indexOf(';');
    this._magicNumber = aString.substr(0, index);
    this._location = aString.indexOf(';', ++index);
    this._version = aString.substring(index, this._location++);
    this._string = aString;
}
objj_markedStream.prototype.magicNumber = function()
{
    return this._magicNumber;
}
objj_markedStream.prototype.version = function()
{
    return this._version;
}
objj_markedStream.prototype.getMarker = function()
{
    var string = this._string,
        location = this._location;
    if (location >= string.length)
        return NULL;
    var next = string.indexOf(';', location);
    if (next < 0)
        return NULL;
    var marker = string.substring(location, next);
    if (marker === 'e')
        return NULL;
    this._location = next + 1;
    return marker;
}
objj_markedStream.prototype.getString = function()
{
    var string = this._string,
        location = this._location;
    if (location >= string.length)
        return NULL;
    var next = string.indexOf(';', location);
    if (next < 0)
        return NULL;
    var size = parseInt(string.substring(location, next)),
        text = string.substr(next + 1, size);
    this._location = next + 1 + size;
    return text;
}
function CPPropertyListCreateData(aPlistObject, aFormat)
{
    if (aFormat == kCFPropertyListXMLFormat_v1_0)
        return CPPropertyListCreateXMLData(aPlistObject);
    if (aFormat == kCFPropertyList280NorthFormat_v1_0)
        return CPPropertyListCreate280NorthData(aPlistObject);
    return NULL;
}
function CPPropertyListCreateFromData(aData, aFormat)
{
    if (!aFormat)
    {
        if (aData instanceof objj_data)
        {
            var string = aData.string ? aData.string : objj_msgSend(aData, "string");
            if (string.substr(0, kCFPropertyList280NorthMagicNumber.length) == kCFPropertyList280NorthMagicNumber)
                aFormat = kCFPropertyList280NorthFormat_v1_0;
            else
                aFormat = kCFPropertyListXMLFormat_v1_0;
        }
        else
            aFormat = kCFPropertyListXMLFormat_v1_0;
    }
    if (aFormat == kCFPropertyListXMLFormat_v1_0)
        return CPPropertyListCreateFromXMLData(aData);
    if (aFormat == kCFPropertyList280NorthFormat_v1_0)
        return CPPropertyListCreateFrom280NorthData(aData);
    return NULL;
}
var _CPPropertyListSerializeObject = function(aPlist, serializers)
{
    var type = typeof aPlist,
        valueOf = aPlist.valueOf(),
        typeValueOf = typeof valueOf;
    if (type != typeValueOf)
    {
        type = typeValueOf;
        aPlist = valueOf;
    }
    if (type == "string")
        return serializers["string"](aPlist, serializers);
    else if (aPlist === true || aPlist === false)
        return serializers["boolean"](aPlist, serializers);
    else if (type == "number")
    {
        var integer = FLOOR(aPlist);
        if (integer == aPlist)
            return serializers["integer"](aPlist, serializers);
        else
            return serializers["real"](aPlist, serializers);
    }
    else if (aPlist.slice)
        return serializers["array"](aPlist, serializers);
    else
        return serializers["dictionary"](aPlist, serializers);
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
    node = (node.firstChild); if (node != NULL && ((node.nodeType) == 8 || (node.nodeType) == 3)) while ((node = (node.nextSibling)) && ((node.nodeType) == 8 || (node.nodeType) == 3)) ;;
    if (node)
        return node;
    if ((String(anXMLNode.nodeName)) == PLIST_ARRAY || (String(anXMLNode.nodeName)) == PLIST_DICTIONARY)
        stack.pop();
    else
    {
        if (node == stayWithin)
            return NULL;
        node = anXMLNode;
        while ((node = (node.nextSibling)) && ((node.nodeType) == 8 || (node.nodeType) == 3)) ;;
        if (node)
            return node;
    }
    node = anXMLNode;
    while (node)
    {
        var next = node;
        while ((next = (next.nextSibling)) && ((next.nodeType) == 8 || (next.nodeType) == 3)) ;;
        if (next)
            return next;
        var node = (node.parentNode);
        if (stayWithin && node == stayWithin)
            return NULL;
        stack.pop();
    }
    return NULL;
}
function CPPropertyListCreateFromXMLData(XMLNodeOrData)
{
    var XMLNode = XMLNodeOrData;
    if (XMLNode.string)
    {
        if (window.ActiveXObject)
        {
            XMLNode = new ActiveXObject("Microsoft.XMLDOM");
            XMLNode.loadXML(XMLNodeOrData.string.substr(XMLNodeOrData.string.indexOf(".dtd\">") + 6));
        }
        else
            XMLNode = (new DOMParser().parseFromString(XMLNodeOrData.string, "text/xml").documentElement);
    }
    while (((String(XMLNode.nodeName)) == XML_DOCUMENT) || ((String(XMLNode.nodeName)) == XML_XML))
        XMLNode = (XMLNode.firstChild); if (XMLNode != NULL && ((XMLNode.nodeType) == 8 || (XMLNode.nodeType) == 3)) while ((XMLNode = (XMLNode.nextSibling)) && ((XMLNode.nodeType) == 8 || (XMLNode.nodeType) == 3)) ;;
    if (((XMLNode.nodeType) == 10))
        while ((XMLNode = (XMLNode.nextSibling)) && ((XMLNode.nodeType) == 8 || (XMLNode.nodeType) == 3)) ;;
    if (!((String(XMLNode.nodeName)) == PLIST_PLIST))
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
        if ((String(XMLNode.nodeName)) == PLIST_KEY)
        {
            key = ((String((XMLNode.firstChild).nodeValue)));
            while ((XMLNode = (XMLNode.nextSibling)) && ((XMLNode.nodeType) == 8 || (XMLNode.nodeType) == 3)) ;;
        }
        switch (String((String(XMLNode.nodeName))))
        {
            case PLIST_ARRAY: object = []
                                        containers.push(object);
                                        break;
            case PLIST_DICTIONARY: object = new objj_dictionary();
                                        containers.push(object);
                                        break;
            case PLIST_NUMBER_REAL: object = parseFloat(((String((XMLNode.firstChild).nodeValue))));
                                        break;
            case PLIST_NUMBER_INTEGER: object = parseInt(((String((XMLNode.firstChild).nodeValue))));
                                        break;
            case PLIST_STRING: object = _decodeHTMLComponent((XMLNode.firstChild) ? ((String((XMLNode.firstChild).nodeValue))) : "");
                                        break;
            case PLIST_BOOLEAN_TRUE: object = true;
                                        break;
            case PLIST_BOOLEAN_FALSE: object = false;
                                        break;
            case PLIST_DATA: object = new objj_data();
                                        object.bytes = (XMLNode.firstChild) ? base64_decode_to_array(((String((XMLNode.firstChild).nodeValue))), true) : [];
                                        break;
            default: objj_exception_throw(new objj_exception(OBJJPlistParseException, "*** " + (String(XMLNode.nodeName)) + " tag not recognized in Plist."));
        }
        if (!plistObject)
            plistObject = object;
        else if (currentContainer)
            if (currentContainer.slice)
                currentContainer.push(object);
            else
                { if ((currentContainer)._buckets[key] == NULL) { (currentContainer)._keys.push(key); ++(currentContainer).count; } if (((currentContainer)._buckets[key] = object) == NULL) --(currentContainer).count;};
    }
    return plistObject;
}
function CPPropertyListCreateXMLData(aPlist)
{
    var data = new objj_data();
    data.string = "";
    data.string += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
    data.string += "<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">";
    data.string += "<plist version = \"1.0\">";
    _CPPropertyListAppendXMLData(data, aPlist, "");
    data.string += "</plist>";
    return data;
}
var _CPArrayAppendXMLData = function(XMLData, anArray)
{
    var i = 0,
        count = anArray.length;
    XMLData.string += "<array>";
    for (; i < count; ++i)
        _CPPropertyListAppendXMLData(XMLData, anArray[i]);
    XMLData.string += "</array>";
}
var _CPDictionaryAppendXMLData = function(XMLData, aDictionary)
{
    var keys = aDictionary._keys,
        i = 0,
        count = keys.length;
    XMLData.string += "<dict>";
    for (; i < count; ++i)
    {
        XMLData.string += "<key>" + keys[i] + "</key>";
        _CPPropertyListAppendXMLData(XMLData, ((aDictionary)._buckets[keys[i]]));
    }
    XMLData.string += "</dict>";
}
var _encodeHTMLComponent = function(aString)
{
    return aString.replace(/&/g,'&amp;').replace(/"/g, '&quot;').replace(/'/g, '&apos;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}
var _decodeHTMLComponent = function(aString)
{
    return aString.replace(/&quot;/g, '"').replace(/&apos;/g, '\'').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&');
}
var _CPPropertyListAppendXMLData = function(XMLData, aPlist)
{
    var type = typeof aPlist,
        valueOf = aPlist.valueOf(),
        typeValueOf = typeof valueOf;
    if (type != typeValueOf)
    {
        type = typeValueOf;
        aPlist = valueOf;
    }
    if (type == "string")
        XMLData.string += "<string>" + _encodeHTMLComponent(aPlist) + "</string>";
    else if (aPlist === true)
        XMLData.string += "<true/>";
    else if (aPlist === false)
        XMLData.string += "<false/>";
    else if (type == "number")
    {
        var integer = FLOOR(aPlist);
        if (integer == aPlist)
            XMLData.string += "<integer>" + aPlist + "</integer>";
        else
            XMLData.string += "<real>" + aPlist + "</real>";
    }
    else if (aPlist.slice)
        _CPArrayAppendXMLData(XMLData, aPlist);
    else if (aPlist._keys)
        _CPDictionaryAppendXMLData(XMLData, aPlist);
    else
        objj_exception_throw(new objj_exception(OBJJPlistSerializeException, "*** unknown plist ("+aPlist+") type: " + type));
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
function CPPropertyListCreateFrom280NorthData(aData)
{
    var stream = new objj_markedStream(aData.string),
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
            case DICTIONARY_MARKER: object = new objj_dictionary();
                                    containers.push(object);
                                    break;
            case FLOAT_MARKER: object = parseFloat(stream.getString());
                                    break;
            case INTEGER_MARKER: object = parseInt(stream.getString());
                                    break;
            case STRING_MARKER: object = stream.getString();
                                    break;
            case TRUE_MARKER: object = true;
                                    break;
            case FALSE_MARKER: object = false;
                                    break;
            default: objj_exception_throw(new objj_exception(OBJJPlistParseException, "*** " + marker + " marker not recognized in Plist."));
        }
        if (!plistObject)
            plistObject = object;
        else if (currentContainer)
            if (currentContainer.slice)
                currentContainer.push(object);
            else
                { if ((currentContainer)._buckets[key] == NULL) { (currentContainer)._keys.push(key); ++(currentContainer).count; } if (((currentContainer)._buckets[key] = object) == NULL) --(currentContainer).count;};
    }
    return plistObject;
}
function CPPropertyListCreate280NorthData(aPlist)
{
    var data = new objj_data();
    data.string = kCFPropertyList280NorthMagicNumber + ";1.0;" + _CPPropertyListSerializeObject(aPlist, _CPPropertyList280NorthSerializers);
    return data;
}
var _CPPropertyList280NorthSerializers = {};
_CPPropertyList280NorthSerializers["string"] = function(aString)
{
    return STRING_MARKER + ';' + aString.length + ';' + aString;
}
_CPPropertyList280NorthSerializers["boolean"] = function(aBoolean)
{
    return (aBoolean ? TRUE_MARKER : FALSE_MARKER) + ';';
}
_CPPropertyList280NorthSerializers["integer"] = function(anInteger)
{
    var string = "" + anInteger;
    return INTEGER_MARKER + ';' + string.length + ';' + string;
}
_CPPropertyList280NorthSerializers["real"] = function(aFloat)
{
    var string = "" + aFloat;
    return FLOAT_MARKER + ';' + string.length + ';' + string;
}
_CPPropertyList280NorthSerializers["array"] = function(anArray, serializers)
{
    var index = 0,
        count = anArray.length,
        string = ARRAY_MARKER + ';';
    for (; index < count; ++index)
        string += _CPPropertyListSerializeObject(anArray[index], serializers);
    return string + END_MARKER + ';';
}
_CPPropertyList280NorthSerializers["dictionary"] = function(aDictionary, serializers)
{
    var keys = aDictionary._keys,
        index = 0,
        count = keys.length,
        string = DICTIONARY_MARKER +';';
    for (; index < count; ++index)
    {
        var key = keys[index];
        string += KEY_MARKER + ';' + key.length + ';' + key;
        string += _CPPropertyListSerializeObject(((aDictionary)._buckets[key]), serializers);
    }
    return string + END_MARKER + ';';
}
var OBJJ_ENVIRONMENTS = ["CommonJS", "ObjJ"];
function objj_mostEligibleEnvironmentFromArray(environments)
{
    var index = 0,
        count = OBJJ_ENVIRONMENTS.length,
        innerCount = environments.length;
    for(; index < count; ++index)
    {
        var innerIndex = 0,
            environment = OBJJ_ENVIRONMENTS[index];
        for (; innerIndex < innerCount; ++innerIndex)
            if(environment === environments[innerIndex])
                return environment;
    }
    return NULL;
}
var OBJJFileNotFoundException = "OBJJFileNotFoundException",
    OBJJExecutableNotFoundException = "OBJJExecutableNotFoundException";
var objj_files = { },
    objj_bundles = { },
    objj_bundlesForClass = { },
    objj_searches = { };
var OBJJ_NO_FILE = {};
if (typeof OBJJ_INCLUDE_PATHS === "undefined")
    OBJJ_INCLUDE_PATHS = ["Frameworks", "SomethingElse"];
var OBJJ_BASE_URI = "";
if (window.opera) {
var DOMBaseElement = document.getElementsByTagName("base")[0];
if (DOMBaseElement)
    OBJJ_BASE_URI = (DOMBaseElement.getAttribute('href')).substr(0, (DOMBaseElement.getAttribute('href')).lastIndexOf('/') + 1);
}
function objj_file()
{
    this.path = NULL;
    this.bundle = NULL;
    this.included = NO;
    this.contents = NULL;
    this.fragments = NULL;
}
function objj_bundle()
{
    this.path = NULL;
    this.info = NULL;
    this._URIMap = { };
    this.__address = (OBJECT_COUNT++);
}
function objj_getBundleWithPath(aPath)
{
    return objj_bundles[aPath];
}
function objj_setBundleForPath(aPath, aBundle)
{
    objj_bundles[aPath] = aBundle;
}
function objj_bundleForClass(aClass)
{
    return objj_bundlesForClass[aClass.name];
}
function objj_addClassForBundle(aClass, aBundle)
{
    objj_bundlesForClass[aClass.name] = aBundle;
}
function objj_request_file(aFilePath, shouldSearchLocally, aCallback)
{
    new objj_search(aFilePath, shouldSearchLocally, aCallback).attemptNextSearchPath();
}
var objj_search = function(aFilePath, shouldSearchLocally, aCallback)
{
    this.filePath = aFilePath;
    this.bundle = NULL;
    this.bundleObservers = [];
    this.searchPath = NULL;
    this.searchedPaths = [];
    this.includePathsIndex = shouldSearchLocally ? -1 : 0;
    this.searchRequest = NULL;
    this.didCompleteCallback = aCallback;
}
objj_search.prototype.nextSearchPath = function()
{
    var path = objj_standardize_path((this.includePathsIndex == -1 ? "" : OBJJ_INCLUDE_PATHS[this.includePathsIndex] + '/') + this.filePath);
    ++this.includePathsIndex;
    return path;
}
objj_search.prototype.attemptNextSearchPath = function()
{
    var searchPath = this.nextSearchPath(),
        file = objj_files[searchPath];
    objj_alert("Will attempt to find " + this.filePath + " at " + searchPath);
    if (file)
    {
        objj_alert("The file request at " + this.filePath + " has already been downloaded at " + searchPath);
        var index = 0,
            count = this.searchedPaths.length;
        for (; index < count; ++index)
            objj_files[this.searchedPaths[index]] = file;
        if (this.didCompleteCallback)
            this.didCompleteCallback(file);
        return;
    }
    var existingSearch = objj_searches[searchPath];
    if (existingSearch)
    {
        if (this.didCompleteCallback)
            existingSearch.didCompleteCallback = this.didCompleteCallback;
        return;
    }
    this.searchedPaths.push(this.searchPath = searchPath);
    var infoPath = objj_standardize_path((searchPath).substr(0, (searchPath).lastIndexOf('/') + 1) + "Info.plist"),
        bundle = objj_bundles[infoPath];
    if (bundle)
    {
        this.bundle = bundle;
        this.request(searchPath, this.didReceiveSearchResponse);
    }
    else
    {
        var existingBundleSearch = objj_searches[infoPath];
        if (existingBundleSearch)
        {
            --this.includePathsIndex;
            this.searchedPaths.pop();
             if (this.searchedPaths.length)
                 this.searchPath = this.searchedPaths[this.searchedPaths.length - 1];
             else
                 this.searchPath = NULL;
            existingBundleSearch.bundleObservers.push(this);
            return;
        }
        else
        {
            this.bundleObservers.push(this);
            this.request(infoPath, this.didReceiveBundleResponse);
            if (!this.searchReplaced)
                this.searchRequest = this.request(searchPath, this.didReceiveSearchResponse);
        }
    }
}
if (window.ActiveXObject) {
objj_search.responseCallbackLock = NO;
objj_search.responseCallbackQueue = [];
objj_search.removeResponseCallbackForFilePath = function(aFilePath)
{
    var queue = objj_search.responseCallbackQueue,
        index = queue.length;
    while (index--)
        if (queue[index][3] == aFilePath)
        {
            queue.splice(index, 1);
            return;
        }
}
objj_search.serializeResponseCallback = function(aMethod, aSearch, aResponse, aFilePath)
{
    var queue = objj_search.responseCallbackQueue;
    queue.push([aMethod, aSearch, aResponse, aFilePath]);
    if (objj_search.responseCallbackLock)
        return;
    objj_search.responseCallbackLock = YES;
    while (queue.length)
    {
        var callback = queue[0];
        queue.splice(0, 1);
        callback[0].apply(callback[1], [callback[2]]);
    }
    objj_search.responseCallbackLock = NO;
}
}
objj_search.prototype.request = function(aFilePath, aMethod)
{
    var search = this,
        isPlist = aFilePath.substr(aFilePath.length - 6, 6) == ".plist",
        request = objj_request_xmlhttp(),
        response = objj_response_xmlhttp();
    response.filePath = aFilePath;
    request.onreadystatechange = function()
    {
        if (request.readyState == 4)
        {
            if (response.success = (request.status != 404 && request.responseText && request.responseText.length) ? YES : NO)
            {
                if (window.files_total)
                {
                    if (!window.files_loaded)
                        window.files_loaded = 0;
                    window.files_loaded += request.responseText.length;
                    if (window.update_progress)
                        window.update_progress(window.files_loaded / window.files_total);
                }
                if (isPlist)
                    response.xml = objj_standardize_xml(request);
                else
                    response.text = request.responseText;
            }
            if (window.ActiveXObject)
                objj_search.serializeResponseCallback(aMethod, search, response, aFilePath);
            else
                aMethod.apply(search, [response]);
        }
    }
    objj_searches[aFilePath] = this;
    if (request.overrideMimeType && isPlist)
        request.overrideMimeType('text/xml');
    if (window.opera && aFilePath.charAt(0) != '/')
        aFilePath = OBJJ_BASE_URI + aFilePath;
    try
    {
        request.open("GET", aFilePath, YES);
        request.send("");
    }
    catch (anException)
    {
        response.success = NO;
        if (window.ActiveXObject)
            objj_search.serializeResponseCallback(aMethod, search, response, aFilePath);
        else
            aMethod.apply(search, [response]);
    }
    return request;
}
objj_search.prototype.didReceiveSearchResponse = function(aResponse)
{
    if (!this.bundle)
    {
        this.cachedSearchResponse = aResponse;
        return;
    }
    if (aResponse.success)
    {
        file = new objj_file();
        file.path = aResponse.filePath;
        file.bundle = this.bundle
        file.contents = aResponse.text;
        this.complete(file);
    }
    else if (this.includePathsIndex < OBJJ_INCLUDE_PATHS.length)
    {
        this.bundle = NULL;
        this.attemptNextSearchPath();
    }
    else
        objj_exception_throw(new objj_exception(OBJJFileNotFoundException, "*** Could not locate file named \"" + this.filePath + "\" in search paths."));
}
objj_search.prototype.didReceiveBundleResponse = function(aResponse)
{
    var bundle = new objj_bundle();
    bundle.path = aResponse.filePath;
    if (aResponse.success)
        bundle.info = CPPropertyListCreateFromXMLData(aResponse.xml);
    else
        bundle.info = new objj_dictionary();
    objj_bundles[aResponse.filePath] = bundle;
    var executablePath = ((bundle.info)._buckets["CPBundleExecutable"]);
    if (executablePath)
    {
        var environment = objj_mostEligibleEnvironmentFromArray(((bundle.info)._buckets["CPBundleEnvironments"]));
        executablePath = environment + ".environment/" + executablePath;
        this.request((aResponse.filePath).substr(0, (aResponse.filePath).lastIndexOf('/') + 1) + executablePath, this.didReceiveExecutableResponse);
        var directory = (aResponse.filePath).substr(0, (aResponse.filePath).lastIndexOf('/') + 1),
            replacedFiles = ((((bundle.info)._buckets["CPBundleReplacedFiles"]))._buckets[environment]),
            index = 0,
            count = replacedFiles.length;
        for (; index < count; ++index)
        {
            objj_searches[directory + replacedFiles[index]] = this;
            if (directory + replacedFiles[index] == this.searchPath)
            {
                this.searchReplaced = YES;
                if (!this.cachedSearchResponse && this.searchRequest)
                    this.searchRequest.abort();
                if (window.ActiveXObject)
                    objj_search.removeResponseCallbackForFilePath(this.searchPath);
            }
        }
    }
    this.bundle = bundle;
    var observers = this.bundleObservers,
        index = 0,
        count = observers.length;
    for(; index < count; ++index)
    {
        var observer = observers[index];
        if (observer != this)
            observer.attemptNextSearchPath();
        else if (this.cachedSearchResponse && !this.searchReplaced)
            this.didReceiveSearchResponse(this.cachedSearchResponse);
    }
    this.bundleObservers = [];
}
objj_search.prototype.didReceiveExecutableResponse = function(aResponse)
{
    if (!aResponse.success)
        objj_exception_throw(new objj_exception(OBJJExecutableNotFoundException, "*** The specified executable could not be located at \"" + this.filePath + "\"."));
    var files = objj_decompile(aResponse.text, this.bundle),
        index = 0,
        count = files.length,
        length = this.filePath.length;
    for (; index < count; ++index)
    {
        var file = files[index],
            path = file.path;
        if (this.filePath == path.substr(path.length - length))
            this.complete(file);
        else
            objj_files[path] = file;
    }
}
objj_search.prototype.complete = function(aFile)
{
    var index = 0,
        count = this.searchedPaths.length;
    for (; index < count; ++index)
    {
        objj_files[this.searchedPaths[index]] = aFile;
    }
    if (this.didCompleteCallback)
        this.didCompleteCallback(aFile);
}
function objj_standardize_path(aPath)
{
    if (aPath.indexOf("/./") != -1 && aPath.indexOf("//") != -1 && aPath.indexOf("/../") != -1)
        return aPath;
    var index = 0,
        components = aPath.split('/');
    for(;index < components.length; ++index)
        if(components[index] == "..")
        {
            components.splice(index - 1, 2);
            index -= 2;
        }
        else if(index != 0 && !components[index].length || components[index] == '.' || components[index] == "..")
            components.splice(index--, 1);
    return components.join('/');
}
if (window.ActiveXObject) {
var objj_standardize_xml = function(aRequest)
{
    var XMLData = new ActiveXObject("Microsoft.XMLDOM");
    XMLData.loadXML(aRequest.responseText.substr(aRequest.responseText.indexOf(".dtd\">") + 6));
    return XMLData;
}
} else {
var objj_standardize_xml = function(aRequest)
{
    return aRequest.responseXML;
}
}
function objj_response_xmlhttp()
{
    return new Object;
}
if (window.XMLHttpRequest) {
var objj_request_xmlhttp = function()
{
    return new XMLHttpRequest();
}
} else if (window.ActiveXObject) {
var MSXML_XMLHTTP_OBJECTS = [ "Microsoft.XMLHTTP", "Msxml2.XMLHTTP", "Msxml2.XMLHTTP.3.0", "Msxml2.XMLHTTP.6.0" ],
    index = MSXML_XMLHTTP_OBJECTS.length;
while (index--)
{
    try
    {
        new ActiveXObject(MSXML_XMLHTTP_OBJECTS[index]);
        break;
    }
    catch (anException)
    {
    }
}
var MSXML_XMLHTTP = MSXML_XMLHTTP_OBJECTS[index];
delete index;
delete MSXML_XMLHTTP_OBJECTS;
var objj_request_xmlhttp = function()
{
    return new ActiveXObject(MSXML_XMLHTTP);
}
}
var OBJJUnrecognizedFormatException = "OBJJUnrecognizedFormatException";
var STATIC_MAGIC_NUMBER = "@STATIC",
    MARKER_PATH = "p",
    MARKER_URI = "u",
    MARKER_CODE = "c",
    MARKER_BUNDLE = "b",
    MARKER_TEXT = "t",
    MARKER_IMPORT_STD = 'I',
    MARKER_IMPORT_LOCAL = 'i';
var STATIC_EXTENSION = "sj";
function objj_decompile(aString, bundle)
{
    var stream = new objj_markedStream(aString);
    if (stream.magicNumber() != STATIC_MAGIC_NUMBER)
        objj_exception_throw(new objj_exception(OBJJUnrecognizedFormatException, "*** Could not recognize executable code format in bundle: "+bundle));
    if (stream.version() != 1.0)
        objj_exception_throw(new objj_exception(OBJJUnrecognizedFormatException, "*** Could not recognize executable code format in bundle: "+bundle));
    var file = NULL,
        files = [],
        marker;
    while (marker = stream.getMarker())
    {
        var text = stream.getString();
        switch (marker)
        {
            case MARKER_PATH: if (file && file.contents && file.path === file.bundle.path)
                                            file.bundle.info = CPPropertyListCreateWithData({string:file.contents});
                                        file = new objj_file();
                                        file.path = (bundle.path).substr(0, (bundle.path).lastIndexOf('/') + 1) + text;
                                        file.bundle = bundle;
                                        file.fragments = [];
                                        files.push(file);
                                        objj_files[file.path] = file;
                                        break;
            case MARKER_URI: var URI = stream.getString();
                                        if (URI.toLowerCase().indexOf("mhtml:") === 0)
                                            URI = "mhtml:" + (window.location.href).substr(0, (window.location.href).lastIndexOf('/') + 1) + '/' + (bundle.path).substr(0, (bundle.path).lastIndexOf('/') + 1) + '/' + URI.substr("mhtml:".length);
                                        bundle._URIMap[text] = URI;
                                        break;
            case MARKER_BUNDLE: var bundlePath = (bundle.path).substr(0, (bundle.path).lastIndexOf('/') + 1) + '/' + text;
                                        file.bundle = objj_getBundleWithPath(bundlePath);
                                        if (!file.bundle)
                                        {
                                            file.bundle = new objj_bundle();
                                            file.bundle.path = bundlePath;
                                            objj_setBundleForPath(file.bundle, bundlePath);
                                        }
                                        break;
            case MARKER_TEXT: file.contents = text;
                                        break;
            case MARKER_CODE: file.fragments.push(fragment_create_code(text, bundle, file));
                                        break;
            case MARKER_IMPORT_STD: file.fragments.push(fragment_create_file(text, bundle, NO, file));
                                        break;
            case MARKER_IMPORT_LOCAL: file.fragments.push(fragment_create_file(text, bundle, YES, file));
                                        break;
        }
    }
    if (file && file.contents && file.path === file.bundle.path)
        file.bundle.info = CPPropertyListCreateWithData({string:file.contents});
    return files;
}
var OBJJ_EXCEPTION_OUTPUT_STREAM = NULL;
function objj_exception(aName, aReason, aUserInfo)
{
    this.name = aName;
    this.message = aReason;
    this.userInfo = aUserInfo;
    this.__address = (OBJECT_COUNT++);
    if (typeof Packages !== "undefined" && Packages && Packages.org)
        this.rhinoException = Packages.org.mozilla.javascript.JavaScriptException(this, null, 0);
}
objj_exception.prototype = new Error();
function objj_exception_throw(anException)
{
    throw anException;
}
function objj_exception_report(anException, aSourceFile)
{
    objj_fprintf(OBJJ_EXCEPTION_OUTPUT_STREAM, aSourceFile.path + "\n" + anException);
    throw anException;
}
function objj_exception_setOutputStream(aStream)
{
    OBJJ_EXCEPTION_OUTPUT_STREAM = aStream;
}
objj_exception_setOutputStream(warning_stream);
var OBJJ_PREPROCESSOR_DEBUG_SYMBOLS = 1 << 0,
    OBJJ_PREPROCESSOR_TYPE_SIGNATURES = 1 << 1;
function objj_preprocess( aString, aBundle, aSourceFile, flags)
{
    try
    {
        return new objj_preprocessor(aString.replace(/^#[^\n]+\n/, "\n"), aSourceFile, aBundle, flags).fragments();
    }
    catch (anException)
    {
        objj_exception_report(anException, aSourceFile);
    }
    return [];
}
var OBJJParseException = "OBJJParseException",
    OBJJClassNotFoundException = "OBJJClassNotFoundException";
var TOKEN_ACCESSORS = "accessors",
    TOKEN_CLASS = "class",
    TOKEN_END = "end",
    TOKEN_FUNCTION = "function",
    TOKEN_IMPLEMENTATION = "implementation",
    TOKEN_IMPORT = "import",
    TOKEN_NEW = "new",
    TOKEN_SELECTOR = "selector",
    TOKEN_SUPER = "super",
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
var SUPER_CLASSES = new objj_dictionary();
var OBJJ_CURRENT_BUNDLE = NULL;
var objj_lexer = function(aString)
{
    this._index = -1;
    this._tokens = (aString + '\n').match(/\/\/.*(\r|\n)?|\/\*(?:.|\n|\r)*?\*\/|\w+\b|[+-]?\d+(([.]\d+)*([eE][+-]?\d+))?|"[^"\\]*(\\[\s\S][^"\\]*)*"|'[^'\\]*(\\[\s\S][^'\\]*)*'|\s+|./g);
    this._context = [];
    return this;
}
objj_lexer.prototype.push = function()
{
    this._context.push(this._index);
}
objj_lexer.prototype.pop = function()
{
    this._index = this._context.pop();
}
objj_lexer.prototype.peak = function(shouldSkipWhitespace)
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
objj_lexer.prototype.next = function()
{
    return this._tokens[++this._index];
}
objj_lexer.prototype.previous = function()
{
    return this._tokens[--this._index];
}
objj_lexer.prototype.last = function()
{
    if (this._index < 0)
        return NULL;
    return this._tokens[this._index - 1];
}
objj_lexer.prototype.skip_whitespace= function(shouldMoveBackwards)
{
    var token;
    if (shouldMoveBackwards)
        while((token = this.previous()) && TOKEN_WHITESPACE.test(token)) ;
    else
        while((token = this.next()) && TOKEN_WHITESPACE.test(token)) ;
    return token;
}
var objj_stringBuffer = function()
{
    this.atoms = [];
}
objj_stringBuffer.prototype.toString = function()
{
    return this.atoms.join("");
}
objj_stringBuffer.prototype.clear = function()
{
    this.atoms = [];
}
objj_stringBuffer.prototype.isEmpty = function()
{
    return (this.atoms.length === 0);
}
var objj_preprocessor = function(aString, aSourceFile, aBundle, flags)
{
    this._currentSelector = "";
    this._currentClass = "";
    this._currentSuperClass = "";
    this._currentSuperMetaClass = "";
    this._file = aSourceFile;
    this._fragments = [];
    this._preprocessed = new objj_stringBuffer();
    this._tokens = new objj_lexer(aString);
    this._flags = flags;
    this._bundle = aBundle;
    this._classMethod = false;
    this.preprocess(this._tokens, this._preprocessed);
    this.fragment();
}
objj_preprocessor.prototype.fragments = function()
{
    return this._fragments;
}
objj_preprocessor.prototype.accessors = function(tokens)
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
            objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** @property attribute name not valid.")));
        if ((token = tokens.skip_whitespace()) == TOKEN_EQUAL)
        {
            value = tokens.skip_whitespace();
            if (!/^\w+$/.test(value))
                objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** @property attribute value not valid.")));
            if (name == "setter")
            {
                if ((token = tokens.next()) != TOKEN_COLON)
                    objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** @property setter attribute requires argument with \":\" at end of selector name.")));
                value += ":";
            }
            token = tokens.skip_whitespace();
        }
        attributes[name] = value;
        if (token == TOKEN_CLOSE_PARENTHESIS)
            break;
        if (token != TOKEN_COMMA)
            objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Expected ',' or ')' in @property attribute list.")));
    }
    return attributes;
}
objj_preprocessor.prototype.brackets = function( tokens, aStringBuffer)
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
        var selector = new objj_stringBuffer();
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
            marg_list = new objj_stringBuffer();
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
objj_preprocessor.prototype.directive = function(tokens, aStringBuffer, allowedDirectivesFlags)
{
    var buffer = aStringBuffer ? aStringBuffer : new objj_stringBuffer(),
        token = tokens.next();
    if (token.charAt(0) == TOKEN_DOUBLE_QUOTE)
        buffer.atoms[buffer.atoms.length] = token;
    else if (token == TOKEN_CLASS)
    {
        tokens.skip_whitespace();
        return;
    }
    else if (token == TOKEN_IMPLEMENTATION)
        this.implementation(tokens, buffer);
    else if (token == TOKEN_IMPORT)
        this._import(tokens);
    else if (token == TOKEN_SELECTOR)
        this.selector(tokens, buffer);
    else if (token == TOKEN_ACCESSORS)
        return this.accessors(tokens);
    if (!aStringBuffer)
        return buffer;
}
objj_preprocessor.prototype.fragment = function()
{
    var preprocessed = this._preprocessed.toString();
    if ((/[^\s]/).test(preprocessed))
        this._fragments.push(fragment_create_code(preprocessed, this._bundle, this._file));
    this._preprocessed.clear();
}
objj_preprocessor.prototype.implementation = function(tokens, aStringBuffer)
{
    var buffer = aStringBuffer,
        token = "",
        category = NO,
        class_name = tokens.skip_whitespace(),
        superclass_name = "Nil",
        instance_methods = new objj_stringBuffer(),
        class_methods = new objj_stringBuffer();
    if (!(/^\w/).test(class_name))
        objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Expected class name, found \"" + class_name + "\".")));
    this._currentSuperClass = NULL;
    this._currentSuperMetaClass = NULL;
    this._currentClass = class_name;
    this._currentSelector = "";
    if((token = tokens.skip_whitespace()) == TOKEN_OPEN_PARENTHESIS)
    {
        token = tokens.skip_whitespace();
        if (token == TOKEN_CLOSE_PARENTHESIS)
            objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Can't Have Empty Category Name for class \"" + class_name + "\".")));
        if (tokens.skip_whitespace() != TOKEN_CLOSE_PARENTHESIS)
            objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Improper Category Definition for class \"" + class_name + "\".")));
        buffer.atoms[buffer.atoms.length] = "{\nvar the_class = objj_getClass(\"" + class_name + "\")\n";
        buffer.atoms[buffer.atoms.length] = "if(!the_class) objj_exception_throw(new objj_exception(OBJJClassNotFoundException, \"*** Could not find definition for class \\\"" + class_name + "\\\"\"));\n";
        buffer.atoms[buffer.atoms.length] = "var meta_class = the_class.isa;";
        var superclass_name = ((SUPER_CLASSES)._buckets[class_name]);
        if (!superclass_name)
        {
            this._currentSuperClass = "objj_getClass(\"" + class_name + "\").super_class";
            this._currentSuperMetaClass = "objj_getMetaClass(\"" + class_name + "\").super_class";
        }
        else
        {
            this._currentSuperClass = "objj_getClass(\"" + superclass_name + "\")";
            this._currentSuperMetaClass = "objj_getMetaClass(\"" + superclass_name + "\")";
        }
    }
    else
    {
        if(token == TOKEN_COLON)
        {
            token = tokens.skip_whitespace();
            if (!TOKEN_IDENTIFIER.test(token))
                objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Expected class name, found \"" + token + "\".")));
            superclass_name = token;
            this._currentSuperClass = "objj_getClass(\"" + superclass_name + "\")";
            this._currentSuperMetaClass = "objj_getMetaClass(\"" + superclass_name + "\")";
            { if ((SUPER_CLASSES)._buckets[class_name] == NULL) { (SUPER_CLASSES)._keys.push(class_name); ++(SUPER_CLASSES).count; } if (((SUPER_CLASSES)._buckets[class_name] = superclass_name) == NULL) --(SUPER_CLASSES).count;};
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
                if (token == TOKEN_PREPROCESSOR)
                    attributes = this.directive(tokens);
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
                objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Expected ';' in ivar declaration, found '}'.")));
            if (ivar_count)
                buffer.atoms[buffer.atoms.length] = "]);\n";
            if (!token)
                objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Expected '}'")));
            for (ivar_name in accessors)
            {
                var accessor = accessors[ivar_name],
                    property = accessor["property"] || ivar_name;
                var getterName = accessor["getter"] || property,
                    getterCode = "(id)" + getterName + "\n{\nreturn " + ivar_name + ";\n}";
                if (instance_methods.atoms.length !== 0)
                    instance_methods.atoms[instance_methods.atoms.length] = ",\n";
                instance_methods.atoms[instance_methods.atoms.length] = this.method(new objj_lexer(getterCode));
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
                instance_methods.atoms[instance_methods.atoms.length] = this.method(new objj_lexer(setterCode));
            }
        }
        else
            tokens.previous();
        buffer.atoms[buffer.atoms.length] = "objj_registerClassPair(the_class);\n";
        buffer.atoms[buffer.atoms.length] = "objj_addClassForBundle(the_class, objj_getBundleWithPath(OBJJ_CURRENT_BUNDLE.path));\n";
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
                objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Expected \"@end\", found \"@" + token + "\".")));
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
objj_preprocessor.prototype._import = function(tokens)
{
    this.fragment();
    var path = "",
        token = tokens.skip_whitespace(),
        isLocal = (token != TOKEN_LESS_THAN);
    if (token == TOKEN_LESS_THAN)
    {
        while((token = tokens.next()) && token != TOKEN_GREATER_THAN)
            path += token;
        if(!token)
            objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Unterminated import statement.")));
    }
    else if (token.charAt(0) == TOKEN_DOUBLE_QUOTE)
        path = token.substr(1, token.length - 2);
    else
        objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Expecting '<' or '\"', found \"" + token + "\".")));
    this._fragments.push(fragment_create_file(path, NULL, isLocal, this._file));
}
objj_preprocessor.prototype.method = function(tokens)
{
    var buffer = new objj_stringBuffer(),
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
                objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Argument list expected after ','.")));
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
    if (this._flags & OBJJ_PREPROCESSOR_DEBUG_SYMBOLS)
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
    if (this._flags & OBJJ_PREPROCESSOR_DEBUG_SYMBOLS)
        buffer.atoms[buffer.atoms.length] = ","+JSON.stringify(types);
    buffer.atoms[buffer.atoms.length] = ")";
    this._currentSelector = "";
    return buffer;
}
objj_preprocessor.prototype.preprocess = function(tokens, aStringBuffer, terminator, instigator, tuple)
{
    var buffer = aStringBuffer ? aStringBuffer : new objj_stringBuffer(),
        count = 0,
        token = "";
    if (tuple)
    {
        tuple[0] = buffer;
        var bracket = false,
            closures = [0, 0, 0];
    }
    while ((token = tokens.next()) && ((token != terminator) || count))
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
            if (token == instigator)
                ++count;
            else if (token == terminator)
                --count;
        }
        if(token == TOKEN_IMPORT)
        {
            objj_fprintf(warning_stream, this._file.path + ": import keyword is deprecated, use @import instead.");
            this._import(tokens);
        }
        else if (token === TOKEN_FUNCTION)
        {
            var accumulator = "";
            while((token = tokens.next()) && token != TOKEN_OPEN_PARENTHESIS && !(/^\w/).test(token))
                accumulator += token;
            if (token === TOKEN_OPEN_PARENTHESIS)
            {
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
        objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Expected ']' - Unterminated message send or array.")));
    if (!aStringBuffer)
        return buffer;
}
objj_preprocessor.prototype.selector = function(tokens, aStringBuffer)
{
    var buffer = aStringBuffer ? aStringBuffer : new objj_stringBuffer();
    buffer.atoms[buffer.atoms.length] = "sel_getUid(\"";
    if (tokens.skip_whitespace() != TOKEN_OPEN_PARENTHESIS)
        objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Expected '('")));
    var selector = tokens.skip_whitespace();
    if (selector == TOKEN_CLOSE_PARENTHESIS)
        objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Unexpected ')', can't have empty @selector()")));
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
                    objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Unexpected whitespace in @selector().")));
            else
                objj_exception_throw(new objj_exception(OBJJParseException, this.error_message("*** Illegal character '" + token + "' in @selector().")));
        }
        buffer.atoms[buffer.atoms.length] = token;
        starting = (token == TOKEN_COLON);
    }
    buffer.atoms[buffer.atoms.length] = "\")";
    if (!aStringBuffer)
        return buffer;
}
objj_preprocessor.prototype.error_message = function(errorMessage)
{
    return errorMessage + " <Context File: "+ this._file.path +
                                (this._currentClass ? " Class: "+this._currentClass : "") +
                                (this._currentSelector ? " Method: "+this._currentSelector : "") +">";
}
var objj_included_files = { };
var FRAGMENT_CODE = 1,
    FRAGMENT_FILE = 1 << 2,
    FRAGMENT_LOCAL = 1 << 3;
function objj_fragment()
{
    this.info = NULL;
    this.type = 0;
    this.context = NULL;
    this.bundle = NULL;
    this.file = NULL;
}
function objj_context()
{
    this.fragments = [];
    this.scheduled = NO;
    this.blocked = NO;
}
objj_fragment.prototype.toMarkedString = function()
{
    return (this.type & FRAGMENT_FILE) ? ((this.type & FRAGMENT_LOCAL) ? MARKER_IMPORT_LOCAL : MARKER_IMPORT_STD) + ';' + this.info.length + ';' + this.info :
                            MARKER_CODE + ';' + this.info.length + ';' + this.info;
}
function fragment_create_code(aCode, aBundle, aFile)
{
    var fragment = new objj_fragment();
    fragment.type = (FRAGMENT_CODE);
    fragment.info = (aCode);
    fragment.bundle = aBundle;
    fragment.file = aFile;
    return fragment;
}
function fragment_create_file(aPath, aBundle, isLocal, aFile)
{
    var fragment = new objj_fragment();
    fragment.type = (FRAGMENT_FILE | (FRAGMENT_LOCAL * isLocal));
    fragment.info = aPath;
    fragment.bundle = aBundle;
    fragment.file = aFile;
    return fragment;
}
objj_context.prototype.evaluate = function()
{
    this.scheduled = NO;
    if (this.blocked)
        return this.schedule();
    var sleep = NO,
        start = new Date(),
        fragments = this.fragments;
    while (!sleep && fragments.length)
    {
        var fragment = fragments.pop();
        if ((fragment.type & FRAGMENT_FILE))
            sleep = fragment_evaluate_file(fragment);
        else
            sleep = fragment_evaluate_code(fragment);
        sleep = sleep || ((new Date() - start) > 3000);
    }
    if (sleep)
        this.schedule();
    else if (this.didCompleteCallback)
        this.didCompleteCallback(this);
}
objj_context.prototype.schedule = function()
{
    if (this.scheduled)
        return;
    this.scheduled = YES;
    var context = this;
    window.setNativeTimeout(function () { context.evaluate(); }, 0);
}
objj_context.prototype.pushFragment = function(aFragment)
{
    aFragment.context = this;
    this.fragments.push(aFragment);
}
function fragment_evaluate_code(aFragment)
{
    var compiled;
    OBJJ_CURRENT_BUNDLE = aFragment.bundle;
    try
    {
        var functionText = "function(){"+aFragment.info+"/**/\n}";
        if (typeof system !== "undefined" && system.engine === "rhino")
            compiled = Packages.org.mozilla.javascript.Context.getCurrentContext().compileFunction(window, functionText, aFragment.file.path, 0, null);
        else
            compiled = eval("("+functionText+")");
    }
    catch(anException)
    {
        objj_exception_report(anException, aFragment.file);
    }
    compiled();
    return NO;
}
function fragment_evaluate_file(aFragment)
{
    var context = aFragment.context,
        requiresSleep = YES;
    context.blocked = YES;
    objj_request_file(aFragment.info, (aFragment.type & FRAGMENT_LOCAL), function(aFile)
    {
        requiresSleep = NO;
        context.blocked = NO;
        if (aFile == OBJJ_NO_FILE)
            objj_alert("uh oh!");
        if (objj_included_files[aFile.path])
            return;
        objj_included_files[aFile.path] = YES;
        if (!aFile.fragments)
            aFile.fragments = objj_preprocess(aFile.contents, aFile.bundle, aFile, OBJJ_PREPROCESSOR_DEBUG_SYMBOLS);
        var fragments = aFile.fragments,
            count = fragments.length,
            directory = aFile.path.substr(0, aFile.path.lastIndexOf('/') + 1);
        while (count--)
        {
            var fragment = fragments[count];
            if ((fragment.type & FRAGMENT_FILE))
            {
                if ((fragment.type & FRAGMENT_LOCAL))
                    fragment.info = directory + fragment.info;
                objj_request_file(fragment.info, (fragment.type & FRAGMENT_LOCAL), NULL);
            }
            context.pushFragment(fragment);
        }
    });
    return requiresSleep;
}
function objj_import( pathOrPaths, isLocal, didCompleteCallback)
{
    var context = new objj_context(),
        paths = pathOrPaths;
    if (typeof paths === "string")
        paths = [paths];
    var index = 0,
        count = paths.length;
    for (; index < count; ++index)
        context.pushFragment(fragment_create_file(paths[index], new objj_bundle(""), isLocal, NULL));
    context.didCompleteCallback = didCompleteCallback;
    context.evaluate();
}
if (window.OBJJ_MAIN_FILE)
{
    var addOnload = function(handler)
    {
        if (window.addEventListener)
            window.addEventListener("load", handler, false);
        else if (window.attachEvent)
            window.attachEvent("onload", handler);
    }
    var documentLoaded = NO;
    var defaultHandler = function()
    {
        documentLoaded = YES;
    }
    addOnload(defaultHandler);
    objj_import(OBJJ_MAIN_FILE, YES, function()
    {
        if (documentLoaded)
            main();
        else
            addOnload(main);
    });
}
