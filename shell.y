
/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{
#include <string>

extern "C" void expandWildcardsIfNecessary(std::string *s);

#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <cpp_string> WORD
%token NOTOKEN GREAT NEWLINE GREATGREAT PIPE AMPERSAND GREATAMPERSAND GREATGREATAMPERSAND LESS TWOGREAT

%{
//#define yylex yylex
#include <cstdio>
#include "shell.hh"

extern FILE * yyin;
void yyerror(const char * s);
int yylex();

%}

%%

goal:
  command_list
  ;
command_line:
  pipe_list io_modifier_list background_optional NEWLINE {
    //printf("   Yacc: Execute command\n"); 
		Shell::_currentCommand.execute();
	}
  | NEWLINE
  | error NEWLINE{yyerrok;}
command_list:
  command |
  command_list command
  ; /* command loop*/
pipe_list:
	pipe_list PIPE command_and_args
	| command_and_args
	;
command: command_line
;
/*
simple_command:	
  command_and_args iomodifier_opt NEWLINE {
    printf("   Yacc: Execute command\n");
    Shell::_currentCommand.execute();
  }
  | NEWLINE 
  | error NEWLINE { yyerrok; }
  ;
*/
command_and_args:
  command_word argument_list {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

command_word:
  WORD {
    //printf("   Yacc: insert command \"%s\"\n", $1->c_str());
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

argument_list:
argument_list argument
  | /* can be empty */
  ;

argument:
  WORD {
    //printf("   Yacc: insert argument \"%s\"\n", $1->c_str());
    //expandWildcardsIfNecessary($1);
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

io_modifier_list:
  io_modifier_list io_modifier
  | /*empty*/
  ;
background_optional:
  AMPERSAND{
    Shell::_currentCommand._background = 1;
  }
 | /*empty*/
 ;
io_modifier:
  GREAT WORD {
    if (Shell::_currentCommand._outFile != 0) {
      Shell::_currentCommand._ambiguity = 1;
    }
    //printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._append = 0;
  }
  | TWOGREAT WORD{
    if (Shell::_currentCommand._outFile != 0) {
      Shell::_currentCommand._ambiguity = 1;
    }
    Shell::_currentCommand._errFile = $2;
    Shell::_currentCommand._append = 1;
  }
  | GREATGREAT WORD{
    if (Shell::_currentCommand._outFile != 0) {
      Shell::_currentCommand._ambiguity = 1;
    }
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._append = 1;    
  }
  | GREATGREATAMPERSAND WORD{
    if (Shell::_currentCommand._outFile != 0) {
      Shell::_currentCommand._ambiguity = 1;
    }
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;
    Shell::_currentCommand._append = 1;
  }
  | GREATAMPERSAND WORD{
    if (Shell::_currentCommand._outFile != 0) {
      Shell::_currentCommand._ambiguity = 1;
    }
    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;  
    Shell::_currentCommand._append = 0;  
  }
  | LESS WORD{
    if (Shell::_currentCommand._inFile != 0) {
      Shell::_currentCommand._ambiguity = 1;
    }
    Shell::_currentCommand._inFile = $2;
    Shell::_currentCommand._append = 0;
  }
  ;

%%

void
yyerror(const char * s)
{
  fprintf(stderr,"%s", s);
}

#if 0
main()
{
  
  yin = fopen(".shellrc", "r");
    if (yyin > 0) {
        yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));
        yyparse();
        yyin = stdin;
        yy_switch_to_buffer(yy_create_buffer(yyin, YY_BUF_SIZE));
        yyparse();
    } else{
        yyin = NULL;
        yyparse();
    }
}
#endif
