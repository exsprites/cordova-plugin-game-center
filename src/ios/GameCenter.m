//
//  GameCenter.m
//  Copyright (c) 2013-2015 Lee Crossley - http://ilee.co.uk
//

#import "Cordova/CDV.h"
#import "Cordova/CDVViewController.h"
#import "GameCenter.h"

@implementation GameCenter

- (void) auth:(CDVInvokedUrlCommand*)command;
{
    [self.commandDelegate runInBackground:^{

        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];

        if([[GKLocalPlayer localPlayer] authenticateHandler] == nil) {
            localPlayer.authenticateHandler = ^(UIViewController *viewController, NSError *error) {
                CDVPluginResult* pluginResult = nil;
                if (viewController != nil)
                {
                    // Login required
                    [self.viewController presentViewController:viewController animated:YES completion:nil];
                }
                else
                {
                    if (localPlayer.isAuthenticated)
                    {
                        NSDictionary* user = @{
                                               @"alias":localPlayer.alias,
                                               @"displayName":localPlayer.displayName,
                                               @"playerID":localPlayer.playerID
                                               };
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:user];
                    }
                    else if (error != nil)
                    {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
                    }
                    else
                    {
                        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"already set"];
                    }
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                }
            };
        }
        else
        {
            CDVPluginResult* pluginResult = nil;
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"already set"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
}

-(void)checkAuth:(CDVInvokedUrlCommand*)command;
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        if([GKLocalPlayer localPlayer].isAuthenticated)
        {
            NSDictionary* status = @{@"isAuth":@true};
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:status];
        }
        else
        {
            NSDictionary* status = @{@"isAuth":@false};
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:status];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
     }];
}

-(void)getUserData:(CDVInvokedUrlCommand*)command;
{
    [self.commandDelegate runInBackground:^{
        CDVPluginResult* pluginResult = nil;
        if([GKLocalPlayer localPlayer].isAuthenticated)
        {
            NSDictionary* user = @{
                @"alias":[GKLocalPlayer localPlayer].alias,
                @"displayName":[GKLocalPlayer localPlayer].displayName,
                @"playerID":[GKLocalPlayer localPlayer].playerID
            };
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:user];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"not isAuthenticated"];
        }
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) generateIdentityVerification:(CDVInvokedUrlCommand*)command;
{
    [self.commandDelegate runInBackground:^{

        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];

        [localPlayer generateIdentityVerificationSignatureWithCompletionHandler:^(NSURL *publicKeyUrl, NSData *signature, NSData *salt, uint64_t timestamp, NSError *error) {
            __block CDVPluginResult* pluginResult = nil;
            if(error != nil)
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } else {
                NSDictionary* user = @{
                       @"playerId":localPlayer.playerID,
                       @"alias":localPlayer.alias,
                       @"displayName":localPlayer.displayName,
                       @"publicKeyUrl":[publicKeyUrl absoluteString],
                       @"signature":[self base64forData:signature],
                       @"salt":[self base64forData:salt],
                       @"timestamp":@(timestamp),
                       @"bundleId": [[NSBundle mainBundle] bundleIdentifier]
                };
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:user];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];
    }];
}

- (void) getPlayerImage:(CDVInvokedUrlCommand*)command;
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    __block CDVPluginResult* pluginResult = nil;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:
                      @"user.jpg" ];

    // Check if the user photo is cached
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:path];

    if(fileExists){
        // Return it if it does
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:path];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }else{
        // Else load it from the game center
        [localPlayer loadPhotoForSize:GKPhotoSizeSmall withCompletionHandler:^(UIImage *photo, NSError *error) {

            if (photo != nil)
            {
                NSData* data = UIImageJPEGRepresentation(photo, 0.8);
                [data writeToFile:path atomically:YES];
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:path];
            }
            if (error != nil)
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }
}

- (void) submitScore:(CDVInvokedUrlCommand*)command;
{
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    int64_t score = [[args objectForKey:@"score"] integerValue];
    NSString *leaderboardId = [args objectForKey:@"leaderboardId"];

    __block CDVPluginResult* pluginResult = nil;

    // Different methods depending on iOS version
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0)
    {
        GKScore *scoreSubmitter = [[GKScore alloc] initWithLeaderboardIdentifier: leaderboardId];
        scoreSubmitter.value = score;
        scoreSubmitter.context = 0;

        [GKScore reportScores:@[scoreSubmitter] withCompletionHandler:^(NSError *error) {
            if (error)
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            }
            else
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }
    else
    {
        GKScore *scoreSubmitter = [[GKScore alloc] initWithLeaderboardIdentifier:leaderboardId];
        scoreSubmitter.value = score;

        [GKScore reportScores:@[scoreSubmitter] withCompletionHandler:^(NSError *error) {
            if (error)
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            }
            else
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }
}

- (void)getPlayerScore:(CDVInvokedUrlCommand *)command {
 	NSString *leaderboardId = [command.arguments objectAtIndex:0];

	GKLeaderboard *leaderboard = [[GKLeaderboard alloc] init];
  	leaderboard.identifier = leaderboardId;
	[leaderboard loadScoresWithCompletionHandler: ^(NSArray *scores, NSError *error) {
		if (error) {
			NSLog(@"%@", error);

			//CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
			//[pr setKeepCallbackAsBool:YES];
			//[self.commandDelegate sendPluginResult:pr callbackId:command.callbackId];
			CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
			//[pr setKeepCallbackAsBool:YES];
			[self.commandDelegate sendPluginResult:pr callbackId:command.callbackId];
		}
		else if (scores) {
			GKScore *s = leaderboard.localPlayerScore;
			NSLog(@"Local player's score: %lld", s.value);

            CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:[NSString stringWithFormat:@"%lld", s.value]];
 			//[pr setKeepCallbackAsBool:YES];
			[self.commandDelegate sendPluginResult:pr callbackId:command.callbackId];
			//CDVPluginResult* pr = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
			//[pr setKeepCallbackAsBool:YES];
			//[self.commandDelegate sendPluginResult:pr callbackId:command.callbackId];
		}
	}];
}

- (void) reportAchievement:(CDVInvokedUrlCommand*)command;
{
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *achievementId = [args objectForKey:@"achievementId"];
    NSString *percent = [args objectForKey:@"percent"];

    float percentFloat = [percent floatValue];

    __block CDVPluginResult* pluginResult = nil;

    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier: achievementId];
    if (achievement)
    {
        achievement.percentComplete = percentFloat;
        achievement.showsCompletionBanner = YES;

        NSArray *achievements = [NSArray arrayWithObjects:achievement, nil];

        [GKAchievement reportAchievements:achievements withCompletionHandler:^(NSError *error) {
            if (error != nil)
            {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
            }
            else
            {
                // Achievement notification banners are broken on iOS 7 so we do it manually here if 100%:
                if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0 &&
                    [[[UIDevice currentDevice] systemVersion] floatValue] < 8.0 &&
                    floorf(percentFloat) >= 100)
                {
                    [GKNotificationBanner showBannerWithTitle:@"Achievement" message:@"Completed!" completionHandler:^{}];
                }

                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    }

}


- (void) resetAchievements:(CDVInvokedUrlCommand*)command;
{
    __block CDVPluginResult* pluginResult = nil;

    // Clear all progress saved on Game Center.
    [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error)
     {
         if (error != nil)
         {
             pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
         } else {
             pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
         }
         [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

     }
    ];

}

- (void) showLeaderboard:(CDVInvokedUrlCommand*)command;
{
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *leaderboardId = [args objectForKey:@"leaderboardId"];
    NSString *showAchievements = [args objectForKey:@"showAchievements"];

    CDVPluginResult* pluginResult = nil;

    GKGameCenterViewController *gameCenterController = [[GKGameCenterViewController alloc] init];
    if (gameCenterController != nil)
    {
        gameCenterController.gameCenterDelegate = self;

        if (leaderboardId.length > 0)
        {
            gameCenterController.leaderboardIdentifier = leaderboardId;
        }

        if ([showAchievements isEqualToString:@"true"])
        {
            gameCenterController.viewState = GKGameCenterViewControllerStateAchievements;
        }
        else
        {
            gameCenterController.viewState = GKGameCenterViewControllerStateLeaderboards;
        }

        [self.viewController presentViewController:gameCenterController animated:YES completion:nil];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    }
    else
    {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) getAchievements:(CDVInvokedUrlCommand*)command;
{
     __block CDVPluginResult* pluginResult = nil;
     NSMutableArray *earntAchievements = [NSMutableArray array];

     [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error)
     {
         if (error == nil)
         {
             for (GKAchievement* achievement in achievements)
             {
                 NSMutableDictionary *entry = [NSMutableDictionary dictionary];
                 entry[@"identifier"] = achievement.identifier;
                 entry[@"percentComplete"] = [NSNumber numberWithDouble: achievement.percentComplete];
                 entry[@"completed"] = [NSNumber numberWithBool:achievement.completed];
                 entry[@"lastReportedDate"] = [NSNumber numberWithDouble:[achievement.lastReportedDate timeIntervalSince1970] * 1000];
                 entry[@"showsCompletionBanner"] = [NSNumber numberWithBool:achievement.showsCompletionBanner];
                 entry[@"playerID"] = achievement.playerID;

                 [earntAchievements addObject:entry];
             }
             pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray: earntAchievements];
         }
         else
         {
             pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
         }
         [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
     }];
}


- (NSString*)base64forData:(NSData*)theData
{
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];

    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;

    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;

            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }

        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }

    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

- (void) getScore:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    NSMutableDictionary *args = [command.arguments objectAtIndex:0];
    NSString *leaderboardId = [args objectForKey:@"leaderboardId"];

    GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
    leaderboardRequest.identifier = leaderboardId;

    [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
        if (error) {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[error localizedDescription]];
        } else if (scores) {
            GKScore *localPlayerScore = leaderboardRequest.localPlayerScore;

            NSDictionary* userScore = @{
                                        @"score": [NSNumber numberWithLongLong:localPlayerScore.value]
                                        };
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:userScore];
        } else {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        }

        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) isAccessPointAvailable:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    if (@available(iOS 14.0, *)) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:false];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];

}

- (void) modifyAccessPoint:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    if (@available(iOS 14.0, *)) {

        NSDictionary* options = [command argumentAtIndex:0 withDefault:[NSNull null]];
        if ((NSNull *)options == [NSNull null])
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:false];
        }
        else
        {
            NSString* position = nil;

            position = [options objectForKey:@"location"];
            if (position && [position length] > 0) {

                if ([position isEqualToString:@"TOP_LEFT"]) {
                    [GKAccessPoint shared].location = GKAccessPointLocationTopLeading;
                }
                else if ([position isEqualToString:@"TOP_RIGHT"]) {
                    [GKAccessPoint shared].location = GKAccessPointLocationTopTrailing;
                }
                else if ([position isEqualToString:@"BOTTOM_LEFT"]) {
                    [GKAccessPoint shared].location = GKAccessPointLocationBottomLeading;
                }
                else if ([position isEqualToString:@"BOTTOM_RIGHT"]) {
                    [GKAccessPoint shared].location = GKAccessPointLocationBottomTrailing;
                }
            }

            NSString* highlights = nil;
            highlights = [options objectForKey:@"showHighlights"];
            if (highlights && [highlights length] > 0) {
                [GKAccessPoint shared].showHighlights = [highlights boolValue];
            }

            NSString* active = nil;
            active = [options objectForKey:@"active"];
            if (active && [active length] > 0) {
                [GKAccessPoint shared].active = [active boolValue];
            }

            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:true];
        }
    }
    else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:false];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}
@end
