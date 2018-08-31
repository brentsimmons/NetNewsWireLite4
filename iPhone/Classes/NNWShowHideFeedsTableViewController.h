//
//  NNWShowHideFeedsTableViewController.h
//  nnwiphone
//
//  Created by Brent Simmons on 9/6/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NNWShowHideFeedsTableViewController : UITableViewController {
@private
	NSArray *_feedProxies;
}

+ (NNWShowHideFeedsTableViewController *)showHideFeedsTableViewController;


@end
