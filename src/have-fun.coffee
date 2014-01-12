_ = require('lodash')
primitives = require('./primitives')

exports.primitives = primitives

exports.fromString = fromString = {}

fromString.stringToFile = (stringToStringFun, callbackArgumentIndex) ->
  primitives.stringToWriteFile(stringToStringFun, callbackArgumentIndex, 1)

fromString.fileToFile = (stringToStringFun, inputArgumentIndex, callbackArgumentIndex) ->
  stringToFileFun = fromString.stringToFile(stringToStringFun, callbackArgumentIndex)
  primitives.stringToReadFile(stringToFileFun, inputArgumentIndex, callbackArgumentIndex + 1)

fromString.fileToDir = (stringToStringFun, extension, inputArgumentIndex, callbackArgumentIndex) ->
  fileToFileFun = fromString.fileToFile(stringToStringFun, inputArgumentIndex, callbackArgumentIndex)
  primitives.filePathToDirPath(primitives.appendExtension(fileToFileFun, extension, 1), 1, inputArgumentIndex)

fromString.fileToString = (stringToStringFun, callbackArgumentIndex) ->
  primitives.stringToReadFile(stringToStringFun, inputArgumentIndex, callbackArgumentIndex)

fromString.globsToStrings = (stringToStringFun, inputArgumentIndex, callbackArgumentIndex) ->
  fileToStringFun = fromString.fileToString(stringToStringFun, callbackArgumentIndex)
  primitives.readFilesToGlobs(primitives.singleToArray(fileToStringFun, inputArgumentIndex, callbackArgumentIndex), inputArgumentIndex, callbackArgumentIndex)

fromString.globsToFiles = (stringToStringFun, inputArgumentIndex, callbackArgumentIndex) ->
  fileToFileFun = fromString.fileToFile(stringToStringFun, inputArgumentIndex, callbackArgumentIndex)
  primitives.readFilesToGlobs(primitives.argToGeneratedOptional(primitives.singleToArray(fileToFileFun, [inputArgumentIndex, 1], callbackArgumentIndex + 1), 1, inputArgumentIndex, true), inputArgumentIndex, callbackArgumentIndex + 1)

fromString.globsToDir = (stringToStringFun, extension, inputArgumentIndex, callbackArgumentIndex) ->
  fileToFileFun = fromString.fileToFile(stringToStringFun, inputArgumentIndex, callbackArgumentIndex)
  primitives.readFilesToGlobs(primitives.singleToArray(primitives.filePathToDirPath(primitives.appendExtension(fileToFileFun, extension, 1), 1, inputArgumentIndex), inputArgumentIndex, callbackArgumentIndex + 1), inputArgumentIndex, callbackArgumentIndex + 1)

# For the sync version, one must replace the first argument (the function) by it's asynchronous version
# We tell `syncToAsync` to add the callback argument to the end
# Therefore, the `numberOfArguments` argument will equal `callbackArgumentIndex`, which is present on the `fromString` functions
###
fromStringSync.fileToFile = () -> fromString.fileToFile(primitives.syncToAsync(fun, numberOfArguments), inputArgumentIndex, numberOfArguments)
fromStringSync.fileToString = () -> fromString.fileToString(primitives.syncToAsync(fun, numberOfArguments), numberOfArguments)
###

exports.fromStringSync = fromStringSync = _.mapValues fromString, (f) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    syncFun = args[0]
    numberOfArguments = args[args.length - 1] #numberOfArguments always comes at the end (like callbackArgumentIndex)
    args[0] = primitives.syncToAsync(syncFun, numberOfArguments)
    f.apply(null, args)