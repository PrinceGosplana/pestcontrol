//
//  AnimatingSprite.h
//  PestControl2
//
//  Created by Oleksandr Isaiev on 29.07.14.
//  Copyright (c) 2014 None. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface AnimatingSprite : SKSpriteNode

@property (strong, nonatomic) SKAction * facingForwardAnim;
@property (strong, nonatomic) SKAction * facingBackAnim;
@property (strong, nonatomic) SKAction * facingLeftAnim;
@property (strong, nonatomic) SKAction * facingRightAnim;

@property (assign, nonatomic) PCFacingDirection facingDirection;

+ (SKAction *) createAnimWithPrefix: (NSString *) prefix suffix: (NSString *) suffix;

@end
