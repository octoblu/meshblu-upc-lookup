{Plugin}              = require '../index'
{EventEmitter}        = require 'events'
request               = require 'request'

describe 'UPCLookupPlugin', ->

  it 'should exist', ->
    expect(Plugin).to.exist

  describe '->onMessage', ->

    describe 'when there is no apiKey set in options', ->
      beforeEach ->
        @sut          = new Plugin
        @errorSpy     = sinon.spy()
        @error        = new Error("API KEY has not been set on options")
        @sut.on('error', @errorSpy)
        @sut.setOptions({})
        @sut.onMessage({})

      it 'should send an error message saying the apiKey is missing', ->
        expect(@errorSpy).to.have.been.calledWith(@error)

    describe 'when there is an apiKey and no upcCode', ->
      beforeEach ->
        @sut          = new Plugin
        @errorSpy     = sinon.spy()
        @error        = new Error("UPC Code is missing")
        @sut.on('error', @errorSpy)
        @sut.setOptions({
          apiKey : "12345"
          })
        @sut.onMessage({})

      it 'should send an error message saying the UPC code is missing', ->
        expect(@errorSpy).to.have.been.calledWith(@error)

    describe 'when there is an apiKey and a upcCode', ->
      before (done)->
        sinon.stub(request, 'get')
        @dependencies =
          request : request

        @options =
          apiKey : "abcde"

        @message =
          upcCode : "54321"

        @sut = new Plugin(@dependencies)
        @sut.setOptions(@options)
        @sut.onMessage(@message)
        done()

      after (done) ->
        request.get.restore()
        done()

      it 'should make a request to the upcdatabase.org site with api key and UPC code in the URL',(done) ->
        expect(@dependencies.request.get).to.have.been.calledWith("http://api.upcdatabase.org/json/#{@options.apiKey}/#{@message.upcCode}")
        done()
        return
        #errors
        # 101 - API Key length is incorrect
        # 105 - API Key incorrect
        #messages
        # 199 - No more API requests remaining
        # 205 - The code you entered was non-numeric
        # 301 - Code does not exist
        # 500 - High server load
      describe 'When the upc database site returns errors', ->
        describe 'when the API key length is incorrect', ->
          beforeEach (done) ->
            request.get.yields(null, {statusCode : 200}, {valid : false, error: 101, reason: "Api Key length is incorrect"})
            @errorSpy = sinon.spy()
            @sut.on('error', @errorSpy)
            @sut.onMessage(@message)
            done()

          it 'should emit an error',(done) ->
            expect(@errorSpy).to.have.been.calledWith(new Error("101:Api Key length is incorrect"))
            done()

         describe 'when the API key is incorrect', ->
           beforeEach (done) ->
             request.get.yields(null, {statusCode : 200}, {valid : false, error: 105, reason: "Api Key is incorrect"})
             @errorSpy = sinon.spy()
             @sut.on('error', @errorSpy)
             @sut.onMessage(@message)
             done()

           it 'should emit an error',(done) ->
             expect(@errorSpy).to.have.been.calledWith(new Error("105:Api Key is incorrect"))
             done()