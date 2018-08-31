//
//  RSOperationController.h
//  libTapLynx
//
//  Created by Brent Simmons on 12/13/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>


/*Main thread only -- except for C method RSAddOperationIfNotInQueue*/


@class RSOperation;

/*Only sent if tracksOperations is YES.*/
extern NSString *RSOperationControllerDidBeginOperationsNotification;
extern NSString *RSOperationControllerDidEndOperationsNotification;


extern void RSAddOperationIfNotInQueue(RSOperation *operation); /*Works only with shared controller, and only when tracksOperations is YES*/

@interface RSOperationController : NSObject {
@private
	NSMutableArray *operations;
	NSOperationQueue *operationQueue;
	NSUInteger numberOfOperations;
	NSString *name;
	BOOL tracksOperations;
}

+ (id)sharedController; /*There's a main controller, but it's okay to create more than one*/
+ (void)setSuspended:(BOOL)suspended; /*suspend or unsuspend all*/
+ (void)cancelAllOperations; /*for all, not just sharedController*/

- (BOOL)hasDownloadOperationsScheduled;
- (BOOL)hasOperationsScheduledOfType:(NSInteger)operationType;
- (BOOL)hasOperationWithType:(NSInteger)operationType andObject:(id)object;

- (void)addOperation:(RSOperation *)operation;
- (BOOL)addOperationIfNotInQueue:(RSOperation *)operation; //Requires tracksOperations to be YES
- (void)cancelOperation:(RSOperation *)operationToCancel;
- (void)cancelAllOperations;
+ (void)waitUntilAllOperationsAreFinishedInAllQueues;

- (void)setSuspended:(BOOL)suspended;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain, readonly) NSOperationQueue *operationQueue;

@property (nonatomic, assign) BOOL tracksOperations; //default is YES -- otherwise operations and numberOfOperations are undefined
@property (nonatomic, retain, readonly) NSMutableArray *operations; 
@property (nonatomic, assign, readonly) NSUInteger numberOfOperations;
@end
