//
//  BCFastNewsItemCell.m
//  bobcat
//
//  Created by Brent Simmons on 3/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWNewsListCell.h"
#import "NNWFeedProxy.h"
#import "NNWNewsListCellContentView.h"


@implementation NNWNewsListCell

@synthesize tableController;

#pragma mark Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		CGRect r = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
		_cellView = [[NNWNewsListCellContentView alloc] initWithFrame:r];
		_cellView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_cellView.contentMode = UIViewContentModeRedraw;
		[self.contentView addSubview:_cellView];
		if ([reuseIdentifier hasSuffix:@"-alt"])
			_cellView.isAlternate = YES;
		self.clipsToBounds = YES;
		self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[_cellView removeFromSuperview];
	[_cellView release];
	[super dealloc];
}


#pragma mark Accessors

- (void)setNewsItemProxy:(id)newsItemProxy {
	_cellView.newsItemProxy = (NNWNewsItemProxy *)newsItemProxy;
}


- (void)setTableController:(NNWNewsListTableController *)aTableController {
	_cellView.tableController = aTableController;
}


- (void)setIsAlternate:(BOOL)flag {
	_cellView.isAlternate = flag;
}


- (void)setHighlighted:(BOOL)flag {
	_cellView.highlighted = flag;
	[self setNeedsDisplay];
}


- (void)setSelected:(BOOL)flag {
	_cellView.selected = flag;
	[self setNeedsDisplay];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[self setSelected:selected];
}


- (BOOL)wantsThumbnailWithURLString:(NSString *)urlString {
	return [_cellView wantsThumbnailWithURLString:urlString];
}


- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	[_cellView setNeedsDisplay];
}


- (BOOL)isOpaque {
	return YES;
}


- (void)prepareForReuse {
	[_cellView prepareForReuse];
	[super prepareForReuse];
}


@end
