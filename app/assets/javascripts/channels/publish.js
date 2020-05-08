App.publish = App.cable.subscriptions.create({ channel: "PublishChannel", channelId: "12345" }, {
  connected: function() {
  },

  disconnected: function() {
  },

  received: function(data) {
    if (data["consumerChannelId"]) {
      console.log("consumerChannelId: ", data["consumerChannelId"])
    }
  }
});
