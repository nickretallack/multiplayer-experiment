define [
    'library/jquery'
    'library/mustache'
    'cs!library/keydown'
    'cs!library/vector'
    'cs!player'
], ($, mustache, KEYS, Vector, Player) ->
    render = mustache.to_html
    socket = io.connect('http://localhost')
    your_id = null
    speed = 5
    motions =
        "up": new Vector(0,-1)
        "down": new Vector(0,1)
        "left": new Vector(-1,0)
        "right": new Vector(1,0)


    class Place
        constructor: (objects, players) ->
            @players = []
            @objects = []
            for item in objects
                @add_static item
            for item in players
                @add item

        draw_static: ->
            for item in _.values @objects
                item.draw()
        draw: ->
            for item in _.values @players
                item.draw()

        add_static: (item) ->
            @objects.push item
            item.place = this

        add: (item) ->
            @players.push item
            item.place = this

        get_items: ->
            @objects.concat @players

    class Tree
        template:"""<div class="tree"></div>"""
        constructor: (@position) ->
            @radius = 15
            @el = $ @template
            $(document.body).append @el
            @model = this
        draw: ->
            @el.css model_corner(@model).as_css()

    trees = [
        new Tree(new Vector(200,200))
    ]
    players = {}
    player_views = {}

    place = new Place trees, players


    model_corner = (model) ->
        model.position.minus new Vector(model.radius, model.radius)

    class PlayerView
        template:"""<div class="player"></div>"""
        constructor: (@model) ->
            @el = $ @template
            $(document.body).append @el

        control: ->
            motion = new Vector 0,0
            for key, vector of motions
                if KEYS[key]
                    motion = motion.add vector
            new_position = @model.position.add motion.scale(speed)

            for item_view in @place.get_items()
                if item_view != this
                    item = item_view.model
                    if new_position.distance(item.position) < @model.radius + item.radius
                        console.log "Stuck"
                        return
                

            unless new_position.equals @model.position
                socket.emit 'move', position:new_position.components
            
        draw: ->
            @el.css model_corner(@model).as_css()


    socket.on 'moved', (data) ->
        player = players[data.player_id]
        player.position.components = data.position

    make_a_player = (id, position) ->
        players[id] = player = new Player
        player.position.components = position
        player_views[id] = player_view = new PlayerView
        player_view.model = player
        place.add player_view

    socket.on 'player-list', (data) ->
        your_id = data.your_id
        for id, position of data.player_list
            make_a_player id, position

        place.draw_static()

        setInterval (-> 
            player_views[your_id].control()
            place.draw()
        ), 10

    socket.on 'joined', (data) ->
        unless data.player_id is your_id
            make_a_player data.player_id, data.position

    join_template = """<form>Choose a name:<input type="text"><button>Join</button></form>"""
    page_template = """
        <div id="user-card"></div>
        <div id="game">
    """
