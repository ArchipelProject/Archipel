// Ver .91 Feb 21 1998
//////////////////////////////////////////////////////////////
//
//	Copyright 1998 Jeremie
//	Free for public non-commercial use and modification
//	as long as this header is kept intact and unmodified.
//	Please see http://www.jeremie.com for more information
//	or email jer@jeremie.com with questions/suggestions.
//
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
////////// Simple XML Processing Library //////////////////////
///////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////
////   Fully complies to the XML 1.0 spec 
////   as a well-formed processor, with the
////   exception of full error reporting and
////   the document type declaration(and it's
////   related features, internal entities, etc).
///////////////////////////////////////////////////////////////


/////////////////////////
//// the object constructors for the hybrid DOM

function _element()
{
	this.type = "element";
	this.name = new String();
	this.attributes = new Array();
	this.contents = new Array();
	this.uid = _Xparse_count++;
	_Xparse_index[this.uid]=this;
}

function _chardata()
{
	this.type = "chardata";
	this.value = new String();
}

function _pi()
{
	this.type = "pi";
	this.value = new String();
}

function _comment()
{
	this.type = "comment";
	this.value = new String();
}

// an internal fragment that is passed between functions
function _frag()
{
	this.str = new String();
	this.ary = new Array();
	this.end = new String();
}

/////////////////////////


// global vars to track element UID's for the index
var _Xparse_count = 0;
var _Xparse_index = new Array();


/////////////////////////
//// Main public function that is called to 
//// parse the XML string and return a root element object

function Xparse(src)
{
	var frag = new _frag();

	// remove bad \r characters and the prolog
	frag.str = _prolog(src);

	// create a root element to contain the document
	var root = new _element();
	root.name="ROOT";

	// main recursive function to process the xml
	frag = _compile(frag);

	// all done, lets return the root element + index + document
	root.contents = frag.ary;
	root.index = _Xparse_index;
	_Xparse_index = new Array();
	return root;
}

/////////////////////////


/////////////////////////
//// transforms raw text input into a multilevel array
function _compile(frag)
{
	// keep circling and eating the str
	while(1)
	{
		// when the str is empty, return the fragment
		if(frag.str.length == 0)
		{
			return frag;
		}

		var TagStart = frag.str.indexOf("<");

		if(TagStart != 0)
		{
			// theres a chunk of characters here, store it and go on
			var thisary = frag.ary.length;
			frag.ary[thisary] = new _chardata();
			if(TagStart == -1)
			{
				frag.ary[thisary].value = _entity(frag.str);
				frag.str = "";
			}
			else
			{
				frag.ary[thisary].value = _entity(frag.str.substring(0,TagStart));
				frag.str = frag.str.substring(TagStart,frag.str.length);
			}
		}
		else
		{
			// determine what the next section is, and process it
			if(frag.str.substring(1,2) == "?")
			{
				frag = _tag_pi(frag);
			}
			else
			{
				if(frag.str.substring(1,4) == "!--")
				{
					frag = _tag_comment(frag);
				}
				else
				{
					if(frag.str.substring(1,9) == "![CDATA[")
					{
						frag = _tag_cdata(frag);
					}
					else
					{
						if(frag.str.substring(1,frag.end.length + 3) == "/" + frag.end + ">" || _strip(frag.str.substring(1,frag.end.length + 3)) == "/" + frag.end)
						{
							// found the end of the current tag, end the recursive process and return
							frag.str = frag.str.substring(frag.end.length + 3,frag.str.length);
							frag.end = "";
							return frag;
						}
						else
						{
							frag = _tag_element(frag);
						}
					}
				}
			}

		}
	}
	return "";
}
///////////////////////


///////////////////////
//// functions to process different tags

function _tag_element(frag)
{
	// initialize some temporary variables for manipulating the tag
	var close = frag.str.indexOf(">");
	var empty = (frag.str.substring(close - 1,close) == "/");
	if(empty)
	{
		close -= 1;
	}

	// split up the name and attributes
	var starttag = _normalize(frag.str.substring(1,close));
	var nextspace = starttag.indexOf(" ");
	var attribs = new String();
	var name = new String();
	if(nextspace != -1)
	{
		name = starttag.substring(0,nextspace);
		attribs = starttag.substring(nextspace + 1,starttag.length);
	}
	else
	{
		name = starttag;
	}

	var thisary = frag.ary.length;
	frag.ary[thisary] = new _element();
	frag.ary[thisary].name = _strip(name);
	if(attribs.length > 0)
	{
		frag.ary[thisary].attributes = _attribution(attribs);
	}
	if(!empty)
	{
		// !!!! important, 
		// take the contents of the tag and parse them
		var contents = new _frag();
		contents.str = frag.str.substring(close + 1,frag.str.length);
		contents.end = name;
		contents = _compile(contents);
		frag.ary[thisary].contents = contents.ary;
		frag.str = contents.str;
	}
	else
	{
		frag.str = frag.str.substring(close + 2,frag.str.length);
	}
	return frag;
}

function _tag_pi(frag)
{
	var close = frag.str.indexOf("?>");
	var val = frag.str.substring(2,close);
	var thisary = frag.ary.length;
	frag.ary[thisary] = new _pi();
	frag.ary[thisary].value = val;
	frag.str = frag.str.substring(close + 2,frag.str.length);
	return frag;
}

function _tag_comment(frag)
{
	var close = frag.str.indexOf("-->");
	var val = frag.str.substring(4,close);
	var thisary = frag.ary.length;
	frag.ary[thisary] = new _comment();
	frag.ary[thisary].value = val;
	frag.str = frag.str.substring(close + 3,frag.str.length);
	return frag;
}

function _tag_cdata(frag)
{
	var close = frag.str.indexOf("]]>");
	var val = frag.str.substring(9,close);
	var thisary = frag.ary.length;
	frag.ary[thisary] = new _chardata();
	frag.ary[thisary].value = val;
	frag.str = frag.str.substring(close + 3,frag.str.length);
	return frag;
}

/////////////////////////


//////////////////
//// util for element attribute parsing
//// returns an array of all of the keys = values
function _attribution(str)
{
	var all = new Array();
	while(1)
	{
		var eq = str.indexOf("=");
		if(str.length == 0 || eq == -1)
		{
			return all;
		}

		var id1 = str.indexOf("\'");
		var id2 = str.indexOf("\"");
		var ids = new Number();
		var id = new String();
		if((id1 < id2 && id1 != -1) || id2 == -1)
		{
			ids = id1;
			id = "\'";
		}
		if((id2 < id1 || id1 == -1) && id2 != -1)
		{
			ids = id2;
			id = "\"";
		}
		var nextid = str.indexOf(id,ids + 1);
		var val = str.substring(ids + 1,nextid);

		var name = _strip(str.substring(0,eq));
		all[name] = _entity(val);
		str = str.substring(nextid + 1,str.length);
	}
	return "";
}
////////////////////


//////////////////////
//// util to remove \r characters from input string
//// and return xml string without a prolog
function _prolog(str)
{
	var A = new Array();

	A = str.split("\r\n");
	str = A.join("\n");
	A = str.split("\r");
	str = A.join("\n");

	var start = str.indexOf("<");
	if(str.substring(start,start + 3) == "<?x" || str.substring(start,start + 3) == "<?X" )
	{
		var close = str.indexOf("?>");
		str = str.substring(close + 2,str.length);
	}
	var start = str.indexOf("<!DOCTYPE");
	if(start != -1)
	{
		var close = str.indexOf(">",start) + 1;
		var dp = str.indexOf("[",start);
		if(dp < close && dp != -1)
		{
			close = str.indexOf("]>",start) + 2;
		}
		str = str.substring(close,str.length);
	}
	return str;
}
//////////////////


//////////////////////
//// util to remove white characters from input string
function _strip(str)
{
	var A = new Array();

	A = str.split("\n");
	str = A.join("");
	A = str.split(" ");
	str = A.join("");
	A = str.split("\t");
	str = A.join("");

	return str;
}
//////////////////


//////////////////////
//// util to replace white characters in input string
function _normalize(str)
{
	var A = new Array();

	A = str.split("\n");
	str = A.join(" ");
	A = str.split("\t");
	str = A.join(" ");

	return str;
}
//////////////////


//////////////////////
//// util to replace internal entities in input string
function _entity(str)
{
	var A = new Array();

	A = str.split("&lt;");
	str = A.join("<");
	A = str.split("&gt;");
	str = A.join(">");
	A = str.split("&quot;");
	str = A.join("\"");
	A = str.split("&apos;");
	str = A.join("\'");
	A = str.split("&amp;");
	str = A.join("&");

	return str;
}
//////////////////
