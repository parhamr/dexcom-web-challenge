#!/usr/bin/ruby

class Array
  def interquartile_mean(call_sort = true)
    sort if call_sort
    quartile_size = self.size / 4.0
    first_quartile_ending_index = quartile_size.ceil - 1
    third_quartile_ending_index = (quartile_size * 3).floor
    interquartile_range = self[first_quartile_ending_index..third_quartile_ending_index]
    factor = quartile_size - (interquartile_range.size / 2.0 - 1)
    (interquartile_range[1...-1].inject(0, :+) + (interquartile_range[0] + interquartile_range[-1]) * factor) / (2*quartile_size)
  end

  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end
end

class IncrementalInterQuartileMeanProcessor

  # NOTE: interquartile mean cannot be calculated with sets below this value (>= is valid)
  def self.min_input_length
    4
  end

  def initialize(*args)
    STDERR << "args: #{args.inspect}\n"
    @options = args.extract_options!
  end

  def calculate
    raise ArgumentError, "source_file undefined; aborting!" if @options[:source_file].nil? || @options[:source_file].empty?
    process_input
  end

  private

  def process_input
    clean_data = []
    skipped_line_count = 0
    # NOTE: allowed to raise exceptions about file presence and permissions
    File.open(path_to_source_file(@options[:source_file]), 'r') do |file_handle|
      file_handle.flock(File::LOCK_EX)
      # REVIEW: length check
      line_count = source_file_size
      if line_count < min_input_length
        raise RuntimeError, "FATAL: file '#{@options[:source_file]}' must exceed #{min_input_length} lines (#{line_count} found)"
      end
      STDERR << "Processing '#{path_to_source_file(@options[:source_file])}' -- #{line_count} lines\n"
      sleep 1
      file_handle.each_line do |line_data|
        # REVIEW: input sanitization
        clean_line = (@options[:strip_invalid] ? strip_input(line_data) : line_data)
        # REVIEW: handle empty input
        if clean_line.empty?
          skipped_line_count += 1
          next
        end
        # REVIEW: supports floats
        clean_line = clean_line.method(@options[:as_integer] ? :to_i : :to_f).call
        # NOTE: sorted insert!
        insert_index = clean_data.bsearch_index { |x, _| x > clean_line }.to_i
        clean_data.insert(insert_index, clean_line)
        # NOTE: not possible to process with fewer than 4 values
        next if clean_data.length < min_input_length
        STDOUT << "#{clean_data.length}: #{"%.2f" % clean_data.interquartile_mean(false)}\n"
      end
    end
    STDERR << "skipped_line_count: #{skipped_line_count}\n"
  end

  def path_to_source_file(source_file)
    File.join(File.dirname(__FILE__), source_file)
  end

  def source_file_size
    `wc -l #{path_to_source_file(@options[:source_file])}`.strip.split()[0].to_i
  end

  def min_input_length
    IncrementalInterQuartileMeanProcessor.min_input_length
  end

  def strip_input(input)
    # remove any non-numeric chars
    input.gsub %r{[^\d\.]+}, ''
  end

end

IncrementalInterQuartileMeanProcessor.new(
  source_file: "data.txt",
  strip_invalid: true,
  verbose: true,
  as_integer: true,
  strict: true
).calculate
