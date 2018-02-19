
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
#include <dirent.h>
#include <string.h>
#include <sys/prctl.h>
#include "shell.hh"
#include <regex.h>     
#include <assert.h>

/* int mygetc(FILE * f) {
       static char *p;
       char ch;

       if(!isatty(0)) {
               //stdin is not a tty. call real getc
               return getc(f);
       }

       //stdin is a tty. call our read_line
       if (p == NULL || *p == 0) {
               char * s  = read_line();
               p = s;
       }

       ch = *p;
       p++;

       return ch;
}

#undef getc
#define getc(f) mygetc(f) */

static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

void expandWildcardsIfNecessary(std::string *s)
{
	char *arg = (char *) s->c_str();
// Return if arg does not contain * or ?
	if (strchr(arg, '*') == NULL && strchr(arg, '?') == NULL) {
		Command::_currentSimpleCommand->insertArgument(s);
		return;
	}
	// 1. Convert wildcard to regular expression
	// Convert “*” -> “.*”
	//“?” -> “.”
	//“.” -> “\.” and others you need
	// Also add ^ at the beginning and $ at the end to match
	// the beginning ant the end of the word.
	// Allocate enough space for regular expression
	char * reg = (char*)malloc(2*strlen(arg)+10);
	char * a = arg;
	char * r = reg;
	*r = '^';
	r++;
	// match beginning of line
	while (*a) {
		if (*a == '*') { 
			*r='.'; 
			r++; 
			*r='*'; 
			r++; 
		}
		else if (*a == '?') { 
			*r='.'; 
			r++;
		}
		else if (*a == '.') { 
			*r='\\'; 
			r++; 
			*r='.'; 
			r++;
		}
		else { 
			*r=*a; 
			r++;
		}
		a++;
	}
	*r='$'; 
	r++; 
	*r=0;// match end of line and add null char
	// 2. compile regular expression. See lab3-src/regular.cc
	regex_t re;
	int expbuf = regcomp(&re, r, REG_EXTENDED|REG_NOSUB );
	if (expbuf==0) {
		perror("compile");
		return;
	}
	// 3. List directory and add as arguments the entries
	// that match the regular expression
	DIR * dir = opendir(".");
	if (dir == NULL) {
		perror("opendir");
		return;
	}
	struct dirent * ent;
	int maxEntries = 20;
	int nEntries = 0;
	char ** array = (char**) malloc(maxEntries*sizeof(char*));
	while ( (ent = readdir(dir))!= NULL) {
		// Check if name matches
		regmatch_t match;
		if (regexec(&re, ent->d_name, 1, &match, 0 ) ==0 ) {
			if (nEntries == maxEntries) {
				maxEntries *=2;
				array = (char **) realloc( array, maxEntries*sizeof(char*));
				assert(array!=NULL);
			}
			array[nEntries]= strdup(ent->d_name);
			nEntries++;
		}
	}
	closedir(dir);
	//sortArrayStrings(array, nEntries);
	// Add arguments
	for (int i = 0; i < nEntries; i++) {
		// Command::_currentSimpleCommand->insertArgument(array[i]));
	}
	free(array);


}

%}

%%

"source" [^ \t\n\>\|][^ \t\n\>\|]* {
	yyin = fopen(yytext , "r");
    if(yyin == 0){
        printf("Cannot open file %s\n", yytext);
        exit(1);
    }
    yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));
    BEGIN(INITIAL);
}

\n 	{
		return NEWLINE;
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


\$\([^\n]*\) {
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
			write(parentpipe[1], "\nexit1\n", 7);

			close(parentpipe[1]);
			close(childpipe[0]);

			dup2(parentpipe[0], 0);
			dup2(childpipe[1], 1);

			char *argv[2];
			argv[0] = command;
			argv[1] = NULL;

			execvp("/proc/self/exe", argv);
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


[^ \t\n&<>\|]*\\[^ \t\n]* {
		//escape
		char * newArg = (char*)malloc(strlen(yytext) + 1);
		int x = 0;
		for (int i = 0; i < strlen(yytext); i++) {
			if (yytext[i] == '\\') 
				i++;
			newArg[x] = yytext[i];
			x++;
		
		}
		newArg[x] = '\0'; 
		yylval.string_val = strdup(newArg);
    	return WORD;
}

"\"[^\n]*\"" {
//printf("%s\n", "quotes");
	char * ret = strdup(yytext + 1); // rm first quote
	//printf("rm1st: %s\n", ret);
	int n = strlen(ret);
	ret[n-1] = '\0'; // rm last quote
	//printf("rm->%d: %s\n", n-1, ret);
	yylval.string_val = ret;
	return WORD;
}

[^ \t\n\>\|][^ \t\n\>\|]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}

%%
