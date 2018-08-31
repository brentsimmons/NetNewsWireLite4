//
//  RSFeedParserProxy.m
//  RSCoreTests
//
//  Created by Brent Simmons on 6/23/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSFeedParserProxy.h"
#import "RSFeedTypeDetector.h"
#import "RSAtomParser.h"
#import "RSRSSParser.h"
#import "RSGoogleReaderFeedParser.h"


@interface RSFeedParserProxy ()
@property (nonatomic, strong) RSAbstractFeedParser *actualParser;
@end

@implementation RSFeedParserProxy

@synthesize actualParser;



- (BOOL)parseData:(NSData *)feedData error:(NSError **)error {
    
    @autoreleasepool {
        RSFeedType feedType = RSFeedTypeForData(feedData);
        if (feedType == RSFeedTypeNotAFeed)
            return NO;
        if (feedType == RSFeedTypeAtom)
            self.actualParser = [[RSAtomParser alloc] init];
        else if (feedType == RSFeedTypeRSS)
            self.actualParser = [[RSRSSParser alloc] init];
        if (self.actualParser == nil)
            return NO;
        [self.actualParser parseData:feedData error:error];
    }
    return YES;
}


- (NSMutableDictionary *)headerItems {
    return self.actualParser.headerItems;
}


- (NSMutableArray *)newsItems {
    return self.actualParser.newsItems;
}


- (NSString *)feedTitle {
    return self.actualParser.feedTitle;
}


- (NSString *)feedHomePageURL {
    return self.actualParser.feedHomePageURL;
}


@end
