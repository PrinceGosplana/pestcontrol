#import "Bug.h"
#import "Player.h"
#import "TileMapLayer.h"
#import "MyScene.h"


@implementation Bug

static SKAction * sharedFacingBackAnim = nil;
- (SKAction *) facingBackAnim {
    return sharedFacingBackAnim;
}

static SKAction * sharedFacingForwardAnim = nil;
- (SKAction *)facingForwardAnim {
    return sharedFacingForwardAnim;
}

static SKAction * sharedFacingLeftAnim = nil;
- (SKAction *)facingLeftAnim {
    return sharedFacingLeftAnim;
}

static SKAction * sharedFacingRightAnim = nil;
- (SKAction *)facingRightAnim {
    return sharedFacingRightAnim;
}

+ (void) initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFacingForwardAnim = [Bug createAnimWithPrefix:@"bug" suffix:@"ft"];
        sharedFacingBackAnim = [Bug createAnimWithPrefix:@"bug" suffix:@"bk"];
        sharedFacingLeftAnim = [Bug createAnimWithPrefix:@"bug" suffix:@"lt"];
        sharedFacingRightAnim = [Bug createAnimWithPrefix:@"bug" suffix:@"rt"];
    });
}

- (instancetype) init {
    SKTextureAtlas * atlas = [SKTextureAtlas atlasNamed:@"characters"];
    SKTexture * texture = [atlas textureNamed:@"bug_ft1"];
    texture.filteringMode = SKTextureFilteringNearest;
    if (self = [super initWithTexture:texture]) {
        self.name = @"bug";
        CGFloat minDiam = MIN(self.size.width, self.size.height);
        minDiam = MAX(minDiam - 8, 8);
        self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:minDiam / 2.0f];
        self.physicsBody.categoryBitMask = PCPhysicsCategoryBug;
        self.physicsBody.collisionBitMask = 0;
        
        [self runAction:self.facingForwardAnim];
    }
    return self;
}

- (void) walk {
    // 1
    TileMapLayer * tileLayer = (TileMapLayer *) self.parent;
    // 2
    CGPoint tileCoord = [tileLayer coordForPoint:self.position];
    int randomX = arc4random() % 3 - 1;
    int randomY = arc4random() % 3 - 1;
    CGPoint randomCoord = CGPointMake(tileCoord.x + randomX, tileCoord.y + randomY);
    // 3
    BOOL didMove = NO;
    MyScene * scene = (MyScene *)self.scene;

    if ([tileLayer isValidTileCoord:randomCoord] && ![scene tileAtCoord:randomCoord hasAnyProps:(PCPhysicsCategoryWall | PCPhysicsCategoryWater | PCPhysicsCategoryBreakable)]) {
        // 4
        didMove = YES;
        CGPoint randomPos = [tileLayer pointForcoord:randomCoord];
        // TODO: block
//        SKAction * moveToPos = [SKAction sequence:@[
//                                                    [SKAction moveTo:randomPos duration:1],
//                                                    [SKAction runBlock:^{
//            [self walk];
//        }]]];
        SKAction * moveToPos = [SKAction sequence:
                                @[[SKAction moveTo:randomPos duration:1],
                                  [SKAction performSelector:@selector(walk) onTarget:self]]];
        [self runAction:moveToPos];
        [self faceDirection:CGPointMake(randomX, randomY)];
    }
    // 5
    if (!didMove) {
        [self runAction:[SKAction sequence:@[[SKAction waitForDuration:0.25 withRange:0.15],
                                             [SKAction performSelector:@selector(walk) onTarget:self]]]];
    }
    
}

- (void)start {
    [self walk];
}

- (void) faceDirection: (CGPoint) dir {
    PCFacingDirection facingDir = self.facingDirection;
    
    if (dir.y != 0 && dir.x != 0) {
        facingDir = dir.y < 0 ? PCFacingDirectionBack : PCFacingDirectionForward;
        self.zRotation = dir.y < 0 ? M_PI_4 : -M_PI_4;
        if (dir.x > 0) {
            self.zRotation *= -1;
        }
    } else {
        self.zRotation = 0;
        
        if (dir.y == 0) {
            if (dir.x > 0) {
                facingDir = PCFacingDirectionRight;
            } else if (dir.x < 0) {
                facingDir = PCFacingDirectionLeft;
            }
        } else if (dir.y < 0) {
            facingDir = PCFacingDirectionBack;
        } else {
            facingDir = PCFacingDirectionForward;
        }
    }
    self.facingDirection = facingDir;
}
@end
