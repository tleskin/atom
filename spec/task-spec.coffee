Task = require '../src/task'
Grim = require 'grim'

describe "Task", ->
  describe "@once(taskPath, args..., callback)", ->
    it "terminates the process after it completes", ->
      handlerResult = null
      task = Task.once require.resolve('./fixtures/task-spec-handler'), (result) ->
        handlerResult = result

      processClosed = false
      processErrored = false
      childProcess = task.childProcess
      spyOn(childProcess, 'kill').andCallThrough()
      task.childProcess.on 'error', -> processErrored = true

      waitsFor ->
        handlerResult?

      runs ->
        expect(handlerResult).toBe 'hello'
        expect(childProcess.kill).toHaveBeenCalled()
        expect(processErrored).toBe false

  it "calls listeners registered with ::on when events are emitted in the task", ->
    task = new Task(require.resolve('./fixtures/task-spec-handler'))

    events = []
    task.on "some-event", (args...) -> events.push(["some-event", args...])
    task.on "some-other-event", (args...) -> events.push(["some-other-event", args...])

    waitsFor (done) -> task.start(done)

    runs ->
      expect(events).toEqual [
        ["some-event", 1, 2, 3]
        ["some-other-event", 4, 5, 6]
      ]

  it "unregisters listeners when the Disposable returned by ::on is disposed", ->
    task = new Task(require.resolve('./fixtures/task-spec-handler'))

    eventSpy = jasmine.createSpy('eventSpy')
    disposable = task.on("some-event", eventSpy)
    disposable.dispose()

    waitsFor (done) -> task.start(done)

    runs ->
      expect(eventSpy).not.toHaveBeenCalled()

  it "reports deprecations in tasks", ->
    jasmine.snapshotDeprecations()
    handlerPath = require.resolve('./fixtures/task-handler-with-deprecations')
    task = new Task(handlerPath)

    waitsFor (done) -> task.start(done)

    runs ->
      deprecations = Grim.getDeprecations()
      expect(deprecations.length).toBe 1
      expect(deprecations[0].getStacks()[0][1].fileName).toBe handlerPath
      jasmine.restoreDeprecationsSnapshot()
