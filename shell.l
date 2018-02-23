
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
#include <algorithm>

static void yyunput (int c,char *buf_ptr  );

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
	std::string str;
	str.append("^");
	str.append(s->c_str());
	size_t i=0;
	while(i<str.size()){
		if((i = str.find("*", i)) != std::string::npos){
			str.replace(i , 1, ".*");
			i+=2;
		}
		if((i = str.find("?", i)) != std::string::npos){
			str.replace(i , 1, ".");
			i++;
		}
		if((i = str.find(".", i)) != std::string::npos){
			str.replace(i , 1, "\\.");
			i+=2;
		}
		if((i = str.find("*",i)) != std::string::npos){
			str.replace(i , 1, ".*");
			i+=2;
		}

	}
	str.append("$");
	// match beginning of line
	// 2. compile regular expression. See lab3-src/regular.cc
	regex_t re;
	char * sReg = (char *) str.c_str();
	int expbuf = regcomp(&re, sReg, 0 );
	if (expbuf!=0) {
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
	int nEntries = 0;
	std::vector<std::string *> array;
	while ( (ent = readdir(dir))!= NULL) {
		// Check if name matches
		regmatch_t match;
		if (regexec(&re, ent->d_name, 1, &match, 0 ) ==0 ) {
			std::string *s = (strdup(ent->d_name));
			array.push_back(s);
			//nEntries++;
		}
	}
	closedir(dir);
	std::sort(array.begin(), array.end());
	// Add arguments
	for (int i = 0; i < array.size(); i++) {
		Command::_currentSimpleCommand->insertArgument(array[i]);
	}
}

%}

%%

source[ ^\t\n][ ^\t\n]*.* {
	std::string  s (yytext);
	s.assign(s.substr(s.find(" ") + 1, s.size()-s.find(" ")));
	yyin = fopen(s.c_str() , "r");
    if(yyin == 0){
        printf("Cannot open file %s\n", s.c_str());
        exit(1);
    }
    yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));
    yyparse();
    yypop_buffer_state();
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
		char * command = strdup(yytext + 2);
		command[ strlen(command) - 1] = '\0';

		int defaultin = dup(0);
		int defaultout = dup(1);

		int childpout[2];
		int parentpin[2];
		pipe(childpout);
		pipe(parentpin);

		int max = 5;
		int index = 0;
		char * buffer = (char *) calloc(0, max * sizeof(char));
		char c;

		int ret = fork();
		if (ret == 0) {
			write(parentpin[1], command, strlen(command));
			write(parentpin[1], "\nexit1\n", 7);

			close(parentpin[1]);
			close(childpout[0]);

			dup2(parentpin[0], 0);
			dup2(childpout[1], 1);

			char *argv[2];
			argv[0] = command;
			argv[1] = NULL;

			execvp("/proc/self/exe", argv);
			perror("subshell");
			_exit(0);
		} else if (ret > 0) {
			
			close(parentpin[0]);
			close(parentpin[1]);
			close(childpout[1]);

			waitpid(ret, NULL, 0);

			while(read(childpout[0], &c, 1) > 0) {
				buffer[index] = c;
				if(index + 1 > max) {
					max *= 2;
					buffer = (char*)realloc(buffer, (max * sizeof(char*)));
				}
				index++;
			}
			buffer[index] = '\0';
			
			close(childpout[0]);
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


[^ \t\n]*\\[^ \t\n]* {
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
		yylval.cpp_string = new std::string(strdup(newArg));
    	return WORD;
}


\"[^\n]*\" {
	//printf("%s\n", "quotes");
	char * ret = strdup(yytext + 1); // rm first quote
	//printf("rm1st: %s\n", ret);
	int n = strlen(ret);
	ret[n-1] = '\0'; // rm last quote
	//printf("rm->%d: %s\n", n-1, ret);
	yylval.cpp_string = new std::string(strdup(ret));
	return WORD;
}


[^ \t\n\>\|][^ \t\n\>\|]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}

%%
