//
//  RSGoogleReaderParsedSub.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/27/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@class RSGoogleReaderParsedCategory;

@interface RSGoogleReaderParsedSub : NSObject {
@private
	NSString *googleID;
	NSString *title;
	NSMutableArray *categories;
	NSString *firstItemMsec;
	NSTimeInterval firstItemTimestamp;
}


@property (nonatomic, retain) NSString *googleID;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, retain) NSString *firstItemMsec;
@property (nonatomic, assign, readonly) NSTimeInterval firstItemTimestamp;

- (void)addCategory:(RSGoogleReaderParsedCategory *)category;


@end


@interface RSGoogleReaderParsedCategory : NSObject {
@private
	NSString *googleID;
	NSString *label;
}


+ (RSGoogleReaderParsedCategory *)categoryWithGoogleID:(NSString *)aGoogleID;
+ (void)emptyCategoryCache;


@property (nonatomic, retain) NSString *googleID;
@property (nonatomic, retain) NSString *label;

- (void)setLabelIfNotSet:(NSString *)aLabel;
- (BOOL)isEmpty;


@end
