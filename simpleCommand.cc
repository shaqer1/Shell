#include <cstdio>
#include <cstdlib>
#include <stdio.h>
#include <iostream>
#include <string.h>
#include "simpleCommand.hh"
#include <limits.h>
#include <unistd.h>

static std::string last_arg;
static int assign = 1;

SimpleCommand::SimpleCommand() {
  _arguments = std::vector<std::string *>();
}

SimpleCommand::~SimpleCommand() {
  // iterate over all the arguments and delete them
  for (auto & arg : _arguments) {
    delete arg;
  }
}

int checkEnvVar(std::string *c){
  if(strcmp(c->c_str(), "SHELL") == 0){
    char * resolved_path = (char *) malloc(PATH_MAX);
    c->assign(realpath("/proc/self/exe", resolved_path));
    return 0;
  }if(strcmp(c->c_str(), "$") == 0){
    c->assign(std::to_string(getpid()));
    return 0;
  }if(strcmp(c->c_str(), "_") == 0){
    c->assign(last_arg);
    return 0;
  }
  return -1;
}

void SimpleCommand::insertArgument( std::string * argument ) {
  if(argument->size() == 0){
    return;
  }
  assign = _arguments.size() > 0;
  if(last_arg == NULL){
    last_arg = *argument;
  }
  if (strchr(argument->c_str(), '$')) {
    //printf("%s\n", argument);
    int i = 0;
    while (i < argument->size()) {
      if (argument->at(i) == '$') {
        i = argument->find('}');
        std::string varName = argument->substr(argument->find('{') +1, i - (argument->find('{') +1));
        int res = checkEnvVar(&varName);
        char * c =  res == -1 ? getenv(varName.c_str()) : (char *) varName.c_str();
        if(c == NULL){
          perror("invalid var");
          exit(0);
        }
        std::string var (c);
        argument->assign(argument->substr(0,argument->find('$')) + var + 
          argument->substr(argument->find("}") +1));
      }
      i++;
    }
    _arguments.push_back(argument);
  } else if (argument->at(0) == '~' && argument->size() == 1) {
    std::string s (strdup(getenv("HOME")));
    _arguments.push_back(&s);
  }else if(argument->at(0) == '~') {
    argument->assign("/homes/" + argument->substr(1));
    _arguments.push_back(argument);
  }else {
    _arguments.push_back(argument);
    if(assign){
      last_arg = *argument;      
    }
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
