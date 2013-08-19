//
//  LTRemoteOutput.h
//  Chapter9
//
//  Created by 石井 晃 on 13/08/19.
//  Copyright (c) 2013年 OneChance. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LTRemoteOutput : NSObject

@property (nonatomic) double phase;
@property (nonatomic) Float32 sampleRate;


- (void)play;
- (void)stop;
- (void)prepareAudioUnit;

@end
