//
//  NNWBrowserAddressTextField.m
//  nnwipad
//
//  Created by Brent Simmons on 3/12/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWBrowserAddressTextField.h"


@implementation NNWBrowserAddressTextField


- (void)commonInit {
	self.background = [[UIImage imageNamed:@"WebviewAddressField.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:10];
	self.borderStyle = UITextBorderStyleNone;
}


- (id)init {
	self = [super init];
	if (!self)
		return nil;
	[self commonInit];
	return self;
}


- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	[self commonInit];
	return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (!self)
		return nil;
	[self commonInit];
	return self;
}


/*Text is placed strangely without these UITextField overrides.
 These are tested where height is 32, which is the height of the graphic.
 They may need to be changed for other heights.*/

static const NSInteger kNNWBrowserAddressTextFieldRightViewWidth = 16;
static const NSInteger kNNWBrowserAddressTextFieldRightViewMarginLeft = 12;

- (CGRect)textRectForBounds:(CGRect)bounds {
	CGRect r = CGRectInset(bounds, 6, 4);
	r.size.width -= (kNNWBrowserAddressTextFieldRightViewWidth + kNNWBrowserAddressTextFieldRightViewMarginLeft);
	return r;
}


- (CGRect)editingRectForBounds:(CGRect)bounds {
	return [self textRectForBounds:bounds];
}


- (CGRect)rightViewRectForBounds:(CGRect)bounds {
	CGRect r = bounds;
	r.size.width = kNNWBrowserAddressTextFieldRightViewWidth;
	r.origin.x = CGRectGetMaxX(bounds) - r.size.width;
	return r;
}


@end
