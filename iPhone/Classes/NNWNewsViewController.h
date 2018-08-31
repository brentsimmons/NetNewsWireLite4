//
//  NNWNewsViewController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NNWNewsTableViewController, NNWProxy, NNWNewsItemProxy, NNWMainViewController, NNWAdView;

@interface NNWNewsViewController : UIViewController {
@private
	NNWNewsTableViewController *_tableViewController;
	NNWProxy *_nnwProxy;
	UIBarButtonItem *_markAllAsReadToolbarItem;
	NSArray *_googleIDsOfDescendants; /*for folders*/
	NNWMainViewController *_mainViewController;
	NNWAdView *_adView;
	NNWNewsItemProxy *_stateRestoredNewsItemProxy;
}


+ (NNWNewsViewController *)viewControllerWithState:(NSDictionary *)state;

@property (nonatomic, retain) NNWProxy *nnwProxy;
@property (nonatomic, retain) NSArray *googleIDsOfDescendants;
@property (nonatomic, retain, readonly) NNWNewsItemProxy *firstUnreadItem;
@property (nonatomic, assign) NNWMainViewController *mainViewController;
@property (retain) NNWNewsItemProxy *stateRestoredNewsItemProxy;

/*Used by up/down arrows and next-unread for detail view. TODO: make this a delegate thing instead of having the detail view know about this view controller.*/

- (NNWNewsItemProxy *)nextOrPreviousNewsItem:(NNWNewsItemProxy *)relativeToNewsItem directionIsUp:(BOOL)directionIsUp;
- (NNWNewsItemProxy *)nextUnread:(NNWNewsItemProxy *)relativeToNewsItem;

/*State restoring*/

- (NNWNewsItemProxy *)newsItemProxyWithGoogleID:(NSString *)googleID;
- (void)fetchNewsItemsInBackgroundAndWait;

- (void)fetchNewsItems;

@end
