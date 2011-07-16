define [
    'cs!library/vector'
    'library/sylvester'
    'library/backbone'
    'library/underscore'
], (Vector, sylvester, backbone, _) ->
    $V = sylvester.$V

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
            unless obstacles or new_position.equals @position
                @set position:new_position
    ,
        parse: (attributes) ->
            attributes['position'] = $V attributes['position']['elements']...
            attributes



    PlayerCollection = backbone.Collection.extend
        model:Player

    Place = backbone.Model.extend
        initialize: ->
            _.bindAll this, 'collide'
            @players = new PlayerCollection

        collide: (player, new_position) ->
            for item in @players.toArray()
                if item.id != player.id and new_position.distance(item.position) < player.radius + item.radius
                    console.log "Stuck"
                    return [item]
            
        



    Player:Player
    PlayerCollection:PlayerCollection
    Place:Place

