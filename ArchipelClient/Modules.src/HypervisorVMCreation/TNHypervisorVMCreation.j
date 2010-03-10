/*  
 * TNViewHypervisorControl.j
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
 
@import "TNDatasourceVMs.j"

trinityTypeHypervisorControl            = @"trinity:hypervisor:control";

trinityTypeHypervisorControlAlloc       = @"alloc";
trinityTypeHypervisorControlFree        = @"free";
trinityTypeHypervisorControlRosterVM    = @"rostervm";


@implementation TNHypervisorVMCreation : TNModule 
{
    @outlet CPTextField     fieldJID            @accessors;
    @outlet CPTextField     fieldName           @accessors;
    @outlet CPButton        buttonCreateVM      @accessors;
    @outlet CPPopUpButton   popupDeleteMachine  @accessors;
    @outlet CPButton        buttonDeleteVM      @accessors;
    @outlet CPScrollView    scrollViewListVM    @accessors;
    
    CPTableView         tableVirtualMachines        @accessors;
    TNDatasourceVMs     virtualMachinesDatasource   @accessors;
    
    TNStropheContact    _virtualMachineRegistredForDeletion;
    id                  pushNotificationRegistrationID;
}

- (void)awakeFromCib
{
    pushNotificationRegistrationID = nil;
    
    // VM table view
    virtualMachinesDatasource   = [[TNDatasourceVMs alloc] init];
    tableVirtualMachines        = [[CPTableView alloc] initWithFrame:[[self scrollViewListVM] bounds]];
    
    [[self scrollViewListVM] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self scrollViewListVM] setAutohidesScrollers:YES];
    [[self scrollViewListVM] setDocumentView:[self tableVirtualMachines]];
    [[self scrollViewListVM] setBorderedWithHexColor:@"#9e9e9e"];
    
    [[self tableVirtualMachines] setUsesAlternatingRowBackgroundColors:YES];
    [[self tableVirtualMachines] setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [[self tableVirtualMachines] setAllowsColumnReordering:YES];
    [[self tableVirtualMachines] setAllowsColumnResizing:YES];
    [[self tableVirtualMachines] setAllowsEmptySelection:YES];
    
    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"];
    [vmColumNickname setWidth:250];
    [[vmColumNickname headerView] setStringValue:@"Name"];
    
    var vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"jid"];
    [vmColumJID setWidth:450];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];
    
    var vmColumStatusIcon = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"];
    var imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setResizingMask:CPTableColumnAutoresizingMask ];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];
    
    [[self tableVirtualMachines] addTableColumn:vmColumStatusIcon];
    [[self tableVirtualMachines] addTableColumn:vmColumNickname];
    [[self tableVirtualMachines] addTableColumn:vmColumJID];
    
    [[self tableVirtualMachines] setDataSource:[self virtualMachinesDatasource]];
}

- (void)willLoad
{
    var center = [CPNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:[self contact]];
    
    var params = [[CPDictionary alloc] init];

    [params setValue:@"iq" forKey:@"name"];
    [params setValue:[[self contact] jid] forKey:@"from"];
    [params setValue:@"push" forKey:@"type"];
    [params setValue:{"matchBare": YES} forKey:@"options"];
   
    pushNotificationRegistrationID = [[self connection] registerSelector:@selector(didSubscriptionPushReceived:) ofObject:self withDict:params];
}


- (void)willUnload
{   
    [[self connection] deleteRegistredSelector:pushNotificationRegistrationID];
}

- (void)willShow
{
    [[self fieldName] setStringValue:[[self contact] nickname]];
    [[self fieldJID] setStringValue:[[self contact] jid]];
        
    [self getHypervisorRoster];
}

- (void)willHide
{
    var center  = [CPNotificationCenter defaultCenter];
    [center removeObserver:self];
    
}

- (BOOL)didSubscriptionPushReceived:(TNStropheStanza)aStanza
{
    if ([aStanza valueForAttribute:@"change"] == @"subscription-added")
    {
        [self getHypervisorRoster];
    }
    
    return YES;
}


- (void)didNickNameUpdated:(CPNotification)aNotification
{
    [[self fieldName] setStringValue:[[self contact] nickname]] 
}

- (void)getHypervisorRosterForTimer:(CPTimer)aTimer
{
    [self getHypervisorRoster];
}

- (void)getHypervisorRoster
{
    var uid             = [[[self contact] connection] getUniqueId];
    var rosterStanza    = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
        
    [rosterStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlRosterVM}];
    
    [[[self contact] connection] registerSelector:@selector(didReceiveHypervisorRoster:) ofObject:self withDict:params];
    [[[self contact] connection] send:rosterStanza];
}

- (void)didReceiveHypervisorRoster:(id)aStanza 
{
    var queryItems  = [aStanza childrenWithName:@"item"];
    var center      = [CPNotificationCenter defaultCenter];
    
    [[[self virtualMachinesDatasource] VMs] removeAllObjects];
    
    
    for (var i = 0; i < [queryItems count]; i++)
    {
        var jid     = [[queryItems objectAtIndex:i] text];
        var entry   = [[self roster] getContactFromJID:jid];
        
        if (entry) 
        {
            if ([[[entry vCard] firstChildWithName:@"TYPE"] text] == "virtualmachine")
            {
                [[self virtualMachinesDatasource] addVM:entry];
                
                [center addObserver:self selector:@selector(didVirtualMachineChangesStatus:) name:TNStropheContactPresenceUpdatedNotification object:entry];   
            }
        }
    }
    [[self tableVirtualMachines] reloadData];
}

- (void)didVirtualMachineChangesStatus:(CPNotification)aNotif
{
    [[self tableVirtualMachines] reloadData];
}


//actions
- (IBAction)addVirtualMachine:(id)sender
{
    var uid             = [[[self contact] connection] getUniqueId];
    var creationStanza  = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
    var uuid            = [CPString UUID];
    var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
    
    [creationStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlAlloc}];
    [creationStanza addChildName:@"jid" withAttributes:{}];
    [creationStanza addTextNode:uuid];
    
    
    [[[self contact] connection] registerSelector:@selector(didAllocVirtualMachine:) ofObject:self withDict:params];
    [[[self contact] connection] send:creationStanza];
    
    [buttonCreateVM setEnabled:NO];
}

- (void)didAllocVirtualMachine:(id)aStanza
{
    [buttonCreateVM setEnabled:YES];
    
    
    if ([aStanza getType] == @"success")
    {
        var vmJid   = [[[aStanza firstChildWithName:@"query"] firstChildWithName:@"virtualmachine"] valueForAttribute:@"jid"];
        
        [[TNViewLog sharedLogger] log:@"sucessfully create a virtual machine"];
    }
    else
    {
        [CPAlert alertWithTitle:@"Error" message:@"Unable to create virtual machine" style:CPCriticalAlertStyle];
        [[TNViewLog sharedLogger] log:@"error during creation a virtual machine"];
    }
}

- (IBAction) deleteVirtualMachine:(id)sender
{
    if (([[self tableVirtualMachines] numberOfRows]) && ([[self tableVirtualMachines] numberOfSelectedRows] <= 0))
    {
         [CPAlert alertWithTitle:@"Error" message:@"You must select a virtual machine"];
         return;
    }
    
    var selectedIndex                       = [[[self tableVirtualMachines] selectedRowIndexes] firstIndex];
    _virtualMachineRegistredForDeletion     = [[[self virtualMachinesDatasource] VMs] objectAtIndex:selectedIndex];
    
    var alert = [[CPAlert alloc] init];
    
    [buttonDeleteVM setEnabled:NO];
    
    [alert setDelegate:self];
    [alert setTitle:@"Destroying a Virtual Machine"];
    [alert setMessageText:@"Are you sure you want to completely remove this virtual machine ?"];
    [alert setWindowStyle:CPHUDBackgroundWindowMask];
    [alert addButtonWithTitle:@"Yes"];
    [alert addButtonWithTitle:@"No"];
    [alert runModal];
}

- (void)alertDidEnd:(CPAlert)theAlert returnCode:(int)returnCode 
{
    if (returnCode == 0)
    {
        var vm              = _virtualMachineRegistredForDeletion;
        var uid             = [[[self contact] connection] getUniqueId];
        var freeStanza      = [TNStropheStanza iqWithAttributes:{"type" : trinityTypeHypervisorControl, "to": [[self contact] fullJID], "id": uid}];
        var params          = [CPDictionary dictionaryWithObjectsAndKeys:uid, @"id"];
        
        [freeStanza addChildName:@"query" withAttributes:{"type" : trinityTypeHypervisorControlFree}];
        [freeStanza addTextNode:[vm jid]];
        
        [[self roster] removeContact:[vm jid]];
        
        [[[self contact] connection] registerSelector:@selector(didFreeVirtualMachine:) ofObject:self withDict:params];
        [[[self contact] connection] send:freeStanza];
    }
    else
    {
        _virtualMachineRegistredForDeletion = Nil;
        [buttonDeleteVM setEnabled:YES];
    }
}

- (void)didFreeVirtualMachine:(id)aStanza
{
    [buttonDeleteVM setEnabled:YES];
    _virtualMachineRegistredForDeletion = Nil;
    if ([aStanza getType] == @"success")
    {
        [[TNViewLog sharedLogger] log:@"sucessfully deallocating a virtual machine"];
        [self getHypervisorRoster];
    }
    else
    {
        [CPAlert alertWithTitle:@"Error" message:@"Unable to free virtual machine" style:CPCriticalAlertStyle];
        [[TNViewLog sharedLogger] log:@"error during free a virtual machine"];
    }
}

@end


