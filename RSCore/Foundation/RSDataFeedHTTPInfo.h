//
//  NNWFeedHTTPInfo.h
//  NetNewsWire3.2
//
//  Created by Brent Simmons on 8/10/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TLPluginProtocols.h"


/*Used only by OnMyMac. No defined relations -- lookup via feedURL.*/

@class RSHTTPConditionalGetInfo;
@class NGFeedSpecifier;


@interface RSDataFeedHTTPInfo : NSManagedObject {
}

@property (nonatomic, retain) NSDate *dateLastChecked;
@property (nonatomic, retain) NSString *URL;
@property (nonatomic, retain) NSString *httpResponseEtag;
@property (nonatomic, retain) NSString *httpResponseLastModified;

@property (nonatomic, retain, readonly) RSHTTPConditionalGetInfo *conditionalGetInfo;

+ (RSDataFeedHTTPInfo *)fetchOrCreateFeedHTTPInfoWithFeedURL:(NSString *)aURL moc:(NSManagedObjectContext *)moc didCreate:(BOOL *)didCreate;

+ (void)saveHTTPInfoForFeedURL:(NSString *)aURL checkDate:(NSDate *)checkDate conditionalGetInfo:(RSHTTPConditionalGetInfo *)conditionalGetInfo moc:(NSManagedObjectContext *)moc;
+ (void)saveHTTPInfoForFeedSpecifier:(NGFeedSpecifier *)feedSpecifier checkDate:(NSDate *)checkDate conditionalGetInfo:(RSHTTPConditionalGetInfo *)conditionalGetInfo moc:(NSManagedObjectContext *)moc;

+ (RSHTTPConditionalGetInfo *)conditionalGetInfoForFeedURL:(NSString *)aURL moc:(NSManagedObjectContext *)moc;
+ (RSHTTPConditionalGetInfo *)conditionalGetInfoForFeedSpecifier:(id<NGFeedSpecifier>)feedSpecifier moc:(NSManagedObjectContext *)moc;

/*Returns YES if it made changes.*/
+ (BOOL)clearConditionalGetInfoForFeedURL:(NSURL *)feedURL moc:(NSManagedObjectContext *)moc;
+ (BOOL)clearConditionalGetInfoForFeedSpecifier:(NGFeedSpecifier *)feedSpecifier moc:(NSManagedObjectContext *)moc;


@end
