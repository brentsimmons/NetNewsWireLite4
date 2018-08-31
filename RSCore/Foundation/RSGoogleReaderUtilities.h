//
//  RSGoogleUtilities.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 12/7/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


NSURL *RSGoogleReaderURLWithClientAppended(NSString *urlString);


/*IDs
 Google IDs can be long -- like tag:google.com,2005:reader/item/1234567890123456,
 or short like just the final ID part: 1234567890123456.
 The long version is always 32 characters. Short is always 16.
 With the conversion functions, it's safe to pass in an already-shortened
 or already-lengthened ID.*/

BOOL RSGoogleReaderItemIDIsLong(NSString *itemID);

NSString *RSGoogleReaderShortItemIDForLongItemID(NSString *itemID);
NSArray *RSGoogleReaderShortItemIDsForLongItemIDs(NSArray *longItemIDs);
NSSet *RSGoogleReaderSetOfShortItemIDsForArrayOfLongItemIDs(NSArray *longItemIDs);
NSArray *RSGoogleReaderArrayOfLongItemIDsForSetOfShortItemIDs(NSSet *shortItemIDs);
NSString *RSGoogleReaderLongItemIDForShortItemID(NSString *shortItemID);
NSArray *RSGoogleReaderLongItemIDsForShortItemIDs(NSArray *shortItemIDs);

NSString *SLGoogleReaderCalculatedIDForFeedURLString(NSString *feedURLString);
NSString *SLGoogleReaderCalculatedIDForFolderName(NSString *folderName);

BOOL SLGoogleReaderGuidIsFromGoogleReader(NSString *guid);

/*Illegal characters in Google names: " < > ? & / \ ^
 Translate to: _ [ ] _ + | | _*/
NSString *SLGoogleReaderNameForFolderName(NSString *folderName);