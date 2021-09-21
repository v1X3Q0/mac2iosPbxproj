//
//  main.m
//  mac2iosPbxproj
//
//  Created by David Riusech on 9/18/21.
//

#import <Foundation/Foundation.h>

NSString* sdkroot_g;
NSString* version_g;

void dumpDict(NSDictionary* targDict)
{
    for(id key in targDict)
        NSLog(@"key=%@ value=%@", key, [targDict objectForKey:key]);
}

void parseBuildConfiguration(NSMutableDictionary* objects, NSString* buildConfigurationList, bool isRoot)
{
    NSDictionary* XCConfigurationList = [objects objectForKey:buildConfigurationList];
    NSArray* buildConfigurations = [XCConfigurationList objectForKey:@"buildConfigurations"];
    for (id debRelConfig in buildConfigurations)
    {
        NSDictionary* XCBuildConfiguration = [objects objectForKey:debRelConfig];
        NSMutableDictionary* buildSettings = [XCBuildConfiguration objectForKey:@"buildSettings"];
        NSString* sdkroot = [buildSettings objectForKey:@"SDKROOT"];
        NSString* iphoneDep = [buildSettings objectForKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
        NSString* macDep = [buildSettings objectForKey:@"MACOSX_DEPLOYMENT_TARGET"];
        if (sdkroot != 0)
        {
            [buildSettings removeObjectForKey:@"SDKROOT"];
        }
        if (isRoot)
        {
            [buildSettings setObject:sdkroot_g forKey:@"SDKROOT"];
            //            sdkroot = @"bakaos";
        }
        if (iphoneDep != 0)
        {
            [buildSettings removeObjectForKey:@"IPHONEOS_DEPLOYMENT_TARGET"];
        }
        if (macDep != 0)
        {
            [buildSettings removeObjectForKey:@"MACOSX_DEPLOYMENT_TARGET"];
        }
        if (isRoot)
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
//        dumpDict(objects);
//        NSLog(@"value=%@", [buildSettings objectForKey:@"IPHONEOS_DEPLOYMENT_TARGET"]);
//        NSLog(@"value=%@", [buildSettings objectForKey:@"MACOSX_DEPLOYMENT_TARGET"]);

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

int main(int argc, const char * argv[]) {
//scheme theoretical value $(SOURCE_ROOT)/$(CODE_SIGN_ENTITLEMENTS)
    if (argc != 4)
    {
        printf("usage: %s pbxproj sdk version\n", argv[0]);
        return -1;
    }
    NSString* plistFile = [NSString stringWithUTF8String:argv[1]];
    sdkroot_g = [NSString stringWithUTF8String:argv[2]];
    version_g = [NSString stringWithUTF8String:argv[3]];
    CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:plistFile];
    NSDictionary *theDict = [NSDictionary dictionaryWithContentsOfFile:plistFile];
//    for(id key in theDict)
//        NSLog(@"key=%@ value=%@", key, [theDict objectForKey:key]);

//    NSLog(@"value=%@", [theDict objectForKey:@"rootObject"]);
    
    NSString* rootObjVal = [theDict objectForKey:@"rootObject"];
    NSDictionary* objects = [theDict objectForKey:@"objects"];
    NSDictionary* PBXProject = [objects objectForKey:rootObjVal];
    NSString* buildConfigurationList = [PBXProject objectForKey:@"buildConfigurationList"];
    parseBuildConfiguration(objects, buildConfigurationList, true);
//    dumpDict(objects);
    NSArray* targets = [PBXProject objectForKey:@"targets"];
    
    for (id eachTarg in targets)
    {
        NSDictionary* PBXNativeTarget = [objects objectForKey:eachTarg];
        buildConfigurationList = [PBXNativeTarget objectForKey:@"buildConfigurationList"];
        parseBuildConfiguration(objects, buildConfigurationList, false);
    }

    WriteMyPropertyListToFile((__bridge CFPropertyListRef)theDict, url);
    
    NSLog(@"patched the file %@", plistFile);
    return 0;
}
