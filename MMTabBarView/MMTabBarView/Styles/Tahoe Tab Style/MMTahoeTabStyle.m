//
//  MMTahoeTabStyle.m
//  -----------------
//
//  Changes released in accordance with MMTabBarView license.
//

#import <MMTabBarView/MMTahoeTabStyle.h>
#import "MMMojaveTabStyle+Assets.h"
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

static const CGFloat kMMTahoeBarHeight = 34.0;

// Status icons from typical icon packs carry a bit of baked-in bottom
// padding; nudge them down so they sit optically centered in the pill.
static const CGFloat kMMTahoeIconNudgeY = 1.0;

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

- (NSRect)drawingRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell
{
    NSRect result = NSInsetRect(theRect, 0, kMMTahoePillInsetY + 2.0);
    result.origin.x += kMMTahoePillInsetX + kMMTahoeContentPaddingLeft;
    result.size.width -= (kMMTahoePillInsetX + kMMTahoeContentPaddingLeft) + (kMMTahoePillInsetX + kMMTahoeContentPaddingRight);
    return result;
}

#pragma mark - Icon and Close Button (Chrome-style shared slot)

/* The close button occupies the same slot as the status icon: hovering a
 * tab swaps the icon for a circled X, like Chrome does with favicons. */

- (NSRect)_leadingSlotRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell imageSize:(NSSize)imageSize
{
    NSRect drawingRect = [self drawingRectForBounds:theRect ofTabCell:cell];

    if (imageSize.height > NSHeight(drawingRect)) {
        CGFloat scale = NSHeight(drawingRect) / imageSize.height;
        imageSize = NSMakeSize(imageSize.width * scale, imageSize.height * scale);
    }

    NSRect result;
    result.size = imageSize;
    result.origin.x = drawingRect.origin.x;
    if (imageSize.width < kMMTabBarIconWidth)
        result.origin.x += ceil((kMMTabBarIconWidth - imageSize.width) / 2.0);
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

- (NSRect)titleRectForBounds:(NSRect)theRect ofTabCell:(MMTabBarButtonCell *)cell
{
    NSRect drawingRect = [self drawingRectForBounds:theRect ofTabCell:cell];
    NSRect constrainedDrawingRect = drawingRect;

    // Icon and close button share one leading slot — reserve it once.
    NSRect iconRect = [cell iconRectForBounds:theRect];
    NSRect closeButtonRect = [cell closeButtonRectForBounds:theRect];
    CGFloat slotWidth = MAX(NSWidth(iconRect), NSWidth(closeButtonRect));
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

- (CGFloat)desiredWidthOfTabCell:(MMTabBarButtonCell *)cell
{
    // Must match our drawingRectForBounds padding or titles get truncated
    // even when there is plenty of room.
    CGFloat resultWidth = (kMMTahoePillInsetX * 2) + kMMTahoeContentPaddingLeft + kMMTahoeContentPaddingRight;

    // one leading slot shared by icon and close button
    if (cell.icon || cell.shouldDisplayCloseButton)
        resultWidth += kMMTabBarIconWidth + kMMTabBarCellPadding;

    resultWidth += cell.attributedStringValue.size.width;

    if (cell.showObjectCount)
        resultWidth += cell.objectCounterSize.width + kMMTabBarCellPadding;

    if (cell.isProcessing)
        resultWidth += kMMTabBarCellPadding + kMMTabBarIndicatorWidth;

    return ceil(resultWidth);
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

- (NSAttributedString *)attributedStringValueForTabCell:(MMTabBarButtonCell *)cell
{
    NSMutableAttributedString *attrStr = [[super attributedStringValueForTabCell:cell] mutableCopy];
    [attrStr addAttribute:NSFontAttributeName
                    value:[NSFont systemFontOfSize:12.0]
                    range:NSMakeRange(0, attrStr.length)];
    return attrStr;
}

#pragma mark - Drawing

- (void)drawBezelOfTabBarView:(MMTabBarView *)tabBarView inRect:(NSRect)rect
{
    rect = tabBarView.bounds;

    // No opaque background: the hosting window places a vibrancy backdrop
    // behind the bar (falling back to the plain window background).

    // Single subtle separator towards the message view; no top hairline,
    // no per-tab dividers — Tahoe is line-less.
    [[self colorForPart:MMMbezelBottom ofTabBarView:tabBarView] set];
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

    NSColor *fillColor = nil;
    if (button.state == NSOnState)
        fillColor = [self colorForPart:MMMtabSelected ofTabBarView:tabBarView];
    else if (button.cell.mouseHovered)
        fillColor = [self colorForPart:MMMtabUnselectedHover ofTabBarView:tabBarView];

    if (!fillColor)
        return;   // unselected, not hovered: pill stays invisible

    CGFloat radius = pillRect.size.height / 2.0;
    NSBezierPath *pill = [NSBezierPath bezierPathWithRoundedRect:pillRect xRadius:radius yRadius:radius];
    [fillColor set];
    [pill fill];
}

@end

NS_ASSUME_NONNULL_END
