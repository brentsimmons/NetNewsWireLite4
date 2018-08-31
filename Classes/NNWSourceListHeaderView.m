//
//  NNWSourceListHeaderView.m
//  nnw
//
//  Created by Brent Simmons on 12/24/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NNWSourceListHeaderView.h"


@interface NNWSourceListHeaderView ()

@property (nonatomic, assign) BOOL didAddTextLayer;
@property (nonatomic, retain) CATextLayer *feedsLabelTextLayer;
@end


@implementation NNWSourceListHeaderView


#pragma mark Layout

- (CGRect)frameForFeedsLabelTextLayer {
	return CGRectInset([self bounds], 8.0f, 0.0f);
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	if (self.feedsLabelTextLayer != nil)
		self.feedsLabelTextLayer.frame = [self frameForFeedsLabelTextLayer];
}


#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return YES;
}

- (void)addTextLayer {
	[self setWantsLayer:YES];
	CATextLayer *textLayer = [CATextLayer layer];
	textLayer.string = @"Feeds";
	textLayer.frame = [self frameForFeedsLabelTextLayer];
	textLayer.font = [NSFont boldSystemFontOfSize:13.0f];
	textLayer.fontSize = 13.0f;
	textLayer.foregroundColor = CGColorCreateGenericGray(0.35f, 0.95f);
	textLayer.truncationMode = kCATruncationEnd;
	textLayer.alignmentMode = kCAAlignmentCenter;
	textLayer.shadowColor = CGColorCreateGenericGray(1.0f, 0.75f);
	textLayer.shadowOpacity = 1.0f;
	textLayer.shadowOffset = CGSizeMake(0.0f, -1.0f);
	textLayer.shadowRadius = 1.0f;
	[self.layer addSublayer:textLayer];
	self.feedsLabelTextLayer = textLayer;
}


- (void)drawHorizontalLineAtY:(CGFloat)y withColor:(CGColorRef)lineColor {
	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(context);
	CGContextSetShouldAntialias(context, false);
	
	CGRect rBounds = [self bounds];
	
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, CGRectGetMinX(rBounds), y);
	CGContextAddLineToPoint(context, CGRectGetMaxX(rBounds), y);
	
	CGContextSetLineWidth(context, 1.0f);
	CGContextSetStrokeColorWithColor(context, lineColor);
	CGContextStrokePath(context);
	
	CGContextRestoreGState(context);
}


- (void)drawRect:(NSRect)r {
	
	if (!self.didAddTextLayer) {
		[self addTextLayer];
		self.didAddTextLayer = YES;
	}
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	
	size_t numberOfLocations = 3;
	CGFloat locations[3] = {0.0, 0.25, 1.0};
	CGFloat components[12] = {0.7, 0.7, 0.71, 1.0,  0.8, 0.8, 0.81, 1.0,  0.92, 0.92, 0.94, 1.0};
	
	CGColorSpaceRef deviceColorspace = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(deviceColorspace, components, locations, numberOfLocations);
	
	CGRect rBounds = [self bounds];
	CGContextDrawLinearGradient(context, gradient, CGPointMake(CGRectGetMinX(rBounds), CGRectGetMaxY(rBounds)), rBounds.origin, 0);
	
	CGGradientRelease(gradient);
	CGColorSpaceRelease(deviceColorspace);
	
	static CGColorRef bottomLineColor = nil;
	if (bottomLineColor == nil)
		bottomLineColor = CGColorCreateGenericGray(0.3f, 1.0f);
	static CGColorRef topLineColor = nil;
	if (topLineColor == nil)
		topLineColor = CGColorCreateGenericGray(1.0f, 0.7f);
	
	[self drawHorizontalLineAtY:CGRectGetMaxY(rBounds) withColor:bottomLineColor];
	[self drawHorizontalLineAtY:CGRectGetMinY(rBounds) + 2 withColor:topLineColor];
	
//	CGContextSaveGState(context);
//	CGContextSetShouldAntialias(context, false);
//	CGContextBeginPath(context);
//	CGContextMoveToPoint(context, CGRectGetMinX(rBounds), CGRectGetMaxY(rBounds));
//	CGContextAddLineToPoint(context, CGRectGetMaxX(rBounds), CGRectGetMaxY(rBounds));
//	CGContextClosePath(context);
//	CGContextSetLineWidth(context, 1.0f);
//	CGContextSetStrokeColorWithColor(context, lineColor);
//	CGContextStrokePath(context);
//	CGContextRestoreGState(context);
}


@end
