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
@import <TNKit/TNUIKitScrollView.j>

@import "TNCellApplianceStatus.j";
@import "TNDownoadObject.j";
@import "TNVMCastDatasource.j";



var TNArchipelVMCastsOpenedVMCasts                      = @"TNArchipelVMCastsOpenedVMCasts_",
    TNArchipelTypeHypervisorVMCasting                   = @"archipel:hypervisor:vmcasting",
    TNArchipelTypeHypervisorVMCastingGet                = @"get",
    TNArchipelTypeHypervisorVMCastingRegister           = @"register",
    TNArchipelTypeHypervisorVMCastingUnregister         = @"unregister",
    TNArchipelTypeHypervisorVMCastingDownload           = @"downloadappliance",
    TNArchipelTypeHypervisorVMCastingDeleteAppliance    = @"deleteappliance",
    TNArchipelPushNotificationVMCasting                 = @"archipel:push:vmcasting";

/*! @defgroup  hypervisorvmcasts Module Hypervisor VMCasts

    @desc This module handle the management of VMCasts
*/


/*! @ingroup hypervisorvmcasts
    Main controller of the module
*/
@implementation TNHypervisorVMCastsController : TNModule
{
    @outlet CPButtonBar         buttonBarControl;
    @outlet CPCheckBox          checkBoxOnlyInstalled;
    @outlet TNUIKitScrollView   mainScrollView;
    @outlet CPSearchField       fieldFilter;
    @outlet CPTextField         fieldNewURL;
    @outlet CPView              viewTableContainer;
    @outlet CPWindow            windowDownloadQueue;
    @outlet CPWindow            windowNewCastURL;

    CPButton                    _downloadButton;
    CPButton                    _downloadQueueButton;
    CPButton                    _minusButton;
    CPButton                    _plusButton;
    CPOutlineView               _mainOutlineView;
    TNVMCastDatasource          _castsDatasource;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    [fieldNewURL setValue:[CPColor grayColor] forThemeAttribute:@"text-color" inState:CPTextFieldStatePlaceholder];
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
        columnUrl           = [[CPTableColumn alloc] initWithIdentifier:@"URL"],
        columnSize          = [[CPTableColumn alloc] initWithIdentifier:@"size"],
        columnStatus        = [[CPTableColumn alloc] initWithIdentifier:@"status"],
        dataViewPrototype   = [[TNCellApplianceStatus alloc] init];

    [[columnName headerView] setStringValue:CPBundleLocalizedString(@"VMCasts", @"VMCasts")];
    [columnName setWidth:300];
    [columnName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]];

    [[columnDescription headerView] setStringValue:CPBundleLocalizedString(@"Comment", @"Comment")];
    [columnDescription setWidth:250];
    [columnDescription setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"comment" ascending:YES]];

    [[columnUrl headerView] setStringValue:CPBundleLocalizedString(@"URL", @"URL")];
    [columnUrl setWidth:250];
    [columnUrl setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"URL" ascending:YES]];

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
    //[_mainOutlineView addTableColumn:columnUrl]


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


    // menuBar
    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(openNewVMCastURLWindow:)];
    [_plusButton setToolTip:CPBundleLocalizedString(@"Register to a new VMCast feed", @"Register to a new VMCast feed")];

    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(remove:)];
    [_minusButton setToolTip:CPBundleLocalizedString(@"Unregister from a VMCast feed", @"Unregister from a VMCast feed")];

    _downloadButton = [CPButtonBar plusButton];
    [_downloadButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/download.png"] size:CPSizeMake(16, 16)]];
    [_downloadButton setTarget:self];
    [_downloadButton setAction:@selector(download:)];
    [_downloadButton setToolTip:CPBundleLocalizedString(@"Start to download selected appliance", @"Start to download selected appliance")];

    _downloadQueueButton = [CPButtonBar plusButton];
    [_downloadQueueButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/view.png"] size:CPSizeMake(16, 16)]];
    [_downloadQueueButton setTarget:self];
    [_downloadQueueButton setAction:@selector(showDownloadQueue:)];
    [_downloadQueueButton setToolTip:CPBundleLocalizedString(@"Show all current downloads", @"Show all current downloads")];

    [_minusButton setEnabled:NO];
    [_downloadButton setEnabled:NO];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _downloadButton, _downloadQueueButton]];

    [checkBoxOnlyInstalled setToolTip:CPBundleLocalizedString(@"If checked, it will only displayed installed appliances", @"If checked, it will only displayed installed appliances")];
}

#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];

    [windowDownloadQueue setEntity:_entity];
    [_mainOutlineView setDelegate:nil];
    [_mainOutlineView setDelegate:self];

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationVMCasting];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [self getVMCasts];
}

/*! called when module is unloaded
*/
- (void)willUnload
{
    [windowDownloadQueue orderOut:nil];
    [windowNewCastURL orderOut:nil];

    [_mainOutlineView deselectAll];

    [[_castsDatasource contents] removeAllObjects];
    [_mainOutlineView reloadData];

    [super willUnload];
}

/*! called when module becomes unvisible
*/
- (void)willHide
{
    [super willHide];
    // message sent when the tab is changed
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Register to a new VMCasts", @"Register to a new VMCasts") action:@selector(openNewVMCastURLWindow:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Unregister from selected VMCast", @"Unregister from selected VMCast") action:@selector(removeVMCast:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Download selected appliance", @"Download selected appliance") action:@selector(download:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Remove selected appliance", @"Remove selected appliance") action:@selector(removeAppliance:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:CPBundleLocalizedString(@"Show activity monitor", @"Show activity monitor") action:@selector(showDownloadQueue:) keyEquivalent:@""] setTarget:self];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [self setControl:_downloadQueueButton enabledAccordingToPermission:@"vmcasting_downloadqueue"];
    [self setControl:_plusButton enabledAccordingToPermission:@"vmcasting_register"];

    if (![self currentEntityHasPermission:@"vmcasting_downloadqueue"])
        [windowDownloadQueue close];

    if (![self currentEntityHasPermission:@"vmcasting_register"])
        [windowNewCastURL close];

    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex],
        currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex];

    if (([currentVMCast isKindOfClass:TNVMCast]) && [self currentEntityHasPermission:@"vmcasting_unregister"])
        [self setControl:_minusButton enabledAccordingToPermission:@"vmcasting_unregister"]
    else if (([currentVMCast isKindOfClass:TNVMCastSource]) && [self currentEntityHasPermission:@"vmcasting_deleteappliance"])
        [self setControl:_minusButton enabledAccordingToPermission:@"vmcasting_deleteappliance"]
    else
        [_minusButton setEnabled:NO];


    [self outlineViewSelectionDidChange:NO];
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

    CPLog.info(@"PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);

    [self getVMCasts];

    if (change == @"download_complete")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Appliance", @"Appliance") message:CPBundleLocalizedString(@"Download complete", @"Download complete")];
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
    [fieldNewURL setStringValue:@""];
    [windowNewCastURL makeKeyAndOrderFront:nil];
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

/*! add new VMCast
    @param sender the sender of the action
*/
- (IBAction)addNewVMCast:(id)aSender
{
    [windowNewCastURL close];
    [self addNewVMCast];
}

/*! remove a thing (VMCast or Appliance)
    @param sender the sender of the action
*/
- (IBAction)remove:(id)aSender
{
    [self remove];
}

/*! remove an Appliance
    @param sender the sender of the action
*/
- (IBAction)removeAppliance:(id)aSender
{
    [self removeAppliance];
}

/*! remove an VMCast
    @param sender the sender of the action
*/
- (IBAction)removeVMCast:(id)someUserInfo
{
    [self removeVMCast];
}

/*! starts a download
    @param sender the sender of the action
*/
- (IBAction)download:(id)aSender
{
    [self download];
}

/*! show the download queue window
    @param sender the sender of the action
*/
- (IBAction)showDownloadQueue:(id)aSender
{
    [windowNewCastURL setTitle:CPBundleLocalizedString(@"Download queue for ", @"Download queue for ") + [_entity nickname]];
    [windowDownloadQueue makeKeyAndOrderFront:nil];
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
        [[_castsDatasource contents] removeAllObjects];

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

/*! ask hypervisor to add VMCasts
*/
- (void)addNewVMCast
{
    [windowNewCastURL orderOut:nil];

    var stanza      = [TNStropheStanza iqWithType:@"set"],
        url         = [fieldNewURL stringValue];

    [fieldNewURL setStringValue:@""];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingRegister,
        "url": url}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didAddNewVMCast:)];
}

/*! compute the hypervisor answer about adding a VMCast
    @param aStanza TNStropheStanza that contains the hypervisor answer
*/
- (BOOL)_didAddNewVMCast:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"VMCast", @"VMCast") message:CPBundleLocalizedString(@"VMcast has been registred", @"VMcast has been registred")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}

/*! ask hypervisor to add remove a VMCast or an Appliance
*/
- (void)remove
{
    if (([_mainOutlineView numberOfRows] == 0) || ([_mainOutlineView numberOfSelectedRows] <= 0))
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"VMCast", @"VMCast") message:CPBundleLocalizedString(@"You must select a VMCast or an Appliance", @"You must select a VMCast or an Appliance") icon:TNGrowlIconError];

        return;
    }

    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex],
        currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex];

    if ([currentVMCast isKindOfClass:TNVMCast])
        [self removeAppliance];
    else if ([currentVMCast isKindOfClass:TNVMCastSource])
        [self removeVMCast];

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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"Appliance", @"Appliance") message:CPBundleLocalizedString(@"Appliance has been uninstalled", @"Appliance has been uninstalled")];
    else
        [self handleIqErrorFromStanza:aStanza];

    return NO;
}


/*! ask hypervisor to add remove an VMCast. but before ask user if he is sure.
*/
- (void)removeVMCast
{
    var alert = [TNAlert alertWithMessage:CPBundleLocalizedString(@"Delete VMCast", @"Delete VMCast")
                                informative:CPBundleLocalizedString(@"Are you sure you want to unregister fro this VMCast? All its appliances will be deleted.", @"Are you sure you want to unregister fro this VMCast? All its appliances will be deleted.")
                                 target:self
                                 actions:[[CPBundleLocalizedString(@"Unregister", @"Unregister"), @selector(performRemoveVMCast:)], [CPBundleLocalizedString(@"Cancel", @"Cancel"), nil]]];

    [alert runModal];
}

/*! ask hypervisor to add remove an VMCast
*/
- (void)performRemoveVMCast:(id)someUserInfo
{
    var selectedIndex   = [[_mainOutlineView selectedRowIndexes] firstIndex],
        currentVMCast   = [_mainOutlineView itemAtRow:selectedIndex],
        uuid            = [currentVMCast UUID],
        stanza          = [TNStropheStanza iqWithType:@"set"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorVMCasting}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorVMCastingUnregister,
        "uuid": uuid}];


    [self sendStanza:stanza andRegisterSelector:@selector(_didRemoveVMCast:)]
}

/*! compute the hypervisor answer about removing an vmcast
    @param aStanza TNStropheStanza that contains the hypervisor answer
*/
- (BOOL)_didRemoveVMCast:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"VMCast", @"VMCast") 
                                                         message:CPBundleLocalizedString(@"VMcast has been unregistred", @"VMcast has been unregistred")];
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
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:CPBundleLocalizedString(@"VMCast", @"VMCast") 
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
    [windowDownloadQueue makeKeyAndOrderFront:nil];

    return NO;
}


#pragma mark -
#pragma mark Delegates

- (void)outlineViewSelectionDidChange:(CPNotification)aNotification
{
    [_minusButton setEnabled:NO];
    [_downloadButton setEnabled:NO];

    if ([_mainOutlineView numberOfSelectedRows] > 0)
    {
        var selectedIndexes = [_mainOutlineView selectedRowIndexes],
            object          = [_mainOutlineView itemAtRow:[selectedIndexes firstIndex]];

        if ([object isKindOfClass:TNVMCast])
        {
            var conditionNotInstalled = (([object status] == TNArchipelApplianceNotInstalled) || ([object status] == TNArchipelApplianceInstallationError)),
                conditionInstalled = ([object status] == TNArchipelApplianceInstalled);

            [self setControl:_downloadButton enabledAccordingToPermission:@"vmcasting_downloadappliance" specialCondition:conditionNotInstalled];
            [self setControl:_minusButton enabledAccordingToPermission:@"vmcasting_deleteappliance" specialCondition:conditionInstalled];
            [_minusButton setToolTip:CPBundleLocalizedString(@"Delete the selected appliance from the hypervisor repository", @"Delete the selected appliance from the hypervisor repository")];
        }
        else if ([object isKindOfClass:TNVMCastSource])
        {
            [self setControl:_minusButton enabledAccordingToPermission:@"vmcasting_unregister"];
            [_downloadButton setEnabled:NO]
            [_minusButton setToolTip:CPBundleLocalizedString(@"Unregister from a VMCast feed", @"Unregister from a VMCast feed")];
        }
    }
}

- (void)outlineViewItemWillExpand:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelVMCastsOpenedVMCasts + [item name];

    [defaults setObject:@"expanded" forKey:key];
}

- (void)outlineViewItemWillCollapse:(CPNotification)aNotification
{
    var item        = [[aNotification userInfo] valueForKey:@"CPObject"],
        defaults    = [CPUserDefaults standardUserDefaults],
        key         = TNArchipelVMCastsOpenedVMCasts + [item name];

    [defaults setObject:@"collapsed" forKey:key];
}

@end



// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNHypervisorVMCastsController], comment);
}


