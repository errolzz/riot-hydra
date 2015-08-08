<login class={logged: loggedIn}>
    <h1>hydra.fm</h1>

    <div class="first">
        <p>Login with your google account.</p>
        <button onclick={login}>Google Login</button>
    </div>

    <div class="wizard">
        <p>Welcom Errol</p>
        <p>Choose a username</p>
        <input type="text" placeholder="username" onkeyup={nameChanged}>
        <button onclick={enter}>Enter</button>

        <p show={error}>{error}</p>
    </div>

    <script>
        var self = this
        self.loggedIn = false
        self.username = ''

        login(e) {
            //do some google shit
            //on complete
            self.loggedIn = true
        }

        nameChanged(e) {
            self.username = e.target.value
        }

        enter(e) {
            //if long enough name
            if(self.username.length > 3) {
                //check if already in use
                RiotControl.trigger('login.enter')
            } else {
                self.error = 'Username must be at least 4 characters.'
            }
        }
    </script>
</login>