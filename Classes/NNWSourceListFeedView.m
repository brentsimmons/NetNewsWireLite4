//
//  NNWSourceListFeedView.m
//  nnw
//
//  Created by Brent Simmons on 11/28/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWSourceListFeedView.h"


@interface NNWSourceListFeedView ()

@property (nonatomic, retain) CALayer *imageLayer;
@end

@implementation NNWSourceListFeedView

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil)
		return nil;
//	[self setWantsLayer:YES];
//	imageLayer = [[CALayer layer] retain];
//	imageLayer.frame = CGRectMake(8.0f, 8.0f, 64.0f, 64.0f);
//	imageLayer.contentsGravity = kCAGravityResizeAspectFill;
//	[self.layer addSublayer:imageLayer];
	imageView = [[NSImageView alloc] initWithFrame:CGRectMake(8.0f, 8.0f, 64.0f, 64.0f)];
	//[self addSubview:imageView];
	return self;
}


#pragma mark Accessors

static NSImage *imageWithCGImage(CGImageRef aCGImage) {
	return [[[NSImage alloc] initWithCGImage:aCGImage size:NSMakeSize(CGImageGetWidth(aCGImage), CGImageGetHeight(aCGImage))] autorelease];
}


- (void)setRepresentedObject:(id <RSTreeNodeRepresentedObject>)aRepresentedObject {
//	self.imageLayer.frame = CGRectMake(8.0f, 8.0f, 64.0f, 64.0f);
	if (representedObject == aRepresentedObject)
		return;
	[representedObject autorelease];
	representedObject = [aRepresentedObject retain];
	CGImageRef largeImage = nil;
	if ([self.representedObject respondsToSelector:@selector(largeImage)])
		largeImage = (CGImageRef)(self.representedObject.largeImage);
	CGImageRef smallImage = nil;
	if ([self.representedObject respondsToSelector:@selector(smallImage)])
		smallImage = (CGImageRef)(self.representedObject.smallImage);
	if (largeImage != nil) {
		if (self.image != (id)largeImage) {
			[self.imageView setImage:imageWithCGImage(largeImage)];
//			self.imageLayer.contents = (id)largeImage;
			self.image = (id)largeImage;			
		}
	}
	else if (smallImage != nil) {
		if (self.image != (id)smallImage) {
			[self.imageView setImage:imageWithCGImage(smallImage)];
//			self.imageLayer.contents = (id)smallImage;
			self.image = (id)smallImage;
		}
	}
	else {
		if (self.image != nil) {
			[self.imageView setImage:nil];
			self.imageLayer.contents = nil;
			self.image = nil;
		}
	}
}


#pragma mark Layout

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
	[self.imageView setFrame:CGRectMake(8.0f, 8.0f, 64.0f, 64.0f)];
//	self.imageLayer.zPosition = 1.0f;
}


#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return NO;
}


- (void)drawRect:(NSRect)dirtyRect {

	//	[[NSColor clearColor] set];
	//	NSRectFill(dirtyRect);
	//	NSRect rBounds = NSInsetRect([self bounds], 3.0f, 3.0f);
	//
	//	NSRect rclip = NSIntegralRect(rBounds);
	////	rclip.origin.x += 1.5;
	////	rclip.size.width -= 3;
	////	rclip.origin.y += 1.5;
	////	rclip.size.height -= 3;
	//	NSBezierPath *px = [NSBezierPath bezierPathWithRoundedRect:rclip cornerRadius:6.0];
	//	[px setLineWidth:1.0];
	//	[px addClip];
	
	NSRect rBounds = [self bounds];
	
	NSColor *baseColor = [NSColor orangeColor];
//	baseColor = [NSColor colorForControlTint:[NSColor currentControlTint]];
//	baseColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
//	//baseColor = [NSColor colorWithDeviceWhite:217.0f/255.0f alpha:1.0f];
//	baseColor = [NSColor colorWithDeviceWhite:168.0f/255.0f alpha:1.0f];
//	baseColor = [NSColor colorWithDeviceWhite:150.0f/255.0f alpha:0.3f];
//	baseColor = [NSColor selectedTextBackgroundColor];
	//	baseColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
	baseColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f];
//	baseColor = [NSColor colorWithDeviceRed:70.0f/255.0f green:80.0f/255.0f blue:90.0f/255.0f alpha:1.0f];
//	
////	baseColor = [NSColor colorWithDeviceRed:188.0f/255.0f green:194.0f/255.0f blue:203.0f/255.0f alpha:1.0f];
//	//	baseColor = [NSColor colorWithDeviceWhite:217.0f/255.0f alpha:1.0f];
////	baseColor = [NSColor colorWithDeviceRed:225.0f/255.0f green:225.0f/255.0f blue:226.0f/255.0f alpha:1.0f];
	//baseColor = [NSColor colorWithDeviceWhite:238.0f/255.0f alpha:1.0f];
//	//baseColor = [NSColor blueColor];
//	baseColor = [NSColor colorWithDeviceRed:228.0f/255.0f green:228.0f/255.0f blue:228.0f/255.0f alpha:1.0f];
	baseColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:0.8f];
	baseColor = [NSColor colorWithDeviceRed:217.0f/255.0f green:221.0f/255.0f blue:227.0f/255.0f alpha:1.0f];
//	baseColor = [baseColor highlightWithLevel:0.2f];
//	NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:[baseColor shadowWithLevel:0.5f] endingColor:[baseColor shadowWithLevel:0.5f]] autorelease];
//	[gradient drawInRect:rBounds angle:-90.0f];
	
	baseColor = [NSColor colorWithDeviceRed:228.0f/255.0f green:234.0f/255.0f blue:222.0f/255.0f alpha:1.0f];
	//baseColor = [NSColor colorWithDeviceRed:205.0f/255.0f green:210.0f/255.0f blue:225.0f/255.0f alpha:1.0f];
	//baseColor = [baseColor shadowWithLevel:0.5f];
//	static NSColor *backgroundTextureColor = nil;
//	if (backgroundTextureColor == nil)
//		backgroundTextureColor = [[NSColor colorWithPatternImage:[NSImage imageNamed:@"bluepattern"]] retain];
//	[[NSGraphicsContext currentContext] setPatternPhase:NSMakePoint(0, NSMaxY([self bounds]))];
//	[backgroundTextureColor set];
//	NSRectFillUsingOperation(rBounds, NSCompositeSourceOver);

	[baseColor set];
//	[[NSColor whiteColor] set];
//	[[NSColor colorWithDeviceWhite:0.4f alpha:1.0f] set];
	[[NSColor colorWithDeviceWhite:244.0f/255.0f alpha:1.0f] set];
	[[NSColor colorWithDeviceWhite:48.0f/255.0f alpha:1.0f] set];
	//[[NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f] set];
	//[[NSColor blackColor] set];
//	[[[NSColor colorWithDeviceRed:41.0f/255.0f green:56.0f/255.0f blue:83.0f/255.0f alpha:1.0f] shadowWithLevel:0.7] set];
//	NSRectFill(rBounds);
	
	//	NSImage *image = [NSImage imageNamed:@"Feed"];
//	[image drawInRect:rBounds fromRect:NSMakeRect(0.0f, 0.0f, [image size].width, [image size].height) operation:NSCompositeSourceOver fraction:0.2f];
	
//	[baseColor set];
//	NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
	NSBezierPath *p = [NSBezierPath bezierPath];
	[p setLineWidth:1.0f];
	NSRect r = rBounds;
	[p moveToPoint:r.origin];
	[p lineToPoint:NSMakePoint(NSMaxX(r), NSMinY(r))];
	[[NSColor colorWithDeviceWhite:1.0f alpha:0.3f] set];
//	[p stroke];
	
	
	NSBezierPath *p2 = [NSBezierPath bezierPath];
	[p2 setLineWidth:1.0f];
	r.origin.y = NSMaxY(r);
	[p2 moveToPoint:r.origin];
	[p2 lineToPoint:NSMakePoint(NSMaxX(r), r.origin.y)];
	[[NSColor colorWithDeviceWhite:0.0f alpha:0.1f] set];
//	[p2 stroke];
	
	//BOOL didDrawFaviconOnRight = NO;
	static const CGFloat imageWidthAndHeight = 64.0f;
	[NSGraphicsContext saveGraphicsState];
		CGRect rImage = NSMakeRect(8, 8, imageWidthAndHeight, imageWidthAndHeight);
		rImage = CGRectIntegral(CGRectCenteredVerticallyInRect(rImage, rBounds));	
	rImage = CGRectIntegral(CGRectCenteredHorizontallyInRect(rImage, rBounds));
	NSRect rOuterImage = rImage;
//	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rImage xRadius:2.0f yRadius:2.0f];
//	[path addClip];
	CGImageRef largeImage = nil;
	CGImageRef smallImage = nil;
	if ([self.representedObject respondsToSelector:@selector(largeImage)])
		largeImage = (CGImageRef)(self.representedObject.largeImage);
	if ([self.representedObject respondsToSelector:@selector(smallImage)])
		smallImage = (CGImageRef)(self.representedObject.smallImage);
		CGContextRef currentContext = [[NSGraphicsContext currentContext] graphicsPort];
		//	CGRect rImage = NSMakeRect(CGRectGetMaxX(rBounds) - (imageWidthAndHeight + 8), 8, imageWidthAndHeight, imageWidthAndHeight);
//		NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rImage xRadius:5 yRadius:5];
//		[path addClip];
			[[NSColor colorWithDeviceWhite:220.0f/255.0f alpha:1.0f] set];
	[[[NSColor colorWithDeviceRed:155.0f/255.0f green:160.0f/255.0f blue:164.0f/255.0f alpha:1.0f] highlightWithLevel:0.7f] set];
			//[[NSColor whiteColor] set];
			//[[NSColor colorWithDeviceWhite:245.0f/255.0f alpha:1.0f] set];

	NSColor *dgx = [[NSColor colorWithDeviceRed:155.0f/255.0f green:160.0f/255.0f blue:164.0f/255.0f alpha:1.0f] highlightWithLevel:0.8f];
	NSColor *lgx = [[NSColor colorWithDeviceRed:155.0f/255.0f green:160.0f/255.0f blue:164.0f/255.0f alpha:1.0f] highlightWithLevel:0.99f];
	NSGradient *gx = [[[NSGradient alloc] initWithStartingColor:dgx endingColor:lgx] autorelease];
	NSRect rGradientx = rOuterImage;
	//rGradientx.size.height = (rGradientx.size.height / 2.0f) + 8.0f;
	[gx drawInRect:rGradientx angle:-90.0f];
	
			static CGColorRef shadowColor = nil;
			if (shadowColor == nil)
				shadowColor = CGColorCreateGenericGray(1.0f, 0.6f);
//			CGContextSaveGState(currentContext);
//			CGContextSetShadowWithColor(currentContext, CGSizeMake(0.0f, -1.0f), 1.0f, shadowColor);		
//			NSRectFillUsingOperation(rImage, NSCompositeSourceOver);
//			CGContextRestoreGState(currentContext);	
	
	if (largeImage != nil || smallImage != nil) {
		rOuterImage = rImage;
		if (largeImage == nil) {
			rImage = NSMakeRect(8.0f, 8.0f, 16.0f, 16.0f);
			rImage = CGRectIntegral(CGRectCenteredInRect(rImage, rOuterImage));			
		}
		CGImageRef imageToDraw = largeImage ? largeImage : smallImage;
		if ([(id)imageToDraw isKindOfClass:[NSImage class]]) {
			NSImage *nsimage = (NSImage *)imageToDraw;
			[image setFlipped:YES];
			[nsimage drawInRect:rImage fromRect:NSMakeRect(110.0f, 4.0f, 2.0f * imageWidthAndHeight, 2.0f * imageWidthAndHeight) operation:NSCompositeSourceOver fraction:1.0f];
			//[nsimage drawInRect:rImage fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0f];
		}
		else {
			CGContextSaveGState(currentContext);
			CGContextTranslateCTM(currentContext, CGRectGetMinX(rImage), CGRectGetMaxY(rImage));
			CGContextScaleCTM(currentContext, 1, -1);
			CGContextTranslateCTM(currentContext, -rImage.origin.x, -rImage.origin.y);
			CGContextSetBlendMode (currentContext, kCGBlendModeMultiply);
			CGContextDrawImage(currentContext, rImage, imageToDraw);			
			CGContextRestoreGState(currentContext);		
		}
	
		NSColor *dg = [NSColor colorWithDeviceWhite:1.0f alpha:0.00f];
		NSColor *lg = [NSColor colorWithDeviceWhite:1.0f alpha:0.3f];
		NSGradient *g = [[[NSGradient alloc] initWithStartingColor:dg endingColor:lg] autorelease];
		NSRect rGradient = rOuterImage;
		rGradient.size.height = (rGradient.size.height / 2.0f) + 8.0f;
		[g drawInRect:rGradient angle:-90.0f];
		
		//[[NSColor colorWithDeviceWhite:0.6f alpha:1.0f] set];
		[[NSColor colorWithDeviceRed:155.0f/255.0f green:160.0f/255.0f blue:164.0f/255.0f alpha:1.0f] set];
		[[NSColor colorWithDeviceRed:106.0f/255.0f green:161.0f/255.0f blue:243.0f/255.0f alpha:1.0f] set];
		[[NSColor colorWithDeviceWhite:0.0f alpha:1.0] set];
		[[NSColor whiteColor] set];
		NSFrameRect(rOuterImage);
//		[[NSColor whiteColor] set];
//		NSFrameRect(NSInsetRect(rOuterImage, 1, 1));
	//	[[NSColor colorWithDeviceRed:220.0f/255.0f green:184.0f/255.0f blue:85.0f/255.0f alpha:1.0f] set];
//		[[NSColor colorWithDeviceRed:85.0f/255.0f green:220.0f/255.0f blue:136.0f/255.0f alpha:1.0f] set];
//		[[NSColor colorWithDeviceRed:220.0f/255.0f green:213.0f/255.0f blue:174.0f/255.0f alpha:1.0f] set];
		//NSFrameRect(rOuterImage);
		//NSFrameRect(NSInsetRect(rOuterImage, 2, 2));

//		if (largeImage != nil && smallImage != nil) {
//			//didDrawFaviconOnRight = YES;
//			NSRect rSmallImage = rImage;
//			rSmallImage.origin.x = NSMaxX(rSmallImage) - 19.0f;
//			rSmallImage.origin.y = NSMaxY(rSmallImage) - 19.0f;
//			rSmallImage.size.width = 16.0f;
//			rSmallImage.size.height = 16.0f;
//			[[NSColor whiteColor] set];
//			NSRectFillUsingOperation(rSmallImage, NSCompositeSourceOver);
//			[[NSColor grayColor] set];
//			CGContextSaveGState(currentContext);
//			//CGContextSetShadowWithColor(currentContext, CGSizeMake(0.0f, -1.0f), 1.0f, shadowColor);		
//			//NSFrameRect(NSInsetRect(rSmallImage, -1, -1));
//			CGContextTranslateCTM(currentContext, CGRectGetMinX(rSmallImage), CGRectGetMaxY(rSmallImage));
//			CGContextScaleCTM(currentContext, 1, -1);
//			CGContextTranslateCTM(currentContext, -rSmallImage.origin.x, -rSmallImage.origin.y);
//			CGContextSetBlendMode (currentContext, kCGBlendModeMultiply);
//			CGContextDrawImage(currentContext, rSmallImage, smallImage);			
//			CGContextRestoreGState(currentContext);		
//		}
		
		//if (largeImage != nil) {
		//}
	}
	
	[[NSColor colorWithDeviceWhite:1.0f alpha:1.0f] set];
	//[path setLineWidth:2.0f];
	//CGContextSetShadowWithColor(currentContext, CGSizeMake(0.0f, -2.0f), 4.0f, shadowColor);		
	[[NSColor colorWithDeviceRed:155.0f/255.0f green:160.0f/255.0f blue:164.0f/255.0f alpha:1.0f] set];
	//[path stroke];
//	[imageWithCGImage((CGImageRef)(self.image)) drawInRect:[self.imageView frame] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[NSGraphicsContext restoreGraphicsState];

	
	CGContextSaveGState(currentContext);
	CGContextSetShadowWithColor(currentContext, CGSizeMake(0.0f, 2.0f), 3.0f, shadowColor);		
	NSBezierPath *px = [NSBezierPath bezierPath];
	[px setLineWidth:1.0f];
	[px moveToPoint:NSMakePoint(NSMinX(rOuterImage) - 1.0f, NSMaxY(rOuterImage))];
	[px lineToPoint:NSMakePoint(NSMaxX(rOuterImage) + 1.0f, NSMaxY(rOuterImage))];
	[[NSColor colorWithDeviceRed:155.0f/255.0f green:160.0f/255.0f blue:164.0f/255.0f alpha:0.5f] set];
	//[px stroke];
	CGContextRestoreGState(currentContext);	
	

//	NSImage *actionImage = [NSImage imageNamed:NSImageNameActionTemplate];
//	NSRect rAction = NSMakeRect(0.0f, 0.0f, 16.0f, 16.0f);
//	rAction.origin.x = rBounds.size.width - 40.0f;
//	rAction = CGRectCenteredVerticallyInRect(rAction, rBounds);
//	rAction = NSIntegralRect(rAction);
//	[actionImage drawInRect:rAction fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:0.2f];
	
	if (RSStringIsEmpty(self.title))
		return;
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	NSColor *fontColor = [NSColor colorWithDeviceRed:120.0f/255.0f green:126.0f/255.0f blue:139.0f/255.0f alpha:1.0f];
	fontColor = [NSColor colorWithDeviceWhite:0.95f alpha:1.0f];
	//fontColor = [baseColor shadowWithLevel:0.7f];
	fontColor = [fontColor highlightWithLevel:0.0f];
	//fontColor = [fontColor highlightWithLevel:0.5f];
	fontColor = [NSColor colorWithDeviceWhite:0.95f alpha:1.0f];
	fontColor = [NSColor colorWithDeviceRed:220.0f/255.0f green:184.0f/255.0f blue:85.0f/255.0f alpha:1.0f];
	fontColor = [NSColor colorWithDeviceRed:106.0f/255.0f green:161.0f/255.0f blue:243.0f/255.0f alpha:1.0f];
	fontColor = [[NSColor blackColor] highlightWithLevel:0.8f];
	//fontColor = [NSColor colorWithDeviceWhite:0.95f alpha:1.0f];
[attributes setObject:fontColor forKey:NSForegroundColorAttributeName];
	//[attributes setObject:[NSColor colorWithDeviceWhite:0.0f alpha:0.8f] forKey:NSForegroundColorAttributeName];
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0f alpha:0.3f]];
	[shadow setShadowBlurRadius:1.0f];
	//[attributes setObject:shadow forKey:NSShadowAttributeName];
	 
	[attributes setObject:[NSFont systemFontOfSize:12.0f] forKey:NSFontAttributeName];

	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
	[attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];

	NSAttributedString *titleString = [[[NSAttributedString alloc] initWithString:self.title attributes:attributes] autorelease];
	NSRect rTitle = [titleString boundingRectWithSize:NSMakeSize(NSWidth([self bounds]) - 8.0f, 20.0f) options:NSStringDrawingUsesLineFragmentOrigin];
	rTitle = [titleString boundingRectWithSize:NSMakeSize(96.0f, 1024.0f) options:NSStringDrawingUsesLineFragmentOrigin];
	rTitle = CGRectCenteredHorizontallyInRect(rTitle, [self bounds]);
	rTitle.origin.y = 79.0f;
	rTitle = CGRectIntegral(rTitle);
	[[NSColor colorWithDeviceRed:220.0f/255.0f green:184.0f/255.0f blue:85.0f/255.0f alpha:1.0f] set];
	[[NSColor colorWithDeviceWhite:1.0f alpha:0.9f] set];
	NSRect rTitleBackground = NSInsetRect(rTitle, -2.0f, -2.0f);
	rTitleBackground.origin.y = rTitleBackground.origin.y + 1.0f;
	rTitleBackground = CGRectIntegral(rTitleBackground);
	//NSRectFillUsingOperation(rTitleBackground, NSCompositeSourceOver);
	
	NSBezierPath *pUnread = [NSBezierPath bezierPath];
		[pUnread setLineWidth:16.0];
		[pUnread setLineCapStyle:NSRoundLineCapStyle];
	
		[[NSColor whiteColor] set];
		[pUnread moveToPoint:NSMakePoint(rTitleBackground.origin.x, floorf(NSMidY(rTitleBackground)))];
	[pUnread lineToPoint:NSMakePoint(rTitleBackground.origin.x + rTitleBackground.size.width, floorf(NSMidY(rTitleBackground)))];
	[[NSColor colorWithDeviceRed:106.0f/255.0f green:161.0f/255.0f blue:243.0f/255.0f alpha:1.0f] set];
	[[NSColor colorWithDeviceRed:220.0f/255.0f green:184.0f/255.0f blue:85.0f/255.0f alpha:1.0f] set];
	//[pUnread stroke];
	
//	NSPoint titlePoint = NSMakePoint(8.0f, 78.0f);
//	if (didDrawFaviconOnRight)
//		titlePoint.x = titlePoint.x + 20.0f;
	[titleString drawInRect:CGRectIntegral(rTitle)];
//	[titleString drawAtPoint:titlePoint];
}


- (void)prepareForReuse {
	self.image = nil;
	//self.imageLayer.contents = nil;
	[self.imageView setImage:nil];
	self.title = @"";
}


@end
