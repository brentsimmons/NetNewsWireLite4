//
//  NNWAddFeedsRowView.h
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NNWArticleListScrollView.h"


@interface NNWAddFeedsRowView : NSView  <NNWArticleListRowView> {
@private
	BOOL selected;
	NSImage *image;
	NSImageView *imageView;
	NSString *reuseIdentifier;
	NSString *title;
}


@property (nonatomic, assign) BOOL selected;
@property (nonatomic, retain) NSImage *image;
@property (nonatomic, retain) NSImageView *imageView;
@property (nonatomic, retain) NSString *reuseIdentifier;
@property (nonatomic, retain) NSString *title;


@end
