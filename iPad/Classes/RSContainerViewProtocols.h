//
//  RSContainerViewProtocols.h
//  nnwipad
//
//  Created by Brent Simmons on 11/1/10.
//  Copyright 2010 NewsGator Technologies, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


/*
 When a different content view should be displayed (as in, when you want to display
 a web page instead of an article, etc.) then do .representedObject = someObject to swap it in.
 This calls will then ask the registered content view controllers if they want to handle
 that represented object (starting with the currently-displayed view controller). Whichever
 says yes will get swapped in (if not already displayed).
 
 Before being considered for display, a content view controller should have registered via
 registerContentViewControllerClass. Each registered class must conform to the RSContentViewController
 protocol.
*/


@protocol RSUserSelectedObjectSource <NSObject>

@required
@property (nonatomic, retain, readonly) id userSelectedObject;

@end


@protocol RSContainerViewController <NSObject>

@required

- (void)registerContentViewControllerClass:(Class)aClass;

/*The container view asks sender for userSelectedObject. Then it asks the registered
 content view controllers if they want to handle that object. First one to say yes wins.*/

- (void)userDidSelectObject:(id<RSUserSelectedObjectSource>)sender;

/*Same as a above, except that it's now a kind of stack. When userDidDeselectObject
 is called, the container view goes back to the previous selected object.
 Example: a web page in NetNewsWire for iPad is temporary. When user clicks back,
 the container view goes back to displaying the article content view.*/

- (void)userDidSelectTemporaryObject:(id<RSUserSelectedObjectSource>)sender;

/*If it was temporary, pop back to previous object.*/

- (void)userDidDeselectObject:(id<RSUserSelectedObjectSource>)sender;


@end


@protocol RSContentViewController <NSObject>

@required
+ (BOOL)wantsToDisplayRepresentedObject:(id)aRepresentedObject;

/*It's a class method, so you can have a pool and reuse a given instance, if you want.*/

+ (UIViewController<RSContentViewController> *)contentViewControllerWithRepresentedObject:(id)aRepresentedObject;

@property (nonatomic, retain) id representedObject;

@optional

/*To allow an existing view to get reused, implement the representedObject property
 *and* return YES from canReuseViewWithRepresentedObject.*/

- (BOOL)canReuseViewWithRepresentedObject:(id)aRepresentedObject;

- (NSArray *)toolbarItems:(BOOL)orientationIsLandscape;


@end
