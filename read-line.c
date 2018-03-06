/*
 * CS252: Systems Programming
 * Purdue University
 * Example that shows how to read one line with simple editing
 * using raw terminal.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#define MAX_BUFFER_LINE 2048

extern void tty_raw_mode(void);


int line_length;
int cursorPos;
char line_buffer[MAX_BUFFER_LINE];

// Buffer where line is stored
int line_length;
char line_buffer[MAX_BUFFER_LINE];
static char ** history;
int history_length = 0;
int MAX_HISTORY = 50;

// Simple history array
// This history does not change. 
// Yours have to be updated.
int history_index = 0;
/*char * history [] = {
  "ls -al | grep x", 
  "ps -e",
  "cat read-line-example.c",
  "vi hello.c",
  "make",
  "ls -al | grep xxx | grep yyy"
};*//*
int history_length = sizeof(history)/sizeof(char *);*/

void read_line_print_usage()
{
  char * usage = "\n"
    " ctrl-?       Print usage\n"
    " Backspace    Deletes last character\n"
    " up arrow     See last command in the history\n";

  write(1, usage, strlen(usage));
}

/* 
 * Input a line with some basic editing.
 */
char * read_line() {
  // Set terminal in raw mode
  tty_raw_mode();

  line_length = 0;
  cursorPos = 0;
  if(history == NULL){
    history = (char **)calloc(MAX_HISTORY, sizeof(char*));
  }

  // Read one line until enter is typed
  while (1) {

    // Read one character in raw mode.
    char ch;
    read(0, &ch, 1);

    if (ch>=32 && ch!=127 && ch != 27) {
      // It is a printable character.  

      if (cursorPos != line_length) {
        char temp;
        int i;

        for (i = line_length-1; i >= cursorPos; i--) {
          temp = line_buffer[i];
          line_buffer[i] = line_buffer[i - 1];
          line_buffer[i + 1] = temp;
        }
        
        line_buffer[cursorPos] = ch;
        
        int j = line_length - cursorPos;
        for (i = 0; i < j; i++) {
          char k = 27;
          char l = 91;
          char m = 67;
          write(1, &k, 1);
          write(1, &l, 1);
          write(1, &m, 1);
        }

        for (i = 0; i < line_length; i++) {
          ch = 8;
          write(1, &ch, 1);
        }

        for (i = 0; i < line_length; i++) {
          ch = ' ';
          write(1, &ch, 1);
        }

        for (i = 0; i < line_length; i++) {
          ch = 8;
          write(1, &ch, 1);
        }

        line_length++;
        cursorPos++;
        write(1, line_buffer, line_length);
        for (i = 0; i < line_length; i++) {
          ch = 8;
          write(1, &ch, 1);
        }

        line_buffer[line_length] = '\0';
        
        for (i = 0; i < cursorPos; i++) {
          char esc = 27;
          char brac = 91;
          char C = 67;
          write(1, &esc, 1);
          write(1, &brac, 1);
          write(1, &C, 1);
        }
        
      } else {
        // Do echo
        write(1, &ch, 1);

        // If max number of character reached return.
        if (line_length == MAX_BUFFER_LINE - 2) break;

        // add char to buffer.
        line_buffer[line_length] = ch;
        line_length++;
        cursorPos++;
      }
    } else if (ch == 10 || ch == 13) {
      // <Enter> was typed. Return line

      // Set History
      line_buffer[line_length] = '\0';
      if (history_length == MAX_HISTORY) {
        MAX_HISTORY *= 2;
        history = (char **)realloc(history, MAX_HISTORY * sizeof(char*));
      }
      history[history_length] = strdup(line_buffer);
      //printf("%s\n", line_buffer);
      history_length++;
      history_index = history_length;

      // Print newline
      ch = 10;
      write(1, &ch, 1);
      ch = 13;
      write(1, &ch, 1);

      break;
    }
    else if (ch == 31) {
      // ctrl-?
      read_line_print_usage();
      line_buffer[0]=0;
      break;
    }
    else if (ch == 8 || ch == 127 && line_length != 0 && cursorPos != 0) {
      // <backspace> was typed. Remove previous char read.
      int i;
      for (i = cursorPos; i < line_length; i++) {
        char temp = line_buffer[i];
        line_buffer[i] = line_buffer[i + 1];
        line_buffer[i - 1] = temp;
      }

      int j = line_length - cursorPos;
      for (i = 0; i < j; i++) {
        char esc = 27;
        char brac = 91;
        char C = 67;
        write(1, &esc, 1);
        write(1, &brac, 1);
        write(1, &C, 1);
      }

      for (i = 0; i < line_length; i++) {
        ch = 8;
        write(1, &ch, 1);
      }

      for (i = 0; i < line_length; i++) {
        ch = ' ';
        write(1, &ch, 1);
      }

      for (i = 0; i < line_length; i++) {
        ch = 8;
        write(1, &ch, 1);
      }

      line_length--;
      write(1, line_buffer, line_length);
      for (i = 0; i < line_length; i++) {
        ch = 8;
        write(1, &ch, 1);
      }

      line_buffer[line_length] = '\0';
      cursorPos--;
      for (i = 0; i < cursorPos; i++) {
        char esc = 27;
        char brac = 91;
        char C = 67;
        write(1, &esc, 1);
        write(1, &brac, 1);
        write(1, &C, 1);
      }
    } else if (ch == 1) { //ctrl-a Home
      int i;
      for (i = 0; i < cursorPos; i++) {
        ch = 8;
        write(1, &ch, 1);
      }
      cursorPos = 0;
    } else if (ch == 4 && line_length != 0 && cursorPos != 0 && cursorPos != line_length) { //ctrl-d
      char temp = line_buffer[cursorPos];
      if (temp) {
        int i;
        for (i = cursorPos + 1; i < line_length; i++) {
          temp = line_buffer[i];
          line_buffer[i] = line_buffer[i + 1];
          line_buffer[i - 1] = temp;
        }

        int j = line_length - cursorPos;
        for (i = 0; i < j; i++) {
          char esc = 27;
          char brac = 91;
          char C = 67;
          write(1, &esc, 1);
          write(1, &brac, 1);
          write(1, &C, 1);
        }

        for (i = 0; i < line_length; i++) {
          ch = 8;
          write(1, &ch, 1);
        }

        for (i = 0; i < line_length; i++) {
          ch = ' ';
          write(1, &ch, 1);
        }

        for (i = 0; i < line_length; i++) {
          ch = 8;
          write(1, &ch, 1);
        }

        line_length--;
        write(1, line_buffer, line_length);
        for (i = 0; i < line_length; i++) {
          ch = 8;
          write(1, &ch, 1);
        }

        line_buffer[line_length] = '\0';
        for (i = 0; i < j; i++) {
          char esc = 27;
          char brac = 91;
          char C = 67;
          write(1, &esc, 1);
          write(1, &brac, 1);
          write(1, &C, 1);
        }
      }
    } else if (ch == 5) { //ctrl-e End //todo
      int i;
      int j = line_length - cursorPos;
      for (i = 0; i < j; i++) {
          char esc = 27;
          char brac = 91;
          char C = 67;
          write(1, &esc, 1);
          write(1, &brac, 1);
          write(1, &C, 1);
      }
      cursorPos = line_length;
    } else if (ch==27) {
        // Escape sequence. Read two chars more
        char ch1; 
        char ch2;
        read(0, &ch1, 1);
        read(0, &ch2, 1);

        //left
        if (ch1 == 91 && ch2 == 68 && cursorPos != 0) {
        ch = 8;
        write(1, &ch, 1);
        --cursorPos;
        } else if (ch1 == 91 && ch2 == 67 && cursorPos != line_length) {//right
            ch = line_buffer[cursorPos];
            write(1, &ch, 1);
            ++cursorPos;
        } else if (ch1 == 91 && ch2 == 65) {//up
          if (history_index > 0 && history[history_index-1] != NULL) {//null everytime history is not preserved
                // Erase old line
              // Print backspaces
              int i = 0;
              for (i = 0; i < line_length; i++) {
                ch = 8;
                write(1, &ch, 1);
              }
              // Print spaces on top
              for (i = 0; i < line_length; i++) {
                ch = ' ';
                write(1, &ch, 1);
              }
              // Print backspaces
              for (i = 0; i < line_length; i++) {
                ch = 8;
                write(1, &ch, 1);
              }

              //history
              //history_index--;
              strcpy(line_buffer, history[history_index-1]);
              line_length = strlen(line_buffer);
              history_index = (history_index + 1) % history_length;
              cursorPos = line_length;
              // print line
              write(1, line_buffer, line_length);
          }
        } else if (ch1 == 91 && ch2 == 66) {
          printf("down");
          // Down arrow. Print next line in history.
          if (history_index > 0 && history[history_index-1] != NULL) {
            // delete old line
            // Print backspaces
            int i = 0;
            for (i = 0; i < line_length; i++) {
              ch = 8;
              write(1, &ch, 1);
            }
           //  Print spaces on top
            for (i = 0; i < line_length; i++) {
              ch = ' ';
              write(1, &ch, 1);
            }
           //  Print backspaces
            for (i = 0; i < line_length; i++) {
              ch = 8;
              write(1, &ch, 1);
            }

            // Copy from history
            strcpy(line_buffer, history[history_index-1]);
            line_length = strlen(line_buffer);
            history_index = (history_index - 1) % history_length;
            cursorPos = line_length;
            // print line
            write(1, line_buffer, line_length);
          }
        } else if (ch1 == 91 && ch2 == 49) { //Home 126
          char ch3;
          read(0, &ch3, 1);
          int i;
          for (i = 0; i < cursorPos; i++) {
            ch = 8;
            write(1, &ch, 1);
          }
          cursorPos = 0;
        } else if (ch1 == 91 && ch2 == 52) { //End 126
          char ch3;
          read(0, &ch3, 1);
          int i;
          int j = line_length - cursorPos;
          for (i = 0; i < j; i++) {
            char esc = 27;
            char brac = 91;
            char C = 67;
            write(1, &esc, 1);
            write(1, &brac, 1);
            write(1, &C, 1);
          }
          cursorPos = line_length;
        }
    }
  }

  // Add eol and null char at the end of string
  line_buffer[line_length]=10;
  line_length++;
  line_buffer[line_length]=0;

  return line_buffer;
}

