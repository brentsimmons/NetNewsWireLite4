//
//  NNWArticleGroupHeaderView.h
//  nnw
//
//  Created by Brent Simmons on 12/27/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NNWArticleListScrollView.h"


@class NNWArticleListGroupItem;


@interface NNWArticleGroupHeaderView : NSView <NNWArticleListRowView> {
@private
    BOOL selected;
    NNWArticleListGroupItem *groupItem;
    NSString *reuseIdentifier;
    NSString *title;
    BOOL isFirst;
}

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) NNWArticleListGroupItem *groupItem;
@property (nonatomic, strong) NSString *reuseIdentifier;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) BOOL isFirst;

@end
