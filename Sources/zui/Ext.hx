package zui;

class Ext {

	public static function drawEditableList(ui:Zui, id:String, ar:Array<Dynamic>,
                                            addCb:String->Void = null,
                                            removeCb:Int->Void = null,
                                            getNameCb:Int->String = null,
                                            setNameCb:Int->String->Void = null,
                                            itemDrawCb:String->Int->Void = null,
                                            showRadio = false,
                                            editable = true):Int {
        var selected = 0;

        if (addCb == null) addCb = function(name:String) { ar.push(name); };
        if (removeCb == null) removeCb = function(i:Int) { ar.splice(i, 1); };
        if (getNameCb == null) getNameCb = function(i:Int) { return ar[i]; };
        if (setNameCb == null) setNameCb = function(i:Int, name:String) { ar[i] = name; };

        var i = 0;
        while (i < ar.length) {
            if (showRadio) { // Prepend ratio button
                ui.row([0.12, 0.68, 0.2]);
                if (ui.radio(Id.nest(id, 0), i, "")) {
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
        if (ui.button("Add")) {
            addCb("untitled");
        }

        return selected;
    }
}
