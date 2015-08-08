# zui

Immediate Mode Graphical User interface for Haxe Kha, mainly useful for tools or game debug. Can be used directly as Kha library included in project.kha.  

Inspired by [imgui](https://github.com/ocornut/imgui).

## Getting started
``` hx
var ui = new Zui(font, fontSmall);
ui.begin(g);
ui.window(Id.window(), x, y, w, h, Zui.LAYOUT_VERTICAL);
if (button("Hello")) {
    trace("World");
}
ui.end();
```

## Elements
``` hx
node(id:String, text:String, accent = 1, expanded = false):Bool
text(text:String, align = ALIGN_LEFT)
textInput(id:String, text:String, label:String = ""):String
button(text:String):Bool
check(id:String, text:String, initState:Bool = false):Bool
radio(groupId:String, pos:Int, text:String, initState:Int = 0):Bool
row(ratios:Array<Float>)
```

Ext.hx - more complex elements:
``` hx
drawList(...)
drawNodeList(...)
```

Id.hx - simple macros to generate ids
``` hx
var state = check(Id.check(), "Check Box");
```

## Roadmap
- More robust ID system
- More elements
- Nicer theme
- Optimize

## Example

``` hx
ui.window(Id.window(), 0, 0, 250, 600);

if (ui.node(Id.node(), "Node", 2, true)) {
    ui.text("Text");
    ui.textInput(Id.textInput(), "Hello", "Input");
    ui.button("Button");
    ui.check(Id.check(), "Check Box");
    var id = Id.radio();
    ui.radio(id, Id.pos(), "Radio 1");
    ui.radio(id, Id.pos(), "Radio 2");
    ui.radio(id, Id.pos(), "Radio 3");
    if (ui.node(Id.node(), "Nested Node", 1)) {
        ui.text("Row");
        ui.row([2/5, 2/5, 1/5]);
        ui.button("A");
        ui.button("B");
        ui.check(Id.check(), "C");
        ui.text("Simple list");
        Ext.drawList(ui, Id.list(), ["Item 1", "Item 2", "Item 3"]);
    }
}

ui.end();
```

<img src="https://raw.githubusercontent.com/luboslenco/zui/master/zui.png" alt="Zui Preview" width="25%"/>
