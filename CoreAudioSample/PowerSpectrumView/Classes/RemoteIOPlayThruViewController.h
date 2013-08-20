//
//  RemoteIOPlayThruViewController.h
//  RemoteIOPlayThru
//
//  Created by Norihisa Nagano
//

#import <UIKit/UIKit.h>
#import "RemoteIOPlayThru.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "SpectrumView.h"


@interface RemoteIOPlayThruViewController : UIViewController {
    RemoteIOPlayThru *playThru;
    NSURL *recordingURL;
    
    IBOutlet SpectrumView *spectrumView;
}

-(void)initializeAudioSession;
-(void)startTimer;
@end