
//
//  RSFaviconCache.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 10/30/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <ImageIO/ImageIO.h>
#endif
#import "RSImageFolderCache.h"
#import "RSFoundationExtras.h"
#import "RSFileUtilities.h"


@interface RSImageFolderCache ()

@property (nonatomic, strong) NSString *folderPath;
@property (nonatomic, strong) RSCache *cgImageCache;
@property (nonatomic, strong) RSCache *pngDataCache;

- (NSData *)readData:(NSString *)filename error:(NSError **)error;
- (BOOL)writeData:(NSData *)fileData filename:(NSString *)filename error:(NSError **)error;

@end


@implementation RSImageFolderCache

@synthesize folderPath;
@synthesize cgImageCache;
@synthesize pngDataCache;


#pragma mark Init

- (id)initWithFolder:(NSString *)aFolderPath {
    self = [super init];
    if (self == nil)
        return nil;
    if (RSLockCreate(&folderLock) != 0)
        return nil;
    folderPath = [aFolderPath copy];
    cgImageCache = [[RSCache alloc] init];
    pngDataCache = [[RSCache alloc] init];
#if !TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidResignActive:) name:NSApplicationDidResignActiveNotification object:nil];
#endif
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    RSLockDestroy(&folderLock);
}


#pragma mark Paths

+ (NSString *)filenameForURLString:(NSString *)urlString {
    return [NSString stringWithFormat:@"%@%@", [urlString rs_URLStringSafeForFileSystem], @".png"];
}


- (NSString *)pathWithFilename:(NSString *)filename {
    return [self.folderPath stringByAppendingPathComponent:filename];
}


- (NSURL *)URLWithFilename:(NSString *)filename {
    return [NSURL fileURLWithPath:[self pathWithFilename:filename] isDirectory:NO];
}


#pragma mark In-Memory Cache Limit

- (NSUInteger)inMemoryCacheCountLimit {
    return MAX(self.cgImageCache.countLimit, self.pngDataCache.countLimit);
}


- (void)setInMemoryCacheCountLimit:(NSUInteger)aCountLimit {
    self.cgImageCache.countLimit = aCountLimit;
    self.pngDataCache.countLimit = aCountLimit;
}


#pragma mark Reading

- (CGImageRef)cachedCGImageForFilename:(NSString *)filename {
    return (__bridge CGImageRef)[self.cgImageCache objectForKey:filename];
}


- (CGImageRef)cgImageFromFile:(NSString *)path {
    RSLockLock(&folderLock);
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], NULL);
    CGImageRef cgImage = nil;
    if (imageSourceRef != nil) {
        cgImage = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);
        CFRelease(imageSourceRef);
    }
    RSLockUnlock(&folderLock);
    return cgImage;
}


- (CGImageRef)cgImageForFilename:(NSString *)filename {
    
    CGImageRef inMemoryCachedCGImage = [self cachedCGImageForFilename:filename];
    if (inMemoryCachedCGImage != nil)
        return inMemoryCachedCGImage;
    
    CGImageRef onDiskCachedCGImage = [self cgImageFromFile:[self pathWithFilename:filename]];
    if (onDiskCachedCGImage != NULL)
        [self.cgImageCache setObject:(__bridge id)onDiskCachedCGImage forKey:filename];
    return onDiskCachedCGImage;
}


- (NSData *)pngDataFromCGImage:(CGImageRef)cgImage {
    NSMutableData *convertedImageData = [NSMutableData data];
    CGImageDestinationRef imageDataDestination = CGImageDestinationCreateWithData((CFMutableDataRef)convertedImageData, kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(imageDataDestination, cgImage, NULL);
    CGImageDestinationFinalize(imageDataDestination);
    CFRelease(imageDataDestination);
    return convertedImageData;        
}


- (CGImageRef)cgImageFromData:(NSData *)imageData {
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, NULL);
    CFRelease(imageSourceRef);
    return cgImage;
}


- (NSData *)pngDataForFilename:(NSString *)filename {
    
    NSData *inMemoryCachedPNGImageData = [self.pngDataCache objectForKey:filename];
    if (inMemoryCachedPNGImageData != nil)
        return inMemoryCachedPNGImageData;
    
    NSData *onDiskCachedPNGImageData = nil;
    NSString *path = [self pathWithFilename:filename];
    RSLockLock(&folderLock);
    if (RSFileIsPNG(path)) {
        NSError *error = nil;
        onDiskCachedPNGImageData = [self readData:filename error:&error];
    }
    RSLockUnlock(&folderLock);
    if (onDiskCachedPNGImageData != nil) {
        [self.pngDataCache setObject:onDiskCachedPNGImageData forKey:filename];
        return onDiskCachedPNGImageData;
    }
    
    /*Need to convert raw data to PNG by way of CGImage. This does not cause the CGImage
     to get cached in cgImageCache (though it may already be),
     because we might not want two copies of the image cached in memory.*/
    CGImageRef cgImage = [self cachedCGImageForFilename:filename];
    if (cgImage == NULL)
        cgImage = [self cgImageFromFile:path];
    if (cgImage == NULL)
        return nil;
    NSData *convertedPNGImageData = [self pngDataFromCGImage:cgImage];
    if (convertedPNGImageData == nil)
        return nil;
    [self.pngDataCache setObject:convertedPNGImageData forKey:filename];
    return convertedPNGImageData;
}



#pragma mark Writing

- (BOOL)saveCGImage:(CGImageRef)cgImage withFilename:(NSString *)filename error:(NSError **)error {
#pragma unused(error)
    if (cgImage == nil || RSStringIsEmpty(filename))
        return NO;
    [self.cgImageCache setObject:(__bridge id)cgImage forKey:filename];
    CGImageDestinationRef imageFileDestination = CGImageDestinationCreateWithURL((CFURLRef)[self URLWithFilename:filename], kUTTypePNG, 1, NULL);
    if (imageFileDestination == nil)
        return NO;
    CGImageDestinationAddImage(imageFileDestination, cgImage, NULL);
    RSLockLock(&folderLock);
    BOOL success = CGImageDestinationFinalize(imageFileDestination);
    RSLockUnlock(&folderLock);
    CFRelease(imageFileDestination);
    return success;
}


- (BOOL)saveImageData:(NSData *)imageData withFilename:(NSString *)filename error:(NSError **)error {
    if ([imageData dataIsPNG])
        [self.pngDataCache setObject:imageData forKey:filename];
    return [self writeData:imageData filename:filename error:error];
}


- (BOOL)writeData:(NSData *)fileData filename:(NSString *)filename error:(NSError **)error {
    RSLockLock(&folderLock);
    BOOL success = [fileData writeToFile:[self pathWithFilename:filename] options:NSAtomicWrite error:error];
    RSLockUnlock(&folderLock);
    return success;
}


- (NSData *)readData:(NSString *)filename error:(NSError **)error {
    /*Caller must have locked access.*/
    return [NSData dataWithContentsOfFile:[self pathWithFilename:filename] options:0 error:error];
}


#pragma mark Notifications

- (void)applicationDidResignActive:(NSNotification *)note {
    [self.cgImageCache removeAllObjects];
    [self.pngDataCache removeAllObjects];
}



@end

