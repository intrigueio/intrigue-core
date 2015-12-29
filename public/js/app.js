(function($) {
  "use strict";

  function getTaskData() {
    // http://stackoverflow.com/questions/1420881/how-to-extract-base-url-from-a-string-in-javascript
    if (typeof location.origin === 'undefined') {
      location.origin = location.protocol + '//' + location.host;
    }

    //get the list of tasks and rewrite the task
    $.getJSON(location.origin + "/v1/tasks.json", function(data) {
      parseTasks(data);
    });

    // get the specific task data
    var form = $("form")[0]
    var task_name = form.task_name.value
    $.getJSON(location.origin + "/v1/tasks/" + task_name + ".json", function(data) {
      parseEntities(data);
    });
  }

  /* -------------------------------------------------------------------------- */

    function parseEntities(task_hash) {
      //var task_count = task_hash.length;
      //console.log(JSON.stringify(task_hash))
      //var form = $("form")[0]
      //
      $('#entity_type').empty()

      $.each(task_hash["allowed_types"], function(key, value) {
      $('#entity_type')
         .append($("<option></option>")
         .attr("value",value)
         .text(value));
      });

      $('#entity_name').text = "xys"
    }

  /* -------------------------------------------------------------------------- */

    function parseTasks(tasks_hash) {
      var task_count = tasks_hash.length;
      var metadata = $("#metadata");
      //console.log(task_hash)

      $.each(tasks_hash, function(index, value) {
        var entity_type, entity_name, form = $("form")[0];
        if (value.name === form.task_name.value) {
          // get values, so we can check if they exist
          entity_type = form.entity_type.value;
          entity_name = form.attrib_name.value;

          // if we don't have a set type
          if (!location.search.split("entity_id=")[1] && !location.search.split("task_result_id=")[1] && !!location.search.split("entities")[1]) {
            form.entity_type.value = value.example_entities[0].type;
            form.attrib_name.value = value.example_entities[0].attributes.name;
          }
          metadata.html(
            "<pre><code class='json'>" +
            JSON.stringify(value, null, 2) +
            "</code></pre>"
          );
          setOptions(value.allowed_options);
        }
      });

      highlightCode();
    }

  /* -------------------------------------------------------------------------- */

  function setOptions(options) {
    var option_html = "";
    $( "#options" ).empty();

    $.each(options, function(index, value) {
      option_html += [
        '<div class="form-group">',
          '<label class="col-xs-4 control-label" for="' + value.name + '">',
            value.name,
          '</label>',
          '<div class="col-xs-6">',
          '<input id="' + value.name + '" class="form-control input-sm" type="text" value="'
          + value.default + '" name="option_' + value.name + '"></input>',
          '</div>',
        '</div>'
      ].join('');
    });

    // Only show 'Option' fields if applicable
    if (option_html) {
      $( "#options" ).html(option_html);
    }
  }

  /* -------------------------------------------------------------------------- */

  // Initialize highlight.js syntax highlighting
  function highlightCode() {
    $(document).ready(function() {
      $('pre code').each(function(i, block) {
        hljs.highlightBlock(block);
      });
    });
  }

  // Add onchange event to <select>
  $("#task_name").on("change", getTaskData);


}(jQuery));
