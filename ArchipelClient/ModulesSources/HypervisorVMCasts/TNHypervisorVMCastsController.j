/*
 * TNVMCasting.j
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
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPOutlineView.j>
@import <AppKit/CPProgressIndicator.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPView.j>
@import <AppKit/CPWindow.j>

@import <TNKit/TNAlert.j>

@import "../../Model/TNModule.j"
@import "TNCellApplianceStatus.j";
@import "TNDownoadObject.j";
@import "TNVMCastDatasource.j";
@import "TNVMCastRegistrationController.j"
@import "TNDownloadQueueController.j"

@global CPLocalizedString
@global CPLocalizedStringFromTableInBundle
@global TNArchipelTypeHypervisorVMCastingDownloadProgress


var TNArchipelVMCastsOpenedVMCasts                      = @"TNArchipelVMCastsOpenedVMCasts_",
    TNArchipelTypeHypervisorVMCasting                   = @"archipel:hypervisor:vmcasting",
    TNArchipelTypeHypervisorVMCastingGet                = @"get",
    TNArchipelTypeHypervisorVMCastingDownload           = @"downloadappliance",
    TNArchipelTypeHypervisorVMCastingDeleteAppliance    = @"deleteappliance",
    TNArchipelPushNotificationVMCasting                 = @"archipel:push:vmcasting";

var TNModuleControlForRegisterVmCast                    = @"RegisterVmCast",
    TNModuleControlForRemoveItem                        = @"RemoveItem",
    TNModuleControlForDownloadApplicance                = @"DownloadApplicance",
    TNModuleControlForShowDownloadQueue                 = @"ShowDownloadQueue";

/*! @defgroup  hypervisorvmcasts Module Hypervisor VMCasts

    @desc This module handle the management of VMCasts
*/


/*! @ingroup hypervisorvmcasts
    Main controller of the module
*/
@implementation TNHypervisorVMCastsController : TNModule
{
    @outlet CPButtonBar                     buttonBarControl;
    @outlet CPCheckBox                      checkBoxOnlyInstalled;
    @outlet CPScrollView                    mainScrollView;
    @outlet CPSearchField                   fieldFilter;
    @outlet CPView                          viewTableContainer;
    @outlet TNVMCastRegistrationController  VMCastRegistrationController;
    @outlet TNDownloadQueueController       downloadQueueController;

    CPOutlineView                           _mainOutlineView        @accessors(getter=mainOutlineView);

    TNVMCastDatasource                      _castsDatasource;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    _castsDatasource = [[TNVMCastDatasource alloc] init];

    _mainOutlineView = [[CPOutlineView alloc] initWithFrame:[mainScrollView bounds]];
    [_mainOutlineView setCornerView:nil];
    [_mainOutlineView setAutoresizingMask:CPViewHeightSizable | CPViewWidthSizable];
    [_mainOutlineView setAllowsColumnResizing:YES];
    [_mainOutlineView setUsesAlternatingRowBackgroundColors:YES];
    [_mainOutlineView setColumnAutoresizingStyle:CPTableViewLastColumnOnlyAutoresizingStyle];
    [_mainOutlineView setDataSource:_castsDatasource];

    var columnName          = [[CPTableColumn alloc] initWithIdentifier:@"name"],
        columnDescription   = [[CPTableColumn alloc] initWithIdentifier:@"comment"],
        columnSize          = [[CPTableColumn alloc] initWithIdentifier:@"size"],
        columnStatus        = [[CPTableColumn alloc] initWithIdentifier:@"status"],
        dataViewPrototype   = [[TNCellApplianceStatus alloc] init];

    [[columnName headerView] setStringValue:CPBundleLocalizedString(@"VMCasts", @"VMCasts")];
    [columnName setWidth:300];
    [columnName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    [[columnDescription headerView] setStringValue:CPBundleLocalizedString(@"Comment", @"Comment")];
    [columnDescription setWidth:250];
    [columnDescription setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"comment" ascending:YES]];

    [[columnSize headerView] setStringValue:CPBundleLocalizedString(@"Size", @"Size")];
    [columnSize setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"size" ascending:YES]];

    [columnStatus setWidth:120];
    [[columnStatus headerView] setStringValue:CPBundleLocalizedString(@"Status", @"Status")];
    [[columnStatus setDataView:dataViewPrototype]];

    [_mainOutlineView setOutlineTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnName];
    [_mainOutlineView addTableColumn:columnSize];
    [_mainOutlineView addTableColumn:columnStatus];
    [_mainOutlineView addTableColumn:columnDescription];

    [mainScrollView setAutohidesScrollers:YES];
    [mainScrollView setDocumentView:_mainOutlineView];
    [_mainOutlineView reloadData];
    [_mainOutlineView recoverExpandedWithBaseKey:TNArchipelVMCastsOpenedVMCasts itemKeyPath:@"name"];

    [_mainOutlineView setTarget:self];
    [_mainOutlineView setDoubleAction:@selector(download:)];

    // filter field
    [fieldFilter setSendsSearchStringImmediately:YES];
    [fieldFilter setTarget:self];
    [fieldFilter setAction:@selector(fieldFilterDidChange:)];


    // create the control items

    [self addControlsWithIdentifier:TNModuleControlForRegisterVmCast
                              title:CPBundleLocalizedString(@"Register to a new VMCast feed", @"Register to a new VMCast feed")
                             target:self
                             action:@selector(openNewVMCastURLWindow:)
                              image:CPImageInBundle(@"IconsButtons/plus.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForRemoveItem
                              title:CPBundleLocalizedString(@"Remove/Unregister", @"Remove/Unregister")
                             target:self
                             action:@selector(remove:)
                              image:CPImageInBundle(@"IconsButtons/minus.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForDownloadApplicance
                              title:CPBundleLocalizedString(@"Download selected appliance", @"Download selected appliance")
                             target:self
                             action:@selector(download:)
                              image:CPImageInBundle(@"IconsButtons/download.png",nil, [CPBundle mainBundle])];

    [self addControlsWithIdentifier:TNModuleControlForShowDownloadQueue
                              title:CPBundleLocalizedString(@"Open download queue", @"Open download queue")
                             target:self
                             action:@selector(showDownloadQueue:)
                              image:CPImageInBundle(@"IconsButtons/view.png",nil, [CPBundle mainBundle])];

    [[self buttonWithIdentifier:TNModuleControlForRemoveItem] setEnabled:NO];
    [[self buttonWithIdentifier:TNModuleControlForDownloadApplicance] setEnabled:NO];

    [buttonBarControl setButtons:[
        [self buttonWithIdentifier:TNModuleControlForRegisterVmCast],
        [self buttonWithIdentifier:TNModuleControlForRemoveItem],
        [self buttonWithIdentifier:TNModuleControlForDownloadApplicance],
        [self buttonWithIdentifier:TNModuleControlForShowDownloadQueue]]];

    [VMCastRegistrationController setDelegate:self];
    [downloadQueueController setDelegate:self];

    [checkBoxOnlyInstalled setState:CPOffState];
}

#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    [_mainOutlineView setDelegate:nil];
    [_mainOutlineView setDelegate:self];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationVMCasting];

    [self getVMCasts];

    return YES;
}

/*! called when module is unloaded
*/
- (void)willHide
{
    [downloadQueueController closeWindow:nil];
    [VMCastRegistrationController closeWindow:nil];

    [_mainOutlineView deselectAll];

    [super willHide];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [super permissionsChanged];
    [self outlineViewSelectionDidChange:NO];
}

/*! called when the UI needs to be updated according to the permissions
*/
- (void)setUIAccordingToPermissions
{
    [self setControl:[self buttonWithIdentifier:TNModuleControlForShowDownloadQueue] enabledAccordingToPermission:@"vmcasting_downloadqueue"];
    [self setControl:[self buttonWithIdentifier:TNModuleControlForRegisterVmCast] enabledAccordingToPermission:@"vmcasting_register"];

    if (![self currentEntityHasPermission:@"vmcasting_downloadqueue"])
        [downloadQueueController closeWindow:nil];

    if (![self currentEntityHasPermission:@"vmcasting_register"])
        [VMCastRegistrationController closeWindow:nil];

    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex],
        currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex];

    if (([currentVMCast isKindOfClass:TNVMCast]) && [self currentEntityHasPermission:@"vmcasting_unregister"])
        [self setControl:[self buttonWithIdentifier:TNModuleControlForRemoveItem] enabledAccordingToPermission:@"vmcasting_unregister"]
    else if (([currentVMCast isKindOfClass:TNVMCastSource]) && [self currentEntityHasPermission:@"vmcasting_deleteappliance"])
        [self setControl:[self buttonWithIdentifier:TNModuleControlForRemoveItem] enabledAccordingToPermission:@"vmcasting_deleteappliance"]
    else
        [[self buttonWithIdentifier:TNModuleControlForRemoveItem] setEnabled:NO];
}

/*! this message is used to flush the UI
*/
- (void)flushUI
{
    [[_castsDatasource contents] removeAllObjects];
    [_mainOutlineView reloadData];
}

#pragma mark -
#pragma mark Notification handlers

/*! called when an Archipel push is received
    @param aNotification CPDictionary containing the push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    [self getVMCasts];

    switch (change)
    {
        case @"download_start":
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name] message:CPBundleLocalizedString(@"Appliance download started", @"Appliance download started")];
            break
        case @"download_complete":
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name] message:CPBundleLocalizedString(@"Appliance download complete", @"Appliance download complete")];
            break;
        case @"download_error":
            [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name] message:CPBundleLocalizedString(@"Appliance download error", @"Appliance download error") icon:TNGrowlIconError];
            break
    }

    return YES;
}


#pragma mark -
#pragma mark Actions

/*! update filter
    @param sender the sender of the action
*/
- (IBAction)fieldFilterDidChange:(id)aSender
{
    [_castsDatasource setFilter:[fieldFilter stringValue]];
    [_mainOutlineView reloadData];
    [_mainOutlineView recoverExpandedWithBaseKey:TNArchipelVMCastsOpenedVMCasts itemKeyPath:@"name"];
}

/*! opens the add VMCast window
    @param sender the sender of the action
*/
- (IBAction)openNewVMCastURLWindow:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    [VMCastRegistrationController openWindow:[self buttonWithIdentifier:TNModuleControlForRegisterVmCast]];
}

/*! called when filter checkbox change
    @param sender the sender of the action
*/
- (IBAction)clickOnFilterCheckBox:(id)aSender
{
    if ([checkBoxOnlyInstalled state] == CPOnState)
        [_castsDatasource setFilterInstalled:YES];
    else
        [_castsDatasource setFilterInstalled:NO];

    [_mainOutlineView reloadData];
    [_mainOutlineView recoverExpandedWithBaseKey:TNArchipelVMCastsOpenedVMCasts itemKeyPath:@"name"];
}

/*! remove a thing (VMCast or Appliance)
    @param sender the sender of the action
*/
- (IBAction)remove:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([_mainOutlineView numberOfSelectedRows] < 1)
        return;

    [self remove];
}

/*! remove an Appliance
    @param sender the sender of the action
*/
- (IBAction)removeAppliance:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([_mainOutlineView numberOfSelectedRows] < 1)
        return;

    if (![[_mainOutlineView itemAtRow:[_mainOutlineView selectedRow]] isKindOfClass:TNVMCast])
        return;

    [self removeAppliance];
}

/*! remove an VMCast
    @param sender the sender of the action
*/
- (IBAction)removeVMCast:(id)someUserInfo
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([_mainOutlineView numberOfSelectedRows] < 1)
        return;

    if (![[_mainOutlineView itemAtRow:[_mainOutlineView selectedRow]] isKindOfClass:TNVMCastSource])
        return;

    [VMCastRegistrationController removeVMCast];
}

/*! starts a download
    @param sender the sender of the action
*/
- (IBAction)download:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    if ([_mainOutlineView numberOfSelectedRows] < 1)
        return;

    if (![[_mainOutlineView itemAtRow:[_mainOutlineView selectedRow]] isKindOfClass:TNVMCast])
        return;

    [self download];
}

/*! show the download queue window
    @param sender the sender of the action
*/
- (IBAction)showDownloadQueue:(id)aSender
{
    [self requestVisible];
    if (![self isVisible])
        return;

    [downloadQueueController showWindow:[self buttonWithIdentifier:TNModuleControlForShowDownloadQueue]];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask hypervisor VMCasts
*/
- (void)getVMCasts
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingGet}];

    [self setModuleStatus:TNArchipelModuleStatusWaiting];
    [self sendStanza:stanza andRegisterSelector:@selector(_didReceiveVMCasts:)];
}

/*! compute the hypervisor answer containing the VMCasts
*/
- (BOOL)_didReceiveVMCasts:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [self flushUI];

        var sources = [aStanza childrenWithName:@"source"];

        for (var i = 0; i < [sources count]; i++)
        {
            var source      = [sources objectAtIndex:i],
                name        = [source valueForAttribute:@"name"],
                url         = [CPURL URLWithString:[source valueForAttribute:@"url"]],
                uuid        = [CPURL URLWithString:[source valueForAttribute:@"uuid"]],
                comment     = [source valueForAttribute:@"description"],
                newSource   = [TNVMCastSource VMCastSourceWithName:name UUID:uuid URL:url comment:comment],
                appliances  = [source childrenWithName:@"appliance"];

            for (var j = 0; j < [appliances count]; j++)
            {
                var appliance   = [appliances objectAtIndex:j],
                    name        = [appliance valueForAttribute:@"name"],
                    url         = [CPURL URLWithString:[appliance valueForAttribute:@"url"]],
                    comment     = [appliance valueForAttribute:@"description"],
                    size        = [appliance valueForAttribute:@"size"],
                    date        = [appliance valueForAttribute:@"pubDate"],
                    uuid        = [appliance valueForAttribute:@"uuid"],
                    status      = parseInt([appliance valueForAttribute:@"status"]),
                    newCast     = [TNVMCast VMCastWithName:name URL:url comment:comment size:size pubDate:date UUID:uuid status:status];

                [[newSource content] addObject:newCast];
            }

            [_castsDatasource addSource:newSource];
        }
        [_mainOutlineView reloadData];
        [_mainOutlineView recoverExpandedWithBaseKey:TNArchipelVMCastsOpenedVMCasts itemKeyPath:@"name"];
        [self setModuleStatus:TNArchipelModuleStatusReady];
    }
    else if ([aStanza type] == @"error")
    {
        [self setModuleStatus:TNArchipelModuleStatusError];
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! ask hypervisor for progress of downloads
    @param aTimer an eventual timer that trigger the message
*/
- (void)updateDownloadProgress:(CPTimer)aTimer
{
    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingDownloadProgress}];

    [_entity sendStanza:stanza andRegisterSelector:@selector(_didDownloadProgress:) ofObject:self];
}

/*! compute the hypervisor answer containing the VMCasts
    @param aStanza TNStropheStanza that contains the hypervisor answer
*/
- (BOOL)_didDownloadProgress:(TNStropheStanza)aStanza
{
    return NO;
}

/*! ask hypervisor to add remove a VMCast or an Appliance
*/
- (void)remove
{
    if (([_mainOutlineView numberOfRows] == 0) || ([_mainOutlineView numberOfSelectedRows] <= 0))
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name] message:CPBundleLocalizedString(@"You must select a VMCast or an Appliance", @"You must select a VMCast or an Appliance") icon:TNGrowlIconError];

        return;
    }

    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex],
        currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex];

    if ([currentVMCast isKindOfClass:TNVMCast])
    {
        if ([currentVMCast status] == TNArchipelApplianceInstalled)
            [self removeAppliance];
    }
    else if ([currentVMCast isKindOfClass:TNVMCastSource])
        [VMCastRegistrationController removeVMCast];
}

/*! ask hypervisor to add remove an Appliance. but before ask user if he is sure.
*/
- (void)removeAppliance
{
    var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Delete appliance", @"Delete appliance")
                                informative:CPBundleLocalizedString(@"Are you sure you want to remove this appliance? This doesn't affect virtual machine that have been instanciated from this template.", @"Are you sure you want to remove this appliance? This doesn't affect virtual machine that have been instanciated from this template.")
                                 target:self
                                 actions:[["Delete", @selector(performRemoveAppliance:)], ["Cancel", nil]]];

    [alert runModal];
}

/*! ask hypervisor to add remove an Appliance
*/
- (void)performRemoveAppliance:(id)someUserInfo
{
    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex],
        currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex],
        uuid            = [currentVMCast UUID],
        stanza          = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingDeleteAppliance,
        "uuid": uuid}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didDeleteAppliance:)];
}

/*! compute the hypervisor answer about removing an appliance
    @param aStanza TNStropheStanza that contains the hypervisor answer
*/
- (BOOL)_didDeleteAppliance:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name] message:CPBundleLocalizedString(@"Appliance has been uninstalled", @"Appliance has been uninstalled")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! ask hypervisor to add download an appliance. but before ask user if he is sure.
*/
- (void)download
{
    var selectedIndex   = [[ _mainOutlineView selectedRowIndexes] firstIndex],
        item            = [_mainOutlineView itemAtRow:selectedIndex];

    if (([item status] != TNArchipelApplianceNotInstalled) && ([item status] != TNArchipelApplianceInstallationError))
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:[_entity name]
                                                         message:CPBundleLocalizedString(@"Appliance is already downloaded. If you want to instanciante it, create a new Virtual Machine and choose Packaging module.", @"Appliance is already downloaded. If you want to instanciante it, create a new Virtual Machine and choose Packaging module.")
                                                            icon:TNGrowlIconError];

        return;
    }

    var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Download", @"Download")
                                informative:CPBundleLocalizedString(@"Are you sure you want to download this appliance?", @"Are you sure you want to download this appliance?")
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Download", @"Download"), @selector(performDownload:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];

    [alert runModal];
}

/*! ask hypervisor to add download an appliance
*/
- (void)performDownload:(id)someUserInfo
{
    var selectedIndex   = [[ _mainOutlineView selectedRowIndexes] firstIndex],
        item            = [_mainOutlineView itemAtRow:selectedIndex],
        uuid            = [item UUID],
        stanza  = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingDownload,
        "uuid": uuid}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didDownload:)]
}

/*! compute the hypervisor answer about downloading appliance
    @param aStanza TNStropheStanza that contains the hypervisor answer
*/
- (BOOL)_didDownload:(TNStropheStanza)aStanza
{
    [downloadQueueController closeWindow:nil];
    [downloadQueueController showWindow:[self buttonWithIdentifier:TNModuleControlForRegisterVmCast]];

    return NO;
}


#pragma mark -
#pragma mark Delegates

- (void)outlineViewSelectionDidChange:(CPNotification)aNotification
{
    [[self buttonWithIdentifier:TNModuleControlForRemoveItem] setEnabled:NO];
    [[self buttonWithIdentifier:TNModuleControlForDownloadApplicance] setEnabled:NO];

    if ([_mainOutlineView numberOfSelectedRows] > 0)
    {
        var selectedIndexes = [_mainOutlineView selectedRowIndexes],
            object          = [_mainOutlineView itemAtRow:[selectedIndexes firstIndex]];

        if ([object isKindOfClass:TNVMCast])
        {
            var conditionNotInstalled = (([object status] == TNArchipelApplianceNotInstalled) || ([object status] == TNArchipelApplianceInstallationError)),
                conditionInstalled = ([object status] == TNArchipelApplianceInstalled);

            [self setControl:[self buttonWithIdentifier:TNModuleControlForDownloadApplicance] enabledAccordingToPermission:@"vmcasting_downloadappliance" specialCondition:conditionNotInstalled];
            [self setControl:[self buttonWithIdentifier:TNModuleControlForRemoveItem] enabledAccordingToPermission:@"vmcasting_deleteappliance" specialCondition:conditionInstalled];
        }
        else if ([object isKindOfClass:TNVMCastSource])
        {
            [self setControl:[self buttonWithIdentifier:TNModuleControlForRemoveItem] enabledAccordingToPermission:@"vmcasting_unregister"];
            [[self buttonWithIdentifier:TNModuleControlForDownloadApplicance] setEnabled:NO]
        }
    }
}

- (void)outlineViewItemWillExpand:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelVMCastsOpenedVMCasts + [item name];

    [[defaults objectForKey:@"TNOutlineViewsExpandedGroups"] setObject:@"expanded" forKey:key];
}

- (void)outlineViewItemWillCollapse:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelVMCastsOpenedVMCasts + [item name];

    [[defaults objectForKey:@"TNOutlineViewsExpandedGroups"] setObject:@"collapsed" forKey:key];
}

/*! Delegate of CPOutlineView for Menu
*/
- (CPMenu)outlineView:(CPOutlineView)anOutlineView menuForTableColumn:(CPTableColumn)aTableColumn item:(int)anItem
{
    if ((anOutlineView != _mainOutlineView) && ([anOutlineView numberOfSelectedRows] > 1))
        return;

    [_contextualMenu removeAllItems];

    if([anOutlineView numberOfSelectedRows] == 0)
    {
       [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForRegisterVmCast]];
       return _contextualMenu;
    }

    var itemRow = [_mainOutlineView rowForItem:anItem];
    if ([_mainOutlineView selectedRow] != itemRow)
        [_mainOutlineView selectRowIndexes:[CPIndexSet indexSetWithIndex:itemRow] byExtendingSelection:NO];

    var selectedIndexes = [_mainOutlineView selectedRowIndexes],
        object          = [_mainOutlineView itemAtRow:[selectedIndexes firstIndex]];

    if (([object isKindOfClass:TNVMCast]) && (([object status] == TNArchipelApplianceNotInstalled) || ([object status] == TNArchipelApplianceInstallationError)))
    {
           [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForDownloadApplicance]];
    }
    else
    {
           [_contextualMenu addItem:[self menuItemWithIdentifier:TNModuleControlForRemoveItem]];
    }

    return _contextualMenu;
}

/* Delegate of CPOutlineView for delete key event
*/
- (void)outlineViewDeleteKeyPressed:(CPOutlineView)anOutlineView
{
    if (anOutlineView != _mainOutlineView)
        return;

    [self remove:anOutlineView];
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNHypervisorVMCastsController], comment);
}


