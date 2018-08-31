//
//  NNWSourceListFeedView.h
//  nnw
//
//  Created by Brent Simmons on 11/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NNWArticleListScrollView.h"
#import "RSTreeNode.h"


@interface NNWSourceListFeedView : NSView <NNWArticleListRowView> 

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *reuseIdentifier;

@property (nonatomic, retain) id<RSTreeNodeRepresentedObject> representedObject;

@property (nonatomic, retain) id image;
@property (nonatomic, retain) NSImageView *imageView;

@end
