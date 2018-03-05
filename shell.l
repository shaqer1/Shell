
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
#include <vector>

static void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

bool comparePtrToString(std::string* a, std::string* b) { return a->compare(*b) < 0; }

void expandWildcardsIfNecessary(std::string *prefix, std::string *suffix){
	std::vector<std::string *> array;
	//std::string str (suffix->c_str);
	//here
	expandWildcards(prefix, suffix, array);
	std::sort(array.begin(), array.end(), comparePtrToString);
	// Add arguments
	for (int i = 0; i < array.size(); i++) {
			Command::_currentSimpleCommand->insertArgument(array[i]);
	}
	if(array.size() == 0){
		prefix->append("/");
		char * c = strcat(c, suffix->c_str());
		Command::_currentSimpleCommand->insertArgument(new std::string(c));
	}
}

void expandWildcards(std::string *prefix, std::string *suffix, std::vector<std::string *> & array)
{
// Return if arg does not contain * or ?
	if (suffix != NULL && suffix->size() ==0){
		array.push_back(prefix);
		//Command::_currentSimpleCommand->insertArgument(prefix);
		return;
	}
	int pos = suffix->find("/");
	//pos = (pos == 0 && suffix->find("/",pos+1) != std::string::npos)?suffix->find("/",pos+1):pos;
	std::string * component;
	if(pos != std::string::npos){
		component = new std::string(suffix->substr(0,pos));
		suffix->assign(suffix->substr(pos+1));
	}else{
		component = new std::string(suffix->c_str());
		suffix = new std::string("");
	}
	if(prefix == NULL){
		prefix = new std::string("");
	}

	if(component->find("*") == std::string::npos && component->find("?") == std::string::npos){
		expandWildcards(new std::string(*prefix 
		+ *(new std::string((prefix->compare("/")==0)?"":"/")) 
		+ *component), suffix, array);
		return;
	}
	// 1. Convert wildcard to regular expression
	// Convert “*” -> “.*”
	//“?” -> “.”
	//“.” -> “\.” and others you need
	// Also add ^ at the beginning and $ at the end to match
	// the beginning ant the end of the word.
	// Allocate enough space for regular expression
	int showDots = 0;
	if(component->compare(".*") == 0){
		showDots = 1;
	}
	std::string str;
	str.append("^");
	//str.append(prefix->c_str());
	str.append(component->c_str());
	size_t i=0;
	while(i<str.size()){//TODO: ?? test 7
		if(str[i] == '.'){
			//i = str.find(".", i);
			str.replace(i , 1, "\\.");
			i++;
			//str.replace(i,1,".");
			//i+=2;
		} else if(str[i] == '*'){
			//i = str.find("*", i);
			str.replace(i , 1, ".*");
			//i+=2;
			i++;
		}else if(str[i] == '?'){
			//i = str.find("?", i);
			str.replace(i , 1, ".");
			//i++;
		}
		i++;

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
	char * dir;
	if(prefix->size() == 0){
		dir = (char *) ".";
	}else{
		dir = (char *) prefix->c_str();
	}
	DIR * d = opendir(dir);
	if (d == NULL) {
		perror("opendir");
		return;
	}
	struct dirent * ent;
	while ( (ent = readdir(d))!= NULL) {
		// Check if name matches
		regmatch_t match;
		if (regexec(&re, ent->d_name, 1, &match, 0 ) == 0 && (showDots ||
				(*ent->d_name != '.'))) {//+ *(new std::string("/"))   strcmp(ent->d_name,".") !=0 && strcmp(ent->d_name,"..") != 0
			//TODO: if suffix not empty check if directory
			if(suffix->size()>0 && ent->d_type != DT_DIR){
				continue;
			}
			expandWildcards(
				new std::string(
					*prefix + *(new std::string((prefix->size()==0 || prefix->compare("/")==0)?"":"/")) + *(new std::string(ent->d_name)))
					, suffix, array);//TODO like 53
		}
	}
	closedir(d);
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
