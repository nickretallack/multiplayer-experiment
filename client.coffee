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
    $V = sylvester.$V 
    render = mustache.to_html
    motions =
        "up": $V(0,-1)
        "down": $V(0,1)
        "left": $V(-1,0)
        "right": $V(1,0)

    model_corner = (model) ->
        model.position.minus $V(model.radius, model.radius)

    home = new models.Place
    home.obstacles.add [
        {position: $V(200,200)},
        {position: $V(300,200)}
    ]


    Client = backbone.Model.extend
        initialize: ->
            _.bindAll this, 'run', 'step', 'control_current_player'

            @current_player = null
            @current_place = home
            @socket = io.connect('http://localhost')
            @players = new models.PlayerCollection
            
            @socket.on 'moved', (data) =>
                unless data.player_id is @current_player.id
                    player = @players.get data.player_id
                    player.set position:$V data.position...

            @socket.on 'player-list', (data) =>
                @players.add data.player_list
                @current_player = @players.get data.your_id
                @current_place.players.add @players.toArray()
                for player in @current_place.players.toArray()
                    player.place = @current_place
                    player.client = this

                @current_player.bind 'change:position', (model,position) ->
                    client.socket.emit 'move', position:position.elements
    
                @run()

            @socket.on 'joined', (data) =>
                unless data.id is @current_player.id
                    player = new models.Player models.Player.parse(data)
                    @current_place.players.add player
                    @players.add player

        run: -> 
            @trigger 'run'
            setInterval @step, 10

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
        initialize: ->
            _.bindAll this, 'center', 'render'
            @place_view = new PlaceView model:@model.current_place
            @model.bind 'run', =>
                @model.current_player.bind 'change:position', @center
                @center()
            $(window).resize @center

        render: ->
            @place_view.render()
            $(document.body).append @place_view.el

        center: ->
            window_size = $V $(document.body).innerWidth(), $(document.body).innerHeight()
            corner = @model.current_player.position.scale(-1)
            center = window_size.scale(0.5)
            $(@place_view.el).css center.plus(corner).as_css()
                

    PlaceView = backbone.View.extend
        className:'place'
        initialize: ->
            for obstacle in @model.obstacles.toArray()
                obstacle_view = new ObstacleView model:obstacle
                obstacle_view.render()
                $(@el).append obstacle_view.el

            @model.players.bind 'add', (player) =>
                player_view = new PlayerView model:player
                player_view.render()
                $(@el).append player_view.el

    PlayerView = backbone.View.extend
        className:'player'
        initialize: ->
            _.bindAll this, 'update_position'
            @update_position()
            @model.bind 'change:position', @update_position

        update_position: ->
            $(@el).css model_corner(@model).as_css()
            
        render: ->

    ObstacleView = backbone.View.extend
        className:'tree'
        render: ->
            $(@el).css model_corner(@model).as_css()

    client = new Client
    view = new ClientView model:client
    view.render()

