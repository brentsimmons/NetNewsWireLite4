//
//  NNWAdView.m
//  nnwiphone
//
//  Created by Brent Simmons on 9/7/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWAdView.h"
#import "BCDownloadImageRequest.h"
#import "BCDownloadRequest.h"
#import "NNWAppDelegate.h"
#import "NNWWebPageViewController.h"
#import "RSCache.h"


NSString *NNWAdTouchedNotification = @"NNWAdTouchedNotification";

@interface NNWAdLoader : NSObject {
	@private
	NSMutableArray *_ads;
	RSCache *_imageCache;
	BOOL _loadingAd;
}
+ (id)sharedAdLoader;
- (NSDictionary *)pullAd;
- (void)loadNewAd;
- (UIImage *)imageWithURLString:(NSString *)urlString;
@end

@implementation NNWAdLoader


+ (id)sharedAdLoader {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


- (id)init {
	if (![super init])
		return nil;
	_ads = [[NSMutableArray array] retain];
	_imageCache = [[RSCache cache] retain];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleImageDownloaded:) name:BCDownloadDidCompleteNotification object:nil];
	return self;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_ads release];
	[_imageCache release];
	[super dealloc];
}


- (void)handleImageDownloaded:(NSNotification *)note {
	BCDownloadImageRequest *downloadRequest = [note object];
	if (downloadRequest.downloadType != BCDownloadTypeAdImage || ![downloadRequest isKindOfClass:[BCDownloadImageRequest class]])
		return;
	NSString *urlString = [downloadRequest.url absoluteString];
	if (!urlString || !downloadRequest.image)
		return;
	[_imageCache setObject:downloadRequest.image forKey:urlString];
}


- (UIImage *)imageWithURLString:(NSString *)urlString {
	UIImage *image = [_imageCache objectForKey:urlString];
	if (image)
		return image;
	BCDownloadImageRequest *downloadRequest = [[[BCDownloadImageRequest alloc] initWithURL:[NSURL URLWithString:urlString]] autorelease];
	downloadRequest.downloadPriority = BCDownloadImmediately;
	downloadRequest.downloadType = BCDownloadTypeAdImage;
	[downloadRequest addToDownloadQueue];
	return nil;
}


- (NSDictionary *)pullAd {
	NSDictionary *ad = nil;
	@synchronized(_ads) {
		if (RSIsEmpty(_ads)) {
			[self loadNewAd];
			return nil;
		}
		ad = [[[_ads lastObject] retain] autorelease];
		if ([_ads count] < 2)
			[self loadNewAd];
		if ([self imageWithURLString:[ad objectForKey:@"imgURLString"]] == nil)
			return nil;
		[_ads removeLastObject];
	}
	return ad;
}


- (NSString *)pullLineJunkFromString:(NSString *)s {
	NSMutableString *fixedString = [[s mutableCopy] autorelease];
	while (true) {
		NSInteger stringLength = [fixedString length];
		if (stringLength < 2)
			break;
		NSInteger ixFirst = 0;
		unichar ch = [fixedString characterAtIndex:ixFirst];
		if (ch == ';' || ch == '"' || ch == '\n' || ch == '\r' || ch == '\'' || ch == '>') {
			[fixedString deleteCharactersInRange:NSMakeRange(ixFirst, 1)];
			continue;
		}
		break;
	}
	while (true) { /*end*/
		NSInteger stringLength = [fixedString length];
		if (stringLength < 2)
			break;
		NSInteger ixLast = stringLength - 1;
		unichar ch = [fixedString characterAtIndex:ixLast];
		if (ch == ';' || ch == '"' || ch == '\n' || ch == '\r' || ch == '\'' || ch == '>') {
			[fixedString deleteCharactersInRange:NSMakeRange(ixLast, 1)];
			continue;
		}
		break;
	}
	[fixedString replaceOccurrencesOfString:@"\\" withString:@"" options:0 range:NSMakeRange(0, [fixedString length])];
	[fixedString replaceOccurrencesOfString:@"\\" withString:@"" options:0 range:NSMakeRange(0, [fixedString length])];
	return fixedString;
}


- (NSString *)pullURLString:(NSString *)s attributeName:(NSString *)attributeName {
	NSString *attributeSeparator = [NSString stringWithFormat:@"%@=\"", attributeName];
	NSArray *components = [s componentsSeparatedByString:attributeSeparator];
	if (!components || [components count] < 2)
		return nil;
	s = [components objectAtIndex:1];
	components = [s componentsSeparatedByString:@" "];
	if (RSIsEmpty(components))
		return nil;
	NSString *urlString = nil;
	for (NSString *oneString in components) {
		if (![oneString hasPrefix:@"http://"])
			continue;
		urlString = oneString;
		urlString = [self pullLineJunkFromString:urlString];
		return urlString;
	}
	return nil;	
}


- (NSString *)pullImgURLString:(NSString *)s {
	return [self pullURLString:s attributeName:@"src"];
}


- (NSString *)pullURLString:(NSString *)s {
	return [self pullURLString:s attributeName:@"href"];
}


- (NSString *)pullAdText:(NSString *)s {
	NSMutableString *dest = [[s mutableCopy] autorelease];
	CFStringTrimWhitespace((CFMutableStringRef)dest);
	s = [NSString stripPrefix:dest prefix:@"'"];
	s = [NSString stripSuffix:s suffix:@";"];
	s = [NSString stripSuffix:s suffix:@"'"];
	s = RSStringReplaceAll(s, @"\\", @"");
	s = [NSString stringWithDecodedEntities:s];
	return [NSString rs_stringWithStrippedHTML:s maxCharacters:1000];
}


- (void)parseAdWithData:(NSData *)data {
	if (RSIsEmpty(data))
		return;
	NSString *rawAdText = [NSString stringWithUTF8EncodedData:data];
	if (RSStringIsEmpty(rawAdText))
		return;
	NSString *urlString = nil;
	NSString *imgURLString = nil;
	NSString *adText = nil;
	BOOL nextIsAdText = NO;
	NSArray *components = [rawAdText componentsSeparatedByString:@"advert+='"];
	if (RSIsEmpty(components) || [components count] < 2)
		return;
	for (NSString *oneString in components) {
		if (RSStringIsEmpty(imgURLString) && [oneString hasPrefix:@"<img"])
			imgURLString = [self pullImgURLString:oneString];
		if (RSStringIsEmpty(urlString) && [oneString hasPrefix:@"<a"])
			urlString = [self pullURLString:oneString];
		if (RSStringIsEmpty(adText) && nextIsAdText)
			adText = [self pullAdText:oneString];
		if ([oneString caseInsensitiveContains:@"p class=\"ads"])
			nextIsAdText = YES;
	}
	if (RSStringIsEmpty(imgURLString) || RSStringIsEmpty(urlString) || RSStringIsEmpty(adText))
		return;
	[self performSelectorOnMainThread:@selector(imageWithURLString:) withObject:imgURLString waitUntilDone:NO]; /*starts download if needed*/
	NSMutableDictionary *adDict = [NSMutableDictionary dictionary];
	[adDict setObject:imgURLString forKey:@"imgURLString"];
	[adDict setObject:urlString forKey:@"urlString"];
	[adDict setObject:adText forKey:@"adText"];
	@synchronized(_ads) {
		[_ads addObject:adDict];		
	}
}

static NSString *NNWDeckAdFormat = @"http://www.northmay.com/deck/deckNN_js.php?%@";

- (void)loadNewAd {
	if (app_delegate.offline || _loadingAd)
		return;
	_loadingAd = YES;
	[self performSelectorInBackground:@selector(loadAdInBackground) withObject:nil];
}


- (void)loadAdInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *timestampString = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970] * 1000.0f];
	NSArray *timestampStringComponents = [timestampString componentsSeparatedByString:@"."];
	timestampString = [timestampStringComponents objectAtIndex:0];
	NSString *urlString = [NSString stringWithFormat:NNWDeckAdFormat, timestampString];
	NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:10];
	[urlRequest setValue:app_delegate.userAgent forHTTPHeaderField:@"User-Agent"];
	[urlRequest setHTTPShouldHandleCookies:NO];
	NSInteger statusCode = -1;
	NSURLResponse *response = nil;
	NSError *error = nil;
	NSData *data = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&response error:&error];
	if (error && [error code] == NSURLErrorNotConnectedToInternet)
		[self postNotificationOnMainThread:BCNotConnectedToInternetNotification];
	if ([response respondsToSelector:@selector(statusCode)])
		statusCode = [(NSHTTPURLResponse *)response statusCode];
	if (statusCode != 200)
		goto loadAdInBackground_exit;
	[self postNotificationOnMainThread:BCConnectedToInternetNotification];
	(void)[self parseAdWithData:data];
loadAdInBackground_exit:
	_loadingAd = NO;
[pool drain];
}


@end


@interface NNWAdView ()
@property (nonatomic, retain) UILabel *adTextLabel;
@property (nonatomic, retain) UILabel *adsViaDeckLabel;
@property (nonatomic, retain) NSDictionary *adDict;
@property (nonatomic, retain) UIImageView *imageView;
@property (nonatomic, retain) UIImage *image;
- (id)initWithFrame:(CGRect)frame adDictionary:(NSDictionary *)adDictionary;
@end

@implementation NNWAdView

@synthesize adTextLabel = _adTextLabel, adsViaDeckLabel = _adsViaDeckLabel, adDict = _adDict, imageView = _imageView, image = _image;

#pragma mark Class Methods

+ (NSInteger)adViewHeight {
	return 90;
}


+ (NNWAdView *)adViewWithFrameIfConnected:(CGRect)frame {
	NSDictionary *adDict = [[NNWAdLoader sharedAdLoader] pullAd];
	if (!adDict)
		return nil;
	return [[[self alloc] initWithFrame:frame adDictionary:adDict] autorelease];
}


#pragma mark Init

- (id)initWithFrame:(CGRect)frame adDictionary:(NSDictionary *)adDictionary {
	if (![super initWithFrame:frame])
		return nil;
	_adDict = [adDictionary retain];
	self.contentMode = UIViewContentModeRedraw;
	self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self layoutSubviews];
	[self setNeedsLayout];
	[self setNeedsDisplay];
	self.userInteractionEnabled = YES;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleImageDownloaded:) name:BCDownloadDidCompleteNotification object:nil];
//	_webView = [[[UIWebView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)] autorelease];
//	UIScrollView *scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)] autorelease];
//	scrollView.bounces = NO;
//	scrollView.contentSize = frame.size;
//	[self addSubview:scrollView];
//	[scrollView addSubview:_webView];
//	scrollView.contentMode = UIViewContentModeRedraw;
//	_webView.contentMode = UIViewContentModeRedraw;
//	_webView.backgroundColor = [UIColor colorWithWhite:0.933 alpha:1.000];
//	scrollView.backgroundColor = [UIColor colorWithWhite:0.933 alpha:1.000];
//	//_webView.scalesPageToFit = YES;
//	_webView.dataDetectorTypes = UIDataDetectorTypeAll;
//	_webView.delegate = self;
//	[self performSelectorOnMainThread:@selector(loadAd) withObject:nil waitUntilDone:NO];
//	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//	_webView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_adDict release];
	[_adTextLabel release];
	[_adsViaDeckLabel release];
	[_imageView release];
	[_image release];
//	_webView.delegate = nil;
//	[_webView stopLoading];
//	[_webView retain];
//	[_webView performSelector:@selector(autorelease) withObject:nil afterDelay:3.0]; /*Prevent crashes*/
	[super dealloc];
}


#pragma mark Actions

- (void)adTouched:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:NNWAdTouchedNotification object:self userInfo:self.adDict];
}




- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!RSIsEmpty([event touchesForView:self]))
		[self adTouched:self];
}


#pragma mark Ad


//NSString *_adHTMLText = @"<html><head><meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; minimum-scale=1.0;\"/><style>body{font-family:Helvetica, sans-serif;font-size:10.5px;margin:0px;border-toxp:1px solid #999;background-color:#eee;background: -webkit-gradient(linear, left top, left bottom, from(#fff), to(#ddd), color-stop(0.5, #e3e3e3));} .ad {float:right;background-color:transparent} .ads {padding-left:2px;padding-top:4px;text-align:right;text-shadow:#fff 0px 1px 1px;}img {max-height:90px;max-width:auto;min-width:90px;margin-left:8px;} a, a:link, a:visited {text-decoration:none;color:#003399}.via{padding-left:2px;margin-top:-8px;text-align:right;vertical-align:bottom;color: #333;text-shadow:#fff 0px 1px 1px;}</style><title></title><body style='font-size:11.5px'><script type=\"text/javascript\">\n(function(id) {\ndocument.write('<script type=\"text/javascript\" src=\"' + 'http://www.northmay.com/deck/deck' + id + '_js.php?' + (new Date().getTime()) + '\"></' + 'script>');\n})(\"NN\");\n</script><p class='via' >Ads via <a href='http://decknetwork.net/' style='text-decoration:none;text-shadow:#fff 0px 1px 1px'>The Deck</a></p></body></html>";
////NSString *_adHTMLText = @"<html><head><style>.ad {float:left}.ads {float:right}</style><script>document.onload = function(){document.ontouchmove = function(e){e.prevent.default();}};</script><title></title><body style='font-size:11.5px' bgcolor=\"#EBEBEB\"><center><script type=\"text/javascript\">\n(function(id) {\ndocument.write('<script type=\"text/javascript\" src=\"' + 'http://www.northmay.com/deck/deck' + id + '_js.php?' + (new Date().getTime()) + '\"></' + 'script>');\n})(\"NN\");\n</script><p style='font-size:11px'>Ads via <a href='http://decknetwork.net/' style='text-decoration:none;text-shadow:#fff 0px 1px 1px'>The Deck</a></p></center></body></html>";
//
//- (void)loadAd {
//	static NSURL *baseURL = nil;
//	if (!baseURL)
//		baseURL = [[NSURL URLWithString:@"http://www.northmay.com/deck/"] retain];
//	[_webView loadHTMLString:_adHTMLText baseURL:baseURL];
//}


#pragma mark Layout

#define kNNWImageWidth 90
#define kNNWImageHeight 90
#define kNNWMarginLeft 4
#define KNNWImageMarginLeft 6
#define kNNWMarginTop 4
#define kNNWMarginBottom 4
#define kNNWDeckLabelHeight 12

- (CGRect)rectForAdTextWithImageSize:(CGSize)imageSize {	
	return CGRectMake(kNNWMarginLeft, kNNWMarginTop, self.bounds.size.width - (kNNWMarginLeft + KNNWImageMarginLeft + imageSize.width), self.bounds.size.height - (kNNWMarginTop + kNNWMarginBottom + kNNWDeckLabelHeight));
}


- (CGRect)rectForAdsViaDeckWithImageSize:(CGSize)imageSize {
	return CGRectMake(kNNWMarginLeft, CGRectGetMaxY(self.bounds) - (kNNWMarginBottom + kNNWDeckLabelHeight), self.bounds.size.width - (kNNWMarginLeft + KNNWImageMarginLeft + imageSize.width), kNNWDeckLabelHeight);
}



- (CGRect)rectForImageView {
	if (!self.image)
		self.image = [[NNWAdLoader sharedAdLoader] imageWithURLString:[self.adDict objectForKey:@"imgURLString"]];
	CGSize imageSize = CGSizeMake(kNNWImageWidth, kNNWImageHeight);
	if (self.image)
		imageSize = self.image.size;
	if (imageSize.height > kNNWImageHeight + 1) {
		self.image = [UIImage scaledImage:self.image toSize:CGSizeMake(kNNWImageWidth, kNNWImageHeight)];
		self.imageView.image = self.image;
		imageSize = self.image.size;
	}
	CGRect newFrame = CGRectMake(CGRectGetMaxX(self.bounds) - imageSize.width, 0, imageSize.width, imageSize.height);
	if (!CGRectEqualToRect(newFrame, self.imageView.frame))
		[self setNeedsDisplay];
	return newFrame;
}


- (void)layoutSubviews {
	CGRect rImageView = [self rectForImageView];
	if (!self.adTextLabel) {
		self.adTextLabel = [[[UILabel alloc] initWithFrame:[self rectForAdTextWithImageSize:rImageView.size]] autorelease];
		self.adTextLabel.text = [self.adDict objectForKey:@"adText"];
		[self addSubview:self.adTextLabel];
		self.adTextLabel.backgroundColor = [UIColor clearColor];
		self.adTextLabel.font = [UIFont systemFontOfSize:12.5];
		self.adTextLabel.numberOfLines = 0;
		self.adTextLabel.textColor = [UIColor blackColor];
		//self.adTextLabel.textColor = [UIColor whiteColor];
		//self.adTextLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.7];
		self.adTextLabel.shadowOffset = CGSizeMake(0, 1);
		self.adTextLabel.textAlignment = UITextAlignmentCenter;
		[self setNeedsDisplay];
	}
	self.adTextLabel.frame = [self rectForAdTextWithImageSize:rImageView.size];
	if (!self.adsViaDeckLabel) {
		self.adsViaDeckLabel = [[[UILabel alloc] initWithFrame:[self rectForAdsViaDeckWithImageSize:rImageView.size]] autorelease];
		self.adsViaDeckLabel.text = @"Ads via The Deck";
		[self addSubview:self.adsViaDeckLabel];
		self.adsViaDeckLabel.backgroundColor = [UIColor clearColor];
		self.adsViaDeckLabel.font = [UIFont systemFontOfSize:11.0];
		self.adsViaDeckLabel.numberOfLines = 1;
		self.adsViaDeckLabel.textColor = [UIColor colorWithWhite:0.0 alpha:1.0];
		//self.adsViaDeckLabel.textColor = [UIColor whiteColor];
		//self.adsViaDeckLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.7];
		self.adsViaDeckLabel.shadowOffset = CGSizeMake(0, 1);
		self.adsViaDeckLabel.textAlignment = UITextAlignmentCenter;
		[self setNeedsDisplay];
	}
	self.adsViaDeckLabel.frame = [self rectForAdsViaDeckWithImageSize:rImageView.size];
	if (!self.imageView) {
		self.imageView = [[[UIImageView alloc] initWithImage:nil] autorelease];
		self.imageView.frame = [self rectForImageView];
		[self addSubview:self.imageView];
		[self setNeedsDisplay];
	}
	if (!self.imageView.image) {
		if (!self.image)
			self.image = [[NNWAdLoader sharedAdLoader] imageWithURLString:[self.adDict objectForKey:@"imgURLString"]];
		if (self.image) {
			self.imageView.image = self.image;
			[self setNeedsDisplay];
		}
	}
	self.imageView.frame = rImageView;
}


- (void)handleImageDownloaded:(NSNotification *)note {
	[self setNeedsLayout];
	[self setNeedsDisplay];
}


#pragma mark Drawing

- (BOOL)isOpaque {
	return NO;
}


- (void)drawRect:(CGRect)r {
	static UIImage *backgroundImage = nil;
	if (!backgroundImage)
//		backgroundImage = [[UIImage grayBackgroundGradientImageWithStartGray:0.968 endGray:0.92 topLineGray:1.0 size:CGSizeMake(self.bounds.size.width / 4, self.bounds.size.height)] retain];
	backgroundImage = [[UIImage grayBackgroundGradientImageWithStartGray:0.968 endGray:0.9 topLineGray:1.0 size:CGSizeMake(self.bounds.size.width / 4, self.bounds.size.height)] retain];
	[backgroundImage drawInRect:self.bounds];
//	UIImage *image = [[NNWAdLoader sharedAdLoader] imageWithURLString:[self.adDict objectForKey:@"imgURLString"]];
//	CGSize imageSize = image.size;
//	
//	if (image)
//		[image drawInRect:[self rectForImage:image]];
}


@end
