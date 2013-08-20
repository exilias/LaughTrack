//
//  LTRemoteIOPlayThru.h
//  Chapter12
//
//  Created by 石井 晃 on 13/08/19.
//  Copyright (c) 2013年 OneChance. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LTViewController.h"


@interface LTRemoteIOPlayThru : NSObject

@property (nonatomic, assign) LTViewController *superView;

- (void)prepareAUGraph;
- (void)play;
- (void)stop;
- (void)record:(NSURL *)toURL;	// 録音を実行するメソッド
- (void)stopRecording;

@end
