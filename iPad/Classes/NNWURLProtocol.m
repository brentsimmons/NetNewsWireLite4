//
//  NNWURLProtocol.m
//  nnwiphone
//
//  Created by Brent Simmons on 9/8/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "NNWURLProtocol.h"
#import "RSMimeTypes.h"


static NSString *NNWImageURLScheme = @"nnw-image:";
static NSString *NNWReadPostImageName = @"PostReadIndicator.png";
static NSString *NNWUnreadPostImageName = @"UnreadPost.png";

static NSMutableDictionary *imagesDictionary = nil;
static NSMutableArray *imageNames = nil;


@interface NNWURLProtocol ()
+ (NSData *)imageDataForImageName:(NSString *)imageName;
@end
	
	
@implementation NNWURLProtocol

+ (void)startup {
	imagesDictionary = [[NSMutableDictionary dictionary] retain];
	imageNames = [[NSArray arrayWithObjects:NNWReadPostImageName, NNWUnreadPostImageName, nil] retain];
	for (NSString *oneImageName in imageNames)
		(void)[self imageDataForImageName:oneImageName]; // adds to cache
	[NSURLProtocol registerClass:[self class]];
}


static NSString *imageNameWithURL(NSURL *url) {
	NSString *urlString = [url absoluteString];
	if (![urlString hasPrefix:NNWImageURLScheme])
		return nil;
	NSArray *urlStringComponents = [urlString componentsSeparatedByString:@":"];
	if (urlStringComponents == nil || [urlStringComponents count] != 2)
		return nil;
	NSString *imageName = [urlStringComponents objectAtIndex:1];
	if ([imageNames containsObject:imageName])
		return imageName;
	return nil;
}


+ (BOOL)canInitWithRequest:(NSURLRequest *)theRequest {
	return [[[theRequest URL] absoluteString] hasPrefix:NNWImageURLScheme];
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}


+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
	return [[[a URL] absoluteString] isEqualToString:[[b URL] absoluteString]];
}


+ (NSData *)imageDataForImageName:(NSString *)imageName {
	NSData *imageData = nil;
	@synchronized(self) {
		NSData *imageData = [imagesDictionary objectForKey:imageName];
		if (imageData != nil)
			return imageData;
		UIImage *image = [UIImage imageNamed:imageName];
		if (image == nil)
			return nil;
		imageData = UIImagePNGRepresentation(image);
		[imagesDictionary safeSetObject:imageData forKey:imageName];
	}
	return imageData;
}


- (void)startLoading {
    id<NSURLProtocolClient> client = [self client];
    NSURLRequest *request = [self request];
	NSString *mimeType = RSPNGMimeType;
	NSString *imageName = imageNameWithURL([[self request] URL]);
	NSData *imageData = nil;
	if (imageName != nil)
		imageData = [NNWURLProtocol imageDataForImageName:imageName];
    if (imageData) {
        NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[request URL] MIMEType:mimeType expectedContentLength:[imageData length] textEncodingName:nil];
        [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowedInMemoryOnly];
        [client URLProtocol:self didLoadData:imageData];
        [client URLProtocolDidFinishLoading:self];
        [response release];
    }
	else
		[client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil]];
}


- (void)stopLoading {
}


@end
