//
//  RSPluginManager.m
//  padlynx
//
//  Created by Brent Simmons on 10/2/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <objc/runtime.h>
#import "RSPluginManager.h"
#import "RSPluginProtocols.h"
#import "RSObserverProtocols.h"
#import "RSUserInterfaceContext.h"
#if TARGET_OS_IPHONE
#import "RSPluginHelperiOS.h"
#else
#import "RSPluginHelper.h"
#endif

@interface RSPluginManager ()

@property (nonatomic, strong) NSMutableArray *plugins;
@property (nonatomic, strong) NSMutableArray *commands;
@property (nonatomic, strong, readwrite) NSArray *sharingCommands;
@property (nonatomic, strong) id<RSPluginHelper> pluginHelper;
@property (nonatomic, strong) NSMutableArray *pluginClasses;
@property (nonatomic, strong) NSMutableArray *appObserverPlugins;
@property (nonatomic, strong) NSMutableArray *adManagerPlugins;
@end


@implementation RSPluginManager

@synthesize plugins;
@synthesize commands;
@synthesize sharingCommands;
@synthesize pluginHelper;
@synthesize pluginClasses;
@synthesize appObserverPlugins;
@synthesize adManagerPlugins;

#pragma mark Class Method

+ (RSPluginManager *)sharedManager {
    static id gMyInstance = nil;
    if (gMyInstance == nil)
        gMyInstance = [[self alloc] init];
    return gMyInstance;
}


#pragma mark Init

- (id)init {
    self = [super init];
    if (self == nil)
        return nil;
    plugins = [NSMutableArray array];
    pluginClasses = [NSMutableArray array];
    commands = [NSMutableArray array];
    appObserverPlugins = [NSMutableArray array];
#if TARGET_OS_IPHONE
    pluginHelper = [[RSPluginHelperiOS alloc] init];
    adManagerPlugins = [[NSMutableArray array] retain];
#else
    pluginHelper = [[RSPluginHelper alloc] init];
#endif
    return self;
}


#pragma mark Dealloc



#pragma mark Registering

- (void)updateSharingCommands {
    self.sharingCommands = [self commandsOfType:RSPluginCommandTypeSharing];
}


- (void)registerCommandsInPlugin:(id<RSPlugin>)plugin {
    if (![plugin respondsToSelector:@selector(allCommands)])
        return;
    for (id oneCommand in plugin.allCommands) {
        if ([oneCommand conformsToProtocol:@protocol(RSPluginCommand)])
            [self.commands addObject:oneCommand];
    }
    [self updateSharingCommands];
}


- (void)registerObserverPlugin:(id<RSAppObserver>)plugin {
    [self.appObserverPlugins addObject:plugin];
}

//#if TARGET_OS_IPHONE
//
//- (void)registerAdPlugin:(id<RSAdManager>)plugin {
//    [self.adManagerPlugins addObject:plugin];
//}
//
//#endif


- (void)registerPluginOfClass:(Class)pluginClass {
    if ([self.pluginClasses containsObject:pluginClass] || ![pluginClass conformsToProtocol:@protocol(RSPlugin)])
        return;
    [self.pluginClasses addObject:pluginClass];
    id<RSPlugin> plugin = [[pluginClass alloc] init];
    if ([plugin respondsToSelector:@selector(shouldRegister:)] && ![plugin shouldRegister:self])
        return;
    if ([plugin respondsToSelector:@selector(willRegister:)])
        [plugin willRegister];
    [self.plugins addObject:plugin];
    [self registerCommandsInPlugin:plugin];
    if ([plugin conformsToProtocol:@protocol(RSAppObserver)])
        [self registerObserverPlugin:(id<RSAppObserver>)plugin];
//#if TARGET_OS_IPHONE
//    if ([plugin conformsToProtocol:@protocol(RSAdManager)])
//        [self registerAdPlugin:(id<RSAdManager>)plugin];
//#endif
    if ([plugin respondsToSelector:@selector(didRegister:)])
        [plugin didRegister];
}


- (void)registerPlugins:(NSArray *)somePluginClasses {
    for (Class onePluginClass in somePluginClasses)
        [self registerPluginOfClass:onePluginClass];
}


- (void)registerPluginsWithClassNames:(NSArray *)somePluginClassNames {
    for (NSString *onePluginClassName in somePluginClassNames) {
        Class onePluginClass = NSClassFromString(onePluginClassName);
        if (onePluginClass == nil)
            NSLog(@"Can't register plugin with class name %@ because the class doesn't exist.", onePluginClassName);
        else
            [self registerPluginOfClass:onePluginClass];
    }
}


#pragma mark Loading

#if !TARGET_OS_IPHONE

- (void)loadPluginsFromFolder:(NSURL *)aFolder {
    
}


- (void)loadPluginsFromUserPluginsFolder {
    //TODO: loadPluginsFromUserPluginsFolder
}


- (void)loadPluginsFromBuiltinPluginsFolder {
    
}

#endif


- (void)loadPluginsFromPluginsFolders {
#if !TARGET_OS_IPHONE
    [self loadPluginsFromBuiltinPluginsFolder];
    [self loadPluginsFromUserPluginsFolder];
#endif
}


- (void)loadUserPlugins {
#if !TARGET_OS_IPHONE
    [self loadPluginsFromUserPluginsFolder];
#endif
}


#pragma mark Running Commands

- (BOOL)runPluginCommand:(id<RSPluginCommand>)pluginCommand withItems:(NSArray *)items sendingViewController:(id)sendingViewController sendingView:(id)sendingView sendingControl:(id)sendingControl barButtonItem:(id)barButtonItem event:(id)event error:(NSError **)error {
    RSUserInterfaceContext *userInterfaceContext = [RSUserInterfaceContext contextWithViewController:(id)sendingViewController view:(id)sendingView control:(id)sendingControl barButtonItem:(id)barButtonItem event:(id)event];
    return [pluginCommand performCommandWithArray:items userInterfaceContext:userInterfaceContext pluginHelper:self.pluginHelper error:error];
}


#pragma mark Validation

- (BOOL)validateCommand:(id<RSPluginCommand>)pluginCommand withArray:(NSArray *)items {
    return [pluginCommand validateCommandWithArray:items];
}


- (NSArray *)validCommandsOfType:(NSInteger)commandType forArray:(NSArray *)items {
    NSMutableArray *validCommands = [NSMutableArray array];
    NSArray *commandsToValidate = [self commandsOfType:commandType];
    for (id<RSPluginCommand> oneCommand in commandsToValidate) {
        if ([self validateCommand:oneCommand withArray:items])
            [validCommands addObject:oneCommand];
    }
    return validCommands;
}


#pragma mark Commands of Type

- (BOOL)command:(id<RSPluginCommand>)command isOfType:(NSInteger)commandType {
    for (NSNumber *oneCommandType in command.commandTypes) {
        if (commandType == [oneCommandType integerValue])
            return YES;
    }
    return NO;
}


- (NSArray *)commandsOfType:(NSInteger)commandType {
    NSMutableArray *someCommands = [NSMutableArray array];
    for (id<RSPluginCommand> oneCommand in self.commands) {
        if ([self command:oneCommand isOfType:commandType])
            [someCommands addObject:oneCommand];
    }
    return someCommands;
}


#pragma mark Plugins of Type

- (NSArray *)sharingCommandsInPlugin:(id<RSPlugin>)aPlugin {
    if (![aPlugin respondsToSelector:@selector(allCommands)])
        return nil;
    NSMutableArray *pluginSharingCommands = [NSMutableArray array];
    for (id<RSPluginCommand> oneCommand in aPlugin.allCommands) {
        if ([oneCommand.commandTypes containsObject:[NSNumber numberWithInteger:RSPluginCommandTypeSharing]])
            [pluginSharingCommands addObject:oneCommand];
    }
    return pluginSharingCommands;    
}


- (BOOL)pluginContainsAtLeastOneSharingCommand:(id<RSPlugin>)aPlugin {
    if (![aPlugin respondsToSelector:@selector(allCommands)])
        return NO;
    for (id<RSPluginCommand> oneCommand in aPlugin.allCommands) {
        if ([oneCommand.commandTypes containsObject:[NSNumber numberWithInteger:RSPluginCommandTypeSharing]])
            return YES;
    }
    return NO;
}


- (NSArray *)sharingPlugins {
    NSMutableArray *tempArray = [NSMutableArray array];
    for (id<RSPlugin> onePlugin in self.plugins) {
        if ([self pluginContainsAtLeastOneSharingCommand:onePlugin])
            [tempArray addObject:onePlugin];
    }
    return tempArray;
}


#pragma mark Finding a Commands

- (id<RSPluginCommand>)pluginCommandOfClass:(Class)aClass {
    for (id<RSPlugin>onePlugin in self.plugins) {
        if (![onePlugin respondsToSelector:@selector(allCommands)])
            continue;
        for (id<RSPluginCommand>onePluginCommand in onePlugin.allCommands) {
            if ([onePluginCommand isKindOfClass:aClass])
                return onePluginCommand;
        }
    }
    return nil;
}


//- (id<RSPluginCommand>)pluginCommandOfClass:(Class)aClass {
//    for (id<RSPluginCommand> onePluginCommand in self.sharingCommands) {
//        if ([onePluginCommand isKindOfClass:aClass])
//            return onePluginCommand;
//    }
//    return nil;    
//}


- (id<RSPluginCommand>)pluginCommandWithCommandID:(NSString *)aCommandID {

    if (RSStringIsEmpty(aCommandID))
        return nil;

    for (id<RSPlugin>onePlugin in self.plugins) {
        if (![onePlugin respondsToSelector:@selector(allCommands)])
            continue;
        for (id<RSPluginCommand>onePluginCommand in onePlugin.allCommands) {
            if ([onePluginCommand respondsToSelector:@selector(commandID)] && [onePluginCommand.commandID isEqualToString:aCommandID])
                return onePluginCommand;
        }
    }
    return nil;    
}


- (id<RSPluginCommand>)sharingCommandWithCommandID:(NSString *)aCommandID {
    if (RSStringIsEmpty(aCommandID))
        return nil;
    for (id<RSPluginCommand> onePluginCommand in self.sharingCommands) {
        if ([onePluginCommand respondsToSelector:@selector(commandID)] && [onePluginCommand.commandID isEqualToString:aCommandID])
            return onePluginCommand;
    }
    return nil;    
}


#pragma mark Calling Plugins

- (void)makePlugins:(NSArray *)somePlugins performSelector:(SEL)aSelector withObject:(id)anObject {
    @autoreleasepool {
        for (id<RSPlugin> onePlugin in somePlugins) {
            if ([onePlugin respondsToSelector:aSelector])
                [onePlugin performSelector:aSelector withObject:anObject];
        }
    }
}


- (void)makePlugins:(NSArray *)somePlugins performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 {
    @autoreleasepool {
        for (id<RSPlugin> onePlugin in somePlugins) {
            if ([onePlugin respondsToSelector:aSelector])
                [onePlugin performSelector:aSelector withObject:object1 withObject:object2];
        }    
    }
}


static const char *kNNWPluginCommandKey = "pluginCommand";
static const char *kNNWPluginAssociatedObjectKey = "object";

- (void)associateMenuItem:(NSMenuItem *)aMenuItem withPluginCommand:(id<RSPluginCommand>)aPluginCommand {
    objc_setAssociatedObject(aMenuItem, (void *)kNNWPluginCommandKey, aPluginCommand, OBJC_ASSOCIATION_RETAIN);
}


- (id<RSPluginCommand>)associatedPluginCommandForMenuItem:(NSMenuItem *)aMenuItem {
    return objc_getAssociatedObject(aMenuItem, (void *)kNNWPluginCommandKey);
}


- (void)associateMenuItem:(NSMenuItem *)aMenuItem withObject:(id)anObject {
    objc_setAssociatedObject(aMenuItem, (void *)kNNWPluginAssociatedObjectKey, anObject, OBJC_ASSOCIATION_RETAIN);    
}


- (id<RSSharableItem>)associatedObjectForMenuItem:(NSMenuItem *)aMenuItem {
    return objc_getAssociatedObject(aMenuItem, (void *)kNNWPluginAssociatedObjectKey);    
}


- (BOOL)pluginCommand:(id<RSPluginCommand>)aPluginCommand isOfType:(NSUInteger)aPluginCommandType {
    NSArray *types = [aPluginCommand commandTypes];
    return types != nil && [types containsObject:[NSNumber numberWithUnsignedInteger:aPluginCommandType]];
}
                            

- (NSArray *)pluginCommandsOfType:(NSUInteger)aPluginCommandType inPlugin:(id<RSPlugin>)aPlugin {
    NSMutableArray *pluginCommands = [NSMutableArray array];
    for (id<RSPluginCommand> onePluginCommand in aPlugin.allCommands) {
        if ([self pluginCommand:onePluginCommand isOfType:aPluginCommandType])
            [pluginCommands addObject:onePluginCommand];
    }
    return pluginCommands;        
}
                                                                           
                                                                           
- (id<RSPluginCommand>)soloPluginCommandOfType:(NSUInteger)aPluginCommandType inPlugin:(id<RSPlugin>)aPlugin {
    /*If there just one, return it -- otherwise return nil if there are zero or more than one.*/
    NSArray *pluginCommands = [self pluginCommandsOfType:aPluginCommandType inPlugin:aPlugin];
    if (RSIsEmpty(pluginCommands) || [pluginCommands count] > 1)
        return nil;
    return [pluginCommands objectAtIndex:0];
}


- (NSArray *)groupedCommandsOfType:(NSUInteger)aPluginCommandType inPlugin:(id<RSPlugin>)aPlugin {
    /*If the plugin has zero or one command of this type, return nil.*/
    NSArray *pluginCommands = [self pluginCommandsOfType:aPluginCommandType inPlugin:aPlugin];
    if (RSIsEmpty(pluginCommands) || [pluginCommands count] < 2)
        return nil;
    return pluginCommands;
}


- (NSArray *)soloPluginCommandsOfType:(NSUInteger)aPluginCommandType {
    NSMutableArray *soloPluginCommands = [NSMutableArray array];
    for (id<RSPlugin> onePlugin in self.plugins) {
        id<RSPluginCommand> oneSoloPluginCommand = [self soloPluginCommandOfType:aPluginCommandType inPlugin:onePlugin];
        if (oneSoloPluginCommand != nil)
            [soloPluginCommands addObject:oneSoloPluginCommand];
    }
    return soloPluginCommands;
}

- (NSArray *)pluginsWithGroupedCommandsOfType:(NSUInteger)aPluginCommandType {
    NSMutableArray *pluginsWithGroupedCommands = [NSMutableArray array];
    for (id<RSPlugin>onePlugin in self.plugins) {
        NSArray *groupedCommands = [self groupedCommandsOfType:aPluginCommandType inPlugin:onePlugin];
        if (!RSIsEmpty(groupedCommands))
            [pluginsWithGroupedCommands addObject:onePlugin];        
    }
    return pluginsWithGroupedCommands;
}


- (NSArray *)pluginsWithSoloCommandsOfType:(NSUInteger)aPluginCommandType {
    NSMutableArray *pluginsWithSoloCommands = [NSMutableArray array];
    for (id<RSPlugin>onePlugin in self.plugins) {
        id<RSPluginCommand>aPluginCommand = [self soloPluginCommandOfType:aPluginCommandType inPlugin:onePlugin];
        if (aPluginCommand != nil)
            [pluginsWithSoloCommands addObject:onePlugin];        
    }
    return pluginsWithSoloCommands;
}


- (NSArray *)groupedCommandsOfType:(NSUInteger)aPluginCommandType {
    NSArray *pluginsWithGroupedCommands = [self pluginsWithGroupedCommandsOfType:aPluginCommandType];
    if (RSIsEmpty(pluginsWithGroupedCommands))
        return nil;
    NSMutableArray *groupedPluginCommands = [NSMutableArray array];
    for (id<RSPlugin>onePlugin in pluginsWithGroupedCommands) {
        NSArray *groupedCommands = [self groupedCommandsOfType:aPluginCommandType inPlugin:onePlugin];
        if (!RSIsEmpty(groupedCommands))
            [groupedPluginCommands addObjectsFromArray:groupedCommands];
    }
    return groupedPluginCommands;
}


- (void)addPluginCommand:(id<RSPluginCommand>)aPluginCommand toMenu:(NSMenu *)aMenu associatedObject:(id)anAssociatedObject indentationLevel:(NSInteger)indentationLevel {
    
    NSString *title = aPluginCommand.title;
    if (indentationLevel > 0 && [aPluginCommand respondsToSelector:@selector(shortTitle)] && aPluginCommand.shortTitle != nil)
        title = aPluginCommand.shortTitle;
    NSMenuItem *aMenuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(performSharingPluginCommandWithSender:) keyEquivalent:@""];
    
    if ([aPluginCommand respondsToSelector:@selector(image)] && aPluginCommand.image != nil)
        [aMenuItem setImage:aPluginCommand.image];
    [self associateMenuItem:aMenuItem withPluginCommand:aPluginCommand];
    if (anAssociatedObject != nil)
        [self associateMenuItem:aMenuItem withObject:anAssociatedObject];
    if (indentationLevel > 0)
        [aMenuItem setIndentationLevel:indentationLevel];
    
    [aMenu addItem:aMenuItem];    
}


- (void)addSoloPluginCommandsOfType:(NSUInteger)aPluginCommandType toMenu:(NSMenu *)aMenu associatedObject:(id)associatedObject {
    for (id<RSPluginCommand>onePluginCommand in [self soloPluginCommandsOfType:aPluginCommandType])
        [self addPluginCommand:onePluginCommand toMenu:aMenu associatedObject:associatedObject indentationLevel:0];
}


- (void)addLabelForPlugin:(id<RSPlugin>)aPlugin toMenu:(NSMenu *)aMenu {
    if ([aPlugin respondsToSelector:@selector(titleForGroup)])
        [aMenu addItem:[[NSMenuItem alloc] initWithTitle:aPlugin.titleForGroup action:nil keyEquivalent:@""]];
}


- (void)addGroupedPluginCommandsOfType:(NSUInteger)aPluginCommandType toMenu:(NSMenu *)aMenu associatedObject:(id)anAssociatedObject indentGroupedItems:(BOOL)indentGroupedItems {
    
    NSArray *pluginsWithGroupedCommands = [self pluginsWithGroupedCommandsOfType:aPluginCommandType];
    if (RSIsEmpty(pluginsWithGroupedCommands))
        return;
    
    NSInteger indentationLevel = 0;
    if (indentGroupedItems)
        indentationLevel = 1;

    for (id<RSPlugin>onePlugin in pluginsWithGroupedCommands) {
        [aMenu rs_addSeparatorItemIfLastItemIsNotSeparator];
        if (indentGroupedItems)
            [self addLabelForPlugin:onePlugin toMenu:aMenu];
        
        for (id<RSPluginCommand>onePluginCommand in onePlugin.allCommands) {
            if ([self pluginCommand:onePluginCommand isOfType:aPluginCommandType])
                [self addPluginCommand:onePluginCommand toMenu:aMenu associatedObject:anAssociatedObject indentationLevel:indentationLevel]; 
        }
    }
}


- (void)addPluginCommandsOfType:(NSUInteger)aPluginCommandType toMenu:(NSMenu *)aMenu associatedObject:(id)anAssociatedObject indentGroupedItems:(BOOL)indentGroupedItems {
    [self addSoloPluginCommandsOfType:aPluginCommandType toMenu:aMenu associatedObject:anAssociatedObject ];
    [self addGroupedPluginCommandsOfType:aPluginCommandType toMenu:aMenu associatedObject:anAssociatedObject indentGroupedItems:indentGroupedItems];
}


- (NSArray *)orderedPluginCommandsOfType:(NSUInteger)aPluginCommandType {
    /*Solo commands first, then grouped.*/
    NSMutableArray *orderedPluginCommands = [NSMutableArray array];
    NSArray *soloPluginCommands = [self soloPluginCommandsOfType:aPluginCommandType];
    if (!RSIsEmpty(soloPluginCommands))
        [orderedPluginCommands addObjectsFromArray:soloPluginCommands];
    NSArray *groupedPluginCommands = [self groupedCommandsOfType:aPluginCommandType];
    if (!RSIsEmpty(groupedPluginCommands))
        [orderedPluginCommands addObjectsFromArray:groupedPluginCommands];
    return orderedPluginCommands;
}


@end
