//
//  NNWDetailContentContainerView.h
//  nnwipad
//
//  Created by Brent Simmons on 2/19/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NNWDetailContentContainerView : UIView {
@private
	UIToolbar *toolbar;
	UIView *contentView;
}


@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *contentView;


@end
