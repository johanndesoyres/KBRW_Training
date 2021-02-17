require('!!file-loader?name=[name].[ext]!./webflow/index.html')
require('!!file-loader?name=[name].[ext]!./webflow/order1.html')

/* required library for our React app */
var ReactDOM = require('react-dom')
var React = require("react")
var createReactClass = require('create-react-class')
var Qs = require('qs')
var Cookie = require('cookie')
var XMLHttpRequest = require("xhr2")
var When = require('when')


/* required css for our application */
require('./webflow/css/webflow.css');


/* var orders = [
    { remoteid: "000000189", custom: { customer: { full_name: "TOTO & CIE" }, billing_address: "Some where in the world" }, items: 2 },
    { remoteid: "000000190", custom: { customer: { full_name: "Looney Toons" }, billing_address: "The Warner Bros Company" }, items: 3 },
    { remoteid: "000000191", custom: { customer: { full_name: "Asterix & Obelix" }, billing_address: "Armorique" }, items: 29 },
    { remoteid: "000000192", custom: { customer: { full_name: "Lucky Luke" }, billing_address: "A Cowboy doesn't have an address. Sorry" }, items: 0 },
] */

var GoTo = (route, params, query) => {
    var qs = Qs.stringify(query)
    var url = routes[route].path(params) + ((qs == '') ? '' : ('?' + qs))
    history.pushState({}, "", url)
    onPathChange()
}

// remoteProps renvoie un tuple avec l'url qui sera utilisé par l'API et le  nom de la prop à récupérer
var remoteProps = {
    /*user: (props) => {
        return {
            url: "/api/me",
            prop: "user"
        }
    },*/
    orders: (props) => {
        //if (!props.user)
        //return
        var qs = { ...props.qs/*, user_id: props.user.value.id*/ }
        var query = Qs.stringify(qs)
        return {
            url: "/api/orders" + (query == '' ? '' : '?' + query),
            prop: "orders"
        }
    },
    order: (props) => {
        return {
            url: "/api/order/" + props.order_id,
            prop: "order"
        }
    }
}

var Layout = createReactClass({
    render() {
        return <JSXZ in="index" sel=".layout">
            <Z sel=".layout-container">
                <this.props.Child {...this.props} />
            </Z>
        </JSXZ>
    }
})

var Header = createReactClass(
    {
        render() {
            return <JSXZ in="index" sel=".header">
                <Z sel=".header-container">
                    <this.props.Child {...this.props} />
                </Z>
            </JSXZ>
        }
    });

var Orders = createReactClass(
    {
        statics: {
            remoteProps: [remoteProps.orders]
        },

        render() {
            console.log("this.props : ")
            console.log(this.props)
            return this.props.orders.value.map((order, index) => (<JSXZ in="index" sel=".table-line" key={index}>
                <Z sel=".order_id">{order.id}</Z>
                <Z sel=".full_name">{order.full_name}</Z>
                <Z sel=".billing_adress">{order.billing_address}</Z>
                <Z sel=".items">{order.items}</Z>
            </JSXZ>))
        }
    });

var Order = createReactClass(
    {
        render() {
            // TO DO
            return /*<JSXZ in="order1" sel=".order">
                <Z sel=".order-details">
                    
                </Z>
            </JSXZ>*/
        }
    });


// L'objet HTTP nous permettra d'envoyer des requêtes à notre serveur
var HTTP = new (function () {
    this.get = (url) => this.req('GET', url)
    this.delete = (url) => this.req('DELETE', url)
    this.post = (url, data) => this.req('POST', url, data)
    this.put = (url, data) => this.req('PUT', url, data)

    this.req = (method, url, data) => new Promise((resolve, reject) => {
        var req = new XMLHttpRequest()
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
    "orders": {
        path: (params) => {
            return "/";
        },
        match: (path, qs) => {
            return (path == "/") && { handlerPath: [Layout, Header, Orders] }
        }
    },
    "order": {
        path: (params) => {
            return "/order/" + params;
        },
        match: (path, qs) => {
            var r = new RegExp("/order/([^/]*)$").exec(path)
            return r && { handlerPath: [Layout, Header, Order], order_id: r[1] }
        }
    }
}

class Router {
    static match(path, qs) {
        if (path === "/") {
            return ["orders", (path == "/") && { handlerPath: [Layout, Header, Orders] }]
        }
        else if (path.includes("/order/")) {
            var r = new RegExp("/order/([^/]*)$").exec(path)
            return ["order", r && { handlerPath: [Layout, Header, Order], order_id: r[1] }]
        }
        else {
            return null
        }
    }

}

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
        return <JSXZ in="index" sel=".section">
            <Z sel=".error">{this.props.message} : {this.props.code}</Z>
        </JSXZ>
    }
})

var browserState = { Child: Child }

class Renderer {
    static render(browserState) {

        var path = location.pathname
        var qs = Qs.parse(location.search.slice(1))
        var cookies = Cookie.parse(document.cookie)
        browserState = {
            ...browserState, // Recupere les données de l'objet browser state
            path: path,
            qs: qs,
            cookie: cookies
        }

        const result = Router.match(browserState.path, browserState.qs) // on récupére la route et les components à afficher

        if (!result) {
            this.renderError({ message: "Not Found", code: 404 })
            return
        }

        let routeName = result[0] // route (ex : orders)
        let routeProps = result[1] // components à afficher

        browserState = {
            ...browserState,
            ...routeProps,
            route: routeName
        }

        console.log("browser state")
        console.log(browserState)

        this.addRemoteProps(browserState).then(
            (browserState) => {
                ReactDOM.render(<Child {...browserState} />, document.getElementById('root'))
            },
            (error) => { error.message = "Shit happened"; this.renderError(error) }
        );
    }

    static renderError(error) {
        console.log(error)
        let status_code = error.code.toString()
        ReactDOM.render(<ErrorPage message={error.message} code={status_code} />, document.getElementById('root'))
    }


    // props = browser state
    // specs = éléments de remoteProps

    static async addRemoteProps(props) {
        let remoteProps = this.listUnresolvedRemoteProps(props) // liste des remoteProps à charger
        while (remoteProps.length > 0) {
            let resolvedProps = remoteProps.map(async spec => { // liste des ressources renvoyées par l'API (chaque ressurce correspond à une remoteProp)
                return { [spec.prop]: { url: spec.url, value: await HTTP.get(spec.url) } }
            });
            props = await Promise.all(resolvedProps).then(resolvedProps => Object.assign(props, ...resolvedProps)); // remplacement des props par les nouvelles
            remoteProps = this.listUnresolvedRemoteProps(props)
        }
        return props; // on renvoie toutes les props, ce qui correspond au browser state
    }

    // Permet d'enlever les remoteProps qui ont deja été chargées de la liste
    static listUnresolvedRemoteProps(props) {
        return props.handlerPath
            .map(component => component.remoteProps) // -> [[remoteProps.user], [remoteProps.orders], null]
            .filter(x => x) // -> [[remoteProps.user], [remoteProps.orders]]
            .flat(Infinity)
            .map(spec_fun => spec_fun(props)) // -> 1st call [{url: '/api/me', prop: 'user'}, undefined]
            .filter(x => x) // get rid of undefined from remoteProps that don't match their dependencies
            .filter(specs => !props[specs.prop] || props[specs.prop].url != specs.url) // get rid of remoteProps already resolved with the url
    }
}

window.addEventListener("popstate", () => { Renderer.render(browserState) })
Renderer.render(browserState)

