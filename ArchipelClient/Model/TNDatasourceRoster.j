/*
 * TNDatasourceRoster.j
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

@import <AppKit/CPOutlineView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableColumn.j>

@import <StropheCappuccino/PubSub/TNPubSubNode.j>
@import <StropheCappuccino/TNStropheRoster.j>
@import <StropheCappuccino/TNXMLNode.j>

@global TNArchipelRosterOutlineViewReload
@global TNTagsControllerNodeReadyNotification
@global TNArchipelEntityTypes
@global TNArchipelEntityTypeUser

/*! @global
    @group TNDragType
    Drag type for contacts
*/
TNDragTypeContact   = @"TNDragTypeContact";

/*! @ingroup archipelcore
    Subclass of TNStropheRoster that allow TNOutlineViewRoster to use it as Data Source.
*/
@implementation TNDatasourceRoster  : TNStropheRoster
{
    BOOL                        _hideOfflineContacts    @accessors(getter=isOfflineContactsHidden, setter=setHideOfflineContacts:);
    CPSearchField               _filterField            @accessors(property=filterField);
    CPString                    _filter                 @accessors(property=filter);

    CPDictionary                _tagsRegistry;
    CPArray                     _draggedItems;
    TNPubSubNode                _pubsubTagsNode;
    CPTimer                     _reloadGraceTimer;
}


#pragma mark -
#pragma mark Initialization

+ (TNStropheRoster)rosterWithConnection:(TNStropheConnection)aConnection
{
    return [[TNDatasourceRoster alloc] initWithConnection:aConnection];
}

/*! init the datasource
    @param aConnection a valid connected TNStropheConnection
    @return initialized instance of TNDatasourceRoster
*/
- (id)initWithConnection:(TNStropheConnection)aConnection
{
    if (self = [super initWithConnection:aConnection])
    {
        _filter                     = nil;
        _hideOfflineContacts        = NO;

        // register for notifications that should trigger outlineview reload
        var center = [CPNotificationCenter defaultCenter];

        [center addObserver:self selector:@selector(didTagsNodeReady:) name:TNTagsControllerNodeReadyNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterRetrievedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterContactRemovedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterGroupAddedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactMessageTreatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterGroupRenamedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterGroupRemovedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterPushNotification object:nil];
    }

    return self;
}


/*! analyse the content of vCard will return the TNArchipelEntityType
    @param aVCard TNXMLNode containing the vCard
    @return value of TNArchipelEntityType
*/
- (CPString)analyseVCard:(TNStropheVCard)aVCard
{
    if (aVCard)
    {
        var itemType = [aVCard role];

        if ([TNArchipelEntityTypes containsKey:itemType])
            return itemType;
        else
            return TNArchipelEntityTypeUser;
    }

    return TNArchipelEntityTypeUser;
}

/*! A Shorthand to fetch the description of a registered entity type
    @param anEntity CPString The name of the entity to get the description for.
    @return CPString Returns the localized description of the entity.
*/
- (CPString)entityDescriptionFor:(CPString)anEntity
{
       return [TNArchipelEntityTypes objectForKey:anEntity];
}

#pragma mark -
#pragma mark Notification handlers

/*! Reload the content of the datasource
    @param aNotification CPNotification that trigger the message
*/
- (void)updateOutlineView:(CPNotification)aNotification
{
    if (_reloadGraceTimer)
        [_reloadGraceTimer invalidate];

    _reloadGraceTimer = [CPTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(_performUpdateOutlineView:) userInfo:nil repeats:NO];
}

- (void)_performUpdateOutlineView:(CPTimer)aTimer
{
    [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelRosterOutlineViewReload object:self];
    _reloadGraceTimer = nil;
}

/*! initializes the TNPubSubNode when roster is retreived
    @param aNotification CPNotification that trigger the message
*/
- (void)didTagsNodeReady:(CPNotification)aNotification
{
    _pubsubTagsNode = [aNotification object];
    [self _didTagsRecovered:nil];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didTagsRecovered:) name:TNStrophePubSubNodeRetrievedNotification object:_pubsubTagsNode];
}

/*! will update the content of _tagsRegistry that will be use to filter matching tags
    @param aNotification CPNotification that trigger the message
*/
- (void)_didTagsRecovered:(CPNotification)aNotification
{
    _tagsRegistry = [CPDictionary dictionary];

    for (var i = 0; i < [[_pubsubTagsNode content] count]; i++)
    {
        var tagItem = [[[_pubsubTagsNode content] objectAtIndex:i] firstChildWithName:@"tag"],
            jid     = [tagItem valueForAttribute:@"jid"],
            tags    = [tagItem valueForAttribute:@"tags"];

        if (![_tagsRegistry containsKey:jid])
            [_tagsRegistry setObject:[CPArray array] forKey:jid];

        [[_tagsRegistry objectForKey:jid] addObjectsFromArray:tags.split(";;")];
    }

    if ([_filterField stringValue] != @"")
        [self filterFieldDidChange:_filterField];
}


#pragma mark -
#pragma mark Actions

/*! Action that will be plugged to the CPSearchField in order to catch
    when user changes the value
*/
- (IBAction)filterFieldDidChange:(id)aSender
{
    _filter = [aSender stringValue];
    [self updateOutlineView:nil];
}


#pragma mark -
#pragma mark Filtering


/*! allow to define a CPSearchField to filter entries
    @param aField CPSearchField to use for filtering
*/
- (void)setFilterField:(CPSearchField)aField
{
    _filterField = aField;

    [_filterField setSendsSearchStringImmediately:YES]
    [_filterField setTarget:self];
    [_filterField setAction:@selector(filterFieldDidChange:)];
}

/*! Message use internally for filtering
    @param aFilter CPString containing the filter
    @return a CPArray containing the contacts that matches the filters
*/
- (CPArray)_getEntriesMatching
{
    var theEntries      = [self contacts],
        filteredEntries = [CPArray array];

    if (!_filter)
        return theEntries;

    for (var i = 0; i < [theEntries count]; i++)
    {
        var entry = [theEntries objectAtIndex:i];

        if ([[entry name] uppercaseString].indexOf([_filter uppercaseString]) != -1
            || [[[entry JID] bare] uppercaseString].indexOf([_filter uppercaseString]) != -1
            || [[_tagsRegistry objectForKey:[[entry JID] bare]] containsObject:[_filter lowercaseString]])
        {
            [filteredEntries addObject:entry];
        }
    }
    return filteredEntries;
}


#pragma mark -
#pragma mark Utilities

/*! return group content.
    @param aGroup the group to parse
    @param onlyOnline is TRUE, only online contacts will be returned
    @return CPArray containing group's content
*/
- (CPArray)contentsOfGroup:(TNStropheGroup)aGroup hideOffline:(BOOL)shouldHideOffline
{
    if (!shouldHideOffline)
        return [aGroup content];

    var c = [CPArray array];

    for (var i = 0; i < [[aGroup content] count]; i++)
    {
        var item = [[aGroup content] objectAtIndex:i];

        if ([item isKindOfClass:TNStropheGroup])
            [c addObject:item];
        else if ([item XMPPShow] != TNStropheContactStatusOffline)
            [c addObject:item];
    }

    return c;
}


#pragma mark -
#pragma mark Delegates

/*! delegate of TNPubSubNode that will be sent when an pubsub event is recieved
    it will simply recover the content
*/
- (void)pubsubNode:(TNPubSubNode)aPubSubMode receivedEvent:(TNStropheStanza)aStanza
{
    [_pubsubTagsNode retrieveItems];
}


#pragma mark -
#pragma mark Datasource

/*! CPOutlineView Datasource
*/
- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)item
{
    if (_filter)
        return [[self _getEntriesMatching] count];

    if (!item)
        return [_content count];
    else
    {
        if ([item isKindOfClass:TNStropheContact])
            return 0;
        else
        {
            return [[self contentsOfGroup:item hideOffline:_hideOfflineContacts] count];
        }
    }
}

/*! CPOutlineView Datasource
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)item
{
    if (_filter)
        return NO;

    return [item isKindOfClass:TNStropheGroup];
}

/*! CPOutlineView Datasource
*/
- (id)outlineView:(CPOutlineView)anOutlineView child:(int)index ofItem:(id)item
{
    if (_filter)
        return [[self _getEntriesMatching].sort() objectAtIndex:index];

    if (!item)
        return [_content.sort() objectAtIndex:index];
    else
    {
        if ([item isKindOfClass:TNStropheGroup])
            return [[self contentsOfGroup:item hideOffline:_hideOfflineContacts] objectAtIndex:index];
        else
            return nil;
    }
}

/*! CPOutlineView Datasource
*/
- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    var cid = [tableColumn identifier];

    if (cid == @"name")
        return item;
}

/*! CPOutlineView Datasource
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView writeItems:(CPArray)theItems toPasteboard:(CPPasteBoard)thePasteBoard
{
    _draggedItems = theItems;

    // we check that we only have all contacts or all groups, but not mixed objects
    var baseClass = [[theItems objectAtIndex:0] class];
    for (var i = 0; i < [theItems count]; i++)
        if ([[theItems objectAtIndex:i] class] != baseClass)
            return NO;

    [thePasteBoard declareTypes:[TNDragTypeContact] owner:self];
    [thePasteBoard setData:[CPKeyedArchiver archivedDataWithRootObject:theItems] forType:TNDragTypeContact];

    return YES;
}

/*! CPOutlineView Datasource
*/
- (CPDragOperation)outlineView:(CPOutlineView)anOutlineView validateDrop:(id < CPDraggingInfo >)theInfo proposedItem:(id)theItem proposedChildIndex:(int)theIndex
{
    if ([theItem isKindOfClass:TNStropheGroup])
    {
        [anOutlineView setDropItem:theItem dropChildIndex:theIndex];
        return CPDragOperationEvery;
    }

    [anOutlineView setDropItem:nil dropChildIndex:theIndex];
    return CPDragOperationEvery;
}

/*! CPOutlineView Datasource
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView acceptDrop:(id < CPDraggingInfo >)theInfo item:(id)targetItem childIndex:(int)theIndex
{
    for (var i = 0; i < [_draggedItems count]; i++)
    {
        var draggedItem = [_draggedItems objectAtIndex:i];

        if (targetItem === draggedItem)
            continue;

        switch ([draggedItem class])
        {
            case TNStropheGroup:
                [self moveGroup:draggedItem intoGroup:targetItem];
                break;
            case TNStropheContact:
                [self setGroups:(targetItem) ?  [CPArray arrayWithObject:targetItem] : nil  ofContact:draggedItem];
                break;
        }
    }

    return YES;
}

@end
