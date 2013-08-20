//
//  RemoteIOPlayThru.h
//  RemoteIOPlayThru
//
//  Created by Norihisa Nagano
//

#define FFT_SIZE 256
#define SAMPLE_RATE 22050.0

#import <Foundation/Foundation.h>
#import "iPhoneCoreAudio.h"
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import "FFT.h"

@interface RemoteIOPlayThru : NSObject {
    AUGraph mAuGraph;
    AudioUnit remoteIOUnit;
    BOOL isPlaying;
    
    FFT *fft;
    float *powerSpectrum;
    UInt32 frameSize;
}

@property(readonly) AudioUnit remoteIOUnit;
@property(readonly) FFT *fft;

-(float*)powerSpectrum;//追加
-(UInt32)frameSize;

-(void)prepareAUGraph;
-(void)play;
-(void)stop;
@end