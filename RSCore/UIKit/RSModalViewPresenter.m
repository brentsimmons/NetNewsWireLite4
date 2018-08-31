//
//  NGModalViewPresenter.m
//  ModalView
//
//  Created by Nicholas Harris on 3/12/10.
//  Copyright 2010 Sirrahsoft LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RSModalViewPresenter.h"


#ifndef app_delegate
#define app_delegate ([UIApplication sharedApplication].delegate)
#endif

@implementation RSGrayViewController
@synthesize containerView;

-(void)loadView
{
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	CGRect windowFrame = CGRectMake(500, 500, window.frame.size.width, window.frame.size.height);
	
	UIInterfaceOrientation orientation = self.interfaceOrientation;
	if((orientation == UIInterfaceOrientationLandscapeLeft) ||
	   (orientation == UIInterfaceOrientationLandscapeRight))
		windowFrame = CGRectMake(500, 500, window.frame.size.height, window.frame.size.width);
	
	containerView = [[[UIView alloc]initWithFrame:windowFrame]retain];
	containerView.backgroundColor = [UIColor clearColor];
	containerView.autoresizesSubviews = NO;
	containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	windowFrame = CGRectMake(-500, -500, windowFrame.size.width+500, windowFrame.size.height+500);
	modalView = [[[UIView alloc]initWithFrame:windowFrame]retain];
	modalView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
	modalView.autoresizesSubviews = NO;
	modalView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[modalView addSubview:containerView];
	
	self.view = modalView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	//NSLog(@"willRotateToInterfaceOrientation");
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
	//NSLog(@"willAnimateRotationToInterfaceOrientation");
}

-(void)dealloc
{
	[modalView dealloc];
	[super dealloc];
}

@end



@implementation RSModalViewPresenter

@synthesize modalViewController = _modalViewController;
@synthesize delegate;

-(id)initWithViewController:(UIViewController*)modalViewController
{
	self.modalViewController = modalViewController;
	
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(dismissModalView) name:kRSDismissModalViewController object:nil];
	
	return self;
}

-(void)presentModalView
{
	// grab the window from the app delegate
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	CGSize windowSize = CGSizeMake(window.frame.size.width, window.frame.size.height);
	
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if((orientation == UIInterfaceOrientationLandscapeLeft) ||
	   (orientation == UIInterfaceOrientationLandscapeRight))
		windowSize = CGSizeMake(window.frame.size.height, window.frame.size.width);
	
	grayViewController = [[RSGrayViewController alloc]initWithNibName:nil bundle:nil];
	[self.delegate addModalViewAsSubview:grayViewController.view];
	
	self.modalViewController.view.frame = CGRectMake(windowSize.width/2-kRSModalViewWidth/2, windowSize.height, kRSModalViewWidth, kRSModalViewHeight);
	
	
	shadowViewController = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"ViewDropShadow.png"]];
	shadowViewController.frame = CGRectMake(windowSize.width/2-shadowViewController.frame.size.width/2, windowSize.height, shadowViewController.frame.size.width, shadowViewController.frame.size.height);
	
	[grayViewController.containerView addSubview:shadowViewController];
	
	overlayViewController = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"ModalViewOverlay.png"]];
	overlayViewController.frame = CGRectMake(0, 0, 540, 620);
	[self.modalViewController.view addSubview:overlayViewController];
	
	[grayViewController.containerView addSubview:self.modalViewController.view];
	
	self.modalViewController.view.layer.cornerRadius = 7;
	
	// Final animation stuff
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.33];
	
	grayViewController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
	shadowViewController.frame = CGRectMake(windowSize.width/2-shadowViewController.frame.size.width/2, windowSize.height/2-shadowViewController.frame.size.height/2, shadowViewController.frame.size.width, shadowViewController.frame.size.height);
	self.modalViewController.view.frame = CGRectMake(windowSize.width/2-kRSModalViewWidth/2, windowSize.height/2-kRSModalViewHeight/2, kRSModalViewWidth, kRSModalViewHeight);
	
	[UIView commitAnimations];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willRotate:) name:RSWillAnimateRotationToInterfaceOrientation object:nil];
}

-(void)willRotate:(NSNotification*)notification
{
	NSDictionary *userInfoDict = [notification userInfo];
	NSNumber *orientationNumber = [userInfoDict objectForKey:@"orientation"];
	NSNumber *durationNumber = [userInfoDict objectForKey:@"duration"];
	
	UIInterfaceOrientation orientation = [orientationNumber intValue];
	NSTimeInterval duration = [durationNumber doubleValue];
	
	//UIWindow *window = [app_delegate window];
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	CGSize windowSize = CGSizeMake(window.frame.size.width, window.frame.size.height);
	
	if((orientation == UIInterfaceOrientationLandscapeLeft) ||
	   (orientation == UIInterfaceOrientationLandscapeRight))
		windowSize = CGSizeMake(window.frame.size.height, window.frame.size.width);
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:duration];
	shadowViewController.frame = CGRectMake(windowSize.width/2-shadowViewController.frame.size.width/2, windowSize.height/2-shadowViewController.frame.size.height/2, shadowViewController.frame.size.width, shadowViewController.frame.size.height);
	self.modalViewController.view.frame = CGRectMake(windowSize.width/2-kRSModalViewWidth/2, windowSize.height/2-kRSModalViewHeight/2, kRSModalViewWidth, kRSModalViewHeight);
	[UIView commitAnimations];
}

-(void)didRotate:(NSNotification*)notification
{
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	CGSize windowSize = CGSizeMake(window.frame.size.width, window.frame.size.height);
	
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if((orientation == UIInterfaceOrientationLandscapeLeft) ||
	   (orientation == UIInterfaceOrientationLandscapeRight))
		windowSize = CGSizeMake(window.frame.size.height, window.frame.size.width);
	
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDuration:0.33];
	shadowViewController.frame = CGRectMake(windowSize.width/2-shadowViewController.frame.size.width/2, windowSize.height/2-shadowViewController.frame.size.height/2, shadowViewController.frame.size.width, shadowViewController.frame.size.height);
	self.modalViewController.view.frame = CGRectMake(windowSize.width/2-kRSModalViewWidth/2, windowSize.height/2-kRSModalViewHeight/2, kRSModalViewWidth, kRSModalViewHeight);
	[UIView commitAnimations];
}

-(void)dismissModalView
{
	//UIWindow *window = [app_delegate window];
	UIWindow *window = [[UIApplication sharedApplication] keyWindow];
	CGSize windowSize = CGSizeMake(window.frame.size.width, window.frame.size.height);
	
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if((orientation == UIInterfaceOrientationLandscapeLeft) ||
	   (orientation == UIInterfaceOrientationLandscapeRight))
		windowSize = CGSizeMake(window.frame.size.height, window.frame.size.width);
	
	[UIView beginAnimations:kRSDismissModalViewAnimation context:nil];
	[UIView setAnimationDuration:0.33];
	[UIView setAnimationDidStopSelector:@selector(_animationDidStop:finished:context:)];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate:self];
	
	grayViewController.view.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
	self.modalViewController.view.frame = CGRectMake(windowSize.width/2-self.modalViewController.view.frame.size.width/2, windowSize.height, self.modalViewController.view.frame.size.width, self.modalViewController.view.frame.size.height);
	shadowViewController.frame = CGRectMake(windowSize.width/2-shadowViewController.frame.size.width/2, windowSize.height, shadowViewController.frame.size.width, shadowViewController.frame.size.height);
	
	[UIView commitAnimations];
}

- (void)_animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	if([animationID isEqualToString:kRSDismissModalViewAnimation])
	{
		[grayViewController.view removeFromSuperview];
		
		if((self.delegate)&&([self.delegate respondsToSelector:@selector(modalViewDidDismiss:)]))
			[self.delegate modalViewDidDismiss:_modalViewController];
	}
}

-(void)dealloc
{
	[grayViewController release];
	[_modalViewController release];
	[super dealloc];
}

@end
