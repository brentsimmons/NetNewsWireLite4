//
//  NNWFeedsContainerViewController.h
//  nnwipad
//
//  Created by Brent Simmons on 2/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NNWMainViewController;

@interface NNWFeedsContainerViewController : UIViewController {
@private
	NNWMainViewController *mainViewController;
}


@property (nonatomic, retain) IBOutlet NNWMainViewController *mainViewController;


@end
