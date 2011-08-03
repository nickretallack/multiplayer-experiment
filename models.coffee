define [
    'cs!library/vector'
    'library/sylvester'
    'library/backbone'
    'library/underscore'
], (Vector, sylvester, backbone, _) ->
    $V = sylvester.$V

    Obstacle = backbone.Model.extend
        initialize: ->
        defaults:
            position: $V 100,100
            radius:15
        toJSON: ->
            json = backbone.Model::toJSON.apply(this)
            json.position = json.position.elements
            json

    Player = backbone.Model.extend
        initialize: ->
            _.bindAll this, 'intend_motion'
        defaults:
            position: $V 50,50
            radius: 25
            speed: 5
        intend_motion: (motion) ->
            new_position = @position.add motion.scale(@speed)
            obstacles = @place.collide this, new_position
            unless obstacles.length or new_position.equals @position
                @set position:new_position
        toJSON: ->
            json = backbone.Model::toJSON.apply(this)
            json.position = json.position.elements
            json
    
    parse_it = (attributes) ->
        attributes['position'] = $V attributes['position']...
        attributes

    PlayerCollection = backbone.Collection.extend
        model:Player

    ObstacleCollection = backbone.Collection.extend
        model:Obstacle

    Place = backbone.Model.extend
        initialize: ->
            _.bindAll this, 'collide'
            @players = new PlayerCollection
            @obstacles = new ObstacleCollection

        collide: (player, new_position) ->
            hits = []
            for item in @obstacles.toArray()
                if item.id != player.id and new_position.distance(item.position) < player.radius + item.radius
                    hits.push item
            return hits
            
        
    Player:Player
    PlayerCollection:PlayerCollection
    Place:Place
    Obstacle:Obstacle
    ObstacleCollection:ObstacleCollection
    parse_it:parse_it

