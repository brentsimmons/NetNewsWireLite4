//
//  RSDrawingUtilities.m
//  nnw
//
//  Created by Brent Simmons on 12/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSDrawingUtilities.h"


void RSCGRectFillWithColor(CGRect r, CGColorRef aColor) {
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort]; //TODO: iPhone version
	CGContextSaveGState(context);
	CGContextSetFillColorWithColor(context, aColor);
	CGContextFillRect(context, r);
	CGContextRestoreGState(context);	
}


CGColorRef RSCGWhiteColor(void) {
	static CGColorRef whiteColor = nil;
	if (whiteColor == nil)
		whiteColor = CGColorRetain(CGColorGetConstantColor(kCGColorWhite));
	return whiteColor;
}


void RSCGRectFillWithWhite(CGRect r) {
	RSCGRectFillWithColor(r, RSCGWhiteColor());
}



void RSDrawCGImageInRectWithBlendMode(CGImageRef cgImage, CGRect r, CGBlendMode blendMode) {	
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState(context);
	CGContextTranslateCTM(context, CGRectGetMinX(r), CGRectGetMaxY(r));
	CGContextScaleCTM(context, 1, -1);
	CGContextTranslateCTM(context, -r.origin.x, -r.origin.y);	
	CGContextSetBlendMode(context, blendMode);
	CGContextDrawImage(context, r, cgImage);
	CGContextRestoreGState(context);	
}

