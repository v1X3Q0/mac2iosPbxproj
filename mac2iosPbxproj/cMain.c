//
//  cMain.c
//  mac2iosPbxproj
//
//  Created by David Riusech on 9/25/21.
//

#include <stdio.h>
#include "cEntry.h"
#include <unistd.h>

void print5(const char* sdkroot, const char* version, const char* project)
{
    printf("%s %s %s\n", sdkroot, version, project);
}

int patchPbxproj(const char* project, const char* sdkroot, const char* version)
{
    return parsePbxproj_internal(project, sdkroot, version, NULL, NULL, NULL);
}

int patchPbxprojTarg(const char* project, const char* sdkroot, const char* version, const char* targName)
{
    return parsePbxproj_internal(project, sdkroot, version, targName, NULL, NULL);
}

int getTargFWDeps(const char* project, const char* targName, char** depsOutList)
{
    return parsePbxproj_internal(project, NULL, NULL, targName, depsOutList, NULL);
}

int getProjTargPairs(const char* project, char** targProdPairList)
{
    return parsePbxproj_internal(project, NULL, NULL, NULL, NULL, targProdPairList);
}




int parsePbxproj(const char* project, const char* sdkroot, const char* version, char** depsOutList)
{
//    printf("in %s, sleeping for 1\n", __func__);
//    sleep(1);
    return parsePbxproj_internal(project, sdkroot, version, NULL, NULL, NULL);
}
