#!/usr/bin/env expect

spawn -noecho claude {*}$argv

# interact overwrites both of these, so keep a copy.
set claude $spawn_id
set claude_tty $spawn_out(slave,name)

proc resize {} {
    global claude_tty
    if {[catch {stty rows} rows]} return
    if {[catch {stty columns} cols]} return
    # stty reports 0 rather than failing when stdin is not a terminal.
    if {$rows > 0 && $cols > 0} {
        catch {stty rows $rows columns $cols < $claude_tty}
    }
}

resize
trap resize WINCH

interact -o -nobuffer -re {Do you want to proceed\?} {
    send -i $claude -- "1\r"
}

catch wait result
exit [lindex $result 3]
