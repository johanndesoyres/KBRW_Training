require('!!file-loader?name=[name].[ext]!./webflow/accounts.html')

/* required library for our React app */
var ReactDOM = require('react-dom')
var React = require("react")
var createReactClass = require('create-react-class')
var Qs = require('qs')
var Cookie = require('cookie')
var XMLHttpRequest = require("xhr2")
var When = require('when')
var $ = require("jquery");


/* required css for our application */
require('./webflow/css/webflow.css');


var GoTo = (route, params, query) => {
    var url = routes[route].path(params) + ((query == '') ? '' : ('?' + query))
    history.pushState({}, "", url)
    onPathChange()
}

// remoteProps renvoie un tuple avec l'url qui sera utilisé par l'API et le  nom de la prop à récupérer
var remoteProps = {
    accounts: (props) => {
        var qs = { ...props.qs }
        var query = Qs.stringify(qs)
        var res = ""
        if (query == '') {
            res = "/api/accounts"
        } else if (query.includes("id=") && (query.includes("name=") || query.includes("amt="))) {
            res = "/api/post/account?" + query
        } else if (query.includes("id=")) {
            res = "/api/delete/account?" + query
        }
        return {

            url: res,
            prop: "accounts"
        }
    }
}

var Layout = createReactClass(
    {
        render() {
            return <JSXZ in="accounts" sel=".layout" >
                <Z sel=".layout-container">
                    <this.props.Child {...this.props} />
                </Z>
            </JSXZ >
        }
    });



var Header = createReactClass(
    {
        render() {
            return <JSXZ in="accounts" sel=".header">
                <Z sel=".del-button" value="Delete"><ChildrenZ /></Z>
                <Z sel=".post-button" value="Post"><ChildrenZ /></Z>
                <Z sel=".accounts-content">
                    <this.props.Child {...this.props} />
                </Z>
            </JSXZ>
        }
    });

var Accounts = createReactClass(
    {
        statics: {
            remoteProps: [remoteProps.accounts]
        },

        render() {
            return this.props.accounts.value.map((account, index) => (<JSXZ in="accounts" sel=".accounts-content" key={index}>
                <Z sel=".account_nb" >{account.accnt_nb}</Z>
                <Z sel=".first_name" >{account.first_name}</Z>
                <Z sel=".name" >{account.name}</Z>
                <Z sel=".amount" >{account.amt}</Z>
                <Z sel=".last_update" >{account.last_update}</Z>
            </JSXZ>))
        }
    });

var Child = createReactClass({
    render() {
        var [ChildHandler, ...rest] = this.props.handlerPath
        return <ChildHandler {...this.props} handlerPath={rest} />
    }
})

var ErrorPage = createReactClass({

    render() {
        console.log("ErrorPage")
        console.log(this)
        return <JSXZ in="accounts" sel=".header-container">
            <Z sel=".error">{this.props.message} : {this.props.code}</Z>
        </JSXZ>
    }
})

// L'objet HTTP nous permettra d'envoyer des requêtes à notre serveur
var HTTP = new (function () {
    this.get = (url) => this.req('GET', url)
    this.delete = (url) => this.req('DELETE', url)
    this.post = (url, data) => this.req('POST', url, data)
    this.put = (url, data) => this.req('PUT', url, data)

    this.req = (method, url, data) => new Promise((resolve, reject) => {
        var req = new XMLHttpRequest()
        console.log("URL :")
        console.log(url)
        req.open(method, url)  // initialisation de la requete
        req.responseType = "text"
        req.setRequestHeader("accept", "application/json,*/*;0.8")
        req.setRequestHeader("content-type", "application/json")
        // onload() sera invoqué dés qu'on aura recu une réponse (ex: 200, 300, 404, etc)
        req.onload = () => {
            console.log("req.responseText")
            console.log(req.responseText)
            if (req.status >= 200 && req.status < 300) {
                resolve(req.responseText && JSON.parse(req.responseText))
            } else {
                reject({ http_code: req.status })
            }
        }
        // on error sera invoqué dés qu'il y aura une erreur du serveur (ex : coupure réseau, etc)
        req.onerror = (err) => {
            reject({ http_code: req.status })
        }
        req.send(data && JSON.stringify(data)) // on envoie la requête, ici on met "data &&" pour empeché d'appeler JSON.stringify avec data = null
    })
})()


var routes = {
    "accounts": {
        path: (params) => {
            return "/";
        },
        match: (path, qs) => {
            return (path == "/") && { handlerPath: [Layout, Header, Accounts] }
        }
    }
}

var browserState = { Child: Child }

// props = browser state
// specs = éléments de remoteProps
function addRemoteProps(props) {
    return new Promise((resolve, reject) => {
        //Here we could call `[].concat.apply` instead of `Array.prototype.concat.apply`
        //apply first parameter define the `this` of the concat function called
        //Ex [0,1,2].concat([3,4],[5,6])-> [0,1,2,3,4,5,6]
        // <=> Array.prototype.concat.apply([0,1,2],[[3,4],[5,6]])
        //Also `var list = [1,2,3]` <=> `var list = new Array(1,2,3)`

        // On va rempacer les props dans handlerPath par les remote props
        var remoteProps = Array.prototype.concat.apply([],
            props.handlerPath
                .map((c) => c.remoteProps) // -> [[remoteProps.user], [remoteProps.orders], null]
                .filter((p) => p) // -> [[remoteProps.user], [remoteProps.orders]]
        )

        var remoteProps = remoteProps
            .map((spec_fun) => spec_fun(props)) // -> 1st call [{url: '/api/me', prop: 'user'}, undefined]
            // -> 2nd call [{url: '/api/me', prop: 'user'}, {url: '/api/orders?user_id=123', prop: 'orders'}]
            .filter((specs) => specs) // get rid of undefined from remoteProps that don't match their dependencies
            .filter((specs) => !props[specs.prop] || props[specs.prop].url != specs.url) // get rid of remoteProps already resolved with the url
        if (remoteProps.length == 0)
            return resolve(props)


        // https://github.com/cujojs/when/blob/master/docs/api.md#whenmap 
        // When.map permet de mettre la serie d'operation de la fonction map dans une Promise

        // Promise va contenir les resultats de toutes les requetes 
        var promise = When.map( // Returns a Promise that either on a list of resolved remoteProps, or on the rejected value by the first fetch who failed 
            remoteProps.map((spec) => { // Returns a list of Promises that resolve on list of resolved remoteProps ([{url: '/api/me', value: {name: 'Guillaume'}, prop: 'user'}])
                return HTTP.get(spec.url)
                    .then((result) => { spec.value = result; return spec }) // we want to keep the url in the value resolved by the promise here. spec = {url: '/api/me', value: {name: 'Guillaume'}, prop: 'user'} 
            })
        )

        // https://github.com/cujojs/when/blob/master/docs/api.md#whenreduce

        //
        When.reduce(promise, (acc, spec) => { // {url: '/api/me', value: {name: 'Guillaume'}, prop: 'user'}
            acc[spec.prop] = { url: spec.url, value: spec.value }
            return acc
        }, props).then((newProps) => {
            addRemoteProps(newProps).then(resolve, reject)
        }, reject)

    })
}


function onPathChange() {  // fuonction qui va retourner les components à afficher pour le path courant

    var path = location.pathname
    var qs = Qs.parse(location.search.slice(1))
    var cookies = Cookie.parse(document.cookie)
    browserState = {
        ...browserState, // Recupere les données de l'objet browser state
        path: path,
        qs: qs,
        cookie: cookies
    }
    var route, routeProps
    //We try to match the requested path to one our our routes
    for (var key in routes) {
        routeProps = routes[key].match(path, qs) // Components à afficher
        if (routeProps) {
            route = key  // Path
            break;
        }
    }
    browserState = {     // on remplit le browser state avec nos données
        ...browserState,
        ...routeProps,
        route: route
    }
    //If we don't have a match, we render an Error component
    if (!route)
        return ReactDOM.render(<ErrorPage message={"Not Found"} code={404} />, document.getElementById('root'))

    addRemoteProps(browserState).then(
        (props) => {
            browserState = props
            //Log our new browserState
            console.log("browser state :")
            console.log(browserState)
            //Render our components using our remote data
            ReactDOM.render(<Child {...browserState} />, document.getElementById('root'))
        }, (res) => {
            ReactDOM.render(<ErrorPage message={"Shit happened"} code={res.http_code} />, document.getElementById('root'))
        })
}

window.addEventListener("popstate", () => { onPathChange() })
onPathChange()

