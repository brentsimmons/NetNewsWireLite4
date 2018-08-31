//
//  NNWAppDelegate.h
//  nnwipad
//
//  Created by Brent Simmons on 2/3/10.
//  Copyright NewsGator Technologies, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>


#define app_delegate ((NNWAppDelegate *)[[UIApplication sharedApplication] delegate])


static const CGFloat KEYBOARD_ANIMATION_DURATION = 0.3;
static const CGFloat PORTRAIT_KEYBOARD_HEIGHT = 264;
static const CGFloat LANDSCAPE_KEYBOARD_HEIGHT = 352;

extern NSString *NNWGoogleServiceName;
extern NSString *NNWGoogleUsernameKey;
extern NSString *NNWGooglePasswordKey;

extern NSString *NNWStatusMessageDidBeginNotification;
extern NSString *NNWStatusMessageDidEndNotification;
extern NSString *NNWStatusMessageKey;

extern NSString *NNWSubscriptionsDidUpdateNotification;
extern NSString *NNWNewsItemsDidSaveNotification;
extern NSString *NNWNewsItemsKey;

extern NSString *NNWWebPageDidAppearNotification;
extern NSString *NNWArticleDidAppearNotification;

extern NSString *NNWRightPaneViewTypeKey;

extern NSString *NNWWillAnimateRotationToInterfaceOrientation;
extern NSString *NNWDidAnimateRotationToInterfaceOrientation;

extern NSString *NNWTitleDidChangeNotification;


/*State*/

extern NSString *NNWStateLeftPaneViewControllerKey;
extern NSString *NNWStateRightPaneViewControllerKey;
extern NSString *NNWStateFeedsLocationInOutlineKey;
extern NSString *NNWStateArticleIDKey;
extern NSString *NNWStateWebPageURLKey;
extern NSString *NNWStateNewsKey;
extern NSString *NNWStateNewsProxyIsFolderKey;

extern NSString *NNWPopoverWillDisplayNotification;
extern NSString *NNWPopoverControllerKey; /*in userInfo for notification*/

@class NNWMainViewController;
@class NNWNewsListTableController;
@class NNWArticleViewController;
@class NNWCurrentNewsItemsController;
@class NNWProxy;
@class NGModalViewPresenter;

typedef enum _NNWLeftPaneViewType {
	NNWLeftPaneViewFeeds,
	NNWLeftPaneViewNews
} NNWLeftPaneViewType;

typedef enum _NNWRightPaneViewType {
	NNWRightPaneViewNone,
	NNWRightPaneViewArticle,
	NNWRightPaneViewWebPage
} NNWRightPaneViewType;

@class RSDetailViewController;

@interface NNWAppDelegate : NSObject <UIApplicationDelegate> {
@private    
    UIWindow *window;
    
    UISplitViewController *splitViewController;
    
    NNWMainViewController *masterViewController;
    RSDetailViewController *detailViewController;
	NNWNewsListTableController *newsListViewController;
	NNWArticleViewController *articleViewController;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;	    
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
	NSThread *_coreDataThread;

	BOOL _stopped;

	NNWCurrentNewsItemsController *currentNewsItemsController;

	NSString *userAgent;
	UIInterfaceOrientation interfaceOrientation;
	UIViewController *currentLeftPaneViewController;
	UIViewController *currentRightPaneViewController;
	NNWRightPaneViewType rightPaneViewType;
	NGModalViewPresenter *_modalViewPresenter;
	
	BOOL firstRun;
	BOOL didRestoreWebpageState;
	
	UIBarButtonItem *popoverButtonItem;
	NSString *titleForPopoverButtonItem;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet NNWMainViewController *masterViewController;
@property (nonatomic, retain) IBOutlet RSDetailViewController *detailViewController;
@property (nonatomic, retain) NNWNewsListTableController *newsListViewController;
@property (nonatomic, retain) NNWArticleViewController *articleViewController;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (retain) NSThread *coreDataThread;
@property (nonatomic, retain) NNWCurrentNewsItemsController *currentNewsItemsController;
@property (nonatomic, assign, readonly) NNWRightPaneViewType rightPaneViewType;
@property (nonatomic, retain) NSString *userAgent;
@property (nonatomic, retain, readonly) NSString *googleUsername;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;
@property (nonatomic, assign, readonly) BOOL interfaceOrientationIsLandscape;
@property (nonatomic, retain) UIViewController *currentLeftPaneViewController;
@property (nonatomic, retain, readonly) UIViewController *currentRightPaneViewController;
@property (nonatomic, assign, readonly) BOOL firstRun;
@property (nonatomic, assign) BOOL didRestoreWebpageState;
@property (nonatomic, retain) UIBarButtonItem *popoverButtonItem;

- (void)saveManagedObjectContext;
- (void)saveManagedObjectContext:(NSManagedObjectContext *)moc;

- (void)sendStatusMessageDidBegin:(NSString *)message;
- (void)sendStatusMessageDidEnd:(NSString *)message;

- (void)showStartupLogin;
- (void)showAlertWithDictionary:(NSDictionary *)errorDict;

- (void)dismissModalViewController;

- (void)runDefaultsPrompt;

- (void)fetchNewsItemsForNNWProxy:(NNWProxy *)nnwProxy;

- (BOOL)shouldNavigateToURL:(NSURL *)url;
- (BOOL)shouldOpenURLInMoviePlayer:(NSURL *)url;

- (void)showAlertWithError:(NSError *)error;
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;

@end


@interface NNWNavigationBar : UINavigationBar
@end

@interface NNWNavigationController : UINavigationController
@end

