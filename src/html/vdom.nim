import macros
from strutils import toUpperAscii, toLowerAscii, tokenize

{.push hint[ConvFromXtoItselfNotNeeded]: off.}
type
    Event* = ref object

type
  VNodeKind* {.pure.} = enum
    vtext, int = "#int", bool = "#bool", verbatim = "#verbatim",

    html, head, title, base, link, meta, style,
    script, noscript,
    body, section, nav, article, aside,
    h1, h2, h3, h4, h5, h6, hgroup,
    header, footer, address, main,

    p, hr, pre, blockquote, ol, ul, li,
    dl, dt, dd,
    figure, figcaption,

    vdiv = "div",

    a, em, strong, small,
    strikethrough = "s", cite, quote,
    dfn, abbr, data, time, code, vvar = "var", samp,
    kdb, sub, sup, italic = "i", bold = "b", underlined = "u",
    mark, ruby, rt, rp, bdi, dbo, span, br, wbr,
    ins, del, img, iframe, embed, vobject = "object",
    param, video, audio, source, track, canvas, map, area,

    # SVG elements, see: https://www.w3.org/TR/SVG2/eltindex.html
    animate, animateMotion, animateTransform, circle, clipPath, defs, desc,
    vdiscard = "discard", ellipse, feBlend, feColorMatrix, feComponentTransfer,
    feComposite, feConvolveMatrix, feDiffuseLighting, feDisplacementMap,
    feDistantLight, feDropShadow, feFlood, feFuncA, feFuncB, feFuncG, feFuncR,
    feGaussianBlur, feImage, feMerge, feMergeNode, feMorphology, feOffset,
    fePointLight, feSpecularLighting, feSpotLight, feTile, feTurbulence,
    filter, foreignObject, g, image, line, linearGradient, marker, mask,
    metadata, mpath, path, pattern, polygon, polyline, radialGradient, rect,
    vset = "set", stop, svg, switch, symbol, text, textPath, tspan,
    unknown, use, view,

    # MathML elements
    maction, math, menclose, merror, mfenced, mfrac, mglyph, mi, mlabeledtr,
    mmultiscripts, mn, mo, mover, mpadded, mphantom, mroot, mrow, ms, mspace,
    msqrt, mstyle, msub, msubsup, msup, mtable, mtd, mtext, mtr, munder,
    munderover, semantics,

    table, caption, colgroup, col, tbody, thead,
    tfoot, tr, td, th,

    form, fieldset, legend, label, input, button,
    select, datalist, optgroup, option, textarea,
    keygen, output, progress, meter,
    details, summary, command, menu

const
  selfClosing = {area, base, br, col, embed, hr, img, input,
    link, meta, param, source, track, wbr}

type
  EventKind* {.pure.} = enum ## The events supported by the virtual DOM.
    onclick, ## An element is clicked.
    oncontextmenu, ## An element is right-clicked.
    ondblclick, ## An element is double clicked.
    onkeyup, ## A key was released.
    onkeydown, ## A key is pressed.
    onkeypressed, ## A key was pressed.
    onfocus, ## An element got the focus.
    onblur, ## An element lost the focus.
    onchange, ## The selected value of an element was changed.
    onscroll, ## The user scrolled within an element.

    onmousedown, ## A pointing device button (usually a mouse) is pressed
                 ## on an element.
    onmouseenter, ## A pointing device is moved onto the element that
                  ## has the listener attached.
    onmouseleave, ## A pointing device is moved off the element that
                  ## has the listener attached.
    onmousemove, ## A pointing device is moved over an element.
    onmouseout, ## A pointing device is moved off the element that
                ## has the listener attached or off one of its children.
    onmouseover, ## A pointing device is moved onto the element that has
                 ## the listener attached or onto one of its children.
    onmouseup, ## A pointing device button is released over an element.

    ondrag,  ## An element or text selection is being dragged (every 350ms).
    ondragend, ## A drag operation is being ended (by releasing a mouse button
               ## or hitting the escape key).
    ondragenter, ## A dragged element or text selection enters a valid drop target.
    ondragleave, ## A dragged element or text selection leaves a valid drop target.
    ondragover, ## An element or text selection is being dragged over a valid
                ## drop target (every 350ms).
    ondragstart, ## The user starts dragging an element or text selection.
    ondrop, ## An element is dropped on a valid drop target.

    onsubmit, ## A form is submitted
    oninput, ## An input value changes

    onanimationstart,
    onanimationend,
    onanimationiteration,

    onkeyupenter, ## vdom extension: an input field received the ENTER key press
    onkeyuplater,  ## vdom extension: a key was pressed and some time
                  ## passed (useful for on-the-fly text completions)
    onload, ## img

    ontransitioncancel,
    ontransitionend,
    ontransitionrun,
    ontransitionstart,

    onwheel ## fires when the user rotates a wheel button on a pointing device.

macro buildLookupTables(): untyped =
  var a = newTree(nnkBracket)
  for i in low(VNodeKind)..high(VNodeKind):
    let x = $i
    let y = if x[0] == '#': x else: toUpperAscii(x)
    a.add(newCall("string", newLit(y)))
  var e = newTree(nnkBracket)
  for i in low(EventKind)..high(EventKind):
    e.add(newCall("string", newLit(substr($i, 2))))

  template tmpl(a, e) {.dirty.} =
    const
      toTag*: array[VNodeKind, string] = a
      toEventName*: array[EventKind, string] = e

  result = getAst tmpl(a, e)

buildLookupTables()

type
  EventHandler* = proc (ev: Event; target: VNode) {.closure.}
  NativeEventHandler* = proc (ev: Event) {.closure.}

  EventHandlers* = seq[(EventKind, EventHandler, NativeEventHandler)]

  VNode* = ref object of RootObj
    kind*: VNodeKind
    index*: int ## a generally useful 'index'
    id*, class*, text*: string
    kids*: seq[VNode]
    # even index: key, odd index: value; done this way for memory efficiency:
    attrs: seq[string]
    events*: EventHandlers

proc value*(n: VNode): string = n.text
proc `value=`*(n: VNode; v: string) = n.text = v

proc intValue*(n: VNode): int = n.index
proc vn*(i: int): VNode = VNode(kind: VNodeKind.int, index: i)
proc vn*(b: bool): VNode = VNode(kind: VNodeKind.int, index: ord(b))
proc vn*(x: string): VNode = VNode(kind: VNodeKind.text, index: -1, text: x)

proc setEventIfNoConflict(v: VNode; kind: EventKind; handler: EventHandler) =
  assert handler != nil
  for i in 0..<v.events.len:
    if v.events[i][0] == kind:
      #v.events[i][1] = handler
      return
  v.events.add((kind, handler, nil))

proc mergeEvents*(v: VNode; handlers: EventHandlers) =
  ## Overrides or adds the event handlers to `v`'s internal event handler list.
  for h in handlers: v.setEventIfNoConflict(h[0], h[1])

proc setAttr*(n: VNode; key: string; val: string = "") =
  if n.attrs.len == 0:
    n.attrs = @[key, val]
  else:
    for i in countup(0, n.attrs.len-2, 2):
      if n.attrs[i] == key:
        n.attrs[i+1] = val
        return
    n.attrs.add key
    n.attrs.add val

proc getAttr*(n: VNode; key: string): string =
  for i in countup(0, n.attrs.len-2, 2):
    if n.attrs[i] == key: return n.attrs[i+1]

proc len*(x: VNode): int = x.kids.len
proc `[]`*(x: VNode; idx: int): VNode = x.kids[idx]
proc `[]=`*(x: VNode; idx: int; y: VNode) = x.kids[idx] = y

proc add*(parent, kid: VNode) =
  parent.kids.add kid

proc delete*(parent: VNode; position: int) =
  parent.kids.delete(position)
proc insert*(parent, kid: VNode; position: int) =
   parent.kids.insert(kid, position)
proc newVNode*(kind: VNodeKind): VNode = VNode(kind: kind, index: -1)

proc tree*(kind: VNodeKind; kids: varargs[VNode]): VNode =
  result = newVNode(kind)
  for k in kids: result.add k

proc tree*(kind: VNodeKind; attrs: openarray[(string, string)];
           kids: varargs[VNode]): VNode =
  result = tree(kind, kids)
  for a in attrs: result.setAttr(a[0], a[1])

proc text*(s: string): VNode = VNode(kind: VNodeKind.vtext, text: s, index: -1)

proc verbatim*(s: string): VNode =
  VNode(kind: VNodeKind.verbatim, text: s, index: -1)


iterator items*(n: VNode): VNode =
  for i in 0..<n.kids.len: yield n.kids[i]

iterator attrs*(n: VNode): (string, string) =
  for i in countup(0, n.attrs.len-2, 2):
    yield (n.attrs[i], n.attrs[i+1])

proc sameAttrs*(a, b: VNode): bool =
  if a.attrs.len == b.attrs.len:
    result = true
    for i in 0 ..< a.attrs.len:
      if a.attrs[i] != b.attrs[i]: return false

proc addEventListener*(n: VNode; event: EventKind; handler: EventHandler) =
  n.events.add((event, handler, nil))

template toStringAttr(field) =
  if n.field.len > 0:
    result.add " " & astToStr(field) & " = " & $n.field

proc toString*(n: VNode; result: var string; indent: int) =
  for i in 1..indent: result.add ' '
  if result.len > 0: result.add '\L'
  result.add "<" & $n.kind
  toStringAttr(id)
  toStringAttr(class)
  for k, v in attrs(n):
    result.add " " & $k & " = " & $v
  result.add ">\L"
  if n.kind == VNodeKind.vtext:
    result.add n.text
  else:
    if n.text.len > 0:
      result.add " value = "
      result.add n.text
    for child in items(n):
      toString(child, result, indent+2)
  for i in 1..indent: result.add ' '
  result.add "\L</" & $n.kind & ">"

proc add*(result: var string, n: VNode, indent = 0, indWidth = 2) =
  ## adds the textual representation of `n` to `result`.

  proc addEscapedAttr(result: var string, s: string) =
    # `addEscaped` alternative with less escaped characters.
    # Only to be used for escaping attribute values enclosed in double quotes!
    for c in items(s):
      case c
      of '<': result.add("&lt;")
      of '>': result.add("&gt;")
      of '&': result.add("&amp;")
      of '"': result.add("&quot;")
      else: result.add(c)

  proc addEscaped(result: var string, s: string) =
    ## same as ``result.add(escape(s))``, but more efficient.
    for c in items(s):
      case c
      of '<': result.add("&lt;")
      of '>': result.add("&gt;")
      of '&': result.add("&amp;")
      of '"': result.add("&quot;")
      of '\'': result.add("&#x27;")
      of '/': result.add("&#x2F;")
      else: result.add(c)

  proc addIndent(result: var string, indent: int) =
    result.add("\n")
    for i in 1..indent: result.add(' ')

  if n.kind == VNodeKind.vtext:
    result.addEscaped(n.text)
  elif n.kind == VNodeKind.verbatim:
    result.add(n.text)
  else:
    let kind = $n.kind
    result.add('<')
    result.add(kind)
    if n.id.len > 0:
      result.add " id=\""
      result.addEscapedAttr(n.id)
      result.add('"')
    if n.class.len > 0:
      result.add " class=\""
      result.addEscapedAttr(n.class)
      result.add('"')
    for k, v in attrs(n):
      result.add(' ')
      result.add(k)
      result.add("=\"")
      result.addEscapedAttr(v)
      result.add('"')
    if n.len > 0:
      result.add('>')
      if n.len > 1:
        var noWhitespace = false
        for i in 0..<n.len:
          if n[i].kind == VNodeKind.vtext:
            noWhitespace = true
            break

        if noWhitespace:
          # for mixed leaves, we cannot output whitespace for readability,
          # because this would be wrong. For example: ``a<b>b</b>`` is
          # different from ``a <b>b</b>``.
          for i in 0..<n.len: result.add(n[i], indent+indWidth, indWidth)
        else:
          for i in 0..<n.len:
            result.addIndent(indent+indWidth)
            result.add(n[i], indent+indWidth, indWidth)
          result.addIndent(indent)
      else:
        result.add(n[0], indent+indWidth, indWidth)
      result.add("</")
      result.add(kind)
      result.add(">")
    elif n.kind in selfClosing:
      result.add(" />")
    else:
      result.add(">")
      result.add("</")
      result.add(kind)
      result.add(">")


proc `$`*(n: VNode): string =
    result = ""
    add(result, n)

type NodeModifier* = proc (node: VNode) {.gcSafe.}
{.pop.}