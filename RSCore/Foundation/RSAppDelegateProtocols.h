//
//  RSAppDelegateProtocol.h
//  RSCoreTests
//
//  Created by Brent Simmons on 9/3/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


/*Sometimes an object may need to call back to the app delegate for something.
 This protocol formalizes what those things are, in the hopes of keeping it limited
 but also organized.
 
 To call the app delegate: rs_app_delegate.someProperty or [rs_app_delegate someMethod].
 The odd-looking call is a virtue: helps us remember that we'd prefer a better solution.*/


#if TARGET_OS_IPHONE
#define rs_app_delegate ((id<RSAppDelegate>)[[UIApplication sharedApplication] delegate])
#else
#define rs_app_delegate ((id<RSAppDelegate>)[NSApp delegate])
#endif

@class RSPluginManager;


@protocol RSAppDelegate <NSObject>

@required

@property (nonatomic, retain, readonly) NSString *userAgent;
@property (nonatomic, retain, readonly) NSString *applicationNameForWebviewUserAgent;

@property (nonatomic, retain, readonly) NSString *pathToCacheFolder;
@property (nonatomic, retain, readonly) NSString *pathToDataFolder; //Documents folder for app on iOS, app support on OS X

@property (nonatomic, assign, readonly) BOOL refreshInProgress;
@property (nonatomic, assign) BOOL runningModalSheet;

@property (nonatomic, assign, readonly) BOOL appIsShuttingDown;

- (void)showAlertSheetWithTitle:(NSString *)title andMessage:(NSString *)message;

/*Data*/
@property (nonatomic, retain, readonly) id dataController;
- (void)addCoreDataBackgroundOperation:(NSOperation *)operation;
- (NSManagedObjectContext *)mainThreadManagedObjectContext;
- (NSManagedObjectContext *)temporaryManagedObjectContext; //For an NSOperation
- (void)saveManagedObjectContext:(NSManagedObjectContext *)moc;

/*Plugin support.*/
- (void)makeAppObserversPerformSelector:(SEL)aSelector withObject:(id)anObject;
- (void)makeAppObserversPerformSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;

@property (nonatomic, retain, readonly) RSPluginManager *pluginManager;

- (BOOL)systemShouldOpenURLString:(NSString *)aURLString;

#if TARGET_OS_IPHONE

@property (nonatomic, retain, readonly) UIViewController *rootViewController;
@property (nonatomic, retain, readonly) UIWindow *window;
@property (nonatomic, assign, readonly) BOOL isiPadVersion;
@property (nonatomic, assign, readonly) UIInterfaceOrientation currentOrientation;
@property (nonatomic, assign, readonly) BOOL currentOrientationIsPortrait;

- (void)presentError:(NSError *)anError; //already defined for NSApplication

#endif

@end
