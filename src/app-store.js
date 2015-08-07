function AppStore() {
    riot.observable(this)

    var self = this;
    self.items = [
        {title: 'tops', done: false},
        {title: 'timmy', done: false},
        {title: 'torment', done: false}
    ];

    self.on('item_add', function(newitem) {
        self.items.push(newitem);
        self.trigger('items_changed', self.items);
    });

    self.on('item_remove', function() {
        //loop through items, remove done ones
        var notDone = [];
        for(var i=0; i<self.items.length; i++) {
            if(!self.items[i].done) notDone.push(self.items[i]);
        }
        self.items = notDone;
        self.trigger('items_changed', self.items);
    });

    self.on('item_init', function() {
        self.trigger('items_changed', self.items);
    });
}