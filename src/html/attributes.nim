import macros, strutils
import ../selector, vdom

{.push hint[ConvFromXtoItselfNotNeeded]: off.}
macro attributeModifier(field: untyped, defaultVal: untyped): untyped =
    let fieldStr = newStrLitNode(field.strVal)
    let val = ident("val")
    result = quote do:
        proc `field`*(`val` = `defaultVal`): NodeModifier =
            result = proc (node: VNode) =
                node.setAttr(`fieldStr`, $`val`)

proc attr*(field, val: string): NodeModifier =
    result = proc (node: VNode) =
        node.setAttr(field, val)

proc id*(val: Selector): NodeModifier =
    result = proc (node: VNode) =
        node.setAttr("id", val.name)

proc class*(selector: Selector, classes: openArray[string]): NodeModifier =
    result = proc (node: VNode) =
        let val = selector.name & " " & classes.join(" ")
        node.setAttr("class", val)

proc class*(classes: openArray[string]): NodeModifier =
    result = proc (node: VNode) =
        let val = classes.join(" ")
        node.setAttr("class", val)

proc forAttr*(val: Selector): NodeModifier =
    result = proc (node: VNode) =
        node.setAttr("for", val.name)

proc elType*(val: string): NodeModifier =
    result = proc (node: VNode) =
        node.setAttr("type", val)

proc ownerForm*(val: Selector): NodeModifier =
    result = proc (node: VNode) =
        node.setAttr("form", val.name)

proc contextmenu*(val: Selector): NodeModifier =
    result = proc (node: VNode) =
        node.setAttr("contextmenu", val.name)

proc datalist*(val: Selector): NodeModifier =
    result = proc (node: VNode) =
        node.setAttr("list", val.name)

proc maxAttr*(val: string | int): NodeModifier =
    result = proc (node: VNode) =
        node.setAttr("max", $val)

proc minAttr*(val: string | int): NodeModifier =
    result = proc (node: VNode) =
        node.setAttr("min", $val)

attributeModifier(id, "")
attributeModifier(class, "")
attributeModifier(name, "")
attributeModifier(href, "")
attributeModifier(src, "")
attributeModifier(rel, "")
attributeModifier(style, "")
attributeModifier(title, "")
attributeModifier(requried, true)
attributeModifier(readonly, true)
attributeModifier(disabled, true)
attributeModifier(hidden, true)
attributeModifier(pattern, "")
attributeModifier(placeholder, "")
attributeModifier(maxlength, 0)
attributeModifier(minlength, 0)
attributeModifier(value, "")
attributeModifier(alt, "")
attributeModifier(autocapitalize, true)
attributeModifier(autocomplete, true)
attributeModifier(autofocus, true)
attributeModifier(checked, true)
attributeModifier(contenteditable, true)
attributeModifier(download, true)
attributeModifier(draggable, true)
attributeModifier(enctype, "")
attributeModifier(open, true)
attributeModifier(reversed, true)
attributeModifier(selected, true)
attributeModifier(spellcheck, true)
attributeModifier(step, 0)
attributeModifier(wrap, true)

# TODO: ARIA roles
{.pop.}