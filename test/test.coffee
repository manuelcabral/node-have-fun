expect = require('chai').expect
path = require('path')
sinon = require('sinon')
haveFun = require("../src/have-fun")


describe 'have-funs', ->

  describe 'syncToAsync()', ->

    it 'should transform a synchronous function into an asynchronous one'

  describe 'singleToArray()', ->

    it 'transforms a function which receives and outputs a single element into one which receives and outputs an array', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, cb) -> cb(null, vals[i])
      transformed = haveFun.singleToArray(f)
      transformed [1,2,0], (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['b', 'c', 'a'])
        done()

    it 'should callback with error if any of the functions does', (done) ->
      f = (error, cb) -> cb(error, !error)
      transformed = haveFun.singleToArray(f)

      transformed [false,"someerror",false], (err) ->
        expect(err).to.equal("someerror")
        done()

  describe 'input.stringToFilePath()', ->

    it 'transforms a function receiving a string to one receiving a file path to read', (done) ->
      f = (x, cb) -> cb(null, x.toUpperCase())
      transformed = haveFun.input.stringToFilePath(f)

      transformed path.join(__dirname,'files/testdata.txt'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.equal("SOMETESTDATA")
        done()

    it 'receives options for readFile', (done) ->
      f = (x, cb) -> cb(null, x.readInt8(0))
      transformed = haveFun.input.stringToFilePath(f, { encoding: null })

      transformed path.join(__dirname,'files/testdata.txt'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.equal(115)
        done()

    it 'throws error if file does not exist', (done) ->
      f = (x, cb) -> cb(null, x.toUpperCase())
      transformed = haveFun.input.stringToFilePath(f)

      transformed path.join(__dirname,'unexisting_file'), (err, result) ->
        expect(err).to.be.ok
        expect(result).to.be.not.ok
        done()      

  describe 'input.filePathsToGlob()', ->

    f = haveFun.singleToArray(haveFun.input.stringToFilePath((x, cb) -> cb(null, x.toUpperCase())))

    it 'transforms a function receiving a list of file paths into one receiving a glob', (done) ->
      transformed = haveFun.input.filePathsToGlob(f)

      transformed path.join(__dirname,'files/*globtest*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([ 'GLOBTESTDATA', 'MOREGLOBTESTDATA'])
        done()

    it 'receives glob options', (done) ->
      transformed = haveFun.input.filePathsToGlob(f, { dot: true })

      transformed path.join(__dirname,'files/*globtest*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([ 'HIDDENGLOBDATA', 'GLOBTESTDATA', 'MOREGLOBTESTDATA'])
        done()

    it 'returns empty list if no matches occur', (done) ->
      transformed = haveFun.input.filePathsToGlob(f)

      transformed path.join(__dirname,'files/unexisting_file*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([])
        done()

  describe 'input.flatten()', ->

    it 'flattens the input before calling the function', ->
      f = sinon.spy()
      transformed = haveFun.input.flatten(f)
      transformed([[1,2],[3,4]])
      expect(f.firstCall.args[0]).to.eql([1,2,3,4])
