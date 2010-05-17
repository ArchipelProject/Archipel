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
    @outlet CPSearchField           filterField;
    @outlet CPButtonBar             buttonBarControl;
    @outlet CPView                  viewTableContainer;
    
    CPTableView             _tableVirtualMachines;
    TNTableViewDataSource   _datasourceGroupVM;
}


- (void)awakeFromCib
{
    [viewTableContainer setBorderedWithHexColor:@"#9e9e9e"];
    
    _datasourceGroupVM      = [[TNTableViewDataSource alloc] init];
    _tableVirtualMachines   = [[CPTableView alloc] initWithFrame:[VMScrollView bounds]];
    
    [VMScrollView setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [VMScrollView setAutohidesScrollers:YES];
    [VMScrollView setDocumentView:_tableVirtualMachines];
    
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

    var vmColumJID = [[CPTableColumn alloc] initWithIdentifier:@"JID"];
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

    [_datasourceGroupVM setTable:_tableVirtualMachines];
    [_datasourceGroupVM setSearchableKeyPaths:[@"nickname", @"JID"]];
    [_tableVirtualMachines setDataSource:_datasourceGroupVM];            

    var createButton  = [CPButtonBar plusButton];
    [createButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-play.png"] size:CPSizeMake(16, 16)]];
    [createButton setTarget:self];
    [createButton setAction:@selector(create:)];
    
    var shutdownButton  = [CPButtonBar plusButton];
    [shutdownButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-stop.png"] size:CPSizeMake(16, 16)]];
    [shutdownButton setTarget:self];
    [shutdownButton setAction:@selector(shutdown:)];
    
    var suspendButton  = [CPButtonBar plusButton];
    [suspendButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-pause.png"] size:CPSizeMake(16, 16)]];
    [suspendButton setTarget:self];
    [suspendButton setAction:@selector(suspend:)];
    
    var resumeButton  = [CPButtonBar plusButton];
    [resumeButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-resume.png"] size:CPSizeMake(16, 16)]];
    [resumeButton setTarget:self];
    [resumeButton setAction:@selector(resume:)];
    
    var rebootButton  = [CPButtonBar plusButton];
    [rebootButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-restart.png"] size:CPSizeMake(16, 16)]];
    [rebootButton setTarget:self];
    [rebootButton setAction:@selector(reboot:)];

    [buttonBarControl setButtons:[createButton, shutdownButton, suspendButton, resumeButton, rebootButton]];
    
    [filterField setTarget:_datasourceGroupVM];
    [filterField setAction:@selector(filterObjects:)];
}


- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];   
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center addObserver:self selector:@selector(reload:) name:TNStropheContactGroupUpdatedNotification object:nil];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
}

- (void)willUnload
{
    [super willUnload];
}

- (void)willShow
{
    [super willShow];

    [self reload:nil];
}

- (void)reload:(CPNotification)aNotification
{
    [fieldName setStringValue:[_entity name]];
    
    [_datasourceGroupVM removeAllObjects];
    
    for (var i = 0; i < [[_entity contacts] count]; i++)
    {
        var contact = [[_entity contacts] objectAtIndex:i];
        var vCard   = [contact vCard];
        
        if (vCard && ([[vCard firstChildWithName:@"TYPE"] text] == TNArchipelEntityTypeVirtualMachine))
            [_datasourceGroupVM addObject:contact];
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
    var contact         = [_datasourceGroupVM objectAtIndex:[selectedIndexes firstIndex]];
    var row             = [[_roster mainOutlineView] rowForItem:contact];
    
    var indexes         = [CPIndexSet indexSetWithIndex:row];
    
    [[_roster mainOutlineView] selectRowIndexes:indexes byExtendingSelection:NO];
}

- (IBAction)create:(id)sender
{
    [self applyAction:TNArchipelActionTypeCreate];
}

- (IBAction)shutdown:(id)sender
{
    [self applyAction:TNArchipelActionTypeShutdown];
}

- (IBAction)suspend:(id)sender
{
    [self applyAction:TNArchipelActionTypePause];
}

- (IBAction)resume:(id)sender
{
    [self applyAction:TNArchipelActionTypeResume];
}

- (IBAction)reboot:(id)sender
{
    [self applyAction:TNArchipelActionTypeReboot];
}

- (void)applyAction:(CPString)aCommand
{
    var controlType;
    
    switch(aCommand)
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
    
    var indexes = [_tableVirtualMachines selectedRowIndexes];
    var objects = [_datasourceGroupVM objectsAtIndexes:indexes];
    for (var i = 0; i < [objects count]; i++)
    {
        var vm = [objects objectAtIndex:i];
        var controlStanza = [TNStropheStanza iqWithAttributes:{"type": TNArchipelTypeVirtualMachineControl}];

        [controlStanza addChildName:@"query" withAttributes:{"type": controlType}];

        [vm sendStanza:controlStanza andRegisterSelector:@selector(didSentAction:) ofObject:self];
        }
    }
}

- (void)didSentAction:(TNStropheStanza)aStanza
{
    var sender = [aStanza getFromNodeUser];
    
    if ([aStanza getType] == @"success")
    {
        var growl = [TNGrowlCenter defaultCenter];
        [growl pushNotificationWithTitle:@"Virtual Machine" message:@"Virtual machine "+sender+" state modified"];
        
        [_tableVirtualMachines reloadData];
    }
    
}
@end



