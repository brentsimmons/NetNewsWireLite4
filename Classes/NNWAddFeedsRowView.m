//
//  NNWAddFeedsRowView.m
//  nnw
//
//  Created by Brent Simmons on 12/20/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWAddFeedsRowView.h"


@implementation NNWAddFeedsRowView

@synthesize image;
@synthesize imageView;
@synthesize reuseIdentifier;
@synthesize selected;
@synthesize title;


#pragma mark Init

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self == nil)
		return nil;
	[self addObserver:self forKeyPath:@"selected" options:0 context:nil];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[self removeObserver:self forKeyPath:@"selected"];
	[title release];
	[reuseIdentifier release];
	[image release];
	[imageView release];
	[super dealloc];
}



#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqualToString:@"selected"])
		[self setNeedsDisplay:YES];
}


#pragma mark Drawing

- (BOOL)isFlipped {
	return YES;
}


- (BOOL)isOpaque {
	return YES;
}


- (void)drawRect:(NSRect)dirtyRect {

	NSRect rBounds = [self bounds];
	NSColor *backgroundColor = [NSColor colorWithDeviceRed:222.0f/255.0f green:228.0f/255.0f blue:234.0f/255.0f alpha:1.0f];

	[backgroundColor set];
	NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);

	NSColor *darkGradientColor = [NSColor colorWithDeviceRed:131.0f/255.0f green:150.f/255.0f blue:184.0f/255.0f alpha:1.0f];
	NSColor *lightGradientColor = [NSColor colorWithDeviceRed:178.0f/255.0f green:191.f/255.0f blue:216.0f/255.0f alpha:1.0f];
	if (self.selected) {
		NSGradient *gradient = [[[NSGradient alloc] initWithStartingColor:darkGradientColor endingColor:lightGradientColor] autorelease];
		[gradient drawInRect:rBounds angle:-90.0f];
	}	
	
	if (RSStringIsEmpty(self.title))
		return;
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	[attributes setObject:[NSColor colorWithDeviceWhite:0.05f alpha:0.95f] forKey:NSForegroundColorAttributeName];
	if (self.selected)
		[attributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	if (self.selected)
		[attributes setObject:[NSColor colorWithDeviceWhite:1.0f alpha:1.0f] forKey:NSForegroundColorAttributeName];//
	if (self.selected)
		[attributes setObject:[NSFont boldSystemFontOfSize:12.0f] forKey:NSFontAttributeName];
	else
		[attributes setObject:[NSFont systemFontOfSize:12.0f] forKey:NSFontAttributeName];
	
	NSMutableParagraphStyle *paragraphStyle = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	[attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	
	CGContextRef context = NULL;
	if (self.selected) {
		context = [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSaveGState(context);
		static CGColorRef shadowColor = nil;
		if (shadowColor == nil)
			shadowColor = CGColorCreateGenericGray(0.0f, 0.5f);
		CGContextSetShadowWithColor(context, CGSizeMake(0.0f, -1.0f), 1.0f, shadowColor);		
	}
	NSAttributedString *titleString = [[[NSAttributedString alloc] initWithString:self.title attributes:attributes] autorelease];
	NSRect rTitle = NSInsetRect([self bounds], 8.0f, 8.0f);
	if (self.image != nil) {
		rTitle = NSMakeRect(8.0f, NSMaxY([self bounds]) - 24.0f, NSWidth([self bounds]) - 16.0f, 16.0f);
	}
	rTitle.origin.y = rTitle.origin.y + 3.0f;
	rTitle = NSIntegralRect(rTitle);
	[titleString drawInRect:rTitle];
	if (self.selected)
		CGContextRestoreGState(context);

	
	if (self.selected) {
		context = [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSaveGState(context);
		static CGColorRef topShadowColor = nil;
		if (topShadowColor == nil)
			topShadowColor = CGColorCreateGenericGray(1.0f, 1.0f);
		CGContextSetShadowWithColor(context, CGSizeMake(0.0f, -1.0f), 6.0f, topShadowColor);		
		NSBezierPath *p = [NSBezierPath bezierPath];
		[p setLineWidth:1.0f];
		[p moveToPoint:NSMakePoint(0, 0.5)];
		[p lineToPoint:NSMakePoint(NSMaxX(rBounds), 0.5)];
		[darkGradientColor set];
		[p stroke];
		CGContextRestoreGState(context);
		
		context = [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSaveGState(context);
		static CGColorRef bottomShadowColor = nil;
		if (bottomShadowColor == nil)
			bottomShadowColor = CGColorCreateGenericGray(0.0f, 0.5f);
		CGContextSetShadowWithColor(context, CGSizeMake(0.0f, 1.0f), 30.0f, bottomShadowColor);		
		NSBezierPath *p2 = [NSBezierPath bezierPath];
		[p2 setLineWidth:1.0f];
		CGFloat maxY = CGRectGetMaxY(rBounds);
		maxY = maxY - 0.5f;
		[p2 moveToPoint:NSMakePoint(0, maxY)];
		[p2 lineToPoint:NSMakePoint(NSMaxX(rBounds), maxY)];
		[darkGradientColor set];
		[p2 stroke];
		CGContextRestoreGState(context);
		
	}
	
	if (self.image != nil) {
		NSSize imageSize = [self.image size];
		NSRect rImage = NSMakeRect(0, 0, imageSize.width, imageSize.height);
		rImage = CGRectCenteredHorizontallyInRect(rImage, [self bounds]);
		rImage.origin.y = 4;
		if (!self.imageView) {
			self.imageView = [[[NSImageView alloc] initWithFrame:rImage] autorelease];			
			[self.imageView setImageScaling:NSImageScaleProportionallyDown];
			[self.imageView setImageFrameStyle:NSImageFrameNone];
			[self.imageView setImage:self.image];
			[self addSubview:self.imageView];
		}
	}
}


- (void)prepareForReuse {
	self.title = @"";
	self.image = nil;
	[self.imageView removeFromSuperview];
	self.imageView = nil;
	self.selected = NO;
}

@end
