//
//  NNWFolder.h
//  nnwiphone
//
//  Created by Brent Simmons on 8/10/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


@class RSParsedGoogleCategory;

@interface NNWFolder : NSManagedObject {
}


+ (NSManagedObject *)folderWithGoogleDictionary:(RSParsedGoogleCategory *)category managedObjectContext:(NSManagedObjectContext *)moc;
+ (void)ensureParent:(NNWFolder *)folder managedObjectContext:(NSManagedObjectContext *)moc;


@end
