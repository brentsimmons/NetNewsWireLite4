//
//  NNWMainTableViewCell.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/14/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWMainTableViewCell.h"
#import "NNWFavicon.h"
#import "NNWFeed.h"
#import "NNWFeedProxy.h"
#import "NNWFolderProxy.h"
#import "NNWMainViewController.h"
#import "RSCache.h"


static RSCache *gDateWidthCache = nil;

@interface NNWMainTableCellContentView ()
@property (nonatomic, retain) UIButton *expandCollapseButton;
- (void)updateExpandCollapseButton;
@end


@implementation NNWMainTableCellContentView

@synthesize /*managedObject = _managedObject,*/ highlighted = _highlighted, isAlternate = _isAlternate, indentationLevel = _indentationLevel, indentationWidth = _indentationWidth, delegate = _delegate, representedObject = _representedObject, expandCollapseButton = _expandCollapseButton, mainViewController = _mainViewController, collapsed = _collapsed;

+ (void)initialize {
//	if (!gTextHeightCache)
//		gTextHeightCache = [[NSMutableDictionary dictionaryWithCapacity:50] retain];
	if (!gDateWidthCache)
		gDateWidthCache = [[RSCache cache] retain];
}


- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	//[_managedObject release];
	[_representedObject release];
	[_expandCollapseButton release];
	[super dealloc];
}


#pragma mark Actions

- (void)_expandCollapse:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWUserDidExpandOrCollapseFolderNotification object:self userInfo:self.representedObject];
	[self updateExpandCollapseButton];
//	[[NSNotificationCenter defaultCenter]
}


#pragma mark Subviews

- (void)setHighlighted:(BOOL)highlighted {
	_highlighted = highlighted;
	[self setNeedsDisplay];
}


- (BOOL)isExpandable {
	if (!self.representedObject)
		return NO;
	NSInteger rowType = [[self.representedObject objectForKey:@"rowType"] integerValue];
	return rowType == NNWFolderItem;
}


//- (BOOL)isCollapsed {
//	if (!self.representedObject)
//		return NO;
//	NNWProxy *folderProxy = [self.representedObject objectForKey:@"nnwProxy"];
//	return [self.mainViewController folderWithGoogleIDIsCollapsed:folderProxy.googleID];
//}


- (void)updateExpandCollapseButtonImage {
	[self.expandCollapseButton setImage:self.collapsed ? [UIImage imageNamed:@"collapsed_folder.png"] : [UIImage imageNamed:@"expanded_folder.png"] forState: UIControlStateNormal];	
}


- (void)ensureExpandCollapseButton {
	if (!self.expandCollapseButton) {
		self.expandCollapseButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[self updateExpandCollapseButtonImage];
//		[self.expandCollapseButton setImage:[UIImage imageNamed:@"expanded_folder.png"] forState: UIControlStateNormal];
		[self.expandCollapseButton addTarget:self action:@selector(_expandCollapse:) forControlEvents:UIControlEventTouchUpInside];
		[self.expandCollapseButton setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
		[self addSubview:_expandCollapseButton];
	//	[self.expandCollapseButton setFrame:CGRectMake(8, 9, 23, 23)];
		static CGFloat buttonInsetTop = 19;
		static CGFloat buttonInsetLeft = 9;
		static CGFloat imageWidth = 23;
		static CGFloat imageHeight = 23;
		static CGFloat buttonWidth = 100;
		CGRect rBounds = self.bounds;
		[self.expandCollapseButton setFrame:CGRectMake(0, 0, buttonWidth, CGRectGetHeight(rBounds))];
		CGFloat buttonMaxY = buttonInsetTop + imageHeight;
		CGFloat buttonInsetBottom = CGRectGetHeight(rBounds)  - buttonMaxY;
		CGFloat buttonInsetRight = buttonWidth - (buttonInsetLeft + imageWidth);
		self.expandCollapseButton.imageEdgeInsets = UIEdgeInsetsMake(8, 9, buttonInsetBottom, buttonInsetRight);
	}
}


- (void)updateExpandCollapseButton {
	[self ensureExpandCollapseButton];
//	[self.expandCollapseButton setImage:self.isCollapsed ? [UIImage imageNamed:@"collapsed_folder.png"] : [UIImage imageNamed:@"expanded_folder.png"] forState: UIControlStateNormal];
	[self updateExpandCollapseButtonImage];
}


- (void)setCollapsed:(BOOL)collapsed {
	_collapsed = collapsed;
	[self updateExpandCollapseButton];
	[self setNeedsLayout];
	[self setNeedsDisplay];
}


- (void)ensureExpandCollapseButtonIsRemoved {
	if (!self.expandCollapseButton)
		return;
	[self.expandCollapseButton removeFromSuperview];
	self.expandCollapseButton = nil;
}


- (void)layoutSubviews {
	if ([self isExpandable])
		[self ensureExpandCollapseButton];
	else
		[self ensureExpandCollapseButtonIsRemoved];
}


//- (void)setNeedsDisplay {
//	[self setNeedsLayout];
//	[super setNeedsDisplay];
//}


#pragma mark -
#pragma mark Caches


+ (NSInteger)cachedWidthForDateString:(NSString *)s {
	NSNumber *cachedWidth = [gDateWidthCache cachedObjectForKey:s];
	if (!cachedWidth)
		return NSNotFound;
	return [cachedWidth integerValue];
}


+ (void)cacheWidth:(NSInteger)width forDateString:(NSString *)s {
	[gDateWidthCache cacheObject:[NSNumber numberWithInteger:width] key:s];
}

#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
}

- (UIImage *)folderBackgroundImage {
	
	static UIImage *folderBackgroundImage = nil;
	if (folderBackgroundImage)
		return folderBackgroundImage;
	
	CGRect rBounds = self.bounds;
	rBounds.origin.x = 0.0;
	rBounds.origin.y = 0.0;
	rBounds.size.width = 320 / 8;
	UIGraphicsBeginImageContext(CGSizeMake(rBounds.size.width, rBounds.size.height));
	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());

	CGGradientRef myGradient;
	CGColorSpaceRef myColorspace;
	size_t num_locations = 4;
	CGFloat locations[4] = {0.0, 0.35, 0.65, 1.0};
	CGFloat startGray = 0.965;
	CGFloat middleGray = 0.96;
	CGFloat thirdGray = 0.95;
	CGFloat endGray = 0.94;
	
	CGFloat components[16] = {startGray, startGray, startGray, 1.0, middleGray, middleGray, middleGray, 1.0, thirdGray, thirdGray, thirdGray, 1.0, endGray, endGray, endGray, 1.0};
	myColorspace = CGColorSpaceCreateDeviceRGB();
	myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
	CGPoint myStartPoint, myEndPoint;
	myStartPoint.x = CGRectGetMinX(rBounds);
	myStartPoint.y = CGRectGetMinY(rBounds);
	myEndPoint.x = CGRectGetMinX(rBounds);
	myEndPoint.y = CGRectGetMaxY(rBounds);
	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), myGradient, myStartPoint, myEndPoint, 0);
	CGColorSpaceRelease(myColorspace);
	CGGradientRelease(myGradient);
	
	[[UIColor colorWithWhite:1.0 alpha:1.0] set];
	CGContextBeginPath(context);
	CGContextSetLineWidth(context, 1.0);
	CGContextSetLineCap(context, kCGLineCapSquare);
	CGContextMoveToPoint(context, rBounds.origin.x, CGRectGetMinY(rBounds) + 0.5);
	CGContextAddLineToPoint(context, rBounds.origin.x + rBounds.size.width + 20, CGRectGetMinY(rBounds) + 0.5);
	CGContextStrokePath(context);

	folderBackgroundImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
	CGContextRelease(context);
	UIGraphicsEndImageContext();
	return folderBackgroundImage;		
}


- (UIImage *)syntheticFeedBackgroundImage {
	static UIImage *folderBackgroundImage = nil;
	if (folderBackgroundImage)
		return folderBackgroundImage;
	
	CGRect rBounds = self.bounds;
	rBounds.origin.x = 0.0;
	rBounds.origin.y = 0.0;
	rBounds.size.width = 320 / 8;
	UIGraphicsBeginImageContext(CGSizeMake(rBounds.size.width, rBounds.size.height));
	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
	
	CGGradientRef myGradient;
	CGColorSpaceRef myColorspace;
	size_t num_locations = 4;
	CGFloat locations[4] = {0.0, 0.25, 0.45, 1.0};
	CGFloat startGray = 0.965;
	CGFloat middleGray = 0.962;
	CGFloat thirdGray = 0.955;
	CGFloat endGray = 0.94;
	CGFloat offsetRed = 0.05;
	CGFloat offsetGreen = 0.025;
	CGFloat components[16] = {startGray - offsetRed, startGray - offsetGreen, startGray, 1.0, middleGray - offsetRed, middleGray - offsetGreen, middleGray, 1.0, thirdGray - offsetRed, thirdGray - offsetGreen, thirdGray, 1.0, endGray - offsetRed, endGray - offsetGreen, endGray, 1.0};
	myColorspace = CGColorSpaceCreateDeviceRGB();
	myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
	CGPoint myStartPoint, myEndPoint;
	myStartPoint.x = CGRectGetMinX(rBounds);
	myStartPoint.y = CGRectGetMinY(rBounds);
	myEndPoint.x = CGRectGetMinX(rBounds);
	myEndPoint.y = CGRectGetMaxY(rBounds);
	CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), myGradient, myStartPoint, myEndPoint, 0);
	CGColorSpaceRelease(myColorspace);
	CGGradientRelease(myGradient);
	
	[[UIColor colorWithWhite:1.0 alpha:1.0] set];
	CGContextBeginPath(context);
	CGContextSetLineWidth(context, 1.0);
	CGContextSetLineCap(context, kCGLineCapSquare);
	CGContextMoveToPoint(context, rBounds.origin.x, CGRectGetMinY(rBounds) + 0.5);
	CGContextAddLineToPoint(context, rBounds.origin.x + rBounds.size.width + 20, CGRectGetMinY(rBounds) + 0.5);
	CGContextStrokePath(context);
	
	folderBackgroundImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
	CGContextRelease(context);
	UIGraphicsEndImageContext();
	return folderBackgroundImage;		
}


- (UIImage *)starredItemsBackgroundImage {
	static UIImage *backgroundImage = nil;
	if (backgroundImage)
		return backgroundImage;
//	backgroundImage = [[UIImage gradientImageWithStartColor:[[UIColor slateBlueColor] lightened] endColor:[UIColor slateBlueColor] topLineColor:[[[UIColor slateBlueColor] lightened] lightened] size:self.bounds.size] retain];
//	backgroundImage = [[UIImage gradientImageWithStartColor:[[UIColor colorWithRed:0.484 green:0.577 blue:0.680 alpha:1.000] lightened] endColor:[UIColor colorWithRed:0.484 green:0.577 blue:0.680 alpha:1.000] topLineColor:[UIColor colorWithRed:0.484 green:0.577 blue:0.680 alpha:1.000] size:self.bounds.size] retain];

//	backgroundImage = [[UIImage gradientImageWithStartColor:[UIColor colorWithRed:0.83 green:0.83 blue:0.83 alpha:1.000] endColor:[UIColor colorWithRed:0.647 green:0.647 blue:0.647 alpha:1.000] topLineColor:[UIColor colorWithRed:0.93 green:0.93 blue:0.93 alpha:1.000] size:self.bounds.size] retain];
	backgroundImage = [[UIImage gradientImageWithStartColor:[UIColor colorWithRed:0.63 green:0.63 blue:0.63 alpha:1.000] endColor:[UIColor colorWithRed:0.447 green:0.447 blue:0.447 alpha:1.000] topLineColor:[[UIColor colorWithRed:0.63 green:0.63 blue:0.63 alpha:1.000] lightened] size:self.bounds.size] retain];

//	backgroundImage = [[UIImage gradientImageWithStartColor:[UIColor colorWithRed:0.306 green:0.523 blue:0.682 alpha:1.000] endColor:[UIColor colorWithRed:0.193 green:0.354 blue:0.560 alpha:1.000] topLineColor:[UIColor colorWithRed:0.306 green:0.523 blue:0.682 alpha:0.9] size:self.bounds.size] retain];

//	backgroundImage = [[UIImage gradientImageWithStartColor:[UIColor colorWithRed:0.193 green:0.354 blue:0.560 alpha:1.000] endColor:[UIColor colorWithRed:0.306 green:0.523 blue:0.682 alpha:1.000] topLineColor:[UIColor colorWithWhite:1.0 alpha:0.25] size:self.bounds.size] retain];
	
	
//	backgroundImage = [[UIImage gradientImageWithStartColor:[[UIColor coolDarkGrayColor] lightened] endColor:[[UIColor coolDarkGrayColor] darkened] topLineColor:[[[UIColor coolDarkGrayColor] lightened] lightened] size:self.bounds.size] retain];
//	backgroundImage = [[UIImage gradientImageWithStartColor:[[[UIColor slateBlueColor] lightened] lightened] endColor:[[UIColor slateBlueColor] lightened] topLineColor:[[UIColor  slateBlueColor] lightened] size:self.bounds.size] retain];

//	backgroundImage = [[UIImage gradientImageWithStartColor:[UIColor colorWithRed:0.932 green:0.953 blue:0.977 alpha:1.000] endColor:[UIColor colorWithRed:0.932 green:0.953 blue:0.977 alpha:1.000] topLineColor:[UIColor colorWithWhite:1.0 alpha:1.0] size:self.bounds.size] retain];
	
	//backgroundImage = [[UIImage gradientImageWithStartColor:[UIColor colorWithRed:0.193 green:0.354 blue:0.560 alpha:1.000] endColor:[UIColor colorWithRed:0.306 green:0.523 blue:0.682 alpha:1.000] topLineColor:[UIColor colorWithRed:0.193 green:0.354 blue:0.560 alpha:0.9] size:self.bounds.size] retain];
//	backgroundImage = [[UIImage grayBackgroundGradientImageWithStartGray:0.975 endGray:0.97 topLineGray:1.0 size:self.bounds.size] retain];
	return backgroundImage;			
}


- (UIImage *)greenBackgroundImage {
	static UIImage *backgroundImage = nil;
	if (backgroundImage)
		return backgroundImage;
	backgroundImage = [[UIImage grayBackgroundGradientImageWithStartGray:0.968 endGray:0.96 topLineGray:1.0 size:self.bounds.size] retain];
//	backgroundImage = [[UIImage gradientImageWithStartColor:[[UIColor colorWithRed:0.235 green:0.302 blue:0.378 alpha:1.000] lightened] endColor:[UIColor colorWithRed:0.235 green:0.302 blue:0.378 alpha:1.000] topLineColor:[UIColor colorWithRed:0.235 green:0.302 blue:0.378 alpha:1.000] size:self.bounds.size] retain];
	return backgroundImage;			
}


- (UIImage *)orangeBackgroundImage {
	return [self greenBackgroundImage];
	static UIImage *backgroundImage = nil;
	if (backgroundImage)
		return backgroundImage;
	backgroundImage = [[UIImage gradientImageWithStartColor:[[UIColor colorWithWhite:0.678 alpha:1.000] lightened] endColor:[UIColor colorWithWhite:0.678 alpha:1.000] topLineColor:[UIColor colorWithWhite:0.678 alpha:0.75] size:self.bounds.size] retain];
	return backgroundImage;			
}


- (UIImage *)settingsRowBackgroundImage {
//	return [self folderBackgroundImage];
	static UIImage *backgroundImage = nil;
	if (backgroundImage)
		return backgroundImage;
//	backgroundImage = [[UIImage gradientImageWithStartColor:[[UIColor coolDarkGrayColor] lightened] endColor:[UIColor coolDarkGrayColor] topLineColor:[[[UIColor coolDarkGrayColor] lightened] lightened] size:self.bounds.size] retain];
//	backgroundImage = [[UIImage gradientImageWithStartColor:[UIColor unreadCountBackgroundColor] endColor:[[UIColor unreadCountBackgroundColor] darkened] topLineColor:[[UIColor unreadCountBackgroundColor] lightened] size:self.bounds.size] retain];
	backgroundImage = [[UIImage grayBackgroundGradientImageWithStartGray:1.0 endGray:1.0 topLineGray:0.90 size:self.bounds.size] retain];
//	backgroundImage = [[UIImage gradientImageWithStartColor:[UIColor unreadCountBackgroundColor] endColor:[[UIColor unreadCountBackgroundColor] darkened] topLineColor:[[UIColor unreadCountBackgroundColor] lightened] size:self.bounds.size] retain];
	return backgroundImage;		
}

- (void)drawRect:(CGRect)r {
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect rBounds = CGRectIntegral(self.bounds);
	rBounds.size.width -= 8;
	NSUInteger leftMargin = 18;
	NSInteger indentationLevel = ((UITableViewCell *)_delegate).indentationLevel;
	NSInteger indentationWidth = ((UITableViewCell *)_delegate).indentationWidth;
	leftMargin += (indentationLevel * indentationWidth * 2);
	static const NSUInteger topMargin = 4;
	static const NSUInteger rightMargin = 8;
	static const NSUInteger imageSpaceWidth = 16;
	static const NSUInteger imageSpaceHeight = 16;
	static const NSUInteger imageRightMargin = 8;
	NSString *title = [_representedObject objectForKey:RSDataTitle];
	NNWProxy *nnwProxy = [_representedObject objectForKey:@"nnwProxy"];
	if (!title)
		title = nnwProxy.title;
	BOOL isStarredItems = [title isEqualToString:@"Starred Items"]; /*TODO: blech*/
	NSInteger rowType = [[_representedObject objectForKey:@"rowType"] integerValue];
	BOOL isSyntheticFeed = [_representedObject boolForKey:@"synthetic"];
	BOOL isFeed = rowType == NNWFeedItem;
	BOOL isFolder = rowType == NNWFolderItem;
	BOOL displayTitleAsFolder = isStarredItems || isSyntheticFeed || isFolder || rowType == NNWShowHideFeedsItem || rowType == NNWSettingsItem || rowType == NNWAboutNetNewsWireItem;
	BOOL settingsRow = rowType == NNWShowHideFeedsItem || rowType == NNWSettingsItem || rowType == NNWAboutNetNewsWireItem;
	UIImage *image = nil;
	BOOL scaleImage = YES;
	if (isFeed)
		image = [NNWFavicon imageForFeedWithGoogleID:nnwProxy.googleID];
	NSUInteger titleX = leftMargin;// + imageSpaceWidth + imageRightMargin;
	NSUInteger descriptionX = leftMargin + imageSpaceWidth + imageRightMargin;
	NSUInteger titleMaxHeight = 20;
	static const NSUInteger titleBottomMargin = 2;
//	static const NSUInteger descriptionBottomMargin = 5;
	NSUInteger maxTextAreaWidth = (CGRectGetMaxX(rBounds) - titleX) - rightMargin;
	UIFont *titleFont = nil;
	if (!titleFont)
		titleFont = [[UIFont boldSystemFontOfSize:14.0] retain];
	static UIFont *unreadCountFont = nil;
	if (!unreadCountFont)
		unreadCountFont = [[UIFont boldSystemFontOfSize:14.0] retain];
	static UIColor *textTextColorFeedNonHighlighted = nil;
	if (!textTextColorFeedNonHighlighted)
		textTextColorFeedNonHighlighted = [[UIColor colorWithWhite:0.35 alpha:1.0] retain];//[[UIColor slateBlueColor] retain];//[[UIColor colorWithWhite:0.25 alpha:1.0] retain];
	UIColor *titleTextColor = textTextColorFeedNonHighlighted;//[UIColor colorWithWhite:0.25 alpha:1.0];//[UIColor colorWithHexString:@"#3366CC"];//[UIColor colorWithWhite:0.5 alpha:1.0];//[UIColor colorWithHexString:@"#3366CC"];
	static UIColor *titleTextColorNonHighlighted = nil;
	if (!titleTextColorNonHighlighted)
		titleTextColorNonHighlighted = [[UIColor colorWithWhite:0.2 alpha:1.0] retain];//[[UIColor slateBlueColor] retain];//[[UIColor colorWithRed:0.230 green:0.302 blue:0.378 alpha:1.000] retain];//[[UIColor colorWithWhite:0.25 alpha:1.0] retain];
	if (displayTitleAsFolder)
		titleTextColor = titleTextColorNonHighlighted;
	if (isStarredItems /* isSyntheticFeed || isFolder || settingsRow*/) {
		static UIColor *titleColorSyntheticFeedNonHighlighted = nil;
		if (!titleColorSyntheticFeedNonHighlighted)
			titleColorSyntheticFeedNonHighlighted = [[UIColor colorWithWhite:1.0 alpha:0.99] retain];
		titleTextColor = titleColorSyntheticFeedNonHighlighted;
	}
//	if (isFolder) {
//		static UIColor *titleColorSyntheticFeedNonHighlighted = nil;
//		if (!titleColorSyntheticFeedNonHighlighted)
//			titleColorSyntheticFeedNonHighlighted = [[UIColor slateBlueColor] retain];//[[UIColor colorWithWhite:1.0 alpha:0.99] retain];
//		titleTextColor = titleColorSyntheticFeedNonHighlighted;
//	}
	static UIColor *descriptionTextColorNonHighlighted = nil;
	if (!descriptionTextColorNonHighlighted)
		descriptionTextColorNonHighlighted = [[UIColor slateBlueColor] retain];//[[UIColor colorWithHexString:@"#333333"] retain];
	UIColor *descriptionTextColor = descriptionTextColorNonHighlighted;
//	descriptionTextColor = [UIColor coolDarkGrayColor];
//	descriptionTextColor = [UIColor slateBlueColor];
	NSUInteger textAreaHeight = 0;
	CGFloat descriptionHeight = 16.0;
	if (displayTitleAsFolder) {
	//	titleTextColor = [UIColor whiteColor];
		titleFont = [UIFont boldSystemFontOfSize:18.0];		
	}
	if (_highlighted) {
		titleTextColor = [UIColor whiteColor];
		descriptionTextColor = [UIColor whiteColor];
	}
	
	if (!_highlighted && isFeed && !isStarredItems && !isSyntheticFeed) {
		//[[[UIColor unreadCountBackgroundColor] lightened] set];
		[[UIColor colorWithWhite:0.95 alpha:1.0] set];
		[[UIColor whiteColor] set];
		UIRectFill(r);
	}	

	/*Unread count geometry*/
	
	NSInteger unreadCount = 0;
//	if (isFeed || isFolder)
		unreadCount = nnwProxy.unreadCount;
//	if (isSyntheticFeed)
//		unreadCount = syntheticFeed.displayCount;
	NSInteger unreadCountWidth = 0;
	//UIFont *unreadCountFont = unreadCountFont;//[UIFont boldSystemFontOfSize:18.0];
	if (unreadCount > 0) {
		NSString *s = [NSString stringWithFormat:@"%d", unreadCount];
		int ctDigits = [s length];
		static const int paddingLeft = 0;
		static const int paddingRight = 0;
		static NSInteger spacePerDigit = -1;
		if (spacePerDigit < 0)
			spacePerDigit = [@"8" sizeWithFont:unreadCountFont constrainedToSize:CGSizeMake(30, 30) lineBreakMode:UILineBreakModeClip].width;
		unreadCountWidth = paddingLeft + (spacePerDigit * ctDigits) + paddingRight;
	}
	CGFloat xCount = (CGRectGetMaxX(rBounds) - 19) - unreadCountWidth;
	CGFloat yCount = topMargin + 8;
	if (isFolder || isSyntheticFeed)
		yCount = (CGRectGetHeight(rBounds) / 2) + 10;
	CGRect rCountBackground = CGRectMake(xCount, yCount, unreadCountWidth, 16);
	NSInteger xUnreadCount = CGRectGetMinX(rCountBackground) - 10;
	if (unreadCount < 1)
		xUnreadCount = CGRectGetMaxX(rBounds) - rightMargin;
	//if (!image)
		descriptionX = leftMargin;
	if (image && indentationLevel == 0)
		titleX += (imageSpaceWidth + 4);
	NSInteger maxTitleWidth = xUnreadCount - titleX;
	
	static NSInteger titleHeightFolder = 0;
	static NSInteger titleHeightFeed = 0;
	if (titleHeightFeed < 1 && isFeed) {
		CGSize titleSize = [@"X" sizeWithFont:titleFont constrainedToSize:CGSizeMake(maxTextAreaWidth, titleMaxHeight) lineBreakMode:UILineBreakModeClip];
		titleHeightFeed = titleSize.height;
	}
	if (titleHeightFolder < 1 && !isFeed) {
		CGSize titleSize = [@"X" sizeWithFont:titleFont constrainedToSize:CGSizeMake(maxTextAreaWidth, titleMaxHeight) lineBreakMode:UILineBreakModeClip];
		titleHeightFolder = titleSize.height;
	} 
//	CGFloat titleHeight = 0;//[NNWMainTableCellContentView _cachedHeightForText:title maxSize:CGSizeMake(maxTitleWidth, titleMaxHeight) boldFont:YES];
//	if (titleHeight < 1) {
//		CGSize titleSize = [title sizeWithFont:titleFont constrainedToSize:CGSizeMake(maxTextAreaWidth, titleMaxHeight) lineBreakMode:UILineBreakModeTailTruncation];
//		[NNWMainTableCellContentView _cacheHeightForText:title maxSize:CGSizeMake(maxTextAreaWidth, titleMaxHeight) boldFont:YES height:titleSize.height];
//		titleHeight = titleSize.height;
//	}
	NSInteger titleHeight = isFeed ? titleHeightFeed : titleHeightFolder;
	textAreaHeight = titleHeight + titleBottomMargin + descriptionHeight;
	NSUInteger margin = (rBounds.size.height - textAreaHeight) / 2;
	NSInteger folderExpandButtonWidth = 18;
	CGRect rTitle = CGRectIntegral(CGRectMake(titleX, margin, maxTitleWidth, titleHeight));
	if (displayTitleAsFolder) {
		if (settingsRow) {
			rTitle.origin.x = 12;
			rTitle.size.width = CGRectGetWidth(rBounds) - rTitle.origin.x;
		}
		if (!settingsRow) {
			rTitle.origin.x += (folderExpandButtonWidth + 1);
			rTitle.size.width -= folderExpandButtonWidth;
		}
		NSInteger cellHeight = rBounds.size.height;
		rTitle.origin.y = (cellHeight / 2) - (titleHeight / 2);
	}
	//CGRect rDescription = CGRectIntegral(CGRectMake(titleX, CGRectGetMaxY(rTitle) + titleBottomMargin, maxTextAreaWidth, descriptionHeight));

	static UIColor *unreadBackgroundColor = nil;
	if (!unreadBackgroundColor)
		unreadBackgroundColor = [[UIColor unreadCountBackgroundColor] retain];
	
	CGRect rDescription = rTitle;
	rDescription.origin.y = CGRectGetMaxY(rDescription) + titleBottomMargin;
	rDescription.origin.x = descriptionX;
	rDescription.size.width = (CGRectGetMaxX(rBounds) - descriptionX) - rightMargin;

	if (isFeed && !isSyntheticFeed) {

		//[[self folderBackgroundImage] drawInRect:self.bounds];
		NSDictionary *mostRecentItemDict = nil;
		if (nnwProxy)
			mostRecentItemDict = ((NNWFeedProxy *)nnwProxy).mostRecentItem;
		static UIFont *mostRecentItemFont = nil;
		if (!mostRecentItemFont)
			mostRecentItemFont = [[UIFont systemFontOfSize:13.0] retain];
		if (mostRecentItemDict) {
			NSString *mostRecentNewsItemTitle = [mostRecentItemDict objectForKey:RSDataPlainTextTitle];
			static NSInteger dateSpacePerCharacter = -1;
			static UIFont *mostRecentItemDateFont = nil;
			if (!mostRecentItemDateFont)
				mostRecentItemDateFont = [[UIFont systemFontOfSize:13.0] retain];
			if (dateSpacePerCharacter < 0)
				dateSpacePerCharacter = [@"3" sizeWithFont:mostRecentItemDateFont constrainedToSize:CGSizeMake(15, 30) lineBreakMode:UILineBreakModeClip].width;
			NSString *mostRecentItemDateString = [mostRecentItemDict objectForKey:@"displayDate"];
			if (!mostRecentItemDateString)
				mostRecentItemDateString = @"";
			NSInteger dateWidth = [NNWMainTableCellContentView cachedWidthForDateString:mostRecentItemDateString];
			if (dateWidth == NSNotFound) {
				dateWidth = [mostRecentItemDateString sizeWithFont:mostRecentItemDateFont constrainedToSize:CGSizeMake(220, 20) lineBreakMode:UILineBreakModeClip].width;
				[NNWMainTableCellContentView cacheWidth:dateWidth forDateString:mostRecentItemDateString];
			}
			CGRect rDate = rDescription;
			rDate.origin.x = CGRectGetMaxX(rDate) - dateWidth;
			rDate.size.width = dateWidth;
			if (_highlighted)
				[[UIColor whiteColor] set];
			else
				[descriptionTextColor set];
			rDescription.size.width = CGRectGetMinX(rDate) - CGRectGetMinX(rDescription);
			if (!RSStringIsEmpty(mostRecentNewsItemTitle))
				[mostRecentNewsItemTitle drawInRect:rDescription withFont:mostRecentItemFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
			
			static UIColor *dateColor = nil;
			if (!dateColor)
				dateColor = [[UIColor colorWithWhite:0.7 alpha:1.0] retain];

			if (_highlighted)
				[[UIColor whiteColor] set];
			else
				//[dateColor set];
				[[UIColor coolDarkGrayColor] set];
			[mostRecentItemDateString drawInRect:rDate withFont:mostRecentItemDateFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
			
			
		}
	}
	else {
		if (!_highlighted && (isFolder || settingsRow)) {
			[[self folderBackgroundImage] drawInRect:self.bounds];// blendMode:kCGBlendModeNormal alpha:0.55];
//			[[UIColor colorWithWhite:0.97 alpha:1.0] set];
//			UIRectFill(self.bounds);
		}
//			[[self starredItemsBackgroundImage] drawInRect:self.bounds];// blendMode:kCGBlendModeNormal alpha:0.15];
//			[[self folderBackgroundImage] drawInRect:self.bounds];
//		if (!_highlighted && settingsRow) {
////			[[UIColor colorWithWhite:0.96 alpha:1.0] set];
////			UIRectFill(self.bounds);
////			[[self starredItemsBackgroundImage] drawInRect:self.bounds];// blendMode:kCGBlendModeNormal alpha:0.15];
//			[[self orangeBackgroundImage] drawInRect:self.bounds];
//		}
		if (!_highlighted && isSyntheticFeed) {
			//[[self settingsRowBackgroundImage] drawInRect:self.bounds];
			if (isStarredItems)
				[[self starredItemsBackgroundImage] drawInRect:self.bounds];// blendMode:kCGBlendModeNormal alpha:0.15];
			else
				[[self greenBackgroundImage] drawInRect:self.bounds];
			//[[self settingsRowBackgroundImage] drawInRect:self.bounds];
			//[[self syntheticFeedBackgroundImage] drawInRect:self.bounds];
//			[[UIColor colorWithWhite:1.0 alpha:1.0] set];
//			UIRectFill(self.bounds);		
		}
	}

	if (image) {
//		CGContextSaveGState(context);
		NSInteger thumbnailY = rTitle.origin.y + 2;
		NSInteger imageIndentLevel = indentationLevel;
		if (imageIndentLevel > 0)
			imageIndentLevel--;
		NSInteger thumbnailX = leftMargin;// + (imageIndentLevel * (indentationWidth * 2));
		if (indentationLevel > 0)
			thumbnailX -= 20;
		CGRect rThumbnail = CGRectIntegral(CGRectMake(thumbnailX, thumbnailY, imageSpaceWidth, imageSpaceHeight));
		if (!scaleImage) {
			CGSize imageSize = image.size;
			thumbnailY = CGRectGetMidY(rBounds) - (imageSize.height / 2);
			rThumbnail = CGRectIntegral(CGRectMake(thumbnailX, thumbnailY, imageSize.width, imageSize.height));
		}
//		if (!_highlighted)
//			CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 1.0, [[UIColor colorWithWhite:0.5 alpha:0.5] CGColor]);
//		CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 1.0, [[UIColor colorWithWhite:1.0 alpha:0.95] CGColor]);
		[image drawInRect:rThumbnail blendMode:kCGBlendModeNormal alpha:1.0];
		//CGContextRestoreGState(context);
	}		

	if (isSyntheticFeed) {
		UIImage *syntheticFeedImage = [_representedObject objectForKey:@"image"];
		if (syntheticFeedImage) {
			CGRect rImage = CGRectZero;
			rImage.origin.x = 4;
			rImage.size.height = syntheticFeedImage.size.height;
			rImage.size.width = syntheticFeedImage.size.width;
			rImage.origin.x = (rTitle.origin.x / 2) - (rImage.size.width / 2);
			rImage.origin.y = (CGRectGetHeight(self.bounds) / 2) - (rImage.size.height / 2);
			rImage = CGRectIntegral(rImage);
			rImage.origin.y--;
			rImage.origin.x++;
			CGContextSaveGState(context);
			if (!_highlighted)
				CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 1.0, [[UIColor colorWithWhite:0.0 alpha:0.5] CGColor]);
			[syntheticFeedImage drawInRect:rImage];// blendMode:kCGBlendModeNormal alpha:1.0];
			CGContextRestoreGState(context);
		}			
	}
	
	if (unreadCount > 0) {		
		CGContextSaveGState(context);
		[unreadBackgroundColor set];
		if (_highlighted)
			[[UIColor whiteColor] set];
//		if (!_highlighted && isFolder)
//			CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 2.0, [[UIColor colorWithWhite:0.25 alpha:0.25] CGColor]);
		CGContextSetLineWidth(context, 20);
		CGContextSetLineCap(context, kCGLineCapRound);
		CGContextMoveToPoint(context, rCountBackground.origin.x, (int)((rCountBackground.origin.y + rCountBackground.size.height) / 2));
		CGContextAddLineToPoint(context, (rCountBackground.origin.x + rCountBackground.size.width), (int)((rCountBackground.origin.y + rCountBackground.size.height) / 2));
		CGContextStrokePath(context);
		CGContextRestoreGState(context);
		
		//CGContextSaveGState(context);
		[[UIColor whiteColor] set];
		if (_highlighted)
			[unreadBackgroundColor set];
		if (isFolder || isSyntheticFeed)
			rCountBackground.origin.y -= 12;
		rCountBackground.origin.y -= 7;
		//rCountBackground.origin.x += 0;
//		if (!_highlighted)
//			CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 1.0, [[UIColor colorWithWhite:0.55 alpha:0.5] CGColor]);

		[[NSString stringWithFormat:@"%d", unreadCount] drawInRect:rCountBackground withFont:unreadCountFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];
	//	CGContextRestoreGState(context);
		
		//	[[UIColor redColor] set];
		//	UIRectFill(rCountBackground);
	}

	//CGContextSaveGState(context);
	//	if (!_highlighted && isFeed)
	//		CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, -1), 1.0, [[UIColor colorWithWhite:1.0 alpha:0.55] CGColor]);
//	if (!_highlighted && !isFeed)
//		CGContextSetShadowWithColor(context, CGSizeMake(0, -1), 1.0, [[UIColor colorWithWhite:1.0 alpha:0.98] CGColor]);
	//	if (settingsRow) {
	//		titleTextColor = [UIColor colorWithWhite:0.0 alpha:0.5];
	//		if (!_highlighted)
	//			CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, -1), 1.0, [[UIColor colorWithWhite:0.0 alpha:0.95] CGColor]);
	//	}
	[titleTextColor set];
	//[[UIColor slateBlueColor] set];
//	if (!isFeed)
//		[[UIColor colorWithWhite:0.9 alpha:0.9] set];
//	if (isFolder || settingsRow || (isSyntheticFeed && !isStarredItems))
//		CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, -1), 1.0, [[UIColor colorWithWhite:0.3 alpha:0.15] CGColor]);		
	[title drawInRect:rTitle withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
	//CGContextRestoreGState(context);

	
	//CGContextRelease(context);
}


@end


#pragma mark -

@implementation NNWMainTableViewCell

#pragma mark Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		CGRect r = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width, self.contentView.bounds.size.height);
		_cellView = [[NNWMainTableCellContentView alloc] initWithFrame:r];
		_cellView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		_cellView.delegate = self;
		_cellView.contentMode = UIViewContentModeRedraw;
		//_cellView.backgroundColor = [UIColor whiteColor];
		[self.contentView addSubview:_cellView];
		if ([reuseIdentifier hasSuffix:@"-alt"])
			_cellView.isAlternate = YES;
		self.clipsToBounds = YES;
		self.contentMode = UIViewContentModeRedraw;
		//self.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[_cellView removeFromSuperview];
	[_cellView release];
	[super dealloc];
}


#pragma mark Accessors

- (void)setIsAlternate:(BOOL)flag {
	_cellView.isAlternate = flag;
}


- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	[_cellView setNeedsDisplay];
}


//- (void)setManagedObject:(NSManagedObject *)obj {
//	_cellView.managedObject = obj;
//	[self setNeedsDisplay];
//}


- (void)setRepresentedObject:(NSDictionary *)dict {
	_cellView.representedObject = dict;
	[self setNeedsDisplay];
	[_cellView setNeedsLayout];
}


- (void)setIndentationLevel:(NSInteger)indentationLevel {
	[super setIndentationLevel:indentationLevel];
	_cellView.indentationLevel = indentationLevel;
	[self setNeedsDisplay];
}


- (void)setIndentationWidth:(CGFloat)w {
	[super setIndentationWidth:w];
	_cellView.indentationWidth = w;
	[self setNeedsDisplay];
}


- (void)setMainViewController:(NNWMainViewController *)mainViewController {
	_cellView.mainViewController = mainViewController;
}


- (void)setCollapsed:(BOOL)collapsed {
	_cellView.collapsed = collapsed;
	[_cellView setNeedsLayout];
	[self setNeedsDisplay];
}


- (BOOL)isOpaque {
	return YES;
}


@end
