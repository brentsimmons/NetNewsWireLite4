//
//  NNWFaviconURLProtocol.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 10/30/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSLocalImageURLProtocol.h"
#import "RSImageFolderCache.h"


static NSMutableDictionary *gSchemeToCacheDictionary = nil;

@implementation RSLocalImageURLProtocol

+ (void)initialize {
    @synchronized(self) {
        if (gSchemeToCacheDictionary == nil)
            gSchemeToCacheDictionary = [[NSMutableDictionary alloc] init];
    }
}


+ (RSImageFolderCache *)cacheForScheme:(NSString *)scheme {
    return [gSchemeToCacheDictionary objectForKey:scheme];
}


+ (RSImageFolderCache *)cacheForRequest:(NSURLRequest *)request {
    return [self cacheForScheme:[[request URL] scheme]];
}


+ (NSData *)pngImageDataForRequest:(NSURLRequest *)request {
    RSImageFolderCache *imageFolderCache = [self cacheForRequest:request];
    if (imageFolderCache == nil)
        return nil;
    return [imageFolderCache pngDataForFilename:[[request URL] resourceSpecifier]];
}


+ (void)mapScheme:(NSString *)scheme toImageFolderCache:(RSImageFolderCache *)imageFolderCache {
    [gSchemeToCacheDictionary setObject:imageFolderCache forKey:scheme];
}


+ (BOOL)canInitWithRequest:(NSURLRequest *)theRequest {
    return [gSchemeToCacheDictionary objectForKey:[[theRequest URL] scheme]] != nil;
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}


+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    NSString *aURLString = [[a URL] absoluteString];
    NSString *bURLString = [[b URL] absoluteString];
    return [aURLString isEqualToString:bURLString];
}


static NSString *RSPNGMimeType = @"image/png";

- (void)startLoading {
    NSData *pngImageData = [RSLocalImageURLProtocol pngImageDataForRequest:[self request]];
    if (pngImageData == nil) {
        [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil]];
        return;
    }
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[[self request] URL] MIMEType:RSPNGMimeType expectedContentLength:(NSInteger)[pngImageData length] textEncodingName:nil];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    [[self client] URLProtocol:self didLoadData:pngImageData];
    [[self client] URLProtocolDidFinishLoading:self];
}


- (void)stopLoading {
}


@end


@implementation RSFaviconURLProtocol

- (void)startLoading {
    NSData *pngImageData = [RSLocalImageURLProtocol pngImageDataForRequest:[self request]];
    if (pngImageData == nil) {
        static NSData *defaultPNGImageData = nil;
        if (defaultPNGImageData == nil) {
            NSString *pathToDefaultFavicon = [[NSBundle mainBundle] pathForResource:@"DefaultFavicon" ofType:@"png"];
            if (!RSStringIsEmpty(pathToDefaultFavicon))
                defaultPNGImageData = [NSData dataWithContentsOfFile:pathToDefaultFavicon];
        }
        if (defaultPNGImageData == nil) {
            [[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil]];
            return;
        }
        else
            pngImageData = defaultPNGImageData;
    }
    NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[[self request] URL] MIMEType:RSPNGMimeType expectedContentLength:(NSInteger)[pngImageData length] textEncodingName:nil];
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    [[self client] URLProtocol:self didLoadData:pngImageData];
    [[self client] URLProtocolDidFinishLoading:self];
}

@end

