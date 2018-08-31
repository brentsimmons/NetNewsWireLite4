//
//  RSDetailContainerView.h
//  nnwipad
//
//  Created by Brent Simmons on 11/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RSDetailContainerView : UIView {
@private
	UIView *contentView;
	UIView *previousContentView;
}


@property (nonatomic, retain) UIView *contentView;

@end
