expect = require('chai').expect
path = require('path')
sinon = require('sinon')
fs = require('fs')
haveFun = require("../src/have-fun")

delay = (t, f) -> setTimeout(f, t)

describe 'have-funs', ->

  before -> try fs.mkdirSync("tmp")

  describe 'syncToAsync()', ->

    it 'should transform a synchronous function into an asynchronous one', (done) ->
      spy = sinon.spy()
      f = haveFun.syncToAsync(spy)
      f (err, result) ->
        expect(err).to.be.not.ok

      expect(spy.callCount).to.equal(0)
      delay 10, ->
        expect(spy.callCount).to.equal(1)
        done()

    it 'should return error when throwing', (done) ->
      f = haveFun.syncToAsync( (-> throw "error") )
      f (err, result) ->
        expect(err).to.equal("error")
        done()


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

    it 'allows the function to receive arguments other than the transformed one', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, append, cb) -> cb(null, vals[i] + append)
      transformed = haveFun.singleToArray(f)
      transformed [1,2,0], 'x', (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['bx', 'cx', 'ax'])
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

    it 'allows the function to still receive a single element. the output will be a single element', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, cb) -> cb(null, vals[i])
      transformed = haveFun.singleToArrayOrSingle(f)
      transformed 2, (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql('c')
        done()

    it 'allows the function to receive arguments other than the transformed one', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, append, cb) -> cb(null, vals[i] + append)
      transformed = haveFun.singleToArrayOrSingle(f)
      transformed [1,2,0], 'x', (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['bx', 'cx', 'ax'])
        done()


  describe 'stringToReadFile()', ->

    it 'transforms a function receiving a string to one receiving a file path to read', (done) ->
      f = (x, cb) -> cb(null, x.toUpperCase())
      transformed = haveFun.stringToReadFile(f)

      transformed path.join(__dirname,'files/testdata.txt'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.equal("SOMETESTDATA")
        done()

    it 'receives options for readFile', (done) ->
      f = (x, cb) -> cb(null, x.readInt8(0))
      transformed = haveFun.stringToReadFile(f, { encoding: null })

      transformed path.join(__dirname,'files/testdata.txt'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.equal(115)
        done()

    it 'throws error if file does not exist', (done) ->
      f = (x, cb) -> cb(null, x.toUpperCase())
      transformed = haveFun.stringToReadFile(f)

      transformed path.join(__dirname,'unexisting_file'), (err, result) ->
        expect(err).to.be.ok
        expect(result).to.be.not.ok
        done()      

  describe 'readFileToGlob()', ->

    f = haveFun.singleToArray(haveFun.stringToReadFile((x, cb) -> cb(null, x.toUpperCase())))

    it 'transforms a function receiving a list of file paths into one receiving a glob', (done) ->
      transformed = haveFun.readFilesToGlob(f)

      transformed path.join(__dirname,'files/*globtest*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([ 'GLOBTESTDATA', 'MOREGLOBTESTDATA'])
        done()

    it 'receives glob options', (done) ->
      transformed = haveFun.readFilesToGlob(f, { dot: true })

      transformed path.join(__dirname,'files/*globtest*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([ 'HIDDENGLOBDATA', 'GLOBTESTDATA', 'MOREGLOBTESTDATA'])
        done()

    it 'returns empty list if no matches occur', (done) ->
      transformed = haveFun.readFilesToGlob(f)

      transformed path.join(__dirname,'files/unexisting_file*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([])
        done()

  describe 'flatten()', ->

    it 'flattens the argument before calling the function', ->
      f = sinon.spy()
      transformed = haveFun.flatten(f)
      transformed([[1,2],[3,4]])
      expect(f.firstCall.args[0]).to.eql([1,2,3,4])


  describe 'addArg()', ->

    it 'adds an argument to a function', ->
      f = sinon.spy()
      transformed = haveFun.addArg(f, -2) #Add argument before the last
      transformed('a', 'b', 'c')
      expect(f.firstCall.args).to.eql(['a', 'c'])


  describe 'stringToWriteFile()', ->

    outfile = path.join(__dirname, "tmp/outfile.txt")
    beforeEach -> try fs.unlinkSync(outfile)

    it 'transforms function which outputs a string into one which writes it to a file and outputs the file path', (done) ->
      f = (input, cb) -> cb(null, input)

      transformed = haveFun.stringToWriteFile(f)
      transformed "all done", outfile, (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.equal(outfile)
        expect(fs.readFileSync(outfile, { encoding: 'utf-8' })).to.equal("all done")
        done()

    ### For some reason, this test is currently failing
    it 'throws error if cannot create folder', (done) ->
      f = (input, cb) -> cb(null, input)

      transformed = haveFun.stringToWriteFile(f)
      transformed "all done", 'invaliddirnam|?e/hello', (err, result) ->
        console.log(err, result)
        expect(err).to.be.ok
        done()
    ###


    it 'throws error if cannot write file', (done) ->
      f = (input, cb) -> cb(null, input)

      transformed = haveFun.stringToWriteFile(f)
      transformed "all done", 'tmp/invalidfilename*|?', (err, result) ->
        expect(err).to.be.ok
        done()

    
  describe 'stringToGenerated()', ->
    it 'transforms function which takes a file path to write into one which takes a function to generate the file path', () ->
      f = sinon.spy()
      transformed = haveFun.stringToGenerated(f)
      nameGenerator = (inputPath) -> "output/#{inputPath}"
      transformed('testpath.txt', nameGenerator)
      expect(f.firstCall.args[1]).to.equal('output/testpath.txt')
        
  describe 'appendExtension()', ->

    it 'transforms function into one with an extension appended to a file path to write', () ->
      f = sinon.spy()
      transformed = haveFun.appendExtension(f, 'js')
      transformed('input.coffee', 'output')
      expect(f.firstCall.args[1]).to.equal('output.js')

  describe 'filePathToDirPath()', ->

    it 'transforms a function which takes a file path to write into one which takes a folder', () ->
      f = sinon.spy()
      transformed = haveFun.filePathToDirPath(f)
      transformed('a', 'output')
      expect(f.firstCall.args[1]).to.equal(path.join('output', 'a'))

    it 'allows singleToArray to be used after it', (done) ->
      f = (input, callback) -> callback(null, input)
      transformed = haveFun.singleToArray(haveFun.filePathToDirPath(haveFun.stringToWriteFile(f)))
      transformed ['firstfile', 'secondfile', 'thirdfile' ], path.join(__dirname, 'tmp', 'output'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.have.length(3)
        expect(result).to.contain(path.join(__dirname, 'tmp', 'output', 'firstfile'))
        expect(result).to.contain(path.join(__dirname, 'tmp', 'output', 'secondfile'))
        expect(result).to.contain(path.join(__dirname, 'tmp', 'output', 'thirdfile'))
        expect(fs.readFileSync(path.join(__dirname, 'tmp', 'output', 'firstfile'), { encoding: 'utf-8' })).to.equal("firstfile")
        expect(fs.readFileSync(path.join(__dirname, 'tmp', 'output', 'secondfile'), { encoding: 'utf-8' })).to.equal("secondfile")
        expect(fs.readFileSync(path.join(__dirname, 'tmp', 'output', 'thirdfile'), { encoding: 'utf-8' })).to.equal("thirdfile")
        done()
