
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
[ \t] {
  /* Discard spaces and tabs */
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
	//printf("rm1st: %s\n", ret);
	int n = strlen(ret);
	ret[n-1] = '\0'; // rm last quote
	//printf("rm->%d: %s\n", n-1, ret);
	yylval.string_val = ret;
	return WORD;
}

[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  yylval.cpp_string = new std::string(yytext);
  return WORD;
}

%%
