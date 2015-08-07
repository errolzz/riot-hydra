<ball>

    <h3>{ opts.title }</h3>
    
    <button disabled={ !items.length } onclick={ remove }>Remove Completed</button>

    <ul>
        <li each={ items }>
            <label class={ completed: done }>
                <input type="checkbox" checked={ done } onclick={ parent.toggle }> { title }
            </label>
        </li>
    </ul>

    <div>
        <input name="input" onkeyup={ edit }>
        <button disabled={ !text } type="button" onclick={add}>Add #{ items.length + 1 }</button>
    </div>
    
    <script>
        var self = this
        self.disabled = true
        self.items = []

        self.on('mount', function() {
            // Trigger init event when component is mounted to page.
            // Any store could respond to this.
            RiotControl.trigger('item_init')
        })  

        // Register a listener for store change events.
        RiotControl.on('items_changed', function(items) {
            self.items = items
            self.update()
        }) 

        edit(e) {
            self.text = e.target.value
        }

        add(e) {
            if (self.text) {
                // Trigger event to all stores registered in central dispatch.
                // This allows loosely coupled stores/components to react to same events.
                RiotControl.trigger('item_add', { title: self.text })
                self.text = self.input.value = ''
            }
        }

        toggle(e) {
            var item = e.item
            item.done = !item.done
            //return true //?
        }

        remove(e) {
            RiotControl.trigger('item_remove')
        }
    </script>

</ball>