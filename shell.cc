#include <cstdio>
#include <unistd.h>
#include "shell.hh"
#include <signal.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <y.tab.hh>

int yyparse(void);

extern "C" void disp( int sig ) {
  putchar('\n');
  Shell::_currentCommand.clear();
  Shell::prompt();
}

extern "C" void killZombies(int sig){
  while(waitpid(-1, NULL, WNOHANG) >0);
}

void Shell::prompt() {
  if(isatty(0)) {
    if (getenv("PROMPT")) {
      printf("%s>", getenv("PROMPT"));
    }
    else {
      printf("myshell>");
    }
    fflush(stdout);
  }
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
  int error =0;
  if ((error = sigaction(SIGCHLD, &sa2, NULL))) {
    perror("sigactionZombie");
    exit(-1);
  }
  yin = fopen(".shellrc", "r");
  if (yyin > 0) {
    yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));
    yyparse();
    yyin = stdin;
    Command::_currentCommand.clear();
    Shell::prompt();
    yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));
    yyparse();
  } else{
    yyin = NULL;
    Shell::prompt();
    yyparse();
  }
}

Command Shell::_currentCommand;
