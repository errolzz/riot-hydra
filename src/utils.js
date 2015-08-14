var U = {};

U.getOne = function(prop, value, list) {
    for(var i=0, l=list.length; i<l; i++) {
        if(list[i][prop] == value) {
            return list[i];
        }
    }
}
U.removeOne = function(prop, value, list) {
    for(var i=0, l=list.length; i<l; i++) {
        if(list[i][prop] == value) {
            return list.splice(i, 1);
        }
    }
}
U.getCookie = function(cname) {
    var name = cname + "=";
    var ca = document.cookie.split(';');
    for(var i=0; i<ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1);
        if (c.indexOf(name) == 0) return c.substring(name.length,c.length);
    }
    return "";
}
U.ajax = function(type, url, success, data, error) {
    var request = new XMLHttpRequest();
    request.open(type, url, true);
    request.onload = function() {
        if (request.status >= 200 && request.status < 400) {
            var data = JSON.parse(request.responseText);
            try {success(data);} catch(e) {}
        } else {
            console.log(request)
            try {error(request);} catch(e) {}
        }
    };
    request.onerror = function() {
        console.log(request)
        try {error(request);} catch(e) {}
    };
    if(type == 'POST' || type == 'PUT') {
        request.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
        request.send(JSON.stringify(data));
    } else {
        request.send();
    }
}


//google sign in
function onGoogleSignIn(googleUser) {
    var profile = googleUser.getBasicProfile();
    var id_token = googleUser.getAuthResponse().id_token;
    document.getElementById('site').style.display = 'none';

    //validate the id token
    U.ajax('POST', '/signin', function(data) {
        if(data.googleId) {
            //all set, save token
            profile.googleId = data.googleId;
            appStore.signedIn(profile);
        } else {
            //no good, sign out
            var auth2 = gapi.auth2.getAuthInstance();
            auth2.signOut();
        }
    }, {token: id_token});
}


//gets a users google avatar
function getGoogleAvatar(index, googleId, callback) {
    gapi.client.load('plus','v1', function() {
        var request = gapi.client.plus.people.get({
            'userId': googleId
        });
        request.execute(function(resp) {
            var img;
            if(resp.image) {
                if(!resp.image.isDefault) {
                    img = resp.image.url.replace('?sz=50', '?sz=100');
                }
            }
            callback(index, img);
        });
    });
}



