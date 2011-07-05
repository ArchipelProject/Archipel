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

@import <AppKit/CPTextField.j>
@import <AppKit/CPWebView.j>


/*! @defgroup generalwelcomeview Module GeneralWelcomeView
    @desc the welcome page
*/

/*! @ingroup generalwelcomeview
    The main controller
*/
@implementation TNGeneralWelcomeViewController : TNModule
{
    @outlet CPWebView       mainWebView;
    @outlet CPImageView     imageViewBrowser;
    @outlet CPTextField     fieldLoading;
    @outlet CPTextField     fieldPreferencesWelcomePageUrl;
}


#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [mainWebView setScrollMode:CPWebViewScrollNative];

    var bundle = [CPBundle bundleForClass:[self class]];

    [imageViewBrowser setImage:[[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:@"browser.png"]]];
    [fieldLoading setValue:[CPColor colorWithHexString:@"eee"] forThemeAttribute:@"text-shadow-color" inState:CPThemeStateNormal];
    [fieldLoading setValue:CGSizeMake(0.0, -1.0) forThemeAttribute:@"text-shadow-offset" inState:CPThemeStateNormal];
    [fieldLoading setTextColor:[CPColor colorWithHexString:@"929292"]];

    [fieldPreferencesWelcomePageUrl setToolTip:CPBundleLocalizedString(@"The URL of the welcome page", @"The URL of the welcome page")];
}

#pragma mark -
#pragma mark TNModule overrides

/*! called when module becomes visible
*/
- (BOOL)willShow
{
    if (![super willShow])
        return NO;

    var defaults = [CPUserDefaults standardUserDefaults];

    [mainWebView setAlphaValue:0.0];
    mainWebView._DOMElement.style.WebkitTransition = "opacity 0.3s";

    [mainWebView setFrameLoadDelegate:self];
    [mainWebView setMainFrameURL:[defaults objectForKey:@"TNArchipelHelpWindowURL"] + "?lang=" + [defaults objectForKey:@"CPBundleLocale"]];

    return YES;
}

/*! called when user saves preferences
*/
- (void)savePreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [defaults setObject:[fieldPreferencesWelcomePageUrl stringValue] forKey:@"TNArchipelHelpWindowURL"];

    [mainWebView setMainFrameURL:[defaults objectForKey:@"TNArchipelHelpWindowURL"] + "?lang=" + [defaults objectForKey:@"CPBundleLocale"]];
}

/*! called when user gets preferences
*/
- (void)loadPreferences
{
    var defaults = [CPUserDefaults standardUserDefaults];

    [fieldPreferencesWelcomePageUrl setStringValue:[defaults objectForKey:@"TNArchipelHelpWindowURL"]];
}


#pragma mark -
#pragma mark Delegate

- (void)webView:(CPWebView)aWebView didFinishLoadForFrame:(id)aFrame
{
    [mainWebView setAlphaValue:1.0];
}

@end


// add this code to make the CPLocalizedString looking at
// the current bundle.
function CPBundleLocalizedString(key, comment)
{
    return CPLocalizedStringFromTableInBundle(key, nil, [CPBundle bundleForClass:TNGeneralWelcomeViewController], comment);
}
