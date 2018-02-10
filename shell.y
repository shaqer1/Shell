
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
%token NOTOKEN GREAT NEWLINE GREATGREAT PIPE LESS AMPER GREATAMPERSAND GREATGREATAMPERSAND

%{
//#define yylex yylex
#include <cstdio>
#include "shell.hh"

void yyerror(const char * s);
int yylex();

%}

%%

goal:
  commands
  ;

commands:
  command
  | commands command
  ;

command: simple_command
       ;

simple_command:	
  command_and_args iomodifier_opt NEWLINE {
    printf("   Yacc: Execute command\n");
    Shell::_currentCommand.execute();
  }
  | NEWLINE 
  | error NEWLINE { yyerrok; }
  ;
pipe_list:
	pipe_list PIPE command_and_args
	| command_and_args
	;

command_and_args:
  command_word argument_list {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

argument_list:
  argument_list argument
  | /* can be empty */
  ;

argument:
  WORD {
    printf("   Yacc: insert argument \"%s\"\n", $1->c_str());
    Command::_currentSimpleCommand->insertArgument( $1 );\
  }
  ;

command_word:
  WORD {
    printf("   Yacc: insert command \"%s\"\n", $1->c_str());
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

iomodifier_list:
	iomodifier_list iomodifier_opt
	| /*empty*/
	;

iomodifier_opt:
  GREATGREAT WORD {
		/* printf("   Yacc: append output \"%s\"\n", $2); */
		if (Command::_currentCommand._outFile != 0) {
			Command::_currentCommand._ambiguity = 1;
		}
		Command::_currentCommand._append = 1;
		Command::_currentCommand._outFile = $2;
	}
	| GREAT WORD {
		/* printf("   Yacc: insert output \"%s\"\n", $2); */
		if (Command::_currentCommand._outFile != 0) {
			Command::_currentCommand._ambiguity = 1;
		}
		Command::_currentCommand._append = 0;
		Command::_currentCommand._outFile = $2;
	}
	| GREATGREATAMPERSAND WORD {
		/* printf("   Yacc: append output & \"%s\"\n", $2); */
		if (Command::_currentCommand._outFile != 0) {
			Command::_currentCommand._ambiguity = 1;
		}
		Command::_currentCommand._append = 1;
		Command::_currentCommand._outFile = $2;
		Command::_currentCommand._errFile = $2;
	}
	| GREATAMPERSAND WORD {
		/* printf("   Yacc: insert output & \"%s\"\n", $2); */
		if (Command::_currentCommand._outFile != 0) {
			Command::_currentCommand._ambiguity = 1;
		}
		Command::_currentCommand._append = 0;
		Command::_currentCommand._outFile = $2;
		Command::_currentCommand._errFile = $2;
	}
	| LESS WORD {
		if (Command::_currentCommand._inFile != 0) {
			Command::_currentCommand._ambiguity = 1;
		}
		/* printf("   Yacc: insert input \"%s\"\n", $2); */
		Command::_currentCommand._append = 0;
		Command::_currentCommand._inFile = $2;
	}
	/*|  can be empty */ 
	;

	background_optional:
	AMPERSAND {
		Command::_currentCommand._background = 1;
	}
	| /*empty*/
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
  yyparse();
}
#endif
