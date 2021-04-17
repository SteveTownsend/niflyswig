# niflyswig
Use SWIG to generate C# bindings to nifly

## Requirements
- SWIG 4.0 from https://sourceforge.net/projects/swig/files/swigwin/swigwin-4.0.2/swigwin-4.0.2.zip
- Visual Studio 2019

## Workflow
The solution contains three projects and relies on a fork of the *nifly* baseline:
- *niflycpp* uses SWIG template file *niflycpp.i* to generate C# wrappers for the nifly library
- *nifly* is the sink for the generated C# code - export to a local NuGet repository for testing outside this solution
- *nifly-test* is a simple test app that reads NIF files of your choosing from the *data* directory, rewrites to a new file and brute-force compares them to the original.
It is recommended to ensure the test works bfore tring more complex NIF manipulation using your locally-exported NuGet package.
When you first open the solution, you will get C# erros due to the test project not finding generated code. Build the solution and the errors should go away.
