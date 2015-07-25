package zui;

class Ext {

	public static function drawEditableList(ui:Zui, ar:Array<String>) {
        var i = 0;
        while (i < ar.length) {
            ui.row([0.8, 0.2]);
            ar[i] = ui.inputText(Id.nest(Id.inputText(), i), ar[i]);
            if (ui.button("X")) {
                ar.splice(i, 1);
            }
            else i++;
        }
        if (ui.button("Add")) {
            ar.push("untitled");
        }
    }
}
