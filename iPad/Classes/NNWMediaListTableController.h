//
//  NNWMediaListTableController.h
//  nnwipad
//
//  Created by Brent Simmons on 2/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NNWMediaListTableController : NSObject <UITableViewDelegate, UITableViewDataSource> {
@private
	UITableView *tableView;
}


@property (nonatomic, retain) IBOutlet UITableView *tableView;


@end
