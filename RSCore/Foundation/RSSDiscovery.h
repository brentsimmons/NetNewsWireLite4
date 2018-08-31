//
//  RSSDiscovery.h
//  NetNewsWire
//
//  Created by Brent Simmons on 4/9/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RSSDiscovery : NSObject


+ (NSString *)getLinkTagURL:(NSString *)xml;
+ (NSString *)normalizeURL:(NSString *)URL;	


@end
