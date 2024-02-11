# view

A barebones assembly schtick. 
Made by anson.

This is a simple program that writes the
contents of a given file to 'stdout', similar
to the program 'cat'. It has an internal
buffer limited to 9,216 bytes, and any file larger
than such will not have all of their data read. This
program will not modify files.

Command-line arguments are as follows:
> view -h (--help) -v (--version) -c (--count) (filename)

As of v.1.0.5, this program supports globbing of
arguments as well as long options, however there is not
much reason to actually do so, considering that this
program will resolve the '--help' and '--version' option
first, which will stop program flow. In that case, '--help'
takes precedence over '--version'. At the moment, view can
not read standard input from pipe, and can only read data
from existing files.

This program is best used for simple ASCII text files,
as other file types may prove to have side effects
in regards to terminal output, though extensive testing
has not been preformed. In the case of files being unable
to be opened or read, view will print respective error
messages. view also gives error messages in the case of
not enough arguments present, and unrecognized arguments.

I was completely unaware of an x86-32 NASM assembly
tutorial 'Writing a useful program with NASM' by 
Jonathan Leto 
(https://web.archive.org/web/20190119034555/http://leto.net/writing/nasm.php)
so any similarity is entirely coincidental.

### v.1.0.0
Initial version, able to read files into a buffer
which is then written to screen.

### v.1.0.5
Added the ability to read long options and to glob
single-character arguments, as well as the option to
print a specific amount of bytes to 'stdout'.
