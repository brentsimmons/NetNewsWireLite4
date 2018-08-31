//
//  RSPluginObjects.m
//  RSCoreTests
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <MobileCoreServices/MobileCoreServices.h>
#endif

#import "RSPluginObjects.h"
#import "RSDataManagedObjects.h"


@interface RSSharableItem ()

@property (nonatomic, retain, readwrite) NSString *uti;
@property (nonatomic, retain, readwrite) NSURL *URL;
@property (nonatomic, retain, readwrite) NSData *itemData;
@property (nonatomic, retain, readwrite) NSString *htmlText;
@property (nonatomic, retain, readwrite) NSString *selectedText;
@property (nonatomic, retain, readwrite) NSString *title;
@property (nonatomic, retain, readwrite) id<RSFeedSpecifier> feed;
@property (nonatomic, retain, readwrite) NSURL *permalink;

@end

@implementation RSSharableItem

@synthesize uti;
@synthesize URL;
@synthesize itemData;
@synthesize htmlText;
@synthesize selectedText;
@synthesize title;
@synthesize feed;
@synthesize permalink;


#pragma mark Class Convenience Methods

+ (id<RSSharableItem>)sharableItemWithURL:(NSURL *)aURL {
	RSSharableItem *sharableItem = [[[RSSharableItem alloc] init] autorelease];
	sharableItem.URL = aURL;
	sharableItem.uti = (NSString *)kUTTypeURL;
	return (id<RSSharableItem>)sharableItem;	
}


+ (id<RSSharableItem>)sharableItemWithURL:(NSURL *)aURL permalink:(NSURL *)aPermalink title:(NSString *)aTitle {
	RSSharableItem *sharableItem = [[[RSSharableItem alloc] init] autorelease];
	sharableItem.URL = aURL;
	sharableItem.permalink = aPermalink;
	if (sharableItem.URL == nil)
		sharableItem.URL = aPermalink;
	sharableItem.title = aTitle;
	sharableItem.uti = (NSString *)kUTTypeText;
	return (id<RSSharableItem>)sharableItem;
}


+ (id<RSSharableItem>)sharableItemWithArticle:(RSDataArticle *)anArticle {
	NSURL *link = nil;
	if (anArticle.link != nil)
		link = [NSURL URLWithString:anArticle.link];
	NSURL *aPermalink = nil;
	if (anArticle.permalink != nil)
		aPermalink = [NSURL URLWithString:anArticle.permalink];	
	NSString *aTitle = anArticle.plainTextTitle;
	if (RSStringIsEmpty(aTitle))
		aTitle = anArticle.title;
	RSSharableItem *sharableItem = [self sharableItemWithURL:link permalink:aPermalink title:aTitle];
	sharableItem.htmlText = anArticle.content.htmlText;
	sharableItem.uti = (NSString *)kUTTypeHTML;
	return (id<RSSharableItem>)sharableItem;
}


+ (id<RSSharableItem>)sharableItemWithTimeBasedMedia:(NSURL *)aURL {
	RSSharableItem *sharableItem = [self sharableItemWithURL:aURL permalink:nil title:nil];
	sharableItem.uti = nil; //sharableItemWithURL assumes text
	NSString *urlString = [aURL absoluteString];
	urlString = [urlString rs_stringByStrippingURLQuery];
	NSString *fileExtension = [urlString pathExtension];
	if (!RSStringIsEmpty(fileExtension)) {
        CFStringRef mediaItemUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge_retained CFStringRef)fileExtension, kUTTypeAudiovisualContent);
		sharableItem.uti = (__bridge NSString *)mediaItemUTI;
		CFRelease(mediaItemUTI);
	}
	if (sharableItem.uti == nil)
		sharableItem.uti = (NSString *)kUTTypeAudiovisualContent;
	return sharableItem;
}

																   
+ (NSArray *)arrayOfOneSharableItemWithArticle:(RSDataArticle *)anArticle {
	return [NSArray arrayWithObject:[self sharableItemWithArticle:anArticle]];
}


#pragma mark Dealloc

- (void)dealloc {
	[uti release];
	[URL release];
	[itemData release];
	[htmlText release];
	[selectedText release];
	[title release];	
	[feed release];
	[permalink release];
	[super dealloc];
}


@end
