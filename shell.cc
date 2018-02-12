#include <cstdio>

#include "shell.hh"

int yyparse(void);

void Shell::prompt() {
  /*if(isatty(0)) {
    if (getenv("PROMPT")) {
      printf("%s>", getenv("PROMPT"));
    }
    else {
      printf("myshell>");
    }
    fflush(stdout);
  }*/
  printf("myshell>");
  fflush(stdout);
}

int main() {
  Shell::prompt();
  yyparse();
}

Command Shell::_currentCommand;
