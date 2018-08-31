//
//  NNWAboutViewController.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/31/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWAboutViewController.h"


@implementation NNWAboutViewController


- (void)viewDidLoad {
	_versionLabel.text = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    [super viewDidLoad];
	self.navigationController.toolbarHidden = YES;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}


@end
