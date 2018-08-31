//
//  NNWAdView.h
//  nnwiphone
//
//  Created by Brent Simmons on 9/7/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>


extern NSString *NNWAdTouchedNotification;

@interface NNWAdView : UIView {
@private
	NSDictionary *_adDict;
	UILabel *_adTextLabel;
	UILabel *_adsViaDeckLabel;
	UIImageView *_imageView;
	UIImage *_image;
}


+ (NSInteger)adViewHeight;
+ (NNWAdView *)adViewWithFrameIfConnected:(CGRect)frame;


@end
