# Primitives

replaceArgument = (fun, argIndex, newValue)
syncToAsync = (fun, callbackIndex)
singleToArray = (fun, argIndexes, callbackIndex)
singleToArrayOptional = (fun, argIndexes, callbackIndex)
flattenArray = (fun, argIndex)
addArg = (fun, newArgIndex)
argToGenerated = (fun, argIndex, generatorParameterIndex, generatorParameterIsCollection = false)
argToGeneratedOptional = (fun, argIndex, generatorParameterIndex, generatorParameterIsCollection = false)
appendExtension = (fun, extension, argIndex)


# Files

stringToReadFile = (fun, argIndex, callbackIndex, readFileOptions = { encoding: 'utf-8' })
readFilesToGlobs = (fun, argIndexBeforeNewIsAdded, callbackIndexBeforeNewIsAdded, globOptionsIndex)
stringToWriteFile = (fun, callbackIndexBeforeNewIsAdded, newFilePathArgIndex, writeFileOptions)
filePathToDirPath = (fun, argIndex, inputFilePathIndex)


# Map functions

fromStringSync.
fromString.
fromTransformStream.

  stringToString
  fileToFile = (stringToStringFun, inputArgumentIndex, callbackArgumentIndex)
  filesToFiles = (stringToStringFun, inputArgumentIndex, callbackArgumentIndex)
  globsToDir = (stringToStringFun, extension, inputArgumentIndex, callbackArgumentIndex)

  # This one would "flatten" the file, since it doesn't know `cwd`. Maybe it's not very useful?
  #
  # fileToDir = (stringToStringFun, extension, inputArgumentIndex, callbackArgumentIndex)
  #
  # coffee.fileToDir(file, coffeeFolder, {}, log("built <%= res %>"))
  #   vs
  # coffee.fileToFile(file, join(coffeeFolder, file, '.js'), {}, log("built <%= res %>"))
  #
  # second doesn't seem much worse!
  

  # globsToStrings = (stringToStringFun, inputArgumentIndex, callbackArgumentIndex)
  # stringToFile = (stringToStringFun, callbackArgumentIndex)
  # fileToString = (stringToStringFun, callbackArgumentIndex)
  

  # globsToStrings = (stringToStringFun, inputArgumentIndex, callbackArgumentIndex)
  # stringToFile = (stringToStringFun, callbackArgumentIndex)
  # fileToString = (stringToStringFun, callbackArgumentIndex)


# Reduce functions

fromStringSync.
fromString.
fromTransformStream.

  stringsToString
  filesToFile
  globsToFile