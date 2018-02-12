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
#include <sys/types.h>
#include <wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include "command.hh"
#include "shell.hh"


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

void Command::execute() {
    // Don't do anything if there are no simple commands
    if ( _simpleCommands.size() == 0 ) {
        Shell::prompt();
        return;
    }

    	int defaultin = dup( 0 );
	int defaultout = dup( 1 );
	int defaulterr = dup( 2 );
    // Print contents of Command data structure
    //print();

    // Add execution here
    // For every simple command fork a new process
	for (uint i = 0; i < _simpleCommands.size(); i++) {
	  
	  int ret = fork();
		//redirect input
	  if(_inFile){
	    dup2( defaultin, 0 );
	  }
	  /*if(__outFile){
	    dup2( defaultout, 1);
	  }*/
	  if(_errFile){
	    dup2( defaulterr, 2);
	  }
	  if(ret == 0){
	    char *argv[_simpleCommands[i]->_arguments.size() + 1];
	    int j =0;
		close( defaultin );
		close( defaultout );
		close( defaulterr );
	    for(uint k =0; i < _simpleCommands[i]->_arguments.size(); k++){
	      argv[j++] =  _simpleCommands[i]->_arguments[k]->c_str();
	    }
	    argv[j] = NULL;
	    execvp(argv[0], argv);
	    exit(1);
	  }else if(ret < 0){
	    perror("fork");
	    exit(2);
	  }else{
	    waitpid(ret,NULL,0);
	    exit(0);
	  }
	}
    // and call exec

    // Clear to prepare for next command
    clear();

    // Print new prompt
    Shell::prompt();
}

SimpleCommand * Command::_currentSimpleCommand;
