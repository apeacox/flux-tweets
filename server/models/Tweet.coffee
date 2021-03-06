config = require("../../config")
redis = require("redis-url").connect(config.redis.url)

# schema
#   twid: String
#   active: Boolean
#   author: String
#   avatar: String
#   body: String
#   date: Date
#   screenname: String

module.exports = Tweet =
  getTweets: (page, skip, callback) ->
    tweets = []
    start = (page * 10) + (skip * 1)
    stop = start + 10
    redis.lrange "timeline", start, stop, (err, res) ->
      # If everything is cool...
      unless err
        res.forEach (raw) ->
          tweet = JSON.parse(raw)
          tweet.active = true # Set them to active
          tweets.push tweet

      # Pass them back to the specified callback
      callback tweets

  create: (tweet, callback) ->
    redis.multi()
      .lpush("timeline", JSON.stringify(tweet), callback)
      .llen("timeline", (err, totalTweets) ->
        if !err && totalTweets >= config.redis.limit
          redis.ltrim("timeline", 0, config.redis.limit)
      ).exec()
