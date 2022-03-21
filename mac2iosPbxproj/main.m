//
//  main.m
//  mac2iosPbxproj
//
//  Created by David Riusech on 9/18/21.
//

#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

#import <Foundation/Foundation.h>
#import "XMLReader.h"

NSString* sdkroot_g;
NSString* version_g;

NSString* proj_sdkroot_g;
NSString* proj_version_g;

typedef enum targetType
{
    ROOT_NODE=1,
    NON_ROOT_NODE,
    SPEC_NODE,
    REM_SUPPORT
} targetType_t;

typedef enum
{
    CLEAN_SDK=0,
    ADD_HEADER
} buildsettingOp_t;

void dumpDict(NSDictionary* targDict)
{
    for(id key in targDict)
        NSLog(@"key=%@ value=%@", key, [targDict objectForKey:key]);
}

void cleanSdk(targetType_t isRoot, NSString* productType, NSMutableDictionary* buildSettings)
{
//        save the pbxproj's sdkroot and deployment target
    NSString* sdkroot = [buildSettings objectForKey:@"SDKROOT"];
    NSString* iphoneDep = [buildSettings objectForKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
    NSString* macDep = [buildSettings objectForKey:@"MACOSX_DEPLOYMENT_TARGET"];
//    (([productType isEqualToString:@"com.apple.product-type.application"] == true) && (iphoneDep == 0));
//    (([productType isEqualToString:@"com.apple.product-type.tool"] == true) && (macDep == 0));

    bool isApp = [productType isEqualToString:@"com.apple.product-type.application"];
    bool isTool = [productType isEqualToString:@"com.apple.product-type.tool"];

    [buildSettings removeObjectForKey:@"SUPPORTED_PLATFORMS"];
    if (isRoot == REM_SUPPORT)
    {
        continue;
    }
    
    if (isRoot == ROOT_NODE)
    {
        proj_sdkroot_g = sdkroot;
        if (iphoneDep != 0)
        {
            proj_version_g = iphoneDep;
        }
        if (macDep != 0)
        {
            proj_version_g = macDep;
        }
    }
//    remove the sdkroot if we have found it, we are not pbxproject, we are not an application or tool,
//        and it does not match with the current one found.
    if (isRoot == NON_ROOT_NODE)
    {
        if (sdkroot != 0)
        {
            if ((isApp == false) && (isTool == false))
            {
                [buildSettings removeObjectForKey:@"SDKROOT"];
            }
        }
    }
//    add the new sdkroot if
//        am pbxproject and sdkroot does not match,
    if (isRoot == ROOT_NODE)
    {
        [buildSettings setObject:sdkroot_g forKey:@"SDKROOT"];
    }
    else if ((isRoot == NON_ROOT_NODE) || (isRoot == SPEC_NODE))
    {
//    preserve the sdkroot if
//        couldn't find sdkroot and:
//            you're an application and newTarget is mac,
//            or you're a tool and newTarget is iphoneos
        if ((isRoot == SPEC_NODE) || (sdkroot == 0))
        {
            if (isApp == true)
            {
                [buildSettings setObject:@"iphoneos" forKey:@"SDKROOT"];
            }
            else if (isTool == true)
            {
                [buildSettings setObject:@"macosx" forKey:@"SDKROOT"];
            }
            else
            {
                [buildSettings setObject:sdkroot_g forKey:@"SDKROOT"];
            }
        }
    }

    if (isRoot == ROOT_NODE)
    {
        if ([sdkroot_g isEqualToString:@"macosx"] == true)
        {
            [buildSettings removeObjectForKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
        }
        else if ([sdkroot_g isEqualToString:@"iphoneos"] == false)
        {
            [buildSettings removeObjectForKey:@"MACOSX_DEPLOYMENT_TARGET"];
        }
    }
    else if ((isRoot == NON_ROOT_NODE) || (isRoot == SPEC_NODE))
    {
//        we wanna remove the key key if we found it,
//            we are not an app and we are not a tool
//            we have a different version
        if ((isApp == false) && (isTool == false))
        {
//                    the iphone version dependency doesn't match
            [buildSettings removeObjectForKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
            [buildSettings removeObjectForKey:@"MACOSX_DEPLOYMENT_TARGET"];
        }

    }
//        we wanna add the replacement if we are root
//        or we are an app or tool
    if (isRoot == ROOT_NODE)
    {
        if ([sdkroot_g isEqualToString:@"iphoneos"] == true)
        {
            [buildSettings setObject:version_g forKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
        }
        else if ([sdkroot_g isEqualToString:@"macosx"] == true)
        {
            [buildSettings setObject:version_g forKey:@"MACOSX_DEPLOYMENT_TARGET"];
        }
    }
    else
    {
        if (isApp == true)
        {
            if ([sdkroot_g isEqualToString:@"iphoneos"] == true)
            {
                [buildSettings setObject:version_g forKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
            }
            else if ([sdkroot_g isEqualToString:@"macosx"] == true)
            {
                if (iphoneDep == 0)
                {
                    [buildSettings setObject:proj_version_g forKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
                }
            }
        }
        else if (isTool == true)
        {
            if ([sdkroot_g isEqualToString:@"macosx"] == true)
            {
                [buildSettings setObject:version_g forKey:@"MACOSX_DEPLOYMENT_TARGET"];
            }
            else if ([sdkroot_g isEqualToString:@"iphoneos"] == true)
            {
                if (macDep == 0)
                {
                    [buildSettings setObject:proj_version_g forKey:@"MACOSX_DEPLOYMENT_TARGET"];
                }
            }
        }
        else if (isRoot == SPEC_NODE)
        {
            if ([sdkroot_g isEqualToString:@"iphoneos"] == true)
            {
                [buildSettings setObject:version_g forKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
            }
            else if ([sdkroot_g isEqualToString:@"macosx"] == true)
            {
                [buildSettings setObject:version_g forKey:@"MACOSX_DEPLOYMENT_TARGET"];
            }
        }
    }
}

void parseBuildConfiguration(NSMutableDictionary* objects, NSString* buildConfigurationList, targetType_t isRoot, NSString* productType, buildsettingOp_t buildsettingOp)
{
    NSDictionary* XCConfigurationList = [objects objectForKey:buildConfigurationList];
    NSArray* buildConfigurations = [XCConfigurationList objectForKey:@"buildConfigurations"];
    for (id debRelConfig in buildConfigurations)
    {
        NSDictionary* XCBuildConfiguration = [objects objectForKey:debRelConfig];
        NSMutableDictionary* buildSettings = [XCBuildConfiguration objectForKey:@"buildSettings"];
        
        switch (buildsettingOp)
        {
            case CLEAN_SDK:
                cleanSdk(isRoot, productType, buildSettings);
                break;
            case ADD_HEADER:
//                addHeader;
                break;
        }
    }
}

void WriteMyPropertyListToFile( CFPropertyListRef propertyList,
            CFURLRef fileURL ) {
   CFDataRef xmlData;
   Boolean status;
   SInt32 errorCode;
 
   // Convert the property list into XML data.
   xmlData = CFPropertyListCreateXMLData( kCFAllocatorDefault, propertyList );
 
   // Write the XML data to the file.
   status = CFURLWriteDataAndPropertiesToResource (
               fileURL,                  // URL to use
               xmlData,                  // data to write
               NULL,
               &errorCode);
 
   CFRelease(xmlData);
}

// -1 if found
int checkStr( char** depListOut, char* depRaw)
{
    int result = -1;
    int i = 0;
    
    for (i = 0; i < 100; i++)
    {
        if (depListOut[i] == 0)
        {
            break;
        }
        if (strcmp(depListOut[i], depRaw) == 0)
        {
            goto fail;
        }
        
    }
    
    result = 0;
fail:
    return result;
}

int grabProjDeps(NSMutableDictionary* objects, NSDictionary* PBXNativeTarget, char** depListOut)
{
    int result = -1;
    size_t depsIter = 0;
    char* depRaw = 0;
    char* depRawOut = 0;

//        grab the dependencies
    NSArray* buildPhases = [PBXNativeTarget objectForKey:@"buildPhases"];
    for (id eachPhase in buildPhases)
    {
        NSDictionary* buildPhase = [objects objectForKey:eachPhase];
        NSString* isa = [buildPhase objectForKey:@"isa"];
        if ([isa isEqualToString:@"PBXFrameworksBuildPhase"] == true)
        {
            NSArray* depFiles = [buildPhase objectForKey:@"files"];
            for (id eachDependency in depFiles)
            {
                NSDictionary* fileGlob = [objects objectForKey:eachDependency];
                NSString* fileGlobRefStr = [fileGlob objectForKey:@"fileRef"];
                NSDictionary* fileGlobRef = [objects objectForKey:fileGlobRefStr];
                NSString* fileGlobName = [fileGlobRef objectForKey:@"path"];
                if (depListOut != NULL)
                {
                    depRaw = (char*)[fileGlobName UTF8String];
                    if (checkStr(depListOut, depRaw) == 0)
                    {
                        depRawOut = malloc(strlen(depRaw));
                        strcpy(depRawOut, depRaw);
                        depListOut[depsIter] = depRawOut;
                        depsIter++;
                    }
                }
//                    NSLog(@"found the dependency %@", fileGlobName);
            }
        }
    }
    return result;
}

int grabTargName(NSMutableDictionary* objects, NSDictionary* PBXNativeTarget, char** prodListOut)
{
    int result = -1;
    char* prodNameOut = 0;
    char* prodNameRaw = 0;
    
    NSString* prodName = [PBXNativeTarget objectForKey:@"productName"];
    prodNameRaw = (char*)[prodName UTF8String];

    prodNameOut = malloc(strlen(prodNameRaw));
    strcpy(prodNameOut, prodNameRaw);
    *prodListOut = prodNameOut;

    result = 0;
    return result;
}

int grabProdName(NSMutableDictionary* objects, NSDictionary* PBXNativeTarget, char** prodListOut)
{
    int result = -1;
    char* prodNameOut = 0;
    char* prodNameRaw = 0;

    NSString* productReference = [PBXNativeTarget objectForKey:@"productReference"];
    NSDictionary* fileGlobRef = [objects objectForKey:productReference];
    NSString* pathName = [fileGlobRef objectForKey:@"path"];
    prodNameRaw = (char*)[pathName UTF8String];

    prodNameOut = malloc(strlen(prodNameRaw));
    strcpy(prodNameOut, prodNameRaw);
    *prodListOut = prodNameOut;

    return result;
}

int parseWorkspace(NSString* xmlFile)
{
    int result = -1;
    NSError *error = nil;

    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:xmlFile];
    NSDictionary *theDict = [NSDictionary dictionaryWithContentsOfFile:xmlFile];

    NSData *data = [NSData dataWithContentsOfFile:xmlFile];
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDictionary *_xmlDictionary = [XMLReader dictionaryForXMLString:s error:&error];

    return result;
}

int parsePbxproj_internal(const char* project, const char* sdkroot, const char* version, const char* targName, char** depsOutList, char** prodTargPairList)
{
    int result = -1;
    size_t prodTargIter = 0;
    char* prodNameOut = 0;
    char* prodNameRaw = 0;
    NSString* targNameO;

    if (targName != 0)
    {
        targNameO = [NSString stringWithUTF8String:targName];
    }

    if (sdkroot != 0)
    {
        sdkroot_g = [NSString stringWithUTF8String:sdkroot];
        version_g = [NSString stringWithUTF8String:version];
    }
    
    NSString* plistFile = [NSString stringWithUTF8String:project];

    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:plistFile];
    NSDictionary *theDict = [NSDictionary dictionaryWithContentsOfFile:plistFile];
//    for(id key in theDict)
//        NSLog(@"key=%@ value=%@", key, [theDict objectForKey:key]);

//    NSLog(@"value=%@", [theDict objectForKey:@"rootObject"]);
    
    NSString* rootObjVal = [theDict objectForKey:@"rootObject"];
    NSMutableDictionary* objects = [theDict objectForKey:@"objects"];
    NSDictionary* PBXProject = [objects objectForKey:rootObjVal];
    NSString* buildConfigurationList = [PBXProject objectForKey:@"buildConfigurationList"];
//    parent project, don't care if we fuck it up
    if (sdkroot != 0)
    {
        if (targName == 0)
        {
            parseBuildConfiguration(objects, buildConfigurationList, ROOT_NODE, NULL);
        }
        else
        {
            parseBuildConfiguration(objects, buildConfigurationList, REM_SUPPORT, NULL);
        }
    }
//    dumpDict(objects);
    NSArray* targets = [PBXProject objectForKey:@"targets"];
    
    for (id eachTarg in targets)
    {
//        each target object is a key for a PBXNativeTarget
        NSDictionary* PBXNativeTarget = [objects objectForKey:eachTarg];
        
//        each native target has a product type, tool, application, lib, etc.
        NSString* productType = [PBXNativeTarget objectForKey:@"productType"];
        
//        each target has a configurationlist, which has the target device info
        buildConfigurationList = [PBXNativeTarget objectForKey:@"buildConfigurationList"];
//        child project, lets mod it a bit
        
        NSString* prodName = [PBXNativeTarget objectForKey:@"name"];

        if (sdkroot != 0)
        {
            if (targName == 0)
            {
                parseBuildConfiguration(objects, buildConfigurationList, NON_ROOT_NODE, productType);
            }
            else if ([prodName isEqualToString: targNameO] == true)
            {
                parseBuildConfiguration(objects, buildConfigurationList, SPEC_NODE, productType);
            }
        }

        if (prodTargPairList != 0)
        {
            prodNameRaw = (char*)[prodName UTF8String];
            prodNameOut = malloc(strlen(prodNameRaw));
            strcpy(prodNameOut, prodNameRaw);
            prodTargPairList[prodTargIter] = prodNameOut;
            prodTargIter++;
            
            grabProdName(objects, PBXNativeTarget, &prodTargPairList[prodTargIter]);
            prodTargIter++;
        }
        
        if ((depsOutList != 0) && (targName != 0))
        {
            if ([prodName isEqualToString: targNameO])
            {
                grabProjDeps(objects, PBXNativeTarget, depsOutList);
            }
        }
    }

    if (sdkroot != 0)
    {
        WriteMyPropertyListToFile((__bridge CFPropertyListRef)theDict, url);
        NSLog(@"patched the file %@", plistFile);

    }
        
    result = 0;
    
    return result;
}
