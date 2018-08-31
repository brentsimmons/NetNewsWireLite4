//
//  NNWNewsListViewController.h
//  nnwipad
//
//  Created by Brent Simmons on 2/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NNWNewsListTableController;

@interface NNWNewsListViewController : UIViewController {
@private
	UIToolbar *toolbar;
	UITableView *newsListTableView;
	NNWNewsListTableController *newsListTableController;
}


@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UITableView *newsListTableView;
@property (nonatomic, retain) IBOutlet NNWNewsListTableController *newsListTableController;

@end
