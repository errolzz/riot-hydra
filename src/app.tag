
<app>
    <login show={screen == 'login'}></login>
    <lobby if={screen == 'lobby'}></lobby>
    <room if={screen == 'room'}></room>

    <script>
        var self = this
        self.screen = 'login'

        RiotControl.on('screen_changed', function(screen) {
            //show only new screen
            self.screen = screen
            self.update()
        })

        setTimeout(function() {
            RiotControl.trigger('lobby.enter_room', API.rooms[0])
        }, 600)
    </script>
</app>