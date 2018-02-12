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

    int tmpin=dup(0);
    int tmpout=dup(1);
//set the initial input
    int fdin;
    if (_inFile) {
      fdin = open(_inFile, O_RDONLY, S_IRUSR | S_IRGRP | S_IROTH);
    } else {
      // Use default input
      fdin=dup(tmpin);
    }
    int ret;
    int fdout;
    // Print contents of Command data structure
    //print();

    // Add execution here
    // For every simple command fork a new process
	for (uint i = 0; i < _simpleCommands.size(); i++) {
	  dup2(fdin, 0);
	  close(fdin);
	  if (i == _simpleCommands.size()-1){
	    // Last simple command
	    if(_outFile){
	      if(_append) {//does not work here
		fdout = open(_outFile, O_WRONLY | O_APPEND | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP);
	      }
	      else {//works here// work for >
		fdout = open(_outFile, O_WRONLY | O_TRUNC | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP);
	      }
	    }
	    else {
	      // Use default output
	      fdout=dup(tmpout);
	    }
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
	  ret = fork();
	  if(ret == 0){
	    char *argv[_simpleCommands[i]->_arguments.size() + 1];
	    int j =0;
	      for(uint k =0; i < _simpleCommands[i]->_arguments.size(); k++){
		*argv =  (char *) _simpleCommands[i]->_arguments[k]->c_str();
	      }
		argv[j] = NULL;
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
