//
//  NNWBrowserViewController.h
//  nnw
//
//  Created by Brent Simmons on 12/30/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class NNWBrowserViewController;

@interface NNWBrowserContentView : NSView {
@private
	NNWBrowserViewController *controller;
}

@property (nonatomic, assign) NNWBrowserViewController *controller;
@end



@protocol NNWBrowserViewControllerDelegate <NSObject>

@required

- (void)closeBrowserViewController:(NNWBrowserViewController *)aBrowserViewController;
- (void)browserViewControllerDidChange:(NNWBrowserViewController *)aBrowserViewController; //change of URL, title, something that may affect sharable item
@end


	
@class NNWToolbar;
@class RSMacWebView;
@class RSBrowserTextField;

@interface NNWBrowserViewController : NSViewController {
@private
	NNWToolbar *toolbar;
	RSMacWebView *webview;
	BOOL backButtonClosesView;
	BOOL pageLoadInProgress;
	RSBrowserTextField *addressField;
	NSSegmentedControl *backForwardButtons;
	NSButton *reloadButton;
	id<NNWBrowserViewControllerDelegate> delegate;
}


@property (nonatomic, retain) IBOutlet NNWToolbar *toolbar;
@property (nonatomic, retain) IBOutlet RSMacWebView *webview;
@property (nonatomic, retain) IBOutlet RSBrowserTextField *addressField;
@property (nonatomic, retain) IBOutlet NSSegmentedControl *backForwardButtons;
@property (nonatomic, retain) IBOutlet NSButton *reloadButton;

@property (nonatomic, assign) id<NNWBrowserViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL backButtonClosesView;


- (void)openURL:(NSURL *)aURL;
- (void)detachDelegates;

- (IBAction)openSpecifiedURL:(id)sender;
- (IBAction)backForwardSegmentClicked:(id)sender;

- (IBAction)closeBrowser:(id)sender;

- (void)goBack:(id)sender;
- (void)goForward:(id)sender;

- (void)makeAddressFieldFirstResponder;

@end
