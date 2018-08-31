//
//  NNWFeedFinder.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 7/21/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*Subscribes to a new feed. Finds the feed via RSS discovery, if needed.*/

enum {
    NNWErrorCouldNotFindFeed = 1000
};

@class NNWFeedFinder;


@protocol NNWFeedFinderDelegate <NSObject>

@required
- (void)feedFinder:(NNWFeedFinder *)feedFinder didFindFeedAtURL:(NSURL *)url;
- (void)feedFinder:(NNWFeedFinder *)feedFinder didFailWithError:(NSError *)error;

@end


@interface NNWFeedFinder : NSObject {
@private
    NSInteger statusCode;
    NSMutableData *responseBody;
    NSMutableDictionary *urlsRead;
    NSString *password;
    NSString *username;
    NSTimer *keepAliveTimer;
    NSURL *originalURL;
    NSURL *permanentURL;
    NSURLRequest *urlRequest;
    id<NNWFeedFinderDelegate> __unsafe_unretained delegate;
}

- (id)initWithURL:(NSURL *)url delegate:(id<NNWFeedFinderDelegate>)aDelegate;
- (void)findFeed;

@property (copy) NSString *password;
@property (copy) NSString *username;
@property (nonatomic, assign, readonly) NSInteger statusCode;
@property (nonatomic, strong, readonly) NSMutableData *responseBody;
@property (nonatomic, strong, readonly) NSURL *originalURL;
@property (nonatomic, strong, readonly) NSURL *permanentURL;

@end

