//
//  RSModalViewPresenter.h
//  Social Sites 2010
//
//  Created by Nicholas Harris on 7/13/10.
//  Copyright 2010 NewsGator Technologies Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kRSModalViewWidth 540
#define kRSModalViewHeight 620
#define kRSDismissModalViewController @"RSDismissModalViewController"
#define kRSDismissModalViewAnimation  @"RSDismissModalViewAnimation"

@protocol RSModalViewPresenterDelegate
-(void)addModalViewAsSubview:(UIView*)modalView;
-(void)modalViewDidDismiss:(UIViewController*)viewController;
@end

@interface RSGrayViewController : UIViewController
{
	UIView *modalView;
	UIView *containerView;
}

@property (nonatomic, retain) UIView* containerView;

@end

@interface RSModalViewPresenter : NSObject {
	UIViewController *_modalViewController;
	UIImageView *shadowViewController;
	UIImageView *overlayViewController;
	RSGrayViewController *grayViewController;
	id <RSModalViewPresenterDelegate> delegate;
}

@property (nonatomic, retain) UIViewController *modalViewController;
@property (nonatomic, assign) id delegate;

-(id)initWithViewController:(UIViewController*)modalViewController;
-(void)presentModalView;
-(void)dismissModalView;

@end
