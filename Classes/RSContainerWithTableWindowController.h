//
//  RSContainerWithTableWindowController.h
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSContainerWindowController.h"
#import "NNWArticleListScrollView.h"



@interface RSContainerWithTableWindowController : RSContainerWindowController <NNWArticleListDelegate> {
@private
	NNWArticleListScrollView *pluginTableView;
	NSView *containerView;
}

@property (retain) IBOutlet NNWArticleListScrollView *pluginTableView;
@property (retain) IBOutlet NSView *containerView;


@end


#pragma mark -


@interface RSContainerWithTableContentView : NSView

@end


@interface RSContainerWithTableContainerView : NSView

@end

@interface RSContainerTableView : NSTableView

@end
