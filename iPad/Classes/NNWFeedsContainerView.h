//
//  NNWFeedsContainerView.h
//  nnwipad
//
//  Created by Brent Simmons on 2/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NNWFeedsContainerView : UIView {
@private
	UIToolbar *toolbar;
	UITableView *tableView;
}


@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UITableView *tableView;


@end
