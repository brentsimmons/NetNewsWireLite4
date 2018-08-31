//
//  BCFastNewsItemCell.h
//  bobcat
//
//  Created by Brent Simmons on 3/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NNWTableCellContentView, NNWNewsItemProxy;

@interface NNWTableViewCell : UITableViewCell {
@private
	NNWTableCellContentView *_cellView;
}


- (void)setNewsItemProxy:(NNWNewsItemProxy *)newsItemProxy;
- (void)setIsAlternate:(BOOL)flag;


@end
