//
//  RSFeedParserProxy.h
//  RSCoreTests
//
//  Created by Brent Simmons on 6/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*When you have an entire feed and want to parse the entire thing and you don't care what type it is.
 This proxy will find the right type, use the right parser, and act as if it's the actual parser --
 that is, you can get headerItems and newsItems from it once parsing is finished.
 No delegates, no streaming, just simple parse this big document and give me results.*/


@class RSAbstractFeedParser;


@interface RSFeedParserProxy : NSObject {
@private
    RSAbstractFeedParser *actualParser;
}


@property (nonatomic, strong, readonly) NSMutableDictionary *headerItems;
@property (nonatomic, strong, readonly) NSMutableArray *newsItems;
@property (nonatomic, strong, readonly) NSString *feedTitle;
@property (nonatomic, strong, readonly) NSString *feedHomePageURL;

- (BOOL)parseData:(NSData *)feedData error:(NSError **)error;


@end
