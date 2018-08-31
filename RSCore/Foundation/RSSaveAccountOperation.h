//
//  RSSaveAccountOperation.h
//  padlynx
//
//  Created by Brent Simmons on 10/16/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RSOperation.h"


@class RSDataAccount;

@interface RSSaveAccountOperation : RSOperation {
@private
	RSDataAccount *account;
}


- (id)initWithAccount:(RSDataAccount *)anAccount;


@end
