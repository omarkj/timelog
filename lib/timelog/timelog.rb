require 'ostruct'
require 'time'

module Timelog
  # A timelog keeps tracks of activities that occur over time.  Existing
  # activities are loaded from the stream and new ones are appended to it.
  class Timelog
    # A new day starts at 4:00am in the morning.
    DAY_BOUNDARY_HOUR = 4

    attr_reader :activities

    def initialize(activities, stream)
      @activities = activities
      @stream = stream
    end

    # Write an activity to the timelog stream.
    def record_activity(description, end_time=nil)
      end_time ||= Time.now

      previous_activity = @activities[-1]
      start_time = nil
      unless previous_activity.nil?
        previous_end_time = previous_activity[:end_time]
        if (more_than_a_day_passed?(end_time, previous_end_time) ||
            crossed_day_change_boundary?(end_time, previous_end_time))
          @stream.puts ''
        end
        start_time = previous_end_time
      end
      @stream.puts("#{end_time.strftime '%Y-%m-%d %H:%M'}: #{description}")
      @activities << {:start_time => start_time, :end_time => end_time,
                      :description => description}
    end

    private

    def more_than_a_day_passed?(end_time, previous_end_time)
      end_time - previous_end_time > 60 * 60 * 24
    end

    def crossed_day_change_boundary?(end_time, previous_end_time)
      previous_end_time.hour < 4 && end_time.hour >= 4
    end
  end

  # Load a timelog from a file stream.
  def self.load_stream(stream)
    activities = []
    start_time = nil
    stream.each do |line|
      result = line.scan(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}): (.*)\n/)
      if result.empty?
        start_time = nil
      else
        item = result[0]
        end_time = Time.new(item[0].to_i, item[1].to_i, item[2].to_i,
                            item[3].to_i, item[4].to_i)
        description = item[5]
        if start_time.nil?
          start_time = end_time
        else
          activities << {:start_time => start_time, :end_time => end_time,
                         :description => description}
          start_time = end_time
        end
      end
    end
    Timelog.new(activities, stream)
  end

  private

  # Get an object with activity information extract from the line or nil if
  # the line is not in the expected format.
  def self.parse_activity_line(line)
    result = line.scan(/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}): (.*)\n/)
    unless result.empty?
      item = result[0]
      timestamp = Time.new(item[0].to_i, item[1].to_i, item[2].to_i,
                           item[3].to_i, item[4].to_i)
      {timestamp: timestamp, description: item[5]}
    end
  end
end
