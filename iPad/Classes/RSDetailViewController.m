//
//  RSDetailViewController.m
//  nnwipad
//
//  Created by Brent Simmons on 11/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDetailViewController.h"
#import "RSDetailContainerView.h"
#import "NNWAppDelegate.h"


NSString *RSSplitViewPopoverButtonItemDidAppearNotification = @"RSSplitViewPopoverButtonItemDidAppearNotification";
NSString *RSSplitViewPopoverButtonItemDidDisappearNotification = @"RSSplitViewPopoverButtonItemDidDisappearNotification";


@interface RSDetailViewController ()

@property (nonatomic, retain) UIPopoverController *popoverController;
@property (nonatomic, retain, readwrite) UIViewController<RSContentViewController> *contentViewController;
@property (nonatomic, retain) NSMutableArray *registeredContentViewControllerClasses;
@property (nonatomic, retain) NSMutableArray *representedObjectSourceStack;
@property (nonatomic, retain) id representedObject;
@property (nonatomic, retain) UIViewController *oldContentViewController;
@property (nonatomic, assign) BOOL didRegisterAsKVOObserver;
@property (nonatomic, retain) UIBarButtonItem *popoverBarButtonItem;
@property (nonatomic, assign) BOOL orientationIsLandscape;

- (void)updateToolbar;

@end


@implementation RSDetailViewController

@synthesize popoverController;
@synthesize toolbar;
@synthesize detailContainerView;
@synthesize contentViewController;
@synthesize registeredContentViewControllerClasses;
@synthesize representedObject;
@synthesize representedObjectSourceStack;
@synthesize oldContentViewController;
@synthesize didRegisterAsKVOObserver;
@synthesize popoverBarButtonItem;
@synthesize orientationIsLandscape;


#pragma mark -
#pragma mark Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self == nil)
		return nil;
	representedObjectSourceStack = [[NSMutableArray array] retain];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[popoverController release];
	[toolbar release];
	[detailContainerView release];
	[contentViewController release];
	[registeredContentViewControllerClasses release];
	[representedObject release];
	[representedObjectSourceStack release];
	[oldContentViewController release];
	[popoverBarButtonItem release];
	[super dealloc];
}


#pragma mark UIViewController

- (void)viewDidLoad {
	if (!self.didRegisterAsKVOObserver) {
		[self addObserver:self forKeyPath:@"representedObject" options:NSKeyValueObservingOptionInitial context:nil];
		[self addObserver:self forKeyPath:@"contentViewController" options:NSKeyValueObservingOptionInitial context:nil];
		[self addObserver:self forKeyPath:@"orientationIsLandscape" options:NSKeyValueObservingOptionInitial context:nil];
		self.didRegisterAsKVOObserver = YES;
	}
}


- (void)viewDidUnload {
	self.popoverController = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	app_delegate.interfaceOrientation = toInterfaceOrientation;
	
	NSMutableDictionary *userInfoDict = [NSMutableDictionary dictionary];
	[userInfoDict setObject:[NSNumber numberWithInt:toInterfaceOrientation] forKey:@"orientation"];
	[userInfoDict setObject:[NSNumber numberWithDouble:duration] forKey:@"duration"];
	
	NSNotification *rotationNotification = [NSNotification notificationWithName:NNWWillAnimateRotationToInterfaceOrientation 
																		 object:nil 
																	   userInfo:userInfoDict];
	[[NSNotificationCenter defaultCenter] postNotification:rotationNotification];	
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	NSMutableDictionary *userInfoDict = [NSMutableDictionary dictionary];
	[userInfoDict setObject:[NSNumber numberWithInt:fromInterfaceOrientation] forKey:@"orientation"];
	
	NSNotification *rotationNotification = [NSNotification notificationWithName:NNWDidAnimateRotationToInterfaceOrientation 
																		 object:nil 
																	   userInfo:userInfoDict];
	[[NSNotificationCenter defaultCenter] postNotification:rotationNotification];
}


#pragma mark Popover

- (void)closePopoverIfNeeded {
	if (self.popoverController != nil && self.popoverController.isPopoverVisible)
        [self.popoverController dismissPopoverAnimated:YES];	
}
	

#pragma mark Split view support

- (void)splitViewController: (UISplitViewController*)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem*)barButtonItem forPopoverController: (UIPopoverController*)pc {
	self.popoverController = pc;
	self.popoverBarButtonItem = barButtonItem;
	self.popoverBarButtonItem.width = 132.0f;
	NSDictionary *userInfo = [NSDictionary dictionaryWithObject:barButtonItem forKey:@"popoverButtonItem"];
	[[NSNotificationCenter defaultCenter] postNotificationName:RSSplitViewPopoverButtonItemDidAppearNotification object:self userInfo:userInfo];
	self.orientationIsLandscape = NO;
}


- (void)splitViewController: (UISplitViewController*)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	self.popoverController = nil;
	self.popoverBarButtonItem = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:RSSplitViewPopoverButtonItemDidDisappearNotification object:self userInfo:nil];
	self.orientationIsLandscape = YES;
}


#pragma mark Content Views

- (NSArray *)toolbarItemsForCurrentContentViewController {
	if (self.contentViewController == nil || ![self.contentViewController respondsToSelector:@selector(toolbarItems:)])
		return nil;
	return [self.contentViewController toolbarItems:self.orientationIsLandscape];
}


- (void)updateToolbar {
	NSMutableArray *toolbarItems = [NSMutableArray array];
	if (self.popoverBarButtonItem != nil)
		[toolbarItems addObject:self.popoverBarButtonItem];
	NSArray *contentViewToolbarItems = [self toolbarItemsForCurrentContentViewController];
	if (!RSIsEmpty(contentViewToolbarItems))
		[toolbarItems addObjectsFromArray:contentViewToolbarItems];
	[self.toolbar setItems:toolbarItems animated:YES];
}


- (UIViewController<RSContentViewController> *)findOrMakeContentViewController {
	
	UIViewController<RSContentViewController> *viewControllerToUse = nil;
	
	if (self.contentViewController != nil && [[self.contentViewController class] wantsToDisplayRepresentedObject:self.representedObject]) {
		if ([self.contentViewController respondsToSelector:@selector(canReuseViewWithRepresentedObject:)] && [self.contentViewController canReuseViewWithRepresentedObject:self.representedObject] && [self.contentViewController respondsToSelector:@selector(setRepresentedObject:)])
			viewControllerToUse = self.contentViewController;
	}
	
	for (Class oneContentViewControllerClass in self.registeredContentViewControllerClasses) {
		if ([oneContentViewControllerClass wantsToDisplayRepresentedObject:self.representedObject]) {
			viewControllerToUse = [oneContentViewControllerClass contentViewControllerWithRepresentedObject:self.representedObject];
			break;
		}
	}
	
	if (viewControllerToUse != nil) {
		viewControllerToUse.representedObject = self.representedObject;
		return viewControllerToUse;
	}
	return nil;
}


- (void)swapInContentViewControllerIfNeeded {
	UIViewController *viewControllerToSwapIn = [self findOrMakeContentViewController];
	if (viewControllerToSwapIn != nil && self.contentViewController != viewControllerToSwapIn) {
		self.oldContentViewController = self.contentViewController;
		self.contentViewController = viewControllerToSwapIn;
		if ([self.contentViewController respondsToSelector:@selector(viewDidAppear:)])
			[self.contentViewController viewDidAppear:YES];
	}
}


- (void)swapInContentView {
	self.detailContainerView.contentView = self.contentViewController.view;
	[self updateToolbar];
}


#pragma mark RSContainerViewController Protocol

- (void)registerContentViewControllerClass:(Class)aClass {
	if (self.registeredContentViewControllerClasses == nil)
		self.registeredContentViewControllerClasses = [NSMutableArray array];
	if (aClass == nil || [self.registeredContentViewControllerClasses containsObject:aClass])
		return;
	[self.registeredContentViewControllerClasses addObject:aClass];
}


- (void)userDidSelectObject:(id<RSUserSelectedObjectSource>)sender {
	self.representedObjectSourceStack = [NSMutableArray arrayWithObject:sender];
	self.representedObject = sender.userSelectedObject;
}


- (void)userDidSelectTemporaryObject:(id <RSUserSelectedObjectSource>)sender {
	[self.representedObjectSourceStack addObject:sender];
	self.representedObject = sender.userSelectedObject;
}


- (void)userDidDeselectObject:(id <RSUserSelectedObjectSource>)sender {
	if ([self.representedObjectSourceStack count] > 0)
		[self.representedObjectSourceStack removeLastObject];
	if ([self.representedObjectSourceStack count] < 1)
		self.representedObject = nil;
	else {
		id<RSUserSelectedObjectSource> currentSource = [self.representedObjectSourceStack lastObject];
		self.representedObject = currentSource.userSelectedObject;
	}
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"representedObject"]) {
		[self closePopoverIfNeeded];
		[self swapInContentViewControllerIfNeeded];		
	}
	else if ([keyPath isEqualToString:@"contentViewController"]) {
		[self closePopoverIfNeeded];
		[self swapInContentView];		
	}
	else if ([keyPath isEqualToString:@"orientationIsLandscape"])
		[self updateToolbar];
}


@end


#pragma mark -

@implementation RSDetailView

@synthesize toolbar;
@synthesize detailContainerView;

#pragma mark Dealloc

- (void)dealloc {
	[toolbar release];
	[detailContainerView release];
	[super dealloc];
}


- (void)layoutSubviews {
	CGRect r = self.bounds;
	CGRect rToolbar = CGRectMake(0, 0, r.size.width, 44.0f);
	rToolbar = CGRectIntegral(rToolbar);
	self.toolbar.frame = rToolbar;
	CGRect rContainerView = r;
	rContainerView.origin.y = CGRectGetMaxY(rToolbar);
	rContainerView.size.height = CGRectGetHeight(r) - rContainerView.origin.y;
	rContainerView = CGRectIntegral(rContainerView);
	self.detailContainerView.frame = rContainerView;
}

@end


