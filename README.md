# Xorg-wall
Send a notification or open an application for all Xorg users on the machine

**TODO:** Pending to extend this README

## Requirements
This script requieres following applications to work:
- zenity
- wmctrl

## Installation

You can use make to install this script into machine sbin.

```
make install
```

## Usage

```
Xorg-wall [options] <mode> <parameters>

Invoke a graphical window to all users of Xorg displays

Options:
     --user <name>   Invoke only for one user
     --ontop         Set the application on top of screen
  -V --version       Show version information
  -h --help          Show this help message

Modes:
     --warning       Print a warning dialog
     --info          Print an info dialog
     --custom        Invoke a custom app

Parameters for --warning <title> <msg> [onTop]
  title    Is the title of the warning window
  msg      Is the message of the warning window

Parameters for --info <title> <msg>
  title    Is the title of the info window
  msg      Is the message of the info window

Parameters for --custom <cmd> [attr ...]
  cmd      Is the command to execute
  attr     Is an attribute for the command
```

## Example

```
Xorg-wall --ontop --warning "System reboot" "System will reboot in 5 minutes. Save any progress."
```

```
Xorg-wall --user ipsum --info "Files uploaded" "Requested files have been uploaded into your user home."
```

```
Xorg-wall --ontop --user ipsum --custom xclock
```