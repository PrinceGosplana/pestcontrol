//
//  AnimatingSprite.m
//  PestControl2
//
//  Created by Oleksandr Isaiev on 29.07.14.
//  Copyright (c) 2014 None. All rights reserved.
//

#import "AnimatingSprite.h"

@implementation AnimatingSprite

+ (SKAction *)createAnimWithPrefix:(NSString *)prefix suffix:(NSString *)suffix {
    SKTextureAtlas * atlas = [SKTextureAtlas atlasNamed:@"characters"];
    NSArray *textures =
  @[[atlas textureNamed:[NSString stringWithFormat:@"%@_%@1", prefix, suffix]],
    [atlas textureNamed:[NSString stringWithFormat:@"%@_%@2", prefix, suffix]]];
    
    [textures[0] setFilteringMode:SKTextureFilteringNearest];
    [textures[1] setFilteringMode:SKTextureFilteringNearest];
    
    return [SKAction repeatActionForever:
            [SKAction animateWithTextures:textures
                             timePerFrame:0.20]];
}

- (void) setFacingDirection:(PCFacingDirection)facingDirection {
    _facingDirection = facingDirection;
    
    switch (facingDirection) {
        case PCFacingDirectionForward:
            [self runAction:self.facingForwardAnim];
            break;
        case PCFacingDirectionBack:
            [self runAction:self.facingBackAnim];
            break;
        case PCFacingDirectionLeft:
            [self runAction:self.facingLeftAnim];
            break;
        case PCFacingDirectionRight:
            [self runAction:self.facingRightAnim];
            break;
        default:
            break;
    }
}

// Saving and loading state
- (void) encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:_facingForwardAnim forKey:@"AS-ForwardAnim"];
    [aCoder encodeObject:_facingBackAnim forKey:@"AS-BackAnim"];
    [aCoder encodeObject:_facingLeftAnim forKey:@"AS-LeftAnim"];
    [aCoder encodeObject:_facingRightAnim forKey:@"AS-RightAnim"];
    [aCoder encodeInt32:_facingDirection forKey:@"AS-FacingDirection"];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _facingForwardAnim = [aDecoder decodeObjectForKey:@"AS-ForwardAnim"];
        _facingBackAnim = [aDecoder decodeObjectForKey:@"AS-BackAnim"];
        _facingLeftAnim = [aDecoder decodeObjectForKey:@"AS-LeftAnim"];
        _facingRightAnim = [aDecoder decodeObjectForKey:@"AS-RightAnim"];
        _facingDirection = [aDecoder decodeInt32ForKey:@"AS-FacingDirection"];
    }
    return self;
}
@end
