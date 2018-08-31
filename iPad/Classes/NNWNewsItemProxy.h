//
//  NNWNewsItemProxy.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/28/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NNWProxy.h"


@interface NNWNewsItemProxy : NNWProxy {
@protected
	NSString *_plainTextTitle;
	NSDate *_datePublished;
#if MEDIA_PLAYBACK
	NSString *_movieURLString;
	NSString *_audioURLString;
#endif
	NSString *_googleFeedID;
	NSString *_googleFeedTitle;
	NSString *_thumbnailURLString;
	BOOL _read;
	BOOL _starred;
	NSString *_preview;
	NSString *_displayDate;
	//NSString *_displaySectionName;
	NSString *_permalink;
	NSString *htmlContent;
	NSString *link;
	NSString *author;
	BOOL _inflated;
}


@property (retain) NSString *plainTextTitle;
@property (retain) NSDate *datePublished;
#if MEDIA_PLAYBACK
@property (retain) NSString *movieURLString;
@property (retain) NSString *audioURLString;
#endif
@property (retain) NSString *googleFeedID;
@property (retain) NSString *googleFeedTitle;
@property (retain) NSString *thumbnailURLString;
@property (assign) BOOL read;
@property (assign) BOOL starred;
@property (retain) NSString *preview;
@property (nonatomic, retain, readonly) NSString *displayDate;
//@property (nonatomic, retain, readonly) NSString *displaySectionName;
@property (retain) NSString *permalink;
@property (assign) BOOL inflated;
@property (retain) NSString *htmlContent;
@property (retain) NSString *link;
@property (retain) NSString *author;

+ (void)userMarkNewsItemsAsRead:(NSArray *)newsItems;

- (void)userMarkAsRead;
- (void)userMarkAsStarred;
- (void)userToggleStarred;

//- (void)buildDisplayDate;
//- (void)buildDisplaySectionName;


@end
