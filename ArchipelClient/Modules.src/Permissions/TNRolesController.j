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


/*! @ingroup permissionsmodule
    roles controller representation
*/
@implementation TNRolesController : CPObject
{
    @outlet CPButtonBar             buttonBar;
    @outlet CPScrollView            scrollViewTableRoles;
    @outlet CPSearchField           filterField;
    @outlet CPTextField             fieldNewTemplateDescription;
    @outlet CPTextField             fieldNewTemplateName;
    @outlet CPView                  viewTableContainer;
    @outlet CPWindow                mainWindow;
    @outlet CPWindow                windowNewTemplate;

    id                              _delegate           @accessors(property=delegate);

    CPTableView                     _tableRoles;
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
    _tableRoles         = [[CPTableView alloc] initWithFrame:[scrollViewTableRoles bounds]];

    [scrollViewTableRoles setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewTableRoles setAutohidesScrollers:YES];
    [scrollViewTableRoles setDocumentView:_tableRoles];

    [_tableRoles setUsesAlternatingRowBackgroundColors:YES];
    [_tableRoles setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableRoles setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_tableRoles setAllowsColumnReordering:YES];
    [_tableRoles setAllowsColumnResizing:YES];
    [_tableRoles setAllowsEmptySelection:YES];

    var colName         = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        colDescription  = [[CPTableColumn alloc] initWithIdentifier:@"description"],
        colValue        = [[CPTableColumn alloc] initWithIdentifier:@"state"],
        checkBoxView    = [CPCheckBox checkBoxWithTitle:@""];

    [colName setWidth:125];
    [[colName headerView] setStringValue:@"Name"];

    [colDescription setWidth:125];
    [[colDescription headerView] setStringValue:@"Description"];

    [colValue setWidth:30];
    [[colValue headerView] setStringValue:@""];
    [checkBoxView setAlignment:CPCenterTextAlignment];
    [checkBoxView setFrameOrigin:CPPointMake(10.0, 0.0)];
    [checkBoxView setTarget:self];
    [checkBoxView setAction:@selector(changePermissionsState:)];
    [colValue setDataView:checkBoxView];

    [_tableRoles addTableColumn:colValue];
    [_tableRoles addTableColumn:colName];
    [_tableRoles addTableColumn:colDescription];

    [_datasourceRoles setTable:_tableRoles];
    [_datasourceRoles setSearchableKeyPaths:[@"name", @"description"]];
    [_tableRoles setDataSource:_datasourceRoles];

    buttonDelete = [CPButtonBar plusButton];
    [buttonDelete setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/minus.png"] size:CPSizeMake(16, 16)]];
    [buttonDelete setTarget:self];
    [buttonDelete setAction:@selector(deleteSelectedRole:)];
    [buttonDelete setToolTip:@"Delete the selected role"];

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
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Role saved" message:@"Your role has been sucessfully saved."];
}

/*! called when a new role has been published
    @param aNotification the notification
*/
- (void)_didPublishRoleFail:(CPNotification)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemPublishedNotification object:_nodeRolesTemplates];
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemPublishErrorNotification object:_nodeRolesTemplates];
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Role save error" message:@"Your role cannot be saved." icon:TNGrowlIconError];
}

/*! called when a new role has been retracted
    @param aNotification the notification
*/
- (void)_didRectractRole:(CPNotificationCenter)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemRetractedNotification object:_nodeRolesTemplates];
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemRetractErrorNotification object:_nodeRolesTemplates];
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Role deleted" message:@"Your role has been sucessfully deleted."];
}

/*! called when a new role has been retracted
    @param aNotification the notification
*/
- (void)_didRectractRoleFail:(CPNotificationCenter)aNotification
{
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemRetractedNotification object:_nodeRolesTemplates];
    [[CPNotificationCenter defaultCenter] removeObserver:self name:TNStrophePubSubItemRetractErrorNotification object:_nodeRolesTemplates];
    [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Role delete error" message:@"Your role cannot be deleted." icon:TNGrowlIconError];
}


#pragma mark -
#pragma mark Actions

/*! show the controller's main window
    @param aSender the sender of the action
*/
- (IBAction)showWindow:(id)aSender
{
    [self reload];
    [mainWindow center];
    [mainWindow makeKeyAndOrderFront:aSender];

    var frame = [mainWindow frame];
    frame.size.height++;
    [mainWindow setFrame:frame];
    frame.size.height--;
    [mainWindow setFrame:frame];
}

/*! will close the controller's main window
    @param aSender the sender of the action
*/
- (IBAction)hideWindow:(id)aSender
{
    [mainWindow close];
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

/*! will open the new template window
    @param aSender the sender of the action
*/
- (IBAction)openNewTemplateWindow:(id)aSender
{
    [fieldNewTemplateName setStringValue:@""];
    [fieldNewTemplateDescription setStringValue:@""];
    [windowNewTemplate center];
    [windowNewTemplate makeKeyAndOrderFront:aSender];
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

    [windowNewTemplate close];
}

/*! delete the current selected role
    @param aSender the sender of the action
*/
- (IBAction)deleteSelectedRole:(id)aSender
{
    var index = [[_tableRoles selectedRowIndexes] firstIndex],
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
    if (!_nodeRolesTemplates)
    {
        _nodeRolesTemplates = [TNPubSubNode pubSubNodeWithNodeName:@"/archipel/roles" connection:[[TNStropheIMClient defaultClient] connection] pubSubServer:nil];
        [_nodeRolesTemplates setDelegate:self];
        [_nodeRolesTemplates retrieveItems];
    }

    [_datasourceRoles removeAllObjects];

    for (var i = 0; i < [[_nodeRolesTemplates content] count]; i++)
    {
        var role        = [[_nodeRolesTemplates content] objectAtIndex:i],
            name        = [[role firstChildWithName:@"role"] valueForAttribute:@"name"],
            description = [[role firstChildWithName:@"role"] valueForAttribute:@"description"],
            newRole     = [CPDictionary dictionaryWithObjectsAndKeys:name, @"name", description, @"description", CPOffState, @"state", role, @"role"];

        [_datasourceRoles addObject:newRole];
    }

    [_tableRoles reloadData];
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