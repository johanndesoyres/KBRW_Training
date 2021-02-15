require('!!file-loader?name=[name].[ext]!./webflow/orders.html')
require('!!file-loader?name=[name].[ext]!./webflow/order1.html')

/* required library for our React app */
var ReactDOM = require('react-dom')
var React = require("react")
var createReactClass = require('create-react-class')

/* required css for our application */
require('./webflow/css/webflow.css');
require('./webflow/css/varela.css');


var orders = [
    { remoteid: "000000189", custom: { customer: { full_name: "TOTO & CIE" }, billing_address: "Some where in the world" }, items: 2 },
    { remoteid: "000000190", custom: { customer: { full_name: "Looney Toons" }, billing_address: "The Warner Bros Company" }, items: 3 },
    { remoteid: "000000191", custom: { customer: { full_name: "Asterix & Obelix" }, billing_address: "Armorique" }, items: 29 },
    { remoteid: "000000192", custom: { customer: { full_name: "Lucky Luke" }, billing_address: "A Cowboy doesn't have an address. Sorry" }, items: 0 },
]

//To render this JSON in the table, we will have to map the list on a **`JSXZ`** render. 


var Page = createReactClass({
    render() {
        return orders.map(order => (
            < JSXZ in="orders" sel=".container" >
                <Z sel=".text-block-a">{order.remoteid}</Z>
                <Z sel=".text-block-b">{order.custom.customer.full_name}</Z>
                <Z sel=".text-block-c">{order.custom.billing_address}</Z>
                <Z sel=".text-block-d">{order.items}</Z>
            </JSXZ >
        ))
    }
})

ReactDOM.render(
    <Page />,
    document.getElementById("root")
)