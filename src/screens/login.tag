<login>
    <section class={logged: loggedIn}>
        <h1>hydra.fm</h1>

        <div class="first">
            <p>Log in with your google account.</p>
            <div class="g-signin2" data-onsuccess="onGoogleSignIn"></div>
        </div>

        <div class="wizard">
            <p>Welcome {firstname}, enter a username</p>
            <input type="text" placeholder="username" onkeyup={nameChanged}>
            <button onclick={enter}>Enter</button>

            <p class="error" show={error}>{error}</p>
            <p class="sign-out" onclick={signOut}>Sign Out</p>
        </div>
    </section>

    <script>
        var self = this
        self.loggedIn = false

        RiotControl.on('new_user', function(userInfo) {
            self.firstname = userInfo.firstname
            self.user = userInfo.user
            self.loggedIn = true
            self.update()
        })

        nameChanged(e) {
            self.user.name = e.target.value
        }

        enter(e) {
            //if long enough name
            if(self.user.name.length > 3) {
                //check if already in use
                RiotControl.trigger('login.createNewUser', self.user)
            } else {
                self.error = 'Username must be at least 4 characters long'
            }
        }

        signOut(e) {
            var auth2 = gapi.auth2.getAuthInstance();
            auth2.signOut();
            window.location = '/';
        }
    </script>
</login>