//
//  NNWToolbar.h
//  nnw
//
//  Created by Brent Simmons on 12/21/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


typedef enum _NNWToolbarItemVisibilityPriority {
    NNWToolbarItemVisibilityPriorityLow,
    NNWToolbarItemVisibilityPriorityMedium,
    NNWToolbarItemVisibilityPriorityHigh
} NNWToolbarItemVisibilityPriority;


@protocol NNWToolbarItem <NSObject>

@optional
@property (nonatomic, assign, readonly) NNWToolbarItemVisibilityPriority visibilityPriority; //NNWToolbarItemVisibilityPriorityLow is default.

@end


#pragma mark -


@class NNWCloseButton;

@interface NNWToolbar : NSView {
@private
    NSArray *toolbarItems;
    NNWCloseButton *closeButton;
}


@property (nonatomic, strong) NSArray *toolbarItems;
@property (nonatomic, strong) IBOutlet NNWCloseButton *closeButton;


@end
