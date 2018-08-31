//
//  RSMimeTypes.m
//  nnwiphone
//
//  Created by Brent Simmons on 12/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSMimeTypes.h"
#import "RSFoundationExtras.h"


/*Text*/

NSString *RSTextHTMLSuffix = @".html";
NSString *RSTextHTMLMimeType = @"text/html";

/*Images*/

NSString *RSGIFSuffix = @".gif";
NSString *RSJJPEGSUffix = @".jpg";
NSString *RSPNGSuffix = @".png";

NSString *RSGIFMimeType = @"image/gif";
NSString *RSJPEGMimeType = @"image/jpeg";
NSString *RSPNGMimeType = @"image/png";

/*Audio*/

NSString *RSAIFFSuffix = @".aiff";
NSString *RSPLSSuffix = @".pls";

NSString *RSAudioAIFFMimeType = @"audio/aiff";
NSString *RSAudioMP3MimeType = @"audio/mp3";
NSString *RSAudioMP4MimeType = @"audio/mp4";
NSString *RSAudioMpegMimeType = @"audio/mpeg";
NSString *RSAudioMpgMimeType = @"audio/mpg";
NSString *RSAudioXM4AMimeType = @"audio/x-m4a";
NSString *RSAudioXM4VMimeType = @"audio/x-m4v";
NSString *RSAudioQuicktimeMimeType = @"audio/quicktime";
NSString *RSAudioPLSMimeType = @"audio/x-scpls";

/*Video*/

NSString *RSM4ASuffix = @".m4a";
NSString *RSM4VSuffix = @".m4v";
NSString *RSMOVSuffix = @".mov";
NSString *RSMP3Suffix = @".mp3";
NSString *RSMP4Suffix = @".mp4";
NSString *RSMPGSuffix = @".mpg";
NSString *RSQTSuffix =  @".qt";

NSString *RSVideoMP4MimeType = @"video/mp4";
NSString *RSVideoMpegMimeType = @"video/mpeg";
NSString *RSVideoMpgMimeType = @"video/mpg";
NSString *RSVideoQuicktimeMimeType = @"video/quicktime";
NSString *RSVideoXM4VMimeType = @"video/x-m4v";


#pragma mark C

NSString *RSMimeTypeForURLString(NSString *urlString) {
	urlString = [urlString rs_stringByStrippingURLQuery];
	if ([urlString hasSuffix:RSJJPEGSUffix])
		return RSJPEGMimeType;
	if ([urlString hasSuffix:RSPNGSuffix])
		return RSPNGMimeType;
	if ([urlString hasSuffix:RSGIFSuffix])
		return RSGIFMimeType;
	if ([urlString hasSuffix:RSMOVSuffix] || [urlString hasSuffix:RSQTSuffix])
		return RSVideoQuicktimeMimeType;
	if ([urlString hasSuffix:RSMPGSuffix])
		return RSVideoMpegMimeType;
	if ([urlString hasSuffix:RSMP4Suffix])
		return RSVideoMP4MimeType;
	if ([urlString hasSuffix:RSAIFFSuffix])
		return RSAudioAIFFMimeType;
	if ([urlString hasSuffix:RSMP3Suffix])
		return RSAudioMP3MimeType;
	if ([urlString hasSuffix:RSM4ASuffix])
		return RSAudioXM4AMimeType;
	if ([urlString hasSuffix:RSM4VSuffix])
		return RSVideoXM4VMimeType;
	return nil;	
}


static NSString *rs_videoMimeTypePrefix = @"video/";
static NSString *rs_xvideoMimeTypePrefix = @"x-video/";
static NSString *rs_audioMimeTypePrefix = @"audio/";
static NSString *rs_xaudioMimeTypePrefix = @"x-audio/";
static NSString *rs_imageMimeTypePrefix = @"image/";
static NSString *rs_ximageMimeTypePrefix = @"x-image/";
static NSString *rs_textMimeTypePrefix = @"text/";
static NSString *rs_xtextMimeTypePrefix = @"x-text/";

RSMediaType RSMediaTypeForMimeType(NSString *mimeType) {
	if (RSStringIsEmpty(mimeType))
		return RSMediaTypeUnknown;
	if ([mimeType hasPrefix:rs_videoMimeTypePrefix])
		return RSMediaTypeVideo;
	if ([mimeType hasPrefix:rs_xvideoMimeTypePrefix])
		return RSMediaTypeVideo;
	if ([mimeType hasPrefix:rs_audioMimeTypePrefix])
		return RSMediaTypeAudio;
	if ([mimeType hasPrefix:rs_xaudioMimeTypePrefix])
		return RSMediaTypeAudio;
	if ([mimeType hasPrefix:rs_imageMimeTypePrefix])
		return RSMediaTypeImage;	
	if ([mimeType hasPrefix:rs_ximageMimeTypePrefix])
		return RSMediaTypeImage;	
	if ([mimeType hasPrefix:rs_textMimeTypePrefix])
		return RSMediaTypeText;	
	if ([mimeType hasPrefix:rs_xtextMimeTypePrefix])
		return RSMediaTypeText;	
	return RSMediaTypeUnknown;
}


BOOL RSDataIsPNG(NSData *imageData) { //TODO: unit tests
	/* http://www.w3.org/TR/PNG/#5PNG-file-signature : "The first eight bytes of a PNG datastream always contain the following (decimal) values: 137 80 78 71 13 10 26 10" */
	const unsigned char *bytes = (const unsigned char *)[imageData bytes];
	return bytes[0] == 137 && bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G' && bytes[4] == 13 && bytes[5] == 10 && bytes[6] == 26 && bytes[7] == 10;
}

