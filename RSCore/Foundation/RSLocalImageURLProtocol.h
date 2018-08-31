//
//  NNWFaviconURLProtocol.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 10/30/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class RSImageFolderCache;

@interface RSLocalImageURLProtocol : NSURLProtocol {
}


+ (void)mapScheme:(NSString *)scheme toImageFolderCache:(RSImageFolderCache *)imageFolderCache;


@end


@interface RSFaviconURLProtocol : RSLocalImageURLProtocol

@end