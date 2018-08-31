//
//  NNWTabThumbnailCache.m
//  NetNewsWire
//
//  Created by Brent Simmons on 9/19/06.
//  Copyright 2006 Ranchero Software. All rights reserved.
//


#import "NNWTabThumbnailCache.h"
#import "NNWBrowser+Tabs.h"
#import "NetNewsWire+UI.h"


NSString *_NNWTabThumbnailCacheFolderName = @"TabThumbnails.noindex";
NSString *_NNWTabImageSuffix = @".tiff";


@interface NNWTabThumbnailCache (Forward)
- (NSImage *)_readImageFromDiskForURLString:(NSString *)urlString;
- (void)_primitiveSetImage:(NSImage *)image forURLString:(NSString *)urlString;
- (void)_writeImageToDisk:(NSImage *)image forURLString:(NSString *)urlString;
@end


@implementation NNWTabThumbnailCache


//#pragma mark Class Methods
//
//+ (id)sharedCache {
//	static id gMyInstance = nil;
//	if (!gMyInstance)
//		gMyInstance = [[self alloc] init];
//	return gMyInstance;
//	}
//
//
//#pragma mark Init
//
//- (id)init {
//	if (![super init])
//		return nil;
//	RSCacheFolderForAppSubFolder(APP_SUPPORT_FOLDER_NAME, _NNWTabThumbnailCacheFolderName, NO);
//	return self;
//	}
	

#pragma mark Dealloc

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
	}


#pragma mark Images

//- (NSImage *)imageForURLString:(NSString *)urlString {
//	if (RSIsEmpty(urlString))
//		return nil;
//	return [self _readImageFromDiskForURLString:urlString];
//	}
	
	
//- (void)setImage:(NSImage *)image forURLString:(NSString *)urlString {
//	if (!image)
//		return;
//	[self _writeImageToDisk:image forURLString:urlString];
//	}

	
#pragma mark Disk

//- (NSString *)_filenameForURLString:(NSString *)urlString {
//	if ([urlString hasPrefix:@"http://"] && [urlString length] > 7)
//		urlString = [urlString substringFromIndex:7];
//	if ([urlString hasPrefix:@"https://"] && [urlString length] > 8)
//		urlString = [urlString substringFromIndex:8];
//	if ([urlString hasPrefix:@"file//"] && [urlString length] > 7)
//		urlString = [urlString substringFromIndex:7];
//	NSString *filename = RSStringReplaceAll(urlString, RSSlash, RSUnderscore);
//	filename = RSStringReplaceAll(filename, RSPeriod, RSUnderscore);
//	filename = RSStringReplaceAll(filename, RSColon, RSUnderscore);
//	filename = RSStringReplaceAll(filename, RSSingleSpaceString, RSUnderscore);
//	filename = RSStringReplaceAll(filename, RSPound, RSUnderscore);
//	filename = RSConcatenateStrings(filename, _NNWTabImageSuffix);
//	return filename;
//	}


//- (NSString *)cacheFolderPath {
//	return RSCacheFolderForAppSubFolder(APP_SUPPORT_FOLDER_NAME, _NNWTabThumbnailCacheFolderName, NO);
//	}
//

//- (NSString *)pathForURLString:(NSString *)urlString {
//	return [[self cacheFolderPath] stringByAppendingPathComponent:[self _filenameForURLString:urlString]];
//	}
	
	
//- (NSImage *)_readImageFromDiskForURLString:(NSString *)urlString {
//	if (RSIsEmpty(urlString))
//		return nil;
//	NSString *f = [self pathForURLString:urlString];
//	if (!RSFileExists(f))
//		return nil;
//	NSError *error = nil;
//	NSData *d = [NSData dataWithContentsOfFile:f options:NSMappedRead error:&error];
//	if (!d)
//		return nil;
//	return [[[NSImage alloc] initWithData:d] autorelease];
//	}


//- (void)_writeImageToDisk:(NSImage *)image forURLString:(NSString *)urlString {
//	if (image && !RSIsEmpty(urlString))
//		[[image TIFFRepresentation] writeToFile:[self pathForURLString:urlString] atomically:YES];
//	}
	

//- (void)startupCache {
//	NSArray *tabURLs = [[NNWBrowser sharedBrowser] tabURLsArray];
//	if (RSIsEmpty(tabURLs))
//		return;
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	int i;
//	int ct = [tabURLs count];
//	for (i = 0; i < ct; i++)
//		(void)[self imageForURLString:[tabURLs safeObjectAtIndex:i]];
//	[pool release];
//	}
	
	
#pragma mark Cache Cleanup

//- (NSDictionary *)_tabURLsDictionary:(NSArray *)tabURLs {
//	if (RSIsEmpty(tabURLs))
//		return nil;
//	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithCapacity:100];
//	int i;
//	int ct = [tabURLs count];
//	for (i = 0; i < ct; i++)
//		[d setBool:YES forKey:[self _filenameForURLString:[tabURLs objectAtIndex:i]]];
//	return d;
//	}



- (void)cleanupImageCache {
	
	/*Remove images that don't exist in browser tabs list.*/
	
//	NSArray *tabURLs = [[NNWBrowser sharedBrowser] tabURLsArray];
//	NSArray *files = [[NSFileManager defaultManager] directoryContentsAtPath:[self cacheFolderPath]];
//	if (RSIsEmpty(files))
//		return;
//	NSString *oneFilename;
//	int i = 0;
//	int ct = [files count];
//	int ctLoops = 0;
//	static int start = 0;
//	if (start >= ct)
//		start = 0;
//	BOOL found = NO;
//	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//	NSDictionary *tabURLsDictionary = [self _tabURLsDictionary:tabURLs];
//	for (i = start; i < ct; i++) {
//		oneFilename = [files objectAtIndex:i];
//		found = [tabURLsDictionary boolForKey:oneFilename];
//		if (!found)
//			RSFileDelete([[self cacheFolderPath] stringByAppendingPathComponent:oneFilename]);
//		ctLoops++;
//		if (ctLoops > 5)
//			break;
//		}
//	start = i;
//	[pool release];
	}
		
	
@end
