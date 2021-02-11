module.exports = function ({ types: t }) {
    return {
        visitor: {
            ExpressionStatement(path) {
                expression = path.node.expression;
                if (t.isJSXElement(expression)) {

                    open_elem = expression.openingElement
                    if (open_elem.name.name !== "Declaration") {
                        return;
                    }
                    attributes = expression.openingElement.attributes
                    if (attributes.length !== 2) {
                        return;
                    }

                    val = t.nullLiteral() // Initialize value
                    var_name = attributes[0].value.value // Get var name
                    var_word = attributes[0].name.name // Get var

                    if (attributes[1].value.value !== undefined) {
                        val = t.stringLiteral(attributes[1].value.value) // Get the value and parse it to a string
                    }

                    else if (attributes[1].value.expression.value !== undefined) {
                        val = t.numericLiteral(attributes[1].value.expression.value) // Get the value and parse it to a numeric
                    }

                    // Write the final expr : ident var_name = value
                    path.replaceWith(t.variableDeclaration(var_word, [t.variableDeclarator(t.identifier(var_name), val)]));
                }
            },
        }
    };
}