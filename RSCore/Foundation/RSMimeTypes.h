//
//  RSMimeTypes.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


/*Text*/

extern NSString *RSTextHTMLSuffix;
extern NSString *RSTextHTMLMimeType;

/*Images*/

extern NSString *RSGIFSuffix; // .gif
extern NSString *RSJJPEGSUffix; // .jpg
extern NSString *RSPNGSuffix; // .png

extern NSString *RSGIFMimeType; // image/gif
extern NSString *RSJPEGMimeType; // image/jpeg
extern NSString *RSPNGMimeType; // image/png

/*Audio*/

extern NSString *RSAIFFSuffix; // .aiff
extern NSString *RSPLSSuffix; //pls

extern NSString *RSAudioAIFFMimeType; // audio/aiff
extern NSString *RSAudioMP3MimeType; // audio/mp3
extern NSString *RSAudioMP4MimeType; // audio/mp4
extern NSString *RSAudioMpegMimeType; // audio/mpeg
extern NSString *RSAudioMpgMimeType; // audio/mpg
extern NSString *RSAudioXM4AMimeType; // audio/x-m4a
extern NSString *RSAudioXM4VMimeType; // audio/x-m4v
extern NSString *RSAudioQuicktimeMimeType; // audio/quicktime
extern NSString *RSAudioPLSMimeType; //audio/x-scpls

/*Video*/

extern NSString *RSM4ASuffix; // .m4a
extern NSString *RSM4VSuffix; // .m4v
extern NSString *RSMOVSuffix; // .mov
extern NSString *RSMP3Suffix; // .mp3
extern NSString *RSMP4Suffix; // .mp4
extern NSString *RSMPGSuffix; // .mpg
extern NSString *RSQTSuffix; // .qt

extern NSString *RSVideoMP4MimeType; // video/mp4
extern NSString *RSVideoMpegMimeType; // video/mpeg
extern NSString *RSVideoMpgMimeType; // video/mpg
extern NSString *RSVideoQuicktimeMimeType; // video/quicktime
extern NSString *RSVideoXM4VMimeType; // video/x-m4v

/*High-level app-defined types*/

typedef enum _RSMediaType {
	RSMediaTypeUnknown,
	RSMediaTypeVideo,
	RSMediaTypeAudio,
	RSMediaTypeImage,
	RSMediaTypeText
} RSMediaType;


NSString *RSMimeTypeForURLString(NSString *urlString); //Best when this can be avoided, because it's just a guess. May return nil.
RSMediaType RSMediaTypeForMimeType(NSString *mimeType);

BOOL RSDataIsPNG(NSData *imageData);

