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
    NNWBrowserViewController *__weak controller;
}

@property (nonatomic, weak) NNWBrowserViewController *controller;
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
    id<NNWBrowserViewControllerDelegate> __unsafe_unretained delegate;
}


@property (nonatomic, strong) IBOutlet NNWToolbar *toolbar;
@property (nonatomic, strong) IBOutlet RSMacWebView *webview;
@property (nonatomic, strong) IBOutlet RSBrowserTextField *addressField;
@property (nonatomic, strong) IBOutlet NSSegmentedControl *backForwardButtons;
@property (nonatomic, strong) IBOutlet NSButton *reloadButton;

@property (nonatomic, unsafe_unretained) id<NNWBrowserViewControllerDelegate> delegate;

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
