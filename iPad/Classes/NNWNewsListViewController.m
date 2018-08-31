    //
//  NNWNewsListViewController.m
//  nnwipad
//
//  Created by Brent Simmons on 2/18/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWNewsListViewController.h"
#import "NNWNewsListTableController.h"


@implementation NNWNewsListViewController

@synthesize toolbar;
@synthesize newsListTableView;
@synthesize newsListTableController;

- (id)init {
	return [self initWithNibName:@"NewsList" bundle:nil];
}

- (void)viewDidLoad {
    [self.view addSubview:self.newsListTableController.tableView];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
