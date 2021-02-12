
var exec = require("cordova/exec");

const boolToString = function(prop) {
    if (prop === true)
        return 'yes';
    if (prop === false)
        return 'no';

    var propType = typeof prop;
    if (propType == 'string') {
        const noCase = prop.toLowerCase();
        if (noCase == 'true')
            return 'yes';
        if (noCase == 'false')
            return 'no';
    }
    return '';
};

module.exports = {
    name: "GameCenter",
    _loggedin: false,
    auth: function (success, failure) {
        var self = this;
        exec(function (result) {
                self._loggedin = true;
                success(result)
            },
            failure, "GameCenter", "auth", []);
    },
    checkAuth: function(success, failure) {
        exec(success, failure, "GameCenter", "checkAuth", []);
    },
    getUserData: function(success, failure) {
        exec(success, failure, "GameCenter", "getUserData", []);
    },
    isLoggedIn: function () {
        return this._loggedin;
    },
    generateIdentityVerification: function (success, failure) {
        exec(success, failure, "GameCenter", "generateIdentityVerification", []);
    },
    getPlayerImage: function (success, failure) {
        exec(success, failure, "GameCenter", "getPlayerImage", []);
    },
    submitScore: function (success, failure, data) {
        exec(success, failure, "GameCenter", "submitScore", [data]);
    },
    getPlayerScore: function (success, failure) {
        exec(success, failure, "GameCenter", "getPlayerScore", []);
    },
    showLeaderboard: function (success, failure, data) {
        exec(success, failure, "GameCenter", "showLeaderboard", [data]);
    },
    reportAchievement: function (success, failure, data) {
        exec(success, failure, "GameCenter", "reportAchievement", [data]);
    },
    resetAchievements: function (success, failure) {
        exec(success, failure, "GameCenter", "resetAchievements", []);
    },
    getAchievements: function (success, failure) {
        exec(success, failure, "GameCenter", "getAchievements", []);
    },
    getScore: function (success, failure, data) {
        exec(success, failure, "GameCenter", "getScore", [data]);
    },

    isAccessPointAvailable: function (success, failure) {
        exec(success, failure, "GameCenter", "isAccessPointAvailable", []);
    },
    modifyAccessPoint: function (success, failure, data) {
        // make sure nothing bad can happen here
        var sendData = {};
        if (typeof data == 'object') {
            if (typeof data.location == 'string') {
                sendData.location = data.location;
            }
            if (typeof data.showHighlights != 'undefined') {
                sendData.showHighlights = boolToString(data.showHighlights);
            }
            if (typeof data.active != 'undefined') {
                sendData.active = boolToString(data.active);
            }
        }
        exec(success, failure, "GameCenter", "modifyAccessPoint", [sendData]);
    },
}


