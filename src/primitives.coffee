async = require('async')
fs = require('fs')
glob = require('glob')
mkdirp = require('mkdirp')
path = require('path')
_ = require('lodash')

exports.replaceArgument = (fun, argIndex, newValue) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    args[argIndex] = newValue
    fun.apply(null, args)


exports.syncToAsync = (fun, callbackIndex) ->
  () ->
    args = Array.prototype.slice.call(arguments)

    async.nextTick ->
      try
        result = fun.apply(null, args)
        args[callbackIndex](null, result)
      catch e
        args[callbackIndex](e)


exports.singleToArray = (fun, argIndexes, callbackIndex) ->
  if !_.isArray(argIndexes) then argIndexes = [ argIndexes ]
  () ->
    args = Array.prototype.slice.call(arguments)
    doneCallback = args[callbackIndex] || (->)

    argsForCall = _.clone(args)
    callFunWithArgs = (input, callback) ->
      argsForCall[argIndexes[i]] = input[i] for i in [0..input.length]
      argsForCall[callbackIndex] = callback
      fun.apply(null, argsForCall)

    argsToUse = (args[argIndex] for argIndex in argIndexes)

    if _.any(argsToUse, (a) -> a.length != argsToUse[0].length)
      return doneCallback(new Error("Arguments must be the same length"))

    argsPerCall = _.zip(argsToUse)
    async.map(argsPerCall, callFunWithArgs, doneCallback)

exports.singleToArrayOptional = (fun, argIndexes, callbackIndex) ->
  if !_.isArray(argIndexes) then argIndexes = [ argIndexes ]
  funWithArrayArg = exports.singleToArray(fun, argIndexes, callbackIndex)
  () ->
    args = Array.prototype.slice.call(arguments)
    argsToUse = (args[argIndex] for argIndex in argIndexes)

    funToApply = if _.any(argsToUse, _.isArray) then funWithArrayArg else fun
    funToApply.apply(null, args)


exports.stringToReadFile = (fun, argIndex, callbackIndex, readFileOptions = { encoding: 'utf-8' }) ->
  () ->
    args = Array.prototype.slice.call(arguments)

    fs.readFile args[argIndex], readFileOptions, (err, content) ->
      if err? then return args[callbackIndex](err)
      args[argIndex] = content
      fun.apply(null, args)


exports.readFilesToGlob = (fun, argIndex, callbackIndex, globOptions) ->
  () ->
    args = Array.prototype.slice.call(arguments)

    glob args[argIndex], globOptions, (err, filePaths) ->
      if err? then return args[callbackIndex](err)
      args[argIndex] = filePaths
      fun.apply(null, args)


globs = exports.singleToArrayOptional(glob, 0, 2)

exports.readFilesToGlobs = (fun, argIndex, callbackIndex, globOptions) ->
  () ->
    args = Array.prototype.slice.call(arguments)

    globs args[argIndex], globOptions, (err, filePaths) ->
      if err? then return args[callbackIndex](err)
      if _.isArray(filePaths) then filePaths = _.flatten(filePaths)
      filePaths = _.uniq(filePaths)
      args[argIndex] = filePaths
      fun.apply(null, args)


exports.flattenArray = (fun, argIndex) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    if _.isArray(args[argIndex])
      args[argIndex] = _.flatten(args[argIndex])
    fun.apply(null, args)

exports.addArg = (fun, newArgIndex) ->
  () ->
    args = Array.prototype.slice.call(arguments)

    args.splice(newArgIndex, 1)
    fun.apply(null, args)


exports.stringToWriteFile = (fun, callbackIndexBeforeNewIsAdded, newFilePathArgIndex, writeFileOptions) ->
  funWithFilePathArg = exports.addArg(fun, newFilePathArgIndex)

  () ->
    args = Array.prototype.slice.call(arguments)
    callbackIndex = 
      if newFilePathArgIndex <= callbackIndexBeforeNewIsAdded then callbackIndexBeforeNewIsAdded + 1
      else callbackIndexBeforeNewIsAdded

    outFile = path.normalize(args[newFilePathArgIndex])
    callback = args[callbackIndex]

    args[callbackIndex] = (err, result) ->
      mkdirp path.dirname(outFile), (err, createdDir) ->
        if err then return callback(err)
        fs.writeFile outFile, result, writeFileOptions, (err) ->
          if err then return callback(err)
          callback(null, outFile)

    #Call original function with new arguments
    funWithFilePathArg.apply(null, args)


exports.argToGenerated = (fun, argIndex, generatorParameterIndex, generatorParameterIsCollection = false) ->
  () ->
    args = Array.prototype.slice.call(arguments)

    args[argIndex] =
      if !generatorParameterIsCollection
        args[argIndex](args[generatorParameterIndex])
      else
        _.map(args[generatorParameterIndex], (p) -> args[argIndex](p))


    fun.apply(null, args)

exports.argToGeneratedOptional = (fun, argIndex, generatorParameterIndex, generatorParameterIsCollection = false) ->
  funWithGenerated = exports.argToGenerated(fun, argIndex, generatorParameterIndex, generatorParameterIsCollection)
  () ->
    args = Array.prototype.slice.call(arguments)

    funToApply = if _.isFunction(args[argIndex]) then funWithGenerated else fun
    funToApply.apply(null, args)

exports.appendExtension = (fun, extension, argIndex) ->
  () ->
    args = Array.prototype.slice.call(arguments)

    args[argIndex] = args[argIndex] + '.' + extension
    fun.apply(null, args)


exports.filePathToDirPath = (fun, argIndex, inputFilePathIndex) ->
  () ->
    args = Array.prototype.slice.call(arguments)

    outputDirPath = args[argIndex]
    inputFilePath = args[inputFilePathIndex]
    args[argIndex] = path.join(outputDirPath, path.basename(inputFilePath))
    fun.apply(null, args)