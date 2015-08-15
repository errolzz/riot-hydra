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
            <button onclick={saveName}>Create</button>
            <p class="error" show={error}>{error}</p>
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
                        //name is valid and available, show youtube auth
                        RiotControl.trigger('login.create_user', self.user)
                    } else {
                        //name is not available
                        self.error = 'That username is already in use'
                    }
                    self.update()
                });
            } else {
                //name is not valid
                self.error = 'Username must be at least 2 characters long'
                self.update();
            }
        }
    </script>
</login>