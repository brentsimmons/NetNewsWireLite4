//
//  RSLocalStyleSheetProtocol.m
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 10/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSLocalStyleSheetProtocol.h"
#import "RSCache.h"
#import "RSMimeTypes.h"


static NSString *RSStyleSheetScheme = @"rsstylesheet";
static NSString *RSStyleSheetRipplesScheme = @"ripples";
static RSCache *gStyleSheetCache = nil;


@implementation RSLocalStyleSheetProtocol

+ (void)initialize {
	@synchronized(self) {
		if (gStyleSheetCache == nil)
			gStyleSheetCache = [[RSCache alloc] init];
	}
}


+ (NSData *)cachedStyleSheetDataForURL:(NSURL *)styleSheetURL {
	return [gStyleSheetCache objectForKey:styleSheetURL];
}


+ (void)cacheStyleSheetData:(NSData *)styleSheetData forURL:(NSURL *)styleSheetURL {
	[gStyleSheetCache setObject:styleSheetData forKey:styleSheetURL];
}


+ (NSData *)handleRipplesRequest:(NSURLRequest *)request {
	/*Special case for Ripples style sheets. They each use a file outside the style sheets folder.*/
	NSData *imageData = [self cachedStyleSheetDataForURL:[request URL]];
	if (imageData != nil)
		return imageData;
	NSString *resourceSpecifier = [[request URL] resourceSpecifier];	
	NSString *path = @"/Library/Desktop Pictures/Ripples Blue.jpg";
	if ([resourceSpecifier hasPrefix:@"moss"])
		path = @"/Library/Desktop Pictures/Ripples Moss.jpg";
	else if ([resourceSpecifier hasPrefix:@"purple"])
		path = @"/Library/Desktop Pictures/Ripples Purple.jpg";
	imageData = [NSData dataWithContentsOfFile:path];
	if (imageData != nil)
		[self cacheStyleSheetData:imageData forURL:[request URL]];
	return imageData;
}


static NSString *RSStyleSheetURLStart = @"rsstylesheet://";
static NSString *RSFileURLStart = @"file://";

+ (NSData *)styleSheetDataForRequest:(NSURLRequest *)request {
	NSString *urlScheme = [[request URL] scheme];
	if ([urlScheme isEqualToString:RSStyleSheetRipplesScheme])
		return [self handleRipplesRequest:request];
	NSURL *styleSheetURL = [request URL];
	NSString *urlString = [styleSheetURL absoluteString];
	urlString = RSStringReplaceAll(urlString, RSStyleSheetURLStart, RSFileURLStart);
	styleSheetURL = [NSURL URLWithString:urlString];
	NSData *styleSheetData = [self cachedStyleSheetDataForURL:styleSheetURL];
	if (styleSheetData != nil)
		return styleSheetData;
	styleSheetData = [NSData dataWithContentsOfURL:styleSheetURL];
	if (styleSheetData == nil)
		return nil;
	if ([[[request URL] absoluteString] rs_caseInsensitiveContains:@"Ripples"] && [[[request URL] absoluteString] hasSuffix:@".css"]) { //Rewrite for Ripples special-case
		NSString *styleSheetString = [[[NSString alloc] initWithData:styleSheetData encoding:NSUTF8StringEncoding] autorelease];
		styleSheetString = RSStringReplaceAll(styleSheetString, @"file:///Library/Desktop%20Pictures/Ripples%20Blue.jpg", @"ripples:blue.jpg");
		styleSheetString = RSStringReplaceAll(styleSheetString, @"file:///Library/Desktop%20Pictures/Ripples%20Moss.jpg", @"ripples:moss.jpg");
		styleSheetString = RSStringReplaceAll(styleSheetString, @"file:///Library/Desktop%20Pictures/Ripples%20Purple.jpg", @"ripples:purple.jpg");
		styleSheetData = [styleSheetString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	}
	[self cacheStyleSheetData:styleSheetData forURL:styleSheetURL];
	return styleSheetData;
}


+ (BOOL)canInitWithRequest:(NSURLRequest *)theRequest {
	NSString *urlScheme = [[theRequest URL] scheme];
	return [urlScheme isEqualToString:RSStyleSheetScheme] || [urlScheme isEqualToString:RSStyleSheetRipplesScheme];
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}


+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
	NSString *aURLString = [[a URL] absoluteString];
	NSString *bURLString = [[b URL] absoluteString];
	return [aURLString isEqualToString:bURLString];
}


//static NSString *NNWMimeTypeForURLString(NSString *urlString);

- (void)startLoading {
	NSData *styleSheetData = [RSLocalStyleSheetProtocol styleSheetDataForRequest:[self request]];
	if (styleSheetData == nil) {
		[[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorResourceUnavailable userInfo:nil]];
		return;
	}
	NSString *mimeType = RSMimeTypeForURLString([[[self request] URL] absoluteString]);
	if (mimeType == nil)
		mimeType = @"text/html";
	NSURLResponse *response = [[NSURLResponse alloc] initWithURL:[[self request] URL] MIMEType:mimeType expectedContentLength:(NSInteger)[styleSheetData length] textEncodingName:nil];
	[[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	[[self client] URLProtocol:self didLoadData:styleSheetData];
	[[self client] URLProtocolDidFinishLoading:self];
	[response release];
}


- (void)stopLoading {
}


@end


///*TODO: use RSMimeTypes*/
//
//NSString *RSTextHTMLMimeType = @"text/html";
//NSString *RSCSSSuffix = @".css";
//NSString *RSCSSMimeType = @"text/css";
//NSString *RSJavaScriptSuffix = @".js";
//NSString *RSJavaScriptMimeType = @"text/javascript";
//
///*Images*/
//
//NSString *RSGIFSuffix = @".gif";
//NSString *RSJJPEGSUffix = @".jpg";
//NSString *RSPNGSuffix = @".png";
//
//NSString *RSGIFMimeType = @"image/gif";
//NSString *RSJPEGMimeType = @"image/jpeg";
//NSString *RSPNGMimeType = @"image/png";
//
///*Audio*/
//
//NSString *RSAIFFSuffix = @".aiff";
//NSString *RSPLSSuffix = @".pls";
//
//NSString *RSAudioAIFFMimeType = @"audio/aiff";
//NSString *RSAudioMP3MimeType = @"audio/mp3";
//NSString *RSAudioMP4MimeType = @"audio/mp4";
//NSString *RSAudioMpegMimeType = @"audio/mpeg";
//NSString *RSAudioMpgMimeType = @"audio/mpg";
//NSString *RSAudioXM4AMimeType = @"audio/x-m4a";
//NSString *RSAudioXM4VMimeType = @"audio/x-m4v";
//NSString *RSAudioQuicktimeMimeType = @"audio/quicktime";
//NSString *RSAudioPLSMimeType = @"audio/x-scpls";
//
///*Video*/
//
//NSString *RSM4ASuffix = @".m4a";
//NSString *RSM4VSuffix = @".m4v";
//NSString *RSMOVSuffix = @".mov";
//NSString *RSMP3Suffix = @".mp3";
//NSString *RSMP4Suffix = @".mp4";
//NSString *RSMPGSuffix = @".mpg";
//NSString *RSQTSuffix =  @".qt";
//
//NSString *RSVideoMP4MimeType = @"video/mp4";
//NSString *RSVideoMpegMimeType = @"video/mpeg";
//NSString *RSVideoMpgMimeType = @"video/mpg";
//NSString *RSVideoQuicktimeMimeType = @"video/quicktime";
//NSString *RSVideoXM4VMimeType = @"video/x-m4v";
//
//
//#pragma mark C
//
//static NSString *NNWMimeTypeForURLString(NSString *urlString) {
//	urlString = [urlString rs_stringByStrippingURLQuery];
//	if ([urlString hasSuffix:RSTextHTMLSuffix])
//		return RSTextHTMLMimeType;
//	if ([urlString hasSuffix:RSCSSSuffix])
//		return RSCSSMimeType;
//	if ([urlString hasSuffix:RSJavaScriptSuffix])
//		return RSJavaScriptMimeType;
//	if ([urlString hasSuffix:RSJJPEGSUffix])
//		return RSJPEGMimeType;
//	if ([urlString hasSuffix:RSPNGSuffix])
//		return RSPNGMimeType;
//	if ([urlString hasSuffix:RSGIFSuffix])
//		return RSGIFMimeType;
//	if ([urlString hasSuffix:RSMOVSuffix] || [urlString hasSuffix:RSQTSuffix])
//		return RSVideoQuicktimeMimeType;
//	if ([urlString hasSuffix:RSMPGSuffix])
//		return RSVideoMpegMimeType;
//	if ([urlString hasSuffix:RSMP4Suffix])
//		return RSVideoMP4MimeType;
//	if ([urlString hasSuffix:RSAIFFSuffix])
//		return RSAudioAIFFMimeType;
//	if ([urlString hasSuffix:RSMP3Suffix])
//		return RSAudioMP3MimeType;
//	if ([urlString hasSuffix:RSM4ASuffix])
//		return RSAudioXM4AMimeType;
//	if ([urlString hasSuffix:RSM4VSuffix])
//		return RSVideoXM4VMimeType;
//	return nil;	
//}

