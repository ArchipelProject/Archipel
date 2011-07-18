/*
 * TNRolesController.j
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

@import <AppKit/CPButton.j>
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPView.j>



/*! @ingroup permissionsmodule
    roles controller representation
*/
@implementation TNRolesController : CPObject
{
    @outlet CPButton                buttonSave;
    @outlet CPButtonBar             buttonBar;
    @outlet CPPopover               mainPopover;
    @outlet CPPopover               popoverNewTemplate;
    @outlet CPSearchField           filterField;
    @outlet CPTableView             tableRoles;
    @outlet CPTextField             fieldNewTemplateDescription;
    @outlet CPTextField             fieldNewTemplateName;
    @outlet CPView                  viewTableContainer;

    id                              _delegate           @accessors(property=delegate);

    TNPubSubNode                    _nodeRolesTemplates;
    TNTableViewDataSource           _datasourceRoles;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    _datasourceRoles    = [[TNTableViewDataSource alloc] init];
    [_datasourceRoles setTable:tableRoles];
    [_datasourceRoles setSearchableKeyPaths:[@"name", @"description"]];
    [tableRoles setDataSource:_datasourceRoles];

    buttonDelete = [CPButtonBar plusButton];
    [buttonDelete setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/minus.png"] size:CPSizeMake(16, 16)]];
    [buttonDelete setTarget:self];
    [buttonDelete setAction:@selector(deleteSelectedRole:)];
    [buttonDelete setToolTip:CPBundleLocalizedString(@"Delete the selected role", @"Delete the selected role")];

    [buttonBar setButtons:[buttonDelete]];

    [filterField setTarget:_datasourceRoles];
    [filterField setAction:@selector(filterObjects:)];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when a new role has been published
    @param aNotification the notification
*/
- (void)_didPublishRole:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemPublishedNotification object:_nodeRolesTemplates];
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemPublishErrorNotification object:_nodeRolesTemplates];
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                     message:CPBundleLocalizedString(@"Your role has been sucessfully saved.", @"Your role has been sucessfully saved.")];
}

/*! called when a new role has been published
    @param aNotification the notification
*/
- (void)_didPublishRoleFail:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemPublishedNotification object:_nodeRolesTemplates];
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemPublishErrorNotification object:_nodeRolesTemplates];
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                     message:CPBundleLocalizedString(@"Your role cannot be saved.", @"Your role cannot be saved.")
                                                        icon:TNGrowlIconError];
}

/*! called when a new role has been retracted
    @param aNotification the notification
*/
- (void)_didRectractRole:(CPNotificationCenter)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemRetractedNotification object:_nodeRolesTemplates];
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemRetractErrorNotification object:_nodeRolesTemplates];
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                     message:CPBundleLocalizedString(@"Your role has been sucessfully deleted.", @"Your role has been sucessfully deleted.")];
}

/*! called when a new role has been retracted
    @param aNotification the notification
*/
- (void)_didRectractRoleFail:(CPNotificationCenter)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemRetractedNotification object:_nodeRolesTemplates];
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemRetractErrorNotification object:_nodeRolesTemplates];
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[[_delegate entity] nickname]
                                                     message:CPBundleLocalizedString(@"Your role cannot be deleted.", @"Your role cannot be deleted.")
                                                        icon:TNGrowlIconError];
}


#pragma mark -
#pragma mark Actions

/*! show the controller's main window
    @param aSender the sender of the action
*/
- (IBAction)openWindow:(id)aSender
{
    [self reload];
    [mainPopover close];
    [mainPopover showRelativeToRect:nil ofView:aSender preferredEdge:nil];
}

/*! will close the controller's main window
    @param aSender the sender of the action
*/
- (IBAction)closeWindow:(id)aSender
{
    [mainPopover close];
}

/*! will open the new template window
    @param aSender the sender of the action
*/
- (IBAction)openNewTemplateWindow:(id)aSender
{
    [fieldNewTemplateName setStringValue:@""];
    [fieldNewTemplateDescription setStringValue:@""];

    [popoverNewTemplate showRelativeToRect:nil ofView:aSender preferredEdge:nil];
    [popoverNewTemplate makeFirstResponder:fieldNewTemplateName];
    [popoverNewTemplate setDefaultButton:buttonSave];
}

/*! close the new template window
    @param aSender the sender of the action
*/
- (IBAction)closeNewTemplateWindow:(id)aSender
{
    [popoverNewTemplate close];
}

/*! apply selected roles to delegate's role datasource
    @param aSender the sender of the action
*/
- (IBAction)applyRoles:(id)aSender
{
    [_delegate applyPermissions:[self buildPermissionsArray]];
}

/*! add selected roles to delegate's role datasource
    @param aSender the sender of the action
*/
- (IBAction)addRoles:(id)aSender
{
    [_delegate addPermissions:[self buildPermissionsArray]];
}

/*! retract selected roles to delegate's role datasource
    @param aSender the sender of the action
*/
- (IBAction)retractRoles:(id)aSender
{
    [_delegate retractPermissions:[self buildPermissionsArray]];
}

/*! save the current set of permission as a role template
    @param aSender the sender of the action
*/
- (IBAction)saveRole:(id)aSender
{
    var template = [TNXMLNode nodeWithName:@"role"];

    [template setValue:[[[TNStropheIMClient defaultClient] JID] bare] forAttribute:@"creator"];
    [template setValue:[fieldNewTemplateName stringValue] forAttribute:@"name"];
    [template setValue:[fieldNewTemplateDescription stringValue] forAttribute:@"description"];

    for (var i = 0; i < [[_delegate datasourcePermissions] count]; i++)
    {
        var perm = [[_delegate datasourcePermissions] objectAtIndex:i];
        if ([perm valueForKey:@"state"] === CPOnState)
        {
            [template addChildWithName:@"permission" andAttributes:{
                @"permission_target": @"template",
                @"permission_type": @"user",
                @"permission_name": [perm objectForKey:@"name"],
                @"permission_value": @"true",
            }];
            [template up];
        }
    }
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didPublishRole:) name:TNStrophePubSubItemPublishedNotification object:_nodeRolesTemplates];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didPublishRoleFail:) name:TNStrophePubSubItemPublishErrorNotification object:_nodeRolesTemplates];
    [_nodeRolesTemplates publishItem:template];
    [popoverNewTemplate close];
}

/*! delete the current selected role
    @param aSender the sender of the action
*/
- (IBAction)deleteSelectedRole:(id)aSender
{
    var index = [[tableRoles selectedRowIndexes] firstIndex],
        role = [[_datasourceRoles objectAtIndex:index] valueForKey:@"role"];

    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didRectractRole:) name:TNStrophePubSubItemRetractedNotification object:_nodeRolesTemplates];
    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(_didRectractRoleFail:) name:TNStrophePubSubItemRetractErrorNotification object:_nodeRolesTemplates];
    [_nodeRolesTemplates retractItem:role];
}


#pragma mark -
#pragma mark Utilities

/*! build a CPArray containing all permissions of selected roles
    @return CPArray containing all permissions
*/
- (CPArray)buildPermissionsArray
{
    var permissions = [CPArray array];

    for (var i = 0; i < [_datasourceRoles count]; i++)
    {
        var datasourceObject    = [_datasourceRoles objectAtIndex:i];

        if ([datasourceObject valueForKey:@"state"] === CPOnState)
        {
            var currentPerms = [[datasourceObject valueForKey:@"role"] childrenWithName:@"permission"];
            [permissions addObjectsFromArray:currentPerms];
        }
    }

    return permissions;
}

/*! reload the content of the permission table
*/
- (void)reload
{
    [_datasourceRoles removeAllObjects];

    for (var i = 0; i < [[_nodeRolesTemplates content] count]; i++)
    {
        var role        = [[_nodeRolesTemplates content] objectAtIndex:i],
            name        = [[role firstChildWithName:@"role"] valueForAttribute:@"name"],
            description = [[role firstChildWithName:@"role"] valueForAttribute:@"description"],
            newRole     = [CPDictionary dictionaryWithObjectsAndKeys:name, @"name", description, @"description", CPOffState, @"state", role, @"role"];

        [_datasourceRoles addObject:newRole];
    }

    [tableRoles reloadData];
}

/*! fetch the role node if needed
*/
- (void)fetchPubSubNodeIfNeeded
{
    if (!_nodeRolesTemplates)
    {
        _nodeRolesTemplates = [TNPubSubNode pubSubNodeWithNodeName:@"/archipel/roles" connection:[[TNStropheIMClient defaultClient] connection] pubSubServer:nil];
        [_nodeRolesTemplates setDelegate:self];
        [_nodeRolesTemplates retrieveItems];
    }
}


#pragma mark -
#pragma mark Delegates

/*! delegate of TNPubSubNode
*/
- (void)pubSubNode:(TNPubSubNode)aNode retrievedItems:(BOOL)hasRetrievedItems
{
    [self reload];
}

/*! delegate of TNPubSubNode
*/
- (void)pubSubNode:(TNPubSubNode)aNode receivedEvent:(TNStropheStanza)aStanza
{
    if (_nodeRolesTemplates)
        [_nodeRolesTemplates retrievedItems];
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNRolesController], comment);
}