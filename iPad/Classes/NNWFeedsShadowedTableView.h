//
//  NNWFeedsShadowedTableView.h
//  nnwipad
//
//  Created by Brent Simmons on 3/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@interface NNWFeedsShadowedTableView : UITableView {
@private
	UIImageView *topShadowView;
	UIImageView *bottomShadowView;
}

@end


@interface NNWNewsListShadowedTableView : NNWFeedsShadowedTableView
@end