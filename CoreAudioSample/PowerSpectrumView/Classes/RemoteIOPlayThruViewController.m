//
//  RemoteIOPlayThruViewController.m
//  RemoteIOPlayThru
//
//  Created by Norihisa Nagano
//

#import "RemoteIOPlayThruViewController.h"


@interface RemoteIOPlayThruViewController ()

@property float noiseVolume;
@property BOOL isSpeaking, isInstantSpeaking, justNow, preIsSpeaking;
@property float timeInSilent, timeFromLastSpeak, timeInInstantSpeaking, timeInNonInstantSpeaking, timeInSpeaking;
@property float *sampleAry;
@property int sampleIndex;

@property AVAudioPlayer *player;

@end



@implementation RemoteIOPlayThruViewController

- (void)viewDidLoad {
	AudioSessionInitialize(NULL, NULL, NULL, NULL);
    UInt32 category = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                            sizeof(UInt32),
                            &category);
	UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride);
	
    AudioSessionSetActive(YES);
	
	
	self.noiseVolume = 0.2;
	self.isSpeaking = self.isInstantSpeaking = self.justNow = self.preIsSpeaking = NO;
	self.timeInSilent = self.timeFromLastSpeak = self.timeInInstantSpeaking = self.timeInNonInstantSpeaking = self.timeInSpeaking = 0.0f;
	self.sampleIndex = 0;
	self.sampleAry = (float *)malloc(sizeof(float) * 30);
	for (int i = 0; i < 30; i++) {
		self.sampleAry[i] = 0;
	}
	
    [self initializeAudioSession];
    playThru = [[RemoteIOPlayThru alloc]init];
    [playThru play];
    
    [self startTimer];
}

-(void)initializeAudioSession{
    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    AudioSessionSetActive(YES);    
    
    //現在のサンプリングレートを確認する
    UInt32 size = sizeof(Float64);
    Float64 sampleRate;
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, 
                            &size, 
                            &sampleRate);
    printf("sampleRate = %f\n",sampleRate);
    
    //サンプリングレートを変更する
    Float64 newSampleRate = SAMPLE_RATE;
    size = sizeof(Float64);
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareSampleRate, 
                            size, 
                            &newSampleRate);
    
    //変更後のサンプリングレートを確認
    size = sizeof(Float64);
    AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, 
                            &size, 
                            &sampleRate);
    printf("sampleRate = %f\n",sampleRate);
    
    size = sizeof(UInt32);
    UInt32 category = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, 
                            size, 
                            &category);
    
    Float32 duration = FFT_SIZE / SAMPLE_RATE;
    printf("duration = %f\n",duration);
    printf("framesize = %f\n",SAMPLE_RATE * duration);

    //IOBufferDurationを変更する
    size = sizeof(Float32);
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, 
                            size,
                            &duration);
}

-(void)startTimer{
    [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(update) userInfo:nil repeats:YES];
}

-(void)update{
    float *powerSpectrum = [playThru powerSpectrum];
    UInt32 frameSize = [playThru frameSize];
    [spectrumView setSpectrum:powerSpectrum bandSize:frameSize / 2];
	
	float powerSpecAvr = 0;
    for (int i = 0; i < 8; i++) {
        powerSpecAvr += powerSpectrum[i];
    }
    powerSpecAvr /= 8;
	
    self.sampleAry[self.sampleIndex] = powerSpecAvr;
	
    self.sampleIndex++;
	
    if(self.sampleIndex >= 30){
        self.sampleIndex = 0;
    }
	
    //sample[30]の平均を求める
    float sampleAverage = 0.0;
    for(int i=0; i < 30; i++){
        sampleAverage += self.sampleAry[i];
    }
	
    sampleAverage /= 30;
    //NSLog(@"%f", sampleAverage);
	
    // ここで発話アルゴリズムを書く
    // -------------------------------
	
    if (sampleAverage > (/*self.noiseVolume * 2*/0.3)) {
        if (!self.isInstantSpeaking) {
            self.isInstantSpeaking = YES;
        }
    } else {
        if (self.isInstantSpeaking) {
            self.isInstantSpeaking = NO;
        }
    }
	
    if (self.isInstantSpeaking) {
        self.timeInInstantSpeaking += 0.01;
        self.timeInNonInstantSpeaking = 0;
        self.isSpeaking = YES;
    } else {
        self.timeInInstantSpeaking = 0;
        self.timeInNonInstantSpeaking += 0.01;
        self.isSpeaking = NO;
    }
	
    // 発話フラグのオンオフ
    if (self.isSpeaking) {
        if (self.timeInNonInstantSpeaking > 0.2) {
            self.isSpeaking = NO;
        }
    } else {
        if (self.timeInInstantSpeaking > 0.2) {
            self.isSpeaking = YES;
        }
    }
	
    // 今でしょフラグのオンオフ
    if(self.preIsSpeaking && !self.isSpeaking) {
        if (self.timeInSpeaking >= 0.2 && self.timeFromLastSpeak >= 2.1) {
            self.justNow = YES;
        }
    }
	
    if (self.isSpeaking) {
        //NSLog(@"発話");
        self.timeInSpeaking += 0.01;
        self.timeInSilent = 0;
    } else {
        //NSLog(@"not発話");
        self.timeInSpeaking = 0;
        self.timeInSilent += 0.01;
    }
	
    // 相づち処理
    if(self.justNow) {
        NSLog(@"今でしょ！");
        self.justNow = NO;
        self.timeFromLastSpeak = 0;
		
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Normal_un_1" ofType:@"wav"];
		NSURL *fileURL = [NSURL fileURLWithPath:path];
		self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
		self.player.volume = 1.0;
		[self.player play];
    } else {
        self.timeFromLastSpeak += 0.01;
    }
	
    self.preIsSpeaking = self.isSpeaking;

}


- (void)dealloc {
    [super dealloc];
}

@end
