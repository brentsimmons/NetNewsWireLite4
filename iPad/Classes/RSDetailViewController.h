//
//  RSDetailViewController.h
//  nnwipad
//
//  Created by Brent Simmons on 11/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSContainerViewProtocols.h"


/*
 Manages the right side of a split-view controller. View hierarchy:
 detailView
	toolbar
	detailContainerView
 
 Content views should not have their own toolbars -- they should use the one provided here.
 Instead, they must conform to the RSContentViewController protocol, which has a method that asks
 for what the toolbar items should be.
 
 This class handles adding/removing the popover toolbar item. The content views don't need to know about it.
 */

extern NSString *RSSplitViewPopoverButtonItemDidAppearNotification; /*userInfo will have @"popoverButtonItem" key*/
extern NSString *RSSplitViewPopoverButtonItemDidDisappearNotification;

@class RSDetailView;
@class RSDetailContainerView;


@interface RSDetailViewController : UIViewController <RSContainerViewController, UIPopoverControllerDelegate, UISplitViewControllerDelegate> {
@private
    UIPopoverController *popoverController;
	UIToolbar *toolbar;
	RSDetailContainerView *detailContainerView;
//	RSDetailView *detailView;
	UIViewController<RSContentViewController> *contentViewController;
	NSMutableArray *registeredContentViewControllerClasses;
	id representedObject;
	NSMutableArray *representedObjectSourceStack;
	UIViewController *oldContentViewController;
	BOOL didRegisterAsKVOObserver;
	UIBarButtonItem *popoverBarButtonItem;
	BOOL orientationIsLandscape;
}

@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet RSDetailContainerView *detailContainerView;
//@property (nonatomic, retain) IBOutlet RSDetailView *detailView;
@property (nonatomic, retain, readonly) UIViewController<RSContentViewController> *contentViewController;


@end


@interface RSDetailView : UIView {
@private
	UIToolbar *toolbar;
	RSDetailContainerView *detailContainerView;
}


@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet RSDetailContainerView *detailContainerView;


@end