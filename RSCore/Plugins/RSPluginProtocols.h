//
//  RSPluginProtocols.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
#define Platform_Window UIWindow
#define Platform_View UIView
#define Platform_ViewController UIViewController
#define Platform_Image UIImage
#define Platform_Event UIEvent
#define Platform_Control UIControl

#else

#import <AppKit/AppKit.h>
#define Platform_Window NSWindow
#define Platform_View NSView
#define Platform_ViewController NSViewController
#define Platform_Image NSImage
#define Platform_Event NSEvent
#define Platform_Control NSControl

#endif


#pragma mark App protocols

@protocol RSFeedSpecifier <NSObject>

@required
@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, retain, readonly) NSURL *URL;
@property (nonatomic, retain, readonly) NSURL *homePageURL;
@property (nonatomic, retain, readonly) id account;

@end


@protocol RSSharableItem <NSObject>

/*uti is guaranteed to be non-nil. At least one other thing will be non-nil.*/

@required
@property (nonatomic, retain, readonly) NSString *uti; //Uniform Type Identifier, like public.html (kUTTypeHTML)
@property (nonatomic, retain, readonly) NSURL *URL;
@property (nonatomic, retain, readonly) NSData *itemData; //images, etc.
@property (nonatomic, retain, readonly) NSURL *permalink; //to the item, not the entire feed
@property (nonatomic, retain, readonly) NSString *selectedText; //if user has selected some portion of the text
@property (nonatomic, retain, readonly) NSString *title;
@property (nonatomic, retain, readonly) NSString *htmlText; //may not be a complete page -- could be just a fragment, like a <description> from an RSS <item>
@property (nonatomic, retain, readonly) id<RSFeedSpecifier> feed; //often nil (the sharable item may be just some web page, for instance)

@end


@protocol RSPluginHelper <NSObject>

@required

/*Might run in a separate small window. Might not.
 If there's already a feedback thing running, any call to start will be ignored.*/

- (void)startIndeterminateFeedbackWithTitle:(NSString *)title image:(Platform_Image *)image;
- (void)stopIndeterminateFeedback;

/*Calling this will implicitly call stopIndeterminateFeedback. (In fact,
 if you're going to show a success message, it's best *not* to call stopIndeterminateFeedback.)
 The success message will appear on screen for a period of time. The image may be ignored.*/

- (void)showSuccessMessageWithTitle:(NSString *)title image:(Platform_Image *)image;

/*Everyone likes to get presents.*/

- (void)presentError:(NSError *)error;

/*If you implement a sharing plugin, you should notify the app when the item was successfully sent.
 This allows observer plugins to know about the event -- see userDidShareItem:serviceIdentifier: in
 RSObserverProtocols.h for the flip side. There's no set list of serviceIdentifiers:
 use a reverse domain name like @"com.twitter", or a string like @"email".*/

- (void)noteUserDidShareItem:(id<RSSharableItem>)sharableItem viaServiceIdentifier:(NSString *)serviceIdentifier;


/*Paths -- you can store things, check config files, etc.*/

@property (nonatomic, retain, readonly) NSString *pathToCacheFolder; 

/*On OS X, pathToAppSupportFolder is ~/Library/Application Support/appname/.
 On iOS it's the Documents folder for that app.*/

@property (nonatomic, retain, readonly) NSString *pathToDataFolder;

@property (nonatomic, retain, readonly) NSString *userAgent;
@property (nonatomic, retain, readonly) NSString *applicationNameForWebviewUserAgent;

 
#if !TARGET_OS_IPHONE //Mac-only methods

/*Plugins that open a web page can use the external browser -- or a popup in NetNewsWire.
 (Use -[[NSWorkspace sharedWorkspace] openURL:] to open in external browser.)*/

- (void)openPopupBrowserWindowWithURL:(NSURL *)url;

/*Apps such as MarsEdit, Twitterrific, and VoodooPad implement the
 External Weblog Editor Interface. <http://ranchero.com/netnewswire/developers/externalinterface>
 The plugin helper can send an Apple event for you - you just need to provide
 the app's name. (Note that this works only for text.)*/

- (BOOL)sendSharableItem:(id<RSSharableItem>)sharableItem toAppWithName:(NSString *)appName error:(NSError **)error;

#endif


@end


@protocol RSPluginManager <NSObject>

@required
@property (nonatomic, retain, readonly) id<RSPluginHelper> pluginHelper;

@end

@protocol RSUserInterfaceContext <NSObject>

/*These are all required -- but any or all may return nil.
 These are for the benefit of RSPluginCommands that need to present a user interface.
 A Mac app might want to run a sheet. An iOS app might want to present a modal
 view controller or a popover.*/

@required

@property (nonatomic, retain, readonly) Platform_Window *window;
@property (nonatomic, retain, readonly) Platform_ViewController *rootViewController;
@property (nonatomic, retain, readonly) Platform_ViewController *hostViewController;
@property (nonatomic, retain, readonly) Platform_Event *event;
@property (nonatomic, retain, readonly) Platform_View *view;
@property (nonatomic, retain, readonly) Platform_Control *control;

#if TARGET_OS_IPHONE
@property (nonatomic, retain, readonly) UIBarButtonItem *barButtonItem;
#endif

@end


#pragma mark -
#pragma mark Plugin protocols

/*Your plugin will have one or more instances, and any method could be called at any time.
 Even the methods that seem like they'd get called just once might get called more than once.*/

@protocol RSPlugin <NSObject>

@optional

/*The plugin manager is your conduit back to the app - it provides some utilities.*/

- (BOOL)shouldRegister:(id<RSPluginManager>)pluginManager; //return NO if you don't wanna (like some needed app doesn't exist locally; don't register Send to Tweetie if the app isn't on the system)
- (void)willRegister;
- (void)didRegister;


/*Array of objects conforming to RSPluginCommand protocol. Not all plugin types have commands, which is why this is optional.
 But, for a sharing plugin (for instance), having no commands would defeat the point entirely.
 
 This might get called more than once -- for instance, at startup and when the app returns to the foreground.
 It's okay to return a different array on subsequent calls.*/

@property (nonatomic, retain, readonly) NSArray *allCommands;

/*All your commands may be grouped in some way, though you can't count on a given presentation.
 They might appear in the same section in a menu, or they might appear in a submenu.
 Or in a toolbar item with a pulldown menu listing your commands. Or somewhere else.*/

@property (nonatomic, assign, readonly) BOOL commandsShouldBeGrouped; //Default is NO
@property (nonatomic, retain, readonly) NSString *titleForGroup; //should be localized
@property (nonatomic, retain, readonly) Platform_Image *imageForGroup; //if grouped, may appear as single icon. Should be 32 x 32 (toolbar-item-sized).
@property (nonatomic, retain, readonly) NSString *tooltipForGroup; //if in a toolbar, for instance. Localized, of course.

/*Not all plugin types can have preferences (check documentation). And preferences are never required.*/

#if !TARGET_OS_IPHONE

@property (nonatomic, retain, readonly) NSViewController *pluginPreferencesViewController; //should create a view of size TBD. Only if the plugin has prefs. Mac only.

#endif

@end


#define RSPluginCommandTypeSharing 1
#define RSPluginCommandTypeOpenInViewer 2 //Just like sharing commands -- but for opening in browsers and similar (viewers, not sharers)


@protocol RSPluginCommand <NSObject>

@required

@property (nonatomic, retain, readonly) NSString *title;

/*The sharableItems array may be nil or one or more objects conforming to RSSharableItem.
 Return YES only if the command will handle all zero, one, or more sharableItems.*/

- (BOOL)validateCommandWithArray:(NSArray *)items;

/*If there's an error to present to the user, return NO. The error should then be filled in.
 The error might then be presented to the user.*/

- (BOOL)performCommandWithArray:(NSArray *)items userInterfaceContext:(id<RSUserInterfaceContext>)userInterfaceContext pluginHelper:(id<RSPluginHelper>)pluginHelper error:(NSError **)error;

/*Identifier must be unique per command. Doesn't have to be human-readable. Something like com.mycompany.mycommand will work fine.
 Must not be dependent on user's language. It also shouldn't change -- it should be the same between runs of the app.
 (The identifier may be used by the toolbar, for instance, to know which items have been added.)*/

@property (nonatomic, retain, readonly) NSString *commandID;

/*Array of NSNumbers that specify the command type: RSPluginCommandTypeSharing, etc.*/

@property (nonatomic, retain, readonly) NSArray *commandTypes;


@optional

@property (nonatomic, retain, readonly) NSString *shortTitle; //like "Facebook" instead of "Share on Facebook" -- something that works in a button
@property (nonatomic, retain, readonly) Platform_Image *image; //Should be 32 x 32, toolbar-size
@property (nonatomic, retain, readonly) NSString *tooltip;

@end

