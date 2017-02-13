-module(hello_handler).
-behavior(cowboy_handler).

-export([init/2]).

init(Req, State) ->
    Resp = cowboy_req:reply(200,
        #{<<"content-type">> => <<"text/plain">>},
        <<"Hello, world!">>,
        Req),
    {ok, Resp, State}.
