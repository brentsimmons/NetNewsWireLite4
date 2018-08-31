//
//  NNWArticleCountView.h
//  nnw
//
//  Created by Brent Simmons on 1/15/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWArticleCountView : NSView {
@private
	NSUInteger numberOfArticles;
	NSUInteger unreadCount;
	CGFloat widthNeeded;
}

@property (nonatomic, assign) NSUInteger numberOfArticles;
@property (nonatomic, assign) NSUInteger unreadCount;
//@property (nonatomic, assign, readonly) CGFloat widthNeeded;

@end
