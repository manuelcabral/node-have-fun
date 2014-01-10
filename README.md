# Have Funs

Functions that change the interface of other functions.

## Example transformations

    // A function which transforms some string data
    resultString = f(inputString)

    // Make the function asynchronous, receiving a two-argument callback as per the node convention
    f(inputString, function(err, resultString){})

    // Make it receive a file
    f(inputFilePath, function(err, resultString){})

    // Write the result to another file
    f(inputFilePath, outputFilePath, function(err, outputFilePath){})

    // Or to a file with the same name as inputFile, but on another folder
    f(inputFilePath, outputFolder, function(err, outputFilePath){})

    // Make it work on a list of files, rather than a single one
    f(inputFilePaths, outputFolder, function(err, outputFilePaths){})

    // A glob returns a list of files
    f(glob, outputFolder, function(err, outputFilePaths){})


The kind of transformation above is what this module allows one to do easily

One could event start with another primitive, such as a transform string:

    var someTransformStream = ...

    f(inputStream, outputStream) // Pipe the data through our transform stream
    f(inputString, function(err, outputString) {}) // Use strings instead
    f(inputFilePath, function(err, outputFilePath) {}) // or files
    f(inputFilePath, outputDir, function(err, outputFilePaths) {}) // Make it work on lists of files


## Input types

 - (stream)
 - string
 - filePath

 - streamList, stringList, filePathList (a list of any the former)
 - glob
 - globList



## Output types

 - For functions outputting a single value
   - (stream)
   - string
   - filePath
   - inputFilePath with appended extension

 - For functions outputting a list of values
   - streamList, stringList, filePathList (a list of any the former)
   - dirPath

## Other transforms

 - Synchronous functions to asynchronous
 - Functions receiving a single argument to receiving multiple arguments
 - Promises?


## Api

    syncToAsync(fun, callbackIndex = -1) // indexes < 0 count from the end
    // result = f(input)
    // f(input, function(err, result)) // Exceptions are passed in `err`

    oneToMultiple(fun, inputIndex = 0, callbackIndex = -1)
    // f(input, function(err, result))
    // f([ input ], function(err, [ result ]))

    input.flatten(fun, inputIndex = 0) // Flattens the input list before executing the function
    // Useful to be able to use a list of globs

    input.stringToFilePath(fun, readFileOptions, inputIndex = 0, callbackIndex = -1)
    // f(inputString, function(err, result))
    // f(inputFilePath, function(err, result))

    input.filePathsToGlob(fun, globOptions, inputIndex = 0, callbackIndex = -1)
    // f( [ filePath ], function(err, [ result ]))
    // f(glob, function(err, [ result ]))

    output.stringToFilePath(fun, writeFileOptions, inputIndex = 0, outputIndex = 1, callbackIndex = -1)
    // f(input, function(err, resultString))
    // f(input, outputFilePath, function(err, outputFilePath))

    output.filePathToGenerated(fun, inputIndex = 0, outputIndex = 1, callbackIndex = -1)
    // f(input, outputFilePath, function(err, outputFilePath))
    // f(input, function(input) { return outputFilePath; }, function(err, outputFilePath))

    output.filePathAddExtension(fun, extension, inputIndex = 0, outputIndex = 1, callbackIndex = -1)
    // f(input, outputFilePath, function(err, outputFilePath))
    // f(input, outputFilePath, function(err, outputFilePath + '.extension'))

    output.generatedToDirPath(fun, inputIndex = 0, outputIndex = 1, callbackIndex = -1)
    // f(input, function(input) { return outputFilePath; }, function(err, outputFilePath))    
    // f(input, dirPath, function(err, outputFilePath))


## Noutro modulo?

lotsOfFun(less.render, '.css')
lotsOfFun(coffee.compile, '.coffee')

inputs importantes:
 - string
 - glob/globs
 - (stream)

outputs importantes:
  - string
  - stringList
  - folder






Não vale a pena gerar todos:

result:
  single:
    string:
      string: f(string, function(err, string))
      filePath: f(string, outputFilePath, function(err, outputFilePath))
    filePath:
      string: f(filePath, function(err, string))
      filePath: f(filePath, outputFilePath, function(err, outputFilePath))
  multi:
    string:
      string: f([string], function(err, [string]))
      filePath: f([string], [outputFilePath], function(err, [outputFilePath]))
      dirPath: f([string], dirPath, function(err, [outputFilePath]))
    filePath:
      string: f([filePath], function(err, [string]))
      filePath: f([filePath], [outputFilePath], function(err, [outputFilePath]))
      dirPath: f([filePath], dirPath, function(err, [outputFilePath]))
    glob:
      string: f(glob, function(err, [string]))
      filePath: f(glob, [outputFilePath], function(err, [outputFilePath]))
      dirPath: f(glob, dirPath, function(err, [outputFilePath]))
    globs:
      string: f(globs, function(err, [string]))
      filePath: f(globs, [outputFilePath], function(err, [outputFilePath]))
      dirPath: f(globs, dirPath, function(err, [outputFilePath]))