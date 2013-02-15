;(function() {
  function Logger(console, types) {
    this.console = console;
    this.types = types;
  }
  var prototype = Logger.prototype;

  prototype.log = function(type, message) {
    var now = moment().format('HH:mm:ss');
    var hidden = this.types[type] === false;
    this.console.prepend(
      "<li class=" + type + " style='" + (hidden ? "display:none" : "") + "'>" +
        "<span class='label time'>" + now + "</span> " +
        "<span class='label type " + type + "'>" + type + "</span> " +
        "<span class='message'>" + message + "</span>" +
      "</li>"
    );
  };

  prototype.setVisibility = function(type, visible) {
    this.types[type] = !!visible;
    this.console.find("li." + type).css("display", visible ? "block" : "none");
  };

  this.Logger = Logger;
})();
