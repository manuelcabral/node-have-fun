async = require('async')
fs = require('fs')
glob = require('glob')
mkdirp = require('mkdirp')
path = require('path')
_ = require('lodash')

negativeIndex = (i, arr) -> if i >= 0 then i else arr.length + i

exports.syncToAsync = (fun, callbackIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    callbackIndex = negativeIndex(callbackIndex, args)

    async.nextTick ->
      try
        fun.apply(null, arguments)
      catch e
        args[callbackIndex](e)


exports.singleToArray = (fun, argIndexes = [ 0 ], callbackIndex = -1) ->
  if !_.isArray(argIndexes) then argIndexes = [ argIndexes ]
  () ->
    args = Array.prototype.slice.call(arguments)
    argIndexes = (negativeIndex(argIndex, args) for argIndex in argIndexes)
    callbackIndex = negativeIndex(callbackIndex, args)

    argsForCall = _.clone(args)
    callFunWithArgs = (input, callback) ->
      argsForCall[argIndexes[i]] = input[i] for i in [0..input.length]
      argsForCall[callbackIndex] = callback
      fun.apply(null, argsForCall)

    argsToUse = (args[argIndex] for argIndex in argIndexes)

    if _.any(argsToUse, (a) -> a.length != argsToUse[0].length)
      return args[callbackIndex](new Error("Arguments must be the same length"))

    argsPerCall = _.zip(argsToUse)
    async.map(argsPerCall, callFunWithArgs, args[callbackIndex])

exports.singleToArrayOptional = (fun, argIndexes = 0, callbackIndex = -1) ->
  if !_.isArray(argIndexes) then argIndexes = [ argIndexes ]
  funWithArrayArg = exports.singleToArray(fun, argIndexes, callbackIndex)
  () ->
    args = Array.prototype.slice.call(arguments)
    argIndexes = (negativeIndex(argIndex, args) for argIndex in argIndexes)
    argsToUse = (args[negativeIndex(argIndex, args)] for argIndex in argIndexes)

    funToApply = if _.any(argsToUse, _.isArray) then funWithArrayArg else fun
    funToApply.apply(null, args)


exports.stringToReadFile = (fun, readFileOptions = { encoding: 'utf-8' }, argIndex = 0, callbackIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    argIndex = negativeIndex(argIndex, args)
    callbackIndex = negativeIndex(callbackIndex, args)

    fs.readFile args[argIndex], readFileOptions, (err, content) ->
      if err? then return args[callbackIndex](err)
      args[argIndex] = content
      fun.apply(null, args)


exports.readFilesToGlob = (fun, globOptions, argIndex = 0, callbackIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    argIndex = negativeIndex(argIndex, args)
    callbackIndex = negativeIndex(callbackIndex, args)

    glob args[argIndex], globOptions, (err, filePaths) ->
      if err? then return args[callbackIndex](err)
      args[argIndex] = filePaths
      fun.apply(null, args)


exports.flatten = (fun, argIndex = 0) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    argIndex = negativeIndex(argIndex, args)
    args[argIndex] = _.flatten(args[argIndex])
    fun.apply(null, args)

exports.addArg = (fun, argIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    argIndex = negativeIndex(argIndex, args)

    args.splice(argIndex, 1)
    fun.apply(null, args)


exports.stringToWriteFile = (fun, writeFileOptions, newFilePathArgIndex = 1, callbackIndex = -1) ->
  funWithFilePathArg = exports.addArg(fun, newFilePathArgIndex)

  () ->
    args = Array.prototype.slice.call(arguments)
    newFilePathArgIndex = negativeIndex(newFilePathArgIndex, args)
    callbackIndex = negativeIndex(callbackIndex, args)

    outFile = args[newFilePathArgIndex]
    callback = args[callbackIndex]

    args[callbackIndex] = (err, result) ->
      mkdirp path.dirname(outFile), (err) ->
        if err then return callback(err)
        fs.writeFile outFile, result, writeFileOptions, (err) ->
          if err then return callback(err)
          callback(null, outFile)

    #Call original function with new arguments
    funWithFilePathArg.apply(null, args)


exports.argToGenerated = (fun, argIndex = 1, generatorParameterIndex = 0) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    generatorParameterIndex = negativeIndex(generatorParameterIndex, args)
    argIndex = negativeIndex(argIndex, args)

    args[argIndex] = args[argIndex](args[generatorParameterIndex])
    fun.apply(null, args)

exports.argToGeneratedOptional = (fun, argIndex = 1, generatorParameterIndex = 0) ->
  funWithGenerated = exports.argToGenerated(fun, argIndex, generatorParameterIndex)
  () ->
    args = Array.prototype.slice.call(arguments)
    argIndex = negativeIndex(argIndex, args)

    funToApply = if _.isFunction(args[argIndex]) then funWithGenerated else fun
    funToApply.apply(null, args)

exports.appendExtension = (fun, extension, argIndex = 1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    argIndex = negativeIndex(argIndex, args)

    args[argIndex] = args[argIndex] + '.' + extension
    fun.apply(null, args)


exports.filePathToDirPath = (fun, argIndex = 1, inputFilePathIndex = 0) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    inputFilePathIndex = negativeIndex(inputFilePathIndex, args)
    argIndex = negativeIndex(argIndex, args)

    outputDirPath = args[argIndex]
    inputFilePath = args[inputFilePathIndex]
    args[argIndex] = path.join(outputDirPath, path.basename(inputFilePath))
    fun.apply(null, args)