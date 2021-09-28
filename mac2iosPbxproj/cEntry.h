//
//  cEntry.h
//  mac2iosPbxproj
//
//  Created by David Riusech on 9/25/21.
//

#ifndef cEntry_h
#define cEntry_h

#include <stdio.h>


void print5(const char* sdkroot, const char* version, const char* project);

int parsePbxproj_internal(const char* project, const char* sdkroot, const char* version, const char* targName, char** depsOutList, char** prodTargPairList);

int patchPbxproj(const char* project, const char* sdkroot, const char* version);
int patchPbxprojTarg(const char* project, const char* sdkroot, const char* version, const char* targName);
int getTargFWDeps(const char* project, const char* targName, char** depsOutList);
int getProjTargPairs(const char* project, char** targProdPairList);
int getNameForProd(char** realName);


#endif /* cEntry_h */
