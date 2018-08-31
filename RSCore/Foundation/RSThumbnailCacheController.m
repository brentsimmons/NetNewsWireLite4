//
//  RSThumbnailCacheController.m
//  libTapLynx
//
//  Created by Brent Simmons on 12/1/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSThumbnailCacheController.h"
#import "RSCache.h"
#import "RSImageScalingSpecifier.h"
#import "RSUIImageExtras.h"
#import "RSUIKitExtras.h"


@interface NSObject (ScaleStub)
- (float)scale;
@end


@interface RSThumbnailCacheController ()
@property (nonatomic, retain, readonly) RSCache *thumbnailMemoryCache;
@end


@implementation RSThumbnailCacheController

@synthesize thumbnailMemoryCache;

#pragma mark Class Methods

+ (id)sharedController {
	static id gMyInstance = nil;
	if (!gMyInstance)
		gMyInstance = [[self alloc] init];
	return gMyInstance;
}


#pragma mark Init

- (id)init {
	self = [super init];
	if (self == nil)
		return nil;
	thumbnailMemoryCache = [[RSCache alloc] init];
	return self;
}


#pragma mark Dealloc

- (void)dealloc {
	[thumbnailMemoryCache release];
	[super dealloc];
}



#pragma mark Cache

- (UIImage *)resizedImageWithData:(NSData *)imageData imageScalingSpecifier:(RSImageScalingSpecifier *)imageScalingSpecifier {
	if (RSIsEmpty(imageData))
		return nil;
	UIImage *image = [[[UIImage imageWithData:imageData] retain] autorelease];
	if (image == nil)
		return image;
	if (image.size.width < imageScalingSpecifier.targetSize.width && image.size.height < imageScalingSpecifier.targetSize.height)
		return image;
	return RSScaleImageWithSpecifier(image, imageScalingSpecifier);
}


static NSString *RSThumbnailCacheURLFormat = @"%@%d%d%da%d%d2";
static NSString *RSThumbnailCacheURLFormat4 = @"%@%d%d%d4c%d%d2";
static NSString *RSThumbnailCacheURLFormat4Scale2 = @"%@%d%d%d42d%d%d2"; //retina display

- (NSString *)mangledURLForImageScalingSpecifier:(RSImageScalingSpecifier *)imageScalingSpecifier {
	static NSString *formatString = nil;
	/*The separate format strings are mainly for simulator use.*/
	if (formatString == nil) {
		if (RSRunningOnOS4OrBetter())
			formatString = [[UIScreen mainScreen].scale > 1.1 ? RSThumbnailCacheURLFormat4Scale2 : RSThumbnailCacheURLFormat4 retain];
		else
			formatString = [RSThumbnailCacheURLFormat retain];
	}
	return [NSString stringWithFormat:formatString, [imageScalingSpecifier.URL absoluteString], (NSInteger)(imageScalingSpecifier.targetSize.width), (NSInteger)(imageScalingSpecifier.targetSize.height), (NSInteger)(imageScalingSpecifier.roundedCorners), (NSInteger)(imageScalingSpecifier.cornerRadius), imageScalingSpecifier.contentMode];	
}

- (void)storeThumbnail:(UIImage *)thumbnail imageScalingSpecifier:(RSImageScalingSpecifier *)imageScalingSpecifier {
	NSString *urlString = [self mangledURLForImageScalingSpecifier:imageScalingSpecifier];
	[self.thumbnailMemoryCache setObject:thumbnail forKey:urlString];
	[self storeObject:[thumbnail rs_jpegOrPNGRepresentation] url:[NSURL URLWithString:urlString]];	
}


- (UIImage *)storeDownloadedDataAndReturnThumbnail:(NSData *)downloadedData imageScalingSpecifier:(RSImageScalingSpecifier *)imageScalingSpecifier {
	UIImage *thumbnail = [self resizedImageWithData:downloadedData imageScalingSpecifier:imageScalingSpecifier];
	if (thumbnail != nil)
		[self storeThumbnail:thumbnail imageScalingSpecifier:imageScalingSpecifier];
	return thumbnail;	
}


- (UIImage *)storeDownloadedDataAndReturnThumbnail:(NSData *)downloadedData url:(NSURL *)url targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners {
	NSLog(@"Deprecation warning: - (UIImage *)storeDownloadedDataAndReturnThumbnail:(NSData *)downloadedData url:(NSURL *)url targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners");
	return [self storeDownloadedDataAndReturnThumbnail:downloadedData imageScalingSpecifier:[RSImageScalingSpecifier imageScalingSpecifierWithURL:url targetSize:targetSize roundedCorners:roundedCorners]];
}


- (UIImage *)memoryCachedThumbnailForImageScalingSpecifier:(RSImageScalingSpecifier *)imageScalingSpecifier {
	NSString *mangledURLString = [self mangledURLForImageScalingSpecifier:imageScalingSpecifier];
	return [self.thumbnailMemoryCache objectForKey:mangledURLString];
}


- (UIImage *)memoryCachedThumbnailAtURL:(NSURL *)URL targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners {
	NSLog(@"Deprecation warning: - (UIImage *)memoryCachedThumbnailAtURL:(NSURL *)URL targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners");
	RSImageScalingSpecifier *imageScalingSpecifier = [RSImageScalingSpecifier imageScalingSpecifierWithURL:URL targetSize:targetSize roundedCorners:roundedCorners];
	return [self memoryCachedThumbnailForImageScalingSpecifier:imageScalingSpecifier];
}


- (UIImage *)cachedThumbnailForImageScalingSpecifier:(RSImageScalingSpecifier *)imageScalingSpecifier {
	NSString *thumbnailModifiedURLString = [self mangledURLForImageScalingSpecifier:imageScalingSpecifier];
	UIImage *memoryCachedImage = [self.thumbnailMemoryCache objectForKey:thumbnailModifiedURLString];
	if (memoryCachedImage != nil)
		return memoryCachedImage;
	NSURL *thumbnailSpecificURL = [NSURL URLWithString:thumbnailModifiedURLString];
	NSData *imageData = [self cachedObjectAtURL:thumbnailSpecificURL];
	if (imageData != nil) {
		UIImage *cachedOnDiskThumbnail = [UIImage rs_imageWithData:imageData expectedSize:imageScalingSpecifier.targetSize];
		if (cachedOnDiskThumbnail != nil) {
			[self.thumbnailMemoryCache setObject:cachedOnDiskThumbnail forKey:thumbnailModifiedURLString];
			return cachedOnDiskThumbnail;
		}
	}
	imageData = [self cachedObjectAtURL:imageScalingSpecifier.URL]; /*May just have raw response*/
	if (RSIsEmpty(imageData))
		return nil;
	UIImage *cachedRawResponseImage = [self resizedImageWithData:imageData imageScalingSpecifier:imageScalingSpecifier];
	if (cachedRawResponseImage == nil)
		return nil;
	/*Store resized version on disk */
	[self storeThumbnail:cachedRawResponseImage imageScalingSpecifier:imageScalingSpecifier];
	return cachedRawResponseImage;
}


- (UIImage *)cachedThumbnailAtURL:(NSURL *)url targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners {
	NSLog(@"Deprecation warning: - (UIImage *)cachedThumbnailAtURL:(NSURL *)url targetSize:(CGSize)targetSize roundedCorners:(BOOL)roundedCorners");
	RSImageScalingSpecifier *imageScalingSpecifier = [RSImageScalingSpecifier imageScalingSpecifierWithURL:url targetSize:targetSize roundedCorners:roundedCorners];
	return [self cachedThumbnailForImageScalingSpecifier:imageScalingSpecifier];
}


@end
