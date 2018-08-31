//
//  NNWArticleListView.m
//  nnw
//
//  Created by Brent Simmons on 11/26/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "NNWArticleListView.h"
#import "NNWSourceListDelegate.h"
#import "NSBezierPath_AMAdditons.h"
#import "RSDataAccount.h"
#import "RSDataArticle.h"
#import "RSDateManager.h"
#import "RSDownloadConstants.h"
#import "RSFaviconController.h"
#import "RSFeed.h"
#import "RSThumbnailController.h"
#import "RSWebClipIconController.h"


static NSMutableSet *gBadThumbnailURLs = nil;

static const CGFloat kNNWArticleListViewMarginLeft = 22.0f;
static const CGFloat kNNWArticleListViewMarginRight = 10.0f;
static const CGFloat kNNWArticleListViewMarginBottom = 10.0f;
static const CGFloat kNNWArticleListViewMarginTop = 10.0f;
static const CGFloat kNNWArticleListViewDateHeight = 16.0f;
static const CGFloat kNNWArticleListViewUnreadIndicatorBoxWidth = 10.0f;
static const CGFloat kNNWArticleListViewThumbnailBoxWidth = 72.0f;
static const CGFloat kNNWArticleTitleFontSize = 13.0f;
static const CGFloat kNNWArticlePreviewFontSize = 13.0f;
static const CGFloat kNNWArticleFeedNameFontSize = 13.0f;
static const CGFloat kNNWArticleDateFontSize = 11.0f;
static const CGFloat kThumbnailImageHeightAndWidth = 58.0f;


static const NSUInteger kMaximumNumberOfLinesInTitle = 2;
static const NSUInteger kMaximumNumberOfLinesInTitleWhenFeedIsShowing = 2;
static const NSUInteger kMaximumNumberOfLinesInPreview = 1;
static const NSUInteger kMaximumNumberOfLinesInPreviewWhenFeedIsShowing = 1;

static NSStringDrawingOptions kStringDrawingOptions = NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesFontLeading;
static NSString *dummyMeasurementString = @"KyZPjgQ";



@interface NNWArticleListView ()

@property (nonatomic, strong) NSButton *unreadButton;
@property (nonatomic, strong) id thumbnail; //CGImageRef
@property (nonatomic, strong) id webclipIcon; //CGImageRef
@property (nonatomic, assign, readonly) BOOL shouldShowWebClipIcon;

- (void)updateLogicalThumbnailURL;
- (void)updateUnreadButton;

@end


@implementation NNWArticleListView

@synthesize article;
@synthesize contextualMenuDelegate;
@synthesize logicalThumbnailURL;
@synthesize reuseIdentifier;
@synthesize selected;
@synthesize showFeedName;
@synthesize thumbnail;
@synthesize title;
@synthesize unreadButton;
@synthesize webclipIcon;


#pragma mark Init

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self == nil)
        return nil;
    if (gBadThumbnailURLs == nil)
        gBadThumbnailURLs = [NSMutableSet set];
    [self addObserver:self forKeyPath:@"selected" options:0 context:nil];
    [self addObserver:self forKeyPath:@"article" options:0 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailDidDownload:) name:RSThumbnailDownloadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(faviconDidDownload:) name:RSFaviconDownloadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(webclipIconDidDownload:) name:RSWebClipIconDownloadedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(articleReadStatusDidChange:) name:RSDataArticleReadStatusDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUnreadButton) name:RSMultipleArticlesDidChangeReadStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainResponderDidChange:) name:RSMainResponderDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainResponderDidChange:) name:NSApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainResponderDidChange:) name:NSApplicationDidResignActiveNotification object:nil];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"selected"];
    [self removeObserver:self forKeyPath:@"article"];
}


#pragma mark Events

- (BOOL)canBecomeKeyView {
    return NO;
}


- (BOOL)acceptsFirstResponder {
    return NO;
}


//- (void)keyDown:(NSEvent *)theEvent {
//    NSLog(@"keyDown: %@", theEvent);
//    [[self superview] keyDown:theEvent];
//}


- (void)mouseDown:(NSEvent *)theEvent {
    [[self superview] mouseDown:theEvent];
    [[self window] makeFirstResponder:[[self enclosingScrollView] documentView]];
}


#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"selected"]) {
        [self setNeedsDisplay:YES];
        [self updateUnreadButton];
    }
    if ([keyPath isEqualToString:@"article"]) {
        [self setNeedsDisplay:YES];
        [self updateLogicalThumbnailURL];
        [self updateUnreadButton];
    }
}


#pragma mark Notifications

- (void)thumbnailDidDownload:(NSNotification *)note {
    if (self.logicalThumbnailURL == nil)
        return;
    NSURL *thumbnailURL = [[note userInfo] objectForKey:RSURLKey];
    if (thumbnailURL == nil)
        return;
    if ([self.logicalThumbnailURL isEqual:thumbnailURL])
        [self setNeedsDisplay:YES];    
}


- (void)webclipIconDidDownload:(NSNotification *)note {
    if (self.shouldShowWebClipIcon && self.webclipIcon == nil)
        [self setNeedsDisplay:YES];
}


- (void)faviconDidDownload:(NSNotification *)note {
    if (self.showFeedName)
        [self setNeedsDisplay:YES];
}


#pragma mark Action Menu

- (void)unreadButtonClicked:(id)sender {
    if (self.article == nil)
        return;
    [self.article markAsRead:![self.article.read boolValue]];
    [self updateUnreadButton];
}


- (void)updateUnreadButtonImage {
    BOOL read = YES;
    if (self.article != nil && ![self.article.read boolValue])
        read = NO;
    if (read)
        [self.unreadButton setImage:nil];
    else
        [self.unreadButton setImage:[NSImage imageNamed:@"lightblueunread.png"]];
}


- (CGRect)rectOfIndicatorBox {
    /*Left-most vertical rect, where unread and star indicators appear.*/
    return CGRectMake(0.0f, 0.0f, kNNWArticleListViewMarginLeft, [self bounds].size.height);
}


- (void)addUnreadButton {    
    if (self.unreadButton != nil) {
        [self updateUnreadButtonImage];
        return;
    }
    CGRect rButton = CGRectMake(0.0f, 0.0f, 16.0f, 16.0f);
    rButton = CGRectCenteredInRect(rButton, [self rectOfIndicatorBox]);
    rButton.origin.x += 10.0f;
    self.unreadButton = [[NSButton alloc] initWithFrame:rButton];
    [self.unreadButton setBordered:NO];
    [[self.unreadButton cell] setBezelStyle:NSTexturedRoundedBezelStyle];
    [self.unreadButton setButtonType:NSMomentaryPushInButton];
    [[self.unreadButton cell] setHighlightsBy:NSPushInCellMask];
    [self.unreadButton setImagePosition:NSImageOnly];
    [self.unreadButton setImage:[NSImage imageNamed:@"lightblueunread.png"]];
    [self addSubview:self.unreadButton];
    [self.unreadButton setAction:@selector(unreadButtonClicked:)];
    [self.unreadButton setTarget:self];
    [self updateUnreadButtonImage];
}


//- (void)removeActionMenu {
//    if (self.actionMenu == nil)
//        return;
//    [self.actionMenu removeFromSuperview];
//    self.actionMenu = nil;
//}


- (void)updateUnreadButton {
    [self addUnreadButton];
//    if (self.selected)
//        [self addActionMenu];
//    else
//        [self removeActionMenu];
}


- (void)articleReadStatusDidChange:(NSNotification *)note {
    if ([note object] == self.article)
        [self updateUnreadButton];
}


- (void)mainResponderDidChange:(NSNotification *)note {
    if (self.selected)
        [self setNeedsDisplay:YES];
}


- (NSMenu *)menuForEvent:(NSEvent *)event {
    if (self.article == nil || self.contextualMenuDelegate == nil)
        return nil;
    return [self.contextualMenuDelegate contextualMenuForArticle:self.article];
}


#pragma mark Thumbnail URL

- (void)updateLogicalThumbnailURL {
    if (self.article == nil) {
        self.logicalThumbnailURL = nil;
        return;
    }
    NSString *thumbnailURLString = self.article.thumbnailURL;
    if (RSStringIsEmpty(thumbnailURLString) || [thumbnailURLString rs_isIgnorableImgURLString]) {
        self.logicalThumbnailURL = nil;
        return;
    }
    if ([gBadThumbnailURLs containsObject:[NSURL URLWithString:self.article.thumbnailURL]]) {
        self.logicalThumbnailURL = nil;
        return;
    }
    self.logicalThumbnailURL = [NSURL URLWithString:self.article.thumbnailURL];
}


#pragma mark Webclips

- (BOOL)shouldShowWebClipIcon {
    if (!self.showFeedName)
        return NO;
    if (self.article.feedURL != nil && [self.article.feedURL rs_caseInsensitiveContains:@"daringfireball"])
        return NO;
    return YES;
}


#pragma mark Drawing

- (BOOL)isFlipped {
    return YES;
}


- (BOOL)isOpaque {
    return YES;
}


+ (CGFloat)heightForArticleWithThumbnail {
    return kThumbnailImageHeightAndWidth + kNNWArticleListViewMarginTop + kNNWArticleListViewMarginBottom;
}


- (NSFont *)titleFont {
    static NSFont *gTitleFont = nil;
    if (gTitleFont == nil)
    gTitleFont = [NSFont boldSystemFontOfSize:kNNWArticleTitleFontSize];
    return gTitleFont;
}


- (NSFont *)previewFont {
    static NSFont *gPreviewFont = nil;
    if (gPreviewFont == nil)
        gPreviewFont = [NSFont systemFontOfSize:kNNWArticlePreviewFontSize];
    return gPreviewFont;    
}


- (NSFont *)dateFont {
    static NSFont *gDateFont = nil;
    if (gDateFont == nil)
        gDateFont = [NSFont boldSystemFontOfSize:kNNWArticleDateFontSize];
    return gDateFont;
}


- (NSFont *)timeFont {
    static NSFont *gTimeFont = nil;
    if (gTimeFont == nil)
        gTimeFont = [NSFont systemFontOfSize:kNNWArticleDateFontSize];
    return gTimeFont;    
}


- (NSFont *)feedNameFont {
    static NSFont *gFeedNameFont = nil;
    if (gFeedNameFont == nil)
        gFeedNameFont = [NSFont systemFontOfSize:kNNWArticleFeedNameFontSize];
    return gFeedNameFont;    
}


- (CGFloat)widthOfRowMinusMargins {
    return [self bounds].size.width - (kNNWArticleListViewMarginLeft + kNNWArticleListViewMarginRight);
}


- (CGRect)innerBoxWithBounds:(CGRect)bounds {
    /*Entire cell minus outer margins -- includes all drawing except for highlight*/
    CGRect rInnerBox = bounds;
    rInnerBox.origin.x = kNNWArticleListViewMarginLeft;
    rInnerBox.size.width = CGRectGetWidth(bounds) - (kNNWArticleListViewMarginLeft + kNNWArticleListViewMarginRight);
    rInnerBox.origin.y = kNNWArticleListViewMarginTop;
    rInnerBox.size.height = CGRectGetHeight(bounds) - (kNNWArticleListViewMarginTop + kNNWArticleListViewMarginBottom);
    return CGRectIntegral(rInnerBox);
}


- (CGRect)unreadIndicatorBoxWithBounds:(CGRect)bounds {
    /*This box is as high as the inner box and wide enough to fit the unread indicator.*/
    CGRect rInnerBox = [self innerBoxWithBounds:bounds];
    CGRect rUnreadIndictor = rInnerBox;
    rUnreadIndictor.size.width = kNNWArticleListViewUnreadIndicatorBoxWidth;
    return CGRectIntegral(rUnreadIndictor);
}


- (CGFloat)widthOfThumbnailBox {
    /*If no thumbnail for this article, it's 0.*/
    if (self.logicalThumbnailURL == nil && self.webclipIcon == nil)
        return 0.0f;
    if ([self bounds].size.width < kNNWArticleListViewThumbnailBoxWidth * 2.5f)
        return 0.0f;
//    if (RSStringIsEmpty(self.article.thumbnailURL) || [self.article.thumbnailURL rs_isIgnorableImgURLString])
//        return 0.0f;
    return kNNWArticleListViewThumbnailBoxWidth;
}


- (CGRect)thumbnailBoxWithBounds:(CGRect)bounds {
    CGRect rInnerBox = [self innerBoxWithBounds:bounds];
    CGRect rThumbnailBox = rInnerBox;
    CGFloat widthOfThumbnailBox = [self widthOfThumbnailBox];
    rThumbnailBox.origin.x = CGRectGetMaxX(rInnerBox) - widthOfThumbnailBox;
    rThumbnailBox.size.width = widthOfThumbnailBox;
    return CGRectIntegral(rThumbnailBox);
}


- (CGRect)textBoxWithBounds:(CGRect)bounds {
    /*Box for title, summary, and date -- unread indicator and thumbnail are outside this box.*/
    CGRect rInnerBox = [self innerBoxWithBounds:bounds];
    CGRect rUnreadIndictor = [self unreadIndicatorBoxWithBounds:bounds];
    CGRect rThumbnailBox = [self thumbnailBoxWithBounds:bounds];
    CGRect rTextBox = rInnerBox;
    rTextBox.origin.x = CGRectGetMaxX(rUnreadIndictor);
    rTextBox.size.width = CGRectGetMinX(rThumbnailBox) - rTextBox.origin.x;
    rTextBox = CGRectInset(rTextBox, 0.0f, 3.0f);
    if (CGRectGetWidth(rThumbnailBox) > 1.0f)
        rTextBox.size.width -= 8.0f;
    return CGRectIntegral(rTextBox);
}


- (CGFloat)lineHeightForPreview {
    static CGFloat previewLineHeight = 0.0f;
    if (previewLineHeight < 1.0f) {
        NSRect previewLineHeightRect = [dummyMeasurementString boundingRectWithSize:NSMakeSize(1000.0f, 1000.0f) options:0 attributes:[NSDictionary dictionaryWithObject:[self previewFont] forKey:NSFontAttributeName]];
        previewLineHeight = previewLineHeightRect.size.height;        
    }
    return previewLineHeight;    
}


static CGFloat kNNWFaviconHeight = 16.0f;

- (CGFloat)heightForDateText {
    static CGFloat dateLineHeight = 0.0f;
    if (dateLineHeight < 1.0f) {
        NSRect dateLineHeightRect = [dummyMeasurementString boundingRectWithSize:NSMakeSize(1000.0f, 1000.0f) options:0 attributes:[NSDictionary dictionaryWithObject:[self dateFont] forKey:NSFontAttributeName]];
        dateLineHeight = dateLineHeightRect.size.height;        
    }
    if (self.showFeedName && dateLineHeight < kNNWFaviconHeight)
        dateLineHeight = kNNWFaviconHeight;
    return dateLineHeight;
}



- (CGRect)dateBoxWithTextBox:(CGRect)textBox {
    CGRect rDateBox = textBox;
    rDateBox.size.height = [self heightForDateText];
    rDateBox.origin.y = CGRectGetMaxY(textBox) - rDateBox.size.height;
    return CGRectIntegral(rDateBox);
}


- (CGRect)feedBoxWithTextBox:(CGRect)textBox {
    if (!self.showFeedName)
        return CGRectZero;
    CGRect rFeedBox = textBox;
    rFeedBox.size.height = kNNWFaviconHeight;
    rFeedBox.origin.y = CGRectGetMaxY(textBox) - rFeedBox.size.height;
    return CGRectIntegral(rFeedBox);
}


- (CGFloat)heightForPreviewText {

    /*Height given current width of row.*/

    CGFloat lineHeight = [self lineHeightForPreview];
    NSString *previewToMeasure = self.article.plainTextPreview;
    if (previewToMeasure == nil)
        return 0.0f;
    CGRect textBox = [self textBoxWithBounds:[self bounds]];
    NSUInteger maxLinesInPreview = self.showFeedName ? kMaximumNumberOfLinesInPreviewWhenFeedIsShowing : kMaximumNumberOfLinesInPreview;
    NSRect rectForPreview = [previewToMeasure boundingRectWithSize:NSMakeSize(textBox.size.width, lineHeight * maxLinesInPreview) options:kStringDrawingOptions attributes:[NSDictionary dictionaryWithObject:[self previewFont] forKey:NSFontAttributeName]];
    return MIN(rectForPreview.size.height, lineHeight * maxLinesInPreview);    
}


- (CGFloat)heightForTitleText {
    
    /*Height given current width of row.*/
    
    static CGFloat lineHeight = 0.0f;
    if (lineHeight < 1.0f) {
        NSRect lineHeightRect = [dummyMeasurementString boundingRectWithSize:NSMakeSize(1000.0f, 1000.0f) options:kStringDrawingOptions attributes:[NSDictionary dictionaryWithObject:[self titleFont] forKey:NSFontAttributeName]];
        lineHeight = lineHeightRect.size.height;
    }
    
    NSString *titleToMeasure = self.title;
    if (titleToMeasure == nil)
        titleToMeasure = dummyMeasurementString;
    CGRect textBox = [self textBoxWithBounds:[self bounds]];
    NSUInteger maxLinesForTitle = self.showFeedName ? kMaximumNumberOfLinesInTitleWhenFeedIsShowing : kMaximumNumberOfLinesInTitle;
    NSRect rectForTitle = [titleToMeasure boundingRectWithSize:NSMakeSize(textBox.size.width, lineHeight * maxLinesForTitle) options:kStringDrawingOptions attributes:[NSDictionary dictionaryWithObject:[self titleFont] forKey:NSFontAttributeName]];
    return MIN(rectForTitle.size.height, lineHeight * maxLinesForTitle);
}


- (NSColor *)frameColor {
    static NSColor *frameColor = nil;
    if (frameColor == nil)
        frameColor = [NSColor colorWithDeviceRed:139.0f/255.0f green:146.0f/255.0f blue:157.0f/255.0f alpha:1.0f];
    return frameColor;
}


- (void)drawWebclipIconInRect:(CGRect)rThumbnail {
    if (rThumbnail.size.width < 1.0f)
        return;
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    

    CGRect rImage = CGRectMake(0.0f, 0.0f, kThumbnailImageHeightAndWidth, kThumbnailImageHeightAndWidth);
    CGFloat imageHeight = CGImageGetHeight((CGImageRef)(self.webclipIcon));
    CGFloat imageWidth = CGImageGetWidth((CGImageRef)(self.webclipIcon));

    /*Don't scale if both height and width are smaller than space.*/
    if (imageWidth < kThumbnailImageHeightAndWidth && imageHeight < kThumbnailImageHeightAndWidth) {
        rImage.size.height = imageHeight;
        rImage.size.width = imageWidth;
    }
    
    rImage = CGRectIntegral(CGRectCenteredInRect(rImage, rThumbnail));
    

    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:rImage xRadius:3.0f yRadius:3.0f];
    [borderPath setLineWidth:1.0f];
    [borderPath addClip];

    CGContextTranslateCTM(context, CGRectGetMinX(rImage), CGRectGetMaxY(rImage));
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, -rImage.origin.x, -rImage.origin.y);
    
    CGContextSetBlendMode (context, kCGBlendModeNormal);
    
    CGInterpolationQuality interpolationQuality = kCGInterpolationHigh;
    if ([self inLiveResize])
        interpolationQuality = kCGInterpolationLow;
    CGContextSetInterpolationQuality(context, interpolationQuality);
        
    CGContextDrawImage(context, rImage, (CGImageRef)(self.webclipIcon));

    CGContextRestoreGState(context);    
}


- (void)drawThumbnailInRect:(CGRect)rThumbnail {
    
    /*The rect rThumbnail is for the entire box. Place in the correct position inside that box.*/
    
    if (rThumbnail.size.width < 1.0f)
        return;
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSaveGState(context);
    
    CGRect rImage = CGRectMake(0.0f, 0.0f, kThumbnailImageHeightAndWidth, kThumbnailImageHeightAndWidth);
    CGRect rClip = CGRectIntegral(CGRectCenteredInRect(rImage, rThumbnail));


    NSBezierPath *borderPath = [NSBezierPath bezierPathWithRoundedRect:rClip xRadius:3.0f yRadius:3.0f];
    [borderPath setLineWidth:1.0f];
    [borderPath addClip];
    
    static CGColorRef placeHolderFillColor = nil;
    if (placeHolderFillColor == nil)
        placeHolderFillColor = CGColorCreateGenericGray(0.93f, 1.0f);
    //RSCGRectFillWithColor(rClip, placeHolderFillColor);
    
    CGFloat imageHeight = CGImageGetHeight((CGImageRef)(self.thumbnail));
    CGFloat imageWidth = CGImageGetWidth((CGImageRef)(self.thumbnail));
    if (imageWidth < 12.0f && imageHeight < 12.0f) {
        [gBadThumbnailURLs rs_addObject:self.logicalThumbnailURL];
        self.logicalThumbnailURL = nil;
        [self setNeedsDisplay:YES];
        return;
    }
    CGFloat scaleFactor = (imageWidth > imageHeight ? imageWidth : imageHeight) / (imageWidth < imageHeight ? imageWidth : imageHeight);
    BOOL drawDetail = (scaleFactor > 1.438f); //chosen because of a specific common Macworld image
    if (imageWidth < kThumbnailImageHeightAndWidth || imageHeight < kThumbnailImageHeightAndWidth) {
        scaleFactor = 1.0f;
        drawDetail = YES;
    }
    if (!drawDetail) {
        if (imageWidth > imageHeight)
            rImage.size.height = rImage.size.height / scaleFactor;
        else
            rImage.size.width = rImage.size.width / scaleFactor;
    }
    
    /*Don't scale if both height and width are smaller than space.*/
    if (imageWidth < kThumbnailImageHeightAndWidth && imageHeight < kThumbnailImageHeightAndWidth) {
        rImage.size.height = imageHeight;
        rImage.size.width = imageWidth;
    }
    
    rImage = CGRectIntegral(CGRectCenteredInRect(rImage, rThumbnail));
    
    if (drawDetail) {
        CGContextClipToRect(context, rImage);
        rImage.size.width = imageWidth;
        rImage.size.height = imageHeight;
        rImage.origin.x = rImage.origin.x - ((imageWidth - kThumbnailImageHeightAndWidth) / 2.0f);
        rImage.origin.y = rImage.origin.y - ((imageHeight - kThumbnailImageHeightAndWidth) / 2.0f);
    }
        
    CGContextTranslateCTM(context, CGRectGetMinX(rImage), CGRectGetMaxY(rImage));
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, -rImage.origin.x, -rImage.origin.y);
    
    CGContextSetBlendMode (context, kCGBlendModeMultiply);

    CGInterpolationQuality interpolationQuality = kCGInterpolationHigh;
    if ([self inLiveResize])
        interpolationQuality = kCGInterpolationLow;
    CGContextSetInterpolationQuality(context, interpolationQuality);

    CGContextDrawImage(context, rImage, (CGImageRef)(self.thumbnail));
    CGContextRestoreGState(context);
}

- (void)viewDidEndLiveResize {
    [self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)r {

    NSRect rBounds = [self bounds];
    
    if (!self.thumbnail && !self.webclipIcon && self.shouldShowWebClipIcon)
        self.webclipIcon = (id)[[RSWebClipIconController sharedController] webclipIconForHomePageURL:[NSURL URLWithString:self.article.feedURL] webclipIconURL:nil]; 

    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    RSCGRectFillWithWhite(r);
    
    NSRect rInnerBox = rBounds;
    rInnerBox.origin.x = kNNWArticleListViewMarginLeft;
    rInnerBox.size.width = rInnerBox.size.width - (kNNWArticleListViewMarginLeft + kNNWArticleListViewMarginRight);
    rInnerBox.origin.y = kNNWArticleListViewMarginTop;
    rInnerBox.size.height = rInnerBox.size.height - (kNNWArticleListViewMarginTop + kNNWArticleListViewMarginBottom);
    
    CGRect rTextBox = [self textBoxWithBounds:rBounds];
    CGRect rDate = [self dateBoxWithTextBox:rTextBox];
    //CGRect rFeedName = [self feedBoxWithTextBox:rTextBox];
    CGRect rTitle = rTextBox;
    rTitle.size.height = [self heightForTitleText];
    CGRect rPreview = rTextBox;
    rPreview.origin.y = CGRectGetMaxY(rTitle);
    rPreview.size.height = CGRectGetMinY(rDate) - rPreview.origin.y;
    CGFloat lineHeightForPreview = [self lineHeightForPreview];
    NSUInteger maxLinesInPreview = self.showFeedName ? kMaximumNumberOfLinesInPreviewWhenFeedIsShowing : kMaximumNumberOfLinesInPreview;
    if (rPreview.size.height < lineHeightForPreview)
        rPreview = NSZeroRect;
    else {
        if (rPreview.size.height > maxLinesInPreview * lineHeightForPreview)
            rPreview.size.height = maxLinesInPreview * lineHeightForPreview;
    }
         

    static CGFloat lineHeight = 0.0f;
    if (lineHeight < 1.0f) {
        NSMutableDictionary *lineHeightAttributes = [NSMutableDictionary dictionary];
        [lineHeightAttributes setObject:[NSFont systemFontOfSize:kNNWArticleTitleFontSize] forKey:NSFontAttributeName];
        NSAttributedString *lineHeightString = [[NSAttributedString alloc] initWithString:@"KyZPjgQ" attributes:lineHeightAttributes];
        NSRect lineHeightRect = [lineHeightString boundingRectWithSize:NSMakeSize(1000.0f, 1000.0f) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesFontLeading];
        lineHeight = lineHeightRect.size.height;
    }
    if (self.selected) {
        NSRect rFrame = NSIntegralRect(NSInsetRect([self bounds], 8.0f, 3.0f));

        rFrame.origin.x = rFrame.origin.x + 0.5f;
        rFrame.origin.y = rFrame.origin.y + 0.5f;
        
        static CGFloat kSelectionCornerRadius = 10.0f;
        
        NSBezierPath *pround = [NSBezierPath bezierPathWithRoundedRect:rFrame xRadius:kSelectionCornerRadius yRadius:kSelectionCornerRadius];
        [pround setLineWidth:1.0f];
        if ([self rs_isOrIsDescendedFromFirstResponder])
            [[[NSColor selectedTextBackgroundColor] shadowWithLevel:0.2f] set];
        else
            [[NSColor grayColor] set];

        
    CGContextSaveGState(context);
        static CGColorRef bottomShadowColor = nil;
        if (bottomShadowColor == nil)
            bottomShadowColor = CGColorCreateGenericGray(0.0f, 0.15f);
        CGContextSetShadowWithColor(context, CGSizeMake(0.0f, -1.0f), 2.0f, bottomShadowColor);        
        [pround stroke];
    CGContextRestoreGState(context);

        CGContextSaveGState(context);
        [pround addClip];
        RSCGRectFillWithWhite(r);
//        if (self.selected && ![NSApp isActive]) {
//            [[NSColor colorWithDeviceWhite:0.98f alpha:1.0f] set];
//            NSRectFill(r);
//        }
            
        CGContextRestoreGState(context);

        [pround stroke];
        
    }

//    [[NSColor orangeColor] set];
//    NSFrameRect(rTextBox);

    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[NSColor colorWithDeviceWhite:0.3f alpha:1.0f] forKey:NSForegroundColorAttributeName];
    if (self.selected)
        [attributes setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
    [attributes setObject:[self titleFont] forKey:NSFontAttributeName];

    static NSColor *previewColor = nil;
            if (previewColor == nil)
                previewColor = [self frameColor];

    NSShadow *shadow = [[NSShadow alloc] init];
    [shadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
    [shadow setShadowBlurRadius:1.0f];
    [shadow setShadowColor:[NSColor colorWithDeviceWhite:1.0f alpha:1.0f]];
    //[attributes setObject:shadow forKey:NSShadowAttributeName];
    NSAttributedString *titleString = [[NSAttributedString alloc] initWithString:(self.title ? self.title : @"") attributes:attributes];
    [titleString drawInRect:rTitle];
    
    if (rPreview.size.height > 1.0f && CGRectIntersectsRect(rPreview, r)) {
        NSString *preview = self.article.plainTextPreview;
        if (!RSStringIsEmpty(preview)) {
            NSMutableDictionary *previewAttributes = [NSMutableDictionary dictionary];
            [previewAttributes setObject:[self previewFont] forKey:NSFontAttributeName];
            [previewAttributes setObject:previewColor forKey:NSForegroundColorAttributeName];
            //[previewAttributes setObject:shadow forKey:NSShadowAttributeName];
            NSAttributedString *previewString = [[NSAttributedString alloc] initWithString:preview attributes:previewAttributes];            
            [previewString drawInRect:rPreview];
        }
    }
    
    

    BOOL didShowFavicon = NO;
        NSRect rFavicon = rDate;
    if (self.showFeedName) {
        
        rFavicon.size.width = 16.0f;
        rFavicon.size.height = 16.0f;
        rFavicon = CGRectCenteredVerticallyInRect(rFavicon, rDate);
        rFavicon = NSIntegralRect(rFavicon);
        rFavicon.size.width = 16.0f;
        rFavicon.size.height = 16.0f;
        RSFeed *feed = [[RSDataAccount localAccount] feedWithURL:[NSURL URLWithString:self.article.feedURL]];
        if (feed != nil) {
            CGImageRef favicon = NNWFaviconForFeed(feed.homePageURL, feed.faviconURL, NO);
            if (favicon != nil) {
                didShowFavicon = YES;
                RSDrawCGImageInRectWithBlendMode(favicon, rFavicon, kCGBlendModeNormal);
            }
            
        }
    }
    

    static NSColor *dateColor = nil;
    if (dateColor == nil)
        dateColor = [NSColor colorWithDeviceRed:157.0f/255.0f green:194.0f/255.0f blue:235.0f/255.0f alpha:1.0f];
    static NSColor *dateReadColor = nil;
    if (dateReadColor == nil)
        dateReadColor = dateColor;

    if (didShowFavicon) {
        rDate.origin.x = NSMaxX(rFavicon) + 4.0f;
        rDate.size.width -= (NSWidth(rFavicon) + 4.0f);
    }
    NSDate *date = self.article.datePublished;
    if (date == nil)
        date = self.article.dateModified;
    if (date == nil)
        date = self.article.dateArrived;
    if (date != nil) {
        NSMutableDictionary *dateAttributes = [NSMutableDictionary dictionary];
        [dateAttributes setObject:[self dateFont] forKey:NSFontAttributeName];
        if ([self.article.read boolValue])
            [dateAttributes setObject:dateReadColor forKey:NSForegroundColorAttributeName];
        else
            [dateAttributes setObject:dateColor forKey:NSForegroundColorAttributeName];
        NSString *dateOnlyString = [date rs_mediumDateOnlyString];
        BOOL shouldShowTime = NO;
        RSDateGroup dateGroup = [[RSDateManager sharedManager] groupForDate:date];
            NSShadow *dateShadow = [[NSShadow alloc] init];
            [dateShadow setShadowOffset:NSMakeSize(0.0f, -1.0f)];
            [dateShadow setShadowBlurRadius:1.0f];
            [dateShadow setShadowColor:[NSColor colorWithDeviceWhite:1.0f alpha:1.0f]];
            //[dateAttributes setObject:dateShadow forKey:NSShadowAttributeName];
        if (dateGroup == RSDateGroupYesterday || dateGroup == RSDateGroupToday)
            shouldShowTime = YES;
        if (shouldShowTime) {
            NSString *timeOnlyString = [date rs_mediumTimeOnlyString];
            if (dateGroup == RSDateGroupToday)
                dateOnlyString = NSLocalizedString(@"Today", @"Today");
            else if (dateGroup == RSDateGroupYesterday)
                dateOnlyString = NSLocalizedString(@"Yesterday", @"Yesterday");
            NSString *dateAndTimeString = [NSString stringWithFormat:@"%@ %@", dateOnlyString, timeOnlyString];
            NSMutableAttributedString *fullDateString = [[NSMutableAttributedString alloc] initWithString:dateAndTimeString attributes:dateAttributes];
            [fullDateString addAttribute:NSFontAttributeName value:[self timeFont] range:NSMakeRange([dateOnlyString length] + 1, [timeOnlyString length])];
            [fullDateString drawInRect:rDate];
            rDate.size.width = [fullDateString size].width;
        }
        else {
            [dateOnlyString drawInRect:rDate withAttributes:dateAttributes];
            rDate.size.width = [dateOnlyString sizeWithAttributes:dateAttributes].width;
        }
    }
    
    
    if (self.thumbnail == nil && self.logicalThumbnailURL != nil)
        self.thumbnail = (id)[[RSThumbnailController sharedController] thumbnailForURL:self.logicalThumbnailURL];
    
    CGRect rThumbnail = [self thumbnailBoxWithBounds:rBounds];
    if (self.thumbnail != nil && self.logicalThumbnailURL != nil) {
        if (CGRectIntersectsRect(r, rThumbnail))
            [self drawThumbnailInRect:rThumbnail];
    }
    if (self.thumbnail == nil && self.webclipIcon != nil && self.shouldShowWebClipIcon) {
        if (CGRectIntersectsRect(r, rThumbnail))
            [self drawWebclipIconInRect:rThumbnail];
    }

}


- (void)prepareForReuse {
    self.contextualMenuDelegate = nil;
    self.thumbnail = nil;
    self.webclipIcon = nil;
    self.logicalThumbnailURL = nil;
    self.article = nil;
    self.title = @"";
    self.selected = NO;
}


@end
