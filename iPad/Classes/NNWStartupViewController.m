    //
//  NNWStartupViewController.m
//  nnwipad
//
//  Created by Brent Simmons on 11/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWStartupViewController.h"


@implementation NNWStartupViewController

@synthesize representedObject;


#pragma mark Init

- (id)init {
	return [super initWithNibName:@"DishView" bundle:nil];
}


#pragma mark Dealloc

- (void)dealloc {
	[representedObject release];
    [super dealloc];
}


#pragma mark UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark RSContentViewController Protocol

+ (id<RSContentViewController>)contentViewControllerWithRepresentedObject:(id)aRepresentedObject {
	return [[[self alloc] init] autorelease];
}


+ (BOOL)wantsToDisplayRepresentedObject:(id)aRepresentedObject {
	return aRepresentedObject == nil;
}


- (BOOL)canReuseViewWithRepresentedObject:(id)aRepresentedObject {
	return YES;
}


- (NSArray *)toolbarItems:(BOOL)orientationIsLandscape {
	return nil;
}

@end


#pragma mark -

@implementation NNWStartupView

@synthesize imageView;


#pragma mark Dealloc

- (void)dealloc {
	[imageView release];
    [super dealloc];
}

#pragma mark Layout

- (void)layoutSubviews {
	CGRect r = self.bounds;
	CGRect rImage = self.imageView.frame;
	rImage.origin.x = CGRectGetMidX(self.bounds) - (rImage.size.width / 2.0f);
	rImage.origin.y = 206.0f;
	rImage.origin.x = 228.0f;
	if (r.size.height > 900.0f) { //portrait
		rImage.origin.x = 260.0f;
		rImage.origin.y = 334.0f;
	}
	rImage = CGRectIntegral(rImage);
	self.imageView.frame = rImage;
}

@end
