//
//  BCConfigData.m
//  bobcat
//
//  Created by Brent Simmons on 9/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BCConfigData.h"
#import "NGFeedSpecifier.h"
#import "RSCache.h"
#import "RSDataAccount.h"
#import "RSDownloadOperation.h"
#import "RSOperationController.h"
#import "RSWebCacheController.h"
#import "TLStrings.h"


NSString *BCFeedURLStringKey = @"xmlUrl";
NSString *BCFeedUsernameKey = @"username";
NSString *BCFeedPasswordKey = @"password";
NSString *BCNewsItemList_ThumbnailMaxWidth = @"NewsItemList_ThumbnailMaxWidth";
NSString *BCNewsItemList_MaxDescriptionLines = @"NewsItemList_MaxDescriptionLines";
NSString *BCNewsItemList_MaxTitleLines = @"NewsItemList_MaxTitleLines";
NSString *BCNewsItemListFeedURL = @"xmlUrl";
NSString *BCNewsItemHTMLTemplateName = @"NewsItemHTML_TemplateName";
NSString *BCWebAdsUseMedialets = @"WebAds_UseMedialets";
NSString *BCWebAdsUseQuattro = @"WebAds_UseQuattro";
NSString *TLWebAdsUseGlam = @"WebAds_UseGlam";
NSString *TLGlamAfid = @"WebAds_GlamAfid";
NSString *TLGlamAppName = @"WebAds_GlamAppName";
NSString *BCTapLynxLicenseKey = @"TapLynx_LicenseKey";
NSString *BCTapLynxDelegateClassKey = @"TapLynx_DelegateClass";
NSString *BCNewsItemList_FolderTextColor = @"NewsItemList_FolderTextColor";
NSString *BCAnalyticsUseMedialets = @"Analytics_UseMedialets";
NSString *BCAnalyticsUsePinchMedia = @"Analytics_UsePinchMedia";
NSString *BCPinchMediaAppID = @"PinchMedia_AppID";
NSString *BCAnalyticsUseFlurry = @"Analytics_UseFlurry";
NSString *BCPushNotificationsUsePushIO = @"PushNotifications_UsePushIO";
NSString *BCPushIOAPIToken = @"PushIO_APIToken";
NSString *BCPushNotificationsTypeAlert = @"PushNotifications_AlertsEnabled";
NSString *BCPushNotificationsTypeSound = @"PushNotifications_SoundEnabled";
NSString *BCPushNotificationsTypeBadge = @"PushNotifications_BadgeEnabled";
NSString *BCFlurryAppID = @"Flurry_AppID";
NSString *BCMedialetsAppID = @"Medialets_AppID";
NSString *TLTabTypeKey = @"Type";
NSString *TLTabTypeVideoBrowser = @"video_browser"; // The Big App Show
NSString *TLTabTypeHorizontalBrowser = @"horizontal_browser"; //For general use
NSString *TLMovieControlMode = @"MovieControlMode";
NSString *TLNewsItemsList_HideDates = @"NewsItemList_HideDates";
NSString *TLEmailLink_TitleTemplate = @"EmailLink_TitleTemplate";
NSString *TLEmailLink_BodyTemplate = @"EmailLink_BodyTemplate";
NSString *TLEmailHTML_BodyTemplate = @"EmailHTML_BodyTemplate";
NSString *TLPhotoGallery_HideCaptions = @"PhotoGallery_HideCaptions";
NSString *TLTabIdentifier = @"TabIdentifier";
NSString *TLTitle = @"Title";
NSString *TLNewsItemList_FolderGroupName = @"NewsItemList_FolderGroupName";
NSString *TLPhotoGallery_GridViewBackgroundColor = @"PhotoGallery_GridViewBackgroundColor";
NSString *TLNewsItemsList_RightArrowImageName = @"NewsItemList_RightArrowImageName";
NSString *TLNewsItemsList_HideNavbarTitle = @"NewsItemList_HideNavbarTitle";
NSString *TLTwitterConsumerKey = @"Twitter_ConsumerKey";
NSString *TLTwitterConsumerSecret = @"Twitter_ConsumerSecret";
NSString *TLNewsItemHTML_OpenInSafariCommand = @"NewsItemHTML_OpenInSafariCommand";
NSString *TLHome_ShowHighlightsView = @"Highlights_Show";
NSString *TLHome_HighlightsViewURL = @"Highlights_URL";
NSString *TLToolbarStyle = @"Toolbar_Style";
NSString *TLToolbarStyleDefault = @"default";
NSString *TLToolbarStyleBlack = @"black";
NSString *TLToolbarTintColor = @"Toolbar_Color";
NSString *TLToolbarImageName = @"Toolbar_Image";
NSString *TLToolbarScaleImageToFill = @"Toolbar_ImageScaleToFill";
NSString *TLHome_RowBackgroundColor = @"Home_RowBackgroundColor";
NSString *TLTraySummaryColor = @"Home_TraySummaryColor";
NSString *TLTrayTitleColor = @"Home_TrayTitleColor";
NSString *TLTrayTitleUnreadColor = @"Home_TrayTitleUnreadColor";
NSString *TLHome_SourceBackgroundImage = @"Home_SourceBackgroundImage";
NSString *TLHome_SourceScaleImageToFill = @"Home_SourceScaleImageToFill";
NSString *TLTabImageName = @"TabImageName";

/*iPad*/
NSString *TLTabHeight = @"Tab_RowHeight";
NSString *TLTabArticleWidth = @"Tab_ArticleWidth";
NSString *TLTabArticleTitleFontSize = @"Tab_ArticleTitleFontSize";
NSString *TLHighlightsWidth = @"Highlights_Width";
NSString *TLTabSourceWidth = @"Source_Width";
NSString *TLTabSourceTitle_BaseName = @"Source_Title";
NSString *TLTabSourceTitleColor = @"Source_TitleColor";
NSString *TLTabSourceImage_BaseName = @"Source_Image";
NSString *TLThumbnailRectBaseName = @"Tab_ArticleThumbnail";
NSString *TLTitleRectBaseName = @"Tab_ArticleTitle";
NSString *TLDateRectBaseName = @"Tab_ArticleDate";
NSString *TLDescriptionRectBaseName = @"Tab_ArticleDescription";
NSString *TLTitleRectNoThumbnailBaseName = @"Tab_ArticleTitleNoThumbnail";
NSString *TLDateRectNoThumbnailBaseName = @"Tab_ArticleDateNoThumbnail";
NSString *TLDescriptionRectNoThumbnailBaseName = @"Tab_ArticleDescriptionNoThumbnail";
NSString *TLArticle_CommandsBackgroundColor = @"Article_CommandsBackgroundColor";
NSString *TLArticle_BaseName = @"Article_";
NSString *TLArticle_CommandsImageName = @"Article_CommandsImageName";
NSString *TLArticle_CommandsScaleImageToFill = @"Article_CommandsScaleImageToFill";
NSString *TLArticle_TemplateName = @"Article_TemplateName";


@interface NSObject (TLSecretsStub)
+ (NSString *)twitterConsumerKey;
+ (NSString *)twitterConsumerSecret;
+ (NSString *)facebookAppID;
@end


@interface BCConfigData ()

@property (nonatomic, retain, readwrite) NSDictionary *configDictionary;
@property (nonatomic, retain, readwrite) NSArray *tabs;
@property (nonatomic, retain, readwrite) UIImage *staticAdImage;
@property (nonatomic, assign, readwrite) BOOL showAds;
@property (nonatomic, assign, readwrite) BOOL useStaticAdImage;
@property (nonatomic, assign, readwrite) BOOL useBlackNavController;
@property (nonatomic, assign, readwrite) BOOL useCustomColorForNavController;
@property (nonatomic, retain, readwrite) UIColor *customColorForNavController;
@property (nonatomic, retain, readwrite) NSString *appURL;
@property (nonatomic, retain) NSDictionary *defaultsDictionary;
@property (nonatomic, assign, readwrite) BOOL showUnreadCounts;
@property (nonatomic, assign, readwrite) BOOL allFeedsAreLocal;
@property (nonatomic, assign, readwrite) BOOL favoritesFeatureEnabled;
@property (nonatomic, assign, readwrite) BOOL landscapeDisabled;
@property (nonatomic, assign, readwrite) UIBarStyle toolbarStyle;
@property (nonatomic, retain, readwrite) UIColor *toolbarColor;
@property (nonatomic, retain, readwrite) NSString *toolbarImageName;
@property (nonatomic, assign, readwrite) BOOL scaleToolbarImageToFill;
@property (nonatomic, assign, readwrite) CGFloat highlightsWidth;
@property (nonatomic, assign, readwrite) CGFloat sourceWidth;

- (void)_readConfigFile;
- (void)_setupDefaults;
- (BOOL)_webconfigEnabledInDictionary:(NSDictionary *)d;
- (NSDictionary *)_cachedWebConfigFile;
- (BOOL)_shouldUseWebConfigDictionary:(NSDictionary *)webconfigDict insteadOfEmbeddedDictionary:(NSDictionary *)embeddedDict;
- (void)_downloadImagesInConfigFile:(NSDictionary *)d;
- (void)downloadAppArtworkWithURLString:(NSString *)urlString;

@end


@implementation BCConfigData

@synthesize configDictionary = _configDictionary, tabs = _tabs;
@synthesize staticAdImage = _staticAdImage, showAds = _showAds, useStaticAdImage = _useStaticAdImage;
@synthesize useBlackNavController = _useBlackNavController, useCustomColorForNavController = _useCustomColorForNavController;
@synthesize customColorForNavController = _customColorForNavController, appURL = _appURL;
@synthesize defaultsDictionary = _defaultsDictionary, showUnreadCounts = _showUnreadCounts, allFeedsAreLocal = _allFeedsAreLocal;
@synthesize customColorForMoreNavController = _customColorForMoreNavController;
@synthesize useCustomColorForMoreNavController = _useCustomColorForMoreNavController;
@synthesize useBlackForMoreNavController = _useBlackForMoreNavController, favoritesFeatureEnabled = _favoritesFeatureEnabled;
@synthesize landscapeDisabled = _landscapeDisabled;
@synthesize toolbarStyle;
@synthesize toolbarImageName;
@synthesize toolbarColor;
@synthesize scaleToolbarImageToFill;
@synthesize highlightsWidth;
@synthesize sourceWidth;


#pragma mark Class Methods

+ (BCConfigData *)sharedData {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	if (![super init])
		return nil;
	[self _setupDefaults];
	[self _readConfigFile];
	_templateCache = [[RSCache alloc] init];
	[self performSelectorOnMainThread:@selector(_downloadWebConfigFileIfNeeded) withObject:nil waitUntilDone:NO];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[_tabs release];
	[_staticAdImage release];
	[_customColorForNavController release];
	[_appURL release];
	[_templateCache release];
	[toolbarColor release];
	[toolbarImageName release];
	[super dealloc];
}


#pragma mark Defaults

- (void)_setupDefaults {
	self.showAds = NO;
	self.useStaticAdImage = NO;
	self.useBlackNavController = NO;
	self.useCustomColorForNavController = NO;
	self.toolbarStyle = UIBarStyleDefault;
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	[d setObject:@"#333333" forKey:@"NewsItemList_ReadColor"];
	[d setObject:@"#2262F5" forKey:@"NewsItemList_UnreadColor"];
	[d setObject:@"#000000" forKey:@"NewsItemList_DescriptionColor"];
	[d setObject:@"#666666" forKey:@"NewsItemList_DateColor"];
	[d setObject:[NSNumber numberWithInt:16] forKey:@"NewsItemList_TitleFontSize"];
	[d setObject:@"#2262F5" forKey:@"NewsItemHTML_TitleBackgroundColor"];
	[d setObject:@"#1050E0" forKey:@"NewsItemHTML_TitleBackgroundBottomBorderColor"];
	[d setObject:@"#FFFFFF" forKey:@"NewsItemHTML_TitleColor"];
	[d setObject:@"#CCCCCC" forKey:@"NewsItemHTML_DatelineColor"];
	[d setObject:@"#000000" forKey:@"NewsItemHTML_DescriptionColor"];
	[d setObject:@"#FFFFFF" forKey:@"NewsItemHTML_BackgroundColor"];
	[d setObject:@"#2262F5" forKey:@"NewsItemHTML_LinkColor"];
	[d rs_setBool:YES forKey:TLNewsItemHTML_OpenInSafariCommand];
	[d setObject:@"#555555" forKey:@"PhotoGallery_HeaderColor"];
	[d setObject:@"chevron_light.png" forKey:@"NewsItemHTML_ChevronImage"];
	[d setObject:(id)kCFBooleanTrue forKey:@"NewsItemList_Group"];
	[d setObject:[NSNumber numberWithInt:30] forKey:@"Refresh_Minutes"];
	[d setObject:[NSNumber numberWithInt:50] forKey:@"WebAds_Height"];
	[d setObject:[NSNumber numberWithInt:300] forKey:@"WebAds_Width"];
	[d rs_setBool:NO forKey:@"NewsItemHTML_hideFeedName"];
	[d rs_setBool:NO forKey:@"NewsItemHTML_hideEmailAddress"];
	[d setObject:@"blue" forKey:@"MoreNavController_style"];
	[d setObject:@"#666666" forKey:@"MoreNavController_color"];
	[d setObject:@"left" forKey:@"NavController_backgroundImageAlignment"];
	[d setObject:@"left" forKey:@"NewsItemList_RefreshButtonPrimaryTabPlacement"];
	[d setObject:@"left" forKey:@"NewsItemList_RefreshButtonNonPrimaryTabPlacement"];
	[d rs_setBool:NO forKey:@"NewsItemList_RefreshButton"];
	[d setObject:@"static" forKey:@"WebAds_Type"];
	[d setObject:@"[[title]]" forKey:TLEmailLink_TitleTemplate];
	[d setObject:@"[[body]]" forKey:TLEmailLink_BodyTemplate];
	[d setObject:@"F0F0F0" forKey:@"Ad_GradientStartColor"];
	[d setObject:@"E0E0E0" forKey:@"Ad_GradientEndColor"];
	[d setObject:@"F9F9F9" forKey:@"Ad_GradientTopLine"];
	[d rs_setBool:NO forKey:@"WebConfig_Enabled"];
	[d setObject:[NSNumber numberWithInteger:75] forKey:@"PhotoGallery_TargetSizeK"];
	[d setObject:[NSDate distantPast] forKey:@"WebConfig_Date"];
	[d setObject:[NSNumber numberWithInteger:60 * 24] forKey:@"WebConfig_MinutesBetweenChecks"];
	[d setObject:[NSNumber numberWithInteger:3] forKey:@"Downloads_MaxConcurrent"];
	[d rs_setBool:YES forKey:@"NewsItemHTML_PostToTwitterCommand"];
	[d setObject:@"CCCCCC" forKey:TLPhotoGallery_GridViewBackgroundColor];
	[d setObject:@"chevron-single-right.png" forKey:TLNewsItemsList_RightArrowImageName];
	[d setObject:TLToolbarStyleDefault forKey:TLToolbarStyle];
	[d setObject:[NSNumber numberWithFloat:320.0f] forKey:TLHighlightsWidth];
	[d setObject:@"666666" forKey:TLArticle_CommandsBackgroundColor];
	[d setObject:[NSNumber numberWithFloat:0.7f] forKey:@"Article_FadeAnimationDuration"];
	[d rs_setBool:YES forKey:@"Tab_ArticleShowThumbnails"];
	[d rs_setBool:YES forKey:@"Toolbar_ButtonsIncludeRefresh"];
	self.defaultsDictionary = [[d copy] autorelease];
}


#pragma mark Reading File

- (NSString *)configFileName {
	if (RSRunningOniPad())
		return @"NGConfig-iPad";
	return @"NGConfig";
}


- (void)_readConfigFile {
	NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[self configFileName] ofType:@"plist"]];
	if ([self _webconfigEnabledInDictionary:d]) {
		NSDictionary *webConfigDict = [self _cachedWebConfigFile];
		if ([self _shouldUseWebConfigDictionary:webConfigDict insteadOfEmbeddedDictionary:d]) {
			d = webConfigDict;
			[self performSelectorOnMainThread:@selector(_downloadImagesInConfigFile:) withObject:d waitUntilDone:NO];
		}
	}
	self.configDictionary = d;
	self.tabs = [d objectForKey:@"tabs"];
	if ([d objectForKey:@"Ads_StaticImageName"])
		self.staticAdImage = [UIImage imageNamed:[d objectForKey:@"Ads_StaticImageName"]];
	self.showAds = [d rs_boolForKey:@"Ads_Show"];
	self.useStaticAdImage = [d rs_boolForKey:@"Ads_UseStaticImage"];
	self.landscapeDisabled = [d rs_boolForKey:@"Landscape_Disable"];
	if ([[d objectForKey:@"NavController_style"] isEqual:@"black"])
		self.useBlackNavController = YES;
	else if ([[d objectForKey:@"NavController_style"] isEqual:@"custom"]) {
		self.useCustomColorForNavController = YES;
		self.customColorForNavController = [UIColor rs_colorWithHexString:[d objectForKey:@"NavController_color"]];
	}
	self.appURL = [d objectForKey:@"AppURL"];
	self.showUnreadCounts = [d rs_boolForKey:@"ShowUnreadCounts"];
	if ([d objectForKey:@"allFeedsAreLocal"])
		self.allFeedsAreLocal = [d rs_boolForKey:@"allFeedsAreLocal"];
	self.favoritesFeatureEnabled = NO;//[d boolForKey:@"Favorites"];
	if ([[d objectForKey:TLToolbarStyle] isEqualToString:TLToolbarStyleBlack])
		self.toolbarStyle = UIBarStyleBlack;
	else
		self.toolbarStyle = UIBarStyleDefault;
	NSString *toolbarTintColor = [d objectForKey:TLToolbarTintColor];
	if (!RSStringIsEmpty(toolbarTintColor))
		self.toolbarColor = [UIColor rs_colorWithHexString:toolbarTintColor];
	if (!RSStringIsEmpty([d objectForKey:TLToolbarImageName]))
		self.toolbarImageName = [d objectForKey:TLToolbarImageName];
	self.scaleToolbarImageToFill = [d rs_boolForKey:TLToolbarScaleImageToFill];
	if ([d objectForKey:TLHighlightsWidth] == nil)
		self.highlightsWidth = 320.0f;
	else
		self.highlightsWidth = [[d objectForKey:TLHighlightsWidth] floatValue];
	if ([d objectForKey:TLTabSourceWidth] == nil)
		self.sourceWidth = 128;
	else
		self.sourceWidth = [[d objectForKey:TLTabSourceWidth] floatValue];
	if ([d rs_boolForKey:BCWebAdsUseQuattro])
		NSLog(@"WARNING: Quattro ads are no longer supported, since Quattro has been purchased by Apple and is no longer updating their SDK. If you still require Quattro, you can build using TapLynx 1.3.4 and an older version of Xcode (3.2.2 or earlier).");
}


#pragma mark Web Config

- (UIImage *)artworkImageWithName:(NSString *)imageName {
	if ([imageName hasPrefix:@"http://"]) {
		NSData *data = [[RSPermanentWebCacheController sharedController] cachedObjectAtURL:[NSURL URLWithString:imageName]];
		if (data != nil) {
			UIImage *image = [UIImage imageWithData:data];
			if (image != nil)
				return image;
		}
		[self downloadAppArtworkWithURLString:imageName];
		return nil;
	}
	return [UIImage imageNamed:imageName];	
}


- (BOOL)_webconfigEnabledInDictionary:(NSDictionary *)d {
	id obj = [d objectForKey:@"WebConfig_Enabled"];
	if (!obj)
		return NO;
	obj = [d objectForKey:@"WebConfig_URL"];
	if (!obj)
		return NO;
	return [d rs_boolForKey:@"WebConfig_Enabled"];
}


- (NSString *)_webconfigFilePath {
	static NSString *webconfigFilePath = nil;
	if (!webconfigFilePath)
		webconfigFilePath = [RSAppSupportFilePath(@"WebConfig.plist") retain];
	return webconfigFilePath;
}


- (void)_addDownloadableObjectWithKey:(NSString *)key inDictionary:(NSDictionary *)d toArray:(NSMutableArray *)anArray {
	NSString *s = [d objectForKey:key];
	if (RSStringIsEmpty(s) || ![s hasPrefix:@"http://"])
		return;
	[anArray addObject:s];
}


- (void)appArtworkDidDownload:(RSDownloadOperation *)operation {
	
}


- (void)downloadAppArtworkWithURLString:(NSString *)urlString {
	RSDownloadOperation *operation = [[[RSDownloadOperation alloc] initWithURL:[NSURL URLWithString:urlString] delegate:self callbackSelector:@selector(appArtworkDidDownload:) parser:nil useWebCache:YES] autorelease];
	operation.usePermanentWebCache = YES;
	operation.operationObject = [NSURL URLWithString:urlString];
	operation.operationType = RSOperationTypeDownloadWebConfigFile;
	[operation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	RSAddOperationIfNotInQueue(operation);
}


- (void)_downloadImagesInConfigFile:(NSDictionary *)d {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:@selector(_downloadImagesInConfigFile:) withObject:d waitUntilDone:NO];
		return;
	}
	NSArray *tabs = [d objectForKey:@"tabs"];
	if (RSIsEmpty(tabs))
		return;
	NSMutableArray *urls = [NSMutableArray arrayWithCapacity:50];
	for (NSDictionary *oneTab in tabs) {
		[self _addDownloadableObjectWithKey:@"NavController_backgroundImage" inDictionary:oneTab toArray:urls];
		[self _addDownloadableObjectWithKey:@"TabImageName" inDictionary:oneTab toArray:urls];		
	}
	if (RSIsEmpty(urls))
		return;
	for (NSString *oneURLString in urls)
		[self downloadAppArtworkWithURLString:oneURLString];
}


- (void)_writeFileInBackgroundThenDownloadImages:(NSDictionary *)fileDict {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSError *error = nil;
	[[fileDict objectForKey:@"data"] writeToFile:[fileDict objectForKey:@"f"] options:NSAtomicWrite error:&error];
	[self _downloadImagesInConfigFile:fileDict];
	[pool drain];
}



- (void)webConfigFileDidDownload:(RSDownloadOperation *)operation {
	if (RSIsEmpty(operation.responseBody) || operation.statusCode != 200)
		return;
	NSString *f = [self _webconfigFilePath];
	[NSThread detachNewThreadSelector:@selector(_writeFileInBackgroundThenDownloadImages:) toTarget:self withObject:[NSDictionary dictionaryWithObjectsAndKeys:f, @"f", operation.responseBody, @"data", nil]];
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"webConfigLastDownloadDate"];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWebConfigDidDownload];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
}


- (void)_downloadWebConfig {
	NSString *urlString = [self stringWithName:@"WebConfig_URL" tab:nil];
	if (RSStringIsEmpty(urlString))
		return;
	RSDownloadOperation *downloadOperation = [[[RSDownloadOperation alloc] initWithURL:[NSURL URLWithString:urlString] delegate:self callbackSelector:@selector(webConfigFileDidDownload:) parser:nil useWebCache:NO] autorelease];
	[downloadOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
	downloadOperation.operationType = RSOperationTypeDownloadWebConfigFile;
	RSAddOperationIfNotInQueue(downloadOperation);
}


- (NSDictionary *)_cachedWebConfigFile {
	return [NSDictionary dictionaryWithContentsOfFile:[self _webconfigFilePath]];
}


- (BOOL)_shouldUseWebConfigDictionary:(NSDictionary *)webconfigDict insteadOfEmbeddedDictionary:(NSDictionary *)embeddedDict {
	NSDate *dWebConfig = [webconfigDict objectForKey:@"WebConfig_Date"];
	NSDate *dEmbedded = [embeddedDict objectForKey:@"WebConfig_Date"];
	if (!dWebConfig && !dEmbedded)
		return NO;
	if (!dWebConfig)
		dWebConfig = [NSDate distantPast];
	if (!dEmbedded)
		dEmbedded = [NSDate distantPast];
	return [dWebConfig compare:dEmbedded] == NSOrderedDescending;
}


- (void)_downloadWebConfigFileIfNeeded {
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:kWebConfigDidDownload];
	if (![self _webconfigEnabledInDictionary:self.configDictionary])
		return;
	NSDate *dateLastDownloadedWebConfigFile = [[NSUserDefaults standardUserDefaults] objectForKey:@"webConfigLastDownloadDate"];
	if (!dateLastDownloadedWebConfigFile)
		dateLastDownloadedWebConfigFile = [NSDate distantPast];
	NSInteger minutesBetweenChecks = [self integerWithName:@"WebConfig_MinutesBetweenChecks" tab:nil];
	NSDate *checkTime = [[[NSDate alloc] initWithTimeInterval:minutesBetweenChecks * 60 sinceDate:dateLastDownloadedWebConfigFile] autorelease];
	if ([checkTime compare:[NSDate date]] == NSOrderedAscending)
		[self _downloadWebConfig];
}


#pragma mark Per-tab config

/*If not specified in the tab, inherit from top-level specification*/

- (BOOL)useBlackNavControllerForTab:(NSDictionary *)tabDictionary {
	NSString *navControllerStyle = [tabDictionary objectForKey:@"NavController_style"];
	if (RSStringIsEmpty(navControllerStyle))
		return self.useBlackNavController;
	return [navControllerStyle isEqualToString:@"black"];
}


- (BOOL)useCustomColorForNavControllerForTab:(NSDictionary *)tabDictionary {
	NSString *navControllerStyle = [tabDictionary objectForKey:@"NavController_style"];
	if (RSStringIsEmpty(navControllerStyle))
		return self.useCustomColorForNavController;
	return [navControllerStyle isEqualToString:@"custom"];
}


- (BOOL)useCustomColorForMoreNavController {
	NSString *navControllerStyle = [self stringWithName:@"MoreNavController_style" tab:nil];
	return !RSStringIsEmpty(navControllerStyle) && [navControllerStyle isEqualToString:@"custom"];	
}


- (BOOL)useBlackForMoreNavController {
	NSString *navControllerStyle = [self stringWithName:@"MoreNavController_style" tab:nil];
	return !RSStringIsEmpty(navControllerStyle) && [navControllerStyle isEqualToString:@"black"];		
}


- (UIColor *)customColorForMoreNavController {
	if (_customColorForMoreNavController)
		return _customColorForMoreNavController;
	_customColorForMoreNavController = [[self colorWithName:@"MoreNavController_color" tab:nil] retain];
	return _customColorForMoreNavController;
}


- (NSString *)_colorString:(NSString *)colorName tab:(NSDictionary *)tabDictionary {
	NSString *colorHexString = [tabDictionary objectForKey:colorName];
	if (RSStringIsEmpty(colorHexString))
		colorHexString = [self.configDictionary objectForKey:colorName];
	if (RSStringIsEmpty(colorHexString))
		colorHexString = [self.defaultsDictionary objectForKey:colorName];
	return colorHexString;
}


- (UIColor *)colorWithName:(NSString *)colorName tab:(NSDictionary *)tabDictionary {
	NSString *colorString = [self _colorString:colorName tab:tabDictionary];
	if (RSStringIsEmpty(colorString))
		return [UIColor clearColor];
	return [UIColor rs_colorWithHexString:[self _colorString:colorName tab:tabDictionary]];
}


- (NSString *)colorStringWithName:(NSString *)colorName tab:(NSDictionary *)tabDictionary {
	NSString *colorHexString = [self _colorString:colorName tab:tabDictionary];
	if (![colorHexString hasPrefix:@"#"])
		return [NSString stringWithFormat:@"#%@", colorHexString];
	return colorHexString;
}


- (id)objectWithName:(NSString *)name tab:(NSDictionary *)tabDictionary {
	id obj = tabDictionary ? [tabDictionary objectForKey:name] : nil;
	if (!obj)
		obj = [self.configDictionary objectForKey:name];
	if (!obj)
		obj = [self.defaultsDictionary objectForKey:name];
	return obj;
}


- (BOOL)objectWithNameExists:(NSString *)name tab:(NSDictionary *)tabDictionary {
	id obj = [self objectWithName:name tab:tabDictionary];
	return obj != nil;
}


- (BOOL)boolWithName:(NSString *)name tab:(NSDictionary *)tabDictionary {
	id obj = [self objectWithName:name tab:tabDictionary];
	if (!obj)
		return NO;
	if (obj == (id)kCFBooleanTrue)
		return YES;
	if ([obj respondsToSelector:@selector(intValue)])
		return [obj intValue] > 0;
	return NO;
}


- (NSString *)stringWithName:(NSString *)name tab:(NSDictionary *)tabDictionary {
	return (NSString *)[self objectWithName:name tab:tabDictionary];
}


- (NSInteger)integerWithName:(NSString *)name tab:(NSDictionary *)tabDictionary {
	NSNumber *num = [self objectWithName:name tab:tabDictionary];
	if (num && [num respondsToSelector:@selector(integerValue)])
		return [num integerValue];
	return 0;
}


- (CGFloat)floatWithName:(NSString *)name tab:(NSDictionary *)tabDictionary {
	NSNumber *num = [self objectWithName:name tab:tabDictionary];
	if (num && [num respondsToSelector:@selector(floatValue)])
		return [num floatValue];
	return 0;
	
}


- (UIColor *)tintColorForTab:(NSDictionary *)tabDictionary {
	if ([self useCustomColorForNavControllerForTab:tabDictionary])
		return [self colorWithName:@"NavController_color" tab:tabDictionary];
	else if ([self useBlackNavControllerForTab:tabDictionary])
		return [UIColor colorWithWhite:0.25f alpha:1.0f];		
	return nil; /*Standard blue: no tinting*/
}


- (UIImage *)imageWithName:(NSString *)name tab:(NSDictionary *)tabDictionary {
	NSString *imageName = [self stringWithName:name tab:tabDictionary];
	if (RSStringIsEmpty(imageName))
		return nil;
//	UIImage *image = [[NSBundle mainBundle] rs_imageForResourceNamed:imageName];
//	if (image == nil)
	return [UIImage imageNamed:imageName];
//	return image;
}


NSString *TLMovieControlModeDefault = @"default";
NSString *TLMovieControlModeVolumeOnly = @"volumeOnly";
NSString *TLMovieControlModeHidden = @"hidden";

- (MPMovieControlMode)movieControlModeForTab:(NSDictionary *)tabDictionary {
	NSString *movieControlModeString = [self objectWithName:TLMovieControlMode tab:tabDictionary];
	if (movieControlModeString == nil)
		return MPMovieControlModeDefault;
	if ([movieControlModeString caseInsensitiveCompare:TLMovieControlModeHidden] == NSOrderedSame)
		return MPMovieControlModeHidden;
	if ([movieControlModeString caseInsensitiveCompare:TLMovieControlModeVolumeOnly] == NSOrderedSame)
		return MPMovieControlModeVolumeOnly;
	return MPMovieControlModeDefault;
}


- (NSString *)emailSubjectWithTitle:(NSString *)title tab:(NSDictionary *)tabDictionary {
	if (title == nil)
		return TL_DEFAULT_EMAIL_SUBJECT;
	NSString *emailTitleTemplate = [self stringWithName:TLEmailLink_TitleTemplate tab:tabDictionary];
	return RSStringReplaceAll(emailTitleTemplate, @"[[title]]", title);
}


- (NSString *)emailLinkBodyWithMessage:(NSString *)message tab:(NSDictionary *)tabDictionary {
	if (message == nil)
		return nil;
	NSString *emailLinkBodyTemplate = [self stringWithName:TLEmailLink_BodyTemplate tab:tabDictionary];
	emailLinkBodyTemplate = RSStringReplaceAll(emailLinkBodyTemplate, @"\\n", @"\n");
	return RSStringReplaceAll(emailLinkBodyTemplate, @"[[body]]", message);
}


- (NSString *)emailHTMLBodyWithMessage:(NSString *)message tab:(NSDictionary *)tabDictionary {
	if (message == nil)
		return nil;
	NSString *emailHTMLBodyTemplate = [self stringWithName:TLEmailHTML_BodyTemplate tab:tabDictionary];
	if (RSStringIsEmpty(emailHTMLBodyTemplate))
		return message;
	emailHTMLBodyTemplate = RSStringReplaceAll(emailHTMLBodyTemplate, @"\\n", @"\n");
	NSString *emailHTMLBodyHeader = [emailHTMLBodyTemplate rs_substringToFirstOccurenceOfString:@"[[body]]"];
	NSString *emailHTMLBodyFooter = [emailHTMLBodyTemplate rs_substringAfterFirstOccurenceOfString:@"[[body]]"];
	if (RSStringIsEmpty(emailHTMLBodyHeader) && RSStringIsEmpty(emailHTMLBodyFooter))
		return message;
	NSMutableString *newMessage = [NSMutableString stringWithString:message];
	if (!RSStringIsEmpty(emailHTMLBodyHeader)) {
		NSInteger indexOfBodyTag = [newMessage rangeOfString:@"<body>" options:NSCaseInsensitiveSearch].location;
		if ([newMessage rs_caseInsensitiveContains:@"<body>"])
			[newMessage replaceOccurrencesOfString:@"<body>" withString:[NSString stringWithFormat:@"<body>%@", emailHTMLBodyHeader] options:NSCaseInsensitiveSearch range:NSMakeRange(0, indexOfBodyTag + 10)];		
	}
	if (!RSStringIsEmpty(emailHTMLBodyFooter)) {
		NSInteger indexOfBodyTag = [newMessage rangeOfString:@"</body>" options:NSCaseInsensitiveSearch].location;
		if ([newMessage rs_caseInsensitiveContains:@"</body>"])
			[newMessage replaceOccurrencesOfString:@"</body>" withString:[NSString stringWithFormat:@"%@</body>", emailHTMLBodyFooter] options:NSCaseInsensitiveSearch range:NSMakeRange(0, indexOfBodyTag + 7)];		
	}
	return newMessage;
}


#pragma mark Feeds - templates


- (NSString *)articleTemplateKey {
	return rs_app_delegate.isiPadVersion ? TLArticle_TemplateName : BCNewsItemHTMLTemplateName;
}


- (NSString *)templateNameForFeed:(NSString *)feedURLString inTab:(NSDictionary *)tabDictionary {
	NSArray *feeds = [tabDictionary objectForKey:@"Feeds"];
	for (NSDictionary *oneFeedDict in feeds) {
		NSString *oneFeedURLString = [oneFeedDict objectForKey:BCNewsItemListFeedURL];
		if (oneFeedURLString && [oneFeedURLString isEqualToString:feedURLString]) {
			NSString *templateName = [oneFeedDict objectForKey:[self articleTemplateKey]];
			if (!RSStringIsEmpty(templateName))
				return templateName;
		}
	}
	return [self stringWithName:[self articleTemplateKey] tab:tabDictionary];
}


- (NSString *)templateForFeed:(NSString *)feedURLString inTab:(NSDictionary *)tabDictionary {
	NSString *templateName = [self templateNameForFeed:feedURLString inTab:tabDictionary];
	if (RSStringIsEmpty(templateName))
		return nil;
	NSString *template = [_templateCache objectForKey:templateName];
	if (!RSStringIsEmpty(template))
		return template;
	NSString *templatePath = [[NSBundle mainBundle] pathForResource:[templateName stringByDeletingPathExtension] ofType:[templateName pathExtension]];
	NSError *error = nil;
	NSStringEncoding encoding = NSUTF8StringEncoding;
	template = [NSString stringWithContentsOfFile:templatePath usedEncoding:&encoding error:&error];
	[_templateCache setObject:template forKey:templateName];
	return template;
}


#pragma mark Feeds

- (NSArray *)feedURLStringsOfPhotoGalleries {
	NSMutableArray *tempArray = [NSMutableArray array];
	for (NSDictionary *oneTab in self.tabs) {
		NSString *tabType = [oneTab objectForKey:TLTabTypeKey];
		if (RSStringIsEmpty(tabType) || ![tabType isEqualToString:@"photo_gallery"])
			continue;
		NSArray *feeds = [oneTab objectForKey:@"Feeds"];
		if (RSIsEmpty(feeds))
			continue;
		for (NSDictionary *oneFeed in feeds)
			[tempArray rs_safeAddObject:[oneFeed objectForKey:@"xmlUrl"]];
	}
	return tempArray;
}


- (void)addFeedsFromTab:(NSDictionary *)oneTab toArray:(NSMutableArray *)feedSpecifiers {
	NSArray *feeds = [oneTab objectForKey:@"Feeds"];
	if (RSIsEmpty(oneTab))
		return;
	for (NSDictionary *oneItem in feeds) {
		if ([oneItem isKindOfClass:[NSDictionary class]] && [oneItem objectForKey:BCFeedURLStringKey])
			[feedSpecifiers rs_safeAddObject:[NGFeedSpecifier feedSpecifierWithName:nil feedURL:[NSURL URLWithString:[oneItem objectForKey:BCFeedURLStringKey]] feedHomePageURL:nil account:[RSDataAccount localAccount]]];
		else if ([oneItem isKindOfClass:[NSDictionary class]])
			[self addFeedsFromTab:oneItem toArray:feedSpecifiers];
	}	
}


- (void)addFeedURLsFromTab:(NSDictionary *)oneTab toArray:(NSMutableArray *)feedURLs {
	NSArray *feeds = [oneTab objectForKey:@"Feeds"];
	if (RSIsEmpty(oneTab))
		return;
	for (NSDictionary *oneItem in feeds) {
		if ([oneItem isKindOfClass:[NSDictionary class]] && [oneItem objectForKey:BCFeedURLStringKey] != nil)
			[feedURLs rs_safeAddObject:[NSURL URLWithString:[oneItem objectForKey:BCFeedURLStringKey]]];
		else if ([oneItem isKindOfClass:[NSDictionary class]])
			[self addFeedURLsFromTab:oneItem toArray:feedURLs];
	}	
}


- (NSArray *)feedSpecifiersForTab:(NSDictionary *)tab {
	NSMutableArray *feedSpecifiers = [NSMutableArray array];
	[self addFeedsFromTab:tab toArray:feedSpecifiers];
	return feedSpecifiers;
}


- (NSArray *)allFeedSpecifiers {
	NSMutableArray *feedSpecifiers = [NSMutableArray array];
	for (NSDictionary *oneTab in self.tabs)
		[self addFeedsFromTab:oneTab toArray:feedSpecifiers];
	return feedSpecifiers;
}


- (NSArray *)allFeedURLs {
	NSMutableArray *feedURLs = [NSMutableArray array];
	for (NSDictionary *oneTab in self.tabs)
		[self addFeedURLsFromTab:oneTab toArray:feedURLs];
	return feedURLs;
}


#pragma mark Twitter

- (NSString *)twitterConsumerKey {
	static NSString *twitterConsumerKey = nil;
	if (twitterConsumerKey != nil)
		return twitterConsumerKey;
	twitterConsumerKey = [[NSClassFromString(@"TLSecrets") twitterConsumerKey] retain];
	return twitterConsumerKey;
}


- (NSString *)twitterConsumerSecret {
	static NSString *twitterConsumerSecret = nil;
	if (twitterConsumerSecret != nil)
		return twitterConsumerSecret;
	twitterConsumerSecret = [[NSClassFromString(@"TLSecrets") twitterConsumerSecret] retain];
	return twitterConsumerSecret;
}

- (void)twitterConsumerKey:(NSString **)twitterConsumerKey twitterConsumerSecret:(NSString **)twitterConsumerSecret usingTapLynxDefault:(BOOL *)usingTapLynxDefault {
	*twitterConsumerKey = self.twitterConsumerKey;//[self stringWithName:TLTwitterConsumerKey tab:nil];
	*twitterConsumerSecret = self.twitterConsumerSecret;//[self stringWithName:TLTwitterConsumerSecret tab:nil];
#if TARGET_IPHONE_SIMULATOR
	if (RSStringIsEmpty(*twitterConsumerKey)) {
		*usingTapLynxDefault = YES;
		*twitterConsumerKey = @"H5NZrPp46wuRyBr2rcH0A"; //TapLynx consumer key -- only for simulator http://dev.twitter.com/apps/172935
	}
	if (RSStringIsEmpty(*twitterConsumerSecret)) {
		*usingTapLynxDefault = YES;
		*twitterConsumerSecret = @"QzdtuNROsefNzS4yJa8mrYfj97Wh6Y5wSS0OgfrdU"; //TapLynx consumer secret -- only for simulator
	}
	if (*usingTapLynxDefault)
		NSLog(@"Using TapLynx Twitter consumer key and secret. These won't work on the device -- make sure to register your app with Twitter, get your own consumer key and secret for your app, and request xAuth access. If you have any questions about this, please ask on the Google Group.");
#endif
#if !TARGET_IPHONE_SIMULATOR
	*usingTapLynxDefault = NO;
#endif
}


- (BOOL)canPostToTwitter {
#if TARGET_IPHONE_SIMULATOR
	return YES;
#endif
	return !RSStringIsEmpty(self.twitterConsumerKey) && !RSStringIsEmpty(self.twitterConsumerSecret);
}


#pragma mark Facebook

- (NSString *)facebookAppID {
	static NSString *facebookAppID = nil;
	if (facebookAppID != nil)
		return facebookAppID;
	Class tlSecretsClass = NSClassFromString(@"TLSecrets");
	if ([tlSecretsClass respondsToSelector:@selector(facebookAppID)])
		facebookAppID = [[tlSecretsClass facebookAppID] retain];
	return facebookAppID;
}


- (void)facebookAppID:(NSString **)facebookAppID usingTapLynxDefault:(BOOL *)usingTapLynxDefault {
	*facebookAppID = [self facebookAppID];
#if TARGET_IPHONE_SIMULATOR
	if (RSStringIsEmpty(*facebookAppID)) {
		*usingTapLynxDefault = YES;
		*facebookAppID = @"122490921138121"; //TapLynx appID -- only for simulator
		NSLog(@"Using TapLynx Facebook app ID. This won't work on the device -- make sure to register your app with Facebook and get an app ID. If you have any questions about this, please ask on the Google Group.");
	}
#endif
#if !TARGET_IPHONE_SIMULATOR
	*usingTapLynxDefault = NO;
#endif
	
	
}


@end
