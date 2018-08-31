//
//  NNWGoogleLoginOperation.h
//  nnwiphone
//
//  Created by Brent Simmons on 11/24/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperation.h"


@interface NNWGoogleLoginOperation : RSOperation {
@private
	NSInteger statusCode;
}

@property (nonatomic, assign, readonly) NSInteger statusCode;

@end
