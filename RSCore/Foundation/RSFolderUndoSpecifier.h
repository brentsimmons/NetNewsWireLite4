//
//  RSFolderUndoSpecifier.h
//  nnw
//
//  Created by Brent Simmons on 1/23/11.
//  Copyright 2011 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface RSFolderUndoSpecifier : NSObject {
@private
	NSString *accountID;
	NSString *folderName;
}


@property (nonatomic, retain) NSString *accountID;
@property (nonatomic, retain) NSString *folderName;


@end
