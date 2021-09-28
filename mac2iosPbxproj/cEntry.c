//
//  cEntry.c
//  mac2iosPbxproj
//
//  Created by David Riusech on 9/25/21.
//

#include "cEntry.h"
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>

#define ASSUMED_MAX 100

void printUsage(const char* argv0)
{
    fprintf(stderr, "Usage: %s [-p workspace] [-p project] [-s scheme] sdkroot version\n",
            argv0);
}

int main(int argc, const char * argv[]) {
//scheme theoretical value $(SOURCE_ROOT)/$(CODE_SIGN_ENTITLEMENTS)
    
    int opt = 0;
    const char* workspace = 0;
    const char* project = 0;
    char* scheme = 0;
    const char* sdkroot = 0;
    const char* version = 0;
    char** depsListOut = 0;
    char** prodTargListOut = 0;

    while ((opt = getopt(argc, argv, "w:p:s:dlk:v:")) != -1) {
        switch (opt) {
        case 'w':
            workspace = optarg;
            break;
        case 'p':
            project = optarg;
            break;
        case 's':
            scheme = optarg;
            break;
        case 'd':
            depsListOut = calloc(ASSUMED_MAX, sizeof(char*));
            break;
        case 'l':
            prodTargListOut = calloc(ASSUMED_MAX, sizeof(char*) * 2);
            break;
        case 'k':
            sdkroot = optarg;
            break;
        case 'v':
            version = optarg;
            break;
        default: /* '?' */
            printUsage(argv[0]);
            exit(EXIT_FAILURE);
        }
    }
    
//    if ((argc - optind) < 2)
//    {
//        printUsage(argv[0]);
//    }
    
    if (workspace != 0)
    {
        printf("workspace code not supported for objective c");
//        parseWorkspace([NSString stringWithUTF8String:workspace]);
    }
    
    //    if (optind < argc) {
    //        printf("non-option ARGV-elements: ");
    //        while (optind < argc)
    //            printf("%s ", argv[optind++]);
    //        printf("\n");
    //    }

//    sdkroot = argv[optind++];
//    version = argv[optind++];
    parsePbxproj_internal(project, sdkroot, version, scheme, depsListOut, prodTargListOut);
    if (prodTargListOut != 0)
    {
        for (int i = 0; i < ASSUMED_MAX; i++)
        {
            if (prodTargListOut[i] == 0)
            {
                break;
            }
            if (i % 2 == 0)
            {
                printf("\n");
            }
            printf("%s ", prodTargListOut[i]);
        }
    }
//    parsePbxproj(sdkroot, version, project, NULL);
    
    return 0;
}
