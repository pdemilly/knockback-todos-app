###
  knockback-todos.js
  (c) 2011 Kevin Malakoff.
  Knockback-Todos is freely distributable under the MIT license.
  See the following for full license details:
    https:#github.com/kmalakoff/knockback-todos/blob/master/LICENSE
###

$(document).ready(->

  # add a doubleclick and placeholder handlers to KO
  ko.bindingHandlers.dblclick =
    init: (element, value_accessor, all_bindings_accessor, view_model) ->
      $(element).dblclick(ko.utils.unwrapObservable(value_accessor()))

  ###################################
  # Model: http://en.wikipedia.org/wiki/Model_view_controller
  # ORM: http://en.wikipedia.org/wiki/Object-relational_mapping
  ###################################

  # Todos
  class TodoList extends Backbone.Collection
    localStorage: new Store("kb_todos") # Save all of the todo items under the `"kb_todos"` namespace.
    doneCount: -> @models.reduce(((prev,cur)-> return prev + if !!cur.get('done') then 1 else 0), 0)
    remainingCount: -> @models.length - @doneCount()
    doneTasks: -> return @filter((todo) -> return !!todo.get('done'))
    allDone: (done) -> @each((todo) -> todo.save(done: done))
  todos = new TodoList()
  todos.fetch()

  ###################################
  # MVVM: http://en.wikipedia.org/wiki/Model_View_ViewModel
  ###################################

  CreateTodoViewModel = ->
    @input_text = ko.observable('')
    @addTodo = (view_model, event) ->
      text = $.trim(@create.input_text())
      return true if (!text || event.keyCode != 13)
      todos.create({text: text})
      @create.input_text('')
    @

  TodoViewModel = (model) ->
    @text = kb.observable(model, {key: 'text', write: ((text) -> model.save({text: text}))}, this)
    @edit_mode = ko.observable(false)
    @onCheckBeginEdit = => (@edit_mode(true); $('.todo-input').focus()) if not @edit_mode() and not @done()
    @onCheckEndEdit = (view_model, event) => @edit_mode(false) if (event.keyCode == 13) or (event.type == 'blur')

    @done = kb.observable(model, {key: 'done', write: ((done) -> model.save({done: done})) }, this)
    @destroyTodo = => model.destroy()
    @

  TodoListViewModel = (todos) ->
    @todos = ko.observableArray([])
    @collection_observable = kb.collectionObservable(todos, @todos, { view_model: TodoViewModel })
    @tasks_exist = ko.computed(=> @collection_observable().length)
    @completeAll = ko.computed(
      read: => return not @collection_observable.collection().remainingCount() # create a dependency
      write: (done) => @collection_observable.collection().allDone(done)
    )
    @

  # Stats Footer
  StatsViewModel = (todos) ->
    @collection_observable = kb.collectionObservable(todos)
    @remaining_text = ko.computed(=>
      count = @collection_observable.collection().remainingCount(); return '' if not count
      return "#{count} #{if count == 1 then 'item' else 'items'} remaining."
    )
    @clear_text = ko.computed(=>
      count = @collection_observable.collection().doneCount(); return '' if not count
      return "Clear #{count} completed #{if count == 1 then 'item' else 'items'}."
    )
    @clearable = ko.computed(=> return @clear_text()!='')
    @onDestroyDone = => model.destroy() for model in todos.doneTasks()
    @

  app_view_model =
    create: new CreateTodoViewModel()
    todo_list: new TodoListViewModel(todos)
    stats: new StatsViewModel(todos)
  ko.applyBindings(app_view_model, $('#todoapp')[0])

  # Destroy when finished with the view model
  # kb.vmRelease(app_view_model)
)