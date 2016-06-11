//
//  BlurFocus.m
//  BlurFocus
//
//  Created by Wolfgang Baird on 4/30/16.
//  Copyright © 2016 Wolfgang Baird. All rights reserved.
//

@import AppKit;
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface BlurFocus : NSObject
@end

@implementation BlurFocus

NSArray         *_filters;
CIFilter        *_blurFilter;
static void     *isActive = &isActive;

+ (void)load
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignKeyNotification object:nil];
    [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignMainNotification object:nil];
    [center addObserver:self selector:@selector(BF_restoreWindow:) name:NSWindowDidBecomeMainNotification object:nil];
    [center addObserver:self selector:@selector(BF_restoreWindow:) name:NSWindowDidBecomeKeyNotification object:nil];
    NSLog(@"BlurFocus loaded...");
}

+ (void)BF_blurWindow:(NSNotification *)note
{
    NSWindow *win = note.object;
    if (![objc_getAssociatedObject(win, isActive) boolValue]) {
        
        NSView *_win = [[win contentView] superview];
        _filters = [_win contentFilters];
        
        // To apply CIFilters on OS X 10.9, we need to set the property accordingly:
        [_win setWantsLayer:YES];
        [_win setLayerUsesCoreImageFilters:YES];
        
        // Set the layer to redraw itself once it's size is changed
        [_win.layer setNeedsDisplayOnBoundsChange:YES];
        
        // Next, we create the blur filter
        _blurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
        [_blurFilter setDefaults];
        [_blurFilter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputRadius"];
        
        // Now we apply the two filters as the layer's background filters
        [_win setContentFilters:@[_blurFilter]];
        
        // ... and trigger a refresh
        [_win.layer setNeedsDisplay];
        
        // Set alpha
        [win setAlphaValue:0.9];
        
        // Set active flag for window
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
    }
}

+ (void)BF_restoreWindow:(NSNotification *)note
{
    NSWindow *win = note.object;
    if ([objc_getAssociatedObject(win, isActive) boolValue]) {
        [[win.contentView superview] setWantsLayer:YES];
        [[win.contentView superview] setContentFilters:_filters];
        [win setViewsNeedDisplay:YES];
        [win setAlphaValue:1.0];
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:false], OBJC_ASSOCIATION_RETAIN);
    }
}

@end
