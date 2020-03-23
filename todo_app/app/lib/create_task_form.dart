import 'package:flutter/material.dart';
import 'package:todo_app/create_task.graphql.dart';
import 'package:todo_app/schema.graphql.dart' as schema;
import 'package:todo_app/typed_mutation.dart';

final CreateTaskMutation =
    TypedMutation.factoryFor<CreateTaskResult, CreateTaskVariables>(
  documentNode: document,
  dataFromJson: CreateTaskResult.fromJson,
);

class CreateTaskForm extends StatefulWidget {
  @override
  _CreateTaskFormState createState() => _CreateTaskFormState();
}

class _CreateTaskFormState extends State<CreateTaskForm> {
  _CreateTaskFormState([schema.TaskInput task])
      : task = task != null ? task.toBuilder() : schema.TaskInputBuilder();

  schema.TaskInputBuilder task;

  // Create a global key that will uniquely identify the Form widget and allow
  // us to validate the form
  //
  // Note: This is a GlobalKey<FormState>, not a GlobalKey<TaskFormState>!
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return CreateTaskMutation(
      builder: ({
        data,
        exception,
        loading,
        runMutation,
      }) =>
          Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              initialValue: task.title,
              onSaved: (title) => setState(() {
                task.title = title;
              }),
              decoration: InputDecoration(labelText: 'Task Name'),
              validator: (value) {
                if (value.isEmpty) {
                  return 'Title is required';
                }
                return null;
              },
            ),
            TextFormField(
              initialValue: task.description,
              onSaved: (description) => setState(() {
                task.description = description;
              }),
              decoration: InputDecoration(labelText: 'Description'),
            ),
            RaisedButton(
              color: Colors.blue,
              onPressed: () {
                setState(
                  () {
                    // Validate will return true if the form is valid, or false if
                    // the form is invalid.
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      runMutation(
                        CreateTaskVariables(
                          (b) => b
                            ..taskInput =
                                (schema.CreateTaskInputBuilder()..task = task),
                        ),
                        optimisticResult: CreateTaskResult(),
                      );
                      // If the form is valid, we want to show a Snackbar
                      Scaffold.of(context)
                          .showSnackBar(SnackBar(content: Text('Saving Task')));
                    }
                  },
                );
              },
              child: Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }
}
