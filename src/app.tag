
<app>
    <login show={screen == 'login'}></login>
    <lobby if={screen == 'lobby'}></lobby>

    <script>
        var self = this
        self.screen = 'login'

        RiotControl.on('screen_changed', function(newScreen) {
            //show only new screen
            self.screen = newScreen
            self.update()
        }) 
    </script>
</app>