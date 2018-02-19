
/*
 *
 * CS-252 Fall 2017
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

#include <cstring>
#include "y.tab.hh"
#include <unistd.h> //for isatty
#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/prctl.h>



static  void yyunput (int c,char *buf_ptr  );
extern char* shelldir;

void myunputc(int c) {
  unput(c);
}

%}

%%

\n 	{
		return NEWLINE;
	}

[ \t] 	{
		/* Discard spaces and tabs */
     	}	

"|" 	{
		return PIPE;
	}

">" 	{
		return GREAT;
	}

"<" 	{
		return LESS;
	}

">&" 	{
		return GREATAMPERSAND;
	}

">>" 	{
		return GREATGREAT;
	}

">>&" 	{
		return GREATGREATAMPERSAND;
	}

"&" 	{
		return AMPERSAND;
}
"2>" {
  return TWOGREAT;
}
[ \t] {
  /* Discard spaces and tabs */
}


$([^\n\`]*) {
		// subshell
		char * command = strdup(yytext + 2); 	// drop the  `
		command[ strlen(command) - 1] = '\0';

		// store defaultin and out
		int defaultin = dup(0);
		int defaultout = dup(1);

		// creat pipes
		int childpipe[2];
		int parentpipe[2];
		pipe(childpipe);
		pipe(parentpipe);

		// buffer
		int max = 5;
		int index = 0;
		char * buffer = (char *) calloc(0, max * sizeof(char));
		char c;

		int ret = fork();
		if (ret == 0) {
			write(parentpipe[1], command, strlen(command));
			write(parentpipe[1], "\nexit\n", 6);

			close(parentpipe[1]);
			close(childpipe[0]);

			dup2(parentpipe[0], 0);
			dup2(childpipe[1], 1);

			execvp("/proc/self/exe", *command);
			perror("subshell");
			_exit(0);
		} else if (ret > 0) {
			//wait till child finish
			
			close(parentpipe[0]);
			close(parentpipe[1]);
			close(childpipe[1]);

			waitpid(ret, NULL, 0);

			while(read(childpipe[0], &c, 1) > 0) {
				buffer[index] = c;
				if(index + 1 > max) {
					max *= 2;
					buffer = (char*)realloc(buffer, (max * sizeof(char*)));
				}
				index++;
			}
			buffer[index] = '\0';
			
			close(childpipe[0]);
			dup2(defaultin, 0);
			dup2(defaultout, 1);
			close(defaultin);
			close(defaultout);

			int i;
			for (i = index; i > -1 ; i--) {
				if (buffer[i] == '\n') buffer[i] = ' ';
				yyunput(buffer[i], buffer);
			}
		} else {
			perror("fork");
			_exit(1);
		}
	}

[^ \t\n]*\\[^\t\n]* {
//printf("%s\n", "escapes");
	int n = strlen(yytext);
	int i = 0;
	int j = 0;
	char * build = (char *) malloc(sizeof(char)*n);
	for (i = 0; i < n; i++) {
		if(yytext[i] == '\\' && i != n-1) {
			++i;	//rid escape
			//printf("if: yytext[%d] = %c\n", i, yytext[i]);
			build[j++] = yytext[i];
			//printf("if: build[%d] = %c\n", j, build[j]);
		}
		else {
			//printf("else: yytext[%d] = %c\n", i, yytext[i]);
			//printf("else: build[%d] = %c\n", j, build[j]);
			build[j++] = yytext[i];
		}
	}
	build[j] = '\0';
	//printf("build[%d] = %s\n", j, build);
	yylval.string_val = build;
	return WORD;
}

\"[^\n]*\" {
//printf("%s\n", "quotes");
	char * ret = strdup(yytext + 1); // rm first quote
	printf("rm1st: %s\n", ret);
	int n = strlen(ret);
	ret[n-1] = '\0'; // rm last quote
	printf("rm->%d: %s\n", n-1, ret);
	yylval.string_val = ret;
	return WORD;
}

[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}

%%
