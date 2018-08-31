//
//  NNWSourceListDocumentView.m
//  nnw
//
//  Created by Brent Simmons on 11/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSourceListDocumentView.h"


@implementation NNWSourceListDocumentView


//- (id)initWithFrame:(NSRect)frameRect {
//	self = [super initWithFrame:frameRect];
//	if (self == nil)
//		return nil;
//	[self setWantsLayer:YES];
//	return self;
//}


#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return NO;
}


//- (void)drawRect:(NSRect)r {
// //   [[NSColor whiteColor] set];
////	[[NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f] set];
////
////	NSRectFillUsingOperation(r, NSCompositeSourceOver);
//	NSColor *baseColor = [NSColor colorWithDeviceRed:188.0f/255.0f green:194.0f/255.0f blue:203.0f/255.0f alpha:1.0f];
////	baseColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
////	baseColor = [NSColor colorWithDeviceRed:228.0f/255.0f green:228.0f/255.0f blue:228.0f/255.0f alpha:1.0f];
////	baseColor = [baseColor highlightWithLevel:0.2f];
//	[baseColor set];
//	NSRectFillUsingOperation(r, NSCompositeSourceOver);
//	
//	NSImage *image = [NSImage imageNamed:@"SourceListBackground"];
//	NSRect imageRect = NSMakeRect(0, 0, [image size].width, [image size].height);
//	[image drawInRect:imageRect fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0f];
//	
//	
////	NSImage *dishImage = [NSImage imageNamed:@"Dish"];
////	NSSize dishImageSize = [dishImage size];
////	NSRect rBounds = [self bounds];
////	NSRect rDish = rBounds;
////	rDish.size = dishImageSize;
////	rDish.origin.x = NSMidX(rBounds) - (dishImageSize.width / 2);
////	//rDish.origin.y = NSMaxY(rBounds) - (dishImageSize.height + 36.0f);//0.0f;//NSMidY(rBounds) - (dishImageSize.height / 2);
////	rDish.origin.y = NSMidY(rBounds) - (dishImageSize.height / 2);
////	rDish = NSIntegralRect(rDish);
////	NSRect fromRect = rDish;
////	fromRect.origin.x = 0.0f;
////	fromRect.origin.y = 0.0f;
////	fromRect = NSIntegralRect(fromRect);
////	//[dishImage drawAtPoint:rDish.origin fromRect:fromRect operation:NSCompositeSourceOver fraction:0.1f];
////	[dishImage drawInRect:rDish fromRect:fromRect operation:NSCompositeSourceOver fraction:0.3f respectFlipped:YES hints:nil]; 
//}


@end
