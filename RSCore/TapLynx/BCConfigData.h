//
//  BCConfigData.h
//  bobcat
//
//  Created by Brent Simmons on 9/15/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

/*Reads the config file that specifies tabs, feed hierarchy, etc.*/

#define kWebConfigDidDownload @"TLWebConfigDidDownload"

extern NSString *BCFeedURLStringKey;
extern NSString *BCNewsItemList_ThumbnailMaxWidth;
extern NSString *BCNewsItemList_MaxDescriptionLines;
extern NSString *BCNewsItemList_MaxTitleLines;
extern NSString *BCWebAdsUseMedialets;
extern NSString *BCWebAdsUseQuattro;
extern NSString *TLWebAdsUseGlam;
extern NSString *TLGlamAfid;
extern NSString *TLGlamAppName;
extern NSString *BCTapLynxLicenseKey;
extern NSString *BCTapLynxDelegateClassKey;
extern NSString *BCNewsItemList_FolderTextColor;
extern NSString *BCAnalyticsUseMedialets;
extern NSString *BCAnalyticsUsePinchMedia;
extern NSString *BCPinchMediaAppID;
extern NSString *BCAnalyticsUseFlurry;
extern NSString *BCFlurryAppID;
extern NSString *BCPushNotificationsUsePushIO;
extern NSString *BCPushIOAPIToken;
extern NSString *BCPushNotificationsTypeAlert;
extern NSString *BCPushNotificationsTypeSound;
extern NSString *BCPushNotificationsTypeBadge;
extern NSString *BCFeedUsernameKey;
extern NSString *BCFeedPasswordKey;
extern NSString *BCMedialetsAppID;
extern NSString *TLTabTypeKey;
extern NSString *TLTabTypeVideoBrowser;
extern NSString *TLTabTypeHorizontalBrowser;
extern NSString *TLMovieControlMode;
extern NSString *TLNewsItemsList_HideDates;
extern NSString *TLEmailLink_TitleTemplate;
extern NSString *TLEmailLink_BodyTemplate;
extern NSString *TLEmailHTML_BodyTemplate;
extern NSString *TLPhotoGallery_HideCaptions;
extern NSString *TLPhotoGallery_GridViewBackgroundColor;
extern NSString *TLTabIdentifier;
extern NSString *TLTitle;
extern NSString *TLNewsItemList_FolderGroupName;
extern NSString *TLNewsItemsList_RightArrowImageName;
extern NSString *TLNewsItemsList_HideNavbarTitle; //doesn't inherit
extern NSString *TLTwitterConsumerKey;
extern NSString *TLTwitterConsumerSecret;
extern NSString *TLNewsItemHTML_OpenInSafariCommand;
extern NSString *TLHome_ShowHighlightsView;
extern NSString *TLHome_HighlightsViewURL;
extern NSString *TLToolbarStyle; //default or black
extern NSString *TLToolbarTintColor;
extern NSString *TLHome_RowBackgroundColor;
extern NSString *TLTrayDateColor;
extern NSString *TLTraySummaryColor;
extern NSString *TLTrayTitleColor;
extern NSString *TLTrayTitleUnreadColor;
extern NSString *TLHome_SourceBackgroundImage;
extern NSString *TLHome_SourceScaleImageToFill;
extern NSString *TLTabImageName;

/*iPad*/
extern NSString *TLTabHeight;
extern NSString *TLTabArticleWidth;
extern NSString *TLTabArticleTitleFontSize;
extern NSString *TLHighlightsWidth;
extern NSString *TLTabSourceWidth;
extern NSString *TLTabSourceTitle_BaseName;
extern NSString *TLTabSourceTitleColor;
extern NSString *TLTabSourceImage_BaseName;
extern NSString *TLThumbnailRectBaseName;
extern NSString *TLTitleRectBaseName;
extern NSString *TLDateRectBaseName;
extern NSString *TLDescriptionRectBaseName;
extern NSString *TLTitleRectNoThumbnailBaseName;
extern NSString *TLDateRectNoThumbnailBaseName;
extern NSString *TLDescriptionRectNoThumbnailBaseName;
extern NSString *TLArticle_CommandsBackgroundColor;
extern NSString *TLArticle_BaseName;
extern NSString *TLArticle_CommandsImageName;
extern NSString *TLArticle_CommandsScaleImageToFill;
extern NSString *TLArticle_TemplateName;


@class RSCache;

@interface BCConfigData : NSObject {
	@private
	NSDictionary *_configDictionary;
	NSArray *_tabs;
	UIImage *_staticAdImage;
	BOOL _showAds;
	BOOL _useStaticAdImage;
	BOOL _useBlackNavController;
	BOOL _useCustomColorForNavController;
	UIColor *_customColorForNavController;
	NSString *_appURL;
	NSDictionary *_defaultsDictionary;
	BOOL _showUnreadCounts;
	BOOL _allFeedsAreLocal;
	UIColor *_customColorForMoreNavController;
	BOOL _favoritesFeatureEnabled;
	RSCache *_templateCache;
	BOOL _useBlackForMoreNavController;
	BOOL _useCustomColorForMoreNavController;
	BOOL _landscapeDisabled;
	UIBarStyle toolbarStyle;
	UIColor *toolbarColor;
	NSString *toolbarImageName;
	BOOL scaleToolbarImageToFill;
	CGFloat highlightsWidth;
	CGFloat sourceWidth;
}

+ (BCConfigData *)sharedData;

@property (nonatomic, retain, readonly) NSDictionary *configDictionary;
@property (nonatomic, retain, readonly) NSArray *tabs;
@property (nonatomic, retain, readonly) UIImage *staticAdImage;
@property (nonatomic, assign, readonly) BOOL showAds;
@property (nonatomic, assign, readonly) BOOL useStaticAdImage;
@property (nonatomic, assign, readonly) BOOL useBlackNavController;
@property (nonatomic, assign, readonly) BOOL useCustomColorForNavController;
@property (nonatomic, retain, readonly) UIColor *customColorForNavController;
@property (nonatomic, retain, readonly) NSString *appURL;
@property (nonatomic, assign, readonly) BOOL showUnreadCounts;
@property (nonatomic, assign, readonly) BOOL allFeedsAreLocal;
@property (nonatomic, retain, readonly) UIColor *customColorForMoreNavController;
@property (nonatomic, assign, readonly) BOOL useCustomColorForMoreNavController;
@property (nonatomic, assign, readonly) BOOL useBlackForMoreNavController;
@property (nonatomic, assign, readonly) BOOL favoritesFeatureEnabled;
@property (nonatomic, assign, readonly) BOOL landscapeDisabled;
@property (nonatomic, assign, readonly) BOOL canPostToTwitter;
@property (nonatomic, retain, readonly) NSString *twitterConsumerKey;
@property (nonatomic, retain, readonly) NSString *twitterConsumerSecret;
@property (nonatomic, retain, readonly) NSArray *allFeedSpecifiers; //array of NGFeedSpecifier
@property (nonatomic, retain, readonly) NSArray *allFeedURLs; //array of NSURLs
@property (nonatomic, assign, readonly) UIBarStyle toolbarStyle;
@property (nonatomic, retain, readonly) UIColor *toolbarColor;
@property (nonatomic, retain, readonly) NSString *toolbarImageName;
@property (nonatomic, assign, readonly) BOOL scaleToolbarImageToFill;
@property (nonatomic, assign, readonly) CGFloat highlightsWidth;
@property (nonatomic, assign, readonly) CGFloat sourceWidth;

/*Tabs inherit top-level config data when not specified*/

- (BOOL)useBlackNavControllerForTab:(NSDictionary *)tabDictionary;
- (BOOL)useCustomColorForNavControllerForTab:(NSDictionary *)tabDictionary;
- (UIColor *)colorWithName:(NSString *)colorName tab:(NSDictionary *)tabDictionary;
- (NSString *)colorStringWithName:(NSString *)colorName tab:(NSDictionary *)tabDictionary;
- (BOOL)boolWithName:(NSString *)name tab:(NSDictionary *)tabDictionary;
- (NSString *)stringWithName:(NSString *)name tab:(NSDictionary *)tabDictionary;
- (NSInteger)integerWithName:(NSString *)name tab:(NSDictionary *)tabDictionary;
- (CGFloat)floatWithName:(NSString *)name tab:(NSDictionary *)tabDictionary;
- (id)objectWithName:(NSString *)name tab:(NSDictionary *)tabDictionary;
- (BOOL)objectWithNameExists:(NSString *)name tab:(NSDictionary *)tabDictionary;
- (UIColor *)tintColorForTab:(NSDictionary *)tabDictionary;
- (UIImage *)imageWithName:(NSString *)name tab:(NSDictionary *)tabDictionary;
- (MPMovieControlMode)movieControlModeForTab:(NSDictionary *)tabDictionary;
- (NSString *)emailSubjectWithTitle:(NSString *)title tab:(NSDictionary *)tabDictionary;
- (NSString *)emailLinkBodyWithMessage:(NSString *)message tab:(NSDictionary *)tabDictionary;
- (NSString *)emailHTMLBodyWithMessage:(NSString *)message tab:(NSDictionary *)tabDictionary;

- (NSArray *)feedURLStringsOfPhotoGalleries;

- (NSArray *)feedSpecifiersForTab:(NSDictionary *)tab;

/*Feeds - template*/

- (NSString *)templateForFeed:(NSString *)feedURLString inTab:(NSDictionary *)tabDictionary;

/*WebConfig*/

- (UIImage *)artworkImageWithName:(NSString *)imageName;

- (void)twitterConsumerKey:(NSString **)twitterConsumerKey twitterConsumerSecret:(NSString **)twitterConsumerSecret usingTapLynxDefault:(BOOL *)usingTapLynxDefault;
- (void)facebookAppID:(NSString **)facebookAppID usingTapLynxDefault:(BOOL *)usingTapLynxDefault;


@end
