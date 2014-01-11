async = require('async')
fs = require('fs')
glob = require('glob')
mkdirp = require('mkdirp')
path = require('path')
_ = require('lodash')

exports.input = {}
exports.output = {}

negativeIndex = (i, arr) -> if i >= 0 then i else arr.length + i

exports.singleToArray = (fun, inputIndex = 0, callbackIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    inputIndex = negativeIndex(inputIndex, args)
    callbackIndex = negativeIndex(callbackIndex, args)

    argsForCall = _.clone(args)
    callFunWithArgs = (input, callback) ->
      argsForCall[inputIndex] = input
      argsForCall[callbackIndex] = callback
      fun.apply(null, argsForCall)

    async.map(args[inputIndex], callFunWithArgs, args[callbackIndex])

exports.singleToArrayOrSingle = (fun, inputIndex = 0, callbackIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    inputIndex = negativeIndex(inputIndex, args)
    callbackIndex = negativeIndex(callbackIndex, args)

    input = if _.isArray(args[inputIndex]) then args[inputIndex] else [ args[inputIndex] ]
    async.map(input, fun, args[callbackIndex])


exports.input.stringToFilePath = (fun, readFileOptions = { encoding: 'utf-8' }, inputIndex = 0, callbackIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    inputIndex = negativeIndex(inputIndex, args)
    callbackIndex = negativeIndex(callbackIndex, args)

    fs.readFile args[inputIndex], readFileOptions, (err, content) ->
      if err? then return args[callbackIndex](err)
      args[inputIndex] = content
      fun.apply(null, args)


exports.input.filePathsToGlob = (fun, globOptions, inputIndex = 0, callbackIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    inputIndex = negativeIndex(inputIndex, args)
    callbackIndex = negativeIndex(callbackIndex, args)

    glob args[inputIndex], globOptions, (err, filePaths) ->
      if err? then return args[callbackIndex](err)
      args[inputIndex] = filePaths
      fun.apply(null, args)


exports.input.flatten = (fun, inputIndex = 0) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    inputIndex = negativeIndex(inputIndex, args)
    args[inputIndex] = _.flatten(args[inputIndex])
    fun.apply(null, args)

exports.output.stringToFilePath = (fun, writeFileOptions, outputIndex = 1, callbackIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    outputIndex = negativeIndex(outputIndex, args)
    callbackIndex = negativeIndex(callbackIndex, args)

    outFile = args[outputIndex]
    callback = args[callbackIndex]

    args[callbackIndex] = (err, result) ->
      mkdirp path.dirname(outFile), (err) ->
        if err then return callback(err)
        fs.writeFile outFile, result, writeFileOptions, (err) ->
          if err then return callback(err)
          callback(null, outFile)

    #Call original function with new arguments
    args.splice(outputIndex, 1)
    fun.apply(null, args)


exports.output.filePathToGenerated = (fun, inputIndex = 0, outputIndex = 1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    inputIndex = negativeIndex(inputIndex, args)
    outputIndex = negativeIndex(outputIndex, args)

    args[outputIndex] = args[outputIndex](args[inputIndex])
    fun.apply(null, args)

exports.output.filePathAppendExtension = (fun, extension, outputIndex = 1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    outputIndex = negativeIndex(outputIndex, args)

    args[outputIndex] = args[outputIndex] + '.' + extension
    fun.apply(null, args)

exports.output.filePathToDirPath = (fun, inputIndex = 0, outputIndex = 1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    inputIndex = negativeIndex(inputIndex, args)
    outputIndex = negativeIndex(outputIndex, args)
    outputDirPath = args[outputIndex]
    inputFilePath = args[inputIndex]

    args[outputIndex] = path.join(outputDirPath, path.basename(inputFilePath))
    fun.apply(null, args)