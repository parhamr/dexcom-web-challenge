#!/usr/bin/ruby

module IncrementalInterQuartileMean

  def self.calculate(*args)
    STDERR << "args: #{args.inspect}\n"
    raise ArgumentError, "source_file undefined; aborting!" if args[0][:source_file].nil? || args[0][:source_file].empty?
    process_input(args)
  end

  def self.process_input(args)
    clean_data = []
    skipped_line_count = 0
    # NOTE: allowed to raise exceptions about file presence and permissions
    File.open(source_file_to_path(args[0][:source_file]), 'r') do |file_handle|
      if file_handle.count < min_input_length
        raise RuntimeError, "FATAL: file '#{args[0][:source_file]}' must exceed #{min_input_length} lines"
      end
      file_handle.rewind
      STDERR << "Processing '#{source_file_to_path(args[0][:source_file])}' -- #{file_handle.count} lines\n"
      file_handle.rewind
      file_handle.each_line do |line_data|
        clean_line = (args[0][:strip_invalid] ? strip(line_data) : line_data)
        if clean_line.empty?
          skipped_line_count += 1
          next
        end
        clean_data << clean_line.method(args[0][:as_integer] ? :to_i : :to_f).call
        # NOTE: not possible to process with fewer than 4 values
        next if clean_data.length < min_input_length
        quartile_size = clean_data.size / 4.0
        ys = clean_data.sort[quartile_size.ceil-1..(3*quartile_size).floor]
        factor = quartile_size - (ys.size/2.0 - 1)

        mean = (ys[1...-1].inject(0, :+) + (ys[0] + ys[-1]) * factor) / (2*quartile_size)
        STDOUT << "#{clean_data.length}: #{"%.2f" % mean}\n"
      end
    end
    STDERR << "skipped_line_count: #{skipped_line_count}\n"
  end

  def self.source_file_to_path(source_file)
    File.join(File.dirname(__FILE__), source_file)
  end

  def self.chars_to_replace
    ''
  end

  def self.chars_to_strip
    # NOTE: anything not numeric
    %r{[^\d\.]+}
  end

  # NOTE: interquartile mean cannot be calculated with sets below this value (>= is valid)
  def self.min_input_length
    4
  end

  def self.strip(input)
    input.gsub chars_to_strip, chars_to_replace
  end

end

IncrementalInterQuartileMean.calculate(
  source_file: "data.txt",
  strip_invalid: true,
  verbose: true,
  as_integer: true,
  strict: true
)
