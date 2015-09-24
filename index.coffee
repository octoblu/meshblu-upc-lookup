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
  constructor:(@dependencies) ->
    @options = {}
    @messageSchema = MESSAGE_SCHEMA
    @optionsSchema = OPTIONS_SCHEMA

    @request = @dependencies?.request or request

  onMessage: (message) =>
    @emit('error' , new Error("API KEY has not been set on options")) unless @options.apiKey
    @emit('error' , new Error("UPC Code is missing")) unless message.upcCode or message.payload?.upcCode
    @request.get("http://api.upcdatabase.org/json/#{@options.apiKey}/#{message.upcCode}",
     null,
     (error, response, body) =>
       @emit('error', new Error("#{body.error}:#{body.reason}")) unless body.valid
    )

    # @emit 'message', response

  onConfig: (device) =>
    @setOptions device.options

  setOptions: (options={}) =>
    @options = options

module.exports =
  messageSchema: MESSAGE_SCHEMA
  optionsSchema: OPTIONS_SCHEMA
  Plugin: Plugin
