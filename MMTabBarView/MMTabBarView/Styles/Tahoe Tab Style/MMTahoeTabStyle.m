//
//  MMTahoeTabStyle.m
//  -----------------
//
//  Changes released in accordance with MMTabBarView license.
//

#import <MMTabBarView/MMTahoeTabStyle.h>
#import "NSView+MMTabBarViewExtensions.h"
#import <MMTabBarView/MMAttachedTabBarButton.h>
#import <MMTabBarView/MMTabBarView.h>
#import <MMTabBarView/MMOverflowPopUpButton.h>
#import <MMTabBarView/MMRolloverButton.h>
#import <MMTabBarView/MMTabBarButtonCell.Private.h>
#import <MMTabBarView/MMTabBarView.Private.h>

NS_ASSUME_NONNULL_BEGIN

// Horizontal clearance so the outermost pills are not clipped by the
// large Tahoe window corner radius.
static const CGFloat kMMTahoeOuterMargin = 8.0;

// Inset of each pill within its button frame.
static const CGFloat kMMTahoePillInsetX = 3.0;
static const CGFloat kMMTahoePillInsetY = 4.0;

// Inner padding between the pill edge and the cell content. The leading
// side is tighter so the icon/close slot sits 7 pt (14 px @2x) from the
// pill edge, matching its vertical clearance; the trailing side stays
// wider so the title keeps its distance from the rounded cap.
static const CGFloat kMMTahoeContentPaddingLeft = 6.0;
static const CGFloat kMMTahoeContentPaddingRight = 11.0;

// The unread badge is a filled pill of its own, so it may sit closer to the
// rounded cap than the title, which is what the trailing padding above protects.
static const CGFloat kMMTahoeCounterPaddingRight = 8.0;

static const CGFloat kMMTahoeBarHeight = 34.0;

// Status icons from typical icon packs carry a bit of baked-in bottom
// padding; nudge them down so they sit optically centered in the pill.
static const CGFloat kMMTahoeIconNudgeY = 1.0;

/* The geometry below is stated once and asked for everywhere, because this style is the only one in
 * the framework that answers -desiredWidthOfTabCell: itself. Every other style lets
 * MMTabBarButtonCell measure it, which keeps the width and the box it must fit in derived from the
 * same margins by construction. Tahoe cannot do that - its pill inset and asymmetric padding are not
 * the margins generic measurement assumes - so it has to make that agreement explicit instead. A
 * width that restates a padding as a literal is how the two drift apart, and a title then truncates
 * with room to spare on either side.
 */

// Horizontal chrome: what the pill and its inner padding take from the content box.
static inline CGFloat MMTahoeLeadingChrome(void)  { return kMMTahoePillInsetX + kMMTahoeContentPaddingLeft; }
static inline CGFloat MMTahoeTrailingChrome(void) { return kMMTahoePillInsetX + kMMTahoeContentPaddingRight; }

// A badge may sit nearer the cap than a title, so a tab showing one needs less trailing clearance.
static inline CGFloat MMTahoeTrailingChromeWithCounter(void) { return kMMTahoePillInsetX + kMMTahoeCounterPaddingRight; }

// Vertical inset from the button frame to the content box.
static inline CGFloat MMTahoeContentInsetY(void) { return kMMTahoePillInsetY + 2.0; }

// The content height of any button on this bar. The width budget is handed a cell but no bounds,
// and every button on a Tahoe bar is kMMTahoeBarHeight tall.
static inline CGFloat MMTahoeBarContentHeight(void) { return kMMTahoeBarHeight - (MMTahoeContentInsetY() * 2.0); }

// An image taller than the content box is scaled to fit it; both the slot rect and the slot width
// measure through here so they cannot answer differently.
static NSSize MMTahoeScaledImageSize(NSSize imageSize, CGFloat contentHeight)
{
    if ((imageSize.height > contentHeight) && (imageSize.height > 0.0)) {
        CGFloat scale = contentHeight / imageSize.height;
        imageSize = NSMakeSize(imageSize.width * scale, imageSize.height * scale);
    }

    return imageSize;
}

/* Two of this style's colors are entries out of MMMojaveTabStyle's asset catalogue, restated here
 * because that catalogue is a category on that class: it can only be asked by being one, which is
 * exactly what this style no longer is. They are exact copies rather than approximations - the
 * catalogue varies with the window state and with the high contrast setting, so a plain light/dark
 * pair would be right in two of eight states and quietly wrong in the six nobody checks by eye.
 *
 * The trap worth naming: the appearance decided here is the ENCLOSING view's, not the bar's, which
 * is what the catalogue did. The pill fill further down reads the bar's own on purpose, because the
 * pills sit on the vibrancy backdrop the host installs behind the bar. Reading either one where the
 * other is meant looks correct right up until the two appearances differ.
 */
typedef struct {
    BOOL dark;
    BOOL highContrast;
    BOOL windowActive;
} MMTahoeAppearance;

static MMTahoeAppearance MMTahoeAppearanceOfTabBarView(MMTabBarView *tabBarView)
{
    MMTahoeAppearance appearance = { NO, NO, tabBarView.isWindowActive };

    if (@available(macOS 10.14, *)) {
        NSAppearanceName match = [tabBarView.superview.effectiveAppearance
            bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua,
                                                NSAppearanceNameAccessibilityHighContrastAqua,
                                                NSAppearanceNameDarkAqua,
                                                NSAppearanceNameAccessibilityHighContrastDarkAqua]];
        appearance.dark = ([match isEqualToString:NSAppearanceNameDarkAqua] ||
                           [match isEqualToString:NSAppearanceNameAccessibilityHighContrastDarkAqua]);
        appearance.highContrast = ([match isEqualToString:NSAppearanceNameAccessibilityHighContrastAqua] ||
                                   [match isEqualToString:NSAppearanceNameAccessibilityHighContrastDarkAqua]);
    } else {
        // Before 10.14 there is no dark mode to ask about, only the accessibility setting.
        appearance.highContrast = NSWorkspace.sharedWorkspace.accessibilityDisplayShouldIncreaseContrast;
    }

    return appearance;
}

@implementation MMTahoeTabStyle

+ (NSString *)name
{
    return @"Tahoe";
}

- (NSString *)name
{
    return self.class.name;
}

#pragma mark - Tab View Specific

- (NSSize)intrinsicContentSizeOfTabBarView:(MMTabBarView *)tabBarView
{
    return NSMakeSize(NSViewNoIntrinsicMetric, kMMTahoeBarHeight);
}

- (CGFloat)leftMarginForTabBarView:(MMTabBarView *)tabBarView
{
    return (tabBarView.orientation == MMTabBarHorizontalOrientation) ? kMMTahoeOuterMargin : 0.0;
}

- (CGFloat)rightMarginForTabBarView:(MMTabBarView *)tabBarView
{
    return (tabBarView.orientation == MMTabBarHorizontalOrientation) ? kMMTahoeOuterMargin : 0.0;
}

- (CGFloat)heightOfTabBarButtonsForTabBarView:(MMTabBarView *)tabBarView
{
    return kMMTahoeBarHeight;
}

- (NSSize)overflowButtonSizeForTabBarView:(MMTabBarView *)tabBarView
{
    return NSMakeSize(14, kMMTahoeBarHeight);
}

/* Zero, and it has to be said out loud rather than left to the framework's default: the default is
 * zero only for a horizontal bar and MARGIN_Y for a vertical one, and hosts ask this question
 * WITHOUT checking whether the style answers it. Adium sends it straight through an
 * id <MMTabStyle> for its left and right tab positions - an unanswered optional method there is not
 * a wrong margin, it is an unrecognized selector. */
- (CGFloat)topMarginForTabBarView:(MMTabBarView *)tabBarView
{
    return 0.0;
}

/* Every geometry answer in this file is a horizontal one: the bar height, the outer margins that
 * clear the window corners, the pill. Say so, because a style that stays silent here is taken to
 * support both orientations, and -setStyle: would then leave a vertical bar vertical. */
- (BOOL)supportsOrientation:(MMTabBarOrientation)orientation forTabBarView:(MMTabBarView *)tabBarView
{
    return (orientation == MMTabBarHorizontalOrientation);
}

/* This style deliberately says nothing about the add tab button: it has no artwork of its own for
 * one, and Adium never shows one. A host that turns it on gets the framework's stock button and
 * placement rather than something borrowed from a style this one no longer descends from. */

/*!
 * @brief Size tabs by what they ask for, not by equal shares
 *
 * Answering YES here tells MMTabBarController to hand every tab an equal share of the bar, after
 * which it never consults -desiredWidthOfTabCell: at all. This style has a width formula and means
 * it. NO is also what a style gets for staying silent, but silence sitting right above the width
 * methods would read as an omission rather than as the decision it is.
 */
- (BOOL)needsResizeTabsToFitTotalWidth
{
    return NO;
}

- (NSRect)drawingRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell
{
    NSRect result = NSInsetRect(theRect, 0, MMTahoeContentInsetY());
    result.origin.x += MMTahoeLeadingChrome();
    result.size.width -= MMTahoeLeadingChrome() + MMTahoeTrailingChrome();
    return result;
}

#pragma mark - Icon and Close Button (Chrome-style shared slot)

/* The close button occupies the same slot as the status icon: hovering a
 * tab swaps the icon for a circled X, like Chrome does with favicons. */

/*!
 * @brief No large image, in any orientation
 *
 * The large image is the buddy picture. MMTabBarButtonCell offers it to vertical tab bars only, and
 * a style that says nothing gets the framework's own rect, so turning the tab bar sideways made
 * every tab sprout a picture that the same tabs never show lying flat. This style has one slot for
 * one image, described above, and it is the same slot in both orientations.
 */
- (NSRect)largeImageRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell
{
    return NSZeroRect;
}

/*!
 * @brief How much room the leading slot takes, or zero when nothing occupies it
 *
 * The slot is kMMTabBarIconWidth wide and holds whichever of icon and close button is showing,
 * centered within it. A smaller image does not shrink the slot: the title would otherwise shift
 * sideways the moment the pointer entered the tab and the X took the icon's place. A larger one
 * widens it rather than growing into the title.
 *
 * Both the title rect and the width budget ask here, so what is reserved and what is paid for
 * cannot disagree with what is drawn. Measuring the images instead - as the title rect used to,
 * while the budget assumed a flat kMMTabBarIconWidth - left the two describing different tabs.
 */
- (CGFloat)_leadingSlotWidthOfTabCell:(MMTabBarButtonCell *)cell contentHeight:(CGFloat)contentHeight
{
    CGFloat width = 0.0;
    BOOL    occupied = NO;

    if (cell.icon) {
        occupied = YES;
        width = MAX(width, MMTahoeScaledImageSize(cell.icon.size, contentHeight).width);
    }

    if (cell.shouldDisplayCloseButton) {
        NSImage *closeImage = [cell closeButtonImageOfType:MMCloseButtonImageTypeStandard];
        if (closeImage) {
            occupied = YES;
            width = MAX(width, MMTahoeScaledImageSize(closeImage.size, contentHeight).width);
        }
    }

    return (occupied ? MAX(width, kMMTabBarIconWidth) : 0.0);
}

- (NSRect)_leadingSlotRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell imageSize:(NSSize)imageSize
{
    NSRect  drawingRect = [self drawingRectForBounds:theRect ofTabCell:cell];
    CGFloat slotWidth = [self _leadingSlotWidthOfTabCell:cell contentHeight:NSHeight(drawingRect)];

    imageSize = MMTahoeScaledImageSize(imageSize, NSHeight(drawingRect));

    NSRect result;
    result.size = imageSize;
    result.origin.x = drawingRect.origin.x;
    if (imageSize.width < slotWidth)
        result.origin.x += ceil((slotWidth - imageSize.width) / 2.0);
    // Strict vertical centering; the default cell logic carries a nudge
    // tuned for the old 22 pt bar that mis-centers icons here.
    result.origin.y = NSMidY(drawingRect) - imageSize.height / 2.0 + kMMTahoeIconNudgeY;

    return NSIntegralRect(result);
}

- (NSRect)iconRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell
{
    NSImage *icon = cell.icon;
    if (!icon)
        return NSZeroRect;

    NSRect drawingRect = [self drawingRectForBounds:theRect ofTabCell:cell];
    NSSize iconSize = icon.size;
    NSRect result = [self _leadingSlotRectForBounds:theRect ofTabCell:cell imageSize:iconSize];

    BOOL iconOnly = (cell.title.length == 0 && !cell.showObjectCount && !cell.isProcessing);
    if (iconOnly)
        result.origin.x = NSMidX(drawingRect) - NSWidth(result) / 2.0;

    return NSIntegralRect(result);
}

- (NSRect)closeButtonRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell
{
    if (!cell.shouldDisplayCloseButton)
        return NSZeroRect;

    NSImage *image = [cell closeButtonImageOfType:MMCloseButtonImageTypeStandard];
    if (!image)
        return NSZeroRect;

    NSRect result = [self _leadingSlotRectForBounds:theRect ofTabCell:cell imageSize:image.size];
    // Compensate the shared slot's +1 icon nudge: measured on screen, the
    // X is geometrically centered at exactly 1 pt above the slot position.
    result.origin.y -= 1.0;
    return result;
}

/* Answered from the rect rather than as a constant: the close button is drawn at the size of its
 * image inside the shared slot, so a fixed answer here would describe a different button than the
 * one on screen for anyone who asks the size instead of the rect. */
- (NSSize)closeButtonSizeForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell
{
    return [self closeButtonRectForBounds:theRect ofTabCell:cell].size;
}

- (NSRect)titleRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell
{
    NSRect drawingRect = [self drawingRectForBounds:theRect ofTabCell:cell];
    NSRect constrainedDrawingRect = drawingRect;

    // Icon and close button share one leading slot — reserve it once.
    CGFloat slotWidth = [self _leadingSlotWidthOfTabCell:cell contentHeight:NSHeight(drawingRect)];
    if (slotWidth > 0) {
        constrainedDrawingRect.origin.x += slotWidth + kMMTabBarCellPadding;
        constrainedDrawingRect.size.width -= slotWidth + kMMTabBarCellPadding;
    }

    NSRect indicatorRect = [cell indicatorRectForBounds:theRect];
    if (!NSEqualRects(indicatorRect, NSZeroRect))
        constrainedDrawingRect.size.width -= NSWidth(indicatorRect) + kMMTabBarCellPadding;

    NSRect counterBadgeRect = [cell objectCounterRectForBounds:theRect];
    if (!NSEqualRects(counterBadgeRect, NSZeroRect))
        constrainedDrawingRect.size.width -= NSWidth(counterBadgeRect) + kMMTabBarCellPadding;

    NSAttributedString *attrString = cell.attributedStringValue;
    if (attrString.length == 0)
        return NSZeroRect;

    NSSize stringSize = attrString.size;
    NSRect result = NSMakeRect(constrainedDrawingRect.origin.x,
                               drawingRect.origin.y + ceil((drawingRect.size.height - stringSize.height) / 2) - 1.0,
                               constrainedDrawingRect.size.width,
                               stringSize.height);

    result = NSIntegralRect(result);
    // Half-point (1 px @2x) optical correction, applied after pixel
    // alignment; text rendering handles fractional offsets fine.
    result.origin.y += 0.5;
    return result;
}

/* Same geometry as MMTabBarButtonCell computes for itself, only the trailing clearance is the
 * badge's own: the generic version ends the badge where the title has to stop, which leaves it
 * further from the rounded cap than a filled pill needs to be. */
- (NSRect)objectCounterRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell
{
    if (!cell.showObjectCount)
        return NSZeroRect;

    NSRect  drawingRect = [self drawingRectForBounds:theRect ofTabCell:cell];
    NSRect  indicatorRect = [cell indicatorRectForBounds:theRect];
    NSSize  counterSize = cell.objectCounterSize;
    NSRect  result;

    drawingRect.size.width += MMTahoeTrailingChrome() - MMTahoeTrailingChromeWithCounter();

    if (!NSEqualRects(indicatorRect, NSZeroRect))
        drawingRect.size.width -= NSWidth(indicatorRect) + kMMTabBarCellPadding;

    result.size = counterSize;
    result.origin.x = NSMaxX(drawingRect) - counterSize.width;
    result.origin.y = ceil(NSMinY(drawingRect) + (NSHeight(drawingRect) - counterSize.height) / 2.0);

    return NSIntegralRect(result);
}

/*!
 * @brief Everything a tab needs besides its title
 *
 * Shared by the desired and the minimum width so the two can only ever differ by the title, which
 * is the one part that may be truncated.
 */
- (CGFloat)_chromeWidthOfTabCell:(MMTabBarButtonCell *)cell
{
    // A badge is allowed nearer the cap than a title, and the drawing side already grants it that
    CGFloat resultWidth = MMTahoeLeadingChrome() + (cell.showObjectCount ? MMTahoeTrailingChromeWithCounter()
                                                                         : MMTahoeTrailingChrome());

    CGFloat slotWidth = [self _leadingSlotWidthOfTabCell:cell contentHeight:MMTahoeBarContentHeight()];
    if (slotWidth > 0.0)
        resultWidth += slotWidth + kMMTabBarCellPadding;

    if (cell.showObjectCount)
        resultWidth += cell.objectCounterSize.width + kMMTabBarCellPadding;

    if (cell.isProcessing)
        resultWidth += kMMTabBarCellPadding + kMMTabBarIndicatorWidth;

    return resultWidth;
}

- (CGFloat)desiredWidthOfTabCell:(MMTabBarButtonCell *)cell
{
    return ceil([self _chromeWidthOfTabCell:cell] + cell.attributedStringValue.size.width);
}

/*!
 * @brief The narrowest this tab may be squeezed to
 *
 * Answered here for the same reason the desired width is: inheriting the generic one would pair
 * MMTabBarButtonCell's margins and its two separate slots with this style's padding and single
 * slot - a second, quietly different opinion about the same tab.
 */
- (CGFloat)minimumWidthOfTabCell:(MMTabBarButtonCell *)cell
{
    return ceil([self _chromeWidthOfTabCell:cell]);
}

#pragma mark - Selective Drawing

- (void)drawIconOfTabCell:(MMTabBarButtonCell *)cell withFrame:(NSRect)frame inView:(NSView *)controlView
{
    // While hovered, the circled X replaces the status icon.
    if (!cell.shouldDisplayCloseButton || !cell.mouseHovered)
        [cell _drawIconWithFrame:frame inView:controlView];
}

- (void)drawCloseButtonOfTabCell:(MMTabBarButtonCell *)cell withFrame:(NSRect)frame inView:(NSView *)controlView
{
    MMRolloverButton *closeButton = cell.closeButton;


    /* The cell only repositions this subview on property changes
     * (_updateCloseButton), which can run before layout has settled —
     * leaving the X parked at a stale frame forever. This hook runs on
     * every redraw (hover changes repaint the pill), so sync the frame
     * and images here to keep the button reliable. */
    NSRect buttonRect = [self closeButtonRectForBounds:frame ofTabCell:cell];
    if (!NSEqualRects(buttonRect, NSZeroRect) && !NSEqualRects(closeButton.frame, buttonRect))
        [closeButton setFrame:buttonRect];

    if (!closeButton.image) {
        [closeButton setImage:[self closeButtonImageOfType:MMCloseButtonImageTypeStandard forTabCell:cell]];
        [closeButton setAlternateImage:[self closeButtonImageOfType:MMCloseButtonImageTypePressed forTabCell:cell]];
        [closeButton setRolloverImage:[self closeButtonImageOfType:MMCloseButtonImageTypeRollover forTabCell:cell]];
    }

    // Only reveal the X on hover; the icon owns the slot otherwise.
    [closeButton setHidden:!cell.mouseHovered];
}

#pragma mark - Providing Images

- (NSImage *)closeButtonImageOfType:(MMCloseButtonImageType)type forTabCell:(MMTabBarButtonCell *)cell
{
    // The classic circled-X artwork from the original Adium tab style.
    switch (type) {
        case MMCloseButtonImageTypeStandard:
            return [MMTabBarView.bundle imageForResource:@"AquaTabClose_Front"];
        case MMCloseButtonImageTypeRollover:
            return [MMTabBarView.bundle imageForResource:@"AquaTabClose_Front_Rollover"];
        case MMCloseButtonImageTypePressed:
            return [MMTabBarView.bundle imageForResource:@"AquaTabClose_Front_Pressed"];
        case MMCloseButtonImageTypeDirty:
            return [MMTabBarView.bundle imageForResource:@"AquaTabCloseDirty_Front"];
        case MMCloseButtonImageTypeDirtyRollover:
            return [MMTabBarView.bundle imageForResource:@"AquaTabCloseDirty_Front_Rollover"];
        case MMCloseButtonImageTypeDirtyPressed:
            return [MMTabBarView.bundle imageForResource:@"AquaTabCloseDirty_Front_Pressed"];
        default:
            return nil;
    }
}

#pragma mark - Cell Values

/*!
 * @brief The color a tab's title is drawn in
 *
 * The Mojave catalogue this was taken from is eight appearances deep, but only two dimensions of it
 * ever reach a label: its high contrast variants carry byte-identical font colors to the plain
 * ones, and all four of its inactive variants collapse to a single color. What is left is the
 * window state and dark mode, and the window state decides it outright - a window that is not main
 * is answered below before the appearance is ever consulted.
 */
- (NSColor *)_labelColorOfTabCell:(MMTabBarButtonCell *)cell
{
    NSWindow *window = cell.tabBarView.window;

    // A cell measured before it is in a window. The catalogue calls that state inactive.
    if (!window)
        return NSColor.disabledControlTextColor;

    /* This style's own departure: the dimmed gray a solid tab bar can carry is too pale on a
     * translucent pill, which leaves the text far less contrast behind it. Note this also decides
     * the key-but-not-main window, which the catalogue would still have called active. */
    if (!window.isMainWindow)
        return NSColor.secondaryLabelColor;

    if (cell.tabBarButton.state == NSControlStateValueOn)
        return NSColor.textColor;

    // In the dark, hovered and plain unselected tabs share one color; in the light they do not.
    if (MMTahoeAppearanceOfTabBarView(cell.tabBarView).dark)
        return NSColor.secondaryLabelColor;

    return cell.mouseHovered ? NSColor.textColor : NSColor.labelColor;
}

- (NSAttributedString *)attributedStringValueForTabCell:(MMTabBarButtonCell *)cell
{
    NSString *contents = cell.title;
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:contents];
    NSRange range = NSMakeRange(0, contents.length);

    // 12 pt where the older styles use 11: on a 34 pt bar the smaller label reads undersized.
    [attrStr addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12.0] range:range];
    [attrStr addAttribute:NSForegroundColorAttributeName value:[self _labelColorOfTabCell:cell] range:range];

    /* Built once and kept, as the other styles in this framework do it. Centered because a pill is
     * wider than its title whenever the leading slot is empty, and truncating because
     * -titleRectForBounds: hands over only what icon, badge and progress indicator leave behind. */
    static NSMutableParagraphStyle *TruncatingTailParagraphStyle = nil;
    if (!TruncatingTailParagraphStyle)
    {
        TruncatingTailParagraphStyle = [NSParagraphStyle.defaultParagraphStyle mutableCopy];
        [TruncatingTailParagraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
        [TruncatingTailParagraphStyle setAlignment:NSTextAlignmentCenter];
    }
    [attrStr addAttribute:NSParagraphStyleAttributeName value:TruncatingTailParagraphStyle range:range];

    return attrStr;
}

#pragma mark - Drag Support

/* The stacking frame, not the button's current frame: mid-slide the frame is wherever the animation
 * has got to, and the drag image would be cut from the wrong place. The extra point is what this
 * style has always dragged with - the framework's default rect is that one point narrower. */
- (NSRect)draggingRectForTabButton:(MMAttachedTabBarButton *)aButton ofTabBarView:(MMTabBarView *)tabBarView
{
    NSRect dragRect = aButton.stackingFrame;
    dragRect.size.width++;
    return dragRect;
}

#pragma mark - Drawing

/*!
 * @brief The single hairline this style draws, in the eight shades the catalogue held for it
 *
 * sRGB literals rather than the named colors they resemble: these are the catalogue's own values,
 * and swapping in blackColor for the dark entry would change the color space and with it the color.
 */
- (NSColor *)_separatorColorOfTabBarView:(MMTabBarView *)tabBarView
{
    MMTahoeAppearance appearance = MMTahoeAppearanceOfTabBarView(tabBarView);

    if (appearance.dark) {
        // The one entry that does not vary with the window state.
        if (!appearance.highContrast)
            return [NSColor colorWithSRGBRed:0.000 green:0.000 blue:0.000 alpha:1.0];

        return appearance.windowActive ? [NSColor colorWithSRGBRed:0.349 green:0.349 blue:0.349 alpha:1.0]
                                       : [NSColor colorWithSRGBRed:0.325 green:0.325 blue:0.325 alpha:1.0];
    }

    if (appearance.highContrast)
        return appearance.windowActive ? [NSColor colorWithSRGBRed:0.565 green:0.565 blue:0.565 alpha:1.0]
                                       : [NSColor colorWithSRGBRed:0.675 green:0.675 blue:0.675 alpha:1.0];

    return appearance.windowActive ? [NSColor colorWithSRGBRed:0.655 green:0.651 blue:0.651 alpha:1.0]
                                   : [NSColor colorWithSRGBRed:0.820 green:0.820 blue:0.820 alpha:1.0];
}

- (void)drawBezelOfTabBarView:(MMTabBarView *)tabBarView inRect:(NSRect)rect
{
    rect = tabBarView.bounds;

    // No opaque background: the hosting window places a vibrancy backdrop
    // behind the bar (falling back to the plain window background).

    // Single subtle separator towards the message view; no top hairline,
    // no per-tab dividers — Tahoe is line-less.
    [[self _separatorColorOfTabBarView:tabBarView] set];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect) - 0.5)
                              toPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect) - 0.5)];
}

- (void)drawBezelOfTabCell:(MMTabBarButtonCell *)cell withFrame:(NSRect)frame inView:(NSView *)controlView
{
    MMTabBarView *tabBarView = controlView.enclosingTabBarView;
    MMAttachedTabBarButton *button = (MMAttachedTabBarButton *)controlView;

    [self _drawPillInRect:frame usingStatesOfAttachedButton:button ofTabBarView:tabBarView];
}

- (void)drawBezelOfOverflowButton:(MMOverflowPopUpButton *)overflowButton ofTabBarView:(MMTabBarView *)tabBarView inRect:(NSRect)rect
{
    MMAttachedTabBarButton *lastAttachedButton = tabBarView.lastAttachedButton;

    if (lastAttachedButton.isSliding)
        return;

    [self _drawPillInRect:overflowButton.frame usingStatesOfAttachedButton:lastAttachedButton ofTabBarView:tabBarView];
}

#pragma mark - Private Methods

- (void)_drawPillInRect:(NSRect)frame usingStatesOfAttachedButton:(MMAttachedTabBarButton *)button ofTabBarView:(MMTabBarView *)tabBarView
{
    NSRect pillRect = NSInsetRect(frame, kMMTahoePillInsetX, kMMTahoePillInsetY);
    if (NSIsEmptyRect(pillRect))
        return;

    /* Translucent fills so the pills sit naturally on the vibrancy
     * backdrop the hosting window places behind the bar. */
    BOOL dark = NO;
    if (@available(macOS 10.14, *)) {
        NSAppearanceName match = [tabBarView.effectiveAppearance
            bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
        dark = [match isEqualToString:NSAppearanceNameDarkAqua];
    }

    NSColor *fillColor = nil;
    if (button.state == NSControlStateValueOn)
        fillColor = [NSColor colorWithCalibratedWhite:(dark ? 1.0 : 1.0)
                                                alpha:(dark ? 0.22 : 0.65)];
    else if (button.cell.mouseHovered)
        fillColor = [NSColor colorWithCalibratedWhite:(dark ? 1.0 : 1.0)
                                                alpha:(dark ? 0.10 : 0.35)];

    if (!fillColor)
        return;   // unselected, not hovered: pill stays invisible

    CGFloat radius = pillRect.size.height / 2.0;
    NSBezierPath *pill = [NSBezierPath bezierPathWithRoundedRect:pillRect xRadius:radius yRadius:radius];
    [fillColor set];
    [pill fill];
}

@end

NS_ASSUME_NONNULL_END
