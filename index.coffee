'use strict';
util           = require 'util'
{EventEmitter} = require 'events'
debug          = require('debug')('meshblu-upc-lookup')
request        = require 'request'

MESSAGE_SCHEMA =
  type: 'object'
  properties:
    upcCode:
      type: 'string'
      required: true

OPTIONS_SCHEMA =
  type: 'object'
  properties:
    apiKey:
      type: 'string'
      required: true

class Plugin extends EventEmitter
  constructor: (@dependencies) ->
    @options = {}
    @messageSchema = MESSAGE_SCHEMA
    @optionsSchema = OPTIONS_SCHEMA
    @request = @dependencies?.request or request

    @KEY_NOT_SET_ERROR = 'API KEY has not been set on options'
    @UPC_MISSING_ERROR = 'UPC Code is missing'

  onMessage: (message) =>
    debug 'Message received', message

    upcCode = message.upcCode || message.payload?.upcCode
    @emit 'error', new Error(@KEY_NOT_SET_ERROR) unless @options.apiKey
    @emit 'error', new Error(@UPC_MISSING_ERROR) unless upcCode

    url = "http://api.upcdatabase.org/json/#{@options.apiKey}/#{upcCode}"
    @request.get url, json: true, (error, response, body) =>
      debug "Response from UPC database", error, body

      if error
        debug "Error #{error}"
        return @emit 'error', error

      @emit 'message', body

  onConfig: (device) =>
    @setOptions device.options

  setOptions: (options={}) =>
    @options = options

module.exports =
  messageSchema: MESSAGE_SCHEMA
  optionsSchema: OPTIONS_SCHEMA
  Plugin: Plugin
