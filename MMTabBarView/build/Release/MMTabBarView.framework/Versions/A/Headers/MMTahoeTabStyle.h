//
//  MMTahoeTabStyle.h
//  -----------------
//
//  A flat, capsule-shaped tab style matching the rounded look of
//  macOS 26 (Tahoe). Based on MMMojaveTabStyle, whose appearance-aware
//  color catalogue it inherits.
//
//  Tabs are drawn as free-standing rounded pills with generous outer
//  margins, so the first and last tab clear the large window corner
//  radius introduced with Tahoe instead of being clipped by it.
//

#if __has_feature(modules)
#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif
@import Cocoa;
#else
#import <Cocoa/Cocoa.h>
#endif
#import <MMTabBarView/MMMojaveTabStyle.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMTahoeTabStyle : MMMojaveTabStyle

@end

NS_ASSUME_NONNULL_END
