
<app>
    <login show={screen == 'login'}></login>
    <lobby if={screen == 'lobby'}></lobby>
    <room if={screen == 'room'}></room>

    <script>
        var self = this

        self.on('mount', function() {
            self.screen = 'login'
            self.update()
            RiotControl.trigger('app.app_mounted')
        })

        RiotControl.on('screen_changed', function(screen) {
            //show only new screen
            self.screen = screen
            self.update()
        })
    </script>
</app>