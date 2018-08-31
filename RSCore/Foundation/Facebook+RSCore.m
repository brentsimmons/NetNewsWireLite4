//
//  Facebook+RSCore.m
//  padlynx
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "Facebook+RSCore.h"


static CGFloat kBorderWidth = 0;
static CGFloat kTitleMarginX = 8;
static CGFloat kTitleMarginY = 4;


static NSString* kRedirectURL = @"fbconnect://success";
static NSString* kSDKVersion = @"ios";
static NSString* kOAuthURL = @"https://graph.facebook.com/oauth/authorize";


@interface NSObject (RSCoreFBStubs)

- (void)addObservers;

@end

@implementation FBDialog (RSCore)

- (void)sizeToFitOrientation:(BOOL)transform {	
}


- (void)showWithHostViewController:(UIViewController *)viewController {
	[self load];
	[self sizeToFitOrientation:NO];
	
	CGFloat innerWidth = self.frame.size.width - (kBorderWidth+1)*2;  
	[_iconView sizeToFit];
	[_titleLabel sizeToFit];
	[_closeButton sizeToFit];
	
	_titleLabel.frame = CGRectMake(
								   kBorderWidth + kTitleMarginX + _iconView.frame.size.width + kTitleMarginX,
								   kBorderWidth,
								   innerWidth - (_titleLabel.frame.size.height + _iconView.frame.size.width + kTitleMarginX*2),
								   _titleLabel.frame.size.height + kTitleMarginY*2);
	
	_iconView.frame = CGRectMake(
								 kBorderWidth + kTitleMarginX,
								 kBorderWidth + floor(_titleLabel.frame.size.height/2 - _iconView.frame.size.height/2),
								 _iconView.frame.size.width,
								 _iconView.frame.size.height);
	
	_closeButton.frame = CGRectMake(
									self.frame.size.width - (_titleLabel.frame.size.height + kBorderWidth),
									kBorderWidth,
									_titleLabel.frame.size.height,
									_titleLabel.frame.size.height);
	
	_webView.frame = CGRectMake(
								kBorderWidth+1,
								kBorderWidth + _titleLabel.frame.size.height,
								innerWidth,
								self.frame.size.height - (_titleLabel.frame.size.height + 1 + kBorderWidth*2));
	
	[_spinner sizeToFit];
	[_spinner startAnimating];
	_spinner.center = _webView.center;
	
//	UIWindow* window = [UIApplication sharedApplication].keyWindow;
//	if (!window) {
//		window = [[UIApplication sharedApplication].windows objectAtIndex:0];
//	}
//	[window addSubview:self];
	
	[viewController.view addSubview:self];
	[self dialogWillAppear];
    
//	self.transform = CGAffineTransformScale([self transformForOrientation], 0.001, 0.001);
//	[UIView beginAnimations:nil context:nil];
//	[UIView setAnimationDuration:kTransitionDuration/1.5];
//	[UIView setAnimationDelegate:self];
//	[UIView setAnimationDidStopSelector:@selector(bounce1AnimationStopped)];
//	self.transform = CGAffineTransformScale([self transformForOrientation], 1.1, 1.1);
//	[UIView commitAnimations];
	
	[self addObservers];
}


@end


@implementation Facebook (RSCore)

- (void)authorize:(NSString*)application_id permissions:(NSArray*)permissions delegate:(id<FBSessionDelegate>)delegate hostViewController:(UIViewController *)hostViewController {
	NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys:application_id, @"client_id", @"user_agent", @"type", kRedirectURL, @"redirect_uri", @"touch", @"display", kSDKVersion, @"sdk", nil];
	if (permissions != nil)
		[params setValue:[permissions componentsJoinedByString:@","] forKey:@"scope"];	
	_sessionDelegate = delegate;	
	[_loginDialog release];
	_loginDialog = [[FBLoginDialog alloc] initWithURL:kOAuthURL loginParams:params delegate:self];	
	[_loginDialog showWithHostViewController:hostViewController];
}


@end

void RSFacebookAuthorize(Facebook *facebook, NSString *applicationID, NSArray *permissions, id<FBSessionDelegate>delegate, UIViewController *hostViewController) {
	return [facebook authorize:applicationID permissions:permissions delegate:delegate hostViewController:hostViewController];
}
