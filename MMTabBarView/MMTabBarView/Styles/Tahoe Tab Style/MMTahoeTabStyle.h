//
//  MMTahoeTabStyle.h
//  -----------------
//
//  A flat, capsule-shaped tab style matching the rounded look of
//  macOS 26 (Tahoe). Based on MMMojaveTabStyle in this framework's own
//  sense of the word: the two colors it needs from that style's
//  appearance-aware catalogue are copied into its implementation, just
//  as MMMojaveTabStyle was based on MMYosemiteTabStyle. Every style here
//  stands on its own; none inherits from another.
//
//  Tabs are drawn as free-standing rounded pills with generous outer
//  margins, so the first and last tab clear the large window corner
//  radius introduced with Tahoe instead of being clipped by it.
//
//  DELIBERATELY TRANSLUCENT, which is worth knowing before judging it:
//  this style paints no opaque bar background and fills its pills with
//  alpha, because it is meant to sit on the vibrancy backdrop its host
//  installs behind the tab bar (Adium uses an NSVisualEffectView). Drop
//  it onto a plain white view instead and it looks like it draws almost
//  nothing at all - that is the backdrop missing, not the style being
//  unfinished. Close buttons are likewise absent until a tab is hovered,
//  where the X takes the status icon's place in a shared slot, the way
//  a browser swaps out a favicon.
//

#if __has_feature(modules)
#if __has_warning("-Watimport-in-framework-header")
#pragma clang diagnostic ignored "-Watimport-in-framework-header"
#endif
@import Cocoa;
#else
#import <Cocoa/Cocoa.h>
#endif
#import <MMTabBarView/MMTabStyle.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMTahoeTabStyle : NSObject <MMTabStyle>

@end

NS_ASSUME_NONNULL_END
