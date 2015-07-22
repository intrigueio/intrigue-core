(function($) {
  "use strict";

  function getTaskData() {
    // http://stackoverflow.com/questions/1420881/how-to-extract-base-url-from-a-string-in-javascript
    if (typeof location.origin === 'undefined') {
      location.origin = location.protocol + '//' + location.host;
    }
    $.getJSON(location.origin + "/v1/tasks.json", function(data) {
      parseTasks(data);
    });
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
          + value.default + '" name="option_"' + value.name + '></input>',
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

  function parseTasks(task_hash) {
    var task_count = task_hash.length;
    var metadata = $("#metadata");
    console.log(task_hash)

    $.each(task_hash, function(index, value) {
      var entity_type, entity_name, form = $("form")[0];
      if (value.name === form.task_name.value) {
        // get values, so we can check if they exist
        entity_type = form.entity_type.value;
        entity_name = form.attrib_name.value;

        // if we don't have a set type
        if (!location.search.split("type=")[1]) {
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
