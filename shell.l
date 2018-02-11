
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

extern "C" char * read_line();

int mygetc(FILE * f) {
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
#define getc(f) mygetc(f)

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

`[^\n`]*` {
//printf("%s\n", "backticks");
++yytext;
char * stuff = strdup(yytext);
	stuff[strlen(yytext--) - 1] = '\0';
	int tmpin = dup(0);
	int tmpout = dup(1);
	int piper[2];
	int piper2[2];
	pipe(piper);
	pipe(piper2);
	write(piper[1], stuff, strlen(stuff));
	write(piper[1], "\nexitNoPrint\n", 13);
	close(piper[1]);
	dup2(piper[0], 0);
	close(piper[0]);
	dup2(piper2[1], 1);
	close(piper2[1]);
	int ret = fork();
	if(ret == 0) {
		execvp("/proc/self/exe", NULL);
		_exit(1);
	}
	else if (ret < 0 ) {
		perror("fork");
		exit(-1);
	}
	dup2(tmpin, 0);
	dup2(tmpout, 1);
	close(tmpin);
	close(tmpout);
	char c;
	char * buff = (char *) malloc(sizeof(char)*2048);
	int i = 0;
	while(read(piper2[0], &c, 1)) {
		if(c == '\n') {
			buff[i] = ' ';
			i++;
		}
		else {
			buff[i] = c;
			i++;
		}
	}
	buff[i] = '\0';
	for (i = strlen(buff); i >= 0; i--) {
		unput(buff[i]);
	}
	free(buff);

	//yylval.string_val = yytext;
	//return WORD;
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
