# encoding: utf-8

require 'claide/ansi/cursor'
require 'claide/ansi/graphics'

module CLAide
  # Provides support for ANSI Escape sequences
  #
  # For more information see:
  #
  # - http://ascii-table.com/ansi-escape-sequences.php
  # - http://en.wikipedia.org/wiki/ANSI_escape_code
  #
  # This functionality has been inspired and derived from the following gems:
  #
  # - colored
  # - colorize
  #
  class ANSI
    extend Cursor
    extend Graphics

    class << self
      # @return [Bool] Wether the string mixin should be disabled to return the
      # original string. This method is intended to offer a central location
      # where to disable ANSI logic without needed to implement conditionals
      # across the code base of clients.
      #
      # @example
      #
      #   "example".ansi.yellow #=> "\e[33mexample\e[39m"
      #   ANSI.disabled = true
      #   "example".ansi.yellow #=> "example"
      #
      # 可以对属性做get set 操作
      attr_accessor :disabled
    end

    # @return [Hash{Symbol => Fixnum}] The text attributes codes by their
    #         English name.
    # 富文本
    TEXT_ATTRIBUTES = {
      :bold       => 1,
      :underline  => 4,
      :blink      => 5,
      :reverse    => 7,
      :hidden     => 8,
    }

    # @return [Hash{Symbol => Fixnum}] The codes to disable a text attribute by
    #         their name.
    #
    TEXT_DISABLE_ATTRIBUTES = {
      :bold       => 21,
      :underline  => 24,
      :blink      => 25,
      :reverse    => 27,
      :hidden     => 28,
    }

    # Return [String] The escape sequence to reset the graphics.
    #
    # 重置序列
    RESET_SEQUENCE = "\e[0m"

    # @return [Hash{Symbol => Fixnum}] The colors codes by their English name.
    #
    # 颜色
    COLORS = {
      :black      => 0,
      :red        => 1,
      :green      => 2,
      :yellow     => 3,
      :blue       => 4,
      :magenta    => 5,
      :cyan       => 6,
      :white      => 7,
    }

    # Return [String] The escape sequence for the default foreground color.
    #
    # 默认前景色
    DEFAULT_FOREGROUND_COLOR = "\e[39m"

    # Return [String] The escape sequence for the default background color.
    #默认背景色
    DEFAULT_BACKGROUND_COLOR = "\e[49m"

    # @return [Fixnum] The code of a key given the map.
    #
    # @param  [Symbol] key
    #         The key for which the code is needed.
    #
    # @param  [Hash{Symbol => Fixnum}] map
    #         A hash which associates each code to each key.
    #
    # @raise  If the key is not provided.
    # @raise  If the key is not present in the map.
    #
    # 查询map里是否包含key
    def self.code_for_key(key, map)
      unless key
        raise ArgumentError, 'A key must be provided'
      end
      code = map[key]
      unless code
        raise ArgumentError, "Unsupported key: `#{key}`"
      end
      code
    end
  end
end

#-- String mixin -------------------------------------------------------------#

require 'claide/ansi/string_escaper'

class String
  # @return [StringEscaper] An object which provides convenience methods to
  #         wrap the receiver in ANSI sequences.
  #
  # @example
  #
  #   "example".ansi.yellow #=> "\e[33mexample\e[39m"
  #   "example".ansi.on_red #=> "\e[41mexample\e[49m"
  #   "example".ansi.bold   #=> "\e[1mexample\e[21m"
  #
  def ansi
    CLAide::ANSI::StringEscaper.new(self)
  end
end
