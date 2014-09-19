#import <SpriteKit/SpriteKit.h>

@interface MyScene : SKScene

- (BOOL) tileAtPoint: (CGPoint) point hasAnyProps: (uint32_t) props;
- (BOOL) tileAtCoord: (CGPoint) coord hasAnyProps: (uint32_t) props;
- (instancetype) initWithSize:(CGSize)size level: (int) level;

@end

