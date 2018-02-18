/*
 * CS252: Shell project
 *
 * Template file.
 * You will need to add more code here to execute the command table.
 *
 * NOTE: You are responsible for fixing any bugs this code may have!
 *
 */

#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include <iostream>
#include <signal.h>
#include <string.h>
#include <pwd.h>
#include <sys/types.h>
#include <wait.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <fcntl.h>
#include "command.hh"
//#include "lex.yy.cc"
#include "shell.hh"
#include <stdlib.h>



Command::Command() {
    // Initialize a new vector of Simple Commands
    _simpleCommands = std::vector<SimpleCommand *>();

    _outFile = NULL;
    _inFile = NULL;
    _errFile = NULL;
    _background = false;
}

void Command::insertSimpleCommand( SimpleCommand * simpleCommand ) {
    // add the simple command to the vector
    _simpleCommands.push_back(simpleCommand);
}

void Command::clear() {
    // deallocate all the simple commands in the command vector
    for (auto simpleCommand : _simpleCommands) {
        delete simpleCommand;
    }

    // remove all references to the simple commands we've deallocated
    // (basically just sets the size to 0)
    _simpleCommands.clear();

    if ( _outFile && _outFile != _errFile && _outFile != _inFile) {
        delete _outFile;
    }
    _outFile = NULL;

    if ( _inFile && _inFile != _errFile) {
        delete _inFile;
    }
    _inFile = NULL;

    if ( _errFile ) {
        delete _errFile;
    }
    _errFile = NULL;

    _background = false;
}

void Command::print() {  
    printf("\n\n");
    printf("              COMMAND TABLE                \n");
    printf("\n");
    printf("  #   Simple Commands\n");
    printf("  --- ----------------------------------------------------------\n");

    int i = 0;
    // iterate over the simple commands and print them nicely
    for ( auto & simpleCommand : _simpleCommands ) {
        printf("  %-3d ", i++ );
        simpleCommand->print();
    }

    printf( "\n\n" );
    printf( "  Output       Input        Error        Background\n" );
    printf( "  ------------ ------------ ------------ ------------\n" );
    printf( "  %-12s %-12s %-12s %-12s\n",
            _outFile?_outFile->c_str():"default",
            _inFile?_inFile->c_str():"default",
            _errFile?_errFile->c_str():"default",
            _background?"YES":"NO");
	    printf( "\n\n" );
}
/*
for (;;) {
		
		char s[ 20 ];
		printf( "prompt>");
		fflush( stdout );
		fgets( s, 20, stdin );

		if ( !strcmp( s, "exit\n" ) ) {
			printf( "Bye!\n");
			exit( 1 );
		}
    }
 */
/*extern char ** environ;
extern FILE * yyin;
extern int YY_BUF_SIZE;
extern YY_BUFFER_STATE yy_create_buffer (FILE *file,int size  );
extern void yypush_buffer_state (YY_BUFFER_STATE new_buffer );
extern void yyparse();*/

void Command::execute() {
    // Don't do anything if there are no simple commands
    if ( _simpleCommands.size() == 0 ) {
        Shell::prompt();
        return;
    }
    
    if (_ambiguity) {
      // errno = 0;
      printf("Ambiguous output redirect.\n");
    }
    
    if (!strcmp(_simpleCommands[0]->_arguments[0]->c_str(), "exit")) {
      printf("\nGood Bye!!\n\n");
      exit(0);
    }

    int tmpin=dup(0);
    int tmpout=dup(1);
    int tmperr=dup(2);
//set the initial input
    int fdin;
    if (_inFile) {
      fdin = open(_inFile->c_str(), O_RDONLY, S_IRUSR | S_IRGRP | S_IROTH);
    } else {
      // Use default input
      fdin=dup(tmpin);
    }
    int ret;
    int fdout,fderr;
    // Print contents of Command data structure
    //print();

    // Add execution here
    // For every simple command fork a new process
	for (uint i = 0; i < _simpleCommands.size(); i++){
	  dup2(fdin, 0);
	  close(fdin);
	  if (i == _simpleCommands.size()-1){
	    // Last simple command
	    if(_outFile){
	      if(_append) {//does not work here
		fdout = open(_outFile->c_str(), O_WRONLY | O_APPEND | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP);
	      }
	      else {//works here// work for >
		fdout = open(_outFile->c_str(), O_WRONLY | O_TRUNC | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP);
	      }
	    }
	    else {
	      // Use default output
	      fdout=dup(tmpout);
	    }
	    if (_errFile) {
	      if (_append) {
		fderr = open(_errFile->c_str(), O_WRONLY | O_APPEND | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP);
	      }
	      else {
		fderr = open(_errFile->c_str(), O_WRONLY | O_TRUNC | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP);
	      }
	    }
	    else {
	      //use default error
	      fderr = dup(tmperr);
	    }
	    dup2(fderr, 2);
	    close(fderr);
	  }else {
	    // Not last
	    //simple command
	    //create pipe
	    int fdpipe[2];
	    pipe(fdpipe);
	    fdout=fdpipe[1];
	    fdin=fdpipe[0];
	  }// if/else
	  // Redirect output
	  dup2(fdout,1);
	  close(fdout);

      if ( !strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "source") ) {
            FILE * myin = fopen(_simpleCommands[i]->_arguments[1]->c_str(), "r");
            if (myin == NULL) {
                clear();
                Shell::prompt();
                return;
            }
            /*yyin = myin;
            clear();
            fflush(stdout);
            yypush_buffer_state(yy_create_buffer(yyin, YY_BUF_SIZE));
            yyparse();
            yypop_buffer_state();
            yyparse();
            Shell::prompt();*/
            return;
        }

      if (!strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "cd")){
            int error = 0;
            if (_simpleCommands[i]->_arguments.size() > 1) {
                error = chdir(_simpleCommands[i]->_arguments[1]->c_str());
            }
            else {
                //chdir($HOME);
                chdir(getenv("HOME"));
            }
            if (error == -1) {
                //printf("");
                std::string s ("cd: " +  _simpleCommands[i]->_arguments[1] +": No such file or directory \n");
                perror(s.c_str());
                //error should go to error file
                //perror(_simpleCommands[i]->_arguments[1]->c_str());
            }
            continue;
        }
        //implement set environment variable
        else if (!strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "setenv")) {
            if(_simpleCommands[i]->_arguments.size() != 3) {
                printf("Usage: setenv arg1 arg2 \n");
                continue;
            }
            setenv(_simpleCommands[i]->_arguments[1]->c_str(), _simpleCommands[i]->_arguments[2]->c_str(), 1); //the one is for overwriting
            continue;
        }
        //implement unsetting an evironment variable
        else if (!strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "unsetenv")) {
            if(_simpleCommands[i]->_arguments.size() != 2) {
                printf("Usage: unsetenv arg1 \n");
                continue;
            }
            unsetenv(_simpleCommands[i]->_arguments[1]->c_str());
            continue;
        }
        //implement printing of environment variables
        else if (!strcmp(_simpleCommands[i]->_arguments[0]->c_str(), "printenv")) {
            ret = fork();
            if (ret == 0) {
                char **p = environ;
                while (*p != NULL) {
                    printf("%s\n", *p);
                    p++;
                }
                exit(0);
            }
            else if (ret < 0) {
                perror("fork");
                exit(1);
            }
            continue;
        }

	  // ret = fork();
	  ret = fork();
	  //printf("%d",ret);
	  if(ret == 0){
	    //printf("Yass jesus %d", ret);
	    char *argv[_simpleCommands[i]->_arguments.size() + 1];
	    size_t k;
	      for(k =0; k < _simpleCommands[i]->_arguments.size(); k++){
		argv[k] =  (char *) _simpleCommands[i]->_arguments[k]->c_str();
	      }
		argv[k] = NULL;
		execvp(_simpleCommands[i]->_arguments[0]->c_str(), argv);
		exit(1);
	  }else if(ret < 0){
	    perror("fork");
	    exit(1);
	  }
	}
	
	dup2(tmpin,0);
        dup2(tmpout,1);
	close(tmpin);
        close(tmpout);
	if(!_background){
	  waitpid(ret,NULL,0);
	}
    // and call exec

    // Clear to prepare for next command
    clear();

    // Print new prompt
    Shell::prompt();
}

SimpleCommand * Command::_currentSimpleCommand;
