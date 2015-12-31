require 'telegram_bot'
require 'pp'
require 'logger'
# require './lib/savings-bot'

$logger = Logger.new(STDOUT, Logger::DEBUG)

$bot = TelegramBot.new(token: 'YOUR_TOKEN_HERE', logger: $logger)
$logger.debug "starting telegram bot"

def add(user,msg)
  logger_add = Logger.new(STDOUT, Logger::DEBUG)
  file = File.read('data.json')
  data_hash = JSON.parse(file)

  # Create a new user if none exists (REQUIRES USERNAME!)
      if data_hash['user'][user].nil?
        tempHash = {"#{user}" => {"gas" => 0.0,"recent_gas" => 0.0}}
        data_hash['user'][user] = { :gas => '0.0', :recent_gas => '0.0'}
        File.open("data.json","w") do |f|
          f.write(JSON.pretty_generate(data_hash))
        end

  # Else, go about adding their stuff to the totals
      else
        if msg.match(/\d/)
          msg = msg.to_f
          val = data_hash['user'][user]['gas'].to_f
          val += msg
          data_hash['user'][user]['gas'] = val.to_s
        else
          # error?
        end

        File.open("data.json","w") do |f|
          f.write(JSON.pretty_generate(data_hash))
        end
          # how can I respond here?
      end

        logger_add.info "#{user} added #{val.to_s} in JSON"
        # Back to bot ops
end

def savingsBot
  $bot.get_updates(fail_silently: true) do |message|
    $logger.info "@#{message.from.username}: #{message.text}"
    command = message.get_command_for($bot)
    msg = "#{message.text}"
    msg =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/
    user = message.from.username

    message.reply do |reply|
      case command
      when /greet/i
        reply.text = "Hello, #{message.from.first_name}! Please Use the /Add command to continue!"
      when /add/i
        reply.text = "How much did you save?"
        reply.send_with($bot)
        $bot.get_updates(fail_silently: true) do |message|
          $logger.info "@#{message.from.username}: #{message.text}"
          msg = "#{message.text}"
          msg =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/
          user = message.from.username
          add(user,msg)

          f = File.read('data.json')
          data_hash = JSON.parse(f)
          reply.text = "Added! You have saved $#{data_hash['user']["#{user}"]['gas'].to_s}!"
          break
        end
      else
        reply.text = "#{message.from.first_name}, I have no idea what #{command.inspect} means."
      end
      $logger.info "sending #{reply.text.inspect} to @#{message.from.username}"
      reply.send_with($bot)
    end
  end
end

savingsBot
