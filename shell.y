
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

%token <cpp_string> WORD
%token NOTOKEN GREAT NEWLINE GREATGREAT PIPE AMPERSAND GREATAMPERSAND GREATGREATAMPERSAND LESS

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}



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

/*pipe_list:
	pipe_list PIPE command_and_args
	| command_and_args
	;
*/

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

/*iomodifier_list:
  iomodifier_list iomodifier_opt*/
/*|*/ /*empty*/
/*;*/

	/*----end*/
iomodifier_opt:
  GREAT WORD {
    printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    Shell::_currentCommand._outFile = $2;
    //Shell::_currentCommand._append = 0;
  }
  GREATGREAT WORD {
		printf("   Yacc: append output \"%s\"\n", $2->c_str());
	        Shell::_currentCommand._outFile = $2;
		//Shell::_currentCommand._append = 1;
	}
	| GREATGREATAMPERSAND WORD {
	  //Shell::_currentCommand._append = 1;
		printf("   Yacc: append output & \"%s\"\n", $2->c_str());
		Shell::_currentCommand._outFile = $2;
		Shell::_currentCommand._errFile = $2;
	}
	| GREATAMPERSAND WORD {
		printf("   Yacc: insert output & \"%s\"\n", $2->c_str());
		//Shell::_currentCommand._append = 0;
		Shell::_currentCommand._outFile = $2;
		Shell::_currentCommand._errFile = $2;
	}
	| LESS WORD {
		printf("   Yacc: insert input \"%s\"\n", $2->c_str());
		//Shell::_currentCommand._append = 0;
		Shell::_currentCommand._inFile = $2;
	}
  | /* can be empty */ 
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
