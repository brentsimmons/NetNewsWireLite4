//
//  RSUserInterfaceContext.m
//  padlynx
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import "RSUserInterfaceContext.h"


@interface RSUserInterfaceContext ()
#if TARGET_OS_IPHONE
@property (nonatomic, retain, readwrite) UIWindow *window;
@property (nonatomic, retain, readwrite) UIViewController *rootViewController;
@property (nonatomic, retain, readwrite) UIViewController *hostViewController;
@property (nonatomic, retain, readwrite) UIEvent *event;
@property (nonatomic, retain, readwrite) UIView *view;
@property (nonatomic, retain, readwrite) UIControl *control;
@property (nonatomic, retain, readwrite) UIBarButtonItem *barButtonItem;
#else
@property (nonatomic, strong, readwrite) NSWindow *window;
@property (nonatomic, strong, readwrite) NSViewController *rootViewController;
@property (nonatomic, strong, readwrite) NSViewController *hostViewController;
@property (nonatomic, strong, readwrite) NSEvent *event;
@property (nonatomic, strong, readwrite) NSView *view;
@property (nonatomic, strong, readwrite) NSControl *control;
#endif

- (id)findWindow:(id)sender;
- (id)findRootViewController:(id)sender;
- (void)fillInHostViewController:(id)sender;

@end

@implementation RSUserInterfaceContext

@synthesize window;
@synthesize rootViewController;
@synthesize hostViewController;
@synthesize view;
@synthesize control;
#if TARGET_OS_IPHONE
@synthesize barButtonItem;
#endif
@synthesize event;


#pragma mark Class Methods

+ (RSUserInterfaceContext *)contextWithViewController:(id)aViewController view:(id)aView control:(id)aControl barButtonItem:(id)aBarButtonItem event:(id)anEvent {
    return [[self alloc] initWithViewController:aViewController view:aView control:aControl barButtonItem:aBarButtonItem event:anEvent];
}

#pragma mark Init

- (RSUserInterfaceContext *)initWithViewController:(id)aViewController view:(id)aView control:(id)aControl barButtonItem:(id)aBarButtonItem event:(id)anEvent {
    self = [super init];
    if (self == nil)
        return nil;
    hostViewController = aViewController;
    view = aView;
#if TARGET_OS_IPHONE
    barButtonItem = [aBarButtonItem retain];
#endif
    control = aControl;
    event = anEvent;
    window = [self findWindow:aView];
    rootViewController = [self findRootViewController:aView];
    if (hostViewController == nil)
        [self fillInHostViewController:aView];
    return self;
}


#pragma mark Dealloc



#pragma mark Filling In

- (Class)windowClass {
#if TARGET_OS_IPHONE
    return [UIWindow class];
#else
    return [NSWindow class];
#endif
}


- (Class)responderClass {
#if TARGET_OS_IPHONE
    return [UIResponder class];
#else
    return [NSResponder class];
#endif    
}


- (Class)viewControllerClass {
#if TARGET_OS_IPHONE
    return [UIViewController class];
#else
    return [NSViewController class];
#endif    
}


- (id)sharedApplication {
#if TARGET_OS_IPHONE
    return [UIApplication sharedApplication];
#else
    return NSApp;
#endif        
}


- (id)findWindow:(id)sender {
    
    if ([sender isKindOfClass:[self windowClass]])
        return sender;
    if ([sender respondsToSelector:@selector(window)] && [sender window] != nil)
        return [sender window];
    
    if ([sender isKindOfClass:[self responderClass]]) {
        id nomadResponder = sender;
        while (true) {
            if ([nomadResponder isKindOfClass:[self windowClass]])
                return nomadResponder;
            nomadResponder = [nomadResponder nextResponder];
            if (nomadResponder == nil)
                break;
        }
    }
    
    if ([[self sharedApplication] keyWindow] != nil)
        return [[self sharedApplication] keyWindow];
#if !TARGET_OS_IPHONE
    if ([[self sharedApplication] respondsToSelector:@selector(mainWindow)] && [[self sharedApplication] mainWindow] != nil)
        return [[self sharedApplication] mainWindow];
#endif
    return [[[self sharedApplication] windows] rs_safeObjectAtIndex:0];
}


- (void)fillInWindow:(id)sender {
    self.window = [self findWindow:sender];
}


- (id)findRootViewController:(id)sender {
#if TARGET_OS_IPHONE
    if ([self.window respondsToSelector:@selector(rootViewController)])
        return self.window.rootViewController;
#endif
    if ([sender isKindOfClass:[self responderClass]]) {
        id nomadResponder = sender;
        id lastViewControllerFound = nil;
        while (true) {
            if ([nomadResponder isKindOfClass:[self viewControllerClass]])
                lastViewControllerFound = nomadResponder;
            nomadResponder = [nomadResponder nextResponder];
            if (nomadResponder == nil)
                break;
        }
        if (lastViewControllerFound != nil)
            return lastViewControllerFound;
    }
    return nil;
}


- (void)fillInRootViewController:(id)sender {
    self.rootViewController = [self findRootViewController:sender];
}


- (id)findHostViewController:(id)sender {
    if (![sender isKindOfClass:[self responderClass]])
        return nil;
    id nomadResponder = sender;
    while (true) {
        if ([nomadResponder isKindOfClass:[self viewControllerClass]])
            return nomadResponder;
        nomadResponder = [nomadResponder nextResponder];
        if (nomadResponder == nil)
            break;        
    }
    return nil;
}


- (void)fillInHostViewController:(id)sender {
    self.hostViewController = [self findHostViewController:sender];
#if !TARGET_OS_IPHONE
    if (self.hostViewController == nil)
        self.hostViewController = [self findHostViewController:[self.window firstResponder]];
#endif
}


- (void)fillInMissingObjects:(id)sender event:(id)anEvent {
    if (self.window == nil)
        [self fillInWindow:sender];
    if (self.rootViewController == nil)
        [self fillInRootViewController:sender];
    if (self.hostViewController == nil)
        [self fillInHostViewController:sender];
    if (self.event == nil)
        self.event = anEvent;
}


@end
