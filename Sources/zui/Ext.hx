package zui;

class Ext {

	public static function drawEditableList(ui:Zui, id:String, ar:Array<String>,
                                            addCb:Void->Void = null, removeCb:Int->Void = null,
                                            itemDrawCb:String->Int->Void = null) {
        var i = 0;
        while (i < ar.length) {
            ui.row([0.8, 0.2]);
            var itemId = Id.nest(id, i);
            ar[i] = ui.textInput(itemId, ar[i]);
            if (ui.button("X")) {
                ar.splice(i, 1);
                if (removeCb != null) removeCb(i);
            }
            else i++;

            if (itemDrawCb != null) itemDrawCb(Id.nest(itemId, i), i - 1);
        }
        if (ui.button("Add")) {
            ar.push("untitled");
            if (addCb != null) addCb();
        }
    }
}
