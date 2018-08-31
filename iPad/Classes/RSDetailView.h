//
//  RSDetailView.h
//  nnwipad
//
//  Created by Brent Simmons on 11/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@class RSDetailContainerView;

@interface RSDetailView : UIView {
@private
	UIToolbar *toolbar;
	RSDetailContainerView *detailContainerView;
}


@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet RSDetailContainerView *detailContainerView;


@end
