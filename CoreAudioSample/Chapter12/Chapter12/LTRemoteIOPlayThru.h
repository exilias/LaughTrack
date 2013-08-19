//
//  LTRemoteIOPlayThru.h
//  Chapter12
//
//  Created by 石井 晃 on 13/08/19.
//  Copyright (c) 2013年 OneChance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LTRemoteIOPlayThru : NSObject

- (void)prepareAUGraph;
- (void)play;
- (void)stop;

@end
