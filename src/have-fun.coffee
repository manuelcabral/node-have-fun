async = require('async')
fs = require('fs')
glob = require('glob')
_ = require('lodash')

exports.input = {}
exports.output = {}

negativeIndex = (i, arr) -> if i >= 0 then i else arr.length + i

exports.singleToArray = (fun, inputIndex = 0, callbackIndex = -1) ->
  () ->
    args = Array.prototype.slice.call(arguments)
    inputIndex = negativeIndex(inputIndex, args)
    callbackIndex = negativeIndex(callbackIndex, args)

    async.map(args[inputIndex], fun, args[callbackIndex])


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