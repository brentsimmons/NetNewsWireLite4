//
//  NNWMainTableViewCell.m
//  nnwiphone
//
//  Created by Brent Simmons on 8/14/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NNWMainTableViewCell.h"
#import "NNWAppDelegate.h"
#import "NNWDatabaseController.h"
#import "NNWFavicon.h"
#import "NNWFeed.h"
#import "NNWFeedProxy.h"
#import "NNWFolderProxy.h"
#import "NNWMainViewController.h"
#import "RSUIKitExtras.h"



@interface NNWMainTableCellContentView ()
@property (nonatomic, retain) UIButton *expandCollapseButton;
@property (nonatomic, assign, readonly) BOOL disclosed;
- (void)updateExpandCollapseButton;
- (void)updateImageInsetsForExpandCollapseButtonImage;
@end


@implementation NNWMainTableCellContentView

@synthesize highlighted = _highlighted, isAlternate = _isAlternate;
@synthesize indentationLevel = _indentationLevel, indentationWidth = _indentationWidth;
@synthesize delegate = _delegate, representedObject = _representedObject;
@synthesize expandCollapseButton = _expandCollapseButton;
@synthesize mainViewController = _mainViewController, collapsed = _collapsed;
@synthesize hasFolderShadow;
@synthesize selected = _selected;
@synthesize disclosureHighlighted;
@synthesize expandable, level;


- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (!self)
		return nil;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[_representedObject release];
	[_expandCollapseButton release];
	[super dealloc];
}


#pragma mark Actions

- (void)_expandCollapse:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWUserDidExpandOrCollapseFolderNotification object:self userInfo:self.representedObject];
	[self updateExpandCollapseButton];
	self.disclosureHighlighted = YES;
}


- (void)highlightExpandCollapseButton:(id)sender {
	[self incrementDisclosureHighlights];
	[self.layer display];
}


- (void)unhighlightExpandCollapseButton:(id)sender {
	[self decrementDisclosureHighlights];
	[self.layer display];
}

#pragma mark Subviews

- (void)setHighlighted:(BOOL)highlighted {
	_highlighted = highlighted;
	[self setNeedsDisplay];
}


- (void)setSelected:(BOOL)selected {
	_selected = selected;
	[self setNeedsDisplay];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[self setSelected:selected];
}


- (BOOL)isExpandable {
	if (!self.representedObject)
		return NO;
	NSInteger rowType = [[self.representedObject objectForKey:@"rowType"] integerValue];
	return rowType == NNWFolderItem;
}


- (void)setExpandable:(BOOL)flag {
	if (expandable != flag)
		[self setNeedsDisplay];
	expandable = flag;
}


- (void)setLevel:(NSInteger)aLevel {
	if (level != aLevel) {
		[self updateImageInsetsForExpandCollapseButtonImage];
		[self setNeedsDisplay];
	}
	level = aLevel;
}


- (BOOL)disclosed {
	return self.expandable && !self.collapsed;
}


static const CGFloat buttonInsetTop = 18;
static const CGFloat buttonInsetLeft = 5;
static const CGFloat imageWidth = 18;
static const CGFloat imageHeight = 18;
static const CGFloat buttonWidth = 100;
static const CGFloat indentWidth = 20;

- (void)updateImageInsetsForExpandCollapseButtonImage {
	CGRect rBounds = self.bounds;
	CGFloat buttonMaxY = buttonInsetTop + imageHeight;
	CGFloat buttonInsetBottom = CGRectGetHeight(rBounds)  - buttonMaxY;
	CGFloat buttonInsetRight = buttonWidth - (buttonInsetLeft + imageWidth);
	CGFloat buttonImageInsetTop = 8;
	if (self.collapsed)
		buttonImageInsetTop = 10;
	CGFloat leftIndent = self.level * indentWidth;
	self.expandCollapseButton.imageEdgeInsets = UIEdgeInsetsMake(buttonImageInsetTop, 9 + leftIndent, buttonInsetBottom, buttonInsetRight - leftIndent);
}


- (void)updateExpandCollapseButtonImage {
	[self.expandCollapseButton setImage:self.collapsed ? [UIImage imageNamed:@"ArrowUndisclosed.png"] : [UIImage imageNamed:@"ArrowDisclosed.png"] forState:UIControlStateNormal];
	if (_selected)
		[self.expandCollapseButton setImage:self.collapsed ? [UIImage imageNamed:@"ArrowUndisclosed_Selected.png"] : [UIImage imageNamed:@"ArrowDisclosed_Selected.png"] forState:UIControlStateNormal];
	[self updateImageInsetsForExpandCollapseButtonImage];
}


- (void)ensureExpandCollapseButton {
	if (!self.expandCollapseButton) {
		self.expandCollapseButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[self updateExpandCollapseButtonImage];
		[self.expandCollapseButton addTarget:self action:@selector(_expandCollapse:) forControlEvents:UIControlEventTouchUpInside];
		[self.expandCollapseButton addTarget:self action:@selector(highlightExpandCollapseButton:) forControlEvents:UIControlEventTouchDown];
		[self.expandCollapseButton addTarget:self action:@selector(unhighlightExpandCollapseButton:) forControlEvents:UIControlEventTouchUpOutside];
		[self.expandCollapseButton setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin];
		[self addSubview:_expandCollapseButton];
		CGRect rBounds = self.bounds;
		[self.expandCollapseButton setFrame:CGRectMake(0, 0, buttonWidth, CGRectGetHeight(rBounds))];
	}
}


- (void)updateExpandCollapseButton {
	[self ensureExpandCollapseButton];
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


- (void)incrementDisclosureHighlights {
	self.disclosureHighlighted = 1;//self.disclosureHighlighted + 1;
	[self setNeedsDisplay];
}


- (void)decrementDisclosureHighlights {
	self.disclosureHighlighted = 0;//self.disclosureHighlighted - 1;
	//if (self.disclosureHighlighted < 1)
		[self setNeedsDisplay];
}


- (void)setNeedsDisplayOnMainThread {
	[self performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:NO];
}


- (void)setDisclosureHighlighted:(NSInteger)n {
	if (disclosureHighlighted == 0 && n != 0)
		[self setNeedsDisplayOnMainThread];
	else if (n == 0 && disclosureHighlighted != 0)
		[self setNeedsDisplayOnMainThread];
	disclosureHighlighted = n;
}


- (UITableViewCell *)parentCell {
	UIView *nomad = self;
	while (nomad != nil) {
		if ([nomad isKindOfClass:[UITableViewCell class]])
			return (UITableViewCell *)nomad;
		nomad = [nomad superview];
	}
	return nil;
}


- (BOOL)isEditing {
	return [self.parentCell isEditing];
}


- (NNWProxy *)nnwProxy {
	return [_representedObject objectForKey:@"nnwProxy"];
}


- (void)layoutSubviews {
	if ([self isExpandable])
		[self ensureExpandCollapseButton];
	else
		[self ensureExpandCollapseButtonIsRemoved];
}


#pragma mark Drawing

- (BOOL)isOpaque {
	return NO;
}


#pragma mark Row Background Images


- (NSString *)secondaryDisclosedFolderBackgroundImageName {
	NSString *rowImageName = _selected ? @"Folder_Selected_Disclosed.png" : @"Folder_Up_Disclosed.png";
	if (_highlighted)
		rowImageName = @"Folder_UpHighlighted.png";
	return rowImageName;									   	
}


- (NSString *)secondaryFolderBackgroundImageName {
	
	/*For when webview is showing*/

	if (self.disclosed)
		return [self secondaryDisclosedFolderBackgroundImageName];
	
	NSString *rowImageName = _selected ? @"Folder_SelectedWebview.png" : @"Folder_Up.png";
	if (_highlighted)
		rowImageName = @"Folder_SecondarySelected_Highlighted.png";
	
	return rowImageName;									   
}


- (NSString *)disclosedFolderBackgroundImageName {
	NSString *rowImageName = _selected ? @"Folder_Selected_Disclosed.png" : @"Folder_Up_Disclosed.png";
	if (_highlighted)
		rowImageName = @"Folder_UpHighlighted.png";
	if (self.disclosureHighlighted > 0)
		rowImageName = _selected ? @"Folder_Selected_DisclosureHighlighted.png" : @"Folder_Up_DisclosureHighlighted.png";
	return rowImageName;									   	
}


- (NSString *)folderBackgroundImageName {
	
	if (app_delegate.rightPaneViewType == NNWRightPaneViewWebPage)
		return [self secondaryFolderBackgroundImageName];	
	if (self.disclosed)
		return [self disclosedFolderBackgroundImageName];
	NSString *rowImageName = _selected ? @"Folder_Selected.png" : @"Folder_Up.png";
	if (_highlighted)
		rowImageName = @"Folder_UpHighlighted.png";
	if (self.disclosureHighlighted > 0)
		rowImageName = _selected ? @"Folder_Selected_DisclosureHighlighted.png" : @"Folder_Up_DisclosureHighlighted.png";
	return rowImageName;									   
}


- (NSString *)secondaryFeedBackgroundImageName {
	/*For webviews*/
	NSString *rowImageName = _selected ? @"Feed_SecondarySelected.png" : @"Feed.png";
	if (_highlighted)
		rowImageName = @"Feed_Highlighted.png";
	return rowImageName;	
}


- (NSString *)feedBackgroundImageName {
	if (app_delegate.rightPaneViewType == NNWRightPaneViewWebPage)
		return [self secondaryFeedBackgroundImageName];
	NSString *rowImageName = _selected ? @"Feed_Selected.png" : @"Feed.png";
	if (_highlighted)
		rowImageName = @"Feed_Highlighted.png";
	return rowImageName;
}


- (void)drawRect:(CGRect)r {
	BOOL highlightedOrSelected = _highlighted || _selected;
	BOOL drawInteriorAsHighlightedOrSelected = highlightedOrSelected;
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect rBounds = CGRectIntegral(self.bounds);
	rBounds.size.width -= 8;
	NSUInteger leftMargin = 13;
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
	if (isFeed)
		drawInteriorAsHighlightedOrSelected = _selected;
	BOOL isFolder = rowType == NNWFolderItem;
	BOOL displayTitleAsFolder = isStarredItems || isSyntheticFeed || isFolder || rowType == NNWShowHideFeedsItem;
	BOOL settingsRow = rowType == NNWShowHideFeedsItem;
	UIImage *image = nil;
	BOOL scaleImage = YES;
	if (isFeed && !isSyntheticFeed) {
		image = [NNWFavicon imageForFeedWithGoogleID:nnwProxy.googleID];
		if (image == nil)
			image = [NNWFavicon defaultFavicon];
	}
	NSUInteger titleX = leftMargin;
	NSUInteger descriptionX = leftMargin + imageSpaceWidth + imageRightMargin;
	NSUInteger titleMaxHeight = 20;
	static const NSUInteger titleBottomMargin = 2;

	NSUInteger maxTextAreaWidth = (CGRectGetMaxX(rBounds) - titleX) - rightMargin;
	UIFont *titleFont = nil;
	if (!titleFont)
		titleFont = [UIFont boldSystemFontOfSize:14.0];
	static UIFont *unreadCountFont = nil;
	if (!unreadCountFont)
		unreadCountFont = [[UIFont boldSystemFontOfSize:14.0] retain];
	static UIColor *textTextColorFeedNonHighlighted = nil;
	if (!textTextColorFeedNonHighlighted)
		textTextColorFeedNonHighlighted = [[UIColor colorWithWhite:0.219 alpha:1.0] retain];
	UIColor *titleTextColor = textTextColorFeedNonHighlighted;
	static UIColor *titleTextColorNonHighlighted = nil;
	if (!titleTextColorNonHighlighted)
		titleTextColorNonHighlighted = [[UIColor colorWithWhite:0.219 alpha:1.0] retain];
	if (displayTitleAsFolder)
		titleTextColor = titleTextColorNonHighlighted;

	static UIColor *descriptionTextColorNonHighlighted = nil;
	if (!descriptionTextColorNonHighlighted)
		descriptionTextColorNonHighlighted = [[UIColor slateBlueColor] retain];//[[UIColor colorWithHexString:@"#333333"] retain];
	UIColor *descriptionTextColor = descriptionTextColorNonHighlighted;

	NSUInteger textAreaHeight = 0;
	CGFloat descriptionHeight = 0.0f;//16.0;
	if (displayTitleAsFolder) {

		titleFont = [UIFont boldSystemFontOfSize:18.0];		
	}
	if (drawInteriorAsHighlightedOrSelected) {
		titleTextColor = [UIColor whiteColor];
		descriptionTextColor = [UIColor whiteColor];
	}
//	if (!_highlighted && isFeed && !isStarredItems && !isSyntheticFeed) {
//
//		[[UIColor colorWithWhite:0.95 alpha:1.0] set];
//		[[UIColor whiteColor] set];
//		UIRectFill(r);
//	}	

	/*Unread count geometry*/
	
	NSInteger unreadCount = 0;

	unreadCount = nnwProxy.unreadCount;

	NSInteger unreadCountWidth = 0;

	if (unreadCount > 0) {
		NSString *s = [NSString stringWithFormat:@"%d", unreadCount];
		int ctDigits = [s length];
		static const int paddingLeft = 8;
		static const int paddingRight = 8;
		static NSInteger spacePerDigit = -1;
		if (spacePerDigit < 0)
			spacePerDigit = [@"8" sizeWithFont:unreadCountFont constrainedToSize:CGSizeMake(80, 30) lineBreakMode:UILineBreakModeClip].width;
		unreadCountWidth = paddingLeft + (spacePerDigit * ctDigits) + paddingRight;
		if (unreadCountWidth < 23.0f)
			unreadCountWidth = 23.0f;
	}
	unreadCountWidth++;
	CGFloat xCount = (CGRectGetMaxX(rBounds) - 4) - unreadCountWidth;
	CGFloat yCount = topMargin + 20;
	if (isFolder || isSyntheticFeed)
		yCount = (CGRectGetHeight(rBounds) / 2.0);// + 10;
	CGRect rCountBackground = CGRectMake(xCount, yCount, unreadCountWidth, 16);
	NSInteger xUnreadCount = CGRectGetMinX(rCountBackground) - 10;
	if (unreadCount < 1)
		xUnreadCount = CGRectGetMaxX(rBounds) - rightMargin;

	descriptionX = leftMargin;
	if (image)// && indentationLevel == 0)
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

	NSInteger titleHeight = isFeed ? titleHeightFeed : titleHeightFolder;
	textAreaHeight = titleHeight + titleBottomMargin + descriptionHeight;
	NSUInteger margin = ((rBounds.size.height - textAreaHeight) / 2) + 4;
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

	
	static UIColor *unreadBackgroundColor = nil;
	if (!unreadBackgroundColor)
//		unreadBackgroundColor = [[UIColor unreadCountBackgroundColor] retain];
		unreadBackgroundColor = [[UIColor slateBlueColor] retain];
	CGRect rDescription = rTitle;
	rDescription.origin.y = CGRectGetMaxY(rDescription) + titleBottomMargin;
	rDescription.origin.x = descriptionX;
	rDescription.size.width = (CGRectGetMaxX(rBounds) - descriptionX) - rightMargin;

	//UIImage *rowImage = _highlighted ? [UIImage imageNamed:@"Feed_Selected.png"] : [UIImage imageNamed:@"Feed.png"];
//	BOOL articleIsShowing = (app_delegate.rightPaneViewType == NNWRightPaneViewArticle);
	NSString *rowImageName = nil;
//	BOOL collapsed = self.collapsed;
	if (isSyntheticFeed || isFolder)
		rowImageName = [self folderBackgroundImageName];
	else
		rowImageName = [self feedBackgroundImageName];
	if (rowImageName == nil)
		rowImageName = @"Feed.png";
	UIImage *rowImage = [UIImage imageNamed:rowImageName];
//	if (isSyntheticFeed || isFolder) {
//		if (articleIsShowing)
//			rowImageName = _highlighted ? @"Folder_Selected.png" : @"Folder_Up.png";
//		else
//			rowImageName = _highlighted ? [UIImage imageNamed:<#(NSString *)name#>
//		
//	}
//	if (isFolder && !self.collapsed)
//		rowImage = _highlighted ? [UIImage imageNamed:@"Folder_Selected_Disclosed.png"] : [UIImage imageNamed:@"Folder_Up_Disclosed.png"];
	[rowImage drawInRect:self.bounds];
	
	if (image) {

		NSInteger thumbnailY = rTitle.origin.y + 2;
		NSInteger imageIndentLevel = indentationLevel;
		if (imageIndentLevel > 0)
			imageIndentLevel--;
		NSInteger thumbnailX = leftMargin;
//		if (indentationLevel > 0)
//			thumbnailX -= 20;
		CGRect rThumbnail = CGRectIntegral(CGRectMake(thumbnailX, thumbnailY, imageSpaceWidth, imageSpaceHeight));
		if (!scaleImage) {
			CGSize imageSize = image.size;
			thumbnailY = CGRectGetMidY(rBounds) - (imageSize.height / 2);
			rThumbnail = CGRectIntegral(CGRectMake(thumbnailX, thumbnailY, imageSize.width, imageSize.height));
		}

		[image drawInRect:rThumbnail blendMode:kCGBlendModeMultiply alpha:1.0];

	}		

	if (isSyntheticFeed) {
		//UIImage *syntheticFeedImage = [_representedObject objectForKey:@"image"];
		UIImage *syntheticFeedImage = nil;
		NNWProxy *proxy = [_representedObject objectForKey:@"nnwProxy"];
		if ([proxy isKindOfClass:[NNWLatestNewsItemsProxy class]])
			syntheticFeedImage = _highlighted ? [UIImage imageNamed:@"LatestNewsIcon_Selected.png"] : [UIImage imageNamed:@"LatestNewsIcon.png"];
		if ([proxy isKindOfClass:[NNWStarredItemsProxy class]])
			syntheticFeedImage = _highlighted ? [UIImage imageNamed:@"Starred_Selected.png"] : [UIImage imageNamed:@"Starred.png"];
		if (syntheticFeedImage) {
			CGRect rImage = CGRectZero;
			rImage.origin.x = 4;
			rImage.size.height = syntheticFeedImage.size.height;
			rImage.size.width = syntheticFeedImage.size.width;
			rImage.origin.x = (rTitle.origin.x / 2) - (rImage.size.width / 2);
			rImage.origin.y = (CGRectGetHeight(self.bounds) / 2) - (rImage.size.height / 2);
			rImage = CGRectIntegral(rImage);
			rImage.size.height = syntheticFeedImage.size.height;
			rImage.size.width = syntheticFeedImage.size.width;
			rImage.origin.y--;
			rImage.origin.x++;
			CGContextSaveGState(context);
//			if (!drawInteriorAsHighlightedOrSelected)
//				CGContextSetShadowWithColor(context, CGSizeMake(0, -1.0), 1.0, [[UIColor colorWithWhite:0.0 alpha:0.5] CGColor]);
			[syntheticFeedImage drawInRect:rImage];
			CGContextRestoreGState(context);
		}			
	}
	
	if (unreadCount > 0) {		
//		CGContextSaveGState(context);
		[unreadBackgroundColor set];
		if (drawInteriorAsHighlightedOrSelected)
			[[UIColor whiteColor] set];
//		CGContextSetLineWidth(context, 20);
//		CGContextSetLineCap(context, kCGLineCapRound);
//		//rCountBackground.origin.y = rTitle.origin.y - 14;
//		rCountBackground.origin.y = 10;
//		CGContextMoveToPoint(context, rCountBackground.origin.x, (int)((rCountBackground.origin.y + rCountBackground.size.height) / 2));
//		CGContextAddLineToPoint(context, (rCountBackground.origin.x + rCountBackground.size.width), (int)((rCountBackground.origin.y + rCountBackground.size.height) / 2));
//		CGContextStrokePath(context);
//		CGContextRestoreGState(context);
		
		rCountBackground.origin.y = 12;
		static const CGFloat badgeHeight = 23.0f;
		rCountBackground.size.height = badgeHeight;
		static UIImage *unreadBadge = nil;
		if (unreadBadge == nil)
			unreadBadge = [[[UIImage imageNamed:@"UnreadBadge.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:10] retain];
		static UIImage *unreadBadgeSelected = nil;
		if (unreadBadgeSelected == nil)
			unreadBadgeSelected = [[[UIImage imageNamed:@"UnreadBadgeSelected.png"] stretchableImageWithLeftCapWidth:11 topCapHeight:10] retain];
		UIImage *badgeToDraw = drawInteriorAsHighlightedOrSelected ? unreadBadgeSelected : unreadBadge;
		[badgeToDraw drawInRect:rCountBackground];
		
		[[UIColor whiteColor] set];
		if (drawInteriorAsHighlightedOrSelected) {
			static UIColor *unreadBadgeHighlightedBackgroundColor = nil;
			if (unreadBadgeHighlightedBackgroundColor == nil)
				unreadBadgeHighlightedBackgroundColor = [[UIColor colorWithHexString:@"#26425F"] retain];
			[unreadBadgeHighlightedBackgroundColor set];
			//[[UIColor greenColor] set];
		}

		if (isFolder || isSyntheticFeed)
			rCountBackground.origin.y -= 12;
		rCountBackground.origin.y -= 7;
		
		CGRect rCountText = rCountBackground;
		rCountText.origin.y = rTitle.origin.y;
		if (isFolder || isSyntheticFeed)
			rCountText.origin.y += 3;
		rCountText.size.width -= 8;
		rCountText = CGRectIntegral(rCountText);
//		if (!isFolder && RSRunningOnOS42OrBetter())
//			rCountText.origin.y = rCountText.origin.y - 2.0f;
		[[NSString stringWithFormat:@"%d", unreadCount] drawInRect:rCountText withFont:unreadCountFont lineBreakMode:UILineBreakModeClip alignment:UITextAlignmentRight];

	}


	[titleTextColor set];
	if (!drawInteriorAsHighlightedOrSelected)
		CGContextSetShadowWithColor(context, CGSizeMake(0, 1.0), 1.0, [[UIColor colorWithWhite:1.0 alpha:0.5] CGColor]);	
	[title drawAtPoint:rTitle.origin forWidth:rTitle.size.width withFont:titleFont lineBreakMode:UILineBreakModeTailTruncation];
	
	if (self.hasFolderShadow) {
		UIImage *folderShadowImage = [UIImage imageNamed:@"FolderShadow.png"];
		[folderShadowImage drawAtPoint:self.bounds.origin];
	}

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

		[self.contentView addSubview:_cellView];
		if ([reuseIdentifier hasSuffix:@"-alt"])
			_cellView.isAlternate = YES;
		self.clipsToBounds = YES;
		self.contentMode = UIViewContentModeRedraw;

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

- (void)setHasFolderShadow:(BOOL)flag {
	_cellView.hasFolderShadow = flag;
	[self setNeedsDisplay];
}


- (void)setIsAlternate:(BOOL)flag {
	_cellView.isAlternate = flag;
}


- (void)setSelected:(BOOL)flag {
	_cellView.selected = flag;
	[self setNeedsDisplay];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
	[self setSelected:selected];
}


- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	[_cellView setNeedsDisplay];
}


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


- (BOOL)expandable {
	return _cellView.expandable;
}


- (void)setExpandable:(BOOL)flag {
	_cellView.expandable = flag;
}


- (NSInteger)level {
	return _cellView.level;
}


- (void)setLevel:(NSInteger)aLevel {
	_cellView.level = aLevel;
}


- (void)turnOffDisclosureHighlight {
	_cellView.disclosureHighlighted = 0;
}


- (BOOL)isOpaque {
	return NO;
}


@end
