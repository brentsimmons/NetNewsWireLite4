//
//  BCFastCellView.h
//  bobcat
//
//  Created by Brent Simmons on 3/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NNWNewsItemProxy;
@class NNWNewsListTableController;


@interface NNWNewsListCellContentView : UIView {
@protected
	NNWNewsItemProxy *_newsItemProxy;
	BOOL _highlighted;
	BOOL _selected;
	BOOL _isAlternate;
	NNWNewsListTableController *tableController;
	UIImageView *imageView;
	BOOL shouldAnimateThumbnail;
	BOOL animatingThumbnail;
}


@property (nonatomic, retain) NNWNewsItemProxy *newsItemProxy;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, assign) BOOL isAlternate;
@property (nonatomic, assign) NNWNewsListTableController *tableController;

+ (CGFloat)rowHeightForNewsItem:(NNWNewsItemProxy *)newsItem;

- (BOOL)wantsThumbnailWithURLString:(NSString *)urlString;

- (void)prepareForReuse;


@end
