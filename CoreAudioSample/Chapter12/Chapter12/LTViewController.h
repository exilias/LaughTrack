//
//  LTViewController.h
//  Chapter12
//
//  Created by 石井 晃 on 13/08/19.
//  Copyright (c) 2013年 OneChance. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LTViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *currentLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *nowTalkingLabel;
@property (weak, nonatomic) IBOutlet UILabel *noiseLevelLabel;
@property BOOL isNoiseRecording;

- (IBAction)pushedNoiseRecordButton:(id)sender;

- (void)updateCurrentLevelLabel:(NSString *)str;
@end
