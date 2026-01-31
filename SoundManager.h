// SoundManager.h - Audio generation and playback
#ifndef SOUNDMANAGER_H
#define SOUNDMANAGER_H

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@interface SoundManager : NSObject

+ (instancetype)shared;

@property (nonatomic, strong, readonly) NSSound *jumpSound;
@property (nonatomic, strong, readonly) NSSound *gunSound;
@property (nonatomic, strong, readonly) NSSound *enemyGunSound;
@property (nonatomic, strong, readonly) NSSound *doorSound;
@property (nonatomic, strong, readonly) NSSound *footstepSound;
@property (nonatomic, strong, readonly) NSSound *pickupSound;

- (void)playGunSound;
- (void)playEnemyGunSoundWithVolume:(float)volume;
- (void)playDoorSound;
- (void)playFootstepSound;
- (void)playPickupSound;

// Master volume (applied to all sounds)
@property (nonatomic) float masterVolume;

@end

#endif // SOUNDMANAGER_H
