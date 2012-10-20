/*
 * TNIPUtils.j
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


/*! Test given string is a valid IP / netmask
*/
function validateIPAddress(ipaddr)
{
    ipaddr = ipaddr.replace( /\s/g, "");
    var re = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/;

    if (re.test(ipaddr))
    {
        var parts = ipaddr.split(".");

        for (var i = 0; i < parts.length; i++)
            if (parseInt(parseFloat(parts[i])) > 255)
                return false;

        return true;
    }
    else
    {
        return false;
    }
}

/*! Validate that IP1 and IP2 are in the same subnet
*/
function validateIPsInSameSubnet(ipaddr1, ipaddr2, netmask)
{
    var ip1digits = ipaddr1.split("."),
        ip2digits = ipaddr2.split("."),
        ip1 = (ip1digits[0] << 24 | ip1digits[1] << 16 | ip1digits[2] << 8 | ip1digits[3]),
        ip2 = (ip2digits[0] << 24 | ip2digits[1] << 16 | ip2digits[2] << 8 | ip2digits[3]),
        netmaskCIDR = netmaskToCIDR(netmask),
        mask = ((1 << (32 - netmaskCIDR)) - 1) ^ 0xFFFFFFFF;

    return (((ip1 ^ ip2) & mask) == 0);
}

/*! Returns the number of available IP in a subnet
*/
function numberOfAvailableIPInSubnet(mask)
{
    var cidr = netmaskToCIDR(mask),
        minus = (cidr >= 31) ? 0 : 2;

    return Math.pow(2, 32 - cidr) - minus;
}

/*! pad a number
*/
function pad(num, size)
{
    var s = "000000000" + num;
    return s.substr(s.length - size);
}


/*! Returns a string representing the binary representation of an IP
*/
function IPToBinaryRepresentation(ipaddr)
{
    var d = ipaddr.split("."),
        binaryString =  pad(parseInt(d[0]).toString(2), 8) +
                        pad(parseInt(d[1]).toString(2), 8) +
                        pad(parseInt(d[2]).toString(2), 8) +
                        pad(parseInt(d[3]).toString(2), 8);
    return binaryString;
}

/*! Returns a int representing the decimal representation of an IP
*/
function IPToDecimalRepresentation(ipaddr)
{
    return parseInt(IPToBinaryRepresentation(ipaddr), 2);
}

/*! Convert a netmask a it's CIDR representation
*/
function netmaskToCIDR(netmask)
{
    return parseInt(IPToBinaryRepresentation(netmask).split(/1/g).length - 1);
}

/*! Validate the network address (address + netmask)
*/
function validateNetworkAddress(address, mask)
{
    var addrBinary = IPToBinaryRepresentation(address),
        maskBinary = IPToBinaryRepresentation(mask),
        ret = [];

    for (var i = 0; i < maskBinary.length; i++)
        ret.push(parseInt((parseInt(maskBinary[i]) || parseInt(addrBinary[i]))));

    return maskBinary == ret.join(""); // yeah \o/ dirty! @TODO!
}

/*! Test given string is a valid route distinguisher / target
*/
function validateRouteTargetOrDistinguisher(routeStuff)
{
    routeStuff = routeStuff.replace( /\s/g, "");
    var re = /^\d{1,4}:\d{1,4}$/;
    return re.test(routeStuff);
}
/*! Test given string is a valid email address
*/
function validateEmailAddress(email)
{
    email = email.replace( /\s/g, "");
    var re = new RegExp("^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");
    return re.test(email);
}

/*! Test string is a numeric stuff
*/
function isNumber(n)
{
  return !isNaN(parseFloat(n)) && isFinite(n);
}


/*! Return an array 100 random values
*/
function randomValues()
{
    var ret = [];
    for (var i = 0 ; i < 100; i++)
    {
        ret.push(Math.random() * 10);
    }

    return ret;
}

/*! Return an array of 4 random values
*/
function randomSets()
{
   var ret = [];

   for (var i = 0 ; i < 4; i++)
   {
       ret.push(Math.random() * 10);
   }

   return ret;
}

