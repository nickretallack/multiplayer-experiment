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
                @current_place.players.add @players.toArray()
                for player in @current_place.players.toArray()
                    player.place = @current_place
                    player.client = this

                @run()

            @socket.on 'joined', (data) =>
                unless data.id is @current_player.id
                    player = new models.Player models.Player.parse(data)
                    @current_place.players.add player
                    @players.add player
                    @current_player.place = @current_place
                    @current_player.client = this

            @socket.on 'left', (player_id) =>
                player = @players.get player_id
                player.destroy()

            @socket.on 'recognized', (data) =>
                @current_player = new models.Player id:data.player_id
                @current_place.players.add @current_player
                @players.add @current_player
                @current_player.place = @current_place
                @current_player.client = this
                @current_player.bind 'change:position', (model,position) ->
                    client.socket.volatile.emit 'move', position:position.elements
                @trigger 'recognized'

        run: -> 
            @trigger 'run'
            setInterval @step, 10

        step: ->
            @control_current_player() if @current_player
            
        control_current_player: -> 
            motion = $V 0,0
            for key, vector of motions
                if KEYS[key]
                    motion = motion.add vector
            @current_player.intend_motion motion

        login: (credentials) ->
            @socket.emit 'login', credentials

    ClientView = backbone.View.extend
        el:$(document.body)
        template: """
        <nav>
            <label for="name">Name: <input id="name" value="joe"></label>
            <label for="password">Password: <input id="password" value="stuff" type="password"></label>
            <button id="login">Return</button>
            <button id="register">Begin Anew</button>
        </nav>
        <div id="play-area"></div>
        """
        initialize: ->
            _.bindAll this, 'center', 'render', 'set_camera_focus', 'login', 'register'
            @place_view = new PlaceView model:@model.current_place
            $(window).resize @center
            @model.bind 'recognized', =>
                @set_camera_focus @model.current_player

        events:
            "click #login":"login"
            "click #register":"register"

        login: (event) ->
            event.preventDefault()
            name = @$('#name').val()
            password = @$('#password').val()
            if name and password
                @model.login
                    name:name
                    password:password

        register: ->
            @login()

        render: ->
            $(@el).append(@template)
            @place_view.render()
            @$('#play-area').append @place_view.el

        set_camera_focus: (model) ->
            @camera_focus.unbind('change:position', @center) if @camera_focus
            @camera_focus = model
            @camera_focus.bind 'change:position', @center
            @center()

        center: ->
            if @camera_focus
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
            @model.bind 'destroy', =>
                console.log "BYE"
                @remove()

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

