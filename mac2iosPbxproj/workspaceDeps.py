from bs4 import BeautifulSoup
import sys
import argparse
import os
import subprocess
import ctypes
import pathlib

# filename, file_extension = os.path.splitext('/path/to/somefile.ext')
libname = "/Users/mariomain/Library/Developer/Xcode/DerivedData/mac2iosPbxproj-aepknkejeqyaxwdwopsdkajuicxb/Build/Products/Debug/libmac2iosPbxproj.dylib"
c_lib = ctypes.CDLL(libname)

xcodeprojList = []

class xcodeproj_t:
    def __init__(self, xcodeproj_a, targ_a, product_a):
        self.xcodeproj = xcodeproj_a
        self.targ = targ_a
        self.product = product_a
    def dump(self):
        print(self.xcodeproj, self.targ, self.product)    

parser = argparse.ArgumentParser(description='Fix variables of workspace or project.')
parser.add_argument('--workspace', '-w', required=True,
                    help='target workspace')
parser.add_argument('--project', '-p',
                    help='target project')
parser.add_argument('--scheme', '-s',
                    help='target scheme')
parser.add_argument('--deps', '-d', action="store_true",
                    help='target dependencies')

parser.add_argument('--build', '-b',
                    help='build scheme')

parser.add_argument('--sdk', nargs=2,
                    help='patch the sdk of a project and its dependencies')

parser.add_argument('--list', '-l', action="store_true",
                    help='list all projects, targets and products')

args = parser.parse_args()

def dumpXcodeprojList():
    for i in xcodeprojList:
        i.dump()

def populateXcodeprojList(bsxml, wsPath):
    global xcodeprojList
    for groups in bsxml.Workspace.find_all("Group"):
        for filerefs in groups.find_all("FileRef"):
            fileRefLocation = filerefs["location"].replace("group:", "")
            projName, projExtension = os.path.splitext(fileRefLocation)
            if projExtension == ".xcodeproj":
                projAbsPath = "{}/{}".format(os.path.dirname(wsPath), fileRefLocation)
                projCtype = ctypes.c_char_p(bytes("{}/{}".format(projAbsPath, "project.pbxproj"), 'utf-8'))
                targsArray = (ctypes.c_char_p * 200)()
                targsCtype = ctypes.cast(targsArray, ctypes.POINTER(ctypes.c_char_p))
                c_lib.getProjTargPairs(projCtype, targsCtype)
                iterIndex = 0
                targName = ""
                prodName = ""
                for targetL in targsCtype:
                    if targetL == None:
                        break
                    if (iterIndex % 2 == 0):
                        if (targName != ""):
                            xcodeprojList.append(xcodeproj_t(projAbsPath, targName, prodName))
                        targName = targetL.decode('utf-8')
                    elif iterIndex % 2 == 1:
                        prodName = targetL.decode('utf-8')
                    iterIndex += 1
                if (iterIndex % 2 == 0) and (targName != ""):
                    xcodeprojList.append(xcodeproj_t(projAbsPath, targName, prodName))
                # print(targetL.decode('utf-8'))

def getDepsList(projObject):
    depsListOut = []
    projCtype = ctypes.c_char_p(bytes("{}/{}".format(projObject.xcodeproj, "project.pbxproj"), 'utf-8'))
    targCtype = ctypes.c_char_p(bytes(projObject.targ, 'utf-8'))
    depsArray = (ctypes.c_char_p * 100)()
    depsCtype = ctypes.cast(depsArray, ctypes.POINTER(ctypes.c_char_p))
    c_lib.getTargFWDeps(projCtype, targCtype, depsCtype)
    for dependency in depsCtype:
        if dependency == None:
            break
        depsListOut.append(dependency.decode('utf-8'))
    return depsListOut

def main():
    # Reading the data inside the xml
    # file to a variable under the name
    # data
    wsPath = args.workspace
    contentXml = wsPath + "/contents.xcworkspacedata"
    with open(contentXml, 'r') as f:
        bsdata = f.read()
    
    # Passing the stored data inside
    # the beautifulsoup parser, storing
    # the returned object
    bsxml = BeautifulSoup(bsdata, "xml")
    
    # Finding all instances of tag
    # `unique`

    populateXcodeprojList(bsxml, wsPath)

    if (args.list == True):
        dumpXcodeprojList()
    elif (args.deps == True) and (args.scheme != None):
        schemeItem = [p for p in xcodeprojList if p.targ == args.scheme]
        depsListOut = getDepsList(schemeItem[0])
        for dependency in depsListOut:
            print(dependency)
    elif args.sdk != None:
        if args.scheme != None:
            schemeItem = [p for p in xcodeprojList if p.targ == args.scheme]
            depsListOut = getDepsList(schemeItem[0])
            for dependency in depsListOut:
                depItemL = [p for p in xcodeprojList if p.product == dependency]
                depItem = depItemL[0]
                print("patching {} target {} with sdkroot {} and version {}".format(depItem.xcodeproj, depItem.targ, args.sdk[0], args.sdk[1]))
                projCtype = ctypes.c_char_p(bytes("{}/{}".format(depItem.xcodeproj, "project.pbxproj"), 'utf-8'))
                sdkrootCtype = ctypes.c_char_p(bytes(args.sdk[0], 'utf-8'))
                versionCtype = ctypes.c_char_p(bytes(args.sdk[1], 'utf-8'))
                targCtype = ctypes.c_char_p(bytes(depItem.targ, 'utf-8'))
                c_lib.patchPbxprojTarg(projCtype, sdkrootCtype, versionCtype, targCtype)

    # for groups in bsxml.Workspace.find_all("Group"):
    #     for filerefs in groups.find_all("FileRef"):
    #         fileRefLocation = filerefs["location"].replace("group:", "")
    #         projName, projExtension = os.path.splitext(fileRefLocation)
    #         if projExtension == ".xcodeproj":
    #             projAbsPath = "{}/{}".format(os.path.dirname(wsPath), fileRefLocation)
    #             projFilePath = os.path.basename(projAbsPath)
    #             projName, projExtension = os.path.splitext(projFilePath)
    #             if projName == args.project:
    #                 # libname = pathlib.Path().absolute() # "libcmult.so"
    #                 # modify sdk verison
    #                 if (args.sdk != None) and (args.deps == None):
    #                     print("patching {} with sdkroot {} and version {}".format(projAbsPath, args.sdk[0], args.sdk[1]))
    #                     projCtype = ctypes.c_char_p(bytes("{}/{}".format(projAbsPath, "project.pbxproj"), 'utf-8'))
    #                     sdkrootCtype = ctypes.c_char_p(bytes(args.sdk[0], 'utf-8'))
    #                     versionCtype = ctypes.c_char_p(bytes(args.sdk[1], 'utf-8'))
    #                     c_lib.patchPbxproj(projCtype, sdkrootCtype, versionCtype)
    #                 # get library dependencies
    #                 elif (args.deps != None) and (args.scheme == projName) and (args.sdk == None):
    #                     projCtype = ctypes.c_char_p(bytes("{}/{}".format(projAbsPath, "project.pbxproj"), 'utf-8'))
    #                     targCtype = ctypes.c_char_p(bytes(args.scheme, 'utf-8'))
    #                     depsArray = (ctypes.c_char_p * 100)()
    #                     depsCtype = ctypes.cast(depsArray, ctypes.POINTER(ctypes.c_char_p))
    #                     c_lib.getTargFWDeps(projCtype, targCtype, depsCtype)
    #                     for dependency in depsCtype:
    #                         if dependency == None:
    #                             break
    #                         print(dependency.decode('utf-8'))
                    # get project, framework and product hierarchy

                    # get dependencies and patch them according to their matching values
                    # elif (args.deps != None) and (args.scheme == projName) and (args.sdk != None):

                        # c_lib.print5(sdkrootCtype, versionCtype, projCtype)


    # Using find() to extract attributes
    # of the first instance of the tag
    # b_name = Bs_data.find('child', {'name':'Frank'})
    
    # print(b_name)
    
    # Extracting the data stored in a
    # specific attribute of the
    # `child` tag
    # value = b_name.get('test')
    
    # print(value)

if __name__ == "__main__":
    main()