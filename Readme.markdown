##About KOResume

KOResume is a simple resume app.

IMPORTANT - do not use Xcode to generate the Core Data model - if you do you will have hundreds of errors and have to restore all the data model source. See the section below on database

##Database Maintenance

The app uses Core Data and a version comment has been added.

DO NOT use the built-in "Editor" tool to created the NSManagedObject subclasses - download and use mogenerator instead.

modgenerator implements to generation-gap design pattern to create an intermediate class file.  The entity is represented by a Class file prepended with an underscore, but you reference the normal entity name in the code.  For example, if you have an entity Foo in the model, mogenerator will create

        _Foo.h, _Foo.m as well as Foo.h and Foo.m, which subclass _Foo.  
        
Subsequent invocations of mogenerator WILL NOT overwrite the Foo.h or Foo.m files.

At the terminal invoke mogenerator navigate to KOResume/KOResume-iPhone:

        mogenerator -m Classes/KOResume.xcdatamodeld/KOResume.xcdatamodel  -O Classes

##License

KOResume is licensed under MIT license.

