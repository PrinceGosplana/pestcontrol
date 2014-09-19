//
//  FireBug.m
//  PestControl2
//
//  Created by Oleksandr Isaiev on 30.07.14.
//  Copyright (c) 2014 None. All rights reserved.
//

#import "FireBug.h"
#import "MyScene.h"
#import "TileMapLayer.h"

@implementation FireBug

- (instancetype) init {
    if (self = [super init]) {
        self.physicsBody.categoryBitMask = PCPhysicsCategoryFireBug;
        self.physicsBody.collisionBitMask = PCPhysicsCategoryPlayer | PCPhysicsCategoryWall | PCPhysicsCategoryBreakable | PCPhysicsCategoryBoundary;
        self.physicsBody.linearDamping = 1;
        self.physicsBody.angularDamping = 1;
        self.color = [SKColor redColor];
        self.colorBlendFactor = 0.45;
    }
    return self;
}

- (void)kickBug {
    [self removeAllActions];
    [self runAction:[SKAction sequence:@[
                                         [SKAction waitForDuration:1.0],
                                         [SKAction performSelector:@selector(resumeAfterKick) onTarget:self]]]];
}


- (void) resumeAfterKick {
    self.physicsBody.velocity = CGVectorMake(0, 0);
    MyScene * scene = (MyScene *)self.scene;
    if ([scene tileAtPoint:self.position hasAnyProps:PCPhysicsCategoryWater]) {
        SKAction *drown =
        [SKAction group:@[[SKAction rotateByAngle:4*M_PI duration:1],
                          [SKAction scaleTo:0 duration:1]]];
        [self runAction:
         [SKAction sequence:@[drown,[SKAction removeFromParent]]]];

    } else {
        [self walk];
    }
}
@end
