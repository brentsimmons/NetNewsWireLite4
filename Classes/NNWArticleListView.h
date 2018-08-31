//
//  NNWArticleListView.h
//  nnw
//
//  Created by Brent Simmons on 11/26/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NNWArticleListScrollView.h"


@class RSDataArticle;

@protocol NNWArticleContextualMenuDelegate <NSObject>

@required
- (NSMenu *)contextualMenuForArticle:(RSDataArticle *)anArticle;
- (void)selectArticle:(RSDataArticle *)anArticle;

@end


@interface NNWArticleListView : NSView <NNWArticleListRowView> {
@private
    BOOL selected;
    NSString *reuseIdentifier;
    NSString *title;
    RSDataArticle *article;
    NSButton *unreadButton;
    BOOL showFeedName;
    id thumbnail; //CGImageRef
    id webclipIcon; //CGImageRef
    id <NNWArticleContextualMenuDelegate> __unsafe_unretained contextualMenuDelegate;
}

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *reuseIdentifier;

@property (nonatomic, strong) RSDataArticle *article;

@property (nonatomic, assign) BOOL selected;

@property (nonatomic, strong) NSURL *logicalThumbnailURL;

@property (nonatomic, assign) BOOL showFeedName;
@property (nonatomic, unsafe_unretained) id<NNWArticleContextualMenuDelegate> contextualMenuDelegate;

+ (CGFloat)heightForArticleWithThumbnail;

@end
