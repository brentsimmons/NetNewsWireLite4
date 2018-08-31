//
//  RSParsedEnclosure.m
//  RSCoreTests
//
//  Created by Brent Simmons on 5/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSParsedEnclosure.h"
#import "RSFoundationExtras.h"
#import "RSMimeTypes.h"


@interface RSParsedEnclosure ()
@property (nonatomic, assign, readwrite) BOOL didCalculateMIMEType;
@property (nonatomic, assign, readwrite) RSMediaType mediaType;
@property (nonatomic, assign, readwrite) BOOL didCalculateMediaType;
@end


@implementation RSParsedEnclosure

@synthesize urlString;
@synthesize mimeType;
@synthesize medium;
@synthesize fileSize;
@synthesize bitrate;
@synthesize height;
@synthesize width;
@synthesize didCalculateMIMEType;
@synthesize mediaType;
@synthesize didCalculateMediaType;


#pragma mark -
#pragma mark Init

static NSString *RSParsedEnclosureURLStringKey = @"url";
static NSString *RSParsedEnclosureURLString2Key = @"href";
static NSString *RSParsedEnclosureMimeTypeKey = @"mimeType";
static NSString *RSParsedEnclosureMimeType2Key = @"type";
static NSString *RSParsedEnclosureMediumKey = @"medium";
static NSString *RSParsedEnclosureFileSizeKey = @"fileSize";
static NSString *RSParsedEnclosureFileSize2Key = @"length";
static NSString *RSParsedEnclosureBitrateKey = @"bitrate";
static NSString *RSParsedEnclosureHeightKey = @"height";
static NSString *RSParsedEnclosureWidthKey = @"width";


- (id)initWithFeedEnclosureDictionary:(NSDictionary *)enclosureDict {
    if (![super init])
        return nil;
    NSString *aURLString = [enclosureDict objectForKey:RSParsedEnclosureURLStringKey];
    if (RSStringIsEmpty(aURLString))
        aURLString = [enclosureDict objectForKey:RSParsedEnclosureURLString2Key];
    if (RSStringIsEmpty(aURLString))
        return nil;
    mediaType = RSMediaTypeUnknown;
    urlString = aURLString;
    mimeType = [enclosureDict objectForKey:RSParsedEnclosureMimeTypeKey];
    if (RSStringIsEmpty(mimeType))
        mimeType = [enclosureDict objectForKey:RSParsedEnclosureMimeType2Key];
    medium = [enclosureDict objectForKey:RSParsedEnclosureMediumKey];
    fileSize = [enclosureDict rs_integerForKey:RSParsedEnclosureFileSizeKey];
    if (fileSize < 1)
        fileSize = [enclosureDict rs_integerForKey:RSParsedEnclosureFileSize2Key];
    width = [enclosureDict rs_integerForKey:RSParsedEnclosureWidthKey];
    height = [enclosureDict rs_integerForKey:RSParsedEnclosureHeightKey];
    bitrate = [enclosureDict rs_integerForKey:RSParsedEnclosureBitrateKey];
    return self;
}


#pragma mark Dealloc



#pragma mark Accessors

- (NSString *)mimeType {
    /*Calculated (once) if needed. It's possible that the calculation will fail: mimeType may be nil.*/
    if (mimeType != nil || self.didCalculateMIMEType)
        return mimeType;
    self.mimeType = RSMimeTypeForURLString(self.urlString);
    self.didCalculateMIMEType = YES;
    return mimeType;
}


- (RSMediaType)mediaType {
    if (mediaType != RSMediaTypeUnknown || self.didCalculateMediaType)
        return mediaType;
    mediaType = RSMediaTypeForMimeType(self.mimeType);
    self.didCalculateMediaType = YES;
    return mediaType;
}


#pragma mark Testing

- (NSDictionary *)dictionaryRepresentation {
    CFMutableDictionaryRef d = CFDictionaryCreateMutable(kCFAllocatorDefault, 8, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); //no copy keys
    if (self.urlString != nil)
        CFDictionarySetValue(d, (CFStringRef)RSParsedEnclosureURLStringKey, (CFStringRef)(self.urlString));
    if (self.mimeType != nil)
        CFDictionarySetValue(d, (CFStringRef)RSParsedEnclosureMimeTypeKey, (CFStringRef)(self.mimeType));
    if (self.medium != nil)
        CFDictionarySetValue(d, (CFStringRef)RSParsedEnclosureMediumKey, (CFStringRef)(self.medium));
    if (self.fileSize > 0)
        CFDictionarySetValue(d, (CFStringRef)RSParsedEnclosureFileSizeKey, (CFNumberRef)[NSNumber numberWithInteger:self.fileSize]);
    if (self.bitrate > 0)
        CFDictionarySetValue(d, (CFStringRef)RSParsedEnclosureBitrateKey, (CFNumberRef)[NSNumber numberWithInteger:self.bitrate]);
    if (self.height > 0)
        CFDictionarySetValue(d, (CFStringRef)RSParsedEnclosureHeightKey, (CFNumberRef)[NSNumber numberWithInteger:self.height]);
    if (self.width > 0)
        CFDictionarySetValue(d, (CFStringRef)RSParsedEnclosureWidthKey, (CFNumberRef)[NSNumber numberWithInteger:self.width]);
    return (__bridge_transfer NSDictionary *)d;
}


@end
