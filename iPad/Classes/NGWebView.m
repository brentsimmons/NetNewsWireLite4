//
//  NGWebView.m
//  NGWebView
//
//  Created by Nicholas Harris on 3/10/10.
//  Copyright 2010 Sirrahsoft LLC. All rights reserved.
//

#import "NGWebView.h"


@implementation NGWebView

@synthesize delegate, scrollPastContentThreshold, lockContentOffset, scrollView = webViewScrollView;

#pragma mark inits
-(id)init
{
	self = [super init];
	if(!self)
		return nil;
	
	webViewScrollView = [[self.subviews objectAtIndex:0]retain];
	webViewScrollView.delegate = self;
	
	scrollPastContentThreshold = kNGWebViewScrollPastContentThresholdDefault;
	
	return self;
}

-(id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(!self)
		return nil;
	
	webViewScrollView = [[self.subviews objectAtIndex:0]retain];
	webViewScrollView.delegate = self;
	
	scrollPastContentThreshold = kNGWebViewScrollPastContentThresholdDefault;
	
	return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if(!self)
		return nil;
	
	webViewScrollView = [[self.subviews objectAtIndex:0]retain];
	webViewScrollView.delegate = self;
	
	scrollPastContentThreshold = kNGWebViewScrollPastContentThresholdDefault;
		
	return self;
}

-(void)dealloc
{
	[webViewScrollView release];
	[super dealloc];
}

#pragma mark Property Setters
-(void)setScrollPastContentThreshold:(NSInteger)i
{
	if(i < 0)
		scrollPastContentThreshold = 0;
}

-(void)setDelegate:(id)value
{
	delegate = value;
	[super setDelegate:value];
}

#pragma mark UIScrollView delegates
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if(lockContentOffset)
		[scrollView setContentOffset:contentOffset animated:NO];
	
	if(scrollView.dragging)
	{
		contentOffset = scrollView.contentOffset;
		CGSize contentSize = scrollView.contentSize;
		float actualHeight = contentSize.height - scrollView.frame.size.height;
		
		if((contentOffset.y < 0)&&(abs(contentOffset.y) > scrollPastContentThreshold))
		{
			//NSLog(@"scrollViewDidScroll:above");
			webViewHasScrolledAboveContent = true;
		}
		else if (contentOffset.y > (actualHeight + scrollPastContentThreshold))
		{	
			//NSLog(@"scrollViewDidScroll:below");
			webViewHasScrolledBelowContent = true;
		}
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	//NSLog(@"scrollViewDidEndDragging");
	
	if((webViewHasScrolledAboveContent)&&
	   (delegate)&&
	   ([delegate respondsToSelector:@selector(webViewDidScrollAboveContent:)]))
		[delegate webViewDidScrollAboveContent:self];
	
	else if((webViewHasScrolledBelowContent)&&
	   (delegate)&&
	   ([delegate respondsToSelector:@selector(webViewDidScrollBelowContent:)]))
		[delegate webViewDidScrollBelowContent:self];
	
	webViewHasScrolledAboveContent = false;
	webViewHasScrolledBelowContent = false;
}

@end
