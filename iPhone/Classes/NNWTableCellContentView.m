//
//  BCFastCellView.m
//  bobcat
//
//  Created by Brent Simmons on 3/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWTableCellContentView.h"
#import "BCDownloadRequest.h"
#import "NNWFeedProxy.h"
#import "NNWMainViewController.h"
#import "NNWNewsItem.h"
#import "RSCache.h"
#import "RSGoogleFeedParser.h"


static RSCache *gTextHeightCache = nil;

@implementation NNWTableCellContentView


@synthesize newsItemProxy = _newsItemProxy, highlighted = _highlighted, isAlternate = _isAlternate;


#pragma mark Class Methods

+ (void)initialize {
#if THUMBNAILS
	if (!gCachedThumbnails)
		gCachedThumbnails = [[RSCache cache] retain];
#endif
	if (!gTextHeightCache)
		gTextHeightCache = [[RSCache cache] retain];
	static BOOL didRegisterForNotifications = NO;
	if (!didRegisterForNotifications) {
		didRegisterForNotifications = YES;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleMainViewControllerWillAppear:) name:NNWMainViewControllerWillAppearNotification object:nil];
	}
}


+ (void)_handleMainViewControllerWillAppear:(NSNotification *)note {
#if THUMBNAILS
	[gCachedThumbnails emptyCache];
#endif
	[gTextHeightCache emptyCache];
}


#pragma mark Init

- (id)initWithFrame:(CGRect)frame {	
	if (self = [super initWithFrame:frame]) {
		self.opaque = YES;
		self.backgroundColor = [UIColor whiteColor];
		self.clipsToBounds = YES;
#if THUMBNAILS
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_handleImageDownloaded:) name:BCDownloadDidCompleteNotification object:nil];
#endif
	}
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
#if THUMBNAILS
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
	[_newsItemProxy release];
	[super dealloc];
}


#pragma mark Accessors

- (void)setNewsItem:(NNWNewsItemProxy *)newsItemProxy {
	if (newsItemProxy == _newsItemProxy)
		return;
	[_newsItemProxy release];
	_newsItemProxy = [newsItemProxy retain];
	[self setNeedsDisplay];
}


- (void)setHighlighted:(BOOL)flag {
	if (_highlighted == flag)
		return;
	_highlighted = flag;	
	[self setNeedsDisplay];
}


- (void)setIsAlternate:(BOOL)flag {
	if (_isAlternate == flag)
		return;
	_isAlternate = flag;
	[self setNeedsDisplay];
}

#pragma mark -
#pragma mark Thumbnails

#if THUMBNAILS

- (void)_downloadThumbnail {
	BCDownloadRequest *downloadRequest = [[[BCDownloadRequest alloc] initWithURL:[NSURL URLWithString:self.newsItemProxy.thumbnailURLString]] autorelease];
	downloadRequest.responseTransformer = [[[BCDownloadThumbnailTransformer alloc] init] autorelease];
	downloadRequest.downloadPriority = BCDownloadImmediately;
	downloadRequest.downloadType = BCDownloadTypeThumbnail;
	[downloadRequest addToDownloadQueue];
}


+ (UIImage *)_cachedThumbnail:(NSString *)urlString {
	return [gCachedThumbnails cachedObjectForKey:urlString];
}


+ (void)_cacheThumbnail:(UIImage *)image urlString:(NSString *)urlString {
	if (RSStringIsEmpty(urlString))
		return;
	[gCachedThumbnails cacheObject:image key:urlString];
}


//- (UIImage *)_imageWithFilename:(NSString *)filename {
//	NSString *imagePath = [[NSBundle mainBundle] pathForResource:[filename stringByDeletingPathExtension] ofType:[filename pathExtension]];
//	return [UIImage imageWithContentsOfFile:imagePath];
//}


- (NSString *)_resourceImageNameForURLString:(NSString *)urlString {
	return nil;	
}


+ (UIImage *)_noThumbnailImage {
	static UIImage *noThumbnailImage = nil;
	if (!noThumbnailImage) {
		CGRect r = CGRectMake(0, 0, 90, 90);
		UIGraphicsBeginImageContext(CGSizeMake(r.size.width, r.size.height));
		CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
		CGGradientRef myGradient;
		CGColorSpaceRef myColorspace;
		size_t num_locations = 3;
		CGFloat locations[3] = {0.0, 0.75, 1.0};
		CGFloat startGray = 0.97;
		CGFloat middleGray = 0.96;
		CGFloat endGray = 0.95;
		CGFloat components[12] = {startGray, startGray, startGray, 1.0, middleGray, middleGray, middleGray, 1.0, endGray, endGray, endGray, 1.0 };
		
		myColorspace = CGColorSpaceCreateDeviceRGB();
		myGradient = CGGradientCreateWithColorComponents(myColorspace, components, locations, num_locations);
		CGPoint myStartPoint, myEndPoint;
		myStartPoint.x = 0.0;
		myStartPoint.y = 0.0;
		myEndPoint.x = 0.0;
		myEndPoint.y = CGRectGetMaxY(r);
		CGContextDrawLinearGradient(UIGraphicsGetCurrentContext(), myGradient, myStartPoint, myEndPoint, 0);
		CGColorSpaceRelease(myColorspace);
		CGGradientRelease(myGradient);
		
//	//	NSString *defaultLogoImageName = [[BCConfigData sharedData] stringWithName:@"NewsItemList_DefaultThumbnailName" tab:nil];
////		if (!RSStringIsEmpty(defaultLogoImageName)) {
//			UIImage *defaultLogoImage = [UIImage imageNamed:@"Icon.png"];
//			if (defaultLogoImage)
//				[defaultLogoImage drawInRect:r blendMode:kCGBlendModePlusDarker alpha:0.1];
////		}
		UIImage *squareImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		CGContextRelease(context);
		noThumbnailImage = [[UIImage imageInRoundRect:squareImage size:squareImage.size radius:5 frameColor:nil] retain];
	}
	return noThumbnailImage;	
}


- (UIImage *)_defaultThumbnailImage {
	return [NNWTableCellContentView _noThumbnailImage];
}


- (UIImage *)_thumbnailImage {
	NSString *thumbnailURLString = self.newsItemProxy.thumbnailURLString;
	if (RSStringIsEmpty(thumbnailURLString)) {
		UIImage *favicon = [NNWFavicon imageForFeedWithGoogleID:self.newsItemProxy.googleFeedID];
		if (favicon)
			return favicon;
	}
	if (RSStringIsEmpty(thumbnailURLString))
		return [self _defaultThumbnailImage];
	UIImage *cachedThumbnailImage = [NNWTableCellContentView _cachedThumbnail:thumbnailURLString];
	if (cachedThumbnailImage)
		return cachedThumbnailImage;
	UIImage *rawThumbnail = nil;//[self _resourceImageForURLString:thumbnailURLString];
//	if (!rawThumbnail)
//		rawThumbnail = _newsItem.thumbnailImage;
	if (!rawThumbnail) {
		[self _downloadThumbnail];
		return [self _defaultThumbnailImage];
	}
	if (rawThumbnail && !CGSizeEqualToSize(rawThumbnail.size, CGSizeMake(90, 90)))
		rawThumbnail = [UIImage scaledImage:rawThumbnail toSize:CGSizeMake(90, 90)];
//	if (_newsViewController.rawThumbnails)
//		return rawThumbnail;
//	UIImage *roundedThumbnail = [UIImage imageInRoundRect:rawThumbnail size:CGSizeMake(90, 90) radius:5 frameColor:nil];
//	if (!roundedThumbnail)
//		roundedThumbnail = rawThumbnail; /*Should never happen, but at least we have something to show*/
	[NNWTableCellContentView _cacheThumbnail:rawThumbnail urlString:thumbnailURLString];
	return rawThumbnail;
}

	
- (void)_handleImageDownloaded:(NSNotification *)note {
	BCDownloadRequest *downloadRequest = [note object];
	NSString *urlString = [downloadRequest.url absoluteString];
	if (!urlString || ![urlString isEqualToString:self.newsItemProxy.thumbnailURLString])
		return;
	[NNWTableCellContentView _cacheThumbnail:downloadRequest.transformedResponse urlString:self.newsItemProxy.thumbnailURLString];
	[self setNeedsDisplay];
}


#endif

#pragma mark -
#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
}


- (UIImage *)_alternateRowGradientImage {
	CGFloat gradientStartColorGray = 0.92;
	CGFloat gradientEndColorGray = 0.89;
	CGFloat gradientTopLineColorGray = 1.0;
	static UIImage *alternateRowGradientImage = nil;
	CGSize gradientSize = self.bounds.size;
	if (!alternateRowGradientImage)
		alternateRowGradientImage = [[UIImage grayBackgroundGradientImageWithStartGray:gradientStartColorGray endGray:gradientEndColorGray topLineGray:gradientTopLineColorGray size:gradientSize] retain];
	return alternateRowGradientImage;
}


- (UIImage *)_rowGradientImage {
//	if (_isAlternate)
//		return [self _alternateRowGradientImage];
	CGFloat gradientStartColorGray = 0.99;
	CGFloat gradientEndColorGray = 0.97;
	CGFloat gradientTopLineColorGray = 1.0;
	static UIImage *rowGradientImage = nil;
	CGSize gradientSize = self.bounds.size;
	if (!rowGradientImage)
		rowGradientImage = [[UIImage grayBackgroundGradientImageWithStartGray:gradientStartColorGray endGray:gradientEndColorGray topLineGray:gradientTopLineColorGray size:gradientSize] retain];
	return rowGradientImage;
}


+ (CGFloat)_cachedHeightForText:(NSString *)s maxSize:(CGSize)maxSize boldFont:(BOOL)boldFont {
	NSString *key = [NSString stringWithFormat:@"%@%f%f%d", s, maxSize.width, maxSize.height, boldFont];
	return (CGFloat)[[gTextHeightCache cachedObjectForKey:key] floatValue];
}


+ (void)_cacheHeightForText:(NSString *)s maxSize:(CGSize)maxSize boldFont:(BOOL)boldFont height:(CGFloat)height {
	NSString *key = [NSString stringWithFormat:@"%@%f%f%d", s, maxSize.width, maxSize.height, boldFont];
	[gTextHeightCache cacheObject:[NSNumber numberWithFloat:(float)height] key:key];
}


- (void)drawRect:(CGRect)rect {

	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
	self.clipsToBounds = YES;
	
	static const NSUInteger leftMargin = 18;
	static const NSUInteger rightMargin = 12;//8;
	//static const NSUInteger bottomMargin = 4;
	static const NSUInteger imageSpaceWidth = 90;
#if THUMBNAILS
	static const NSUInteger topMargin = 4;
	static const NSUInteger imageSpaceHeight = 90;
#endif
	static const NSUInteger imageRightMargin = 8;
	NSUInteger titleX = leftMargin + imageSpaceWidth + imageRightMargin;
	NSUInteger titleMaxHeight = 50;
	static const NSUInteger titleBottomMargin = 2;
	static const NSUInteger descriptionBottomMargin = 5;
	static const NSUInteger dateMaxHeight = 14;
	UIColor *titleTextColor = [UIColor blackColor];
	UIColor *descriptionTextColor = [UIColor blackColor];
	UIColor *dateTextColor = [UIColor blackColor];
	CGRect rBounds = CGRectIntegral(self.bounds);
	static const NSUInteger movieIndicatorWidth = 24;
	NSUInteger maxTextAreaWidth = (CGRectGetMaxX(rBounds) - titleX) - rightMargin;
//	BOOL newsItemHasMovieEnclosure = self.newsItemProxy.movieURLString != nil;
//	BOOL newsItemHasAudioEnclosure = self.newsItemProxy.audioURLString != nil;
	NSString *feedName = self.newsItemProxy.googleFeedTitle;
	UIImage *favicon = [NNWFavicon imageForFeedWithGoogleID:self.newsItemProxy.googleFeedID];
	BOOL indicateGoesToMovie = NO;//newsItemHasMovieEnclosure;
	BOOL indicateGoesToAudio = NO;//newsItemHasAudioEnclosure;
//	BOOL indicateGoesToMovie = newsItemHasMovieEnclosure && !_newsViewController.showArticleEvenIfEnclosure;
//	BOOL indicateArticleHasMovie = newsItemHasMovieEnclosure && _newsViewController.showArticleEvenIfEnclosure;
	NSUInteger maxLines = 3;
	NSUInteger titleLines = 0;
	NSUInteger descriptionLines = 0;
	CGFloat lineHeight = 16.0f;
	static UIFont *titleFont = nil;
	static UIFont *descriptionFont = nil;
	static UIFont *dateFont = nil;
	static UIFont *feedNameFont = nil;
	NSUInteger textAreaHeight = 0;
	NSUInteger dateHeight = 0;
	NSUInteger dateWidth = 0;
	static NSUInteger dateHeightWhenShowing = 0;
	static NSUInteger dateWidthWhenShowing = 0;
	static const NSInteger rightArrowSectionWidth = 18;
	BOOL showRightArrow = !indicateGoesToMovie && !indicateGoesToAudio;
#if THUMBNAILS
	NSString *thumbnailURLString = self.newsItemProxy.thumbnailURLString;
	if (thumbnailURLString && !NNWImageURLStringIsGoodAsThumbnail(thumbnailURLString))
		thumbnailURLString = nil;
	BOOL newsItemShouldHaveThumbnail = !RSStringIsEmpty(thumbnailURLString);
#endif
	BOOL newsItemShouldHaveThumbnail = NO;
	if (!newsItemShouldHaveThumbnail) {
		titleX = leftMargin + 8;
		maxTextAreaWidth = (CGRectGetMaxX(rBounds) - titleX) - rightMargin;
	}
	if (showRightArrow)
		maxTextAreaWidth -= rightArrowSectionWidth;
	if (indicateGoesToMovie || indicateGoesToAudio)
		maxTextAreaWidth -= movieIndicatorWidth;
	
	if (!titleFont)
		titleFont = [[UIFont boldSystemFontOfSize:15.0] retain];
	titleMaxHeight = MIN((15.0 * 2) + 5 * 2, rBounds.size.height);
	if (!descriptionFont)
		descriptionFont = [[UIFont systemFontOfSize:14.0] retain];
	if (!dateFont)
		dateFont = [[UIFont systemFontOfSize:11.0] retain];
	if (!feedNameFont)
		feedNameFont = [[UIFont boldSystemFontOfSize:11.0] retain];
	NSString *dateText = self.newsItemProxy.displayDate;
//	if (RSStringIsEmpty(dateText))
//		maxLines++;
	
	if (_highlighted) {
		titleTextColor = [UIColor whiteColor];
		descriptionTextColor = [UIColor whiteColor];
		dateTextColor = [UIColor whiteColor];
	}
	else {
		static UIColor *titleTextColorRead = nil;
		if (!titleTextColorRead)
			titleTextColorRead = [[UIColor coolDarkGrayColor] retain];
		static UIColor *titleTextColorUnread = nil;
		if (!titleTextColorUnread)
			titleTextColorUnread = [[UIColor colorWithHexString:@"#3366CC"] retain];//[[UIColor slateBlueColor] retain];//[[UIColor colorWithRed:0.062 green:0.387 blue:0.968 alpha:1.000] retain];//[[UIColor veryBrightBlueColor] retain];//[[UIColor slateBlueColor] retain];//[[UIColor colorWithHexString:@"#5B85D1"] retain];//[[UIColor colorWithHexString:@"#336699"] retain];
			
		titleTextColor = self.newsItemProxy.read ? titleTextColorRead : titleTextColorUnread;
		static UIColor *descriptionTextColorNonHighlighted = nil;
		if (!descriptionTextColorNonHighlighted)
			descriptionTextColorNonHighlighted = [[UIColor coolDarkGrayColor] retain];//[[UIColor colorWithHexString:@"#666666"]retain];//[[UIColor colorWithWhite:0.1 alpha:1.0] retain];//[[UIColor colorWithHexString:@"#333333"] retain];
		descriptionTextColor = descriptionTextColorNonHighlighted;
		static UIColor *dateTextColorNonHighlighted = nil;
		if (!dateTextColorNonHighlighted)
			//dateTextColorNonHighlighted = [[UIColor colorWithRed:0.861 green:0.555 blue:0.184 alpha:1.000] retain];
			//dateTextColorNonHighlighted = [[UIColor coolDarkGrayColor] retain];
			//dateTextColorNonHighlighted = [[UIColor colorWithHexString:@"#3e9430"] retain];
			dateTextColorNonHighlighted = [[UIColor slateBlueColor] retain];
		dateTextColor = dateTextColorNonHighlighted;
	}
	
	if (!_highlighted) {
		[[UIColor whiteColor] set];
		UIRectFill(rect);		
	}
	
	NSString *title = self.newsItemProxy.plainTextTitle;
	CGFloat titleHeight = [NNWTableCellContentView _cachedHeightForText:title maxSize:CGSizeMake(maxTextAreaWidth, titleMaxHeight) boldFont:YES];
	if (titleHeight < 1) {
		CGSize titleSize = [title sizeWithFont:titleFont constrainedToSize:CGSizeMake(maxTextAreaWidth, titleMaxHeight) lineBreakMode:UILineBreakModeTailTruncation];
		[NNWTableCellContentView _cacheHeightForText:title maxSize:CGSizeMake(maxTextAreaWidth, titleMaxHeight) boldFont:YES height:titleSize.height];
		titleHeight = titleSize.height;
	}
	titleLines = (NSUInteger)(titleHeight / lineHeight);
	descriptionLines = maxLines - titleLines;
	
	NSString *description = self.newsItemProxy.preview;
	CGFloat descriptionHeight = 16.0;
	if (RSStringIsEmpty(description)) {
		description = @"";
		descriptionHeight = 0.0f;
		descriptionLines = 0;
	}
	CGSize maxDescriptionSize = CGSizeMake(maxTextAreaWidth, (descriptionLines * lineHeight) + 2);
	if (descriptionLines > 1) {
		descriptionHeight = [NNWTableCellContentView _cachedHeightForText:description maxSize:maxDescriptionSize boldFont:NO];
		if (descriptionHeight < 1) {
			CGSize descriptionSize = [description sizeWithFont:descriptionFont constrainedToSize:CGSizeMake(maxTextAreaWidth, (descriptionLines * lineHeight) + 2) lineBreakMode:UILineBreakModeTailTruncation];
			descriptionHeight = descriptionSize.height;
			[NNWTableCellContentView _cacheHeightForText:description maxSize:maxDescriptionSize boldFont:NO height:descriptionHeight];
		}
	}

	if (dateHeightWhenShowing < 1) {
		CGSize dateSize = [@"Septemberx 33, 2009 88:88:88 PM" sizeWithFont:dateFont constrainedToSize:CGSizeMake(maxTextAreaWidth, dateMaxHeight) lineBreakMode:UILineBreakModeTailTruncation];
		dateHeightWhenShowing = dateSize.height;
		dateWidthWhenShowing = dateSize.width;
	}
	if (!RSStringIsEmpty(dateText)) {
		dateWidth = dateWidthWhenShowing;
		dateHeight = dateHeightWhenShowing;
	}
	CGSize displayDateSize = [dateText sizeWithFont:dateFont constrainedToSize:CGSizeMake(dateWidthWhenShowing, dateHeightWhenShowing) lineBreakMode:UILineBreakModeClip];
	
	textAreaHeight = titleHeight + titleBottomMargin + descriptionHeight;
	if (dateHeight > 0)
		textAreaHeight += descriptionBottomMargin + dateHeight;
	NSUInteger margin = (rBounds.size.height - textAreaHeight) / 2;
	CGRect rTitle = CGRectIntegral(CGRectMake(titleX, margin, maxTextAreaWidth, titleHeight));
	CGRect rDescription = CGRectIntegral(CGRectMake(titleX, CGRectGetMaxY(rTitle) + titleBottomMargin, maxTextAreaWidth, descriptionHeight));
	CGRect rDate = CGRectIntegral(CGRectMake((CGRectGetMaxX(rBounds) - 8) - displayDateSize.width, CGRectGetMaxY(rDescription) + descriptionBottomMargin, displayDateSize.width, displayDateSize.height));
	if (showRightArrow)
		rDate.origin.x = (CGRectGetMaxX(rTitle) - 1) - displayDateSize.width;
//		CGRect rFavicon = CGRectMake((CGRectGetMinX(rTitle) / 2) - 8, CGRectGetMaxY(rDate) - 19, 16, 16);
	CGRect rFavicon = CGRectMake(titleX, CGRectGetMaxY(rDate) - 16, 16, 16);
//	rFavicon = CGRectMake(0, 0, 16, 16);
	CGContextSaveGState(context);
	if (!_highlighted)
		CGContextSetShadowWithColor(UIGraphicsGetCurrentContext(), CGSizeMake(0, -1), 1.0, [[UIColor colorWithWhite:1.0 alpha:0.95] CGColor]);
	[titleTextColor set];
	[title drawInRect:rTitle withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
	CGContextRestoreGState(context);

	
	[descriptionTextColor set];
	[description drawInRect:rDescription withFont:descriptionFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
	[dateTextColor set];
	if (dateHeight > 0)
		[dateText drawInRect:rDate withFont:dateFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentRight];
	CGRect rFeedName = CGRectIntegral(CGRectMake(titleX, rDate.origin.y, (CGRectGetMinX(rDate) - 4) - titleX, dateHeight));
	if (favicon)
		rFeedName = CGRectIntegral(CGRectMake(titleX + 20, rDate.origin.y, ((CGRectGetMinX(rDate) - 4) - titleX) - 20, dateHeight));
	static UIColor *feedNameColorNonHighlighted = nil;
	if (!feedNameColorNonHighlighted)
		feedNameColorNonHighlighted = [[UIColor slateBlueColor] retain];//[[UIColor colorWithWhite:0.35 alpha:1.0] retain];
	UIColor *feedNameColor = _highlighted ? [UIColor whiteColor] : feedNameColorNonHighlighted;
	[feedNameColor set];
	[feedName drawInRect:rFeedName withFont:feedNameFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
	
	
	
	if (self.newsItemProxy.starred) {
		[[UIImage imageNamed:@"stargray.png"] drawInRect:CGRectMake((rTitle.origin.x / 2) - 8, rTitle.origin.y + 2, 16, 16) blendMode:kCGBlendModeNormal alpha:1];
		//[[UIImage imageNamed:@"star_table4.png"] drawInRect:CGRectMake((rTitle.origin.x / 2) - 8, rTitle.origin.y + 2, 16, 16) blendMode:kCGBlendModeNormal alpha:1];
	}
	if (showRightArrow) {
		static UIImage *rightArrow = nil;
		if (!rightArrow)
			rightArrow = [[UIImage imageNamed:@"chevron-single-right.png"] retain];
		static CGFloat imageHeight = 0;
		static CGFloat imageWidth = 0;
		if (imageHeight < 1 || imageWidth < 1) {
			imageHeight = rightArrow.size.height;
			imageWidth = rightArrow.size.width;
		}
		CGRect rArrow = CGRectMake(CGRectGetMaxX(rBounds) - rightArrowSectionWidth, (CGRectGetHeight(rBounds) / 2) - (imageHeight / 2), imageWidth, imageHeight);
		[rightArrow drawInRect:CGRectIntegral(rArrow) blendMode:kCGBlendModeNormal alpha:1.0];
	}
	
	if (favicon) {
		[favicon drawInRect:CGRectIntegral(rFavicon) blendMode:kCGBlendModeNormal alpha:1.0];
	}
	
	if (indicateGoesToMovie || indicateGoesToAudio) {
		UIImage *videoImage = [UIImage imageNamed:@"video_20.png"];
		static CGFloat videoImageHeight = 0;
		static CGFloat videoImageWidth = 0;
		if (videoImageHeight < 1 || videoImageWidth < 1) {
			videoImageHeight = videoImage.size.height;			
			videoImageWidth = videoImage.size.width;			
		}
		CGRect rVideo = CGRectMake(CGRectGetMaxX(rTitle) + 4, (CGRectGetHeight(rBounds) / 2) - (videoImageHeight / 2), videoImageWidth, videoImageHeight);
		[videoImage drawInRect:CGRectIntegral(rVideo) blendMode:kCGBlendModeNormal alpha:1.0];
	}
	
#if THUMBNAILS
	if (newsItemShouldHaveThumbnail) {
		UIImage *thumbnailImage = [self _thumbnailImage];
		if (thumbnailImage) {
			CGRect rThumbnail = CGRectIntegral(CGRectMake(leftMargin, topMargin, imageSpaceWidth, imageSpaceHeight));
			if (!_highlighted)
				CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 1.0, [[UIColor colorWithWhite:0.5 alpha:0.5] CGColor]);
			[thumbnailImage drawInRect:rThumbnail blendMode:kCGBlendModeNormal alpha:1.0];
		}		
	}
#endif
	
	CGContextRelease(context);
}


@end
