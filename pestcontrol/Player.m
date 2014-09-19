#import "Player.h"
#import "MyScene.h"
#import "SKEmitterNode+SKTExtras.h"

@implementation Player

- (instancetype)init {
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed: @"characters"];
    SKTexture *texture = [atlas textureNamed:@"player_ft1"];
    texture.filteringMode = SKTextureFilteringNearest;
    if (self = [super initWithTexture:texture]) {
        self.name = @"player";
        CGFloat minDiam = MIN(self.size.width, self.size.height);
        minDiam = MAX(minDiam-16, 4);
        self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:minDiam/2.0]; // 2
        self.physicsBody.usesPreciseCollisionDetection = YES; // 3
        self.physicsBody.categoryBitMask = PCPhysicsCategoryPlayer;
        self.physicsBody.contactTestBitMask = 0xFFFFFFFF;
        self.physicsBody.collisionBitMask = PCPhysicsCategoryBoundary | PCPhysicsCategoryWall | PCPhysicsCategoryWater;
        self.physicsBody.allowsRotation = NO;
        self.physicsBody.restitution = 1;
        self.physicsBody.friction = 0;
        self.physicsBody.linearDamping = 0;

        self.facingForwardAnim = [Player createAnimWithPrefix:@"player" suffix:@"ft"];
        self.facingBackAnim = [Player createAnimWithPrefix:@"player" suffix:@"bk"];
        self.facingLeftAnim = [Player createAnimWithPrefix:@"player" suffix:@"lt"];
        self.facingRightAnim = [Player createAnimWithPrefix:@"player" suffix:@"rt"];
        [self runAction:self.facingForwardAnim];
    }
    return self;
}

- (void) moveToward: (CGPoint) targetPosition {
    CGPoint targetVector = CGPointNormalize(CGPointSubtract(targetPosition, self.position));
    
    targetVector = CGPointMultiplyScalar(targetVector, 450);
    self.physicsBody.velocity = CGVectorMake(targetVector.x, targetVector.y);
    
    [self faceCurrentDirection];
}

- (void) faceCurrentDirection {
    PCFacingDirection facingDir = self.facingDirection;
    
    CGVector dir = self.physicsBody.velocity;
    if (abs(dir.dy) > abs(dir.dx)) {
        if (dir.dy < 0) {
            facingDir = PCFacingDirectionForward;
        } else {
            facingDir = PCFacingDirectionBack;
        }
    } else {
        facingDir = (dir.dx > 0) ? PCFacingDirectionRight : PCFacingDirectionLeft;
    }
    
//    if (facingDir == 0) {
//        NSLog(@"Forward");
//    } else if (facingDir == 1) {
//        NSLog(@"Back");
//    } else if (facingDir == 2) {
//        NSLog(@"Right");
//    } else {
//        NSLog(@"Left");
//    }
    self.facingDirection = facingDir;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _emitter = [aDecoder decodeObjectForKey:@"Player-Emitter"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_emitter forKey:@"Player-Emitter"];
}

- (void) start {
    _emitter = [SKEmitterNode skt_emitterNamed:@"PlayerTrail"];
    _emitter.targetNode = self.parent;
    [self addChild:_emitter];
    self.zPosition = 100.0f;
}
@end
