{Range, Point} = require 'atom'
child_process = require 'child_process'
fs = require 'fs'
CommandRunner = require '../command-runner'

module.exports =
class Rubocop
  constructor: (@filePath) ->

  run: (callback) ->
    @runRubocop (error, result) =>
      if error?
        callback(error)
      else
        file = result.files[0]
        offenses = file.offenses || file.offences
        violations = offenses.map(@createViolationFromOffense)
        callback(null, violations)

  createViolationFromOffense: (offense) ->
    bufferPoint = new Point(offense.location.line - 1, offense.location.column - 1)
    bufferRange = new Range(bufferPoint, bufferPoint)
    severity = switch offense.severity
               when 'error', 'fatal'
                 'error'
               else
                 'warning'

    severity: severity
    message: offense.message
    bufferRange: bufferRange

  runRubocop: (callback) ->
    runner = new CommandRunner(@constructCommand())

    runner.run (error, result) ->
      return callback(error) if error?

      if result.exitCode == 0 || result.exitCode == 1
        try
          callback(null, JSON.parse(result.stdout))
        catch error
          callback(error)
      else
        callback(new Error("Process exited with code #{result.exitCode}"))

  constructCommand: ->
    command = []

    userRubocopPath = atom.config.get('atom-lint.rubocop.path')

    if userRubocopPath?
      command.push(userRubocopPath)
    else
      command.push('rubocop')

    command.push('--format', 'json', @filePath)
    command
