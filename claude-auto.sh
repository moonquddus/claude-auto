#!/usr/bin/env expect

# Don't time out while Claude Code is thinking/running a command.
set timeout -1

# Start Claude Code with every argument passed to this wrapper.
spawn claude {*}$argv

# Watch the terminal for Claude Code's approval prompt.
expect {
    # The terminal may contain ANSI escape sequences between pieces
    # of text, so don't try to match the entire rendered prompt.
    -re {Do you want to proceed\?} {
        puts "\n\[claude-auto\] Automatically selecting: 1. Yes"
        send "1\r"
        exp_continue
    }

    # Claude exited normally.
    eof {
        catch wait result
        exit [lindex $result 3]
    }

    # Keep the interaction alive.
    timeout {
        exp_continue
    }
}
