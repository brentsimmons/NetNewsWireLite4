//
//  RSFaviconCache.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 10/30/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "RSCache.h"


/*This caches images in memory both as CGImageRefs and as PNG data.
 Sometimes an app needs a CGImage -- so it can draw it in a table view or CALayer or whatever.
 Other times it needs PNG data -- to return to a custom URL protocol, for instance.
 
 The in-memory caches are emptied whenever RSCache gets emptied.
 
 In general, images won't be cached twice, because you don't always want that and it would be
 wasteful of memory. But if you call cgImageForFilename and pngDataForFilename with the same
 filename, that image will get cached twice, using the two different representations.
 
 To write to the cache, call one of the save methods. This saves the image on disk
 as well as caching it in memory.
 
 Thread-safe. Mac + iOS. Requires iOS 4.0 and up -- uses ImageIO.framework.*/


@interface RSImageFolderCache : NSObject {
@private
	NSString *folderPath;
	RSCache *cgImageCache;
	RSCache *pngDataCache;
	pthread_mutex_t folderLock;
}

/*All files for a given RSImageCache instance live in the same folder.*/

- (id)initWithFolder:(NSString *)aFolderPath;

- (CGImageRef)cgImageForFilename:(NSString *)filename;
- (NSData *)pngDataForFilename:(NSString *)filename;

- (CGImageRef)cachedCGImageForFilename:(NSString *)filename;

/*It's up to the caller to be sure that filename is safe for file system use.*/

- (BOOL)saveCGImage:(CGImageRef)cgImage withFilename:(NSString *)filename error:(NSError **)error; //Saved as PNGs
- (BOOL)saveImageData:(NSData *)imageData withFilename:(NSString *)filename error:(NSError **)error; //Any format: doesn't look at imageData

/*Utility for callers: easy way to turn a URL string into a filename safe-for-file-system -- and with a .png suffix.
 Otherwise RSImageFolderCache does *not* translate filenames -- it's up to the callers to use this utility or not.*/

+ (NSString *)filenameForURLString:(NSString *)urlString;

/*On iOS 4.2 and greater and on OS X 10.6 or greater, the in-memory cache uses NSCache.
 You can set that cache's item count limit. It's normally 0, which means no limit.*/

@property (nonatomic, assign) NSUInteger inMemoryCacheCountLimit;
	
@end
