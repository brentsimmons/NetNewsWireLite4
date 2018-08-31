//
//  RSParsedEnclosure.h
//  RSCoreTests
//
//  Created by Brent Simmons on 5/31/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSMimeTypes.h"


/* http://cyber.law.harvard.edu/rss/rss.html#ltenclosuregtSubelementOfLtitemgt */

@interface RSParsedEnclosure : NSObject {
@private
    NSString *urlString;
    NSString *mimeType;
    NSString *medium;
    NSInteger fileSize;
    NSInteger bitrate;
    NSInteger height;
    NSInteger width;
    BOOL didCalculateMIMEType;
    RSMediaType mediaType;
    BOOL didCalculateMediaType;
}

/*All of these may be nil or 0 except for urlString.*/

@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *mimeType;
@property (nonatomic, strong) NSString *medium;
@property (nonatomic, assign) NSInteger fileSize;
@property (nonatomic, assign) NSInteger bitrate;
@property (nonatomic, assign) NSInteger height;
@property (nonatomic, assign) NSInteger width;
@property (nonatomic, assign, readonly) RSMediaType mediaType; //RSMediaTypeVideo, etc.

- (id)initWithFeedEnclosureDictionary:(NSDictionary *)enclosureDict; //Returns nil if no URL. Works for <enclosure> and <media:content>

- (NSDictionary *)dictionaryRepresentation; //testing


@end
