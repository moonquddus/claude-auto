# claude-auto

Auto-pilot for Claude Code. It starts Claude Code and answers the permission
prompts with `1. Yes`.

## Why

Claude Code has a bypass-permissions mode. That mode can still fall back to a
permission prompt and stop work until you answer it. `claude-auto` watches for
those prompts and answers them, so a long task does not wait for you.

You keep full control of the session. The wrapper passes your keyboard through
to Claude Code, so you can type, interrupt and quit as usual.

## Requirements

- `expect`. On macOS, install it with `brew install expect`. On Debian or
  Ubuntu, use `sudo apt install expect`.
- `claude` on your `PATH`.

## Install

Copy the script to a directory on your `PATH` and make it executable:

```sh
install -m 755 claude-auto.sh ~/bin/claude-auto
```

## Use

Use `claude-auto` in place of `claude`. It passes on every argument:

```sh
claude-auto
claude-auto --resume
claude-auto "fix the failing tests"
claude-auto --dangerously-skip-permissions
```

## How it works

The script starts Claude Code on a pseudo-terminal and connects your keyboard
to it. At the same time it reads the output of Claude Code and looks for two
things in order:

1. A question that starts with `Do you want to` and ends with `?`.
2. The first option, `1. Yes`.

When it finds both, it sends `1` and a carriage return. This is the same input
as a manual selection of `1. Yes`.

Two checks keep the wrapper quiet:

- It answers only when the option list comes after the question. If Claude Code
  writes `Do you want to proceed?` in ordinary text, the wrapper does nothing.
- It answers a given prompt once. A redrawn screen cannot cause a second `1`.

The script also copies the size of your terminal to Claude Code, and does it
again when you change the size of the window.

## Log

Set `CLAUDE_AUTO_LOG` to record each automatic answer:

```sh
CLAUDE_AUTO_LOG=~/claude-auto.log claude-auto
```

The wrapper does not write to the screen, because that damages the Claude Code
display.

## Tests

```sh
./test/run.sh
```

The tests replace `claude` with a stub program and drive the wrapper through a
pseudo-terminal. They need no network and no credentials.

## Limits

- The wrapper answers `Yes` to every permission prompt that it finds. It
  removes that safety check. Use it only for work that you accept in advance.
- The wrapper finds a prompt by its text. A change to the text in a new version
  of Claude Code can stop it. If this occurs, the wrapper sends nothing and you
  answer the prompt yourself.
- Use the wrapper for interactive sessions. For a piped or scripted run, use
  `claude` directly.

## License

MIT. See [LICENSE](LICENSE).
