@STATIC;1.0;p;22;BKShowcaseController.jt;20985;@STATIC;1.0;I;16;AppKit/CPTheme.jI;15;AppKit/CPView.jt;20924;objj_executeFile("AppKit/CPTheme.j", false);
objj_executeFile("AppKit/CPView.j", false);
var LEFT_PANEL_WIDTH = 176.0;
var BKLearnMoreToolbarItemIdentifier = "BKLearnMoreToolbarItemIdentifier",
    BKStateToolbarItemIdentifier = "BKStateToolbarItemIdentifier",
    BKBackgroundColorToolbarItemIdentifier = "BKBackgroundColorToolbarItemIdentifier";
{var the_class = objj_allocateClassPair(CPObject, "BKShowcaseController"),
meta_class = the_class.isa;class_addIvars(the_class, [new objj_ivar("_themeDescriptorClasses"), new objj_ivar("_themesCollectionView"), new objj_ivar("_themedObjectsCollectionView")]);
objj_registerClassPair(the_class);
class_addMethods(the_class, [new objj_method(sel_getUid("applicationDidFinishLaunching:"), function $BKShowcaseController__applicationDidFinishLaunching_(self, _cmd, aNotification)
{ with(self)
{
    _themeDescriptorClasses = objj_msgSend(BKThemeDescriptor, "allThemeDescriptorClasses");
    var theWindow = objj_msgSend(objj_msgSend(CPWindow, "alloc"), "initWithContentRect:styleMask:", CGRectMakeZero(), CPBorderlessBridgeWindowMask),
        toolbar = objj_msgSend(objj_msgSend(CPToolbar, "alloc"), "initWithIdentifier:", "Toolbar");
    objj_msgSend(toolbar, "setDelegate:", self);
    objj_msgSend(theWindow, "setToolbar:", toolbar);
    var contentView = objj_msgSend(theWindow, "contentView"),
        bounds = objj_msgSend(contentView, "bounds"),
        splitView = objj_msgSend(objj_msgSend(CPSplitView, "alloc"), "initWithFrame:", bounds);
    objj_msgSend(splitView, "setIsPaneSplitter:", YES);
    objj_msgSend(splitView, "setAutoresizingMask:", CPViewWidthSizable | CPViewHeightSizable);
    objj_msgSend(contentView, "addSubview:", splitView);
    var label = objj_msgSend(CPTextField, "labelWithTitle:", "THEMES");
    objj_msgSend(label, "setFont:", objj_msgSend(CPFont, "boldSystemFontOfSize:", 11.0));
    objj_msgSend(label, "setTextColor:", objj_msgSend(CPColor, "colorWithCalibratedRed:green:blue:alpha:", 93.0 / 255.0, 93.0 / 255.0, 93.0 / 255.0, 1.0));
    objj_msgSend(label, "setTextShadowColor:", objj_msgSend(CPColor, "colorWithCalibratedRed:green:blue:alpha:", 225.0 / 255.0, 255.0 / 255.0, 255.0 / 255.0, 0.7));
    objj_msgSend(label, "setTextShadowOffset:", CGSizeMake(0.0, 1.0));
    objj_msgSend(label, "sizeToFit");
    objj_msgSend(label, "setFrameOrigin:", CGPointMake(5.0, 4.0));
    var themeDescriptorItem = objj_msgSend(objj_msgSend(CPCollectionViewItem, "alloc"), "init");
    objj_msgSend(themeDescriptorItem, "setView:", objj_msgSend(objj_msgSend(BKThemeDescriptorCell, "alloc"), "init"));
    _themesCollectionView = objj_msgSend(objj_msgSend(CPCollectionView, "alloc"), "initWithFrame:", CGRectMake(0.0, 0.0, LEFT_PANEL_WIDTH, CGRectGetHeight(bounds)));
    objj_msgSend(_themesCollectionView, "setDelegate:", self);
    objj_msgSend(_themesCollectionView, "setItemPrototype:", themeDescriptorItem);
    objj_msgSend(_themesCollectionView, "setMinItemSize:", CGSizeMake(20.0, 36.0));
    objj_msgSend(_themesCollectionView, "setMaxItemSize:", CGSizeMake(10000000.0, 36.0));
    objj_msgSend(_themesCollectionView, "setMaxNumberOfColumns:", 1);
    objj_msgSend(_themesCollectionView, "setContent:", _themeDescriptorClasses);
    objj_msgSend(_themesCollectionView, "setAutoresizingMask:", CPViewWidthSizable);
    objj_msgSend(_themesCollectionView, "setVerticalMargin:", 0.0);
    objj_msgSend(_themesCollectionView, "setSelectable:", YES);
    objj_msgSend(_themesCollectionView, "setFrameOrigin:", CGPointMake(0.0, 20.0));
    objj_msgSend(_themesCollectionView, "setAutoresizingMask:", CPViewWidthSizable);
    var scrollView = objj_msgSend(objj_msgSend(CPScrollView, "alloc"), "initWithFrame:", CGRectMake(0.0, 0.0, LEFT_PANEL_WIDTH, CGRectGetHeight(bounds))),
        contentView = objj_msgSend(scrollView, "contentView");
    objj_msgSend(scrollView, "setAutohidesScrollers:", YES);
    objj_msgSend(scrollView, "setDocumentView:", _themesCollectionView);
    objj_msgSend(contentView, "setBackgroundColor:", objj_msgSend(CPColor, "colorWithRed:green:blue:alpha:", 212.0 / 255.0, 221.0 / 255.0, 230.0 / 255.0, 1.0));
    objj_msgSend(contentView, "addSubview:", label);
    objj_msgSend(splitView, "addSubview:", scrollView);
    _themedObjectsCollectionView = objj_msgSend(objj_msgSend(CPCollectionView, "alloc"), "initWithFrame:", CGRectMake(0.0, 0.0, CGRectGetWidth(bounds) - LEFT_PANEL_WIDTH - 1.0, 10.0));
    var collectionViewItem = objj_msgSend(objj_msgSend(CPCollectionViewItem, "alloc"), "init");
    objj_msgSend(collectionViewItem, "setView:", objj_msgSend(objj_msgSend(BKShowcaseCell, "alloc"), "init"));
    objj_msgSend(_themedObjectsCollectionView, "setItemPrototype:", collectionViewItem);
    objj_msgSend(_themedObjectsCollectionView, "setVerticalMargin:", 20.0);
    objj_msgSend(_themedObjectsCollectionView, "setAutoresizingMask:", CPViewWidthSizable);
    var scrollView = objj_msgSend(objj_msgSend(CPScrollView, "alloc"), "initWithFrame:", CGRectMake(LEFT_PANEL_WIDTH + 1.0, 0.0, CGRectGetWidth(bounds) - LEFT_PANEL_WIDTH - 1.0, CGRectGetHeight(bounds)));
    objj_msgSend(scrollView, "setHasHorizontalScroller:", NO);
    objj_msgSend(scrollView, "setAutohidesScrollers:", YES);
    objj_msgSend(scrollView, "setAutoresizingMask:", CPViewWidthSizable | CPViewHeightSizable);
    objj_msgSend(scrollView, "setDocumentView:", _themedObjectsCollectionView);
    objj_msgSend(splitView, "addSubview:", scrollView);
    objj_msgSend(_themesCollectionView, "setSelectionIndexes:", objj_msgSend(CPIndexSet, "indexSetWithIndex:", 0));
    objj_msgSend(theWindow, "setFullBridge:", YES);
    objj_msgSend(theWindow, "makeKeyAndOrderFront:", self);
}
},["void","CPNotification"]), new objj_method(sel_getUid("collectionViewDidChangeSelection:"), function $BKShowcaseController__collectionViewDidChangeSelection_(self, _cmd, aCollectionView)
{ with(self)
{
    var themeDescriptorClass = _themeDescriptorClasses[objj_msgSend(objj_msgSend(aCollectionView, "selectionIndexes"), "firstIndex")],
        itemSize = objj_msgSend(themeDescriptorClass, "itemSize");
    itemSize.width = MAX(100.0, itemSize.width + 20.0);
    itemSize.height = MAX(100.0, itemSize.height + 30.0);
    objj_msgSend(_themedObjectsCollectionView, "setMinItemSize:", itemSize);
    objj_msgSend(_themedObjectsCollectionView, "setMaxItemSize:", itemSize);
    objj_msgSend(_themedObjectsCollectionView, "setContent:", objj_msgSend(themeDescriptorClass, "themedObjectTemplates"));
    objj_msgSend(BKShowcaseCell, "setBackgroundColor:", objj_msgSend(themeDescriptorClass, "showcaseBackgroundColor"));
}
},["void","CPCollectionView"]), new objj_method(sel_getUid("hasLearnMoreURL"), function $BKShowcaseController__hasLearnMoreURL(self, _cmd)
{ with(self)
{
    return objj_msgSend(objj_msgSend(CPBundle, "mainBundle"), "objectForInfoDictionaryKey:", "BKLearnMoreURL");
}
},["BOOL"]), new objj_method(sel_getUid("toolbarAllowedItemIdentifiers:"), function $BKShowcaseController__toolbarAllowedItemIdentifiers_(self, _cmd, aToolbar)
{ with(self)
{
    return [BKLearnMoreToolbarItemIdentifier, CPToolbarSpaceItemIdentifier, CPToolbarFlexibleSpaceItemIdentifier, BKBackgroundColorToolbarItemIdentifier, BKStateToolbarItemIdentifier];
}
},["CPArray","CPToolbar"]), new objj_method(sel_getUid("toolbarDefaultItemIdentifiers:"), function $BKShowcaseController__toolbarDefaultItemIdentifiers_(self, _cmd, aToolbar)
{ with(self)
{
    var itemIdentifiers = [CPToolbarFlexibleSpaceItemIdentifier, BKBackgroundColorToolbarItemIdentifier, BKStateToolbarItemIdentifier];
    if (objj_msgSend(self, "hasLearnMoreURL"))
        itemIdentifiers = [BKLearnMoreToolbarItemIdentifier].concat(itemIdentifiers);
    return itemIdentifiers;
}
},["CPArray","CPToolbar"]), new objj_method(sel_getUid("toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:"), function $BKShowcaseController__toolbar_itemForItemIdentifier_willBeInsertedIntoToolbar_(self, _cmd, aToolbar, anItemIdentifier, aFlag)
{ with(self)
{
    var toolbarItem = objj_msgSend(objj_msgSend(CPToolbarItem, "alloc"), "initWithItemIdentifier:", anItemIdentifier);
    objj_msgSend(toolbarItem, "setTarget:", self);
    if (anItemIdentifier === BKStateToolbarItemIdentifier)
    {
        var popUpButton = objj_msgSend(CPPopUpButton, "buttonWithTitle:", "Enabled");
        objj_msgSend(popUpButton, "addItemWithTitle:", "Disabled");
        objj_msgSend(toolbarItem, "setView:", popUpButton);
        objj_msgSend(toolbarItem, "setTarget:", nil);
        objj_msgSend(toolbarItem, "setAction:", sel_getUid("changeState:"));
        objj_msgSend(toolbarItem, "setLabel:", "State");
        var width = CGRectGetWidth(objj_msgSend(popUpButton, "frame"));
        objj_msgSend(toolbarItem, "setMinSize:", CGSizeMake(width + 20.0, 24.0));
        objj_msgSend(toolbarItem, "setMaxSize:", CGSizeMake(width + 20.0, 24.0));
    }
    else if (anItemIdentifier === BKBackgroundColorToolbarItemIdentifier)
    {
        var popUpButton = objj_msgSend(CPPopUpButton, "buttonWithTitle:", "Window Background");
        objj_msgSend(popUpButton, "addItemWithTitle:", "Light Checkers");
        objj_msgSend(popUpButton, "addItemWithTitle:", "Dark Checkers");
        objj_msgSend(popUpButton, "addItemWithTitle:", "White");
        objj_msgSend(popUpButton, "addItemWithTitle:", "Black");
        objj_msgSend(popUpButton, "addItemWithTitle:", "More Choices...");
        var itemArray = objj_msgSend(popUpButton, "itemArray");
        objj_msgSend(itemArray[0], "setRepresentedObject:", objj_msgSend(BKThemeDescriptor, "windowBackgroundColor"));
        objj_msgSend(itemArray[1], "setRepresentedObject:", objj_msgSend(BKThemeDescriptor, "lightCheckersColor"));
        objj_msgSend(itemArray[2], "setRepresentedObject:", objj_msgSend(BKThemeDescriptor, "darkCheckersColor"));
        objj_msgSend(itemArray[3], "setRepresentedObject:", objj_msgSend(CPColor, "whiteColor"));
        objj_msgSend(itemArray[4], "setRepresentedObject:", objj_msgSend(CPColor, "blackColor"));
        objj_msgSend(toolbarItem, "setView:", popUpButton);
        objj_msgSend(toolbarItem, "setTarget:", nil);
        objj_msgSend(toolbarItem, "setAction:", sel_getUid("changeColor:"));
        objj_msgSend(toolbarItem, "setLabel:", "Background Color");
        var width = CGRectGetWidth(objj_msgSend(popUpButton, "frame"));
        objj_msgSend(toolbarItem, "setMinSize:", CGSizeMake(width, 24.0));
        objj_msgSend(toolbarItem, "setMaxSize:", CGSizeMake(width, 24.0));
    }
    else if (anItemIdentifier === BKLearnMoreToolbarItemIdentifier)
    {
        var title = objj_msgSend(objj_msgSend(CPBundle, "mainBundle"), "objectForInfoDictionaryKey:", "BKLearnMoreButtonTitle");
        if (!title)
            title = objj_msgSend(objj_msgSend(CPBundle, "mainBundle"), "objectForInfoDictionaryKey:", "CPBundleName") || "Home Page";
        var button = objj_msgSend(CPButton, "buttonWithTitle:", title);
        objj_msgSend(button, "setDefaultButton:", YES);
        objj_msgSend(toolbarItem, "setView:", button);
        objj_msgSend(toolbarItem, "setLabel:", "Learn More");
        objj_msgSend(toolbarItem, "setTarget:", nil);
        objj_msgSend(toolbarItem, "setAction:", sel_getUid("learnMore:"));
        var width = CGRectGetWidth(objj_msgSend(button, "frame"));
        objj_msgSend(toolbarItem, "setMinSize:", CGSizeMake(width, 24.0));
        objj_msgSend(toolbarItem, "setMaxSize:", CGSizeMake(width, 24.0));
    }
    return toolbarItem;
}
},["CPToolbarItem","CPToolbar","CPString","BOOL"]), new objj_method(sel_getUid("learnMore:"), function $BKShowcaseController__learnMore_(self, _cmd, aSender)
{ with(self)
{
    window.location.href = objj_msgSend(objj_msgSend(CPBundle, "mainBundle"), "objectForInfoDictionaryKey:", "BKLearnMoreURL");
}
},["void","id"]), new objj_method(sel_getUid("selectedThemeDescriptor"), function $BKShowcaseController__selectedThemeDescriptor(self, _cmd)
{ with(self)
{
    return _themeDescriptorClasses[objj_msgSend(objj_msgSend(_themesCollectionView, "selectionIndexes"), "firstIndex")];
}
},["BKThemeDescriptor"]), new objj_method(sel_getUid("changeState:"), function $BKShowcaseController__changeState_(self, _cmd, aSender)
{ with(self)
{
    var themedObjectTemplates = objj_msgSend(objj_msgSend(self, "selectedThemeDescriptor"), "themedObjectTemplates"),
        count = objj_msgSend(themedObjectTemplates, "count");
    while (count--)
    {
        var themedObject = objj_msgSend(themedObjectTemplates[count], "valueForKey:", "themedObject");
        if (objj_msgSend(themedObject, "respondsToSelector:", sel_getUid("setEnabled:")))
            objj_msgSend(themedObject, "setEnabled:", objj_msgSend(aSender, "title") === "Enabled" ? YES : NO);
    }
}
},["void","id"]), new objj_method(sel_getUid("changeColor:"), function $BKShowcaseController__changeColor_(self, _cmd, aSender)
{ with(self)
{
    var color = nil;
    if (objj_msgSend(aSender, "isKindOfClass:", objj_msgSend(CPColorPanel, "class")))
        color = objj_msgSend(aSender, "color");
    else
    {
        if (objj_msgSend(aSender, "titleOfSelectedItem") === "More Choices...")
        {
            objj_msgSend(aSender, "addItemWithTitle:", "Other");
            objj_msgSend(aSender, "selectItemWithTitle:", "Other");
            objj_msgSend(CPApp, "orderFrontColorPanel:", self);
        }
        else
        {
            color = objj_msgSend(objj_msgSend(aSender, "selectedItem"), "representedObject");
            objj_msgSend(aSender, "removeItemWithTitle:", "Other");
        }
    }
    if (color)
    {
        objj_msgSend(objj_msgSend(self, "selectedThemeDescriptor"), "setShowcaseBackgroundColor:", color);
        objj_msgSend(BKShowcaseCell, "setBackgroundColor:", color);
    }
}
},["void","id"])]);
}
var SelectionColor = nil;
{var the_class = objj_allocateClassPair(CPView, "BKThemeDescriptorCell"),
meta_class = the_class.isa;class_addIvars(the_class, [new objj_ivar("_label")]);
objj_registerClassPair(the_class);
class_addMethods(the_class, [new objj_method(sel_getUid("setRepresentedObject:"), function $BKThemeDescriptorCell__setRepresentedObject_(self, _cmd, aThemeDescriptor)
{ with(self)
{
    if (!_label)
    {
        _label = objj_msgSend(CPTextField, "labelWithTitle:", "hello");
        objj_msgSend(_label, "setFont:", objj_msgSend(CPFont, "systemFontOfSize:", 11.0));
        objj_msgSend(_label, "setFrame:", CGRectMake(10.0, 0.0, CGRectGetWidth(objj_msgSend(self, "bounds")) - 20.0, CGRectGetHeight(objj_msgSend(self, "bounds"))));
        objj_msgSend(_label, "setVerticalAlignment:", CPCenterVerticalTextAlignment);
        objj_msgSend(_label, "setAutoresizingMask:", CPViewWidthSizable | CPViewHeightSizable);
        objj_msgSend(self, "addSubview:", _label);
    }
    objj_msgSend(_label, "setStringValue:", objj_msgSend(aThemeDescriptor, "themeName") + " (" + objj_msgSend(objj_msgSend(aThemeDescriptor, "themedObjectTemplates"), "count") + ")");
}
},["void","id"]), new objj_method(sel_getUid("setSelected:"), function $BKThemeDescriptorCell__setSelected_(self, _cmd, isSelected)
{ with(self)
{
    objj_msgSend(self, "setBackgroundColor:", isSelected ? objj_msgSend(objj_msgSend(self, "class"), "selectionColor") : nil);
    objj_msgSend(_label, "setTextShadowOffset:", isSelected ? CGSizeMake(0.0, 1.0) : CGSizeMakeZero());
    objj_msgSend(_label, "setTextShadowColor:", isSelected ? objj_msgSend(CPColor, "blackColor") : nil);
    objj_msgSend(_label, "setFont:", isSelected ? objj_msgSend(CPFont, "boldSystemFontOfSize:", 11.0) : objj_msgSend(CPFont, "systemFontOfSize:", 11.0));
    objj_msgSend(_label, "setTextColor:", isSelected ? objj_msgSend(CPColor, "whiteColor") : objj_msgSend(CPColor, "blackColor"));
}
},["void","BOOL"])]);
class_addMethods(meta_class, [new objj_method(sel_getUid("selectionColor"), function $BKThemeDescriptorCell__selectionColor(self, _cmd)
{ with(self)
{
    if (!SelectionColor)
        SelectionColor = objj_msgSend(CPColor, "colorWithPatternImage:", objj_msgSend(objj_msgSend(CPImage, "alloc"), "initWithContentsOfFile:size:", objj_msgSend(objj_msgSend(CPBundle, "bundleForClass:", objj_msgSend(BKThemeDescriptorCell, "class")), "pathForResource:", "selection.png"), CGSizeMake(1.0, 36.0)));
    return SelectionColor;
}
},["CPImage"])]);
}
var ShowcaseCellBackgroundColor = nil;
var BKShowcaseCellBackgroundColorDidChangeNotification = "BKShowcaseCellBackgroundColorDidChangeNotification";
{var the_class = objj_allocateClassPair(CPView, "BKShowcaseCell"),
meta_class = the_class.isa;class_addIvars(the_class, [new objj_ivar("_backgroundView"), new objj_ivar("_view"), new objj_ivar("_label")]);
objj_registerClassPair(the_class);
class_addMethods(the_class, [new objj_method(sel_getUid("init"), function $BKShowcaseCell__init(self, _cmd)
{ with(self)
{
    self = objj_msgSendSuper({ receiver:self, super_class:objj_getClass("BKShowcaseCell").super_class }, "init");
    if (self)
        objj_msgSend(objj_msgSend(CPNotificationCenter, "defaultCenter"), "addObserver:selector:name:object:", self, sel_getUid("showcaseBackgroundDidChange:"), BKShowcaseCellBackgroundColorDidChangeNotification, nil);
    return self;
}
},["id"]), new objj_method(sel_getUid("initWithCoder:"), function $BKShowcaseCell__initWithCoder_(self, _cmd, aCoder)
{ with(self)
{
    self = objj_msgSendSuper({ receiver:self, super_class:objj_getClass("BKShowcaseCell").super_class }, "initWithCoder:", aCoder);
    if (self)
        objj_msgSend(objj_msgSend(CPNotificationCenter, "defaultCenter"), "addObserver:selector:name:object:", self, sel_getUid("showcaseBackgroundDidChange:"), BKShowcaseCellBackgroundColorDidChangeNotification, nil);
    return self;
}
},["id","CPCoder"]), new objj_method(sel_getUid("showcaseBackgroundDidChange:"), function $BKShowcaseCell__showcaseBackgroundDidChange_(self, _cmd, aNotification)
{ with(self)
{
    objj_msgSend(_backgroundView, "setBackgroundColor:", objj_msgSend(BKShowcaseCell, "backgroundColor"));
}
},["void","CPNotification"]), new objj_method(sel_getUid("setSelected:"), function $BKShowcaseCell__setSelected_(self, _cmd, isSelected)
{ with(self)
{
}
},["void","BOOL"]), new objj_method(sel_getUid("setRepresentedObject:"), function $BKShowcaseCell__setRepresentedObject_(self, _cmd, anObject)
{ with(self)
{
    if (!_label)
    {
        _label = objj_msgSend(objj_msgSend(CPTextField, "alloc"), "initWithFrame:", CGRectMakeZero());
        objj_msgSend(_label, "setAlignment:", CPCenterTextAlignment);
        objj_msgSend(_label, "setAutoresizingMask:", CPViewMinYMargin | CPViewWidthSizable);
        objj_msgSend(_label, "setFont:", objj_msgSend(CPFont, "boldSystemFontOfSize:", 11.0));
        objj_msgSend(self, "addSubview:", _label);
    }
    objj_msgSend(_label, "setStringValue:", objj_msgSend(anObject, "valueForKey:", "label"));
    objj_msgSend(_label, "sizeToFit");
    objj_msgSend(_label, "setFrame:", CGRectMake(0.0, CGRectGetHeight(objj_msgSend(self, "bounds")) - CGRectGetHeight(objj_msgSend(_label, "frame")),
        CGRectGetWidth(objj_msgSend(self, "bounds")), CGRectGetHeight(objj_msgSend(_label, "frame"))));
    if (!_backgroundView)
    {
        _backgroundView = objj_msgSend(objj_msgSend(CPView, "alloc"), "init");
        objj_msgSend(self, "addSubview:", _backgroundView);
    }
    objj_msgSend(_backgroundView, "setFrame:", CGRectMake(0.0, 0.0, CGRectGetWidth(objj_msgSend(self, "bounds")), CGRectGetMinY(objj_msgSend(_label, "frame"))));
    objj_msgSend(_backgroundView, "setAutoresizingMask:", CPViewWidthSizable | CPViewHeightSizable);
    if (_view)
        objj_msgSend(_view, "removeFromSuperview");
    _view = objj_msgSend(anObject, "valueForKey:", "themedObject");
    objj_msgSend(_view, "setTheme:", nil);
    objj_msgSend(_view, "setAutoresizingMask:", CPViewMinXMargin | CPViewMaxXMargin | CPViewMinYMargin | CPViewMaxYMargin);
    objj_msgSend(_view, "setFrameOrigin:", CGPointMake((CGRectGetWidth(objj_msgSend(_backgroundView, "bounds")) - CGRectGetWidth(objj_msgSend(_view, "frame"))) / 2.0,
        (CGRectGetHeight(objj_msgSend(_backgroundView, "bounds")) - CGRectGetHeight(objj_msgSend(_view, "frame"))) / 2.0));
    objj_msgSend(_backgroundView, "addSubview:", _view);
    objj_msgSend(_backgroundView, "setBackgroundColor:", objj_msgSend(BKShowcaseCell, "backgroundColor"));
}
},["void","id"])]);
class_addMethods(meta_class, [new objj_method(sel_getUid("setBackgroundColor:"), function $BKShowcaseCell__setBackgroundColor_(self, _cmd, aColor)
{ with(self)
{
    if (ShowcaseCellBackgroundColor === aColor)
        return;
    ShowcaseCellBackgroundColor = aColor;
    objj_msgSend(objj_msgSend(CPNotificationCenter, "defaultCenter"), "postNotificationName:object:", BKShowcaseCellBackgroundColorDidChangeNotification, nil);
}
},["void","CPColor"]), new objj_method(sel_getUid("backgroundColor"), function $BKShowcaseCell__backgroundColor(self, _cmd)
{ with(self)
{
    return ShowcaseCellBackgroundColor;
}
},["CPColor"])]);
}

p;19;BKThemeDescriptor.jt;6902;@STATIC;1.0;I;21;Foundation/CPObject.jt;6857;objj_executeFile("Foundation/CPObject.j", false);
var ItemSizes = { },
    ThemedObjects = { },
    BackgroundColors = { },
    LightCheckersColor = nil,
    DarkCheckersColor = nil,
    WindowBackgroundColor = nil;
{var the_class = objj_allocateClassPair(CPObject, "BKThemeDescriptor"),
meta_class = the_class.isa;objj_registerClassPair(the_class);
class_addMethods(meta_class, [new objj_method(sel_getUid("allThemeDescriptorClasses"), function $BKThemeDescriptor__allThemeDescriptorClasses(self, _cmd)
{ with(self)
{
    var themeDescriptorClasses = [];
    for (candidate in global)
    {
        var theClass = objj_getClass(candidate),
            theClassName = class_getName(theClass);
        if (theClassName === "BKThemeDescriptor")
            continue;
        var index = theClassName.indexOf("ThemeDescriptor");
        if ((index >= 0) && (index === theClassName.length - "ThemeDescriptor".length))
            themeDescriptorClasses.push(theClass);
    }
    objj_msgSend(themeDescriptorClasses, "sortUsingSelector:", sel_getUid("compare:"));
    return themeDescriptorClasses;
}
},["CPArray"]), new objj_method(sel_getUid("lightCheckersColor"), function $BKThemeDescriptor__lightCheckersColor(self, _cmd)
{ with(self)
{
    if (!LightCheckersColor)
        LightCheckersColor = objj_msgSend(CPColor, "colorWithPatternImage:", objj_msgSend(objj_msgSend(CPImage, "alloc"), "initWithContentsOfFile:size:", objj_msgSend(objj_msgSend(CPBundle, "bundleForClass:", objj_msgSend(BKThemeDescriptor, "class")), "pathForResource:", "light-checkers.png"), CGSizeMake(12.0, 12.0)));
    return LightCheckersColor;
}
},["CPColor"]), new objj_method(sel_getUid("darkCheckersColor"), function $BKThemeDescriptor__darkCheckersColor(self, _cmd)
{ with(self)
{
    if (!DarkCheckersColor)
        DarkCheckersColor = objj_msgSend(CPColor, "colorWithPatternImage:", objj_msgSend(objj_msgSend(CPImage, "alloc"), "initWithContentsOfFile:size:", objj_msgSend(objj_msgSend(CPBundle, "bundleForClass:", objj_msgSend(BKThemeDescriptor, "class")), "pathForResource:", "dark-checkers.png"), CGSizeMake(12.0, 12.0)));
    return DarkCheckersColor;
}
},["CPColor"]), new objj_method(sel_getUid("windowBackgroundColor"), function $BKThemeDescriptor__windowBackgroundColor(self, _cmd)
{ with(self)
{
    return objj_msgSend(_CPStandardWindowView, "bodyBackgroundColor");
}
},["CPColor"]), new objj_method(sel_getUid("defaultShowcaseBackgroundColor"), function $BKThemeDescriptor__defaultShowcaseBackgroundColor(self, _cmd)
{ with(self)
{
    return objj_msgSend(_CPStandardWindowView, "bodyBackgroundColor");
}
},["CPColor"]), new objj_method(sel_getUid("showcaseBackgroundColor"), function $BKThemeDescriptor__showcaseBackgroundColor(self, _cmd)
{ with(self)
{
    var className = objj_msgSend(self, "className");
    if (!BackgroundColors[className])
        BackgroundColors[className] = objj_msgSend(self, "defaultShowcaseBackgroundColor");
    return BackgroundColors[className];
}
},["CPColor"]), new objj_method(sel_getUid("setShowcaseBackgroundColor:"), function $BKThemeDescriptor__setShowcaseBackgroundColor_(self, _cmd, aColor)
{ with(self)
{
    BackgroundColors[objj_msgSend(self, "className")] = aColor;
}
},["void","CPColor"]), new objj_method(sel_getUid("itemSize"), function $BKThemeDescriptor__itemSize(self, _cmd)
{ with(self)
{
    var className = objj_msgSend(self, "className");
    if (!ItemSizes[className])
        objj_msgSend(self, "calculateThemedObjectTemplates");
    return CGSizeMakeCopy(ItemSizes[className]);
}
},["CGSize"]), new objj_method(sel_getUid("themedObjectTemplates"), function $BKThemeDescriptor__themedObjectTemplates(self, _cmd)
{ with(self)
{
    var className = objj_msgSend(self, "className");
    if (!ThemedObjects[className])
        objj_msgSend(self, "calculateThemedObjectTemplates");
    return ThemedObjects[className];
}
},["CPArray"]), new objj_method(sel_getUid("calculateThemedObjectTemplates"), function $BKThemeDescriptor__calculateThemedObjectTemplates(self, _cmd)
{ with(self)
{
    var templates = [],
        itemSize = CGSizeMake(0.0, 0.0),
        methods = class_copyMethodList(objj_msgSend(self, "class").isa),
        index = 0,
        count = objj_msgSend(methods, "count");
    for (; index < count; ++index)
    {
        var method = methods[index],
            selector = method_getName(method);
        if (selector.indexOf("themed") !== 0)
            continue;
        var impl = method_getImplementation(method),
            object = impl(self, selector);
        if (!object)
            continue;
        var template = objj_msgSend(objj_msgSend(BKThemedObjectTemplate, "alloc"), "init");
        objj_msgSend(template, "setValue:forKey:", object, "themedObject");
        objj_msgSend(template, "setValue:forKey:", BKLabelFromIdentifier(selector), "label");
        objj_msgSend(templates, "addObject:", template);
        if (objj_msgSend(object, "isKindOfClass:", objj_msgSend(CPView, "class")))
        {
            var size = objj_msgSend(object, "frame").size,
                labelWidth = objj_msgSend(objj_msgSend(template, "valueForKey:", "label"), "sizeWithFont:", objj_msgSend(CPFont, "boldSystemFontOfSize:", 12.0)).width + 20.0;
            if (size.width > itemSize.width)
                itemSize.width = size.width;
            if (labelWidth > itemSize.width)
                itemSize.width = labelWidth;
            if (size.height > itemSize.height)
                itemSize.height = size.height;
        }
    }
    var className = objj_msgSend(self, "className");
    ItemSizes[className] = itemSize;
    ThemedObjects[className] = templates;
}
},["void"]), new objj_method(sel_getUid("compare:"), function $BKThemeDescriptor__compare_(self, _cmd, aThemeDescriptor)
{ with(self)
{
    return objj_msgSend(objj_msgSend(self, "themeName"), "compare:", objj_msgSend(aThemeDescriptor, "themeName"));
}
},["int","BKThemeDescriptor"])]);
}
BKLabelFromIdentifier= function(anIdentifier)
{
    var string = anIdentifier.substr("themed".length);
        index = 0,
        count = string.length,
        label = "",
        lastCapital = null,
        isLeadingCapital = YES;
    for (; index < count; ++index)
    {
        var character = string.charAt(index),
            isCapital = /^[A-Z]/.test(character);
        if (isCapital)
        {
            if (!isLeadingCapital)
            {
                if (lastCapital === null)
                    label += ' ' + character.toLowerCase();
                else
                    label += character;
            }
            lastCapital = character;
        }
        else
        {
            if (isLeadingCapital && lastCapital !== null)
                label += lastCapital;
            label += character;
            lastCapital = null;
            isLeadingCapital = NO;
        }
    }
    return label;
}

p;24;BKThemedObjectTemplate.jt;1209;@STATIC;1.0;I;15;AppKit/CPView.jt;1170;objj_executeFile("AppKit/CPView.j", false);
{var the_class = objj_allocateClassPair(CPView, "BKThemedObjectTemplate"),
meta_class = the_class.isa;class_addIvars(the_class, [new objj_ivar("_label"), new objj_ivar("_themedObject")]);
objj_registerClassPair(the_class);
class_addMethods(the_class, [new objj_method(sel_getUid("initWithCoder:"), function $BKThemedObjectTemplate__initWithCoder_(self, _cmd, aCoder)
{ with(self)
{
    self = objj_msgSendSuper({ receiver:self, super_class:objj_getClass("BKThemedObjectTemplate").super_class }, "init");
    if (self)
    {
        _label = objj_msgSend(aCoder, "decodeObjectForKey:", "BKThemedObjectTemplateLabel");
        _themedObject = objj_msgSend(aCoder, "decodeObjectForKey:", "BKThemedObjectTemplateThemedObject");
    }
    return self;
}
},["id","CPCoder"]), new objj_method(sel_getUid("encodeWithCoder:"), function $BKThemedObjectTemplate__encodeWithCoder_(self, _cmd, aCoder)
{ with(self)
{
    objj_msgSend(aCoder, "encodeObject:forKey:", _label, "BKThemedObjectTemplateLabel");
    objj_msgSend(aCoder, "encodeObject:forKey:", _themedObject, "BKThemedObjectTemplateThemedObject");
}
},["void","CPCoder"])]);
}

p;17;BKThemeTemplate.jt;1157;@STATIC;1.0;I;21;Foundation/CPObject.jt;1112;objj_executeFile("Foundation/CPObject.j", false);
{var the_class = objj_allocateClassPair(CPObject, "BKThemeTemplate"),
meta_class = the_class.isa;class_addIvars(the_class, [new objj_ivar("_name"), new objj_ivar("_description")]);
objj_registerClassPair(the_class);
class_addMethods(the_class, [new objj_method(sel_getUid("initWithCoder:"), function $BKThemeTemplate__initWithCoder_(self, _cmd, aCoder)
{ with(self)
{
    self = objj_msgSendSuper({ receiver:self, super_class:objj_getClass("BKThemeTemplate").super_class }, "init");
    if (self)
    {
        _name = objj_msgSend(aCoder, "decodeObjectForKey:", "BKThemeTemplateName");
        _description = objj_msgSend(aCoder, "decodeObjectForKey:", "BKThemeTemplateDescription");
    }
    return self;
}
},["id","CPCoder"]), new objj_method(sel_getUid("encodeWithCoder:"), function $BKThemeTemplate__encodeWithCoder_(self, _cmd, aCoder)
{ with(self)
{
    objj_msgSend(aCoder, "encodeObject:forKey:", _name, "BKThemeTemplateName");
    objj_msgSend(aCoder, "encodeObject:forKey:", _description, "BKThemeTemplateDescription");
}
},["void","CPCoder"])]);
}

p;10;BlendKit.jt;315;@STATIC;1.0;i;22;BKShowcaseController.ji;19;BKThemeDescriptor.ji;17;BKThemeTemplate.ji;24;BKThemedObjectTemplate.jt;195;objj_executeFile("BKShowcaseController.j", true);
objj_executeFile("BKThemeDescriptor.j", true);
objj_executeFile("BKThemeTemplate.j", true);
objj_executeFile("BKThemedObjectTemplate.j", true);

e;