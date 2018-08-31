
//  NNWNewsTableViewController.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


extern NSString *NNWNewsItemsListDidFetchNotification;

@class NNWNewsItemProxy, NNWProxy, NNWAdView;

@interface NNWNewsTableViewController : UITableViewController <NSFetchedResultsControllerDelegate> {
@private
	NSFetchedResultsController *_fetchedResultsController;
	id _delegate;
	NNWProxy *_nnwProxy;
	NSArray *_googleIDsOfDescendants; /*for folders*/
	NSArray *_sections;
	NSArray *_newsItemProxies;
	NNWAdView *_adView;
	NNWNewsItemProxy *_stateRestoredNewsItemProxy;
}


- (void)runFetch;
- (void)runFetchIfNeeded;

- (void)fetchNewsItemsInBackgroundAndWait;

@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) NNWProxy *nnwProxy;
@property (nonatomic, assign, readonly) BOOL hasUnreadItems;
@property (nonatomic, retain) NSArray *googleIDsOfDescendants;
@property (retain, readonly) NSArray *newsItemProxies;
@property (retain) NNWNewsItemProxy *stateRestoredNewsItemProxy;

@end
