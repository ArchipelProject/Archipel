/*  
 * TNSampleTabModule.j
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

@import "TNDatasourceGroupVM.j"



TNArchipelTypeVirtualMachineControl  = @"archipel:vm:control";

TNArchipelTypeVirtualMachineControlCreate      = @"create";
TNArchipelTypeVirtualMachineControlShutdown    = @"shutdown";
TNArchipelTypeVirtualMachineControlReboot      = @"reboot";
TNArchipelTypeVirtualMachineControlSuspend     = @"suspend";
TNArchipelTypeVirtualMachineControlResume      = @"resume";

TNArchipelActionTypeCreate                      = @"Start";
TNArchipelActionTypePause                       = @"Pause";
TNArchipelActionTypeShutdown                    = @"Shutdown";
TNArchipelActionTypeResume                      = @"Resume";
TNArchipelActionTypeReboot                      = @"Reboot";

/*! @defgroup  sampletabmodule Module SampleTabModule
    @desc Development starting point to create a Tab module
*/

/*! @ingroup sampletabmodule
    Sample tabbed module implementation
*/
@implementation TNGroupManagement : TNModule
{
    @outlet CPTextField             fieldJID                @accessors;
    @outlet CPTextField             fieldName               @accessors;
    @outlet CPScrollView            VMScrollView;
    @outlet CPPopUpButton           buttonAction;
    
    CPTableView             _tableVirtualMachines;
    TNDatasourceGroupVM     _datasourceGroupVM;
}


- (void)awakeFromCib
{
    _datasourceGroupVM      = [[TNDatasourceGroupVM alloc] init];
    _tableVirtualMachines   = [[CPTableView alloc] initWithFrame:[VMScrollView bounds]];
    
    [VMScrollView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [VMScrollView setAutohidesScrollers:YES];
    [VMScrollView setDocumentView:_tableVirtualMachines];
    [VMScrollView setBorderedWithHexColor:@"#9e9e9e"];
    
    [_tableVirtualMachines setUsesAlternatingRowBackgroundColors:YES];
    [_tableVirtualMachines setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableVirtualMachines setAllowsColumnReordering:YES];
    [_tableVirtualMachines setAllowsColumnResizing:YES];
    [_tableVirtualMachines setAllowsEmptySelection:YES];
    [_tableVirtualMachines setAllowsMultipleSelection:YES];
    [_tableVirtualMachines setTarget:self];
    [_tableVirtualMachines setDoubleAction:@selector(didVirtualMachineDoubleClick:)];
    
    var vmColumNickname = [[CPTableColumn alloc] initWithIdentifier:@"nickname"];
    [vmColumNickname setWidth:250];
    [[vmColumNickname headerView] setStringValue:@"Name"];

    var vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"jid"];
    [vmColumJID setWidth:450];
    [[vmColumJID headerView] setStringValue:@"Jabber ID"];

    var vmColumStatusIcon   = [[CPTableColumn alloc] initWithIdentifier:@"statusIcon"];
    var imgView             = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)];
    [imgView setImageScaling:CPScaleNone];
    [vmColumStatusIcon setDataView:imgView];
    [vmColumStatusIcon setResizingMask:CPTableColumnAutoresizingMask ];
    [vmColumStatusIcon setWidth:16];
    [[vmColumStatusIcon headerView] setStringValue:@""];
    
    [_tableVirtualMachines addTableColumn:vmColumStatusIcon];
    [_tableVirtualMachines addTableColumn:vmColumNickname];
    [_tableVirtualMachines addTableColumn:vmColumJID];

    [_tableVirtualMachines setDataSource:_datasourceGroupVM];
    
    [buttonAction removeAllItems];
    [buttonAction addItemsWithTitles:[TNArchipelActionTypeCreate, TNArchipelActionTypeShutdown,
            TNArchipelActionTypePause, TNArchipelActionTypeResume, TNArchipelActionTypeReboot]];
}


- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];   
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:[self entity]];
}

- (void)willUnload
{
    [super willUnload];
}

- (void)willShow
{
    [super willShow];

    [[self fieldName] setStringValue:[[self entity] name]];
    
    [[_datasourceGroupVM VMs] removeAllObjects];
    
    for (var i = 0; i < [[[self entity] contacts] count]; i++)
    {
        var contact = [[[self entity] contacts] objectAtIndex:i];
        var vCard   = [contact vCard];
        
        if (vCard && ([[vCard firstChildWithName:@"TYPE"] text] == TNArchipelEntityTypeVirtualMachine))
            [_datasourceGroupVM addVM:contact];
    }
    
    [_tableVirtualMachines reloadData];
}

- (void)willHide
{
    [super willHide];
}

- (void)didVirtualMachineDoubleClick:(id)sender
{
    var selectedIndexes = [_tableVirtualMachines selectedRowIndexes];
    var contact         = [[_datasourceGroupVM VMs] objectAtIndex:[selectedIndexes firstIndex]];
    var row             = [[roster mainOutlineView] rowForItem:contact];
    
    var indexes         = [CPIndexSet indexSetWithIndex:row];
    
    [[roster mainOutlineView] selectRowIndexes:indexes byExtendingSelection:NO];
}

- (IBAction)applyAction:(id)sender
{
    var action          = [buttonAction title];
    var selectedIndexes = [_tableVirtualMachines selectedRowIndexes];
    var controlType;
    
    switch(action)
    {
        case TNArchipelActionTypeCreate:
            controlType = TNArchipelTypeVirtualMachineControlCreate;
            break;

        case TNArchipelActionTypeShutdown:
            controlType = TNArchipelTypeVirtualMachineControlShutdown;
            break;
            
        case TNArchipelActionTypePause:
            controlType = TNArchipelTypeVirtualMachineControlSuspend;
            break;
            
        case TNArchipelActionTypeResume:
            controlType = TNArchipelTypeVirtualMachineControlResume;
            break;
        
        case TNArchipelActionTypeReboot:
            controlType = TNArchipelTypeVirtualMachineControlReboot;
            break;
    }
    
    for (var i = 0; i < [[_datasourceGroupVM VMs] count]; i++)
    {
        var vm = [[_datasourceGroupVM VMs] objectAtIndex:i];
        
        if ([selectedIndexes containsIndex:i])
        {
            var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];

            [controlStanza addChildName:@"query" withAttributes:{"type": controlType}];

            [vm sendStanza:controlStanza andRegisterSelector:@selector(didSentAction:) ofObject:self];
        }
    }
}

- (void)didSentAction:(TNStropheStanza)aStanza
{
    [_tableVirtualMachines reloadData];
}
@end



