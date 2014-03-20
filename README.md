##About KOResume

KOResume is a simple resume app.

IMPORTANT - do not use Xcode to generate the Core Data model - if you do you will have hundreds of errors and have to restore all the data model source. See the section below on database

##Database Maintenance

The app uses Core Data and a version comment has been added.

DO NOT use the built-in "Editor" tool to created the NSManagedObject subclasses - download and use mogenerator from [GitHub](http://rentzsch.github.io/mogenerator/).

mogenerator implements a generation-gap design pattern to create an intermediate class file.  The entity is represented by a Class file prepended with an underscore, but you reference the normal entity name in the code.  For example, if you have an entity Foo in the model, mogenerator will create

        _Foo.h, _Foo.m as well as Foo.h and Foo.m, which subclass _Foo.  
        
Subsequent invocations of mogenerator WILL NOT overwrite the Foo.h or Foo.m files, so you are safe to add custom code without fear of losing your customizations as would happen if you use the built-in Editor.

Once you have mogenator installed on your system you can run it by selecting the Mogenerator scheme in the build menu. If you prefer the command line just open a terminal window, navigate to KOResume/KOResume-iPhone, and invoke mogenerator:

        mogenerator --template-var arc=true -m Classes/DataModel/KOResume.xcdatamodeld/KOResume.xcdatamodel  -O Classes/DataModel

##License

KOResume is licensed under MIT [License](https://github.com/kgomara/KOResume3/blob/master/LICENSE).

