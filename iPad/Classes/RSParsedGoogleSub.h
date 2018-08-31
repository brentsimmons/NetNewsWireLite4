//
//  RSParsedGoogleSub.h
//  nnwiphone
//
//  Created by Brent Simmons on 12/27/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@class RSParsedGoogleCategory;

@interface RSParsedGoogleSub : NSObject {
@private
	NSString *googleID;
	NSString *title;
	NSMutableArray *categories;
	NSString *firstItemMsec;
}


@property (nonatomic, retain) NSString *googleID;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSMutableArray *categories;
@property (nonatomic, retain) NSString *firstItemMsec;

- (void)addCategory:(RSParsedGoogleCategory *)category;


@end


@interface RSParsedGoogleCategory : NSObject {
@private
	NSString *googleID;
	NSString *label;
}


+ (RSParsedGoogleCategory *)categoryWithGoogleID:(NSString *)googleID;
+ (void)emptyCategoryCache;


@property (nonatomic, retain) NSString *googleID;
@property (nonatomic, retain) NSString *label;

- (void)setLabelIfNotSet:(NSString *)aLabel;
- (BOOL)isEmpty;


@end