#include <cstdio>
#include <unistd.h>
#include "shell.hh"
#include <signal.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include "y.tab.hh"
//#include <wchar.h>

#ifndef YY_BUF_SIZE
#ifdef __ia64__
#define YY_BUF_SIZE 32768
#else
#define YY_BUF_SIZE 16384
#endif /* __ia64__ */
#endif
#define YY_TYPEDEF_YY_BUFFER_STATE
typedef struct yy_buffer_state *YY_BUFFER_STATE;



int yyparse(void);
YY_BUFFER_STATE yy_create_buffer(FILE * fd, int s);
void yypush_buffer_state(YY_BUFFER_STATE buff);
void yyrestart(FILE * fd);
void yy_delete_buffer( YY_BUFFER_STATE buff);
 
/*YY_BUFFER_STATE yy_create_buffer (FILE *file,int size  );
void yy_switch_to_buffer (YY_BUFFER_STATE new_buffer  );*/

#define ANSI_COLOR_RED     "\x1b[31m"
#define ANSI_COLOR_GREEN   "\x1b[32m"
#define ANSI_COLOR_YELLOW  "\x1b[33m"
#define ANSI_COLOR_BLUE    "\x1b[34m"
#define ANSI_COLOR_MAGENTA "\x1b[35m"
#define ANSI_COLOR_CYAN    "\x1b[36m"
#define ANSI_COLOR_RESET   "\x1b[0m"


extern "C" void disp( int sig ) {
  printf("\n");
  Shell::_currentCommand.clear();
  Shell::prompt();
}

extern "C" void killZombies(int sig){
  while(waitpid(-1, NULL, WNOHANG) >0);
}

extern "C" void bgHandler(int sig){
    pid_t pid;
  while((pid = waitpid(-1, NULL, WNOHANG)) >0){
    if(pid != -1)
        printf("[%d] exited\n", pid);
  }
    Shell::prompt();
}


void Shell::prompt() {
  if(isatty(0)) {
    if (getenv("PROMPT")) {
      printf("%s>", getenv("PROMPT"));
    }
    else {
      //setlocale(LC_ALL, "");
      //printf("%lc>", (wint_t) 2665);
      printf(ANSI_COLOR_RED "♥" ANSI_COLOR_YELLOW "♥" ANSI_COLOR_GREEN 
        "♥" ANSI_COLOR_BLUE "♥" ANSI_COLOR_MAGENTA "♥" ANSI_COLOR_RESET "⇔");
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

  struct sigaction sa3;
        sa3.sa_handler = bgHandler;
        sigemptyset(&sa3.sa_mask);
        sa3.sa_flags = 0;
        error =0;
        if ((error = sigaction(SIGCHLD, &sa3, NULL))) {
            perror("child");
            exit(-1);
        }

  FILE * fd = fopen(".shellrc", "r");
  if (fd > 0) {
    YY_BUFFER_STATE y = yy_create_buffer(fd, YY_BUF_SIZE);
    yypush_buffer_state(y);
    yyparse();
    yyrestart(stdin);
    fclose(fd);
    yyparse();
  } else {
    fd = NULL;
    Shell::prompt();
    yyparse();
  }

}

Command Shell::_currentCommand;
