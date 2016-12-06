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

NSArray* BF_addFilter(NSArray* gray, NSArray* def)
{
    NSMutableArray *newFilters = [[NSMutableArray alloc] initWithArray:def];
    [newFilters addObjectsFromArray:gray];
    NSArray *result = [newFilters copy];
    return result;
}

@interface BlurFocus : NSObject
@end

@implementation BlurFocus

NSArray         *_blurFilters;
static void     *filterCache = &filterCache;
static void     *isActive = &isActive;

+ (void)load
{
    NSArray *blacklist = @[@"com.apple.notificationcenterui", @"com.google.chrome", @"com.google.chrome.canary"];
    NSString *appID = [[NSBundle mainBundle] bundleIdentifier];
    if (![blacklist containsObject:appID])
    {
        CIFilter *filt = [CIFilter filterWithName:@"CIGaussianBlur"];
        [filt setDefaults];
        [filt setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputRadius"];
        
        _blurFilters = [NSArray arrayWithObjects:filt, nil];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignKeyNotification object:nil];
        [center addObserver:self selector:@selector(BF_blurWindow:) name:NSWindowDidResignMainNotification object:nil];
        [center addObserver:self selector:@selector(BF_clearWindow:) name:NSWindowDidBecomeMainNotification object:nil];
        [center addObserver:self selector:@selector(BF_clearWindow:) name:NSWindowDidBecomeKeyNotification object:nil];
        NSLog(@"BlurFocus loaded...");
    }
}

+ (void)BF_blurWindow:(NSNotification *)note
{
    NSWindow *win = note.object;
    if (![objc_getAssociatedObject(win, isActive) boolValue]
            && !([win styleMask] & NSWindowStyleMaskFullScreen)) {
        NSArray *_defaultFilters = [[win.contentView superview] contentFilters];
        objc_setAssociatedObject(win, filterCache, _defaultFilters, OBJC_ASSOCIATION_RETAIN);
        [[win.contentView superview] setWantsLayer:YES];
        [[win.contentView superview] setContentFilters:BF_addFilter(_blurFilters, _defaultFilters)];
        [win setAlphaValue:0.9];
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:true], OBJC_ASSOCIATION_RETAIN);
    }
}

+ (void)BF_clearWindow:(NSNotification *)note
{
    NSWindow *win = note.object;
    if ([objc_getAssociatedObject(win, isActive) boolValue]) {
        [[win.contentView superview] setWantsLayer:YES];
        [[win.contentView superview] setContentFilters:objc_getAssociatedObject(win, filterCache)];
        [win setAlphaValue:1.0];
        objc_setAssociatedObject(win, isActive, [NSNumber numberWithBool:false], OBJC_ASSOCIATION_RETAIN);
    }
}

@end
