require('@kbrw/node_erlastic').server(function (term, from, number, done) {
    if (term == "hello") return done("reply", "Hello World !");
    if (term == "what") return done("reply", "What what ?");
    if (term[0] == "kbrw") return done("noreply", number + term[1]);
    if (term == "kbrw") return done("reply", number);
    throw new Error("unexpected request")
});