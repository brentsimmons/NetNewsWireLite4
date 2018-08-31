/*
    NNWStyleSheetController.h
    NetNewsWire

    Created by Brent Simmons on Sat Jun 19 2004.
    Copyright (c) 2004 Ranchero Software. All rights reserved.
*/


#import "NNWStyleSheetController.h"
#import "NNWArticleTheme.h"
#import "RSFileUtilities.h"


NSString *NNWStyleSheetFolderName = @"StyleSheets";
NSString *NNWStyleSheetPackageSuffix = @".nnwstyle";
NSString *NNWStyleSheetPackagePathExtension = @"nnwstyle";
NSString *NNWStyleSheetDefaultsNameKey = @"styleSheetName";
NSString *NNWStyleSheetDefaultArticleThemeName = @"Easy";


@interface NNWStyleSheetController ()

@property (nonatomic, assign, readwrite) BOOL installDidError;
@property (nonatomic, strong) NSCache *styleSheetCache;
@property (nonatomic, strong) NSString *folderPath;
@property (nonatomic, strong, readwrite) NSArray *styleSheetNames;
@property (nonatomic, strong, readwrite) NSString *installError;

- (void)installBuiltinArticleThemes;
- (void)updateStyleSheetNames;

@end


@implementation NNWStyleSheetController

@synthesize defaultArticleTheme;
@synthesize folderPath;
@synthesize installDidError;
@synthesize installError;
@synthesize styleSheetCache;
@synthesize styleSheetNames;


#pragma mark Class Methods

+ (NNWStyleSheetController *)sharedController {
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
    styleSheetCache = [[NSCache alloc] init];
    folderPath = RSSubFolderInFolder(rs_app_delegate.pathToDataFolder, NNWStyleSheetFolderName, YES);
//    RSEnsureAppSupportSubFolderExists(NNWStyleSheetFolderName);
//    folderPath = [RSAppSupportFilePath(NNWStyleSheetFolderName) retain];
    [self installBuiltinArticleThemes];
    [self updateStyleSheetNames];
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObject:NNWStyleSheetDefaultArticleThemeName forKey:NNWStyleSheetDefaultsNameKey]];    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStyleSheetNames) name:NSApplicationDidBecomeActiveNotification object:nil];
    return self;
}


#pragma mark Dealloc

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark Styles

- (NNWArticleTheme *)articleThemeWithName:(NSString *)articleThemeName {
    /*Short name-for-display like BlueEasy -- not a path, no suffix.*/
    NNWArticleTheme *styleSheet = [self.styleSheetCache objectForKey:articleThemeName];
    if (styleSheet != nil)
        return styleSheet;
    NSString *styleSheetPath = [self.folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@%@", articleThemeName, NNWStyleSheetPackageSuffix]];
    if (RSFileExists(styleSheetPath)) {
        styleSheet = [[NNWArticleTheme alloc] initWithFolderPath:styleSheetPath];
        [self.styleSheetCache setObject:styleSheet forKey:articleThemeName];
    }
    return styleSheet;
}


- (NNWArticleTheme *)defaultArticleTheme {
    NNWArticleTheme *articleTheme = [self articleThemeWithName:[[NSUserDefaults standardUserDefaults] objectForKey:NNWStyleSheetDefaultsNameKey]];
    if (articleTheme == nil)
        articleTheme = [self articleThemeWithName:NNWStyleSheetDefaultArticleThemeName];
    return articleTheme;
}


- (void)installBuiltinArticleThemes {
    RSFileCopyFilesInFolder([[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:NNWStyleSheetFolderName], self.folderPath);
    }
    
    
- (void)updateStyleSheetNames {
    
    [self.styleSheetCache removeAllObjects];
    
    NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:30];
    NSArray *filenames = RSFilenameArrayForFolder(self.folderPath);
    filenames = [filenames sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (NSString *oneFilename in filenames) {
        if ([oneFilename hasPrefix:@"."])
            continue;
        NSString *oneFilePath = [self.folderPath stringByAppendingPathComponent:oneFilename];
        if (RSFileIsFolder(oneFilePath))
            [tempArray rs_safeAddObject:[oneFilename stringByDeletingPathExtension]];
    }
        
    self.styleSheetNames = tempArray;
    }


- (NSString *)folderForStyleSheetNamed:(NSString *)styleSheetName { //short name, minus .nnwstyle
    NSString *filename = [styleSheetName stringByAppendingPathExtension:NNWStyleSheetPackagePathExtension];
    return [self.folderPath stringByAppendingPathComponent:filename];
}


- (BOOL)styleSheetWithNameExistsOnDisk:(NSString *)styleSheetName {
    NSString *styleSheetPath = [self folderForStyleSheetNamed:styleSheetName];
    return !RSIsEmpty(styleSheetPath) && RSFileExists(styleSheetPath);
}


#pragma mark -
#pragma mark NNWStyleDocument Support


- (BOOL)styleIsInstalled:(NSString *)f {
    
    /*Return yes if f is actually in the StyleSheets directory.*/
    
    NSString *parentFolder = [f stringByDeletingLastPathComponent];
    NSString *styleSheetsFolder = [self folderPath];
    
    parentFolder = [parentFolder rs_stringByStrippingSuffix:@"/"];
    styleSheetsFolder = [styleSheetsFolder rs_stringByStrippingSuffix:@"/"];
    return [parentFolder isEqualToString:styleSheetsFolder];
    }


- (BOOL)styleWithSameNameIsInstalled:(NSString *)f {
    return [self styleSheetWithNameExistsOnDisk:[[f lastPathComponent] stringByDeletingPathExtension]];
    }


- (BOOL)installStyleDocument:(NSString *)pathToDocument {
    
    NSParameterAssert(pathToDocument != nil);
    
    NSString *filename = [pathToDocument lastPathComponent];
    NSString *displayName = [filename stringByDeletingPathExtension];
    
    if (RSIsEmpty(pathToDocument)) {
        self.installDidError = YES;
        self.installError = NSLocalizedStringFromTable(@"The path to the file was not specified.", @"Styles", @"Style document window");
        return NO;
        }
    if ([pathToDocument hasPrefix:self.folderPath]) {
        self.installDidError = YES;
        self.installError = NSLocalizedStringFromTable(@"The file is already in the StyleSheets folder.", @"Styles", @"Style document window");
        return NO;
        }
    if ([self styleIsInstalled:pathToDocument]) {
        self.installDidError = YES;
        self.installError = NSLocalizedStringFromTable(@"The file is already in the StyleSheets folder.", @"Styles", @"Style document window");
        return NO;
        }
    
    self.installDidError = NO;

    NSString *currentPath = [self folderForStyleSheetNamed:displayName];
    if (currentPath != nil && (RSFileExists(currentPath)))
        RSFileDelete(currentPath);
    NSString *pathInStyleSheetsFolder = [self.folderPath stringByAppendingPathComponent:filename];
    RSFileCopy(pathToDocument, pathInStyleSheetsFolder);
    
    [self updateStyleSheetNames];
    return YES;
    }
    
    
@end
