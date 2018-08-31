//
//  BCFastNewsItemCell.h
//  bobcat
//
//  Created by Brent Simmons on 3/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NNWNewsListCellContentView, NNWNewsItemProxy;
@class NNWNewsListTableController;

@interface NNWNewsListCell : UITableViewCell {
@private
	NNWNewsListCellContentView *_cellView;
	NNWNewsListTableController *tableController;
}


@property (nonatomic, assign) NNWNewsListTableController *tableController;

- (void)setNewsItemProxy:(NNWNewsItemProxy *)newsItemProxy;
- (void)setIsAlternate:(BOOL)flag;

- (BOOL)wantsThumbnailWithURLString:(NSString *)urlString;


@end
