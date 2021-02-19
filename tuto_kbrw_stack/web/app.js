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
var $ = require("jquery");


/* required css for our application */
require('./webflow/css/webflow.css');

var GoTo = (route, params, query) => {
    //var qs = Qs.stringify(query)
    var url = routes[route].path(params) + ((query == '') ? '' : ('?' + query))
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
            url: "/api/order/" + '?id=' + props.order_id,
            prop: "order"
        }
    }
}

//fonction pour affecter ou enlever la classe hidden à notre modal component
var cn = function () {
    var args = arguments, classes = {}
    for (var i in args) {
        var arg = args[i]
        if (!arg) continue
        if ('string' === typeof arg || 'number' === typeof arg) {
            arg.split(" ").filter((c) => c != "").map((c) => {
                classes[c] = true
            })
        } else if ('object' === typeof arg) {
            for (var key in arg) classes[key] = arg[key]
        }
    }
    return Object.keys(classes).map((k) => classes[k] && k || '').join(' ')
}

var Layout = createReactClass(
    {
        // permet d'afficher ou de cacher le component en fonction de notre state
        // this.state va changer l'etat de modal, ici l'att modal
        // spec ici designe le component Orders
        // res le resultat de l'interac
        //  on cache le modal
        // on appel la func callback de spec avec res, ici 

        getInitialState: function () {
            return { modal: this.props.modal };
        },
        modal(spec) {
            this.setState({
                modal: {
                    ...spec, callback: (res) => {
                        this.setState({ modal: null }, () => {
                            if (spec.callback) spec.callback(res)
                        })
                    }
                }
            })
        },
        render() {
            // on recupére notre component DeleteModal et on lui passe
            // this.state.modal.type en props

            // this.modal = la fonction
            // this.state.modal = modal dans la fonction modal
            var modal_component = {
                'delete': (props) => <DeleteModal {...props} />
            }[this.state.modal && this.state.modal.type];
            modal_component = modal_component && modal_component(this.state.modal)

            var props = {
                ...this.props, modal: this.modal
            }


            return <JSXZ in="index" sel=".layout" >
                <Z sel=".layout-container">
                    <this.props.Child {...props} />
                </Z>
                <Z sel=".modal-wrapper" className={cn(classNameZ, { 'hidden': !modal_component })}>
                    {modal_component}
                </Z>
            </JSXZ >
        }
    });


var DeleteModal = createReactClass({
    render() {
        return <JSXZ in="index" sel=".modal-wrapper">
            <Z sel=".field-label-2">
                {this.props.message}
            </Z>
            <Z sel=".confirm-button-yes" onClick={() => { this.props.callback(true) }}>
                Yes
           </Z>
            <Z sel=".confirm-button-no" onClick={() => { this.props.callback(false) }}>
                No
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
            return this.props.orders.value.map((order, index) => (<JSXZ in="index" sel=".table-line" key={index}>
                <Z sel=".order_id" >{order.id}</Z>
                <Z sel=".full_name" >{order.full_name}</Z>
                <Z sel=".billing_adress" >{order.billing_address}</Z>
                <Z sel=".items" >{order.items}</Z>
                <Z sel=".y-button" onClick={() => this.props.modal({
                    type: 'delete',
                    title: 'Order deletion',
                    message: `Are you sure you want to delete this ?`,
                    callback: (value) => {
                        //Do something with the return value
                        if (value) {
                            GoTo("orders", "", "del=" + order.id)
                        } else {
                            GoTo("orders", "")
                        }

                    }
                })}><ChildrenZ /></Z>
                <Z sel=".z-button" onClick={() => GoTo("order", order.id)}><ChildrenZ /></Z>
            </JSXZ>))
        }
    });

//<Z sel=".y-button" onClick={() => GoTo("orders", "", "del=" + order.id)}><ChildrenZ /></Z>


var Order = createReactClass(
    {
        statics: {
            remoteProps: [remoteProps.order]
        },

        render() {
            console.log("this.props : ")
            console.log(this.props)
            return <JSXZ in="order1" sel=".section-4">
                <Z sel=".order_order_id">Order ID : {this.props.order.value.id}</Z>
                <Z sel=".order_full_name">Full Name :{this.props.order.value.full_name}</Z>
                <Z sel=".order_billing_adress">Billing Adress : {this.props.order.value.billing_address}</Z>
                <Z sel=".order_items">Items : {this.props.order.value.items}</Z>
            </JSXZ>
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
            console.log(browserState)
            //Render our components using our remote data
            ReactDOM.render(<Child {...browserState} />, document.getElementById('root'))
        }, (res) => {
            ReactDOM.render(<ErrorPage message={"Shit happened"} code={res.http_code} />, document.getElementById('root'))
        })
}

window.addEventListener("popstate", () => { onPathChange() })
onPathChange()

