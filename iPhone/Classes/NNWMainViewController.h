//
//  RootViewController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/6/09.
//  Copyright NewsGator Technologies, Inc. 2009. All rights reserved.
//


enum  {
	NNWSyntheticFeedItem, 
	NNWShowHideFeedsItem,
	NNWSettingsItem,
	NNWAboutNetNewsWireItem,
	NNWFolderItem,
	NNWFeedItem
};


extern NSString *NNWMainViewControllerWillAppearNotification;
extern NSString *NNWUserDidExpandOrCollapseFolderNotification;
extern NSString *NNWViewControllerNameKey; /*state*/
extern NSString *NNWDataNameKey;
extern NSString *NNWStateViewControllerTitleKey;


@class NNWOutlineController, NNWFolderProxy, NNWNewsItemProxy, NNWNewsViewController, NNWAdView;

@interface NNWMainViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
	NNWOutlineController *_outlineController;
	NSMutableArray *_flatOutline;
	NSMutableArray *_flatOutlineOfVisibleItems;
	NSTimer *_updateTimer;
	NSArray *_syntheticFeeds;
	UIBarButtonItem *_refreshButton;
	UIActivityIndicatorView *_refreshActivityIndicator;
	UIBarButtonItem *_refreshActivityIndicatorButton;
	BOOL _feedDownloadsInProgress;
	NSDate *_lastTableViewUpdate;
	BOOL _activeView;
	NSMutableArray *_collapsedFolderGoogleIDs;
	BOOL _tableDisplayDirty; /*reload now if active, or on viewDidAppear*/
	UILabel *_statusTextLabel;
	UIView *_statusTextContainer;
	UIBarButtonItem *_statusToolbarItem;
	NSMutableArray *_statusMessages;
	BOOL _googleSyncCallsInProgress;
	NSArray *_locationInOutline;
	NNWNewsViewController *_newsViewController;
	NNWAdView *_adView;
	NSTimer *_updateStatusMessageTimer;
	NSDate *_lastUpdateCellsDate;
	BOOL _mainViewScrolling;
	NSTimer *_folderUnreadCountTimer;
}


+ (NNWMainViewController *)sharedViewController;

- (BOOL)folderWithGoogleIDIsCollapsed:(NSString *)folderGoogleID;
- (NSArray *)googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)folderProxy;

- (NNWNewsItemProxy *)findNextUnreadItemAndSetupState;

- (void)showStartupLogin;

- (void)saveState;
- (void)saveOutlineToDisk;

- (void)runDefaultsPrompt;


@end
