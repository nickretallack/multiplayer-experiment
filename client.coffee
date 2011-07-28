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
            @socket = io.connect('/')
            @players = new models.PlayerCollection

            @socket.on 'moved', (data) =>
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
                player = new models.Player models.Player.parse(data)
                @current_place.players.add player
                @players.add player
                player.place = @current_place
                player.client = this

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
                    client.socket.emit 'move', position:position.elements
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

        login: (credentials, success, failure) ->
            @socket.emit 'login', credentials, (response) ->
                if response.type is 'success'
                    success()
                else
                    failure(response.message)

        register: (credentials, success, failure) ->
            @socket.emit 'register', credentials, (response) ->
                if response.type is 'success'
                    success()
                else
                    failure(response.message)

    LoginPanel = backbone.View.extend
        template: """
            <h1>Some Game!</h1>
            <p>Choose a name and password to start.</p>
            <label for="name">Name: 
                <input id="name" value="joe"></label>
            <label for="password">Password: 
                <input id="password" value="stuff" type="password"></label>
            <button id="register">I'm New</button>
            <button id="login">Remember Me!</button>
            <p id="message"></p>
        """

        events:
            "click #login":"login"
            "click #register":"register"

        initialize: ->
            _.bindAll this, 'login', 'register', 'process_login_form', 'respond'

        render: ->
            $(@el).append(@template)
            @delegateEvents()

        process_login_form: ->
            name = @$('#name').val()
            password = @$('#password').val()
            if not (name and password)
                @respond "Please enter both a name and a password"
            [name,password]

        respond: (message) ->
            @$('#message').text message

        login: (event) ->
            event.preventDefault()
            [name, password] = @process_login_form()
            if name and password
                @model.login
                    name:name
                    password:password
                , (=> @respond "Logged in as #{name}!")
                , ((message) => @respond message)
       

        register: ->
            event.preventDefault()
            [name, password] = @process_login_form()
            if name and password
                @model.register
                    name:name
                    password:password
                , (=> @respond "Registered as #{name}")
                , ((message) => @respond message)


    ClientView = backbone.View.extend
        el:$(document.body)
        template: """
        <nav id="login-panel">
        </nav>
        <div id="play-area"></div>
        """

        initialize: ->
            _.bindAll this, 'center_camera', 'render', 'set_camera_focus'
            @place_view = new PlaceView model:@model.current_place
            @login_panel = new LoginPanel model:@model
            @model.bind 'recognized', =>
                @set_camera_focus @model.current_player
            $(window).resize @center_camera # should this be here?

        render: ->
            $(@el).append(@template)
            @login_panel.el = @$('#login-panel')
            @login_panel.render()
            @place_view.render()
            @play_area = @$('#play-area')
            @play_area.append @place_view.el

        set_camera_focus: (model) ->
            @camera_focus.unbind('change:position', @center_camera) if @camera_focus
            @camera_focus = model
            @camera_focus.bind 'change:position', @center_camera
            @center_camera()

        center_camera: ->
            if @camera_focus
                window_size = $V @play_area.innerWidth(), @play_area.innerHeight()
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

