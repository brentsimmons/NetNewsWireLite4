//
//  NNWArticleCountView.m
//  nnw
//
//  Created by Brent Simmons on 1/15/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleCountView.h"


@interface NNWArticleCountView ()

@property (nonatomic, assign, readwrite) CGFloat widthNeeded;

- (void)updateUI;
@end


@implementation NNWArticleCountView

@synthesize numberOfArticles;
@synthesize unreadCount;


#pragma mark Init

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
	if (self == nil)
		return nil;
	[self observeValueForKeyPath:@"numberOfArticles" ofObject:self change:nil context:nil];
	[self observeValueForKeyPath:@"unreadCount" ofObject:self change:nil context:nil];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"numberOfArticles"];
	[self removeObserver:self forKeyPath:@"unreadCount"];
	[super dealloc];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self updateUI];
}


#pragma mark UI

- (void)updateUI {
	[self setNeedsDisplay:YES];
}


#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return NO;
}


- (void)drawRect:(NSRect)dirtyRect {
	
	NSRect rNumberOfArticles = [self bounds];
	rNumberOfArticles.size.width = 20.0f;
	
    NSMutableDictionary *numberOfArticlesAttributes = [NSMutableDictionary dictionary];
	[numberOfArticlesAttributes setObject:[NSFont systemFontOfSize:12.0f] forKey:NSFontAttributeName];
	NSString *numberOfArticlesString = [NSString stringWithFormat:@"%d", (int)(self.numberOfArticles)];
	[numberOfArticlesString drawInRect:rNumberOfArticles withAttributes:numberOfArticlesAttributes];
	
	NSRect rUnreadCount = [self bounds];
	rUnreadCount.size.width = 20.0f;
	rUnreadCount.origin.x = 20.0f;
	
    NSMutableDictionary *unreadCountAttributes = [NSMutableDictionary dictionary];
	[unreadCountAttributes setObject:[NSFont systemFontOfSize:12.0f] forKey:NSFontAttributeName];
	NSString *unreadCountString = [NSString stringWithFormat:@"%d", (int)(self.unreadCount)];
	[unreadCountString drawInRect:rUnreadCount withAttributes:unreadCountAttributes];
}


@end
