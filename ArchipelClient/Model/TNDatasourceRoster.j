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

    BOOL                        _shouldDragDuplicate;
    CPDictionary                _tagsRegistry;
    id                          _draggedItem;
    TNPubSubNode                _pubsubTagsNode;
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
        _filter                 = nil;
        _shouldDragDuplicate    = NO;

        // register for notifications that should trigger outlineview reload
        var center = [CPNotificationCenter defaultCenter];

        [center addObserver:self selector:@selector(didTagsNodeReady:) name:TNTagsControllerNodeReadyNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterRetrievedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterRemovedContactNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterAddedContactNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactPresenceUpdatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactNicknameUpdatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterAddedGroupNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactMessageTreatedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheContactVCardReceivedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheGroupRenamedNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterRemovedGroupNotification object:nil];
        [center addObserver:self selector:@selector(updateOutlineView:) name:TNStropheRosterPushNotification object:nil];
    }

    return self;
}


/*! analyse the content of vCard will return the TNArchipelEntityType
    @param aVCard TNXMLNode containing the vCard
    @return value of TNArchipelEntityType
*/
- (CPString)analyseVCard:(TNXMLNode)aVCard
{
    if (aVCard)
    {
        var itemType = [[aVCard firstChildWithName:@"ROLE"] text];

        if ((itemType == TNArchipelEntityTypeVirtualMachine)
            || (itemType == TNArchipelEntityTypeHypervisor)
            || (itemType == TNArchipelEntityTypeGroup))
            return itemType;
        else
            return TNArchipelEntityTypeUser;
    }

    return TNArchipelEntityTypeUser;
}



#pragma mark -
#pragma mark Notification handlers

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

        if (([[entry nickname] uppercaseString].indexOf([_filter uppercaseString]) != -1)
            || [[_tagsRegistry objectForKey:[[entry JID] bare]] containsObject:[_filter lowercaseString]])
        {
            [filteredEntries addObject:entry];
        }
    }
    return filteredEntries;
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
        return ([item isKindOfClass:TNStropheContact]) ? 0 : [[item content] count];
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
            return [[item content] objectAtIndex:index];
        else
            return nil;
    }
}

/*! CPOutlineView Datasource
*/
- (id)outlineView:(CPOutlineView)anOutlineView objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{
    var cid = [tableColumn identifier];

    if (cid == @"nickname")
        return item;
}

/*! CPOutlineView Datasource
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView writeItems:(CPArray)theItems toPasteboard:(CPPasteBoard)thePasteBoard
{
    _draggedItem = [theItems objectAtIndex:0];

    if ([[CPApp currentEvent] modifierFlags] & CPAlternateKeyMask)
    {
        _shouldDragDuplicate = YES;
        [[CPCursor dragCopyCursor] set];
    }


    [thePasteBoard declareTypes:[TNDragTypeContact] owner:self];
    [thePasteBoard setData:[CPKeyedArchiver archivedDataWithRootObject:theItems] forType:TNDragTypeContact];

    return YES;
}

/*! CPOutlineView Datasource
*/
- (CPDragOperation)outlineView:(CPOutlineView)anOutlineView validateDrop:(id < CPDraggingInfo >)theInfo proposedItem:(id)theItem proposedChildIndex:(int)theIndex
{
    if (([_draggedItem isKindOfClass:TNStropheContact]) && ([theItem isKindOfClass:TNStropheGroup]))
    {
        [anOutlineView setDropItem:theItem dropChildIndex:theIndex];
        return CPDragOperationEvery;
    }
    else if (([_draggedItem isKindOfClass:TNStropheGroup]) && ([theItem isKindOfClass:TNStropheGroup]))
    {
        [anOutlineView setDropItem:theItem dropChildIndex:theIndex];
        return CPDragOperationEvery;
    }
    else
    {
        [anOutlineView setDropItem:nil dropChildIndex:theIndex];
        return CPDragOperationEvery;
    }

    return CPDragOperationNone;
}

/*! CPOutlineView Datasource
*/
- (BOOL)outlineView:(CPOutlineView)anOutlineView acceptDrop:(id < CPDraggingInfo >)theInfo item:(id)theItem childIndex:(int)theIndex
{
    if (([_draggedItem isKindOfClass:TNStropheGroup]) && ([theItem isKindOfClass:TNStropheGroup]) && (theItem  != _draggedItem))
    {
        var center          = [CPNotificationCenter defaultCenter],
            contactsToMove  = [[_draggedItem contacts] copy];

        if ([_draggedItem parentGroup])
            [[_draggedItem parentGroup] removeSubGroup:_draggedItem];
        else
            [_content removeObject:_draggedItem];

        [theItem addSubGroup:_draggedItem];
        [self sendRosterSet:[self getAllContactsTreeFromGroup:_draggedItem]];

        _shouldDragDuplicate = NO;

        return YES;
    }
    else if (([_draggedItem isKindOfClass:TNStropheContact]) && ([theItem isKindOfClass:TNStropheGroup]))
    {
        if (_shouldDragDuplicate)
            [self addContact:_draggedItem inGroup:theItem push:YES];
        else
            [self setGroups:[CPArray arrayWithObject:theItem] ofContact:_draggedItem];
        _shouldDragDuplicate = NO;
        [[CPCursor arrowCursor] set];

        return YES;
    }
    else
    {
        if ([_content containsObject:_draggedItem])
            return NO;

        if ([_draggedItem isKindOfClass:TNStropheGroup])
        {
            var affectedContacts = [self getAllContactsTreeFromGroup:_draggedItem];

            if ([_draggedItem parentGroup])
                [[_draggedItem parentGroup] removeSubGroup:_draggedItem];

            [_content addObject:_draggedItem];
            [self sendRosterSet:affectedContacts];
        }
        else
        {
            [self setGroups:[CPArray array] ofContact:_draggedItem];
        }
        return YES;
    }

    return NO;
}

@end