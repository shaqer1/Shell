#include <cstdio>
#include <unistd.h>
#include "shell.hh"

int yyparse(void);

void Shell::prompt() {
  if(isatty(0)) {
    if (getenv("PROMPT")) {
      printf("%s>", getenv("PROMPT"));
    }
    else {
      printf("myshell>");
    }
    fflush(stdout);
  }/*
  printf("myshell>");
  fflush(stdout);*/
}

int main() {

  struct sigaction sa;
    sa.sa_handler = disp;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART;

    if(sigaction(SIGINT, &sa, NULL)){
        perror("sigaction");
	exit(2);
    }

    struct sigaction sa2;
    sa2.sa_handler = killZombies;
    sigemptyset(&sa2.sa_mask);
    sa2.sa_flags = SA_RESTART;
    if (sigaction(SIGCHLD, &sa2, NULL)) {
      perror("sigactionZombie");
      exit(-1);
    }
  
  Shell::prompt();
  yyparse();
}

Command Shell::_currentCommand;
