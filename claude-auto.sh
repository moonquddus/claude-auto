#!/usr/bin/env expect

# Claude Code asks "Do you want to proceed?", "Do you want to create <file>?"
# and several more variants. Option 1 is always "Yes".
set question {Do you want to [^?\r\n]{0,120}\?}
# Claude Code draws ANSI attributes between "1." and "Yes".
set option {1\..{0,20}Yes}
set debounce 1000

spawn -noecho claude {*}$argv

# interact overwrites both of these, so keep a copy.
set claude $spawn_id
set claude_tty $spawn_out(slave,name)

set armed 0
set approved 0

proc resize {} {
    global claude_tty
    if {[catch {stty rows} rows]} return
    if {[catch {stty columns} cols]} return
    # stty reports 0 rather than failing when stdin is not a terminal.
    if {$rows > 0 && $cols > 0} {
        catch {stty rows $rows columns $cols < $claude_tty}
    }
}

proc approve {} {
    global claude armed approved debounce env
    set now [clock milliseconds]
    # A redrawn frame must not send a second "1". It would land in the prompt
    # box and be submitted to Claude as a message.
    if {!$armed || $now - $approved < $debounce} return
    set armed 0
    set approved $now
    send -i $claude -- "1\r"
    if {[info exists env(CLAUDE_AUTO_LOG)]} {
        set log [open $env(CLAUDE_AUTO_LOG) a]
        puts $log "[clock format [clock seconds]] approved"
        close $log
    }
}

resize
trap resize WINCH

interact -o \
    -nobuffer -re $question { set armed 1 } \
    -nobuffer -re $option { approve }

catch wait result
exit [lindex $result 3]
