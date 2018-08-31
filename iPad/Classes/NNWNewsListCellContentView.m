//
//  BCFastCellView.m
//  bobcat
//
//  Created by Brent Simmons on 3/30/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWNewsListCellContentView.h"
#import "NNWAppDelegate.h"
#import "NNWFavicon.h"
#import "NNWFeedProxy.h"
#import "NNWMainViewController.h"
#import "NNWNewsItemProxy.h"
#import "NNWNewsListTableController.h"



@interface NNWNewsListCellContentView ()
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, assign) BOOL shouldAnimateThumbnail;
@property (nonatomic, assign) BOOL animatingThumbnail;
@end

@implementation NNWNewsListCellContentView


@synthesize newsItemProxy = _newsItemProxy, highlighted = _highlighted, selected = _selected, isAlternate = _isAlternate;
@synthesize tableController;
@synthesize imageView, shouldAnimateThumbnail, animatingThumbnail;


#pragma mark Init

- (id)initWithFrame:(CGRect)frame {	
	if (self = [super initWithFrame:frame]) {
		self.opaque = YES;
		self.backgroundColor = [UIColor whiteColor];
		self.clipsToBounds = YES;
	}
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[_newsItemProxy release];
	[imageView release];
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


- (void)setSelected:(BOOL)flag {
	if (_selected == flag)
		return;
	_selected = flag;
	[self setNeedsDisplay];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[self setSelected:selected];
}


- (void)setIsAlternate:(BOOL)flag {
	if (_isAlternate == flag)
		return;
	_isAlternate = flag;
	[self setNeedsDisplay];
}


#pragma mark Reuse

- (void)prepareForReuse {
	[self.imageView removeFromSuperview];
	self.shouldAnimateThumbnail = NO;
	self.animatingThumbnail = NO;
}


#pragma mark Drawing

- (BOOL)isOpaque {
	return YES;
}


static const CGFloat topMargin = 8.0f;
static const CGFloat rightMargin = 10.0f;
static const CGFloat bottomMargin = 8.0f;
static const CGFloat leftMargin = 8.0f;
static const CGFloat thumbWidth = 70.0f;
static const CGFloat thumbHeight = 70.0f;
static const CGFloat faviconTopMargin = 6.0f;
static const CGFloat faviconRightMargin = 4.0f;
static const CGFloat faviconHeight = 16.0f;
static const CGFloat faviconWidth = 16.0f;
static const CGFloat thumbLeftMargin = 8.0f;
static const CGFloat gutterWidth = 32.0f;
static const CGFloat titleFontSize = 14.0f;
static const CGFloat cellWidth = 320.0f;

+ (CGFloat)defaultLineHeight {
	return topMargin + thumbHeight + bottomMargin;
}


+ (CGSize)maxTitleSizeForNewsItemWithoutThumbnail:(NNWNewsItemProxy *)newsItem {
	CGFloat maxHeight = ((([self defaultLineHeight] - topMargin) - bottomMargin) - faviconHeight) - faviconTopMargin;
	CGFloat maxWidth = (cellWidth - gutterWidth) - rightMargin;
	return CGSizeMake(maxWidth, maxHeight);
}


+ (CGSize)maxTitleSizeForNewsItemWithThumbnail:(NNWNewsItemProxy *)newsItem {
	CGFloat maxHeight = ((([self defaultLineHeight] - topMargin) - bottomMargin) - faviconHeight) - faviconTopMargin;
	CGFloat maxWidth = (((cellWidth - gutterWidth) - rightMargin) - thumbWidth) - thumbLeftMargin;
	return CGSizeMake(maxWidth, maxHeight);	
}


+ (CGSize)titleSizeForNewsItem:(NNWNewsItemProxy *)newsItem maxSize:(CGSize)maxSize {
	NSString *title = newsItem.plainTextTitle;
	if (RSStringIsEmpty(title))
		title = @"X";
	CGFloat titleHeight = 0.0f;//[self _cachedHeightForText:title maxSize:maxSize];
	if (titleHeight > 1.0f)
		return CGSizeMake(maxSize.width, titleHeight);
	static UIFont *titleFont = nil;
	if (titleFont == nil)
		titleFont = [[UIFont boldSystemFontOfSize:titleFontSize] retain];
	CGSize titleSize = [title sizeWithFont:titleFont constrainedToSize:maxSize lineBreakMode:UILineBreakModeTailTruncation];
	//[self _cacheHeightForText:title maxSize:maxSize height:titleSize.height];
	return titleSize;	
}


+ (CGSize)titleSizeForNewsItemWithoutThumbnail:(NNWNewsItemProxy *)newsItem {
	CGSize maxSize = [self maxTitleSizeForNewsItemWithoutThumbnail:newsItem];
	return [self titleSizeForNewsItem:newsItem maxSize:maxSize];
}


+ (CGSize)titleSizeForNewsItemWithThumbnail:(NNWNewsItemProxy *)newsItem {
	CGSize maxSize = [self maxTitleSizeForNewsItemWithThumbnail:newsItem];
	return [self titleSizeForNewsItem:newsItem maxSize:maxSize];
}


+ (CGFloat)rowHeightForNewsItem:(NNWNewsItemProxy *)newsItem {
	CGFloat defaultLineHeight = [self defaultLineHeight];
	if (newsItem == nil)
		return defaultLineHeight;
	NSString *thumbnailURLString = newsItem.thumbnailURLString;
	BOOL shouldHaveThumbnail = !RSIsIgnorableImgURLString(thumbnailURLString);
	//BOOL shouldHaveThumbnail = !RSStringIsEmpty(thumbnailURLString);
	if (shouldHaveThumbnail)
		return defaultLineHeight;
	CGSize titleSize = [self titleSizeForNewsItemWithoutThumbnail:newsItem];
	CGFloat rowHeight = topMargin + titleSize.height + faviconTopMargin + faviconHeight + bottomMargin;
	if (rowHeight < defaultLineHeight && rowHeight > defaultLineHeight - 5)
		return defaultLineHeight;
	return rowHeight;
}


- (BOOL)wantsThumbnailWithURLString:(NSString *)urlString {
	NNWNewsItemProxy *newsItem = self.newsItemProxy;
	if (newsItem == nil)
		return NO;
	NSString *thumbnailURLString = newsItem.thumbnailURLString;
	if (thumbnailURLString == nil)
		return NO;
	return [thumbnailURLString isEqualToString:urlString] && !RSIsIgnorableImgURLString(urlString);
}


static NSString *NNWThumbnailOverlayImageName = @"ImageWellOverlay.png";
static NSString *NNWThumbnailOverlaySelectedImageName = @"ImageWellOverlaySelected.png";
static NSString *NNWThumbnailOverlaySecondarySelectedImageName = @"ImageWellOverlaySecondarySelected.png";

- (UIImage *)thumbnailImageForURLString:(NSString *)thumbnailURLString {
	UIImage *cachedThumbnailImage = [self.tableController thumbnailForURLString:thumbnailURLString];
	if (cachedThumbnailImage)
		return cachedThumbnailImage;
	return nil;
}


- (UIImage *)thumbnailOverlayImage {
	NSString *thumbnailOverlayImageName = _selected || _highlighted ? NNWThumbnailOverlaySelectedImageName : NNWThumbnailOverlayImageName;
	if (app_delegate.rightPaneViewType == NNWRightPaneViewWebPage)
		thumbnailOverlayImageName = _selected || _highlighted ? NNWThumbnailOverlaySecondarySelectedImageName : NNWThumbnailOverlayImageName;
	return [UIImage imageNamed:thumbnailOverlayImageName];	
}

- (void)thumbnailAnimationDidComplete:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	self.animatingThumbnail = NO;
	self.shouldAnimateThumbnail = NO;
	[self.imageView removeFromSuperview];
	[self setNeedsDisplay];
}


- (void)startThumbnailAnimation:(UIImage *)thumbnailImage {
	
	/*Draw thumbnail + overlay to an image view and animate its opacity.
	 When not animating, it gets removed and we draw straight to the context.*/
	
	self.animatingThumbnail = YES;
	self.shouldAnimateThumbnail = NO; // Because we're doing it now, it's not still a "should"
	
	CGRect rThumbnailSpace = CGRectMake((cellWidth - thumbWidth) - rightMargin, topMargin, thumbWidth, thumbHeight);

	/*Draw thumbnail + overlay to an image.*/
	
	UIGraphicsBeginImageContext(CGSizeMake(rThumbnailSpace.size.width + 2, rThumbnailSpace.size.height + 2));
	
	CGSize thumbnailSize = thumbnailImage.size;
	CGRect rThumbnail = CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height);
	CGRect rThumbnailDrawSpace = CGRectMake(0, 0, thumbWidth, thumbHeight);
	rThumbnail = CGRectCenteredHorizontallyInContainingRect(rThumbnail, rThumbnailDrawSpace);
	rThumbnail = CGRectCenteredVerticalInContainingRect(rThumbnail, rThumbnailDrawSpace);
	rThumbnail.size.width = thumbnailSize.width;
	rThumbnail.size.height = thumbnailSize.height;
	rThumbnail = CGRectIntegral(rThumbnail);
	
	[thumbnailImage drawAtPoint:CGPointMake(rThumbnail.origin.x, rThumbnail.origin.y)];
	//[[self thumbnailOverlayImage] drawInRect:CGRectMake(0, 0, rThumbnailSpace.size.width, rThumbnailSpace.size.height)];
	[[self thumbnailOverlayImage] drawAtPoint:CGPointZero];

	UIImage *thumbnailAndOverlayImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	if (self.imageView == nil)
		self.imageView = [[[UIImageView alloc] initWithImage:thumbnailAndOverlayImage] autorelease];
	else
		self.imageView.image = thumbnailAndOverlayImage;
	self.imageView.alpha = 0.0;
	CGRect rImageView = rThumbnailSpace;
	rImageView.size.width += 2;
	rImageView.size.height += 2;
	self.imageView.frame = rImageView;
	if (self.imageView.superview != self)
		[self addSubview:self.imageView];
	[UIView beginAnimations:@"thumbnail" context:nil];
	[UIView setAnimationDuration:0.25];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate:self]; 
	[UIView setAnimationDidStopSelector:@selector(thumbnailAnimationDidComplete:finished:context:)];
	self.imageView.alpha = 1.0;
	[UIView commitAnimations];
}


- (void)drawThumbnail:(CGRect)dirtyRect thumbnailURLString:(NSString *)thumbnailURLString {
	
	/*Thumbnails get faded in if they haven't been loaded before.*/
	
	if (thumbnailURLString == nil || self.animatingThumbnail)
		return;
	CGRect rThumbnailSpace = CGRectMake((cellWidth - thumbWidth) - rightMargin, topMargin, thumbWidth, thumbHeight);
	UIImage *thumbnailImage = [self thumbnailImageForURLString:thumbnailURLString];
	if (thumbnailImage == nil) {
		self.shouldAnimateThumbnail = YES;
		self.animatingThumbnail = NO;
		return;
	}

	if (self.shouldAnimateThumbnail) {
		[self startThumbnailAnimation:thumbnailImage];
		return;
	}
	
	if ([self.imageView superview] == self)
		[self.imageView removeFromSuperview];

	if (!CGRectIntersectsRect(dirtyRect, rThumbnailSpace))
		return;

	/*Draw directly to context*/
	CGContextRef context = CGContextRetain(UIGraphicsGetCurrentContext());
	CGContextSaveGState(context);
	
	CGContextAddRect(context, rThumbnailSpace);
	CGContextClip(context);	// The image may actually be too big for the space
	
	CGSize thumbnailSize = thumbnailImage.size;
	CGRect rThumbnail = CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height);
	rThumbnail = CGRectCenteredHorizontallyInContainingRect(rThumbnail, rThumbnailSpace);
	rThumbnail = CGRectCenteredVerticalInContainingRect(rThumbnail, rThumbnailSpace);
	rThumbnail.size.width = thumbnailSize.width;
	rThumbnail.size.height = thumbnailSize.height;
	rThumbnail = CGRectIntegral(rThumbnail);
	
	[thumbnailImage drawAtPoint:rThumbnail.origin];
	
	CGContextRestoreGState(context);
	CGContextRelease(context);
	
	[[self thumbnailOverlayImage] drawAtPoint:rThumbnailSpace.origin];
}


static NSString *NNWIndicatorUnreadImageName = @"Unread.png";
static NSString *NNWIndicatorUnreadSelectedImageName = @"Unread_Selected.png";
static NSString *NNWIndicatorStarredImageName = @"Starred.png";
static NSString *NNWIndicatorStarredSelectedImageName = @"Starred_Selected.png";

- (void)drawIndicator:(CGRect)dirtyRect {
	CGRect rIndicatorSpace = CGRectMake(0, 0, gutterWidth, self.bounds.size.height);
	if (!CGRectIntersectsRect(dirtyRect, rIndicatorSpace))
		return;
	
	UIImage *indicatorImage = nil;
	if (!self.newsItemProxy.read)
		indicatorImage = [UIImage imageNamed: _highlighted || _selected ? NNWIndicatorUnreadSelectedImageName : NNWIndicatorUnreadImageName];
	if (self.newsItemProxy.starred)
		indicatorImage = [UIImage imageNamed: _highlighted || _selected ? NNWIndicatorStarredSelectedImageName : NNWIndicatorStarredImageName];
	if (indicatorImage == nil)
		return;

	CGSize indicatorImageSize = indicatorImage.size;
	CGRect rIndicator = CGRectMake(0, 0, indicatorImageSize.width, indicatorImageSize.height);
	rIndicator = CGRectCenteredVerticalInContainingRect(rIndicator, rIndicatorSpace);
	rIndicator = CGRectCenteredHorizontallyInContainingRect(rIndicator, rIndicatorSpace);
	rIndicator = CGRectIntegral(rIndicator);
	[indicatorImage drawAtPoint:rIndicator.origin];
}


static NSString *NNWArticleCellImageName = @"ArticleCell.png";
static NSString *NNWArticleCellSelectedImageName = @"ArticleCell_Selected.png";
static NSString *NNWArticleCellHighlightedImageName = @"ArticleCell_Highlighted.png";
static NSString *NNWArticleCellSecondarySelectedImageName = @"ArticleCell_SecondarySelected.png";
static NSString *NNWArticleCellSecondaryHighlightedImageName = @"ArticleCell_SecondaryHighlighted.png";

- (void)drawBackground:(CGRect)dirtyRect {
	NSString *backgroundImageName = nil;
	if (!_highlighted) {
		[[UIColor whiteColor] set];
		UIRectFill(dirtyRect);
		backgroundImageName = NNWArticleCellImageName;
	}
	BOOL showingWebPage = (app_delegate.rightPaneViewType == NNWRightPaneViewWebPage);
	if (_selected)
		backgroundImageName = showingWebPage ? NNWArticleCellSecondarySelectedImageName : NNWArticleCellSelectedImageName;
	if (_highlighted)
		backgroundImageName = showingWebPage ? NNWArticleCellSecondaryHighlightedImageName : NNWArticleCellHighlightedImageName;

	if (backgroundImageName != nil)
		[[UIImage imageNamed:backgroundImageName] drawInRect:self.bounds];	
}


- (void)drawRect:(CGRect)rect {
	
	[self drawBackground:rect];
	
	NSString *thumbnailURLString = self.newsItemProxy.thumbnailURLString;
	BOOL shouldHaveThumbnail = !RSIsIgnorableImgURLString(thumbnailURLString);
	CGRect rBounds = self.bounds;
	BOOL shouldShowFeedName = !self.tableController.displayingSingleFeed;
	
	CGFloat titleWidth = (rBounds.size.width - gutterWidth) - rightMargin;
	if (shouldHaveThumbnail)
		titleWidth = (titleWidth - thumbWidth) - thumbLeftMargin;
	CGFloat titleHeight = (((rBounds.size.height - topMargin) - bottomMargin) - faviconHeight) - faviconTopMargin;
	if (!shouldShowFeedName)
		titleHeight = (rBounds.size.height - topMargin) - bottomMargin;
	CGRect rTitle = CGRectIntegral(CGRectMake(gutterWidth, topMargin, titleWidth, titleHeight));
	static UIColor *titleColor = nil;
	if (titleColor == nil)
		titleColor = [[UIColor colorWithRed:0.110f green:0.194f blue:0.255f alpha:1.0f] retain];
	[titleColor set];
	if (_highlighted || _selected)
		[[UIColor whiteColor] set];
	static UIFont *titleFont = nil;
	if (titleFont == nil)
		titleFont = [[UIFont boldSystemFontOfSize:titleFontSize] retain];
	NSString *title = self.newsItemProxy.plainTextTitle;
	if (title == nil)
		title = RSEmptyString;
	CGSize titleSize = CGSizeZero;
	if (shouldHaveThumbnail)
		titleSize = [NNWNewsListCellContentView titleSizeForNewsItemWithThumbnail:self.newsItemProxy];
	else
		titleSize = [NNWNewsListCellContentView titleSizeForNewsItemWithoutThumbnail:self.newsItemProxy];
	rTitle.size.height = titleSize.height;
	if (shouldShowFeedName) {
		rTitle.origin.y = 0;
		CGRect rFeedLine = CGRectMake(gutterWidth, CGRectGetMaxY(rTitle), (rBounds.size.width - gutterWidth) - leftMargin, faviconTopMargin + faviconHeight + 1);
		if (shouldHaveThumbnail)
			rFeedLine.size.width -= (thumbWidth + thumbLeftMargin);
		CGRect rText = CGRectUnion(rTitle, rFeedLine);
		rText = CGRectIntegral(CGRectCenteredVerticalInContainingRect(rText, rBounds));
		rTitle.origin.y = rText.origin.y;							   
	}
	else
		rTitle = CGRectIntegral(CGRectCenteredVerticalInContainingRect(rTitle, rBounds));
	
	if (shouldShowFeedName && shouldHaveThumbnail) // Special case: title is always at same y position near the top.
		rTitle.origin.y = topMargin;
	BOOL drawTextWithShadow = _highlighted || _selected;
	CGContextRef context = nil;
	if (drawTextWithShadow) {
		context = CGContextRetain(UIGraphicsGetCurrentContext());
		CGContextSaveGState(context);
		CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 1.0, [[UIColor colorWithWhite:0.0 alpha:0.45] CGColor]);
	}
	[title drawInRect:rTitle withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
	if (drawTextWithShadow)
		CGContextRestoreGState(context);
	
	if (shouldShowFeedName) {
		UIImage *favicon = [NNWFavicon imageForFeedWithGoogleID:self.newsItemProxy.googleFeedID];
		if (favicon == nil)
			favicon = [NNWFavicon defaultFavicon];
		CGRect rFavicon = CGRectIntegral(CGRectMake(gutterWidth, CGRectGetMaxY(rTitle) + faviconTopMargin, faviconWidth, faviconHeight));
//		CGRect rFavicon = CGRectIntegral(CGRectMake(gutterWidth, (rBounds.size.height - bottomMargin) - faviconHeight, faviconWidth, faviconHeight));
		if (shouldShowFeedName && shouldHaveThumbnail) // Special case: favicon and feedname is always at same y position near the bottom
			rFavicon.origin.y = (CGRectGetMaxY(rBounds) - bottomMargin) - faviconHeight;
		[favicon drawInRect:rFavicon blendMode:_highlighted || _selected ? kCGBlendModeNormal : kCGBlendModeMultiply alpha:1.0];
		
		NSString *feedName = [NNWFeedProxy titleOfFeedWithGoogleID:self.newsItemProxy.googleFeedID];
		if (RSStringIsEmpty(feedName))
			feedName = self.newsItemProxy.googleFeedTitle;
		if (feedName == nil)
			feedName = RSEmptyString;
		CGRect rFeedName = CGRectIntegral(CGRectMake(CGRectGetMaxX(rFavicon) + faviconRightMargin, CGRectGetMinY(rFavicon) + 0, (titleWidth - faviconWidth) - faviconRightMargin, 14));
		static UIFont *feedFont = nil;
		if (feedFont == nil)
			feedFont = [[UIFont boldSystemFontOfSize:12.0] retain];
		static UIColor *feedColor = nil;
		if (feedColor == nil)
			feedColor = [[UIColor colorWithRed:0.341f green:0.341f blue:0.341f alpha:1.0f] retain];
		[feedColor set];
		if (_highlighted || _selected)
			[[UIColor whiteColor] set];
		if (drawTextWithShadow) {
			CGContextSaveGState(context);
			CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 1.0, [[UIColor colorWithWhite:0.0 alpha:0.45] CGColor]);
		}
		[feedName drawInRect:rFeedName withFont:feedFont lineBreakMode:UILineBreakModeTailTruncation alignment:UITextAlignmentLeft];
		if (drawTextWithShadow)
			CGContextRestoreGState(context);
	}
	
	if (drawTextWithShadow)
		CGContextRelease(context);
		
	if (shouldHaveThumbnail)
		[self drawThumbnail:rect thumbnailURLString:thumbnailURLString];
	[self drawIndicator:rect];
}


@end
