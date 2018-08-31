//
//  MasterViewController.h
//  nnwipad
//
//  Created by Brent Simmons on 2/3/10.
//  Copyright NewsGator Technologies, Inc. 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSContainerViewProtocols.h"


enum  {
	NNWShowHideFeedsItem,
	NNWFolderItem,
	NNWFeedItem
};

extern NSString *NNWUserDidExpandOrCollapseFolderNotification;
extern NSString *NNWViewControllerTitleKey;
extern NSString *NNWMainViewControllerToolbarItemsDidUpdateNotification;

@class RSDetailViewController;
@class NNWOutlineController, NNWFolderProxy, NNWNewsItemProxy;
@class NNWLastUpdateContainerView;
@class NNWFeedSelection;

@interface NNWMainViewController : UITableViewController <RSUserSelectedObjectSource> {
    RSDetailViewController *detailViewController;
	NNWOutlineController *_outlineController;
	NSMutableArray *_flatOutline;
	NSMutableArray *_flatOutlineOfVisibleItems;
	NSTimer *_updateTimer;
	NSArray *_syntheticFeeds;
	UIBarButtonItem *refreshItem;
	UIButton *refreshButton;
	UIActivityIndicatorView *_refreshActivityIndicator;
	UIView *activityIndicatorContainerView;
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
	NSTimer *_updateStatusMessageTimer;
	NSDate *_lastUpdateCellsDate;
	BOOL _mainViewScrolling;
	NSArray *currentFeedIDs;
	NSInteger totalUnreadCount;
	NSInteger numberOfCurrentTableViewAnimations;
	NSArray *lastToolbarItems;
	NSString *titleWithoutUnreadCount;
	NNWLastUpdateContainerView *lastUpdateContainerView;
	UIBarButtonItem *lastUpdateToolbarItem;
	NSDate *lastTitleUpdate;
	NSTimer *updateTitleTimer;
	NNWFeedSelection *savedSelection;
	NSArray *allFeedIDs; /*even excluded*/
	id userSelectedObject;
}

@property (nonatomic, retain) IBOutlet RSDetailViewController *detailViewController;
@property (nonatomic, retain) UIBarButtonItem *refreshItem;
@property (nonatomic, retain) UIButton *refreshButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic, retain, readonly) NSArray *lastToolbarItems;
@property (nonatomic, retain, readonly) NSString *titleWithoutUnreadCount;
@property (nonatomic, assign, readonly) NSInteger totalUnreadCount;
@property (nonatomic, retain) NSArray *allFeedIDs;

- (IBAction)refreshButtonPressed:(id)sender;

+ (NNWMainViewController *)sharedViewController;

- (BOOL)folderWithGoogleIDIsCollapsed:(NSString *)folderGoogleID;
- (NSArray *)googleIDsOfDescendantsOfFolder:(NNWFolderProxy *)folderProxy;

- (void)findNextUnreadItemAndSetupState;

- (void)saveState;
- (void)saveOutlineToDisk;
- (void)restoreState;

- (BOOL)anySubscriptionHasUnread;
- (BOOL)anyNodeOtherThanCurrentHasUnread;


@end


@class NNWProxy, NNWOutlineNode;

@interface NNWFeedSelection : NSObject {
@private
	NSInteger section;
	NSInteger row;
	NNWProxy *nnwProxy;
	NNWOutlineNode *node;
}

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) NSInteger row;
@property (nonatomic, retain) NNWProxy *nnwProxy;
@property (nonatomic, retain) NNWOutlineNode *node;

@end
