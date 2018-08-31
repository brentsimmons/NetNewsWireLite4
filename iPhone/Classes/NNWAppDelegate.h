//
//  nnwiphoneAppDelegate.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright NewsGator Technologies, Inc. 2009. All rights reserved.
//


#define app_delegate ((NNWAppDelegate *)[[UIApplication sharedApplication] delegate])


extern NSString *BCConnectedToInternetNotification;
extern NSString *BCNotConnectedToInternetNotification;
extern NSString *NNWBigUIThingDidStartNotification; /*causes downloader to suspend, maybe other things*/
extern NSString *NNWBigUIThingDidEndNotification; /*causes downloader to resume, maybe other things*/
extern NSString *NNWGoogleServiceName;
extern NSString *NNWGoogleUsernameKey;
extern NSString *NNWGooglePasswordKey;
extern NSString *NNWStatusMessageKey;
extern NSString *NNWStatusMessageDidBeginNotification;
extern NSString *NNWStatusMessageDidEndNotification;
extern NSString *NNWExceptionFunctionKey;
extern NSString *NNWExceptionObjectKey;


@class NNWGoogleLoginController;

@interface NNWAppDelegate : NSObject <UIApplicationDelegate> {
    
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;

    UIWindow *window;
    UINavigationController *navigationController;
	
	NSString *_userAgent;
	
	NNWGoogleLoginController *_loginController;
	
	NSInteger _networkActivityCount;
	UIBarButtonItem *_backArrowButtonItem;
	
	BOOL _appIsActive;
	NSThread *_coreDataThread;
	BOOL _stopped;
	
	UIColor *_originalWindowBackgroundColor;
	
	BOOL _offline;
	BOOL _sortNewsItemsAscending;
}

- (IBAction)saveAction:sender;

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (retain) NSThread *coreDataThread;

@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

@property (nonatomic, retain, readonly) NSString *userAgent;

@property (nonatomic, retain, readonly) UIBarButtonItem *backArrowButtonItem;

@property (nonatomic, assign, readonly) BOOL appIsActive;

@property (nonatomic, retain) UIColor *originalWindowBackgroundColor;
@property (nonatomic, assign) BOOL offline;
@property (nonatomic, assign, readonly) BOOL sortNewsItemsAscending;
@property (nonatomic, retain, readonly) NSString *googleUsername;

- (void)startDownloaderManager;
- (void)startRefreshing;
- (void)startRefreshingIfNeeded; /*Checks last refresh date*/

- (void)incrementNetworkActivity;
- (void)decrementNetworkActivity;

- (void)saveManagedObjectContext;

- (void)sendBigUIStartNotification;
- (void)sendBigUIEndNotification;

- (NSDictionary *)googleUsernameAndPasswordDictionary;
- (BOOL)hasGoogleUsernameAndPassword;

- (void)showAlertWithDictionary:(NSDictionary *)errorDict;
- (void)showAlertWithError:(NSError *)error;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

- (void)displayFeedbackMessage:(NSString *)message;

- (void)sendStatusMessageDidBegin:(NSString *)message;
- (void)sendStatusMessageDidEnd:(NSString *)message;

- (void)displayAboutOverlay:(id)sender;

- (BOOL)shouldNavigateToURL:(NSURL *)url;
- (BOOL)shouldOpenURLInMoviePlayer:(NSURL *)url;

- (void)handleCoreDataException:(NSDictionary *)errorDict;

@end

