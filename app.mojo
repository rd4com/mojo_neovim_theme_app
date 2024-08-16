from ui import *
from pathlib import Path
from collections import Dict
var valid_highlight_groups = List[String]()

def main():
    valid_highlight_groups.extend(
        List[String](
            "normal",
            "function",
            "type",
            "identifier",
            "number",
            "string",
            "statement",
            #"another_highlight_group",
        )
    )
    var selection = 0
    if not Path("./_nvim_socket").exists():
        raise "_nvim_socket not present in this folder"
    GUI = Server()
    pynvim = Python.import_module("pynvim").attach(
        'socket', path='_nvim_socket'
    )
    ThemeParts = Dict[String, ThemePart]()
    new_part_name = String("Normal")
    new_part_bgcolor = String("#ffffff")
    new_part_fgcolor = String("#000000")

    @parameter
    def update_highlight(name:String):
        tmp_bg = ThemeParts[name].bgcolor
        if ThemeParts[name].nonebg:
            tmp_bg="none"
        pynvim.command(
            "hi " + name+" "+
            " guifg=" + ThemeParts[name].fgcolor + " "
            " guibg=" + tmp_bg + " "

        )
    while GUI.Event():
        if GUI.Button("Exit app"): break
        GUI.RawHtml("<span style='display:flex'>")
        if GUI.Button("Save"): save(ThemeParts)
        if GUI.Button("Load"): 
            load(ThemeParts)
            for p in ThemeParts: update_highlight(p[])
        if GUI.Button("Export in console for use in init.lua"): 
            export_(ThemeParts)
        GUI.RawHtml("</span>")

        GUI.RawHtml("<span style='display:flex'>")
        if GUI.ComboBox("highlight group", valid_highlight_groups, selection):
            if selection>=len(valid_highlight_groups):
                selection = 0
        if GUI.Button("➕ Add to theme"):
            if valid_highlight_groups[selection] not in ThemeParts:
                tmp = pynvim.command_output(
                    ":hi "+valid_highlight_groups[selection]
                )
                tmp = tmp.split(" ")
                var tmp_fg:String ="#000000"
                var tmp_bg:String ="#ffffff"
                var nonebg = True
                if valid_highlight_groups[selection].lower() == "normal":
                    nonebg=False

                for e in tmp:
                    if e.startswith("guifg="): 
                        tmp_fg = str(e)[6:]
                        validate_color(tmp_fg)
                    if e.startswith("guibg="): 
                        tmp_bg = str(e)[6:]
                        validate_color(tmp_bg)
                
                ThemeParts[valid_highlight_groups[selection]] = ThemePart(
                    tmp_bg,
                    tmp_fg,
                    "none",
                    nonebg
                )
                update_highlight(valid_highlight_groups[selection])
        GUI.RawHtml("</span>")
        GUI.Text("ℹ️ Add more highlight groups in app.mojo")
        GUI.NewLine()
        GUI.NewLine()
        for p in ThemeParts:
            GUI.Text(p[]+ ":")
            GUI.RawHtml("<span style='display:flex'>")
            GUI.Text("foreground")
            if GUI.ColorSelector(ThemeParts._find_ref(p[]).fgcolor): 
                validate_color(ThemeParts._find_ref(p[]).fgcolor)
                update_highlight(p[])
            GUI.Text("background")
            if GUI.ColorSelector(ThemeParts._find_ref(p[]).bgcolor):
                validate_color(ThemeParts._find_ref(p[]).bgcolor)
                update_highlight(p[])
            if GUI.Toggle(ThemeParts._find_ref(p[]).nonebg,"none bg"):
                update_highlight(p[])
            GUI.RawHtml("</span>")
            GUI.NewLine()
    _ = pynvim^
@value
struct ThemePart:
    var bgcolor: String
    var fgcolor: String
    var gui: String
    var nonebg: Bool


def save(ThemeParts: Dict[String, ThemePart]):
    var result:String = ""
    for p in ThemeParts:
        var tmp = ThemeParts[p[]]
        result += (
            p[] + " " + tmp.bgcolor + " " +  tmp.fgcolor + " " + str(tmp.nonebg)
        )
        result += "\n"
    print("➡️ Saved")
    print(result)
    Path("./_saved").write_text(result)

def load(inout ThemeParts: Dict[String, ThemePart]):
    if Path("./_saved").exists():
        var tmp = Path("./_saved").read_text().splitlines()
        if len(tmp)!=0:
            ThemeParts.clear()
        for l in tmp:
            var tmp2 = l[].split(" ")
            ThemeParts[tmp2[0]] = ThemePart(
                tmp2[1],
                tmp2[2],
                "none",
                tmp2[3]=="True"
            )

def export_(ThemeParts: Dict[String,ThemePart]):
    for p in ThemeParts:
        var cur = ThemeParts[p[]]
        var tmp_bg = cur.bgcolor
        if cur.nonebg:
            tmp_bg="none"
        print(
            "vim.cmd(\"hi " + p[] + " guifg=" + cur.fgcolor
            + " guibg=" + tmp_bg + "\")"  
        )

fn validate_color(inout color:String):
    var ok = True
    if len(color)!=7: 
        ok = False
    else:
        if color[0] != "#": ok = False
        for i in range(6):
            if not color[1+i] in String.HEX_DIGITS:
                ok = False
    if ok == False:
        color = "#FFFFFF"
