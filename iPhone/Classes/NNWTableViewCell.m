//
//  BCFastNewsItemCell.m
//  bobcat
//
//  Created by Brent Simmons on 3/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWTableViewCell.h"
#import "NNWFeedProxy.h"
#import "NNWTableCellContentView.h"


@implementation NNWTableViewCell


#pragma mark Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		CGRect r = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
		_cellView = [[NNWTableCellContentView alloc] initWithFrame:r];
		_cellView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_cellView.contentMode = UIViewContentModeRedraw;
		[self.contentView addSubview:_cellView];
		if ([reuseIdentifier hasSuffix:@"-alt"])
			_cellView.isAlternate = YES;
		self.clipsToBounds = YES;
		self.contentMode = UIViewContentModeRedraw;
		//self.selectionStyle = UITableViewCellSelectionStyleGray;
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


- (void)setIsAlternate:(BOOL)flag {
	_cellView.isAlternate = flag;
}


- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	[_cellView setNeedsDisplay];
}


- (BOOL)isOpaque {
	return YES;
}


@end
