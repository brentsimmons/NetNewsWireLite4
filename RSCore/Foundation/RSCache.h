//
//  RSCache.h
//  libTapLynx
//
//  Created by Brent Simmons on 7/12/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/*Thread-safe *in-memory* cache.
 
 Super-easy to use. Treat it like a mutable dictionary.
 
 Uses NSCache when it's available. OK if not available -- still runs on OS X 10.5 and iOS 3.x.
 Removes objects automatically when receives memory warning.*/


@interface RSCache : NSObject {
@private
	BOOL useNSCache;
	NSMutableDictionary *cacheDictionary;
	id nativeCache; //NSCache object
	pthread_mutex_t cacheLock;
}


+ (id)cache; //convenience, not special

- (id)objectForKey:(id)key;
- (void)setObject:(id)obj forKey:(id)key;
- (void)setObjectIfNotNil:(id)obj forKey:(id)key;
- (void)removeObjectForKey:(id)key;

- (void)removeAllObjects;

@property (nonatomic, assign) NSUInteger countLimit; //normally 0 (unlimited). Only works when cache is native NSCache.

@end
