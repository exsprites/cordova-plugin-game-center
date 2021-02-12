
# Work in progress fork

This is my fork to support GameCenter in my Cordova projects. I won't
have time to fix bugs or give any support but I still share my progress 
and new features here. 


# GameCenter Access Point in Cordvoa

Add some basic support for [GameCenter Access Point](https://developer.apple.com/design/human-interface-guidelines/game-center/overview/access-point/) (iOS 14+).


```js
// CHECK IF AVAILABLE

window.gamecenter.isAccessPointAvailable((available) => {
        // Basically you know the API should be there
        // Still need to call `checkAuth()` etc.
    },
    (err) => {}
);


// SHOW, HIDE and MODIFY the access point
const accessPointProps = {
    
    // OPTIONAL, sets position of the accesspoint
    //
    //
    // values: "TOP_LEFT"|"TOP_RIGHT"|"BOTTOM_LEFT"|"BOTTOM_RIGHT"
    // maps to: https://developer.apple.com/documentation/gamekit/gkaccesspointlocation?language=objc
    location: "TOP_LEFT",  
    
    // OPTIONAL, if highlights shall be shown
    //
    // maps to: https://developer.apple.com/documentation/gamekit/gkaccesspoint/3618827-showhighlights?language=objc
    showHighlights: true,
    
    // OPTIONAL, enable/disable access point
    //
    // maps to: https://developer.apple.com/documentation/gamekit/gkaccesspoint/3618827-showhighlights?language=objc
    active: true,  
};

window.gamecenter.modifyAccessPoint(() => {
        // success!
    }, (err) => {
        // failed!
    },
    accessPointProps,
);


// EXAMPLE hide access point
window.gamecenter.modifyAccessPoint(() => {}, () => {}, { active: false });
```

---


## Game Center Plugin for Apache Cordova 

This plugin allows developers to utilise the iOS Game Center in their Cordova / PhoneGap app.

The code under active development and currently has support for [auth](#auth), [submitting a score](#submit-score) and [showing leaderboards](#show-leaderboard) using the native viewcontroller.

### Before you start

Adding Game Center support requires more than simple coding changes. To create a Game Center-aware game, you need to understand these basics before you begin writing code. The full outline of all the Game Center concepts and impacts can be viewed [here](https://developer.apple.com/library/ios/documentation/NetworkingInternet/Conceptual/GameKit_Guide/GameCenterOverview/GameCenterOverview.html).

## Install

#### Latest version from GitHub

```
cordova plugin add https://github.com/CSchnackenberg/cordova-plugin-game-center.git
```

You **do not** need to reference any JavaScript, the Cordova plugin architecture will add a gamecenter object to your root automatically when you build. It will also automatically add the GameKit framework dependency.


## Usage

### Auth

You should do this as soon as your deviceready event has been fired. The plug handles the various auth scenarios for you.

```
var successCallback = function (user) {
    alert(user.alias);
    // user.alias, user.playerID, user.displayName
};

gamecenter.auth(successCallback, failureCallback);
```
### checkAuth

Method for checking Auth on Game Center
```
var successCallback = function (status) {
    alert(status.isAuth);
    // 1
};

gamecenter.checkAuth(successCallback, failureCallback);
```

### getUserData

Method for getting user information after auth
```
var successCallback = function (status) {
    alert(status.isAuth);
    // user.alias, user.playerID, user.displayName
};

gamecenter.getUserData(successCallback, failureCallback);
```

### Generate Identity Verification

Added new method for verification user on server
```
var successCallback = function (localPlayer) {
    alert(user.alias);
 //localPlayer.playerID, localPlayer.alias,localPlayer.displayName,
 //localPlayer.publicKeyUrl, localPlayer.signature, localPlayer.salt, localPlayer.tamestamp, localPlayer.bundleId                

gamecenter.generateIdentityVerification(successCallback, failureCallback);
```

### Fetch Player Image

Loads the current player's photo. Automatically cached on first retrieval.

```
var successCallback = function (path) {
    alert(path); // path to .jpg
};

gamecenter.getPlayerImage(successCallback, failureCallback);
```

### Submit Score

Ensure you have had a successful callback from `gamecenter.auth()` first before attempting to submit a score. You should also have set up your leaderboard(s) in iTunes connect and use the leaderboard identifier assigned there as the leaderboardId.

```
var data = {
    score: 10,
    leaderboardId: "board1"
};
gamecenter.submitScore(successCallback, failureCallback, data);
```

### Show leaderboard

Launches the native Game Center leaderboard view controller for a leaderboard.

```
var data = {
    leaderboardId: "board1"
};
gamecenter.showLeaderboard(successCallback, failureCallback, data);
```

*NB: The period option has been removed in 0.3.0 as it is no longer supported by iOS. The default period is "all time".*

### Report achievement

Reports an achievement to the game center:

```
var data = {
	achievementId: "MyAchievementName",
	percent: "100"
};

gamecenter.reportAchievement(successCallback, failureCallback, data);
```

### Reset achievements

Resets the user's achievements and leaderboard.

```
gamecenter.resetAchievements(successCallback, failureCallback);
```

### Fetch achievements

Fetches the user's achievements from the game center:

```
var successCallback = function (results) {
	if (results) {
    	for (var i = 0; i < results.length; i += 1) {
            //results[i].identifier
            //results[i].percentComplete
            //results[i].completed
            //results[i].lastReportedDate
            //results[i].showsCompletionBanner
            //results[i].playerID
        }
    }
}

gamecenter.getAchievements(successCallback, failureCallback);

```

## Platforms

Should work on iOS14, but no guarantees 🤓.


## License

[MIT License](http://ilee.mit-license.org)
