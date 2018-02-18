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
  std::string complete;
  if (strchr(argument->c_str(), '$')) {
    //printf("%s\n", argument);
    int i = 0;
    while (argument->at(i) != '\0') {
      if (argument->at(i) == '$') {
        i = argument->find('}');
        std::string varName = argument->substr(argument->find('{') +1, i);
        argument->assign(argument->substr(0,argument->find('{')) + varName + 
          argument->substr(argument->find("}" +1)));

        //printf("varname <= ");
        /*while (argument->at(i) != '}') {
          varName[j] = argument->at(i);
          //printf("%c ", argument[i]);
          j++;
          i++;
        }
        varName[j] = '\0';
        //printf("\n  varName: %s\n", varName);
        if (getenv(varName)) {
          complete.append(getenv(varName));
        }
        j = 0;
        free(varName);*/
      }
      i++;
    }
    argument->assign(complete);
    _arguments.push_back(argument);
  } else if (argument->at(0) == '~' && argument->size() == 1) {
    std::string s (strdup(getenv("HOME")));
    _arguments.push_back(*s);
  }else if(argument->at(0) == '~') {
    argument->assign(argument->substr("/homes/" + argument->substr(1))); //get rid of ~
    //printf("%s\n", s);
    //printf("%s\n",complete);
    _arguments.push_back(argument);
  }else {
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
