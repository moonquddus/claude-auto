#!/usr/bin/env expect

# Claude Code asks "Do you want to proceed?", "Do you want to create <file>?"
# and several more variants. Option 1 is always "Yes".
# The full-screen display does not write the spaces between words. It moves the
# cursor instead, so each space can arrive as an escape sequence.
set question {Do[^\r\n]{1,24}you[^\r\n]{1,24}want[^\r\n]{1,24}to[^?\r\n]{0,200}\?}
# The sandbox network dialog puts its question in a box. A narrow window wraps
# the question, so the title arms the wrapper as well.
set title {Network[^\r\n]{1,24}request[^\r\n]{1,24}outside[^\r\n]{1,24}of[^\r\n]{1,24}sandbox}
# Claude Code draws ANSI attributes between "1." and "Yes".
set option {1\.[^\r\n]{0,60}Yes}
set debounce 1000
# Claude Code refuses input that arrives less than 150 ms after a dialog
# appears, so that a stray keypress cannot approve it. Wait past that window.
set settle 0.4

# CLAUDE_AUTO_TRACE records every byte Claude Code writes, to build a pattern
# for a dialog that the wrapper does not answer.
if {[info exists env(CLAUDE_AUTO_TRACE)]} {
    log_file -a $env(CLAUDE_AUTO_TRACE)
}

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
    global claude armed approved debounce settle env
    set now [clock milliseconds]
    # A redrawn frame must not send a second "1". It would land in the prompt
    # box and be submitted to Claude as a message.
    if {!$armed || $now - $approved < $debounce} return
    set armed 0
    sleep $settle
    set approved [clock milliseconds]
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
    -nobuffer -re $title { set armed 1 } \
    -nobuffer -re $option { approve }

catch wait result
exit [lindex $result 3]
