#include <cstdio>
#include <cstdlib>
#include <stdio.h>
#include <iostream>
#include <string.h>
#include "simpleCommand.hh"

SimpleCommand::SimpleCommand() {
  _arguments = std::vector<std::string *>();
}

SimpleCommand::~SimpleCommand() {
  // iterate over all the arguments and delete them
  for (auto & arg : _arguments) {
    delete arg;
  }
}

void SimpleCommand::insertArgument( std::string * argument ) {
  // simply add the argument to the vector
  //implement env var expansion
  char * complete = (char *)calloc(2048, sizeof(char));
  if (strchr(argument->c_str(), '$')) {
    //printf("%s\n", argument);
    int i = 0;
    int j = 0;
    while (argument->at(i) != '\0') {
      if (argument->at(i) == '$') {
        char * varName = (char *)calloc(2048, sizeof(char));
        i += 2;
        //printf("varname <= ");
        while (argument->at(i) != '}') {
          varName[j] = argument->at(i);
          //printf("%c ", argument[i]);
          j++;
          i++;
        }
        varName[j] = '\0';
        //printf("\n  varName: %s\n", varName);
        if (getenv(varName)) {
          strcat(complete, getenv(varName));
        }
        j = 0;
        free(varName);
      }
      else {
        char * others = (char *)calloc(2048, sizeof(char));
        //printf("others <= ");
        while (argument->at(i) != '\0' && argument->at(i) != '$') {
          others[j] = argument->at(i);
          //printf("%c ", argument[i]);
          j++;
          i++;
        }
        //printf("\n  others: %s\n", others);
        strcat(complete, others);
        j = 0;
        free(others);
        i--;
      }
      i++;
    }
    argument = (strdup(complete));
    _arguments.push_back(argument);
  }

  //implement tilde expansion
  else if (argument->at(0) == '~' && argument->size() == 1) {
    _arguments.push_back(strdup(getenv("HOME")));
    //printf("%s\n", _arguments[ _numOfArguments ]);
  }
  else if(argument->at(0) == '~') {
    char * s = argument->substr (1)->c_str(); //get rid of ~
    //printf("%s\n", s);
    const char * homes = "/homes/";
    char * complete = (char *) calloc((strlen(s) + 7), sizeof(char));
    strcat(complete, homes);
    strcat(complete, s);
    //printf("%s\n",complete);
    _arguments.push_back(complete);
  }
  //default without expansion
  else {
    _arguments.push_back(argument);
    //printf("%s\n", argument);
  }
}

// Print out the simple command
void SimpleCommand::print() {
  for (auto & arg : _arguments) {
    std::cout << "\"" << arg << "\" \t";
  }
  // effectively the same as printf("\n\n");
  std::cout << std::endl;
}
