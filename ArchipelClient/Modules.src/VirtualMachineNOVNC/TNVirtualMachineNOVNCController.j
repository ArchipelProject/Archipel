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

@import "TNZoomAnimation.j";


/*! @defgroup  virtualmachinevnc Module VirtualMachineVNC 
    @desc This module allows to access to virtual machine displays
    using VNC.
*/


/*! @ingroup virtualmachinevnc
    @group TNArchipelTypeVirtualMachineControl
    namespave of vm control
*/
TNArchipelTypeVirtualMachineControl             = @"archipel:vm:control";

/*! @ingroup virtualmachinevnc
    @group TNArchipelTypeVirtualMachineControl
    get vnc display
*/
TNArchipelTypeVirtualMachineControlVNCDisplay   = @"vncdisplay";

TNArchipelVNCScaleFactor                        = @"TNArchipelVNCScaleFactor_";


/*! @ingroup virtualmachinevnc
    module that allow to access virtual machine console using VNC
*/
@implementation TNVirtualMachineNOVNCController : TNModule
{
    @outlet CPScrollView    mainScrollView;
    @outlet CPTextField     fieldJID;
    @outlet CPTextField     fieldName;
    @outlet CPView          maskingView;
    @outlet CPSlider        sliderScaling;
    @outlet CPButton        buttonZoomFitToWindow;
    @outlet CPButton        buttonZoomReset;
    @outlet CPTextField     fieldZoomValue;
    @outlet CPView          viewControls;
    
    CPString                _url;
    CPString                _VMHost;
    CPString                _vncDisplay;
    CPString                _webServerPort;
    TNVNCView               _vncView;
}

/*! initialize some value at CIB awakening
*/
- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];
    
    var bundle  = [CPBundle bundleForClass:[self class]];
    
    var imageBg = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"bg-controls.png"]];
    [viewControls setBackgroundColor:[CPColor colorWithPatternImage:imageBg]];
    
    
    var imageZoomFit = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-fullscreen.png"] size:CPSizeMake(16, 16)]
    [buttonZoomFitToWindow setImage:imageZoomFit];
    
    var imageZoomReset = [[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"button-icons/button-icon-reset.png"] size:CPSizeMake(16, 16)]
    [buttonZoomReset setImage:imageZoomReset];
    
    _webServerPort   = [[CPBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"ArchipelServerSideWebServerPort"];
    
    _vncView    = [[TNVNCView alloc] initWithFrame:[mainScrollView bounds]];
    [_vncView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_vncView setCanvasBorderColor:@"#C0C7D2"];
    
    [mainScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [mainScrollView setDocumentView:_vncView];
    [mainScrollView setAutohidesScrollers:YES];
    [sliderScaling setContinuous:YES];
    [sliderScaling setMinValue:1];
    [sliderScaling setMaxValue:200];
}

/*! TNModule implementation
*/
- (void)willLoad
{
    [super willLoad];
    
    var center = [CPNotificationCenter defaultCenter];   
    [center addObserver:self selector:@selector(didNickNameUpdated:) name:TNStropheContactNicknameUpdatedNotification object:_entity];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];
    [center addObserver:self selector:@selector(didPresenceUpdated:) name:TNStropheContactPresenceUpdatedNotification object:_entity];
    
    // var viewBounds = [[self view] bounds];
    // viewBounds.size.height = 1000;
    // [[self view] setFrame:viewBounds];
}

/*! TNModule implementation
*/
- (void)willShow
{
    [super willShow];

    [maskingView setFrame:[[self view] bounds]];
    
    [fieldName setStringValue:[_entity nickname]];
    [fieldJID setStringValue:[_entity JID]];
    [self checkIfRunning];
    
    [[self view] setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [[self view] setFrame:[[[self view] superview] bounds]];
}

/*! TNModule implementation
*/
- (void)willHide
{
    [_vncView disconnect:nil];
    
    [super willHide];
}

/*! TNModule implementation
*/
- (void)willUnload
{
    [super willUnload];
}

- (void)didNickNameUpdated:(CPNotification)aNotification
{
    if ([aNotification object] == _entity)
    {
       [fieldName setStringValue:[_entity nickname]]
    }
}
/*! send stanza to get the current virtual machine VNC display
*/

- (void)didPresenceUpdated:(CPNotification)aNotification
{
    [self checkIfRunning];
}

- (void)checkIfRunning
{
    if ([_entity XMPPShow] == TNStropheContactStatusOnline)
    {
        [maskingView removeFromSuperview];
        [self getVirtualMachineVNCDisplay];
    }
    else
    {
        [maskingView setFrame:[[self view] bounds]];
        [[self view] addSubview:maskingView];
    }
}


- (void)getVirtualMachineVNCDisplay
{
    var stanza   = [TNStropheStanza iqWithType:@"get"];
    
    [stanza addChildName:@"query" withAttributes:{"xmlns": TNArchipelTypeVirtualMachineControl}];
    [stanza addChildName:@"archipel" withAttributes:{
        "action": TNArchipelTypeVirtualMachineControlVNCDisplay}];
                
    [_entity sendStanza:stanza andRegisterSelector:@selector(_didReceiveVNCDisplay:) ofObject:self];
}

/*! message sent when VNC display info is received
    @param aStanza the response stanza
*/
- (void)_didReceiveVNCDisplay:(id)aStanza
{
    if ([aStanza getType] == @"result")
    {
        var bundle      = [CPBundle bundleForClass:self];
        var displayNode = [aStanza firstChildWithName:@"vncdisplay"];
        var defaults    = [TNUserDefaults standardUserDefaults];
        var key         = TNArchipelVNCScaleFactor + [[self entity] JID];
        var lastScale   = [defaults objectForKey:key];
        _vncDisplay     = [displayNode valueForAttribute:@"proxy"];
        _VMHost         = [displayNode valueForAttribute:@"host"];
        
        if (lastScale)
        {
            [sliderScaling setDoubleValue:lastScale];
            [_vncView setZoom:lastScale];
            [fieldZoomValue setStringValue:lastScale];
        }
        else
        {
            [sliderScaling setDoubleValue:100];
            [fieldZoomValue setStringValue:@"100"];
        }
        
        [_vncView setHost:_VMHost];
        [_vncView setPort:_vncDisplay];
        [_vncView connect:nil];
        [_vncView becomeFirstResponder];
        
    }
    else if ([aStanza getType] == @"error")
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


- (IBAction)fitToScreen:(id)sender
{
    var visibleRect     = [_vncView visibleRect];
    var currentVNCSize  = [_vncView canvasSize];
    var currentVNCZoom  = [_vncView canvasZoom];
    var newZoom         = 100 - (Math.abs((visibleRect.size.height - currentVNCSize.height) / currentVNCSize.height) * 100);

    [self animateChangeScaleFrom:currentVNCZoom to:newZoom];
}

- (IBAction)resetZoom:(id)sender
{
    var visibleRect     = [_vncView visibleRect];
    var currentVNCSize  = [_vncView canvasSize];
    var currentVNCZoom  = [_vncView canvasZoom];
    var newZoom         = 100 - (Math.abs((visibleRect.size.height - currentVNCSize.height) / currentVNCSize.height) * 100);

    [self animateChangeScaleFrom:currentVNCZoom to:100];
}

- (IBAction)changeScale:(id)sender
{
    var defaults    = [TNUserDefaults standardUserDefaults];
    var zoom        = [sliderScaling intValue];
    
    var key = TNArchipelVNCScaleFactor + [[self entity] JID];
    [defaults setObject:zoom forKey:key];
    
    [_vncView setZoom:zoom];
    [fieldZoomValue setStringValue:parseInt(zoom)];
}

- (void)animateChangeScaleFrom:(float)aStartZoom to:(float)aEndZoom
{
    var useAnimations = [[CPBundle mainBundle] objectForInfoDictionaryKey:@"TNArchipelUseAnimations"];
    
    if (useAnimations)
    {
        var anim = [[TNZoomAnimation alloc] initWithDuration:0.2 animationCurve:CPAnimationEaseOut];
        [anim setDelegate:self];
        [anim setStartZoomValue:aStartZoom];
        [anim setEndZoomValue:aEndZoom];
        [anim startAnimation];
    }
    else
    {
        [sliderScaling setDoubleValue:aEndZoom];
        [self changeScale:nil];
    }
}


- (float)animation:(CPAnimation)animation valueForProgress:(float)progress
{
    [sliderScaling setDoubleValue:[animation currentZoom]];
    
    [_vncView setZoom:[animation currentZoom]];
    [fieldZoomValue setStringValue:parseInt([animation currentZoom])];
}

- (void)animationDidEnd:(CPAnimation)animation
{
    [self changeScale:nil];
}

@end



