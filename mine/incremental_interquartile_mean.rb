#!/usr/bin/ruby

expected_mean_value = "458.82"

class Array

  def interquartile_mean(call_sort = true)
    self.sort! if call_sort
    quartile_size = self.size / 4.0
    first_quartile_ending_index = quartile_size.ceil - 1
    third_quartile_ending_index = (quartile_size * 3).floor
    interquartile_range = self[first_quartile_ending_index..third_quartile_ending_index]
    factor = quartile_size - (interquartile_range.size / 2.0 - 1)
    interquartile_range_bounded_total = interquartile_range[1...-1].inject(0, :+)
    interquartile_range_bounds_sum = interquartile_range[0] + interquartile_range[-1]
    (interquartile_range_bounded_total + interquartile_range_bounds_sum * factor) / (2 * quartile_size)
  end

  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end

  def sorted_insert(insertable, call_sort = true)
    sort! if call_sort
    bsearch_index { |x, _| x >= insertable }.tap do |i|
      # NOTE: i is nil when empty and/or insertable goes to the end
      i.nil? ? self.push(insertable) : self.insert(i, insertable)
    end
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
    @clean_data = []
  end

  def calculate
    raise ArgumentError, "source_file undefined; aborting!" if @options[:source_file].nil? || @options[:source_file].empty?
    process_input
  end

  private

  def process_input
    mean = 0
    skipped_line_count = 0
    # NOTE: allowed to raise exceptions about file presence and permissions
    File.open(path_to_source_file(@options[:source_file]), 'r') do |file_handle|
      file_handle.flock(File::LOCK_EX)
      # REVIEW: length check
      if source_file_line_count < min_input_length
        raise RuntimeError, "FATAL: file '#{@options[:source_file]}' must exceed #{min_input_length} lines (#{source_file_line_count} found)"
      end
      STDERR << "Processing '#{path_to_source_file(@options[:source_file])}' -- #{source_file_line_count} lines\n"
      file_handle.each_line do |line_data|
        # REVIEW: input sanitization
        clean_line = (@options[:strip_invalid] ? strip_input(line_data) : line_data)
        # REVIEW: handle empty input
        if clean_line.empty?
          skipped_line_count += 1
          next
        end
        # REVIEW: supports floats
        clean_line = clean_line.method(numeric_coercion_method).call
        # NOTE: already sorted; skip the expensive quicksort
        @clean_data.sorted_insert(clean_line, false)
        # NOTE: not possible to process with fewer than 4 values
        next if @clean_data.length < min_input_length
        # NOTE: already sorted; skip the expensive quicksort
        mean = @clean_data.interquartile_mean(false)
        STDOUT << "#{@clean_data.length}: #{"%.2f" % mean}\n"
      end
    end
    STDERR << "skipped_line_count: #{skipped_line_count}\n"
    mean
  end

  def numeric_coercion_method
    @options[:as_integer] ? :to_i : :to_f
  end

  def path_to_source_file(source_file)
    File.join(File.dirname(__FILE__), source_file)
  end

  def source_file_line_count
    @source_file_line_count ||= `wc -l #{path_to_source_file(@options[:source_file])}`.strip.split()[0].to_i
  end

  # REVIEW: accessible for overriding in specs
  def min_input_length
    IncrementalInterQuartileMeanProcessor.min_input_length
  end

  def strip_input(input)
    # remove any non-numeric chars
    input.gsub %r{[^\d\.]+}, ''
  end

end

mean = IncrementalInterQuartileMeanProcessor.new(
  source_file: "data.txt",
  strip_invalid: true,
  verbose: true,
  as_integer: true,
  strict: true
).calculate

formatted_mean = "#{"%.2f" % mean}"

if formatted_mean == expected_mean_value
  STDOUT << "SUCCESS: calculated mean (#{formatted_mean}) matches expected value (#{expected_mean_value})\n"
else
  raise RuntimeError, "FAIL: calculated mean (#{formatted_mean}) did not match expected value (#{expected_mean_value})"
end
