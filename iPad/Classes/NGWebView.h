//
//  NGWebView.h
//  NGWebView
//
//  Created by Nicholas Harris on 3/10/10.
//  Copyright 2010 Sirrahsoft LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNGWebViewScrollPastContentThresholdDefault 50;

@protocol NGWebViewDelegate;

@interface NGWebView : UIWebView {
	id<NGWebViewDelegate> delegate;
	NSInteger scrollPastContentThreshold;
	UIScrollView *webViewScrollView;
	BOOL webViewHasScrolledBelowContent;
	BOOL webViewHasScrolledAboveContent;
	BOOL lockContentOffset;
	BOOL lastAttemptedContentOffset;
	CGPoint contentOffset;
}

@property (nonatomic, assign) NSInteger scrollPastContentThreshold;
@property (nonatomic, assign) id<NGWebViewDelegate> delegate;
@property (nonatomic) BOOL lockContentOffset;
@property (nonatomic, readonly) UIScrollView *scrollView;

@end

@protocol NGWebViewDelegate <UIWebViewDelegate>

@optional
-(void)webViewDidScrollBelowContent:(NGWebView*)webView;
-(void)webViewDidScrollAboveContent:(NGWebView*)webView;

@end