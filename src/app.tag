
<app>
    <login show={screen == 'login'}></login>
    <lobby if={screen == 'lobby'}></lobby>
    <room if={screen == 'room'}></room>

    <script>
        var self = this
        self.screen = 'lobby'

        RiotControl.on('screen_changed', function(screenData) {
            //show only new screen
            self.screen = screenData.screen
            self.update()
        }) 
    </script>
</app>