define [
    'models'
    'pg'
    './library/flow'
], (models, pg, Flow) ->
    db = null

    start_place_id = '3ee0ebcb-dcb7-48e3-b07f-284e3f0da12f'

    set_client = (your_client) ->
        db = your_client

    handle_errors = (success, failure) ->
        (error, result) ->
            if error
                db.query 'rollback'
                console.log "DATABASE ERROR: #{JSON.stringify(error)}"
                failure error if failure
            else
                success result
            
    db_query = (one, two, three, four) ->
        if typeof two is 'function'
            two = handle_errors two, three
        else
            three = handle_errors three, four
        db.query one, two, three

    create_player = (name, password, callback, fail) ->
        try
            Flow().par(generate_uuid).par(generate_uuid).seq (next, results) ->
                [person_id, character_id] = results
                character = new models.Player
                    name:name
                    id:character_id
                    place_id:start_place_id
                    person_id:person_id
                Flow().seq (next) -> 
                    db.query 'begin', next
                .seq (next) ->
                    db.query """insert into person (id, name) values ($1, $2)""", 
                                [person_id, name], handle_errors next, fail
                .seq (next) -> 
                    console.log "ADDING CREDENTIALS"
                    db.query """insert into credentials (id, login, password_hash, person_id) 
                                values (uuid_generate_v4(), $1, crypt($2, gen_salt('bf')), $3)""",
                                [name, password, person_id], handle_errors next, fail
                .seq (next) ->
                    console.log "ADDING CHARACTER"
                    db.query """insert into character (id, name, person_id, place_id, data) 
                                values ($1, $2, $3, $4, $5)""", 
                                [character.id, character.name, person_id, character.place_id, JSON.stringify(character)], handle_errors next, fail
                .seq (next) ->
                    console.log "ENDING TRANSACTION"
                    db.query 'end', callback(character)
        catch error
            console.log "Recovering from", JSON.stringify error
            callback null

    authenticate = (name, password, callback) ->
        console.log "LOGGING IN AS", name, password
        db.query """select person.* from person 
                    join credentials on person.id = credentials.person_id
                    where credentials.login = $1 and credentials.password_hash = crypt($2, credentials.password_hash)""",
                    [name, password], handle_errors (result) ->
                        console.log "RESULT IS", JSON.stringify result
                        if result.rows.length
                            player = new models.Player result.rows[0]
                        else
                            player = null
                        callback player

    generate_uuid = (next) ->
        db.query 'select uuid_generate_v4() as uuid', handle_errors (result) ->
            next result.rows[0].uuid
        
    set_client:set_client
    generate_uuid:generate_uuid
    create_player:create_player
    authenticate:authenticate
