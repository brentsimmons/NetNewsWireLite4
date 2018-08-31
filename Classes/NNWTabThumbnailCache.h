//
//  NNWTabThumbnailCache.h
//  NetNewsWire
//
//  Created by Brent Simmons on 9/19/06.
//  Copyright 2006 Ranchero Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NNWTabThumbnailCache : NSObject {
	}


+ (id)sharedCache;

- (NSImage *)imageForURLString:(NSString *)urlString;
- (void)setImage:(NSImage *)image forURLString:(NSString *)urlString;

- (NSString *)pathForURLString:(NSString *)urlString;

- (void)startupCache;


@end
