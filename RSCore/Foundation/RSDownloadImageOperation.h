//
//  RSDownloadImageOperation.h
//  libTapLynx
//
//  Created by Brent Simmons on 12/3/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSDownloadOperation.h"


/*Exists so that the downloaded (or fetched-from-cache) data can be transformed into
 an image on the background thread.*/

/*iPhone-only for now -- should be fairly easy to make it Mac-compatible*/

extern NSString *RSDownloadImageOperationDidCompleteNotification;


@interface RSDownloadImageOperation : RSDownloadOperation {
@private
	UIImage *image;
}


@property (nonatomic, retain, readonly) UIImage *image;


@end
