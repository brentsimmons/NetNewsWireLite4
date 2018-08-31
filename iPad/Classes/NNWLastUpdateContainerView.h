//
//  NNWLastUpdateContainerView.h
//  nnwipad
//
//  Created by Brent Simmons on 3/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

/*Contains two subviews: one UILabel with bold Last Refresh: text; second UILabel normal text with actual date.
 It observes the NSUserDefaults key for the last refresh date and updates display itself.*/

@interface NNWLastUpdateContainerView : UIView {
@private
	UILabel *refreshLabel;
	CGSize refreshLabelSize;
	UILabel *dateLabel;
	NSDate *lastUpdateDate;
	NSString *lastUpdateKeyPath;
	NSDateFormatter *displayDateFormatter;
	CGFloat dateLabelTextWidth;
}



@end
