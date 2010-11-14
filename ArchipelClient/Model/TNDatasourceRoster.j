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
@import <AppKit/AppKit.j>
@import <StropheCappuccino/StropheCappuccino.j>

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
    CPSearchField               _filterField        @accessors(property=filterField);
    CPString                    _filter             @accessors(property=filter);

    TNPubSubNode                _pubsubTagsNode;
    id                          _draggedItem;
    CPDictionary                _tagsRegistry;
}


//#pragma mark -
//#pragma mark Initialization

/*! init the datasource
    @param aConnection a valid connected TNStropheConnection
    @return initialized instance of TNDatasourceRoster
*/
- (id)initWithConnection:(TNStropheConnection)aConnection
{
    if (self = [super initWithConnection:aConnection])
    {
        _filter = nil;

        // register for notifications that should trigger outlineview reload
        var center = [CPNotificationCenter defaultCenter];

        [center addObserver:self selector:@selector(didTagsNodeReady:) name:TNTagsControllerNodeReadyNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterRetrievedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterRemovedContactNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterAddedContactNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactPresenceUpdatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactNicknameUpdatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactGroupUpdatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterAddedGroupNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactMessageTreatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactVCardReceivedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheGroupRenamedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterRemovedGroupNotification object:nil];
    }

    return self;
}


//#pragma mark -
//#pragma mark Notification handlers


/*! Reload the content of the datasource
    @param aNotification CPNotification that trigger the message
*/
- (void)updateOutlineView:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] postNotificationName:TNArchipelRosterOutlineViewReload object:self];
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
        var tag     = [[[_pubsubTagsNode content] objectAtIndex:i] firstChildWithName:@"tag"],
            jid     = [tag valueForAttribute:@"jid"],
            name    = [tag valueForAttribute:@"name"];

        if (![_tagsRegistry containsKey:jid])
            [_tagsRegistry setObject:[CPArray array] forKey:jid];

        [[_tagsRegistry objectForKey:jid] addObject:name];
    }

    if ([_filterField stringValue] != @"")
        [self filterFieldDidChange:_filterField];
}


//#pragma mark -
//#pragma mark Actions

/*! Action that will be plugged to the CPSearchField in order to catch
    when user changes the value
*/
- (IBAction)filterFieldDidChange:(id)aSender
{
    _filter = [aSender stringValue];
    [self updateOutlineView:nil];
}


//#pragma mark -
//#pragma mark Filtering


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
- (CPArray)_getEntriesMatching:(CPString)aFilter
{
    var theEntries      = [self contacts],
        filteredEntries = [CPArray array];

    if (!aFilter)
        return theEntries;

    for (var i = 0; i < [theEntries count]; i++)
    {
        var entry = [theEntries objectAtIndex:i];

        if (([[entry nickname] uppercaseString].indexOf([aFilter uppercaseString]) != -1)
            || [[_tagsRegistry objectForKey:[entry JID]] containsObject:[aFilter uppercaseString]])
        {
            [filteredEntries addObject:entry];
        }
    }
    return filteredEntries;
}

/*! Message use internally for filtering
    @param aFilter CPString containing the filter
    @param inGroup CPString containing the group of filter
    @return a CPArray containing the contacts in aGroup that matches the filters
*/
- (CPArray)_getEntriesMatching:(CPString)aFilter inGroup:(TNStropheGroup)aGroup
{
    var filteredEntries = [CPArray array];

    if (!aFilter)
        return [aGroup contacts];

    for (var i = 0; i < [[aGroup contacts] count]; i++)
    {
        var entry = [[aGroup contacts] objectAtIndex:i];

        if (([[entry nickname] uppercaseString].indexOf([aFilter uppercaseString]) != -1)
            || [[_tagsRegistry objectForKey:[entry JID]] containsObject:[aFilter lowercaseString]])
            [filteredEntries addObject:entry];
    }

    return filteredEntries;
}


/*! Message use internally for filtering
    @param aFilter CPString containing the filter
    @return a CPArray groups containing contacts matching aFilter
*/
- (CPArray)_getGroupContainingEntriesMatching:(CPString)aFilter
{
    var theGroups       = [self groups],
        filteredGroup   = [CPArray array];

    if (!aFilter)
        return [self groups];

    for (var i = 0; i < [theGroups count]; i++)
    {
        var group = [theGroups objectAtIndex:i];

        if ([[self _getEntriesMatching:aFilter inGroup:group] count] > 0)
            [filteredGroup addObject:group];
    }

    return filteredGroup;
}


//#pragma mark -
//#pragma mark Delegates

/*! delegate of TNPubSubNode that will be sent when an pubsub event is recieved
    it will simply recover the content
*/
- (void)pubsubNode:(TNPubSubNode)aPubSubMode receivedEvent:(TNStropheStanza)aStanza
{
    [_pubsubTagsNode retrieveItems];
}


//#pragma mark -
//#pragma mark Datasource

/*! CPOutlineView Datasource
*/
- (int)outlineView:(CPOutlineView)anOutlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
    {
        return [[self _getGroupContainingEntriesMatching:_filter] count];
    }
    else
    {
        return [[self _getEntriesMatching:_filter inGroup:item] count];
    }
}

/*! CPOutlineView Datasource
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView isItemExpandable:(id)item
{
    return ([item class] == TNStropheGroup) ? YES : NO;
}

/*! CPOutlineView Datasource
*/
- (id)outlineView:(CPOutlineView)anOutlineView child:(int)index ofItem:(id)item
{
    if (!item)
    {
        return [[self _getGroupContainingEntriesMatching:_filter].sort() objectAtIndex:index];
    }
    else
    {
        return [[self _getEntriesMatching:_filter inGroup:item].sort() objectAtIndex:index];
    }
}

/*! CPOutlineView Datasource
*/
- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    var cid = [tableColumn identifier];

    if (cid == @"nickname")
    {
        return item;
    }
}

/*! CPOutlineView Datasource
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView writeItems:(CPArray)theItems toPasteboard:(CPPasteBoard)thePasteBoard
{
    _draggedItem = [theItems objectAtIndex:0];

    [thePasteBoard declareTypes:[TNDragTypeContact] owner:self];
    [thePasteBoard setData:[CPKeyedArchiver archivedDataWithRootObject:theItems] forType:TNDragTypeContact];

    return YES;
}

/*! CPOutlineView Datasource
*/
- (CPDragOperation)outlineView:(CPOutlineView)anOutlineView validateDrop:(id < CPDraggingInfo >)theInfo proposedItem:(id)theItem proposedChildIndex:(int)theIndex
{
    if (([_draggedItem class] == TNStropheContact) && ([theItem class] == TNStropheGroup))
    {
        [anOutlineView setDropItem:theItem dropChildIndex:theIndex];
        return CPDragOperationEvery;
    }
    else if (([_draggedItem class] == TNStropheGroup) && ([theItem class] == TNStropheGroup))
    {
        [anOutlineView setDropItem:theItem dropChildIndex:theIndex];
        return CPDragOperationEvery;
    }

    return CPDragOperationNone;
}

/*! CPOutlineView Datasource
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView acceptDrop:(id < CPDraggingInfo >)theInfo item:(id)theItem childIndex:(int)theIndex
{
    if (([_draggedItem class] == TNStropheGroup) && ([theItem class] == TNStropheGroup) && (theItem  != _draggedItem))
    {
        var center          = [CPNotificationCenter defaultCenter],
            contactsToMove  = [[_draggedItem contacts] copy];

        for (var i = 0; i < [contactsToMove count]; i++)
        {
            var contact = [contactsToMove objectAtIndex:i];

            [self changeGroup:theItem ofContact:contact];
        }

        [self removeGroup:_draggedItem];
        [anOutlineView reloadData];

        return YES;
    }
    else if (([_draggedItem class] == TNStropheContact) && ([theItem class] == TNStropheGroup))
    {
        [self changeGroup:theItem ofContact:_draggedItem];
        [anOutlineView reloadData];

        return YES;
    }

    return NO;
}


@end