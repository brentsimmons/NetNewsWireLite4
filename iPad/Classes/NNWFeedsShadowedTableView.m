//
//  NNWFeedsShadowedTableView.m
//  nnwipad
//
//  Created by Brent Simmons on 3/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWFeedsShadowedTableView.h"


@implementation NNWFeedsShadowedTableView

- (void)dealloc {
	[topShadowView release];
	[bottomShadowView release];	
	[super dealloc];
}

- (NSIndexPath *)indexPathOfLastRow {
	/*Only works with Feeds list*/
	NSInteger numberOfRowsInSection = [self.dataSource tableView:self numberOfRowsInSection:1];
	if (numberOfRowsInSection < 1)
		return [NSIndexPath indexPathForRow:1 inSection:0];
	return [NSIndexPath indexPathForRow:numberOfRowsInSection - 1 inSection:1];
}


- (void)layoutSubviews {
	[super layoutSubviews];
	static CGSize topShadowSize = {0, 0};
	static CGSize bottomShadowSize = {0, 0};
	if (topShadowView == nil) {
		UIImage *topShadowImage = [UIImage imageNamed:@"FirstFeedShadow.png"];
		topShadowView = [[UIImageView alloc] initWithImage:topShadowImage];
		[self addSubview:topShadowView];
		topShadowSize = topShadowImage.size;
	}
	if (bottomShadowView == nil) {
		UIImage *bottomShadowImage = [UIImage imageNamed:@"LastFeedShadow.png"];
		bottomShadowView = [[UIImageView alloc] initWithImage:bottomShadowImage];
		bottomShadowSize = bottomShadowImage.size;
	}

	topShadowView.frame = CGRectMake(0, -(topShadowSize.height), 320, topShadowSize.height);
	
	NSIndexPath *indexPathOfLastVisibleRow = [self.indexPathsForVisibleRows lastObject];
	NSIndexPath *indexPathOfLastRow = [self indexPathOfLastRow];
	if (indexPathOfLastRow != nil && indexPathOfLastVisibleRow != nil && [indexPathOfLastVisibleRow compare:indexPathOfLastRow] == NSOrderedSame) {
		if (bottomShadowView.superview == nil)
			[self addSubview:bottomShadowView];
		CGRect rBottomShadow = [self rectForRowAtIndexPath:indexPathOfLastRow];
		rBottomShadow.size.width = 320;
		rBottomShadow.origin.y = CGRectGetMaxY(rBottomShadow);
		rBottomShadow.origin.x = 0;
		rBottomShadow.size.height = bottomShadowSize.height;
		bottomShadowView.frame = rBottomShadow;
	}
	else {
		if (bottomShadowView.superview == self)
			[bottomShadowView removeFromSuperview];
	}
}	


@end


@implementation NNWNewsListShadowedTableView

- (NSIndexPath *)indexPathOfLastRow {
	/*Assumes just one section*/
	NSInteger numberOfRowsInSection = [self.dataSource tableView:self numberOfRowsInSection:0];
	if (numberOfRowsInSection < 1)
		return nil;
	return [NSIndexPath indexPathForRow:numberOfRowsInSection - 1 inSection:0];
}

@end