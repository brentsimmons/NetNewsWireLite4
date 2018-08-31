//
//  NGModalViewPresenter.h
//  ModalView
//
//  Created by Nicholas Harris on 3/12/10.
//  Copyright 2010 Sirrahsoft LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kModalViewWidth 540
#define kModalViewHeight 620
#define kNGDismissModalViewController @"NGDismissModalViewController"
#define kNGDismissModalViewAnimation  @"NGDismissModalViewAnimation"

@protocol NGModalViewPresenterDelegate
-(void)modalViewDidDismiss:(UIViewController*)viewController;
@end


@interface NGGrayViewController : UIViewController
{
	UIView *modalView;
	UIView *containerView;
}

@property (nonatomic, retain) UIView* containerView;

@end

@interface NGModalViewPresenter : NSObject {
	UIViewController *_modalViewController;
	UIImageView *shadowViewController;
	UIImageView *overlayViewController;
	NGGrayViewController *grayViewController;
	id <NGModalViewPresenterDelegate> delegate;
	UIInterfaceOrientation initialInterfaceOrientation;
}

@property (nonatomic, retain) UIViewController *modalViewController;
@property (nonatomic, assign) id delegate;

-(id)initWithViewController:(UIViewController*)modalViewController;
-(void)presentModalView;
-(void)dismissModalView;

@end
