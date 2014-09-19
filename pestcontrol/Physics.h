//
//  Physics.h
//  pestcontrol
//
//  Created by Administrator on 31.07.14.
//  Copyright (c) 2014 Administrator. All rights reserved.
//

#ifndef pestcontrol_Physics_h
#define pestcontrol_Physics_h

typedef NS_OPTIONS(uint32_t, PCPhysicsCategory) {
    PCPhysicsCategoryBoundary       = 1 << 0,
    PCPhysicsCategoryPlayer         = 1 << 1,
    PCPhysicsCategoryBug            = 1 << 2,
    PCPhysicsCategoryWall           = 1 << 3,
    PCPhysicsCategoryWater          = 1 << 4,
    PCPhysicsCategoryBreakable      = 1 << 5,
    PCPhysicsCategoryFireBug        = 1 << 6,
    PCPhysicsCategoryCrackedWall    = 1 << 7
};

typedef NS_ENUM (int32_t, PCFacingDirection) {
    PCFacingDirectionForward,
    PCFacingDirectionBack,
    PCFacingDirectionRight,
    PCFacingDirectionLeft
};

typedef NS_ENUM (int32_t, PCGameState){
    PCGameStateStartingLevel,
    PCGameStatePlaying,
    PCGameStateInLevelMenu,
    PCGameStateInReloadMenu,
};

typedef NS_ENUM (NSInteger, Side) {
    SideRight = 0,
    SideLeft = 2,
    SideTop = 1,
    SideBottom = 3
};
#endif
