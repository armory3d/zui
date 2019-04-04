package zui;

class Themes {

	public static var dark: TTheme = {
		FONT_SIZE: 13,
		ELEMENT_W: 100,
		ELEMENT_H: 22,
		ELEMENT_OFFSET: 4,
		ARROW_SIZE: 5,
		BUTTON_H: 17,
		CHECK_SIZE: 15,
		CHECK_SELECT_SIZE: 8,
		SCROLL_W: 8,
		TEXT_OFFSET: 8,
		TAB_W: 12,
		LINE_STRENGTH: 1,
		FILL_WINDOW_BG: false,
		FILL_BUTTON_BG: true,
		FILL_ACCENT_BG: false,

		WINDOW_BG_COL: 0xff333333,
		WINDOW_TINT_COL: 0xffffffff,
		ACCENT_COL: 0xff444444,
		ACCENT_HOVER_COL: 0xff484848,
		ACCENT_SELECT_COL: 0xff606060,
		PANEL_BG_COL: 0xff333333,
		PANEL_TEXT_COL: 0xffcac9c7,
		BUTTON_COL: 0xff484848,
		BUTTON_TEXT_COL: 0xffcac9c7,
		BUTTON_HOVER_COL: 0xff3b3b3b,
		BUTTON_PRESSED_COL: 0xff1b1b1b,
		TEXT_COL: 0xffcac9c7,
		LABEL_COL: 0xffaaaaaa,
		ARROW_COL: 0xffcac9c7,
		SEPARATOR_COL: 0xff272727,
		HIGHLIGHT_COL: 0xff205d9c,
	};

	// 2x scaled, for games
	public static var light: TTheme = {
		FONT_SIZE: 13 * 2,
		ELEMENT_W: 100 * 2,
		ELEMENT_H: 22 * 2,
		ELEMENT_OFFSET: 2 * 2,
		ARROW_SIZE: 5 * 2,
		BUTTON_H: 17 * 2,
		CHECK_SIZE: 15 * 2,
		CHECK_SELECT_SIZE: 8 * 2,
		SCROLL_W: 8 * 2,
		TEXT_OFFSET: 8 * 2,
		TAB_W: 12 * 2,
		LINE_STRENGTH: 1 * 2,
		FILL_WINDOW_BG: false,
		FILL_BUTTON_BG: true,
		FILL_ACCENT_BG: false,

		WINDOW_BG_COL: 0xffefefef,
		WINDOW_TINT_COL: 0xff222222,
		ACCENT_COL: 0xffeeeeee,
		ACCENT_HOVER_COL: 0xffbbbbbb,
		ACCENT_SELECT_COL: 0xffaaaaaa,
		PANEL_BG_COL: 0xffffffff,
		PANEL_TEXT_COL: 0xff222222,
		BUTTON_COL: 0xffcccccc,
		BUTTON_TEXT_COL: 0xff222222,
		BUTTON_HOVER_COL: 0xffb3b3b3,
		BUTTON_PRESSED_COL: 0xffb1b1b1,
		TEXT_COL: 0xff999999,
		LABEL_COL: 0xffaaaaaa,
		ARROW_COL: 0xffcac9c7,
		SEPARATOR_COL: 0xff999999,
		HIGHLIGHT_COL: 0xff205d9c,
	};
}

typedef TTheme = {
	var FONT_SIZE: Int;
	var ELEMENT_W: Int;
	var ELEMENT_H: Int;
	var ELEMENT_OFFSET: Int;
	var ARROW_SIZE: Int;
	var BUTTON_H: Int;
	var CHECK_SIZE: Int;
	var CHECK_SELECT_SIZE: Int;
	var SCROLL_W: Int;
	var TEXT_OFFSET: Int;
	var TAB_W: Int;
	var LINE_STRENGTH: Int;
	var FILL_WINDOW_BG: Bool;
	var FILL_BUTTON_BG: Bool;
	var FILL_ACCENT_BG: Bool;

	var WINDOW_BG_COL: Int;
	var WINDOW_TINT_COL: Int;
	var ACCENT_COL: Int;
	var ACCENT_HOVER_COL: Int;
	var ACCENT_SELECT_COL: Int;
	var PANEL_BG_COL: Int;
	var PANEL_TEXT_COL: Int;
	var BUTTON_COL: Int;
	var BUTTON_TEXT_COL: Int;
	var BUTTON_HOVER_COL: Int;
	var BUTTON_PRESSED_COL: Int;
	var TEXT_COL: Int;
	var LABEL_COL: Int;
	var ARROW_COL: Int;
	var SEPARATOR_COL: Int;
	var HIGHLIGHT_COL: Int;
}
