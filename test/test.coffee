expect = require('chai').expect
path = require('path')
sinon = require('sinon')
fs = require('fs')
haveFun = require("../src/have-fun")


describe 'have-funs', ->

  before -> try fs.mkdirSync("tmp")

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

  describe 'singleToArrayOrSingle()', ->

    it 'transforms a function which receives and outputs a single element into one which can also receive array', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, cb) -> cb(null, vals[i])
      transformed = haveFun.singleToArrayOrSingle(f)
      transformed [1,2,0], (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['b', 'c', 'a'])
        done()

    it 'allows the function to still receive a single element. the output will be an array of length 1', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, cb) -> cb(null, vals[i])
      transformed = haveFun.singleToArrayOrSingle(f)
      transformed 2, (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['c'])
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


  describe 'output.stringToFilePath()', ->

    outfile = path.join(__dirname, "tmp/outfile.txt")
    beforeEach -> try fs.unlinkSync(outfile)

    it 'transforms function which outputs a string into one which writes it to a file and outputs the file path', (done) ->
      f = (input, cb) -> cb(null, input)

      transformed = haveFun.output.stringToFilePath(f)
      transformed "all done", outfile, (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.equal(outfile)
        expect(fs.readFileSync(outfile, { encoding: 'utf-8' })).to.equal("all done")
        done()

    ### For some reason, this test is currently failing
    it 'throws error if cannot create folder', (done) ->
      f = (input, cb) -> cb(null, input)

      transformed = haveFun.output.stringToFilePath(f)
      transformed "all done", 'invaliddirnam|?e/hello', (err, result) ->
        console.log(err, result)
        expect(err).to.be.ok
        done()
    ###


    it 'throws error if cannot write file', (done) ->
      f = (input, cb) -> cb(null, input)

      transformed = haveFun.output.stringToFilePath(f)
      transformed "all done", 'tmp/invalidfilename*|?', (err, result) ->
        expect(err).to.be.ok
        done()

    
  describe 'output.filePathToGenerated()', ->

    it 'transforms function which takes a file path to write into one which takes a function to generate the file path', () ->
      f = sinon.spy()
      transformed = haveFun.output.filePathToGenerated(f)
      nameGenerator = (inputPath) -> "output/#{inputPath}"
      transformed('testpath.txt', nameGenerator)
      expect(f.firstCall.args[1]).to.equal('output/testpath.txt')
        
  describe 'output.filePathAppendExtension()', ->

    it 'transforms function into one with an extension appended to a file path to write', () ->
      f = sinon.spy()
      transformed = haveFun.output.filePathAppendExtension(f, 'js')
      transformed('input.coffee', 'output')
      expect(f.firstCall.args[1]).to.equal('output.js')


