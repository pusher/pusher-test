function compareVersions(a, b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] < b[i]) { return -1; }
    if (a[i] > b[i]) { return  1; }
  }
  return 0;
}

function writeLog(type, msg) {
  var elem = $('#debug-console')[0];
  var atBottom = (elem.scrollHeight - elem.scrollTop <= 600);

  var now = moment().format('HH:mm:ss');
  $('#debug-console').prepend(
    "<li class=" + type + ">" +
      "<span class='label time'>" + now + "</span> " +
      "<span class='label type " + type + "'>" + type + "</span> " +
      msg +
    "</li>"
  );

  // Used for auto scrolling text area
  // if (atBottom) {
  //   elem.scrollTop = elem.scrollHeight
  // }
}

function logStatus(st) {
  writeLog('status', st);
  $('#status').text(st);
}

function logError(e) {
  writeLog('error', JSON.stringify(e));
}

function logMessage(msg) {
  writeLog('message', msg);
}

function bindTransportCheckboxes() {
  var transports = {
    ws: Pusher.WSTransport,
    flash: Pusher.FlashTransport,
    sockjs: Pusher.SockJSTransport
  };
  function getCheckboxCallback(checkbox, transport) {
    var isSupportedDefault = transport.isSupported;
    var isSupportedDisabled = function() { return false; };
    return function() {
      if (checkbox.is(":checked")) {
        transport.isSupported = isSupportedDefault;
      } else {
        transport.isSupported = isSupportedDisabled;
      }
    };
  }
  for (var transportName in transports) {
    var transport = transports[transportName];
    var checkbox = $("#transport_" + transportName);
    checkbox.prop("checked", transport.isSupported());
    checkbox.prop("disabled", !transport.isSupported());
    checkbox.click(getCheckboxCallback(checkbox, transport));
  }
}

function run(env) {
  var pusher;

  $('.ajax').click(function() {
    button = $(this);
    button.addClass('disabled');
    $.post(this.href + '&' + Math.random(), null, function() {
      button.removeClass('disabled');
    });
    return false;
  });

  $('#connect').click(function() {
    pusher.connect();
    return false;
  });

  $('#disconnect').click(function() {
    pusher.disconnect();
    return false;
  });

  if (compareVersions(env.version, [1,5,0]) < 0) {
    WebSocket.__swfLocation = "/WebSocketMain.swf";
  }

  Pusher.log = function() {
    if (window.console && window.console.log.apply) {
      window.console.log.apply(window.console, arguments);
    }

    var args = Array.prototype.slice.call(arguments);
    writeLog('debug', args.join(' '));
  };

  // Flash fallback logging
  WEB_SOCKET_DEBUG = true;

  if (compareVersions(env.version, [1,5,0]) >= 0 && env.encrypted) {
    pusher = new Pusher(env.key, {
      encrypted: true
    });
    channel = pusher.subscribe('channel');
    channel.bind("event", function(data) {
      logMessage(data);
    });
    channel.bind('alert', function(data) {
      alert(data);
    });
  } else if (compareVersions(env.version, [1,4,0]) >= 0) {
    pusher = new Pusher(env.key);
    channel = pusher.subscribe('channel');
    channel.bind("event", function(data) {
      logMessage(data);
    });
    channel.bind('alert', function(data) {
      alert(data);
    });
  } else {
    pusher = new Pusher(env.key, 'channel');
    pusher.bind("event", function(data) {
      logMessage(data);
    });
    pusher.bind('alert', function(data) {
      alert(data);
    });
  }

  if (compareVersions(env.version, [2,0,0]) >= 0) {
    writeLog("debug", "session id: " + pusher.sessionID);
  }

  if (compareVersions(env.version, [1,9,0]) < 0) {
    logStatus('connecting');

    pusher.bind("pusher:connection_established", function() {
      logStatus('connected');
    });
    pusher.bind("connection_established", function() {
      logStatus('connected');
    });

    pusher.bind("pusher:connection_failed", function() {
      logStatus('disconnected');
    });
    pusher.bind("connection_failed", function() {
      logStatus('disconnected');
    });
  } else {
    pusher.connection.bind('state_change', function(state) {
      logStatus(state.current);
    });
    pusher.connection.bind('error', function(e) {
      logError(e);
    });
    // pusher.connection._machine.bind('state_change', function(event) {
    //   writeLog("internal-state", "Internal state machine transitioned from " + event.oldState + " to " + event.newState)
    // })
  }
}
