//
//  RSOperationController.m
//  libTapLynx
//
//  Created by Brent Simmons on 12/13/09.
//  Copyright 2009 NewsGator Technologies, Inc.. All rights reserved.
//

#import "RSOperationController.h"
#import "RSAppDelegateProtocols.h"
#import "RSDownloadOperation.h"
#import "RSFoundationExtras.h"
#import "RSOperation.h"


NSString *RSOperationControllerDidBeginOperationsNotification = @"RSOperationControllerDidBeginOperationsNotification";
NSString *RSOperationControllerDidEndOperationsNotification = @"RSOperationControllerDidEndOperationsNotification";

static NSMutableArray *gAllOperationControllers = nil;

@interface NSObject (RSOperationQueueStubs)
- (NSUInteger)operationCount;
- (NSString *)name;
- (void)setName:(NSString *)aName;
@end


//@interface NSOperationQueue (RSOperationController)
//- (NSUInteger)rs_operationCount;
//@end

//@implementation NSOperationQueue (RSOperationController)
//
//- (NSUInteger)rs_operationCount {
//    static NSInteger respondsToOperationCount = NSNotFound;
//    if (respondsToOperationCount == NSNotFound)
//        respondsToOperationCount = [self respondsToSelector:@selector(operationCount)];
//    if (respondsToOperationCount)
//        return [self operationCount];
//    return [[self operations] count];
//}
//
//@end


@interface RSOperationController ()

@property (nonatomic, strong, readwrite) NSMutableArray *operations;
@property (nonatomic, assign, readwrite) NSUInteger numberOfOperations;
@end


@implementation RSOperationController

@synthesize operationQueue;
@synthesize numberOfOperations;
@synthesize operations;
@synthesize tracksOperations;


#pragma mark Class Methods

+ (void)initialize {
    @synchronized([self class]) {
        if (gAllOperationControllers == nil)
            gAllOperationControllers = [NSMutableArray array];
    }
}


+ (id)sharedController {
    static id gMyInstance = nil;
    if (!gMyInstance) {
        gMyInstance = [[self alloc] init];
        ((RSOperationController *)gMyInstance).name = @"Main/Shared";
    }
    return gMyInstance;
}


+ (void)addOperationController:(RSOperationController *)operationController {
    if ([gAllOperationControllers indexOfObjectIdenticalTo:operationController] == NSNotFound)
        [gAllOperationControllers rs_safeAddObject:operationController];
}


+ (void)setSuspended:(BOOL)suspended {
    for (RSOperationController *oneOperationController in gAllOperationControllers)
        [oneOperationController setSuspended:suspended];
}


+ (void)cancelAllOperations {
    [gAllOperationControllers makeObjectsPerformSelector:@selector(cancelAllOperations)];
}


+ (void)waitUntilAllOperationsAreFinishedInAllQueues {
    NSDate *d1 = [NSDate date];
    [gAllOperationControllers makeObjectsPerformSelector:@selector(waitUntilAllOperationsAreFinished)];
    NSDate *d2 = [NSDate date];
    NSTimeInterval elapsedWaitTime = [d2 timeIntervalSinceDate:d1];
    NSLog(@"wait time: %f", elapsedWaitTime);
}


#pragma mark Init

- (id)init {
    if (![super init])
        return nil;
    tracksOperations = YES;
    operations = [NSMutableArray array];
    operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:NSOperationQueueDefaultMaxConcurrentOperationCount];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOperationDidCompleteNotification:) name:RSOperationDidCompleteNotification object:nil];
    [RSOperationController addOperationController:self];
//    [operationQueue addObserver:self forKeyPath:@"operations" options:NSKeyValueObservingOptionNew context:nil];
//    [operationQueue addObserver:self forKeyPath:@"operationCount" options:NSKeyValueObservingOptionNew context:nil];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Sending Notifications

- (void)sendDidBeginOperationsNotification {
    if (self.tracksOperations)
        [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSOperationControllerDidBeginOperationsNotification object:self userInfo:nil];
}


- (void)sendDidEndOperationsNotification {
    if (self.tracksOperations)
        [[NSNotificationCenter defaultCenter] rs_postNotificationOnMainThread:RSOperationControllerDidEndOperationsNotification object:self userInfo:nil];
}


#pragma mark KVO

//- (void)updateNumberOfOperations:(NSNumber *)numOperations {
//    NSUInteger updatedNumberOfOperations = [numOperations unsignedIntegerValue];
//    NSUInteger lastNumberOfOperations = self.numberOfOperations;
//    BOOL sendDidBeginOperationsNotification = (updatedNumberOfOperations > 0 && lastNumberOfOperations < 1);
//    BOOL sendDidEndOperationsNotification = (updatedNumberOfOperations < 1 && lastNumberOfOperations > 0);
//    self.numberOfOperations = updatedNumberOfOperations;
//    if (sendDidBeginOperationsNotification)
//        [self sendDidBeginOperationsNotification];
//    else if (sendDidEndOperationsNotification)
//        [self sendDidEndOperationsNotification];
//}


//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    if (object == self.operationQueue && ([keyPath isEqualToString:@"operations"] || [keyPath isEqualToString:@"operationCount"]))
//        [self performSelectorOnMainThread:@selector(updateNumberOfOperations:) withObject:[NSNumber numberWithUnsignedInteger:[self.operationQueue rs_operationCount]] waitUntilDone:NO];
//}


#pragma mark Notifications

- (void)handleOperationDidCompleteNotification:(NSNotification *)note {
    if (!self.tracksOperations || rs_app_delegate.appIsShuttingDown)
        return;
    if (![self.operations rs_containsObjectIdenticalTo:[note object]])
        return;
    [self.operations removeObjectIdenticalTo:[note object]];
    self.numberOfOperations = [self.operations count];
    if ([self numberOfOperations] < 1)
        [self sendDidEndOperationsNotification];
}


#pragma mark Commands

- (void)addOperation:(RSOperation *)operation {
    if (rs_app_delegate.appIsShuttingDown)
        return;
    BOOL sendDidBeginNotification = self.tracksOperations && (self.numberOfOperations < 1);
    if (self.tracksOperations)
        [self.operations rs_safeAddObject:operation];
    [self.operationQueue addOperation:operation];
    if (sendDidBeginNotification)
        [self sendDidBeginOperationsNotification];
}


- (BOOL)addOperationIfNotInQueue:(RSOperation *)operation {
    if ([self hasOperationWithType:operation.operationType andObject:operation.operationObject])
        return NO;
    [self addOperation:operation];
    return YES;
}


- (void)cancelOperation:(RSOperation *)operationToCancel {
    //[self.operations removeObjectIdenticalTo:[[operationToCancel retain] autorelease]];
    [operationToCancel cancel];
}


- (void)setSuspended:(BOOL)suspended {
    [self.operationQueue setSuspended:suspended];
}


- (void)cancelAllOperations {
    [self.operationQueue cancelAllOperations];
}


- (void)waitUntilAllOperationsAreFinished {
    NSLog(@"ops: %@", [self.operationQueue operations]);
    [self.operationQueue waitUntilAllOperationsAreFinished];
}


#pragma mark Accessors

//- (NSMutableArray *)operations {
//    return [self.operationQueue operations];
//}


- (NSUInteger)operationCount {
    return self.numberOfOperations;
//    static NSInteger respondsToOperationCountSelector = NSNotFound;
//    if (respondsToOperationCountSelector == NSNotFound)
//        respondsToOperationCountSelector = [self.operationQueue respondsToSelector:@selector(operationCount)];
//    if (respondsToOperationCountSelector == 1)
//        return [self.operationQueue operationCount];
//    return [[self.operationQueue operations] count];
}


- (NSInteger)numberOfDownloadOperations {
    NSInteger numberOfDownloadOperations = 0;
    for (RSOperation *oneOperation in self.operations) {
        if ([oneOperation isKindOfClass:[RSDownloadOperation class]])
            numberOfDownloadOperations++;
    }
    return numberOfDownloadOperations;
}


- (BOOL)hasDownloadOperationsScheduled {
    for (RSOperation *oneOperation in self.operations) {
        if ([oneOperation isKindOfClass:[RSDownloadOperation class]])
            return YES;
    }
    return NO;    
}


- (NSInteger)numberOfOperationsOfType:(NSInteger)operationType {
    NSInteger numberOfOperationsOfType = 0;
    for (RSOperation *oneOperation in self.operations) {
        if (oneOperation.operationType == operationType)
            numberOfOperationsOfType++;
    }
    return numberOfOperationsOfType;    
}


- (BOOL)hasOperationsScheduledOfType:(NSInteger)operationType {
    for (RSOperation *oneOperation in self.operations) {
        if (oneOperation.operationType == operationType)
            return YES;
    }
    return NO;
}


- (BOOL)hasOperationWithType:(NSInteger)operationType andObject:(id)object {
    for (RSOperation *oneOperation in self.operations) {
        if (![oneOperation isKindOfClass:[RSOperation class]])
            continue;
        if (oneOperation.operationType != operationType || [oneOperation isCancelled])
            continue;
        if (oneOperation.operationObject == object || [oneOperation.operationObject isEqual:object])
            return YES;
    }
    return NO;
}


- (NSString *)name {
    static NSInteger respondsToNameSelector = NSNotFound;
    if (respondsToNameSelector == NSNotFound)
        respondsToNameSelector = [self.operationQueue respondsToSelector:@selector(name)];
    if (respondsToNameSelector == 1)
        return [self.operationQueue name];
    return name;
}


- (void)setName:(NSString *)aName {
    static NSInteger respondsToSetNameSelector = NSNotFound;
    if (respondsToSetNameSelector == NSNotFound)
        respondsToSetNameSelector = [self.operationQueue respondsToSelector:@selector(setName:)];
    if (respondsToSetNameSelector == 1)
        [self.operationQueue setName:aName];
    else {
        name = aName;
    }
}    


- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - %@", self.operationQueue, [self name]];
}

@end


void RSAddOperationIfNotInQueue(RSOperation *operation) {
    if (![NSThread isMainThread])
        [[RSOperationController sharedController] performSelectorOnMainThread:@selector(addOperationIfNotInQueue:) withObject:operation waitUntilDone:NO];
    else
        [[RSOperationController sharedController] addOperationIfNotInQueue:operation];
}


