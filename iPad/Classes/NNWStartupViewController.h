//
//  NNWStartupViewController.h
//  nnwipad
//
//  Created by Brent Simmons on 11/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSContainerViewProtocols.h"


@interface NNWStartupViewController : UIViewController <RSContentViewController> {
@private
	id representedObject;
}

@end


@interface NNWStartupView : UIView {
@private
	UIImageView *imageView;
	
}

@property (nonatomic, retain) IBOutlet UIImageView *imageView;

@end


