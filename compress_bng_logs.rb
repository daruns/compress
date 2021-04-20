require "zlib"
require "date"
require "logger"
require "benchmark"
LOG_FILE_PATH ||= "/var/log/bngs/"
@success_logger = Logger.new("/root/compress_bng_logs/success_compressions.log")
@failed_logger = Logger.new("/root/compress_bng_logs/failure_compressions.log")

def compress_file(file_name)
#  file_name = file_name
  zipped = "#{file_name}.gz"
  source_file = "#{file_name}"
  begin
    time_consumed = Benchmark.measure {
      Zlib::GzipWriter.open(zipped) do |gz|
        File.open(source_file) do |fp|
          while chunk = fp.read(16 * 1024) do
            gz.write chunk
          end
        end
        gz.close
      end
    }.real
    done = true
    err = ""
  rescue => e
    done = false
    err = e
  ensure
    if done
      @success_logger.info("####### Success! - Done? = #{done} File: [#{file_name}], Time Consumed: [#{time_consumed}]")
      p [done, file_name, time_consumed]
    else
      @failed_logger.info("####### Done? = #{done} ###### Reason = #{err}, Time Consumed: [#{time_consumed}]")
      p [done, err, file_name, time_consumed]
    end
  end
  return [done, err, time_consumed]
end

tow_days_ago = (Time.now - 2*(60*60*24)).strftime("%Y-%m-%d").to_s
file_path_tow_days_ago = LOG_FILE_PATH + tow_days_ago
yesterday_file_log = Dir[file_path_tow_days_ago + "/*.log"]
yesterday_file_zip = Dir[file_path_tow_days_ago + "/*.gz"]
yesterday_file_log.each do |s|
  if File.exist? "#{s}.gz"
    ziped_s = s + ".gz"
    if (0..9).include? ziped_s.split("/").last.split("-").last.gsub(".log.gz","").to_i
      min_size = (0.4 * 1024 * 1024 * 1024)
    else
      min_size = (2 * 1024 * 1024 * 1024)
    end
    if File.size(ziped_s) > min_size
      system("rm -rf #{s}")
      puts "deleted #{s}"
    end
  end
end

# get the log file created yesterday
yesterday = Date.today.prev_day.strftime("%Y-%m-%d")

file_path = LOG_FILE_PATH + yesterday
yesterday_file = Dir[file_path + "/*.log"]
yesterday_file.each do |s|
  unless File.exist? "#{s}.gz"
    compress_file(s)
  end
end

