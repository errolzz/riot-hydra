<login>
    <section class={logged: loggedIn}>
        <h1>hydra.fm</h1>

        <div class="first">
            <p>Log in with your google account.</p>
            <button onclick={login}>Google Login</button>
        </div>

        <div class="wizard">
            <p>Welcom Errol, enter a username</p>
            <input type="text" placeholder="username" onkeyup={nameChanged}>
            <button onclick={enter}>Enter</button>

            <p class="error" show={error}>{error}</p>
        </div>
    </section>

    <script>
        var self = this
        self.loggedIn = false
        self.user = {
            id: '023942', //authed token
            name: ''
        }

        login(e) {
            //do some google shit
            //on complete
            self.loggedIn = true
        }

        nameChanged(e) {
            self.user.name = e.target.value
        }

        enter(e) {
            //if long enough name
            //if(self.username.length > 3) {
                //check if already in use
                RiotControl.trigger('login.enter', self.user)
            /*} else {
                self.error = 'Username must be at least 4 characters long'
            }*/
        }
    </script>
</login>