define [
    'cs!library/vector'
    'library/sylvester'
], (Vector, sylvester) ->
    $V = sylvester.$V


    class Player
        constructor: ->
            @position = $V 50,50
            @radius = 25

