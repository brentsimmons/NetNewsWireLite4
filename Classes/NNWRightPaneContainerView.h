//
//  NNWRightPaneContainerView.h
//  nnw
//
//  Created by Brent Simmons on 1/19/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWRightPaneContainerView : NSView {
@private
    NSMutableArray *viewStack;
    NSImageView *screenshotViewForAnimation;
    NSSplitView *rightPaneSplitView;
}


- (void)pushViewOnTop:(NSView *)aView;
- (void)popView; //pop
- (void)popAllViews;

@property (nonatomic, assign, readonly) BOOL hasPushedView;
@property (nonatomic, strong, readonly) NSView *topView;

@property (nonatomic, strong) IBOutlet NSSplitView *rightPaneSplitView;

@end
