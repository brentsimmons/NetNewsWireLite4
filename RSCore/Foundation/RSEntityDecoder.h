//
//  RSEntityDecoder.h
//  RSCoreTests
//
//  Created by Brent Simmons on 8/4/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


NSString *RSStringWithDecodedEntities(NSString *s);
NSDictionary *RSEntitiesDictionary(void);


@interface NSString (RSEntityDecoder)

+ (NSString *)rs_stringWithDecodedEntities:(NSString *)s convertCarets:(BOOL)convertCarets convertHexEntitiesOnly:(BOOL)convertHexEntitiesOnly;
+ (NSString *)rs_stringWithDecodedEntities:(NSString *)s;


@end

