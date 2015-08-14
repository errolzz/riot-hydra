<login>
    <section class={view}>
        <h1>hydra.fm</h1>

        <div class="first">
            <p>Log in with your google account.</p>
            <div class="g-signin2" data-onsuccess="onGoogleSignIn"></div>
        </div>

        <div class="wizard">
            <p>Welcome {firstname}, enter a username</p>
            <input type="text" placeholder="username" onkeyup={nameChanged} maxlength="12">
            <button onclick={saveName}>Save</button>
            <p class="error" show={error}>{error}</p>
        </div>

        <div class="auth-youtube">
            <p>You must allow hydra.fm to access your YouTube playlists</p>
            <button onclick={authYoutube}>Grant Access</button>
            <p class="error" show={authError}>{authError}</p>
        </div>
    </section>

    <script>
        var self = this
        self.view = 'sign-in'

        RiotControl.on('new_user', function(userInfo) {
            self.firstname = userInfo.firstname
            self.user = userInfo.user
            self.view = 'choose-name'
            self.update()
        })

        RiotControl.on('auth_youtube', function() {
            self.view = 'authorize'
            self.update()
        })

        nameChanged(e) {
            //update username as user types
            self.user.name = e.target.value
        }

        saveName(e) {
            //if long enough name
            if(self.user.name.trim().length > 1) {
                //check if already in use
                U.ajax('GET', '/api/checkname/' + encodeURIComponent(self.user.name.trim()), function(data) {
                    if(!data.name) {
                        //name is valid and available, create user
                        RiotControl.trigger('login.create_user', self.user)
                    } else {
                        //name is not available
                        self.error = 'That username is already in use'
                        self.update();
                    }
                });
            } else {
                //name is not valid
                self.error = 'Username must be at least 2 characters long'
                self.update();
            }
        }
        
        //START HERE - need to set up logic so on page load it shows correct step

        authYoutube(e) {
            //allow app to get/manage users youtube data
            //only called once per user
            var url = 'https://accounts.google.com/o/oauth2/auth'
            url += '?client_id=325125235792-vosk7ah47madtojr3lemn49i631n3n1h.apps.googleusercontent.com'
            url += '&redirect_uri=http://localhost:8000/oauth2callback'
            url += '&response_type=token'
            url += '&scope=https://www.googleapis.com/auth/youtube'

            var win = window.open(url, 'width=500, height=500')

            //listen for the access_token cookie
            var accessTimer = setInterval(function() {
                var c = U.getCookie('access_token');
                if(c) {
                    win.close();
                    if(c == 'no') {
                        self.authError = 'Authorizing didn\'t work... refresh and try again';
                    }
                }
            }, 200);
        }
    </script>
</login>