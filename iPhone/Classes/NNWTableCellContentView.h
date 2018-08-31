//
//  BCFastCellView.h
//  bobcat
//
//  Created by Brent Simmons on 3/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NNWNewsItemProxy;

@interface NNWTableCellContentView : UIView {
@protected
	NNWNewsItemProxy *_newsItemProxy;
	BOOL _highlighted;
	BOOL _isAlternate;
}


@property (nonatomic, retain) NNWNewsItemProxy *newsItemProxy;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign) BOOL isAlternate;

@end
