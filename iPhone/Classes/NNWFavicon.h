//
//  NNWFavicon.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/12/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *NNWFaviconDidDownloadNotification;

@interface NNWFavicon : NSObject {

}


+ (UIImage *)imageForFeedWithGoogleID:(NSString *)googleID;
+ (void)saveFaviconMap;


@end
