package zui;

class Ext {

	public static function drawEditableList(ui:Zui, id:String, ar:Array<String>, itemCb:Int->Void = null) {
        var i = 0;
        while (i < ar.length) {
            ui.row([0.8, 0.2]);
            ar[i] = ui.textInput(Id.nest(id, i), ar[i]);
            if (ui.button("X")) {
                ar.splice(i, 1);
            }
            else i++;

            if (itemCb != null) itemCb(i - 1);
        }
        if (ui.button("Add")) {
            ar.push("untitled");
        }
    }
}
