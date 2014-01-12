expect = require('chai').expect
path = require('path')
sinon = require('sinon')
fs = require('fs')
primitives = require("../src/primitives")

delay = (t, f) -> setTimeout(f, t)

describe 'have-fun', ->

  before -> try fs.mkdirSync("tmp")

  describe 'replaceArgument()', ->

    it 'replaces the value of an argument by another', ->
      spy = sinon.spy()
      f = primitives.replaceArgument(spy, 0, 'overridden')
      f('foo')
      expect(spy.firstCall.args[0]).to.equal('overridden')


  describe 'syncToAsync()', ->

    it 'should transform a synchronous function into an asynchronous one', (done) ->
      spy = sinon.spy()
      f = primitives.syncToAsync(spy, 0)
      f (err, result) ->
        expect(err).to.be.not.ok

      expect(spy.callCount).to.equal(0)
      delay 10, ->
        expect(spy.callCount).to.equal(1)
        done()

    it 'should return error when throwing', (done) ->
      f = primitives.syncToAsync( (-> throw "error"), 0)
      f (err, result) ->
        expect(err).to.equal("error")
        done()


  describe 'singleToArray()', ->

    it 'transforms a function which receives and outputs single elements into one which receives and outputs arrays', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, cb) -> cb(null, vals[i])
      transformed = primitives.singleToArray(f, 0, 1)
      transformed [1,2,0], (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['b', 'c', 'a'])
        done()

    it 'should callback with error if any of the functions does', (done) ->
      f = (error, cb) -> cb(error, !error)
      transformed = primitives.singleToArray(f, 0, 1)

      transformed [false,"someerror",false], (err) ->
        expect(err).to.equal("someerror")
        done()

    it 'allows the function to receive arguments other than the transformed one', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, append, cb) -> cb(null, vals[i] + append)
      transformed = primitives.singleToArray(f, 0, 2)
      transformed [1,2,0], 'x', (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['bx', 'cx', 'ax'])
        done()

    it 'can receive multiple indexes', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, j, cb) -> cb(null, vals[i] + vals[j])
      transformed = primitives.singleToArray(f, [0, 1], 2)
      transformed [1,2,0], [2,1,0], (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['bc', 'cb', 'aa'])
        done()

    it 'throws error if argument lists have different lengths', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, j, cb) -> cb(null, vals[i] + vals[j])
      transformed = primitives.singleToArray(f, [0, 1], 2)
      transformed [1,2,0], [2,1], (err, results) ->
        expect(err).to.be.ok
        done()

    it 'should work without callback function', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, j, cb) -> cb(null, vals[i] + vals[j])
      transformed = primitives.singleToArray(f, [0, 1], 2)
      transformed([1,2,0], [2,1, 0])
      delay(10, -> done())

    it 'should not crash without callback and invalid arguments', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, j, cb) -> cb(null, vals[i] + vals[j])
      transformed = primitives.singleToArray(f, [0, 1], 2)
      transformed([1,2,0], [2,1])
      delay(10, -> done())

  describe 'singleToArrayOptional()', ->

    it 'transforms a function which receives and outputs a single element into one which can also receive array', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, cb) -> cb(null, vals[i])
      transformed = primitives.singleToArrayOptional(f, 0, 1)
      transformed [1,2,0], (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['b', 'c', 'a'])
        done()

    it 'can receive multiple indexes', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, j, cb) -> cb(null, vals[i] + vals[j])
      transformed = primitives.singleToArrayOptional(f, [0, 1], 2)
      transformed [1,2,0], [2,1,0], (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['bc', 'cb', 'aa'])
        done()
        
    it 'allows the function to still receive a single element. the output will be a single element', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, cb) -> cb(null, vals[i])
      transformed = primitives.singleToArrayOptional(f, 0, 1)
      transformed 2, (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql('c')
        done()

    it 'allows the function to receive arguments other than the transformed one', (done) ->
      vals = [ 'a', 'b', 'c' ]
      f = (i, append, cb) -> cb(null, vals[i] + append)
      transformed = primitives.singleToArrayOptional(f, 0, 2)
      transformed [1,2,0], 'x', (err, results) ->
        expect(err).to.be.not.ok
        expect(results).to.eql(['bx', 'cx', 'ax'])
        done()


  describe 'stringToReadFile()', ->

    it 'transforms a function receiving a string to one receiving a file path to read', (done) ->
      f = (x, cb) -> cb(null, x.toUpperCase())
      transformed = primitives.stringToReadFile(f, 0, 1)

      transformed path.join(__dirname,'files/testdata.txt'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.equal("SOMETESTDATA")
        done()

    it 'receives options for readFile', (done) ->
      f = (x, cb) -> cb(null, x.readInt8(0))
      transformed = primitives.stringToReadFile(f, 0, 1, { encoding: null })

      transformed path.join(__dirname,'files/testdata.txt'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.equal(115)
        done()

    it 'throws error if file does not exist', (done) ->
      f = (x, cb) -> cb(null, x.toUpperCase())
      transformed = primitives.stringToReadFile(f, 0, 1)

      transformed path.join(__dirname,'unexisting_file'), (err, result) ->
        expect(err).to.be.ok
        expect(result).to.be.not.ok
        done()      

  describe 'readFilesToGlob()', ->

    upperCaseFun = (x, cb) -> cb(null, x.toUpperCase())
    f = primitives.singleToArray(primitives.stringToReadFile(upperCaseFun, 0, 1), 0, 1)

    it 'transforms a function receiving a list of file paths into one receiving a glob', (done) ->
      transformed = primitives.readFilesToGlob(f, 0, 1)

      transformed path.join(__dirname,'files/*globtest*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([ 'GLOBTESTDATA', 'MOREGLOBTESTDATA'])
        done()

    it 'receives glob options', (done) ->
      transformed = primitives.readFilesToGlob(f, 0, 1, { dot: true })

      transformed path.join(__dirname,'files/*globtest*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([ 'HIDDENGLOBDATA', 'GLOBTESTDATA', 'MOREGLOBTESTDATA'])
        done()

    it 'returns empty list if no matches occur', (done) ->
      transformed = primitives.readFilesToGlob(f, 0, 1)

      transformed path.join(__dirname,'files/unexisting_file*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([])
        done()

  describe 'readFilesToGlobs()', ->

    upperCaseFun = (x, cb) -> cb(null, x.toUpperCase())
    f = primitives.singleToArray(primitives.stringToReadFile(upperCaseFun, 0, 1), 0, 1)

    it 'transforms a function receiving a list of file paths into one receiving a list of globs', (done) ->
      transformed = primitives.readFilesToGlobs(f, 0, 1)

      transformed [ path.join(__dirname,'files/*globtest1*'), path.join(__dirname,'files/*globtest2*') ], (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([ 'GLOBTESTDATA', 'MOREGLOBTESTDATA'])
        done()

    it 'can still receive a single glob', (done) ->
      transformed = primitives.readFilesToGlobs(f, 0, 1)

      transformed path.join(__dirname,'files/*globtest*'), (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([ 'GLOBTESTDATA', 'MOREGLOBTESTDATA'])
        done()


    it 'should only process each file once when it is matched by two globs', (done) ->
      transformed = primitives.readFilesToGlobs(f, 0, 1)

      transformed [ path.join(__dirname,'files/*globtest*'), path.join(__dirname,'files/*globtest2*') ], (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.eql([ 'GLOBTESTDATA', 'MOREGLOBTESTDATA'])
        done()

  describe 'flattenArray()', ->

    it 'flattens the array argument before calling the function', ->
      f = sinon.spy()
      transformed = primitives.flattenArray(f, 0)
      transformed([[1,2],[3,4]])
      expect(f.firstCall.args[0]).to.eql([1,2,3,4])

    it 'should not flatten strings', ->
      f = sinon.spy()
      transformed = primitives.flattenArray(f, 0)
      transformed("hello")
      expect(f.firstCall.args[0]).to.eql("hello")


  describe 'addArg()', ->

    it 'adds an argument to a function', ->
      f = sinon.spy()
      transformed = primitives.addArg(f, -2) #Add argument before the last
      transformed('a', 'b', 'c')
      expect(f.firstCall.args).to.eql(['a', 'c'])


  describe 'stringToWriteFile()', ->

    outfile = path.join(__dirname, "tmp/outfile.txt")
    beforeEach -> try fs.unlinkSync(outfile)

    it 'transforms function which outputs a string into one which writes it to a file and outputs the file path', (done) ->
      f = (input, cb) -> cb(null, input)

      transformed = primitives.stringToWriteFile(f, 1, 1)
      transformed "all done", outfile, (err, result) ->
        expect(err).to.be.not.ok
        expect(result).to.equal(outfile)
        expect(fs.readFileSync(outfile, { encoding: 'utf-8' })).to.equal("all done")
        done()

    ### mkdirp silently fails with invalid input: https://github.com/substack/node-mkdirp/issues/40 
    it.only 'throws error if cannot create folder', (done) ->
      f = (input, cb) -> cb(null, input)

      transformed = primitives.stringToWriteFile(f, 1, 1)
      transformed "all done", 'invaliddirnam*|?e/hello', (err, result) ->
        console.log(err, result)
        expect(err).to.be.ok
        done()
    ###

    it 'throws error if cannot write file', (done) ->
      f = (input, cb) -> cb(null, input)

      transformed = primitives.stringToWriteFile(f, 1, 1)
      transformed "all done", 'tmp/invalidfilename*|?', (err, result) ->
        expect(err).to.be.ok
        done()

    
  describe 'argToGenerated()', ->
    it 'transforms function which takes a file path to write into one which takes a function to generate the file path', () ->
      f = sinon.spy()
      transformed = primitives.argToGenerated(f, 1, 0)
      nameGenerator = (inputPath) -> "output/#{inputPath}"
      transformed('testpath.txt', nameGenerator)
      expect(f.firstCall.args[1]).to.equal('output/testpath.txt')

    it 'may run generator for each element of input parameter', ->
      f = sinon.spy()
      transformed = primitives.argToGenerated(f, 1, 0, true)
      nameGenerator = (inputPath) -> "output/#{inputPath}"
      transformed([ 'testpath.txt', 'testpath2.txt' ], nameGenerator)
      expect(f.firstCall.args[1]).to.eql(['output/testpath.txt', 'output/testpath2.txt'])

  describe 'argToGeneratedOptional()', ->
    it 'generates a function which can take a function to generate a non-function parameter', () ->
      spy = sinon.spy()
      f = primitives.argToGeneratedOptional(spy, 1, 0)
      f("a", (input) -> input + "x")
      expect(spy.firstCall.args).to.eql([ "a", "ax" ])

    it 'can still receive the regular parameter', ->
      spy = sinon.spy()
      f = primitives.argToGeneratedOptional(spy, 1, 0)
      f("a", "bx")
      expect(spy.firstCall.args).to.eql([ "a", "bx" ])


  describe 'appendExtension()', ->

    it 'transforms function into one with an extension appended to a file path to write', () ->
      f = sinon.spy()
      transformed = primitives.appendExtension(f, 'js', 1)
      transformed('input.coffee', 'output')
      expect(f.firstCall.args[1]).to.equal('output.js')

  describe 'filePathToDirPath()', ->

    it 'transforms a function which takes a file path to write into one which takes a folder', () ->
      f = sinon.spy()
      transformed = primitives.filePathToDirPath(f, 1, 0)
      transformed('a', 'output')
      expect(f.firstCall.args[1]).to.equal(path.join('output', 'a'))

    it 'allows singleToArray to be used after it', (done) ->
      f = (input, callback) -> callback(null, input)
      transformed = primitives.singleToArray(primitives.filePathToDirPath(primitives.stringToWriteFile(f), 1, 0), 0, 2)
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