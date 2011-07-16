define [
    'library/jquery'
    'library/underscore'
    'library/mustache'
    'cs!library/keydown'
    'cs!library/vector'
    'cs!models'
    'library/sylvester'
    'library/backbone'
], ($, _, mustache, KEYS, Vector, models, sylvester, backbone) ->

    Client = backbone.Model.extend
        initialize: ->
            _.bindAll this, 'run', 'step', 'control_current_player'

            @current_player = null
            @current_place = new models.Place
            @socket = io.connect('http://localhost')
            @players = new models.PlayerCollection
            
            @socket.on 'moved', (data) =>
                player = players.get data.player_id
                if player.id isnt @current_player.id
                    player.set position:$V data.position...

            @socket.on 'player-list', (data) =>
                @players.reset data.player_list
                @current_player = @players.get data.your_id
                @current_place.set players:@players
                for player in @current_place.players.toArray()
                    player.place = @current_place
                    player.client = this

                @current_player.bind 'change:position', (model,position) ->
                    console.log "move", position.elements
                    client.socket.emit 'move', position:position.elements
    
                @run()

            @socket.on 'joined', (data) =>
                unless data.player_id is your_id
                    make_a_player data.player_id, data.position

        run: -> setInterval @step, 10

        step: ->
            @control_current_player()
            
        control_current_player: -> 
            motion = $V 0,0
            for key, vector of motions
                if KEYS[key]
                    motion = motion.add vector
            @current_player.intend_motion motion


    ClientView = backbone.View.extend
        el:$(document.body)
        initialize:
            @current_player_id = null

    window.client = new Client


    $V = sylvester.$V 
    render = mustache.to_html
    your_id = null
    speed = 5
    motions =
        "up": $V(0,-1)
        "down": $V(0,1)
        "left": $V(-1,0)
        "right": $V(1,0)


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
        new Tree($V(200,200))
    ]
    players = {}
    player_views = {}

    place = new Place trees, players


    model_corner = (model) ->
        model.position.minus $V(model.radius, model.radius)

    class PlayerView
        template:"""<div class="player"></div>"""
        constructor: (@model) ->
            @el = $ @template
            $(document.body).append @el

            
        draw: ->
            @el.css model_corner(@model).as_css()


    #make_a_player = (id, position) ->
    #    players[id] = player = new models.Player
    #    player.position.elements = position
    #    player_views[id] = player_view = new PlayerView
    #    player_view.model = player
    #    place.add player_view


    join_template = """<form>Choose a name:<input type="text"><button>Join</button></form>"""
    page_template = """
        <div id="user-card"></div>
        <div id="game">
    """
