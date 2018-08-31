//
//  NNWMainWindowContentView.m
//  NetNewsWire
//
//  Created by Brent Simmons on 9/29/06.
//  Copyright 2006 Ranchero Software. All rights reserved.
//


#import "RSMainWindowContentView.h"


@interface RSMainWindowContentView ()
@property (nonatomic, retain, readwrite) NSViewController *principalViewController;
@end


@implementation RSMainWindowContentView

@synthesize principalViewController;

#pragma mark Dealloc

- (void)dealloc {
	[principalViewController release];
	[super dealloc];
}


#pragma mark Awake from nib

- (void)awakeFromNib {
	self.backgroundColor = [NSColor rs_borderColor];
	NSString *principalViewControllerClassName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"RSPrincipalViewController"];
	self.principalViewController = [[[NSClassFromString(principalViewControllerClassName) alloc] init] autorelease];
	self.childViewController = self.principalViewController;
}


@end


