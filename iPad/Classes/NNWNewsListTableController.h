//
//  NNWNewsListTableController.h
//  nnwipad
//
//  Created by Brent Simmons on 2/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSContainerViewProtocols.h"


@class NNWProxy;

@interface NNWNewsListTableController : UITableViewController <RSUserSelectedObjectSource, UIActionSheetDelegate> {
@private
	NNWProxy *nnwProxy;
	NSMutableArray *newsItemProxies;
	NSMutableDictionary *thumbnailCache;
	NSMutableArray *cancelableOperations;
	UIBarButtonItem *markAllReadItem;
	UIButton *markAllReadButton;
	NSInteger indexOfSelectedRow;
	BOOL showingActionSheet;
	UIActionSheet *actionSheet;
	UILabel *navbarTitleLabel;
	NSInteger unreadCount;
	NSString *titleWithoutUnreadCount;
	BOOL didRegisterForNotifications;
	BOOL oneShotGotoFirstUnreadItem;
	BOOL didRestoreState;
	BOOL didRestoreWebPageState;
	BOOL needsToRestoreWebPageState;
	BOOL oneShotReload;
	id userSelectedObject;
}


@property (nonatomic, retain) NNWProxy *nnwProxy;
@property (nonatomic, retain) NSMutableDictionary *thumbnailCache;
@property (nonatomic, retain) NSMutableArray *cancelableOperations; /*Canceled when view disappears*/
@property (nonatomic, assign, readonly) BOOL displayingSingleFeed;
@property (nonatomic, retain, readonly) NSString *titleWithoutUnreadCount;
@property (nonatomic, assign, readonly) NSInteger unreadCount;
@property (nonatomic, assign) BOOL oneShotGotoFirstUnreadItem;

- (UIImage *)thumbnailForURLString:(NSString *)urlString;

- (void)gotoNextUnread;
- (BOOL)canGoUp;
- (void)goUp;
- (BOOL)canGoDown;
- (void)goDown;
- (BOOL)canGoToNextUnreadInSameSubscription;
- (BOOL)nextUnreadIsInOtherSubscription;
- (BOOL)canGoToNextUnread;
- (BOOL)hasAnyUnread;

- (void)selectNextRow;


@end