package zui;

class Ext {

	public static function list(ui: Zui, id: String, ar: Array<Dynamic>,
                                    addCb: String->Void = null,
                                    removeCb: Int->Void = null,
                                    getNameCb: Int->String = null,
                                    setNameCb: Int->String->Void = null,
                                    itemDrawCb: String->Int->Void = null,
                                    showRadio = false,
                                    editable = true,
                                    showAdd = true,
                                    initState = 0): Int {
        var selected = 0;

        if (addCb == null) addCb = function(name: String) { ar.push(name); };
        if (removeCb == null) removeCb = function(i: Int) { ar.splice(i, 1); };
        if (getNameCb == null) getNameCb = function(i: Int) { return ar[i]; };
        if (setNameCb == null) setNameCb = function(i: Int, name: String) { ar[i] = name; };

        var i = 0;
        while (i < ar.length) {
            if (showRadio) { // Prepend ratio button
                ui.row([0.12, 0.68, 0.2]);
                if (ui.radio(Id.nest(id, 0), i, "", initState)) {
                    selected = i;
                }
            }
            else { ui.row([0.8, 0.2]); }

            var itemId = Id.nest(id, i);
            editable ? setNameCb(i, ui.textInput(itemId, getNameCb(i))) : ui.text(getNameCb(i));
            if (ui.button("X")) {
                removeCb(i);
            }
            else i++;

            if (itemDrawCb != null) itemDrawCb(Id.nest(itemId, i), i - 1);
        }
        if (showAdd && ui.button("Add")) {
            addCb("untitled");
        }

        return selected;
    }

    public static function setRadioListSelection(ui: Zui, id: String, pos: Int) {
        ui.setRadioSelection(Id.nest(id, 0), pos);
    }

    public static function nodeList(ui: Zui, id: String, ar: Array<Dynamic>,
                                        addCb: String->Void = null,
                                        removeCb: Int->Void = null,
                                        getNameCb: Int->String = null,
                                        setNameCb: Int->String->Void = null,
                                        itemDrawCb: String->Int->Void = null,
                                        editable = true,
                                        showAdd = true) {

        if (addCb == null) addCb = function(name: String) { ar.push(name); };
        if (removeCb == null) removeCb = function(i: Int) { ar.splice(i, 1); };
        if (getNameCb == null) getNameCb = function(i: Int) { return ar[i]; };
        if (setNameCb == null) setNameCb = function(i: Int, name:String) { ar[i] = name; };

        var i = 0;
        while (i < ar.length) {
            ui.row([0.12, 0.68, 0.2]);
            var expanded = ui.node(Id.nest(id, i), "", 0);

            var itemId = Id.nest(id, i);
            editable ? setNameCb(i, ui.textInput(itemId, getNameCb(i))) : ui.text(getNameCb(i));
            if (ui.button("X")) {
                removeCb(i);
            }
            else i++;

            if (itemDrawCb != null && expanded) itemDrawCb(Id.nest(itemId, i), i - 1);
        }
        if (showAdd && ui.button("Add")) {
            addCb("untitled");
        }
    }
	
	public static function colorPicker(ui: Zui, id: String, alpha = false, initColor: Int = 0xff000000): Int {
		var r = ui.slider(Id.nest(id, 0), "R", 0, 1, true);
		var g = ui.slider(Id.nest(id, 1), "G", 0, 1, true);
		var b = ui.slider(Id.nest(id, 2), "B", 0, 1, true);
		var a = 1.0;
		if (alpha) a = ui.slider(Id.nest(id, 3), "A", 0, 1, true);
		var col = kha.Color.fromFloats(r, g, b, a);
		ui.text("", Right, col);
		return col;
	}
}
